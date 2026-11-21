import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import {
  DAILY_REWARDS,
  DAILY_TASKS,
  HERO_STAGES,
  LEVELS,
  PET_BY_ID,
  RARITY,
  SUMMON_POOL,
} from './data'
import type { GameState, Pet, Rarity, SummonRecord, SummonResult } from './types'
import { haptic, playSound, setSoundEnabled, setSoundVolume } from './audio'

const STORAGE_KEY = 'attention-detector-cat-v1'
const DAY = 24 * 60 * 60 * 1000

export type Toast = { id: number; text: string; tone: 'info' | 'good' | 'bad'; icon?: string }

export type FinishReward = {
  coins: number
  gems: number
  xp: number
  stars: number
  leveledUp: boolean
  newBest: boolean
  firstClear: boolean
}

export type ChestResult = { coins: number; gems: number; pet?: Pet; label: string }

export type SummonOutcome = { results: SummonResult[]; spent: number; pity: boolean }

type Store = {
  state: GameState
  toasts: Toast[]
  toast: (text: string, tone?: Toast['tone'], icon?: string) => void
  dismissToast: (id: number) => void
  finishLevel: (levelId: number, score: number, stars: number, pairs: number) => FinishReward
  summon: (count: 1 | 5) => SummonOutcome | null
  canClaimDaily: boolean
  dailyTick: number
  claimDaily: () => { coins: number; gems: number; label: string; day: number } | null
  taskProgress: (metric: 'games' | 'pairs' | 'summons' | 'stars') => number
  claimTask: (id: string) => boolean
  eventProgress: number
  claimEvent: () => boolean
  openChest: () => ChestResult | null
  exchangeGems: () => boolean
  setFavorite: (id: string) => void
  evolveHero: () => boolean
  rename: (name: string) => void
  toggleSound: () => void
  setVolume: (v: number) => void
  reset: () => void
  totalStars: number
  ownedCount: number
  nextLevel: number
}

const defaultState = (): GameState => ({
  v: 1,
  name: 'Игрок123',
  playerLevel: 12,
  xp: 40,
  coins: 12450,
  gems: 250,
  favorite: 'murzik',
  heroStage: 0,
  progress: {
    1: { stars: 3, best: 96, plays: 1, clearedAt: Date.now() - 3 * DAY },
    2: { stars: 3, best: 90, plays: 1, clearedAt: Date.now() - 2 * DAY },
    3: { stars: 2, best: 74, plays: 1, clearedAt: Date.now() - DAY },
  },
  owned: { murzik: 1, slime: 1, bunny: 1, star: 1, fox: 1, panda: 1, capybara: 1 },
  pity: { epic: 2, legendary: 4, total: 6 },
  history: [],
  daily: { last: 0, streak: 0 },
  tasks: { day: dayKey(Date.now()), claims: [], games: 0, pairs: 0, summons: 0, stars: 0 },
  event: { claimed: false },
  settings: { sound: true, volume: 0.7 },
  totals: { games: 24, pairs: 61, stars: 8, summons: 6, best: 96, chests: 1 },
  createdAt: Date.now(),
})

