import { useEffect, useMemo, useRef, useState } from 'react'
import { useGame } from '../game/store'
import { CHAPTER, LEVELS, LEVEL_BY_ID, TYPE_INFO } from '../game/data'
import { Btn, Coin, Gem, HintIcon, Modal, Progress, ScreenHeader, StarImg, StarsRow } from '../components/ui'
import { IconCheck, IconGift, IconLock, IconPlay, IconSparkle, IconTrophy } from '../components/Icon'
import SceneBanner from '../components/SceneBanner'
import { playSound } from '../game/audio'

const NODES = [
  { x: 27, y: 210 },
  { x: 63, y: 300 },
  { x: 35, y: 410 },
  { x: 71, y: 512 },
  { x: 39, y: 618 },
  { x: 23, y: 730 },
  { x: 55, y: 815 },
  { x: 77, y: 918 },
  { x: 45, y: 1010 },
  { x: 24, y: 1110 },
  { x: 51, y: 1205 },
  { x: 72, y: 1308 },
  { x: 41, y: 1412 },
  { x: 29, y: 1540 },
  { x: 63, y: 1665 },
  { x: 40, y: 1780 },
  { x: 58, y: 1890 },
]

const MAP_HEIGHT = 2130

function buildPath() {
  let d = `M ${NODES[0].x} ${NODES[0].y}`
  for (let i = 1; i < NODES.length; i += 1) {
    const prev = NODES[i - 1]
    const cur = NODES[i]
    const mx = (prev.x + cur.x) / 2
    const my = (prev.y + cur.y) / 2
    d += ` Q ${prev.x} ${prev.y} ${mx} ${my}`
  }
  const last = NODES[NODES.length - 1]
  d += ` L ${last.x} ${last.y}`
  return d
}

