import { useCallback, useEffect, useRef, useState } from 'react'
import { LEVEL_BY_ID } from '../game/data'
import { playSound } from '../game/audio'
import { clamp, shuffle, type GameProps } from './types'
import { IconCheck, IconClock, IconPaw } from '../components/Icon'

type Spark = { id: number; x: number; y: number; size: number; delay: number }

function plural(n: number, one: string, few: string, many: string) {
  const mod10 = n % 10
  const mod100 = n % 100
  if (mod10 === 1 && mod100 !== 11) return one
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few
  return many
}
type Round = { total: number; sparks: Spark[]; options: number[] }

const ROUNDS = 5

function makeRound(roundIndex: number): Round {
  const total = 4 + roundIndex + Math.floor(Math.random() * 3)
  const placed: Array<{ x: number; y: number }> = []
  const minGap = 17
  const sparks: Spark[] = Array.from({ length: total }, (_, i) => {
    let x = 12 + Math.random() * 76
    let y = 12 + Math.random() * 76
    for (let attempt = 0; attempt < 40; attempt += 1) {
      const clash = placed.some((p) => Math.hypot(p.x - x, p.y - y * 0.82) < minGap)
      if (!clash) break
      x = 12 + Math.random() * 76
      y = 12 + Math.random() * 76
    }
    placed.push({ x, y })
    return {
      id: i,
      x,
      y,
      size: 15 + Math.random() * 9,
      delay: 220 + i * (150 + Math.random() * 80),
    }
  })
  const options = new Set<number>([total])
  while (options.size < 4) {
    const drift = Math.floor(Math.random() * 5) - 2
    const candidate = total + (drift === 0 ? 3 : drift)
    if (candidate > 0) options.add(candidate)
  }
  return { total, sparks, options: shuffle([...options]) }
}

