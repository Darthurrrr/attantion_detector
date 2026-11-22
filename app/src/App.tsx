import { useCallback, useEffect, useRef, useState } from 'react'
import { GameProvider, useGame } from './game/store'
import Home from './screens/Home'
import MapScreen from './screens/MapScreen'
import PlayScreen from './screens/PlayScreen'
import Summon from './screens/Summon'
import Collection from './screens/Collection'
import { DailyModal, EventsModal, SettingsModal, ShopModal, TasksModal } from './screens/Modals'
import { ToastLayer } from './components/ui'
import { IconSparkle } from './components/Icon'
import { playSound } from './game/audio'
import type { Screen } from './game/types'

type ModalName = 'tasks' | 'events' | 'daily' | 'shop' | 'settings' | null

const PRELOAD = [
  '/assets/bg/meadow_landscape.webp',
  '/assets/bg/meadow_portrait.webp',
  '/assets/bg/map.webp',
  '/assets/bg/summon_landscape.webp',
  '/assets/bg/summon_portrait.webp',
  '/assets/layers/floating_island.png',
  '/assets/layers/meadow_foreground.png',
  '/assets/layers/summon_crystals.png',
  '/assets/bg/collection.webp',
  '/assets/bg/cosmic.webp',
  '/assets/bg/splash.webp',
  '/assets/bg/cosmic_portrait.webp',
  '/assets/hero_cat.png',
  '/assets/hero_cat_cape.png',
  '/assets/hero_cat_armor.png',
  '/assets/hero_avatar.png',
  '/assets/ui/egg_0.png',
  '/assets/ui/gem.png',
  '/assets/ui/star.png',
]

function Splash({ onDone }: { onDone: () => void }) {
  const [progress, setProgress] = useState(8)
  const [ready, setReady] = useState(false)

  useEffect(() => {
    const id = window.setInterval(() => {
      setProgress((p) => Math.min(100, p + 7 + Math.random() * 11))
    }, 130)
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    if (progress < 100) return
    const t = window.setTimeout(() => setReady(true), 200)
    return () => window.clearTimeout(t)
  }, [progress])

  useEffect(() => {
    if (!ready) return
    const t = window.setTimeout(onDone, 1100)
    return () => window.clearTimeout(t)
  }, [ready, onDone])

  return (
    <div className="splash" onClick={onDone} role="button" tabIndex={0} onKeyDown={(e) => e.key === 'Enter' && onDone()}>
      <div className="splash__bg" />
      <div className="splash__veil" />
      <div className="splash__panel">
        <div className="splash__loader">
          <span style={{ width: `${progress}%` }} />
          <b>{Math.round(progress)}%</b>
        </div>
        <p className="splash__tip">
          <span className="splash__tip-icon">
            <IconSparkle size={13} />
          </span>
          Совет: проходите задания и открывайте новые миры внимания!
        </p>
        <span className={`splash__go ${ready ? 'is-ready' : ''}`}>
          {ready ? 'Нажмите, чтобы играть' : 'Загрузка мира Мурзика…'}
        </span>
      </div>
    </div>
  )
}

function Shell() {
  const { toast } = useGame()
  const [screen, setScreen] = useState<Screen>('home')
  const [playLevel, setPlayLevel] = useState(1)
  const [modal, setModal] = useState<ModalName>(null)
  const [shopTab, setShopTab] = useState<'coin' | 'gem'>('gem')
  const [splash, setSplash] = useState(true)
  const visited = useRef(false)

  useEffect(() => {
    PRELOAD.forEach((src) => {
      const img = new Image()
      img.src = src
    })
  }, [])

  useEffect(() => {
    if (splash) return
    if (!visited.current) {
      visited.current = true
      toast('Добро пожаловать в мир внимания!', 'info', 'paw')
    }
  }, [splash, toast])

  const go = useCallback((next: Screen) => {
    setModal(null)
    setScreen(next)
    playSound('transition', 0.55)
  }, [])

  const openShop = useCallback((tab: 'coin' | 'gem') => {
    setShopTab(tab)
    setModal('shop')
  }, [])

  const startLevel = useCallback((level: number) => {
    setPlayLevel(level)
    setScreen('play')
    setModal(null)
  }, [])

  return (
    <div className="app-shell">
      <div className="app-shell__halo" />
      <div className={`stage ${!splash && (screen === 'home' || screen === 'summon') ? 'stage--scene-wide' : ''}`}>
        {screen === 'home' && (
          <Home
            go={go}
            openTasks={() => setModal('tasks')}
            openEvents={() => setModal('events')}
            openDaily={() => setModal('daily')}
            openShop={openShop}
            openSettings={() => setModal('settings')}
            onStart={startLevel}
          />
        )}
        {screen === 'map' && (
          <MapScreen onBack={() => go('home')} onPlay={startLevel} onDaily={() => setModal('daily')} />
        )}
        {screen === 'play' && (
          <PlayScreen key={playLevel} levelId={playLevel} onExit={() => go('map')} onNext={startLevel} />
        )}
        {screen === 'summon' && <Summon onBack={() => go('home')} onShop={() => openShop('gem')} />}
        {screen === 'collection' && (
          <Collection onBack={() => go('home')} onSummon={() => go('summon')} />
        )}

        <ToastLayer />

        <TasksModal open={modal === 'tasks'} onClose={() => setModal(null)} />
        <EventsModal open={modal === 'events'} onClose={() => setModal(null)} onDaily={() => setModal('daily')} />
        <DailyModal open={modal === 'daily'} onClose={() => setModal(null)} />
        <ShopModal open={modal === 'shop'} onClose={() => setModal(null)} tab={shopTab} />
        <SettingsModal open={modal === 'settings'} onClose={() => setModal(null)} />

        {splash && <Splash onDone={() => setSplash(false)} />}
      </div>
    </div>
  )
}

export default function App() {
  return (
    <GameProvider>
      <Shell />
    </GameProvider>
  )
}
