"""Игровые правила «Детектора внимания» — единственный источник истины.

Все суммы, вероятности, уровни и пороги опыта описаны здесь. Клиент не
вычисляет ни валюту, ни результат призыва, ни доступность эволюции.
"""
from __future__ import annotations

from typing import Any, Literal

Rarity = Literal["common", "uncommon", "rare", "epic", "legendary"]

RARITIES: dict[str, dict[str, Any]] = {
    "common": {"label": "Обычный", "color": "#9fb6d9", "order": 0, "rate": 50.0, "dupGems": 2, "itemCoins": 30},
    "uncommon": {"label": "Необычный", "color": "#6bdd8f", "order": 1, "rate": 25.0, "dupGems": 4, "itemCoins": 60},
    "rare": {"label": "Редкий", "color": "#5fafff", "order": 2, "rate": 15.0, "dupGems": 8, "itemCoins": 110},
    "epic": {"label": "Эпический", "color": "#c07bff", "order": 3, "rate": 8.0, "dupGems": 20, "itemCoins": 180},
    "legendary": {"label": "Легендарный", "color": "#ffb93e", "order": 4, "rate": 2.0, "dupGems": 60, "itemCoins": 320},
}

EGG_PRICE = 60
EPIC_PITY = 5          # каждое 5-е открытие — эпик или выше
LEGENDARY_PITY = 10    # каждое 10-е открытие — легендарка
MAX_PET_LEVEL = 99


def _pet(pid: str, name: str, title: str, rarity: Rarity, asset: str, desc: str, stats: tuple[int, int, int]) -> dict[str, Any]:
    return {"id": pid, "name": name, "title": title, "rarity": rarity, "asset": asset, "desc": desc, "stats": list(stats)}


PETS: list[dict[str, Any]] = [
    _pet("murzik", "Мурзик", "Детектив внимания", "legendary", "assets/hero_cat.png",
         "Серо-белый кот с колокольчиком на шее. Ведёт вас по мирам внимания.", (99, 84, 96)),
    _pet("slime", "Слизень Гоша", "Мягкий оптимист", "common", "assets/pets/slime.png",
         "Прыгает туда, куда смотрит. Главное — не скорость, а настроение.", (42, 30, 55)),
    _pet("cat_slime", "Мяу-слайм", "Пушистое желе", "common", "assets/pets/cat_slime.png",
         "Наполовину котик, наполовину желе. Мурчит, когда его гладят.", (48, 36, 58)),
    _pet("bunny", "Пуша", "Зайка-непоседа", "common", "assets/pets/bunny.png",
         "Слышит, как падает листик за три поляны. Уши работают лучше радара.", (50, 44, 60)),
    _pet("star", "Звёздочка", "Карманное сияние", "common", "assets/pets/star.png",
         "Маленькая звезда, которая любит прятаться в траве.", (46, 52, 62)),
    _pet("capybara", "Капи", "Мастер спокойствия", "uncommon", "assets/pets/capybara.png",
         "Самый невозмутимый житель долины. Замечает всё первым.", (64, 32, 58)),
    _pet("blue_slime", "Аква", "Капля внимания", "uncommon", "assets/pets/blue_slime.png",
         "Собран из утренней росы и одной очень удачной мысли.", (58, 48, 66)),
    _pet("fox", "Рыжик", "Хитрый наблюдатель", "uncommon", "assets/pets/fox.png",
         "Замечает всё: от мелькнувшего хвоста до новой звёздочки.", (72, 60, 54)),
    _pet("panda", "Бамбук", "Уютный детектив", "uncommon", "assets/pets/panda.png",
         "Расследует пропажи печенья. Пока безрезультатно, но очень старается.", (66, 40, 68)),
    _pet("penguin", "Пингви", "Ледяной ритм", "uncommon", "assets/pets/penguin.png",
         "Слушает музыку кристаллов и всегда попадает в такт.", (62, 56, 60)),
    _pet("dino", "Дино", "Зелёный романтик", "rare", "assets/pets/dino.png",
         "Коллекционирует полевые цветы и красивые камни.", (70, 62, 72)),
    _pet("robot", "Робик", "Счётная машина", "rare", "assets/pets/robot.png",
         "Считает всё: шаги, звёзды, ваши ошибки. Но очень вежливо.", (84, 72, 48)),
    _pet("ghost", "Бу", "Тихий свидетель", "rare", "assets/pets/ghost.png",
         "Проходит сквозь стены и подсматривает за кристаллами.", (78, 88, 58)),
    _pet("royal_slime", "Король Желе", "Монарх лужи", "rare", "assets/pets/royal_slime.png",
         "Правит самым большим прудом долины. Корона настоящая, желейная.", (76, 52, 84)),
    _pet("dragon", "Дракоша", "Хранитель сокровищ", "epic", "assets/pets/dragon.png",
         "Сторожит кристаллы внимания и делится ими за три пары подряд.", (90, 74, 82)),
    _pet("phoenix", "Феникс", "Утренний огонь", "epic", "assets/pets/phoenix.png",
         "Каждое утро начинает всё заново и учит возвращаться к цели.", (88, 92, 76)),
    _pet("murzik_strider", "Мурзик-странник", "Плащ зоркости", "legendary", "assets/hero_cat_cape.png",
         "Мурзик в плаще странника: видит на три дюны вперёд.", (95, 90, 92)),
    _pet("murzik_keeper", "Мурзик-хранитель", "Доспех внимания", "legendary", "assets/hero_cat_armor.png",
         "Хранитель мира внимания. Появляется только у самых настойчивых.", (99, 94, 98)),
]