export default function CountGame({ levelId, onFinish }: GameProps) {
  const level = LEVEL_BY_ID[levelId]
  const showMs = (level.seconds ?? 3) * 1000
  const [rounds] = useState<Round[]>(() => Array.from({ length: ROUNDS }, (_, i) => makeRound(i)))
  const [roundIndex, setRoundIndex] = useState(0)
  const [stage, setStage] = useState<'show' | 'answer' | 'reveal'>('show')
  const [visible, setVisible] = useState(0)
  const [correct, setCorrect] = useState(0)
  const [mistakes, setMistakes] = useState(0)
  const [picked, setPicked] = useState<number | null>(null)
  const [elapsed, setElapsed] = useState(0)
  const startedAt = useRef(Date.now())
  const finished = useRef(false)
  const round = rounds[roundIndex]

  useEffect(() => {
    const id = window.setInterval(() => {
      if (!finished.current) setElapsed(Math.floor((Date.now() - startedAt.current) / 1000))
    }, 400)
    return () => window.clearInterval(id)
  }, [])

  // показ искр по одной
  useEffect(() => {
    if (stage !== 'show') return
    setVisible(0)
    const timers = round.sparks.map((_, i) =>
      window.setTimeout(() => {
        setVisible(i + 1)
        playSound('tap', 0.28 + Math.min(0.4, i * 0.04))
      }, round.sparks[i].delay),
    )
    const end = window.setTimeout(() => setStage('answer'), showMs)
    return () => {
      timers.forEach((t) => window.clearTimeout(t))
      window.clearTimeout(end)
    }
  }, [stage, round, showMs, roundIndex])

  const finish = useCallback(
    (finalCorrect: number, finalMistakes: number) => {
      if (finished.current) return
      finished.current = true
      const accuracy = finalCorrect / Math.max(1, finalCorrect + finalMistakes)
      const seconds = Math.floor((Date.now() - startedAt.current) / 1000)
      const speed = Math.max(0, Math.min(1, 1 - Math.max(0, seconds - ROUNDS * 6) / (ROUNDS * 6)))
      const score = Math.round(clamp(100 * (0.85 * accuracy + 0.15 * speed)))
      playSound('success')
      window.setTimeout(() => onFinish(score, 0), 650)
    },
    [onFinish],
  )

  const answer = (value: number) => {
    if (stage !== 'answer') return
    const isRight = value === round.total
    setPicked(value)
    setStage('reveal')
    if (isRight) {
      playSound('reward', 0.7)
      setCorrect((c) => c + 1)
    } else {
      playSound('tap', 0.4)
      setMistakes((m) => m + 1)
    }
    const nextCorrect = correct + (isRight ? 1 : 0)
    const nextMistakes = mistakes + (isRight ? 0 : 1)
    window.setTimeout(() => {
      setPicked(null)
      if (roundIndex + 1 >= ROUNDS) {
        finish(nextCorrect, nextMistakes)
      } else {
        setRoundIndex((i) => i + 1)
        setStage('show')
      }
    }, 1200)
  }

  return (
    <div className="game count-game">
      <div className="game-stats">
        <span className="game-stat">
          <span className="game-stat__label">Раунд</span>
          <b>
            {roundIndex + 1} / {ROUNDS}
          </b>
        </span>
        <span className="game-stat game-stat--center">
          <span className="game-stat__label">Верно</span>
          <b>{correct}</b>
        </span>
        <span className="game-stat">
          <span className="game-stat__label">Ошибки</span>
          <b className={mistakes > 0 ? 'is-warn' : ''}>{mistakes}</b>
        </span>
      </div>

      <div className="spark-field">
        <span className="spark-field__glow" aria-hidden />
        <span className="spark-field__mark" aria-hidden>
          <IconPaw size={92} />
        </span>
        {round.sparks.slice(0, visible).map((spark) => (
          <span
            key={`${roundIndex}-${spark.id}`}
            className={`spark-slot ${stage !== 'show' ? 'is-fading' : ''}`}
            style={{
              left: `${spark.x}%`,
              top: `${spark.y}%`,
              width: spark.size,
              height: spark.size,
            }}
          >
            <i className="spark-bob" style={{ animationDelay: `${spark.delay}ms` }}>
              <i className="spark-bob__core" />
              <i className="spark-bob__ray spark-bob__ray--v" />
              <i className="spark-bob__ray spark-bob__ray--h" />
            </i>
          </span>
        ))}
        {stage === 'show' && <span className="spark-field__hint">Считайте искры…</span>}
        <span className="game-timer">
          <IconClock size={13} /> {elapsed} с
        </span>
      </div>

      <div className={`spark-answers ${stage === 'show' ? 'is-idle' : ''}`}>
        <span className="spark-answers__label">
          {stage === 'show' ? 'Сколько искр вспыхнуло?' : 'Сколько искр было?'}
        </span>
        <div className="spark-answers__grid">
          {round.options.map((option) => {
            const isRight = option === round.total
            const state =
              stage === 'reveal' && isRight
                ? 'is-right'
                : stage === 'reveal' && picked === option
                  ? 'is-wrong'
                  : ''
            return (
              <button
                key={option}
                className={`spark-answer ${state}`}
                onClick={() => answer(option)}
                disabled={stage !== 'answer'}
              >
                {option}
                {stage === 'reveal' && isRight && (
                  <span className="spark-answer__ok">
                    <IconCheck size={12} />
                  </span>
                )}
              </button>
            )
          })}
        </div>
      </div>

      <p className="game-tip">
        {stage === 'show'
          ? 'Считайте про себя каждую вспышку — искры гаснут через несколько секунд'
          : stage === 'reveal'
            ? picked === round.total
              ? 'Точно! Внимание — ваша суперсила'
              : `Было ${round.total} ${plural(round.total, 'искра', 'искры', 'искр')}. В следующий раз считайте по группам`
            : 'Выберите число искр, которые успели вспыхнуть'}
      </p>
    </div>
  )
}
