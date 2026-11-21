export type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'

export type Pet = {
  id: string
  name: string
  title: string
  img: string
  rarity: Rarity
  desc: string
  stats: [number, number, number] // внимание, скорость, удача
}

export type LevelType = 'match' | 'odd' | 'firefly' | 'simon' | 'count'

export type LevelDef = {
  id: number
  type: LevelType
  name: string
  tip: string
  /** количество пар для match */
  pairs?: number
  /** число раундов для odd */
  rounds?: number
  /** число клеток в сетке для odd */
  cells?: number
  /** сколько светлячков поймать */
  targets?: number
  /** секунд на раунд firefly */
  time?: number
  /** длина последовательности для simon */
  seq?: number
  /** длительность раунда в секундах для count */
  seconds?: number
}

export type LevelResult = {
  stars: number
  best: number
  plays: number
  clearedAt: number
}

export type SummonRecord = {
  petId: string
  rarity: Rarity
  isNew: boolean
  at: number
}

export type GameState = {
  v: number
  name: string
  playerLevel: number
  xp: number
  coins: number
  gems: number
  favorite: string
  heroStage: 0 | 1 | 2
  progress: Record<string, LevelResult>
  owned: Record<string, number>
  pity: { epic: number; legendary: number; total: number }
  history: SummonRecord[]
  daily: { last: number; streak: number }
  tasks: {
    day: string
    claims: string[]
    games: number
    pairs: number
    summons: number
    stars: number
  }
  event: { claimed: boolean }
  settings: { sound: boolean; volume: number }
  totals: { games: number; pairs: number; stars: number; summons: number; best: number; chests: number }
  createdAt: number
}

export type SummonResult = {
  pet: Pet
  isNew: boolean
  converted: boolean
  coins: number
  gems: number
}

export type Screen = 'home' | 'map' | 'summon' | 'collection' | 'play'
