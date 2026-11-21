import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { LEVEL_BY_ID, PETS } from '../game/data'
import { playSound } from '../game/audio'
import { clamp, shuffle, type GameProps } from './types'
import { IconClock } from '../components/Icon'

type Variant = { filter?: string; transform?: string; label: string }

const VARIANTS_BY_LEVEL: Variant[][] = [
  [{ filter: 'hue-rotate(190deg) saturate(1.5)', label: 'цвет' }],
  [
    { filter: 'hue-rotate(140deg)', label: 'цвет' },
    { transform: 'scaleX(-1)', label: 'зеркало' },
    { transform: 'rotate(20deg)', label: 'поворот' },
  ],
  [
    { filter: 'hue-rotate(95deg)', label: 'цвет' },
    { transform: 'scaleX(-1) rotate(-6deg)', label: 'зеркало' },
    { transform: 'scale(0.82)', label: 'размер' },
    { filter: 'brightness(1.25) saturate(0.7)', label: 'свет' },
  ],
  [
    { filter: 'hue-rotate(62deg)', label: 'цвет' },
    { transform: 'scaleX(-1)', label: 'зеркало' },
    { transform: 'rotate(11deg) scale(0.94)', label: 'поворот' },
    { filter: 'saturate(1.9) brightness(1.1)', label: 'насыщенность' },
    { transform: 'scaleY(0.86)', label: 'высота' },
  ],
  [
    { filter: 'hue-rotate(38deg)', label: 'цвет' },
    { transform: 'scaleX(-1)', label: 'зеркало' },
    { transform: 'rotate(7deg)', label: 'поворот' },
    { filter: 'brightness(1.15)', label: 'свет' },
    { transform: 'scale(0.94)', label: 'размер' },
  ],
]

function pickVariant(levelId: number): Variant {
  const index = Math.min(VARIANTS_BY_LEVEL.length - 1, Math.max(0, Math.floor((levelId - 1) / 3)))
  const list = VARIANTS_BY_LEVEL[index]
  return list[Math.floor(Math.random() * list.length)]
}

type Round = {
  petImg: string
  oddIndex: number
  variant: Variant
  order: number[]
}

function makeRound(cells: number, levelId: number): Round {
  const pet = PETS[Math.floor(Math.random() * PETS.length)]
  const oddIndex = Math.floor(Math.random() * cells)
  return {
    petImg: pet.img,
    oddIndex,
    variant: pickVariant(levelId),
    order: shuffle(Array.from({ length: cells }, (_, i) => i)),
  }
}

export default function OddGame({ levelId, onFinish }: GameProps) {
  const level = LEVEL_BY_ID[levelId]
  const cells = level.cells ?? 9
  const totalRounds = level.rounds ?? 4
  const [roundIndex, setRoundIndex] = useState(0)
  const [rounds] = useState<Round[]>(() =>
    Array.from({ length: totalRounds }, () => makeRound(cells, levelId)),
  )
  const [correct, setCorrect] = useState(0)
  const [mistakes, setMistakes] = useState(0)
  const [wrongIndex, setWrongIndex] = useState<number | null>(null)
  const [rightIndex, setRightIndex] = useState<number | null>(null)
  const [elapsed, setElapsed] = useState(0)
  const startedAt = useRef(Date.now())
  const finished = useRef(false)
  const busy = useRef(false)

  useEffect(() => {
    const id = window.setInterval(() => {
      if (!finished.current) setElapsed(Math.floor((Date.now() - startedAt.current) / 1000))
    }, 400)
    return () => window.clearInterval(id)
  }, [])

  const finish = useCallback(
    (finalCorrect: number, finalMistakes: number) => {
      if (finished.current) return
      finished.current = true
      const accuracy = finalCorrect / Math.max(1, finalCorrect + finalMistakes)
      const seconds = Math.floor((Date.now() - startedAt.current) / 1000)
      const speed = Math.max(0, Math.min(1, 1 - Math.max(0, seconds - totalRounds * 3) / (totalRounds * 5)))
      const score = Math.round(clamp(100 * (0.82 * accuracy + 0.18 * speed)))
      playSound('success')
      window.setTimeout(() => onFinish(score, 0), 650)
    },
    [onFinish, totalRounds],
  )

  const tap = (orderValue: number) => {
    if (busy.current || finished.current) return
    const round = rounds[roundIndex]
    if (orderValue === round.oddIndex) {
      busy.current = true
      setRightIndex(orderValue)
      playSound('reward', 0.7)
      const nextCorrect = correct + 1
      setCorrect(nextCorrect)
      window.setTimeout(() => {
        setRightIndex(null)
        busy.current = false
        if (roundIndex + 1 >= totalRounds) {
          finish(nextCorrect, mistakes)
        } else {
          setRoundIndex((i) => i + 1)
        }
      }, 420)
    } else {
      setWrongIndex(orderValue)
      setMistakes((m) => m + 1)
      playSound('tap', 0.4)
      window.setTimeout(() => setWrongIndex(null), 480)
    }
  }

  const columns = cells <= 6 ? 3 : cells <= 9 ? 3 : cells <= 12 ? 4 : cells <= 16 ? 4 : 5
  const round = rounds[roundIndex]

  const cellsToShow = useMemo(() => round.order.slice(0, cells), [round, cells])

  return (
    <div className="game odd-game">
      <div className="game-stats">
        <span className="game-stat">
          <span className="game-stat__label">Раунд</span>
          <b>
            {Math.min(roundIndex + 1, totalRounds)} / {totalRounds}
          </b>
        </span>
        <span className="game-stat game-stat--center">
          <span className="game-stat__label">Найдено</span>
          <b>{correct}</b>
        </span>
        <span className="game-stat">
          <span className="game-stat__label">Ошибки</span>
          <b className={mistakes > 0 ? 'is-warn' : ''}>{mistakes}</b>
        </span>
      </div>

      <div className="odd-board" style={{ ['--odd-cols' as string]: columns }}>
        {cellsToShow.map((orderValue) => {
          const isOdd = orderValue === round.oddIndex
          const style = isOdd
            ? { filter: round.variant.filter, transform: round.variant.transform }
            : undefined
          return (
            <button
              key={`${roundIndex}-${orderValue}`}
              className={`odd-cell ${wrongIndex === orderValue ? 'is-wrong' : ''} ${rightIndex === orderValue ? 'is-right' : ''}`}
              onClick={() => tap(orderValue)}
              aria-label="Питомец"
            >
              <img src={round.petImg} alt="" style={style} draggable={false} />
            </button>
          )
        })}
      </div>

      <p className="game-tip">
        Один питомец отличается: {round.variant.label}. Найдите его! Осталось {totalRounds - roundIndex}
      </p>
      <span className="game-timer"><IconClock size={13} /> {elapsed} с</span>
    </div>
  )
}
