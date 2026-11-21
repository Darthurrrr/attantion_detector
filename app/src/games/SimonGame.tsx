import { useCallback, useEffect, useRef, useState } from 'react'
import { LEVEL_BY_ID } from '../game/data'
import { playSound, playTone } from '../game/audio'
import { clamp, type GameProps } from './types'

const PADS = [
  { id: 0, color: '#ff8fc4', glow: '#ffd0e6', freq: 392, label: 'розовый' },
  { id: 1, color: '#6fc9ff', glow: '#c9efff', freq: 523, label: 'синий' },
  { id: 2, color: '#8ff0a8', glow: '#d6ffdf', freq: 659, label: 'зелёный' },
  { id: 3, color: '#ffcf5a', glow: '#fff1bb', freq: 784, label: 'золотой' },
]

type Phase = 'watch' | 'input' | 'success' | 'fail'

export default function SimonGame({ levelId, onFinish }: GameProps) {
  const level = LEVEL_BY_ID[levelId]
  const targetLen = level.seq ?? 4
  const [sequence, setSequence] = useState<number[]>(() =>
    Array.from({ length: 3 }, () => Math.floor(Math.random() * 4)),
  )
  const [phase, setPhase] = useState<Phase>('watch')
  const [activePad, setActivePad] = useState<number | null>(null)
  const [inputIndex, setInputIndex] = useState(0)
  const [mistakes, setMistakes] = useState(0)
  const [status, setStatus] = useState('Смотрите на кристаллы…')
  const timers = useRef<number[]>([])
  const finished = useRef(false)
  const mistakesRef = useRef(0)

  const clearTimers = useCallback(() => {
    timers.current.forEach((id) => window.clearTimeout(id))
    timers.current = []
  }, [])

  const playSequence = useCallback(
    (seqToPlay: number[]) => {
      clearTimers()
      setPhase('watch')
      setInputIndex(0)
      setStatus('Смотрите на кристаллы…')
      const startDelay = 500
      const step = 560
      seqToPlay.forEach((pad, index) => {
        timers.current.push(
          window.setTimeout(() => {
            setActivePad(pad)
            playTone(PADS[pad].freq, 0.32, 'triangle', 0.16)
            timers.current.push(
              window.setTimeout(() => {
                setActivePad(null)
                if (index === seqToPlay.length - 1) {
                  timers.current.push(
                    window.setTimeout(() => {
                      setPhase('input')
                      setStatus('Повторите мелодию!')
                    }, 260),
                  )
                }
              }, 330),
            )
          }, startDelay + index * step),
        )
      })
    },
    [clearTimers],
  )

  useEffect(() => {
    playSequence(sequence)
    return clearTimers
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const finish = useCallback(
    (finalMistakes: number) => {
      if (finished.current) return
      finished.current = true
      const score = Math.round(clamp(100 - finalMistakes * 12))
      playSound('success')
      window.setTimeout(() => onFinish(score, 0), 700)
    },
    [onFinish],
  )

  const press = (pad: number) => {
    if (phase !== 'input' || finished.current) return
    setActivePad(pad)
    playTone(PADS[pad].freq, 0.24, 'triangle', 0.16)
    window.setTimeout(() => setActivePad(null), 220)

    if (sequence[inputIndex] !== pad) {
      const nextMistakes = mistakesRef.current + 1
      mistakesRef.current = nextMistakes
      setMistakes(nextMistakes)
      setPhase('fail')
      setStatus('Ой! Смотрите ещё раз')
      playSound('tap', 0.4)
      clearTimers()
      timers.current.push(
        window.setTimeout(() => {
          playSequence(sequence)
        }, 900),
      )
      return
    }

    const nextIndex = inputIndex + 1
    setInputIndex(nextIndex)
    if (nextIndex === sequence.length) {
      if (sequence.length >= targetLen) {
        setPhase('success')
        setStatus('Идеально! Мелодия покорена')
        finish(mistakesRef.current)
        return
      }
      setPhase('success')
      setStatus('Отлично! Новая мелодия…')
      clearTimers()
      timers.current.push(
        window.setTimeout(() => {
          const grown = [...sequence, Math.floor(Math.random() * 4)]
          setSequence(grown)
          playSequence(grown)
        }, 900),
      )
    }
  }

  return (
    <div className="game simon-game">
      <div className="game-stats">
        <span className="game-stat">
          <span className="game-stat__label">Длина</span>
          <b>{sequence.length}</b>
        </span>
        <span className="game-stat game-stat--center">
          <span className="game-stat__label">Прогресс</span>
          <b>
            {sequence.length - 2} / {targetLen - 2}
          </b>
        </span>
        <span className="game-stat">
          <span className="game-stat__label">Ошибки</span>
          <b className={mistakes > 0 ? 'is-warn' : ''}>{mistakes}</b>
        </span>
      </div>

      <p className={`simon-status simon-status--${phase}`}>{status}</p>

      <div className="simon-board">
        <div className="simon-board__aura" />
        {PADS.map((pad) => (
          <button
            key={pad.id}
            className={`simon-pad ${activePad === pad.id ? 'is-active' : ''} ${phase === 'fail' ? 'is-fail' : ''}`}
            style={{ ['--pad-color' as string]: pad.color, ['--pad-glow' as string]: pad.glow }}
            onClick={() => press(pad.id)}
            aria-label={`Кристалл ${pad.label}`}
            disabled={phase !== 'input'}
          >
            <span className="simon-pad__facet" />
            <span className="simon-pad__shine" />
            <span className="simon-pad__glyph">◆</span>
          </button>
        ))}
        <div className="simon-board__center">
          <span className="simon-board__glyph">
            {phase === 'watch' ? '◉' : phase === 'input' ? '◆' : phase === 'fail' ? '!' : '★'}
          </span>
        </div>
      </div>

      <div className="simon-dots">
        {sequence.map((_, i) => (
          <span key={i} className={i < inputIndex && phase === 'input' ? 'is-done' : ''} />
        ))}
      </div>

      <p className="game-tip">Повторите последовательность кристаллов. Ошибки можно исправить!</p>
    </div>
  )
}