PET_BY_ID = {p["id"]: p for p in PETS}
STARTER_PETS = ["murzik", "slime", "bunny"]
# Пул призыва: все, кроме стартового Мурзика (он выдаётся сразу).
SUMMON_POOL = [p for p in PETS if p["id"] != "murzik"]
SEVENTH_DAY_PET = "murzik_keeper"


def pets_by_rarity(rarity: str) -> list[dict[str, Any]]:
    return [p for p in SUMMON_POOL if p["rarity"] == rarity]


# --- опыт питомца ---------------------------------------------------------
_XP_SEGMENTS = ((1, 10, 20, 23), (11, 33, 24, 31), (34, 66, 32, 43), (67, 99, 44, 55))


def xp_per_level(level: int) -> int:
    """Порог опыта для перехода с `level` на `level + 1` (таблица 1–99)."""
    level = max(1, min(MAX_PET_LEVEL, level))
    for start, end, lo, hi in _XP_SEGMENTS:
        if start <= level <= end:
            if end == start:
                return hi
            return lo + round((hi - lo) * (level - start) / (end - start))
    return 55


def form_for_level(level: int) -> int:
    if level >= 67:
        return 3
    if level >= 34:
        return 2
    return 1


# --- тесты ----------------------------------------------------------------
DIFFICULTY_XP = {"easy": 20, "medium": 35, "hard": 50, "special": 75}


def _level(lid: int, kind: str, name: str, tip: str, difficulty: str, **params: Any) -> dict[str, Any]:
    return {"id": lid, "type": kind, "name": name, "tip": tip, "difficulty": difficulty, "params": params}


LEVELS: list[dict[str, Any]] = [
    _level(1, "match", "Первые пары", "Запоминайте, где спрятались питомцы. Чем меньше ходов — тем больше звёзд!", "easy", pairs=4),
    _level(2, "odd", "Кто здесь лишний?", "Один питомец отличается цветом, поворотом или размером.", "easy", cells=6, rounds=4),
    _level(3, "firefly", "Охота за светлячками", "Ловите только золотых светлячков. Фиолетовые — обманки.", "easy", targets=6, seconds=26),
    _level(4, "simon", "Эхо кристаллов", "Повторите мелодию кристаллов в том же порядке.", "easy", seq=4),
    _level(5, "match", "Лесные парочки", "Питомцев стало больше. Начинайте с краёв.", "easy", pairs=6),
    _level(6, "odd", "Тропа наблюдателя", "Смотрите на контуры, а не на мордочки.", "easy", cells=9, rounds=5),
    _level(7, "firefly", "Поляна светлячков", "Сначала выберите цель, потом тянитесь к ней.", "medium", targets=8, seconds=24),
    _level(8, "simon", "Голос тумана", "Проговаривайте цвета про себя: «розовый, синий, золото».", "medium", seq=5),
    _level(9, "match", "Сад воспоминаний", "Если не помните карточку — открывайте рядом с известной.", "medium", pairs=8),
    _level(10, "odd", "Зеркальный зал", "Отражённые питомцы выглядят почти так же.", "medium", cells=12, rounds=5),
    _level(11, "firefly", "Ночной дозор", "Таймер короче. Следите за свечением.", "medium", targets=10, seconds=23),
    _level(12, "simon", "Хор кристаллов", "Держите ритм — он подскажет порядок.", "medium", seq=6),
    _level(13, "match", "Созвездие пар", "Двадцать карточек! Идите по спирали.", "hard", pairs=10),
    _level(14, "odd", "Испытание зеркал", "Отличия совсем тонкие. Сравнивайте попарно.", "hard", cells=16, rounds=6),
    _level(15, "simon", "Сердце внимания", "Финальное испытание главы: семь сигналов.", "hard", seq=7),
    _level(16, "count", "Считаем искры", "Искры вспыхивают и гаснут. Считайте про себя.", "hard", rounds=5, seconds=3),
    _level(17, "count", "Вспышка созвездий", "Искр больше. Держите счёт по группам.", "special", rounds=5, seconds=4),
]

