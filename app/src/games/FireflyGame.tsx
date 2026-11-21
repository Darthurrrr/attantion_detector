import { useCallback, useEffect, useRef, useState } from 'react'
import { LEVEL_BY_ID } from '../game/data'
import { playSound } from '../game/audio'
import { clamp, type GameProps } from './types'

type Entity = { id: number; kind: 'gold' | 'decoy'; x: number; y: number; size: number; drift: number }
type Burst = { id: number; x: number; y: number }

let seq = 1

function spawn(kind: Entity['kind'], taken: Entity[]): Entity {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const x = 9 + Math.random() * 82
    const y = 12 + Math.random() * 76
    const tooClose = taken.some((e) => Math.hypot(e.x - x, e.y - y) < 14)
    if (!tooClose) {
      return {
        id: seq++,
        kind,
        x,
        y,
        size: kind === 'gold' ? 48 + Math.random() * 16 : 34 + Math.random() * 8,
        drift: Math.random() * 4,
      }
    }
  }
  return { id: seq++, kind, x: 20 + Math.random() * 60, y: 20 + Math.random() * 60, size: 46, drift: 1 }
}

export default function FireflyGame({ levelId, onFinish }: GameProps) {
  const level = LEVEL_BY_ID[levelId]
  const targets = level.targets ?? 6
  const totalTime = level.time ?? 24
  const [entities, setEntities] = useState<Entity[]>(() => {
    const list: Entity[] = []
    for (let i = 0; i < Math.min(5, targets); i += 1) list.push(spawn('gold', list))
    for (let i = 0; i < 3; i += 1) list.push(spawn('decoy', list))
    return list
  })
  const [caught, setCaught] = useState(0)
  const [mistakes, setMistakes] = useState(0)
  const [timeLeft, setTimeLeft] = useState(totalTime)
  const [bursts, setBursts] = useState<Burst[]>([])
  const [flash, setFlash] = useState<'good' | 'bad' | null>(null)
  const caughtRef = useRef(0)
  const mistakesRef = useRef(0)
  const finished = useRef(false)

  const finish = useCallback(
    (finalCaught: number, finalMistakes: number) => {
      if (finished.current) return
      finished.current = true
      const score = Math.round(clamp((100 * finalCaught) / targets - finalMistakes * 7))
      playSound(finalCaught >= targets ? 'success' : 'transition')
      window.setTimeout(() => onFinish(score, 0), 650)
    },
    [onFinish, targets],
  )

  useEffect(() => {
    if (finished.current) return
    const id = window.setInterval(() => {
      setEntities((list) =>
        list.map((e) => ({
          ...e,
          x: Math.max(9, Math.min(91, e.x + (Math.random() - 0.5) * 22)),
          y: Math.max(12, Math.min(84, e.y + (Math.random() - 0.5) * 18)),
        })),
      )
    }, 1400)
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    if (finished.current) return
    const id = window.setInterval(() => {
      setTimeLeft((t) => {
        if (t <= 1) {
          window.clearInterval(id)
          finish(caughtRef.current, mistakesRef.current)
          return 0
        }
        return t - 1
      })
    }, 1000)
    return () => window.clearInterval(id)
  }, [finish])

  useEffect(() => {
    if (!bursts.length) return
    const id = window.setTimeout(() => setBursts((list) => list.slice(1)), 650)
    return () => window.clearTimeout(id)
  }, [bursts])

  useEffect(() => {
    if (!flash) return
    const id = window.setTimeout(() => setFlash(null), 260)
    return () => window.clearTimeout(id)
  }, [flash])

  const tap = (entity: Entity) => {
    if (finished.current) return
    if (entity.kind === 'gold') {
      const next = caughtRef.current + 1
      caughtRef.current = next
      setCaught(next)
      setEntities((list) => {
        const rest = list.filter((e) => e.id !== entity.id)
        if (next < targets) {
          const goldOnField = rest.filter((e) => e.kind === 'gold').length
          if (goldOnField < Math.min(5, targets - next)) {
            rest.push(spawn('gold', rest))
          }
        }
        return rest
      })
      setBursts((list) => [...list, { id: entity.id, x: entity.x, y: entity.y }])
      setFlash('good')
      playSound('reward', 0.55)
      if (next >= targets) finish(next, mistakesRef.current)
    } else {
      const nextMistakes = mistakesRef.current + 1
      mistakesRef.current = nextMistakes
      setMistakes(nextMistakes)
      setEntities((list) =>
        list.map((e) =>
          e.id === entity.id
            ? { ...e, x: Math.max(9, Math.min(91, e.x + (Math.random() - 0.5) * 40)), y: Math.max(12, Math.min(84, e.y + 14)) }
            : e,
        ),
      )
      setFlash('bad')
      playSound('tap', 0.35)
    }
  }

  return (
    <div className={`game firefly-game ${flash ? `flash-${flash}` : ''}`}>
      <div className="game-stats">
        <span className="game-stat">
          <span className="game-stat__label">Поймано</span>
          <b>
            {caught} / {targets}
          </b>
        </span>
        <span className="game-stat game-stat--center">
          <span className="game-stat__label">Время</span>
          <b className={timeLeft <= 7 ? 'is-warn' : ''}>{timeLeft} с</b>
        </span>
        <span className="game-stat">
          <span className="game-stat__label">Ошибки</span>
          <b className={mistakes > 0 ? 'is-warn' : ''}>{mistakes}</b>
        </span>
      </div>

      <div className="firefly-timer">
        <span style={{ width: `${(timeLeft / totalTime) * 100}%` }} />
      </div>

      <div className="firefly-field">
        <div className="firefly-field__glow" />
        <div className="firefly-field__grass" />
        {entities.map((e) => (
          <button
            key={e.id}
            className={`firefly firefly--${e.kind}`}
            style={{
              left: `${e.x}%`,
              top: `${e.y}%`,
              width: e.size,
              height: e.size,
              animationDelay: `${e.drift}s`,
            }}
            onClick={() => tap(e)}
            aria-label={e.kind === 'gold' ? 'Золотой светлячок' : 'Обманка'}
          >
            <span className="firefly__core" />
            <span className="firefly__halo" />
            {e.kind === 'gold' && <span className="firefly__star">✦</span>}
          </button>
        ))}
        {bursts.map((b) => (
          <span key={b.id} className="firefly-burst" style={{ left: `${b.x}%`, top: `${b.y}%` }}>
            ✦
          </span>
        ))}
      </div>

      <p className="game-tip">Ловите только золотых светлячков. Фиолетовые — обманки!</p>
    </div>
  )
}
