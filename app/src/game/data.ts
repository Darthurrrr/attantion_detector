import type { LevelDef, Pet, Rarity } from './types'

export const PETS: Pet[] = [
  {
    id: 'murzik',
    name: 'Мурзик',
    title: 'Детектив внимания',
    img: '/assets/hero_cat.png',
    rarity: 'legendary',
    desc: 'Серо-белый кот с колокольчиком на шее. Нашёл сто потерянных звёзд и ни разу не отвлёкся. Ведёт вас по мирам внимания.',
    stats: [99, 84, 96],
  },
  {
    id: 'slime',
    name: 'Слизень Гоша',
    title: 'Мягкий оптимист',
    img: '/assets/pets/slime.png',
    rarity: 'common',
    desc: 'Прыгает туда, куда смотрит. Говорит, что главное — не скорость, а настроение.',
    stats: [42, 30, 55],
  },
  {
    id: 'cat_slime',
    name: 'Мяу-слайм',
    title: 'Пушистое желе',
    img: '/assets/pets/cat_slime.png',
    rarity: 'common',
    desc: 'Наполовину котик, наполовину желе. Мурчит, когда его гладят, и звенит, когда радуется.',
    stats: [48, 36, 58],
  },
  {
    id: 'bunny',
    name: 'Пуша',
    title: 'Зайка-непоседа',
    img: '/assets/pets/bunny.png',
    rarity: 'common',
    desc: 'Слышит, как падает листик за три поляны. Уши работают лучше радара.',
    stats: [50, 44, 60],
  },
  {
    id: 'star',
    name: 'Звёздочка',
    title: 'Карманное сияние',
    img: '/assets/pets/star.png',
    rarity: 'common',
    desc: 'Маленькая звезда, которая любит прятаться в траве. Освещает путь, когда все огни погасли.',
    stats: [46, 52, 62],
  },
  {
    id: 'capybara',
    name: 'Капи',
    title: 'Мастер спокойствия',
    img: '/assets/pets/capybara.png',
    rarity: 'uncommon',
    desc: 'Самый невозмутимый житель долины. Пока все спешат, Капи уже всё заметил.',
    stats: [64, 32, 58],
  },
  {
    id: 'blue_slime',
    name: 'Аква',
    title: 'Капля внимания',
    img: '/assets/pets/blue_slime.png',
    rarity: 'uncommon',
    desc: 'Собран из утренней росы и одной очень удачной мысли. Блестит на солнце.',
    stats: [58, 48, 66],
  },
  {
    id: 'fox',
    name: 'Рыжик',
    title: 'Хитрый наблюдатель',
    img: '/assets/pets/fox.png',
    rarity: 'uncommon',
    desc: 'Замечает всё: от мелькнувшего хвоста до новой звёздочки на небе. И притворяется, что спит.',
    stats: [72, 60, 54],
  },
  {
    id: 'panda',
    name: 'Бамбук',
    title: 'Уютный детектив',
    img: '/assets/pets/panda.png',
    rarity: 'uncommon',
    desc: 'Расследует пропажи печенья. Пока безрезультатно, но очень старается.',
    stats: [66, 40, 68],
  },
  {
    id: 'penguin',
    name: 'Пингви',
    title: 'Ледяной ритм',
    img: '/assets/pets/penguin.png',
    rarity: 'uncommon',
    desc: 'Слушает музыку кристаллов и всегда попадает в такт. Даже когда скользит.',
    stats: [62, 56, 60],
  },
  {
    id: 'dino',
    name: 'Дино',
    title: 'Зелёный романтик',
    img: '/assets/pets/dino.png',
    rarity: 'rare',
    desc: 'Маленький динозавр, который коллекционирует полевые цветы и красивые камни.',
    stats: [70, 62, 72],
  },
  {
    id: 'robot',
    name: 'Робик',
    title: 'Счётная машина',
    img: '/assets/pets/robot.png',
    rarity: 'rare',
    desc: 'Считает всё: шаги, звёзды, ваши ошибки. Но делает это очень вежливо.',
    stats: [84, 72, 48],
  },
  {
    id: 'ghost',
    name: 'Бу',
    title: 'Тихий свидетель',
    img: '/assets/pets/ghost.png',
    rarity: 'rare',
    desc: 'Проходит сквозь стены и подсматривает за кристаллами. Никогда не шумит.',
    stats: [78, 88, 58],
  },
  {
    id: 'royal_slime',
    name: 'Король Желе',
    title: 'Монарх лужи',
    img: '/assets/pets/royal_slime.png',
    rarity: 'rare',
    desc: 'Правит самым большим прудом долины. Корона настоящая, желейная.',
    stats: [76, 52, 84],
  },
  {
    id: 'dragon',
    name: 'Дракоша',
    title: 'Хранитель сокровищ',
    img: '/assets/pets/dragon.png',
    rarity: 'epic',
    desc: 'Сторожит кристаллы внимания. Согласен поделиться, если вы найдёте три пары подряд.',
    stats: [90, 74, 82],
  },
  {
    id: 'phoenix',
    name: 'Феникс',
    title: 'Утренний огонь',
    img: '/assets/pets/phoenix.png',
    rarity: 'epic',
    desc: 'Каждое утро начинает всё заново. Показывает, как важно возвращаться к цели.',
    stats: [88, 92, 76],
  },
]