LEVEL_BY_ID = {l["id"]: l for l in LEVELS}
CHAPTERS = [
    {"id": 1, "name": "Мир внимания", "from": 1, "to": 15, "reward": {"eggs": 1, "gems": 30}},
    {"id": 2, "name": "Мир памяти", "from": 16, "to": 17, "reward": {"eggs": 1, "gems": 40}},
]


def difficulty_of(level_id: int) -> str:
    return LEVEL_BY_ID.get(level_id, LEVELS[0])["difficulty"]


# --- экономика ------------------------------------------------------------
# (id, name, kind, rarity, price, currency, asset, desc) — цены требуют финального баланса (ТЗ п.29).
SHOP_ITEMS: list[dict[str, Any]] = [
    {"id": "cosmo_bubbles", "name": "Пузырьки", "kind": "cosmetic", "rarity": "common", "price": 900, "currency": "coins", "asset": "assets/ui/gem.png", "desc": "Лёгкие мыльные пузырьки вокруг питомца.", "layer": "bubbles"},
    {"id": "cosmo_sparks", "name": "Искры", "kind": "cosmetic", "rarity": "uncommon", "price": 1600, "currency": "coins", "asset": "assets/ui/star.png", "desc": "Золотые искры, вспыхивающие у лап.", "layer": "sparks"},
    {"id": "cosmo_stars", "name": "Звёздная пыль", "kind": "cosmetic", "rarity": "rare", "price": 40, "currency": "gems", "asset": "assets/ui/star.png", "desc": "Медленное сияние маленьких звёзд.", "layer": "stars"},
    {"id": "cosmo_fire", "name": "Огненные вспышки", "kind": "cosmetic", "rarity": "epic", "price": 95, "currency": "gems", "asset": "assets/ui/crystal_node.png", "desc": "Тёплые огоньки, танцующие по кругу.", "layer": "fire"},
    {"id": "cosmo_halo", "name": "Нимб внимания", "kind": "cosmetic", "rarity": "legendary", "price": 220, "currency": "gems", "asset": "assets/ui/star.png", "desc": "Сияющий нимб для настоящих детективов.", "layer": "halo"},

    {"id": "world_meadow", "name": "Луг Мурзика", "kind": "world", "rarity": "common", "price": 0, "currency": "coins", "asset": "assets/bg/home.webp", "desc": "Базовая долина внимания."},
    {"id": "world_cosmos", "name": "Космическая ночь", "kind": "world", "rarity": "rare", "price": 2600, "currency": "coins", "asset": "assets/bg/cosmic.webp", "desc": "Звёздное небо и тихие созвездия."},
    {"id": "world_summon", "name": "Зал призыва", "kind": "world", "rarity": "epic", "price": 120, "currency": "gems", "asset": "assets/bg/summon.webp", "desc": "Светящийся зал, где рождаются питомцы."},
    {"id": "world_collection", "name": "Галерея героев", "kind": "world", "rarity": "uncommon", "price": 1800, "currency": "coins", "asset": "assets/bg/collection.webp", "desc": "Тёплая галерея с портретами друзей."},

    {"id": "ui_violet", "name": "Фиолетовая тема", "kind": "ui", "rarity": "common", "price": 0, "currency": "coins", "asset": "assets/ui/gem.png", "desc": "Базовая палитра мира внимания."},
    {"id": "ui_mint", "name": "Мятная тема", "kind": "ui", "rarity": "uncommon", "price": 2100, "currency": "coins", "asset": "assets/ui/star.png", "desc": "Свежая мятная палитра интерфейса."},
    {"id": "ui_gold", "name": "Золотая тема", "kind": "ui", "rarity": "legendary", "price": 180, "currency": "gems", "asset": "assets/ui/star.png", "desc": "Премиальное золото для избранных."},

    {"id": "coll_crystal", "name": "Кристалл внимания", "kind": "collectible", "rarity": "rare", "price": 1500, "currency": "coins", "asset": "assets/ui/crystal_node.png", "desc": "Коллекционный кристалл первого созвездия."},
    {"id": "coll_chest", "name": "Сундук странника", "kind": "collectible", "rarity": "epic", "price": 90, "currency": "gems", "asset": "assets/ui/chest.png", "desc": "Сундук с гербом Мурзика. Не открывается — просто красивый."},
    {"id": "coll_egg", "name": "Первое яйцо", "kind": "collectible", "rarity": "legendary", "price": 160, "currency": "gems", "asset": "assets/ui/egg_0.png", "desc": "Памятное яйцо, с которого началась коллекция."},
]
ITEM_BY_ID = {i["id"]: i for i in SHOP_ITEMS}

