import { useEffect, useMemo, useState } from 'react'
import { useGame } from '../game/store'
import { PETS, RARITY, SUMMON_POOL } from '../game/data'
import { Btn, Coin, Confetti, Gem, HintIcon, Modal, Progress, ResPill, ScreenHeader } from '../components/ui'
import SceneLayers from '../components/SceneLayers'
import { IconBook, IconEgg, IconInfo, IconPaw, IconSparkle, IconTrophy } from '../components/Icon'
import { playSound } from '../game/audio'
import type { SummonResult } from '../game/types'

const EGG_STAGES = ['/assets/ui/egg_0.png', '/assets/ui/egg_2.png', '/assets/ui/egg_4.png', '/assets/ui/egg_6.png', '/assets/ui/egg_8.png']

export default function Summon({ onBack, onShop }: { onBack: () => void; onShop: () => void }) {
  const { state, summon, ownedCount } = useGame()
  const [outcome, setOutcome] = useState<{ results: SummonResult[]; pity: boolean; spent: number } | null>(null)
  const [revealStep, setRevealStep] = useState(0)
  const [revealed, setRevealed] = useState(false)
  const [showRules, setShowRules] = useState(false)
  const [showHistory, setShowHistory] = useState(false)

  const pityEpic = Math.min(5, state.pity.epic)
  const pityLegend = Math.min(10, state.pity.legendary)
  const totalPets = PETS.length
  const bestResult = useMemo(
    () => (outcome ? outcome.results.reduce((a, b) => (RARITY[b.pet.rarity].order > RARITY[a.pet.rarity].order ? b : a), outcome.results[0]) : null),
    [outcome],
  )

  useEffect(() => {
    if (!outcome) return
    setRevealStep(0)
    setRevealed(false)
    const timers: number[] = []
    ;[1, 2, 3, 4].forEach((step, index) => {
      timers.push(
        window.setTimeout(() => {
          setRevealStep(step)
          playSound('tap', 0.55)
        }, 380 + index * 340),
      )
    })
    timers.push(
      window.setTimeout(() => {
        setRevealed(true)
        playSound(bestResult && RARITY[bestResult.pet.rarity].order >= 3 ? 'success' : 'reward')
      }, 2050),
    )
    return () => timers.forEach((t) => window.clearTimeout(t))
  }, [outcome, bestResult])

  const doSummon = (count: 1 | 5) => {
    const result = summon(count)
    if (!result) return
    setOutcome({ results: result.results, pity: result.pity, spent: result.spent })
  }

  const skip = () => {
    if (!outcome || revealed) return
    setRevealStep(4)
    setRevealed(true)
    playSound('reward')
  }

  const close = () => {
    setOutcome(null)
    setRevealed(false)
    setRevealStep(0)
  }

  const legendaryChance = RARITY.legendary.weight
  const epicChance = RARITY.epic.weight

  return (
    <div className="screen summon">
      <SceneLayers scene="summon" />
      <div className="summon-shade" />
      <div className="sparkles" aria-hidden>
        <i style={{ left: '18%', top: '26%' }} />
        <i style={{ left: '76%', top: '20%', animationDelay: '1.4s' }} />
        <i style={{ left: '63%', top: '52%', animationDelay: '2.1s' }} />
        <i style={{ left: '26%', top: '62%', animationDelay: '0.8s' }} />
      </div>

      <ScreenHeader
        title="Призыв"
        onBack={onBack}
        right={
          <>
            <ResPill type="gem" amount={state.gems} onAdd={onShop} compact />
            <button className="summon-info-btn" onClick={() => setShowRules(true)} aria-label="Правила призыва">
              <IconInfo size={18} />
            </button>
          </>
        }
      />

      <div className="summon-pity">
        <button className="pity-card" onClick={() => setShowRules(true)}>
          <span className="pity-card__icon"><IconTrophy size={15} /></span>
          <span className="pity-card__text">
            <b>
              {pityEpic}/5
            </b>
            <span>Эпический гарант</span>
          </span>
          <span className="pity-card__bar">
            <Progress value={pityEpic} max={5} tone="purple" height={5} />
          </span>
        </button>
        <button className="pity-card pity-card--legend" onClick={() => setShowRules(true)}>
          <span className="pity-card__icon"><Gem size={15} /></span>
          <span className="pity-card__text">
            <b>
              {pityLegend}/10
            </b>
            <span>Легендарный гарант</span>
          </span>
          <span className="pity-card__bar">
            <Progress value={pityLegend} max={10} tone="gold" height={5} />
          </span>
        </button>
      </div>

      <div className="summon-stage">
        <div className="summon-egg">
          <span className="summon-egg__aura" />
          <span className="summon-egg__beams" aria-hidden />
          <span className="summon-crystal summon-crystal--left" aria-hidden="true">
            <img src="/assets/layers/summon_crystals.png" alt="" draggable={false} />
          </span>
          <span className="summon-crystal summon-crystal--right" aria-hidden="true">
            <img src="/assets/layers/summon_crystals.png" alt="" draggable={false} />
          </span>
          <img className="summon-egg__image" src="/assets/ui/egg_0.png" alt="Магическое яйцо" draggable={false} />
          <span className="summon-egg__mark" aria-hidden>
            <IconPaw size={64} />
          </span>
          <span className="summon-egg__pedestal" />
        </div>
        <div className="summon-caption">
          <span className="summon-caption__title">Яйцо внимания</span>
          <span className="summon-caption__sub">
            Открыто {ownedCount} из {totalPets}
          </span>
        </div>
      </div>

      <div className="summon-bottom">
        <div className="summon-buttons">
          <Btn variant="gold" size="lg" onClick={() => doSummon(1)} className="summon-btn">
            <span className="summon-btn__main">Открыть 1</span>
            <span className="summon-btn__cost">
              <Gem size={18} /> 60
            </span>
          </Btn>
          <Btn variant="gold" size="lg" onClick={() => doSummon(5)} className="summon-btn summon-btn--five">
            <span className="summon-btn__main">Открыть 5</span>
            <span className="summon-btn__cost">
              <Gem size={18} /> 300
            </span>
            <span className="summon-btn__save">−20%</span>
          </Btn>
        </div>
        <div className="summon-links">
          <button className="summon-link" onClick={() => setShowHistory(true)}>
            <IconBook size={15} /> История
          </button>
          <span className="summon-chance">
            <IconEgg size={14} /> Эпик {epicChance}% · Легенда {legendaryChance}%
          </span>
          <button className="summon-link" onClick={() => setShowRules(true)}>
            <IconSparkle size={14} /> Правила
          </button>
        </div>
      </div>

      {outcome && (
        <div className={`reveal ${revealed ? 'is-revealed' : ''}`}>
          <div className="reveal__bg" />
          {!revealed && (
            <button className="reveal__skip" onClick={skip}>
              Пропустить ›
            </button>
          )}
          {!revealed ? (
            <div className="reveal-egg">
              <span className="reveal-egg__rays" />
              <div className={`reveal-egg__img stage-${revealStep}`} key={revealStep}>
                <img src={EGG_STAGES[Math.min(4, revealStep)]} alt="" draggable={false} />
              </div>
              <p className="reveal-egg__text">Яйцо наполняется вниманием…</p>
            </div>
          ) : (
            <>
              <Confetti active={!!bestResult && RARITY[bestResult.pet.rarity].order >= 3} pieces={46} />
              <div className="reveal-title">
                {outcome.pity ? 'Гарант сработал!' : bestResult && RARITY[bestResult.pet.rarity].order >= 3 ? 'Невероятная удача!' : 'Новые друзья!'}
              </div>
              <div className={`reveal-cards ${outcome.results.length > 1 ? 'reveal-cards--many' : 'reveal-cards--one'}`}>
                {outcome.results.map((res, index) => {
                  const r = RARITY[res.pet.rarity]
                  return (
                    <div
                      key={`${res.pet.id}-${index}`}
                      className={`summon-card ${outcome.results.length > 1 ? 'summon-card--small' : ''}`}
                      style={{ ['--rarity' as string]: r.color, ['--rarity-dark' as string]: r.dark, animationDelay: `${index * 0.12}s` }}
                    >
                      <span className="summon-card__frame" />
                      <span className="summon-card__glow" />
                      <span className="summon-card__rarity">{r.label}</span>
                      <img src={res.pet.img} alt={res.pet.name} className="summon-card__img" draggable={false} />
                      <span className="summon-card__name">{res.pet.name}</span>
                      {res.isNew ? (
                        <span className="summon-card__badge summon-card__badge--new">Новый!</span>
                      ) : (
                        <span className="summon-card__badge">
                          <Coin size={12} /> +{res.coins}
                        </span>
                      )}
                    </div>
                  )
                })}
              </div>
              <div className="reveal-actions">
                <Btn variant="gold" size="lg" onClick={close}>
                  {outcome.results.length > 1 ? 'Забрать всех' : 'Забрать'}
                </Btn>
                <Btn
                  variant="ghost"
                  size="md"
                  onClick={() => {
                    close()
                    doSummon(outcome.results.length > 1 ? 5 : 1)
                  }}
                  disabled={state.gems < (outcome.results.length > 1 ? 300 : 60)}
                >
                  Ещё раз
                </Btn>
              </div>
            </>
          )}
        </div>
      )}

      <Modal open={showRules} onClose={() => setShowRules(false)}>
        <h3 className="modal-title">Правила призыва</h3>
        <p className="modal-sub">Кристаллы открывают яйца внимания. Внутри — питомцы разной редкости.</p>
        <div className="rules-list">
          {(Object.keys(RARITY) as Array<keyof typeof RARITY>)
            .sort((a, b) => RARITY[b].order - RARITY[a].order)
            .map((r) => (
              <div key={r} className="rules-row">
                <span className="rules-dot" style={{ background: RARITY[r].color }} />
                <span className="rules-name">{RARITY[r].label}</span>
                <span className="rules-chance">{RARITY[r].weight}%</span>
              </div>
            ))}
        </div>
        <div className="hint" style={{ marginTop: 12 }}>
          <HintIcon />
          <span>
            Каждый 5-й призыв гарантирует эпического питомца, каждый 10-й — легендарного. Повторный питомец превращается в
            монеты и кристаллы.
          </span>
        </div>
        <div className="hint" style={{ marginTop: 8 }}>
          <HintIcon />
          <span>Стоимость: 60 кристаллов за 1 призыв или 300 за 5 (скидка 20%).</span>
        </div>
      </Modal>

      <Modal open={showHistory} onClose={() => setShowHistory(false)}>
        <h3 className="modal-title">История призывов</h3>
        {state.history.length === 0 ? (
          <p className="modal-sub">Пока пусто. Откройте первое яйцо!</p>
        ) : (
          <div className="history-list">
            {state.history.slice(0, 12).map((rec, i) => {
              const pet = SUMMON_POOL.find((p) => p.id === rec.petId)
              if (!pet) return null
              return (
                <div key={i} className="history-row">
                  <span className="history-row__img" style={{ borderColor: RARITY[rec.rarity].color }}>
                    <img src={pet.img} alt="" />
                  </span>
                  <span className="history-row__name">
                    {pet.name}
                    <small style={{ color: RARITY[rec.rarity].color }}>{RARITY[rec.rarity].label}</small>
                  </span>
                  <span className={`history-row__tag ${rec.isNew ? 'is-new' : ''}`}>{rec.isNew ? 'Новый' : 'Повтор'}</span>
                </div>
              )
            })}
          </div>
        )}
      </Modal>
    </div>
  )
}