export const PET_BY_ID: Record<string, Pet> = Object.fromEntries(PETS.map((p) => [p.id, p]))

export const RARITY: Record<
  Rarity,
  { label: string; color: string; dark: string; light: string; order: number; weight: number; dupCoins: number }
> = {
  common: {
    label: 'Обычный',
    color: '#9fb6d9',
    dark: '#5b6f9c',
    light: '#dfe9ff',
    order: 0,
    weight: 55,
    dupCoins: 40,
  },
  uncommon: {
    label: 'Необычный',
    color: '#6bdd8f',
    dark: '#2f8a52',
    light: '#ddffe7',
    order: 1,
    weight: 27,
    dupCoins: 80,
  },
  rare: {
    label: 'Редкий',
    color: '#5fafff',
    dark: '#2b5fa8',
    light: '#dcf0ff',
    order: 2,
    weight: 11.5,
    dupCoins: 140,
  },
  epic: {
    label: 'Эпический',
    color: '#c07bff',
    dark: '#6d33a8',
    light: '#f3e2ff',
    order: 3,
    weight: 5,
    dupCoins: 260,
  },
  legendary: {
    label: 'Легендарный',
    color: '#ffb93e',
    dark: '#a95e0c',
    light: '#fff2cf',
    order: 4,
    weight: 1.5,
    dupCoins: 500,
  },
}

export const SUMMON_POOL = PETS.filter((p) => p.id !== 'murzik')

export const LEVELS: LevelDef[] = [
  {
    id: 1,
    type: 'match',
    name: 'Первые пары',
    tip: 'Запоминайте, где спрятались питомцы. Чем меньше ходов — тем больше звёзд!',
    pairs: 4,
  },
  {
    id: 2,
    type: 'odd',
    name: 'Кто здесь лишний?',
    tip: 'Один питомец отличается цветом, поворотом или размером. Смотрите внимательно.',
    cells: 6,
    rounds: 4,
  },
  {
    id: 3,
    type: 'firefly',
    name: 'Охота за светлячками',
    tip: 'Ловите только золотых светлячков. Фиолетовые — обманки, за них штраф.',
    targets: 6,
    time: 26,
  },
  {
    id: 4,
    type: 'simon',
    name: 'Эхо кристаллов',
    tip: 'Повторите мелодию кристаллов в том же порядке. С каждым разом она длиннее.',
    seq: 4,
  },
  {
    id: 5,
    type: 'match',
    name: 'Лесные парочки',
    tip: 'Питомцев стало больше. Открывайте карточки по краям — там проще запоминать.',
    pairs: 6,
  },
  {
    id: 6,
    type: 'odd',
    name: 'Тропа наблюдателя',
    tip: 'Смотрите на контуры, а не на мордочки. Отличие часто прячется на краю.',
    cells: 9,
    rounds: 5,
  },
  {
    id: 7,
    type: 'firefly',
    name: 'Поляна светлячков',
    tip: 'Не гонитесь за каждой искрой. Сначала выберите цель, потом тянитесь к ней.',
    targets: 8,
    time: 24,
  },
  {
    id: 8,
    type: 'simon',
    name: 'Голос тумана',
    tip: 'Проговаривайте цвета про себя: «розовый, синий, золото». Так проще запомнить.',
    seq: 5,
  },
  {
    id: 9,
    type: 'match',
    name: 'Сад воспоминаний',
    tip: 'Если не помните карточку — открывайте новую рядом с уже известной.',
    pairs: 8,
  },
  {
    id: 10,
    type: 'odd',
    name: 'Зеркальный зал',
    tip: 'Отражённые питомцы выглядят почти так же. Ищите зеркальность!',
    cells: 12,
    rounds: 5,
  },
  {
    id: 11,
    type: 'firefly',
    name: 'Ночной дозор',
    tip: 'Таймер короче. Следите за свечением, а не за движением.',
    targets: 10,
    time: 23,
  },
  {
    id: 12,
    type: 'simon',
    name: 'Хор кристаллов',
    tip: 'Последовательность длиннее. Держите ритм — он подскажет порядок.',
    seq: 6,
  },
  {
    id: 13,
    type: 'match',
    name: 'Созвездие пар',
    tip: 'Двадцать карточек! Начните с углов и двигайтесь по спирали.',
    pairs: 10,
  },
  {
    id: 14,
    type: 'odd',
    name: 'Испытание зеркал',
    tip: 'Отличия совсем тонкие. Сравнивайте попарно, клетка за клеткой.',
    cells: 16,
    rounds: 6,
  },
  {
    id: 15,
    type: 'simon',
    name: 'Сердце внимания',
    tip: 'Финальное испытание главы. Семь сигналов — и мир внимания ваш!',
    seq: 7,
  },
  {
    id: 16,
    type: 'count',
    name: 'Считаем искры',
    tip: 'Искры вспыхивают и гаснут. Считайте про себя — и отвечайте, когда погаснут все.',
    seconds: 3,
  },
  {
    id: 17,
    type: 'count',
    name: 'Вспышка созвездий',
    tip: 'Дольше не значит проще: искр становится больше. Держите счёт по группам.',
    seconds: 4,
  },
]

