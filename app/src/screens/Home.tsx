import { useMemo, useState } from 'react'
import { useGame, xpNeeded } from '../game/store'
import { DAILY_TASKS, HERO_STAGES, LEVELS, LEVEL_BY_ID, PET_BY_ID, PET_LINES } from '../game/data'
import { Btn, Countdown, HeartIcon, IconButton, Progress, ResPill, StarImg } from '../components/ui'
import SceneLayers from '../components/SceneLayers'
import {
  IconGear,
  IconMap,
  IconPlay,
  IconMute,
  IconSound,
  IconSparkle,
  IconTrophy,
} from '../components/Icon'
import { haptic, playSound } from '../game/audio'
import type { Screen } from '../game/types'

type Props = {
  go: (screen: Screen) => void
  openTasks: () => void
  openEvents: () => void
  openDaily: () => void
  openShop: (tab: 'coin' | 'gem') => void
  openSettings: () => void
  onStart: (level: number) => void
}

export default function Home({ go, openTasks, openEvents, openDaily, openShop, openSettings, onStart }: Props) {
  const { state, nextLevel, totalStars, canClaimDaily, taskProgress, toggleSound } = useGame()
  const [lineIndex, setLineIndex] = useState(() => Math.floor(Math.random() * PET_LINES.length))
  const [hearts, setHearts] = useState<{ id: number; x: number }[]>([])

  const pet = PET_BY_ID[state.favorite] ?? PET_BY_ID.murzik
  const heroImg = pet.id === 'murzik' ? HERO_STAGES[state.heroStage].img : pet.img
  const clearedCount = Object.keys(state.progress).length
  const xpMax = xpNeeded(state.playerLevel)
  const nextDef = LEVEL_BY_ID[nextLevel]
  const claimableTasks = useMemo(
    () =>
      DAILY_TASKS.filter((t) => !state.tasks.claims.includes(t.id) && taskProgress(t.metric) >= t.goal).length,
    [state.tasks.claims, state.tasks.games, state.tasks.pairs, state.tasks.summons, state.tasks.stars, taskProgress],
  )
  const eventReady = state.tasks.games >= 5 && !state.event.claimed

  const petTheCat = () => {
    setLineIndex((i) => (i + 1) % PET_LINES.length)
    playSound('cuddle', 0.8)
    haptic(10)
    const id = Date.now()
    setHearts((list) => [...list.slice(-5), { id, x: 40 + Math.random() * 45 }])
    window.setTimeout(() => setHearts((list) => list.filter((h) => h.id !== id)), 1200)
  }

  const openLevel = () => {
    playSound('transition')
    onStart(nextLevel)
  }

  return (
    <div className="screen home">
      <SceneLayers scene="home" />
      <div className="scrim-top" />
      <div className="scrim-bottom" />

      <div className="sparkles" aria-hidden>
        <i style={{ left: '12%', top: '22%', animationDelay: '0.2s' }} />
        <i style={{ left: '84%', top: '31%', animationDelay: '1.1s' }} />
        <i style={{ left: '70%', top: '12%', animationDelay: '2.2s' }} />
        <i style={{ left: '28%', top: '9%', animationDelay: '1.7s' }} />
        <i style={{ left: '92%', top: '58%', animationDelay: '0.7s' }} />
      </div>

      <div className="home-hud">
        <button className="profile" onClick={openSettings} aria-label="Профиль и настройки">
          <span className="profile__ring">
            <img src={pet.id === 'murzik' ? '/assets/hero_avatar.png' : pet.img} alt="" />
            <span className="profile__level">{state.playerLevel}</span>
          </span>
          <span className="profile__meta">
            <span className="profile__name">{state.name}</span>
            <span className="profile__xp">
              <Progress value={state.xp} max={xpMax} tone="gold" height={9} />
            </span>
            <span className="profile__xp-label">
              {state.xp} / {xpMax} XP
            </span>
          </span>
        </button>

        <div className="home-hud__res">
          <ResPill type="coin" amount={state.coins} onAdd={() => openShop('coin')} compact />
          <ResPill type="gem" amount={state.gems} onAdd={() => openShop('gem')} compact />
          <IconButton label="Настройки" onClick={openSettings} className="home-hud__gear">
            <IconGear size={20} />
          </IconButton>
        </div>
      </div>

      <nav className="rail" aria-label="Разделы">
        <button className={`rail__btn ${claimableTasks ? 'has-badge' : ''}`} onClick={openTasks}>
          <span className="rail__icon rail__icon--blue">
            <IconTrophy size={24} />
          </span>
          <span className="rail__label">Задания</span>
          {claimableTasks > 0 && <span className="rail__badge">{claimableTasks}</span>}
        </button>
        <button className={`rail__btn ${eventReady ? 'has-badge' : ''}`} onClick={openEvents}>
          <span className="rail__icon rail__icon--pink">
            <img src="/assets/ui/star.png" alt="" className="rail__art" draggable={false} />
          </span>
          <span className="rail__label">События</span>
          {eventReady && <span className="rail__dot" />}
        </button>
        <button className="rail__btn" onClick={() => go('collection')}>
          <span className="rail__icon rail__icon--mint">
            <img src="/assets/pets/bunny.png" alt="" className="rail__art" draggable={false} />
          </span>
          <span className="rail__label">Коллекция</span>
        </button>
        <button className="rail__btn" onClick={() => go('summon')}>
          <span className="rail__icon rail__icon--violet">
            <img src="/assets/ui/egg_0.png" alt="" className="rail__egg" draggable={false} />
          </span>
          <span className="rail__label">Призыв</span>
        </button>
      </nav>

      <button className={`daily-card ${canClaimDaily ? 'is-ready' : ''}`} onClick={openDaily}>
        <span className="daily-card__art">
          <img src="/assets/ui/chest.png" alt="" draggable={false} />
        </span>
        <span className="daily-card__title">Ежедневная награда</span>
        {canClaimDaily ? (
          <span className="daily-card__ready">
            <IconSparkle size={12} /> Забрать
          </span>
        ) : (
          <span className="daily-card__timer">
            <Countdown to={state.daily.last + 24 * 60 * 60 * 1000} />
          </span>
        )}
      </button>

      <div className="home-hero">
        <div className="speech" key={lineIndex}>
          <span>{PET_LINES[lineIndex]}</span>
          <i>
            <HeartIcon size={13} />
          </i>
        </div>
        <button className="home-hero__pet" onClick={petTheCat} aria-label="Погладить питомца">
          <span className="home-hero__glow" />
          <img src={heroImg} alt={pet.name} draggable={false} />
          <span className="home-hero__shadow" />
        </button>
        <div className="home-hero__foreground" aria-hidden="true">
          <img className="home-hero__plants home-hero__plants--left" src="/assets/layers/meadow_foreground.png" alt="" draggable={false} />
          <img className="home-hero__plants home-hero__plants--right" src="/assets/layers/meadow_foreground.png" alt="" draggable={false} />
        </div>
        {hearts.map((h) => (
          <span key={h.id} className="heart-pop" style={{ left: `${h.x}%` }}>
            <HeartIcon size={26} />
          </span>
        ))}
      </div>

      <div className="home-panel">
        <button className="chapter" onClick={() => go('map')} aria-label="Открыть карту уровней">
          <span className="chapter__top">
            <span className="chapter__star">
              <StarImg size={17} />
            </span>
            <span className="chapter__name">Глава 1</span>
            <span className="chapter__stars">
              {totalStars}/{LEVELS.length * 3}
            </span>
            <IconMap size={15} className="chapter__mapicon" />
          </span>
          <span className="chapter__bar">
            <Progress value={clearedCount} max={LEVELS.length} height={10} />
          </span>
          <span className="chapter__bottom">
            <span className="chapter__done">
              Пройдено {clearedCount}/{LEVELS.length}
            </span>
            <span className="chapter__next">
              Ур. {nextLevel} · {nextDef.name}
            </span>
          </span>
        </button>

        <Btn variant="gold" size="lg" className="home-play" onClick={openLevel}>
          <IconPlay size={22} />
          Начать
        </Btn>
      </div>

      <button className="sound-fab" onClick={toggleSound} aria-label={state.settings.sound ? 'Выключить звук' : 'Включить звук'}>
        {state.settings.sound ? <IconSound size={18} /> : <IconMute size={18} />}
      </button>
    </div>
  )
}
