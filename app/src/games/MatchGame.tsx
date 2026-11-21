import { useEffect, useRef, useState } from 'react'
import { LEVEL_BY_ID, PETS } from '../game/data'
import { playSound } from '../game/audio'
import { clamp, shuffle, type GameProps } from './types'
import { IconPaw } from '../components/Icon'

type Card = { uid: number; petId: string; img: string }

export default function MatchGame({ levelId, onFinish }: GameProps) {
  const level = LEVEL_BY_ID[levelId]
  const pairs = level.pairs ?? 6
  const [deck] = useState<Card[]>(() => {
    const chosen = shuffle(PETS.filter((p) => p.id !== 'murzik')).slice(0, pairs)
    return shuffle(
      chosen.flatMap((pet, index) => [
        { uid: index * 2, petId: pet.id, img: pet.img },
        { uid: index * 2 + 1, petId: pet.id, img: pet.img },
      ]),
    )
  })
  const [flipped, setFlipped] = useState<number[]>([])
  const [matched, setMatched] = useState<number[]>([])
  const [moves, setMoves] = useState(0)
  const [lock, setLock] = useState(false)
  const [elapsed, setElapsed] = useState(0)
  const startedAt = useRef(Date.now())
  const finished = useRef(false)

  useEffect(() => {
    const id = window.setInterval(() => {
      if (!finished.current) setElapsed(Math.floor((Date.now() - startedAt.current) / 1000))
    }, 300)
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    if (matched.length !== pairs * 2 || finished.current) return
    finished.current = true
    playSound('success')
    const finalMoves = moves
    const seconds = Math.floor((Date.now() - startedAt.current) / 1000)
    const efficiency = Math.min(1, pairs / Math.max(finalMoves, pairs))
    const speed = Math.max(0, Math.min(1, 1 - Math.max(0, seconds - pairs * 3) / (pairs * 7)))
    const score = Math.round(clamp(100 * (0.8 * efficiency + 0.2 * speed)))
    window.setTimeout(() => onFinish(score, pairs), 700)
  }, [matched, moves, onFinish, pairs])

  const flip = (index: number) => {
    if (lock || finished.current) return
    if (flipped.includes(index) || matched.includes(index)) return
    playSound('tap', 0.6)
    const next = [...flipped, index]
    setFlipped(next)
    if (next.length === 2) {
      setMoves((m) => m + 1)
      const [a, b] = next
      if (deck[a].petId === deck[b].petId) {
        setMatched((m) => [...m, a, b])
        setFlipped([])
        playSound('reward', 0.65)
      } else {
        setLock(true)
        window.setTimeout(() => {
          setFlipped([])
          setLock(false)
        }, 720)
      }
    }
  }

  const cols = 4

  return (
    <div className="game match-game">
      <div className="game-stats">
        <span className="game-stat">
          <span className="game-stat__label">Ходы</span>
          <b>{moves}</b>
        </span>
        <span className="game-stat game-stat--center">
          <span className="game-stat__label">Пары</span>
          <b>
            {matched.length / 2} / {pairs}
          </b>
        </span>
        <span className="game-stat">
          <span className="game-stat__label">Время</span>
          <b>{elapsed}с</b>
        </span>
      </div>

      <div className="match-board" style={{ ['--match-cols' as string]: cols }}>
        {deck.map((card, index) => {
          const isOpen = flipped.includes(index) || matched.includes(index)
          const isMatched = matched.includes(index)
          return (
            <button
              key={card.uid}
              className={`memory-card ${isOpen ? 'is-open' : ''} ${isMatched ? 'is-matched' : ''}`}
              onClick={() => flip(index)}
              aria-label={isOpen ? 'Открытая карточка' : 'Закрытая карточка'}
            >
              <span className="memory-card__inner">
                <span className="memory-card__back">
                  <span className="memory-card__paw"><IconPaw size={24} /></span>
                  <span className="memory-card__star">✦</span>
                </span>
                <span className="memory-card__front">
                  <img src={card.img} alt="" draggable={false} />
                  {isMatched && <span className="memory-card__ok">✓</span>}
                </span>
              </span>
            </button>
          )
        })}
      </div>
      <p className="game-tip">Найдите все пары питомцев. Меньше ходов — больше звёзд!</p>
    </div>
  )
}