DAILY_REWARDS = [
    {"coins": 80, "gems": 0, "eggs": 0, "label": "80 монет"},
    {"coins": 0, "gems": 8, "eggs": 0, "label": "8 кристаллов"},
    {"coins": 150, "gems": 0, "eggs": 0, "label": "150 монет"},
    {"coins": 0, "gems": 12, "eggs": 0, "label": "12 кристаллов"},
    {"coins": 220, "gems": 0, "eggs": 0, "label": "220 монет"},
    {"coins": 0, "gems": 16, "eggs": 0, "label": "16 кристаллов"},
    {"coins": 350, "gems": 25, "eggs": 1, "label": "Сундук недели + яйцо", "pet": SEVENTH_DAY_PET},
]

TASKS = [
    {"id": "play1", "title": "Сыграйте 1 мини-игру", "metric": "games", "goal": 1, "coins": 80, "gems": 0},
    {"id": "play3", "title": "Сыграйте 3 мини-игры", "metric": "games", "goal": 3, "coins": 140, "gems": 0},
    {"id": "pairs8", "title": "Найдите 8 пар", "metric": "pairs", "goal": 8, "coins": 120, "gems": 0},
    {"id": "summon1", "title": "Откройте 1 яйцо", "metric": "summons", "goal": 1, "coins": 0, "gems": 6},
    {"id": "stars5", "title": "Заработайте 5 звёзд", "metric": "stars", "goal": 5, "coins": 200, "gems": 4},
]

STARTER_EVENT = {
    "id": "starter",
    "name": "Первые шаги детектива",
    "steps": [
        {"id": "welcome", "title": "Знакомство", "desc": "Загляните на главный экран и погладьте питомца.", "metric": "pets_patted", "goal": 1, "coins": 120, "gems": 0, "eggs": 0},
        {"id": "tests", "title": "Первые тесты", "desc": "Пройдите 2 любых тренировки.", "metric": "games", "goal": 2, "coins": 200, "gems": 6, "eggs": 0},
        {"id": "egg", "title": "Универсальное яйцо", "desc": "Награда третьего дня новичка.", "metric": "days", "goal": 3, "coins": 0, "gems": 10, "eggs": 1},
    ],
}

LOGIN_BONUS_GEMS = 100


def rules_payload() -> dict[str, Any]:
    return {
        "eggPrice": EGG_PRICE,
        "epicPity": EPIC_PITY,
        "legendaryPity": LEGENDARY_PITY,
        "rates": [{"rarity": r, "rate": meta["rate"]} for r, meta in RARITIES.items()],
        "duplicates": [{"rarity": r, "gems": meta["dupGems"]} for r, meta in RARITIES.items()],
        "xp": {"easy": 20, "medium": 35, "hard": 50, "special": 75, "maxLevel": MAX_PET_LEVEL},
        "xpTable": {str(l): xp_per_level(l) for l in range(1, MAX_PET_LEVEL)},
        "forms": {"1": [1, 33], "2": [34, 66], "3": [67, 99]},
        "evolutionLevels": [33, 66],
    }
