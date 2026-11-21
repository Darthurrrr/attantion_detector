import { useEffect, useState } from 'react'
import { useGame } from '../game/store'
import { LEVELS, LEVEL_BY_ID, TYPE_INFO } from '../game/data'
import { Btn, Coin, Confetti, Gem, HintIcon, IconButton, Modal, Ribbon, StarImg } from '../components/ui'
import { IconSparkle, IconPaw } from '../components/Icon'
import { IconBack, IconClock, IconInfo, IconPlay, IconRefresh } from '../components/Icon'
import MatchGame from '../games/MatchGame'
import OddGame from '../games/OddGame'
import FireflyGame from '../games/FireflyGame'
import SimonGame from '../games/SimonGame'
import { starsFor } from '../games/types'
import { playSound } from '../game/audio'
import type { FinishReward } from '../game/store'

type Result = FinishReward & { score: number }

export default function PlayScreen({
  levelId,
  onExit,
  onNext,
}: {
  levelId: number
  onExit: () => void
  onNext: (level: number) => void
}) {
  const { finishLevel } = useGame()
  const level = LEVEL_BY_ID[levelId]
  const info = TYPE_INFO[level.type]
  const [phase, setPhase] = useState<'countdown' | 'playing' | 'result'>('countdown')
  const [count, setCount] = useState(3)
  const [attempt, setAttempt] = useState(0)
  const [result, setResult] = useState<Result | null>(null)
  const [confirmExit, setConfirmExit] = useState(false)
  const [showTip, setShowTip] = useState(false)

  useEffect(() => {
    setPhase('countdown')
    setCount(3)
    setResult(null)
    setAttempt((a) => a + 1)
  }, [levelId])

  useEffect(() => {
    if (phase !== 'countdown') return
    if (count === 0) {
      setPhase('playing')
      playSound('transition', 0.7)
      return
    }
    playSound('tap', 0.5)
    const id = window.setTimeout(() => setCount((c) => c - 1), 720)
    return () => window.clearTimeout(id)
  }, [phase, count])

  const handleFinish = (score: number, pairs: number) => {
    const stars = starsFor(score)
    const reward = finishLevel(levelId, score, stars, pairs)
    setResult({ ...reward, score })
    setPhase('result')
    playSound('success')
  }

  const restart = () => {
    setResult(null)
    setPhase('countdown')
    setCount(3)
    setAttempt((a) => a + 1)
  }

  const nextLevel = levelId < LEVELS.length ? levelId + 1 : null
  const passed = (result?.score ?? 0) >= 55

  return (
    <div className="screen play">
      <div className="bg-layer bg-layer--play" />
      <div className="play-overlay" />

      <header className="play-header">
        <IconButton label="Выйти" onClick={() => (phase === 'playing' ? setConfirmExit(true) : onExit())}>
          <IconBack size={20} />
        </IconButton>
        <div className="play-level">
          <span className="play-level__id">Уровень {level.id}</span>
          <span className="play-level__name">{level.name}</span>
        </div>
        <div className="play-header__right">
          <span className="chip" style={{ color: info.color }}>
            {info.label}
          </span>
          <IconButton label="Подсказка" tone="gold" onClick={() => setShowTip(true)} className="play-tip-btn">
            <IconInfo size={19} />
          </IconButton>
        </div>
      </header>

      <div className="play-body">
        <div className="game-banner">
          <span className="game-banner__badge" style={{ background: info.color }}>
            {info.short}
          </span>
          <span className="game-banner__text">{info.hint}</span>
        </div>

        {phase !== 'countdown' &&
          (level.type === 'match' ? (
            <MatchGame key={attempt} levelId={level.id} onFinish={handleFinish} />
          ) : level.type === 'odd' ? (
            <OddGame key={attempt} levelId={level.id} onFinish={handleFinish} />
          ) : level.type === 'firefly' ? (
            <FireflyGame key={attempt} levelId={level.id} onFinish={handleFinish} />
          ) : (
            <SimonGame key={attempt} levelId={level.id} onFinish={handleFinish} />
          ))}

        {phase === 'countdown' && (
          <div className="countdown-layer">
            <div className="countdown-card">
              <span className="countdown-card__type" style={{ background: info.color }}>
                {info.short}
              </span>
              <h2>{level.name}</h2>
              <p>{info.hint}</p>
              <div className="countdown-card__num" key={count}>
                {count > 0 ? count : 'GO'}
              </div>
              <span className="countdown-card__hint">Приготовьтесь…</span>
            </div>
          </div>
        )}
      </div>

      {phase === 'result' && result && (
        <div className="result-layer">
          <Confetti active={result.stars >= 2} pieces={result.stars === 3 ? 50 : 24} />
          <div className="result-card">
            <Ribbon tone="gold">{passed ? 'Уровень пройден!' : 'Почти получилось!'}</Ribbon>
            <div className="result-stars">
              {[0, 1, 2].map((i) => (
                <span
                  key={i}
                  className={`result-star ${i < result.stars ? 'is-on' : ''}`}
                  style={{ animationDelay: `${0.25 + i * 0.18}s` }}
                >
                  <StarImg size={58} filled={i < result.stars} />
                </span>
              ))}
            </div>
            <div className="result-score">
              <span>Счёт</span>
              <b>{result.score}</b>
              <span>из 100</span>
            </div>
            <div className="result-tags">
              {result.firstClear && <span className="result-tag result-tag--new">Новый уровень</span>}
              {result.newBest && !result.firstClear && <span className="result-tag">Новый рекорд</span>}
              {result.leveledUp && <span className="result-tag result-tag--level">Новый уровень героя!</span>}
            </div>
            <div className="result-rewards">
              <span className="result-reward">
                <Coin size={24} /> +{result.coins}
              </span>
              <span className="result-reward">
                <Gem size={24} /> +{result.gems}
              </span>
              <span className="result-reward result-reward--xp"><IconSparkle size={16} /> +{result.xp} XP</span>
            </div>
            {result.stars === 3 && <p className="result-praise"><IconPaw size={16} /> Идеальное внимание! Мурзик гордится вами</p>}
            <div className="result-actions">
              <Btn variant="ghost" size="md" icon={<IconRefresh size={18} />} onClick={restart}>
                Ещё раз
              </Btn>
              {nextLevel ? (
                <Btn variant="gold" size="md" icon={<IconPlay size={18} />} onClick={() => onNext(nextLevel)}>
                  Далее
                </Btn>
              ) : (
                <Btn variant="gold" size="md" onClick={onExit}>
                  На карту
                </Btn>
              )}
            </div>
            <button className="result-map-link" onClick={onExit}>
              Вернуться к карте уровней
            </button>
          </div>
        </div>
      )}

      <Modal open={confirmExit} onClose={() => setConfirmExit(false)}>
        <h3 className="modal-title">Выйти из уровня?</h3>
        <p className="modal-sub">Прогресс этой попытки не сохранится. Можно попробовать снова.</p>
        <div className="modal-actions">
          <Btn variant="ghost" full onClick={() => setConfirmExit(false)}>
            Остаться
          </Btn>
          <Btn variant="gold" full onClick={onExit}>
            Выйти
          </Btn>
        </div>
      </Modal>

      <Modal open={showTip} onClose={() => setShowTip(false)}>
        <h3 className="modal-title">Как играть</h3>
        <p className="modal-sub">{level.name}</p>
        <div className="hint">
          <HintIcon />
          <span>{level.tip}</span>
        </div>
        <div className="divider" />
        <p className="play-tip-text">
          {info.hint}. 80+ очков — три звезды, 55+ — две. За звёзды дают больше монет, кристаллов и опыта.
        </p>
        <div className="hint" style={{ marginTop: 10 }}>
          <IconClock size={18} />
          <span>Не спешите: точность важнее скорости, но быстрые ответы дают бонус.</span>
        </div>
      </Modal>
    </div>
  )
}