function dayKey(ts: number) {
  const d = new Date(ts)
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`
}

function loadState(): GameState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return defaultState()
    const parsed = JSON.parse(raw) as Partial<GameState>
    const base = defaultState()
    const state: GameState = {
      ...base,
      ...parsed,
      pity: { ...base.pity, ...(parsed.pity ?? {}) },
      daily: { ...base.daily, ...(parsed.daily ?? {}) },
      tasks: { ...base.tasks, ...(parsed.tasks ?? {}) },
      event: { ...base.event, ...(parsed.event ?? {}) },
      settings: { ...base.settings, ...(parsed.settings ?? {}) },
      totals: { ...base.totals, ...(parsed.totals ?? {}) },
      owned: { ...base.owned, ...(parsed.owned ?? {}) },
      progress: { ...base.progress, ...(parsed.progress ?? {}) },
      history: parsed.history ?? [],
    }
    if (state.tasks.day !== dayKey(Date.now())) {
      state.tasks = { day: dayKey(Date.now()), claims: [], games: 0, pairs: 0, summons: 0, stars: 0 }
    }
    if (state.heroStage > 2 || state.heroStage < 0) state.heroStage = 0
    return state
  } catch {
    return defaultState()
  }
}

const GameContext = createContext<Store | null>(null)

export function GameProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<GameState>(loadState)
  const [toasts, setToasts] = useState<Toast[]>([])
  const [dailyTick, setDailyTick] = useState(() => Date.now())
  const toastSeq = useRef(1)
  const stateRef = useRef(state)
  stateRef.current = state

  useEffect(() => {
    const id = window.setInterval(() => {
      setDailyTick(Date.now())
      setState((prev) => {
        if (prev.tasks.day === dayKey(Date.now())) return prev
        return {
          ...prev,
          tasks: { day: dayKey(Date.now()), claims: [], games: 0, pairs: 0, summons: 0, stars: 0 },
          event: { claimed: false },
        }
      })
    }, 10000)
    return () => window.clearInterval(id)
  }, [])

  useEffect(() => {
    setSoundEnabled(state.settings.sound)
    setSoundVolume(state.settings.volume)
  }, [state.settings.sound, state.settings.volume])

  useEffect(() => {
    const id = window.setTimeout(() => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
      } catch {
        /* приватный режим */
      }
    }, 120)
    return () => window.clearTimeout(id)
  }, [state])

  const toast = useCallback((text: string, tone: Toast['tone'] = 'info', icon?: string) => {
    const id = toastSeq.current++
    setToasts((list) => [...list.slice(-3), { id, text, tone, icon }])
    window.setTimeout(() => setToasts((list) => list.filter((t) => t.id !== id)), 2800)
  }, [])

  const dismissToast = useCallback((id: number) => {
    setToasts((list) => list.filter((t) => t.id !== id))
  }, [])

  const addXp = (s: GameState, amount: number) => {
    let xp = s.xp + amount
    let level = s.playerLevel
    let leveledUp = false
    let gems = s.gems
    let coins = s.coins
    let guard = 0
    while (xp >= xpNeeded(level) && guard < 30) {
      xp -= xpNeeded(level)
      level += 1
      leveledUp = true
      guard += 1
      gems += 6
      coins += 150
    }
    return { xp, level, leveledUp, gems, coins }
  }

  const finishLevel = useCallback<Store['finishLevel']>(
    (levelId, score, stars, pairs) => {
      const def = LEVELS.find((l) => l.id === levelId)
      const levelNum = def?.id ?? 1
      const prev = stateRef.current.progress[levelId]
      const firstClear = !prev
      const newBest = !prev || score > prev.best
      const coins = 50 + levelNum * 6 + stars * 20
      const gems = stars >= 3 ? 4 : stars === 2 ? 2 : 1
      const xp = 45 + stars * 18
      const earnedStars = firstClear ? stars : Math.max(0, stars - (prev?.stars ?? 0))

      setState((s) => {
        const current = s.progress[levelId]
        const leveled = addXp(s, xp)
        return {
          ...s,
          coins: leveled.coins + coins,
          gems: leveled.gems + gems,
          xp: leveled.xp,
          playerLevel: leveled.level,
          progress: {
            ...s.progress,
            [levelId]: {
              stars: Math.max(current?.stars ?? 0, stars),
              best: Math.max(current?.best ?? 0, score),
              plays: (current?.plays ?? 0) + 1,
              clearedAt: Date.now(),
            },
          },
          tasks: {
            ...s.tasks,
            games: s.tasks.games + 1,
            pairs: s.tasks.pairs + pairs,
            stars: s.tasks.stars + earnedStars,
          },
          totals: {
            ...s.totals,
            games: s.totals.games + 1,
            pairs: s.totals.pairs + pairs,
            stars: s.totals.stars + earnedStars,
            best: Math.max(s.totals.best, score),
          },
        }
      })

      const leveledUp = (() => {
        const s = stateRef.current
        return s.xp + xp >= xpNeeded(s.playerLevel)
      })()

      return { coins, gems, xp, stars, leveledUp, newBest, firstClear }
    },
    [],
  )

  const rollRarity = (pity: GameState['pity']): { rarity: Rarity; pityUsed: boolean } => {
    if (pity.legendary >= 9) return { rarity: 'legendary', pityUsed: true }
    if (pity.epic >= 4) {
      return { rarity: Math.random() < 0.15 ? 'legendary' : 'epic', pityUsed: true }
    }
    const pool = (Object.keys(RARITY) as Rarity[]).filter((r) => r !== 'legendary')
    const weights = pool.map((r) => RARITY[r].weight)
    const legendaryWeight = RARITY.legendary.weight
    const total = weights.reduce((a, b) => a + b, 0) + legendaryWeight
    let roll = Math.random() * total
    if (roll < legendaryWeight) return { rarity: 'legendary', pityUsed: false }
    roll -= legendaryWeight
    for (let i = 0; i < pool.length; i += 1) {
      roll -= weights[i]
      if (roll <= 0) return { rarity: pool[i], pityUsed: false }
    }
    return { rarity: 'common', pityUsed: false }
  }

  const summon = useCallback<Store['summon']>((count) => {
    const s = stateRef.current
    const spent = count === 1 ? 60 : 300
    if (s.gems < spent) {
      toast('Не хватает кристаллов — загляните в магазин', 'bad', 'gem')
      return null
    }

    const pity = { ...s.pity }
    const results: SummonResult[] = []
    const owned = { ...s.owned }
    const history: SummonRecord[] = []
    let gotPity = false

    for (let i = 0; i < count; i += 1) {
      const roll = rollRarity(pity)
      if (roll.pityUsed) gotPity = true
      const pool = SUMMON_POOL.filter((p) => p.rarity === roll.rarity)
      const pet = pool[Math.floor(Math.random() * pool.length)] ?? SUMMON_POOL[0]
      const isNew = !owned[pet.id]
      const dup = !isNew
      owned[pet.id] = (owned[pet.id] ?? 0) + 1
      const coins = dup ? RARITY[pet.rarity].dupCoins : 0
      const gems = dup ? Math.round(RARITY[pet.rarity].dupCoins / 20) : 0
      results.push({ pet, isNew, converted: dup, coins, gems })
      history.push({ petId: pet.id, rarity: pet.rarity, isNew, at: Date.now() })

      pity.epic = roll.rarity === 'epic' || roll.rarity === 'legendary' ? 0 : pity.epic + 1
      pity.legendary = roll.rarity === 'legendary' ? 0 : pity.legendary + 1
      pity.total += 1
    }

    setState((prev) => ({
      ...prev,
      gems: prev.gems - spent,
      coins: prev.coins + results.reduce((a, r) => a + r.coins, 0),
      owned,
      pity,
      history: [...history.reverse(), ...prev.history].slice(0, 40),
      tasks: { ...prev.tasks, summons: prev.tasks.summons + count },
      totals: { ...prev.totals, summons: prev.totals.summons + count },
    }))

    return { results, spent, pity: gotPity }
  }, [toast])

  const canClaimDaily = dailyTick - state.daily.last >= DAY

  const claimDaily = useCallback(() => {
    if (dailyTick - stateRef.current.daily.last < DAY) {
      toast('Награда уже получена — возвращайтесь завтра', 'bad', 'clock')
      return null
    }
    const s = stateRef.current
    const within = s.daily.last > 0 && Date.now() - s.daily.last < DAY * 2
    const streak = within ? s.daily.streak + 1 : 1
    const index = (streak - 1) % 7
    const reward = DAILY_REWARDS[index]
    setState((prev) => ({
      ...prev,
      coins: prev.coins + reward.coins,
      gems: prev.gems + reward.gems,
      daily: { last: Date.now(), streak },
      xp: prev.xp,
    }))
    playSound('reward')
    toast(`День ${index + 1}: ${reward.label}!`, 'good', 'gift')
    return { coins: reward.coins, gems: reward.gems, label: reward.label, day: index + 1 }
  }, [dailyTick, toast])

  const taskProgress = useCallback<Store['taskProgress']>(
    (metric) => {
      const s = stateRef.current
      return s.tasks[metric]
    },
    [],
  )

  const claimTask = useCallback<Store['claimTask']>(
    (id) => {
      const task = DAILY_TASKS.find((t) => t.id === id)
      if (!task) return false
      const s = stateRef.current
      if (s.tasks.claims.includes(id)) {
        toast('Награда уже получена', 'bad')
        return false
      }
      if (s.tasks[task.metric] < task.goal) {
        toast('Задание ещё не выполнено', 'bad', 'tasks')
        return false
      }
      setState((prev) => ({
        ...prev,
        coins: prev.coins + task.coins,
        gems: prev.gems + task.gems,
        tasks: { ...prev.tasks, claims: [...prev.tasks.claims, id] },
      }))
      playSound('reward')
      toast('Награда за задание получена!', 'good', 'trophy')
      return true
    },
    [toast],
  )

  const eventProgress = Math.min(5, state.tasks.games)

  const claimEvent = useCallback<Store['claimEvent']>(() => {
    const s = stateRef.current
    if (s.event.claimed) {
      toast('Награда события уже получена', 'bad')
      return false
    }
    if (s.tasks.games < 5) {
      toast('Пройдите ещё несколько игр', 'bad', 'spark')
      return false
    }
    setState((prev) => ({ ...prev, coins: prev.coins + 350, gems: prev.gems + 14, event: { claimed: true } }))
    playSound('reward')
    toast('Марафон внимания завершён: +350 монет и +14 кристаллов!', 'good', 'gift')
    return true
  }, [toast])

  const openChest = useCallback<Store['openChest']>(() => {
    const s = stateRef.current
    if (s.coins < 400) {
      toast('Нужно 400 монет', 'bad', 'coin')
      return null
    }
    const r = Math.random()
    let result: ChestResult
    if (r < 0.08) {
      const pool = SUMMON_POOL.filter((p) => p.rarity === 'epic')
      const pet = pool[Math.floor(Math.random() * pool.length)]
      result = { coins: 0, gems: 0, pet, label: `Питомец: ${pet.name}` }
    } else if (r < 0.4) {
      const gems = 6 + Math.floor(Math.random() * 12)
      result = { coins: 0, gems, label: `${gems} кристаллов` }
    } else {
      const coins = 90 + Math.floor(Math.random() * 170)
      result = { coins, gems: 0, label: `${coins} монет` }
    }
    setState((prev) => ({
      ...prev,
      coins: prev.coins - 400 + result.coins,
      gems: prev.gems + result.gems,
      owned: result.pet
        ? { ...prev.owned, [result.pet.id]: (prev.owned[result.pet.id] ?? 0) + 1 }
        : prev.owned,
      totals: { ...prev.totals, chests: prev.totals.chests + 1 },
    }))
    playSound('reward')
    return result
  }, [toast])

  const exchangeGems = useCallback<Store['exchangeGems']>(() => {
    const s = stateRef.current
    if (s.coins < 250) {
      toast('Нужно 250 монет для обмена', 'bad', 'coin')
      return false
    }
    setState((prev) => ({ ...prev, coins: prev.coins - 250, gems: prev.gems + 25 }))
    playSound('reward')
    toast('Обмен: 250 монет → 25 кристаллов', 'good', 'gem')
    return true
  }, [toast])

  const setFavorite = useCallback((id: string) => {
    setState((prev) => (prev.owned[id] ? { ...prev, favorite: id } : prev))
    playSound('cuddle')
  }, [])

  const evolveHero = useCallback<Store['evolveHero']>(() => {
    const s = stateRef.current
    const next = HERO_STAGES[s.heroStage + 1]
    if (!next) {
      toast('Мурзик достиг максимальной формы', 'info', 'spark')
      return false
    }
    const stars = Object.values(s.progress).reduce((a, r) => a + r.stars, 0)
    if (stars < next.stars) {
      toast(`Нужно ${next.stars} звёзд (у вас ${stars})`, 'bad', 'star')
      return false
    }
    if (s.gems < next.gems) {
      toast(`Нужно ${next.gems} кристаллов`, 'bad', 'gem')
      return false
    }
    setState((prev) => ({
      ...prev,
      gems: prev.gems - next.gems,
      heroStage: (prev.heroStage + 1) as 0 | 1 | 2,
    }))
    playSound('success')
    toast(`Мурзик эволюционировал: ${next.label}!`, 'good', 'paw')
    return true
  }, [toast])

  const rename = useCallback((name: string) => {
    const clean = name.trim().slice(0, 16)
    if (!clean) return
    setState((prev) => ({ ...prev, name: clean }))
  }, [])

  const toggleSound = useCallback(() => {
    setState((prev) => {
      const sound = !prev.settings.sound
      setSoundEnabled(sound)
      if (sound) playSound('tap')
      return { ...prev, settings: { ...prev.settings, sound } }
    })
  }, [])

  const setVolume = useCallback((value: number) => {
    setSoundVolume(value)
    setState((prev) => ({ ...prev, settings: { ...prev.settings, volume: value } }))
  }, [])

  const reset = useCallback(() => {
    const fresh = defaultState()
    setState(fresh)
    setSoundEnabled(fresh.settings.sound)
    setSoundVolume(fresh.settings.volume)
    haptic([20, 40, 20])
    toast('Прогресс сброшен — новая история начинается!', 'info', 'spark')
  }, [toast])

  const totalStars = useMemo(
    () => Object.values(state.progress).reduce((a, r) => a + r.stars, 0),
    [state.progress],
  )

  const ownedCount = Object.keys(state.owned).filter((id) => PET_BY_ID[id]).length

  const nextLevel = useMemo(() => {
    const firstNotCleared = LEVELS.find((l) => !state.progress[l.id])
    return firstNotCleared?.id ?? LEVELS[LEVELS.length - 1].id
  }, [state.progress])

  const value: Store = {
    state,
    toasts,
    toast,
    dismissToast,
    finishLevel,
    summon,
    canClaimDaily,
    dailyTick,
    claimDaily,
    taskProgress,
    claimTask,
    eventProgress,
    claimEvent,
    openChest,
    exchangeGems,
    setFavorite,
    evolveHero,
    rename,
    toggleSound,
    setVolume,
    reset,
    totalStars,
    ownedCount,
    nextLevel,
  }

  return <GameContext.Provider value={value}>{children}</GameContext.Provider>
}

export function useGame() {
  const ctx = useContext(GameContext)
  if (!ctx) throw new Error('useGame must be used inside GameProvider')
  return ctx
}

export function xpNeeded(level: number) {
  return 100 + level * 40
}