export default function MapScreen({
  onBack,
  onPlay,
  onDaily,
}: {
  onBack: () => void
  onPlay: (level: number) => void
  onDaily: () => void
}) {
  const { state, totalStars, nextLevel, toast, canClaimDaily } = useGame()
  const [selected, setSelected] = useState<number | null>(null)
  const scrollRef = useRef<HTMLDivElement>(null)
  const pathD = useMemo(buildPath, [])
  const clearedCount = Object.keys(state.progress).length

  const nodeState = (id: number) => {
    if (state.progress[id]) return state.progress[id].stars >= 1 ? 'done' : 'done'
    if (id === nextLevel) return 'current'
    if (id === 1) return 'current'
    return 'locked'
  }

  useEffect(() => {
    const target = NODES[Math.max(0, nextLevel - 1)]
    const el = scrollRef.current
    if (!el || !target) return
    const t = window.setTimeout(() => {
      el.scrollTo({ top: Math.max(0, target.y - 330), behavior: 'smooth' })
    }, 200)
    return () => window.clearTimeout(t)
  }, [nextLevel])

  const handleNode = (id: number) => {
    const st = nodeState(id)
    if (st === 'locked') {
      const prev = id - 1
      toast(`Сначала пройдите уровень ${prev}`, 'bad', 'lock')
      playSound('tap', 0.5)
      return
    }
    playSound('tap', 0.8)
    setSelected(id)
  }

  const selectedDef = selected ? LEVEL_BY_ID[selected] : null
  const selectedResult = selected ? state.progress[selected] : undefined

  return (
    <div className="screen map">
      <div className="bg-layer bg-layer--map" />
      <div className="scrim-top" />

      <ScreenHeader
        title="Карта уровней"
        onBack={onBack}
        right={
          <>
            <span className="hud-star">
              <StarImg size={19} />
              <b>
                {totalStars}/{LEVELS.length * 3}
              </b>
            </span>
            <button className={`map-gift ${canClaimDaily ? 'is-ready' : ''}`} onClick={onDaily} aria-label="Ежедневная награда">
              <IconGift size={20} />
            </button>
          </>
        }
      />

      <div className="map-scroll" ref={scrollRef}>
        <div className="map-content" style={{ height: MAP_HEIGHT }}>
          <svg className="map-path" viewBox={`0 0 100 ${MAP_HEIGHT}`} preserveAspectRatio="none" aria-hidden>
            <path d={pathD} className="map-path__under" vectorEffect="non-scaling-stroke" />
            <path d={pathD} className="map-path__dashes" vectorEffect="non-scaling-stroke" />
          </svg>

          {LEVELS.map((level, index) => {
            const pos = NODES[index]
            const st = nodeState(level.id)
            const result = state.progress[level.id]
            return (
              <button
                key={level.id}
                className={`map-node map-node--${st}`}
                style={{ left: `${pos.x}%`, top: pos.y }}
                onClick={() => handleNode(level.id)}
                aria-label={`Уровень ${level.id}: ${level.name}`}
              >
                {st === 'current' && (
                  <span className="map-node__hero">
                    <img src="/assets/hero_avatar.png" alt="" />
                  </span>
                )}
                <span className="map-node__disc">
                  {st === 'locked' ? (
                    <IconLock size={20} />
                  ) : (
                    <>
                      <span className="map-node__num">{level.id}</span>
                      {st === 'done' && (
                        <span className="map-node__check">
                          <IconCheck size={10} />
                        </span>
                      )}
                    </>
                  )}
                </span>
                <span className="map-node__stars">
                  <StarsRow stars={result?.stars ?? 0} size={15} />
                </span>
                {st === 'current' && <span className="map-node__play">Играть</span>}
              </button>
            )
          })}

          <div className="map-finish" style={{ top: 2020 }}>
            <span className="map-finish__icon">
              <IconTrophy size={22} />
            </span>
            <span className="map-finish__title">Конец главы</span>
            <span className="map-finish__sub">
              {clearedCount}/{LEVELS.length} уровней · {totalStars}/{LEVELS.length * 3} звёзд
            </span>
          </div>
        </div>
      </div>

      <div className="map-footer">
        <span className="map-footer__crest" aria-hidden>
          <IconTrophy size={19} />
        </span>
        <div className="map-footer__center">
          <span className="map-footer__chapter">Глава {CHAPTER.id} · {CHAPTER.name}</span>
          <span className="map-footer__progress">
            <Progress value={clearedCount} max={LEVELS.length} height={8} />
            <b>
              {clearedCount}/{LEVELS.length}
            </b>
          </span>
        </div>
        <span className="map-footer__next">
          <IconLock size={13} /> {CHAPTER.next}
        </span>
      </div>

      <Modal open={selected !== null} onClose={() => setSelected(null)}>
        {selectedDef && (
          <div className="level-modal">
            <span className="level-modal__type" style={{ ['--type' as string]: TYPE_INFO[selectedDef.type].color }}>
              {TYPE_INFO[selectedDef.type].short}
            </span>
            <h3 className="level-modal__title">Уровень {selectedDef.id}</h3>
            <p className="level-modal__name">{selectedDef.name}</p>
            <SceneBanner scene="training" />
            <div className="level-modal__stars">
              <StarsRow stars={selectedResult?.stars ?? 0} size={34} />
            </div>
            <div className="level-modal__stats">
              <span>
                Лучший счёт: <b>{selectedResult?.best ?? 0}</b>
              </span>
              <span>
                Игр: <b>{selectedResult?.plays ?? 0}</b>
              </span>
            </div>
            <div className="hint">
              <HintIcon />
              <span>{selectedDef.tip}</span>
            </div>
            <div className="level-modal__reward">
              <span>Награда</span>
              <span className="level-modal__reward-items">
                <em><Coin size={13} /> {50 + selectedDef.id * 6}</em>
                <em><Gem size={14} /> 1–4</em>
                <em><IconSparkle size={13} /> XP</em>
              </span>
            </div>
            <Btn
              variant="gold"
              size="lg"
              full
              icon={<IconPlay size={20} />}
              onClick={() => {
                const id = selectedDef.id
                setSelected(null)
                onPlay(id)
              }}
            >
              {selectedResult ? 'Улучшить рекорд' : 'Играть'}
            </Btn>
          </div>
        )}
      </Modal>
    </div>
  )
}