export const LEVEL_BY_ID: Record<number, LevelDef> = Object.fromEntries(LEVELS.map((l) => [l.id, l]))

export const CHAPTER = { id: 1, name: 'Мир внимания', next: 'Мир памяти' }

export const TYPE_INFO: Record<
  LevelDef['type'],
  { label: string; short: string; hint: string; color: string }
> = {
  match: {
    label: 'Найди пару',
    short: 'Пары',
    hint: 'Открывайте карточки и находите одинаковых питомцев',
    color: '#6ad1ff',
  },
  odd: {
    label: 'Найди лишнего',
    short: 'Лишний',
    hint: 'Один питомец отличается от остальных — найдите его',
    color: '#ffbf5e',
  },
  firefly: {
    label: 'Поймай светлячков',
    short: 'Светлячки',
    hint: 'Ловите только золотых светлячков на поляне',
    color: '#ffd766',
  },
  simon: {
    label: 'Повтори мелодию',
    short: 'Мелодия',
    hint: 'Запомните и повторите последовательность кристаллов',
    color: '#c58bff',
  },
  count: {
    label: 'Посчитай искры',
    short: 'Искры',
    hint: 'Считайте вспышки искр, пока они не погасли, и выберите ответ',
    color: '#8ef0c0',
  },
}

export const DAILY_REWARDS = [
  { coins: 60, gems: 0, label: '60 монет' },
  { coins: 0, gems: 6, label: '6 кристаллов' },
  { coins: 120, gems: 0, label: '120 монет' },
  { coins: 0, gems: 10, label: '10 кристаллов' },
  { coins: 200, gems: 0, label: '200 монет' },
  { coins: 0, gems: 15, label: '15 кристаллов' },
  { coins: 350, gems: 25, label: 'Сундук недели' },
]

export type TaskDef = {
  id: string
  title: string
  goal: number
  metric: 'games' | 'pairs' | 'summons' | 'stars'
  coins: number
  gems: number
}

export const DAILY_TASKS: TaskDef[] = [
  { id: 'play1', title: 'Сыграйте 1 мини-игру', goal: 1, metric: 'games', coins: 80, gems: 0 },
  { id: 'play3', title: 'Сыграйте 3 мини-игры', goal: 3, metric: 'games', coins: 140, gems: 0 },
  { id: 'pairs8', title: 'Найдите 8 пар', goal: 8, metric: 'pairs', coins: 120, gems: 0 },
  { id: 'summon1', title: 'Откройте 1 призыв', goal: 1, metric: 'summons', coins: 0, gems: 6 },
  { id: 'stars5', title: 'Заработайте 5 звёзд', goal: 5, metric: 'stars', coins: 200, gems: 4 },
]

export const PET_LINES = [
  'Отличный день для тестов!',
  'Я почти нашёл все пары. Почти!',
  'Кристаллы сами себя не соберут.',
  'Мур-р. Погладь меня, и я подскажу.',
  'Внимание — это как мышка: главное не упустить.',
  'Сегодня я заметил даже пылинку на луне.',
  'Давай пройдём ещё один уровень?',
  'Колокольчик звенит — значит, пора играть!',
]

export const HERO_STAGES = [
  { name: 'Мурзик', img: '/assets/hero_cat.png', stars: 0, gems: 0, label: 'Обычный вид' },
  { name: 'Мурзик-странник', img: '/assets/hero_cat_cape.png', stars: 12, gems: 120, label: 'Плащ странника' },
  { name: 'Мурзик-хранитель', img: '/assets/hero_cat_armor.png', stars: 30, gems: 260, label: 'Доспех хранителя' },
]
