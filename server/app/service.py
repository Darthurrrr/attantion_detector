"""Игровой сервис: вся экономика, призывы, опыт питомцев и награды.

Клиент только отображает ответы этих функций. Все проверки — здесь.
"""
from __future__ import annotations

import hashlib
import json
import random
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import rules
from .models import (
    DailyCounter,
    DailyTask,
    EventProgress,
    IdempotencyKey,
    Player,
    PlayerItem,
    PlayerPet,
    SummonLog,
    TestRun,
    Transaction,
)

DAY = timedelta(days=1)


# ---------------------------------------------------------------- helpers
def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def day_key(now: datetime | None = None) -> str:
    now = now or datetime.now(timezone.utc)
    return now.strftime("%Y-%m-%d")


def today_start() -> datetime:
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def aware(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def log(db: Session, player: Player, kind: str, coins: int = 0, gems: int = 0, eggs: int = 0, note: str = "") -> None:
    db.add(Transaction(player_id=player.id, kind=kind, coins=coins, gems=gems, eggs=eggs, note=note[:160]))


def idem_get(db: Session, player: Player, key: str | None) -> Any | None:
    if not key:
        return None
    row = db.scalar(select(IdempotencyKey).where(IdempotencyKey.player_id == player.id, IdempotencyKey.key == key))
    return json.loads(row.payload) if row else None


def idem_put(db: Session, player: Player, key: str | None, payload: Any) -> None:
    if not key:
        return
    db.add(IdempotencyKey(player_id=player.id, key=key, payload=json.dumps(payload, ensure_ascii=False)))


# ---------------------------------------------------------------- player
def create_player(db: Session, device_id: str, name: str | None = None) -> tuple[Player, str]:
    token = secrets.token_urlsafe(32)
    player = Player(
        device_id=device_id,
        token_hash=hash_token(token),
        name=(name or "Детектив")[:24],
        coins=1500 + rules.LOGIN_BONUS_GEMS * 5,
        gems=120 + rules.LOGIN_BONUS_GEMS,
        eggs=1,
        pity_epic=0,
        pity_legendary=0,
    )
    db.add(player)
    db.flush()
    for pet_id in rules.STARTER_PETS:
        db.add(PlayerPet(player_id=player.id, pet_id=pet_id, level=1, xp=0, form=1))
    player.active_pet_id = rules.STARTER_PETS[0]
    db.add(PlayerItem(player_id=player.id, item_id="world_meadow"))
    db.add(PlayerItem(player_id=player.id, item_id="ui_violet"))
    log(db, player, "start", coins=player.coins, gems=player.gems, eggs=player.eggs, note="Стартовый набор")
    db.commit()
    db.refresh(player)
    return player, token


# ---------------------------------------------------------------- leveling
def level_up_pet(pet: PlayerPet) -> list[int]:
    """Начисляет уровни по таблице опыта. Возвращает список новых уровней."""
    gained: list[int] = []
    guard = 0
    while pet.level < rules.MAX_PET_LEVEL:
        need = rules.xp_per_level(pet.level)
        if pet.xp < need:
            break
        pet.xp -= need
        pet.level += 1
        gained.append(pet.level)
        guard += 1
        if guard > 200:
            break
    if pet.level >= rules.MAX_PET_LEVEL:
        pet.level = rules.MAX_PET_LEVEL
        pet.xp = 0
    return gained


def grant_evolution_items(pet: PlayerPet, new_levels: list[int]) -> list[int]:
    """Предмет эволюции выдаётся на 33 и 66 уровнях. Возвращает выданные пороги."""
    granted: list[int] = []
    for level in new_levels:
        if level in (33, 66):
            pet.evo_items += 1
            granted.append(level)
    return granted


def pet_payload(pet: PlayerPet) -> dict[str, Any]:
    meta = rules.PET_BY_ID[pet.pet_id]
    return {
        "petId": pet.pet_id,
        "name": meta["name"],
        "title": meta["title"],
        "rarity": meta["rarity"],
        "asset": meta["asset"],
        "desc": meta["desc"],
        "stats": meta["stats"],
        "level": pet.level,
        "xp": pet.xp,
        "xpNeeded": rules.xp_per_level(pet.level) if pet.level < rules.MAX_PET_LEVEL else 0,
        "form": pet.form if 1 <= pet.form <= 3 else rules.form_for_level(pet.level),
        "evoItems": pet.evo_items,
        "maxLevel": pet.level >= rules.MAX_PET_LEVEL,
        "canEvolve": can_evolve(pet),
    }


def can_evolve(pet: PlayerPet) -> bool:
    """Эволюция: 33-й уровень — первая форма, 66-й — вторая (ТЗ 6.3–6.5)."""
    form = pet.form if 1 <= pet.form <= 3 else rules.form_for_level(pet.level)
    if form >= 3:
        return False
    threshold = 33 if form == 1 else 66
    return pet.level >= threshold and pet.evo_items >= 1


# ---------------------------------------------------------------- state
def daily_counter(db: Session, player: Player) -> DailyCounter:
    key = day_key()
    row = db.scalar(select(DailyCounter).where(DailyCounter.player_id == player.id, DailyCounter.day == key))
    if not row:
        row = DailyCounter(player_id=player.id, day=key)
        db.add(row)
        db.flush()
    return row


def state_payload(db: Session, player: Player) -> dict[str, Any]:
    counter = daily_counter(db, player)
    tasks_done = {
        t.task_id: t.claimed
        for t in db.scalars(select(DailyTask).where(DailyTask.player_id == player.id, DailyTask.day == counter.day))
    }
    history = db.scalars(
        select(SummonLog).where(SummonLog.player_id == player.id).order_by(SummonLog.id.desc()).limit(60)
    ).all()
    events = {}
    for row in db.scalars(select(EventProgress).where(EventProgress.player_id == player.id)):
        events.setdefault(row.event_id, {})[row.step_id] = row.claimed
    pets = [pet_payload(p) for p in sorted(player.pets, key=lambda p: (rules.RARITIES[rules.PET_BY_ID[p.pet_id]["rarity"]]["order"], -p.level))]
    items = sorted(i.item_id for i in player.items)
    last = aware(player.daily_last)
    return {
        "player": {
            "id": player.id,
            "name": player.name,
            "avatar": player.avatar,
            "level": player.level,
            "xp": player.xp,
            "xpNeeded": account_xp_needed(player.level),
            "isAdmin": player.is_admin,
            "createdAt": player.created_at.isoformat(),
        },
        "wallet": {"coins": player.coins, "gems": player.gems, "eggs": player.eggs},
        "activePetId": player.active_pet_id,
        "pets": pets,
        "items": items,
        "equipped": [i.item_id for i in player.items if i.equipped],
        "themes": {"world": player.world_theme, "ui": player.ui_theme},
        "pity": {"epic": player.pity_epic, "legendary": player.pity_legendary, "total": player.pity_total},
        "history": [
            {
                "petId": h.pet_id,
                "name": rules.PET_BY_ID[h.pet_id]["name"],
                "asset": rules.PET_BY_ID[h.pet_id]["asset"],
                "rarity": h.rarity,
                "isNew": h.is_new,
                "gems": h.gems,
                "pity": h.pity,
                "at": h.created_at.replace(tzinfo=timezone.utc).isoformat(),
            }
            for h in history
        ],
        "daily": {
            "streak": player.daily_streak,
            "last": last.isoformat() if last else None,
            "canClaim": last is None or datetime.now(timezone.utc) - last >= DAY,
        },
        "tasks": {
            "day": counter.day,
            "progress": {"games": counter.games, "pairs": counter.pairs, "summons": counter.summons, "stars": counter.stars},
            "claimed": [tid for tid, done in tasks_done.items() if done],
        },
        "events": events,
        "settings": {"sound": player.sound, "volume": player.volume},
        "petsPatted": player.pets_patted,
    }


def account_xp_needed(level: int) -> int:
    return 100 + level * 40


# ---------------------------------------------------------------- economy
def add_wallet(player: Player, coins: int = 0, gems: int = 0, eggs: int = 0) -> None:
    if player.coins + coins < 0 or player.gems + gems < 0 or player.eggs + eggs < 0:
        raise HTTPException(400, "insufficient_funds")
    player.coins += coins
    player.gems += gems
    player.eggs += eggs


def buy_eggs(db: Session, player: Player, count: int) -> dict[str, Any]:
    if count < 1:
        raise HTTPException(400, "bad_count")
    cost = rules.EGG_PRICE * count
    if player.gems < cost:
        raise HTTPException(400, "insufficient_funds")
    player.gems -= cost
    player.eggs += count
    log(db, player, "buy_eggs", gems=-cost, eggs=count, note=f"{count} яиц")
    db.commit()
    db.refresh(player)
    return {"wallet": {"coins": player.coins, "gems": player.gems, "eggs": player.eggs}, "spent": cost, "maxAffordable": player.gems // rules.EGG_PRICE}


def roll_rarity(pity_epic: int, pity_legendary: int, rng: random.Random) -> tuple[str, bool]:
    """Гаранты: 10-е открытие — легендарка (приоритет), 5-е — эпик или выше."""
    if pity_legendary >= rules.LEGENDARY_PITY - 1:
        return "legendary", True
    if pity_epic >= rules.EPIC_PITY - 1:
        return ("legendary" if rng.random() < 0.10 else "epic"), True
    roll = rng.random() * 100
    for rarity, meta in rules.RARITIES.items():
        roll -= meta["rate"]
        if roll <= 0:
            return rarity, False
    return "common", False


def summon(db: Session, player: Player, count: int, rng: random.Random | None = None) -> dict[str, Any]:
    if count not in (1, 5):
        raise HTTPException(400, "bad_count")
    if player.eggs < count:
        raise HTTPException(400, "not_enough_eggs")
    rng = rng or random.Random()

    owned = {p.pet_id: p for p in player.pets}
    results: list[dict[str, Any]] = []
    pity_epic, pity_legendary = player.pity_epic, player.pity_legendary

    for _ in range(count):
        rarity, pity_used = roll_rarity(pity_epic, pity_legendary, rng)
        pool = rules.pets_by_rarity(rarity) or rules.SUMMON_POOL
        pet = rng.choice(pool)
        existing = owned.get(pet["id"])
        is_new = existing is None
        gems = 0
        if is_new:
            created = PlayerPet(player_id=player.id, pet_id=pet["id"], level=1, xp=0, form=1)
            db.add(created)
            owned[pet["id"]] = created
        else:
            gems = rules.RARITIES[rarity]["dupGems"]
            player.gems += gems

        pity_epic = 0 if rarity in ("epic", "legendary") else pity_epic + 1
        pity_legendary = 0 if rarity == "legendary" else pity_legendary + 1
        player.pity_total += 1

        db.add(
            SummonLog(
                player_id=player.id, pet_id=pet["id"], rarity=rarity, is_new=is_new, gems=gems, pity=pity_used,
            )
        )
        results.append(
            {
                "petId": pet["id"],
                "name": pet["name"],
                "title": pet["title"],
                "asset": pet["asset"],
                "rarity": rarity,
                "isNew": is_new,
                "gems": gems,
                "pity": pity_used,
            }
        )

    player.eggs -= count
    player.pity_epic = pity_epic
    player.pity_legendary = pity_legendary
    log(db, player, "summon", eggs=-count, gems=sum(r["gems"] for r in results), note=", ".join(r["name"] for r in results))
    db.commit()
    db.refresh(player)
    counter = daily_counter(db, player)
    counter.summons += count
    db.commit()
    return {
        "results": results,
        "wallet": {"coins": player.coins, "gems": player.gems, "eggs": player.eggs},
        "pity": {"epic": player.pity_epic, "legendary": player.pity_legendary, "total": player.pity_total},
    }


def buy_item(db: Session, player: Player, item_id: str, qty: int = 1) -> dict[str, Any]:
    item = rules.ITEM_BY_ID.get(item_id)
    if not item:
        raise HTTPException(404, "item_not_found")
    if qty != 1:
        raise HTTPException(400, "single_copy_item")
    owned = {i.item_id: i for i in player.items}
    if item_id in owned:
        if item["kind"] in ("cosmetic", "collectible"):
            # Дубликат предмета конвертируется в монеты (ТЗ 15.3).
            coins = rules.RARITIES[item["rarity"]]["itemCoins"]
            player.coins += coins
            log(db, player, "dup_item", coins=coins, note=item_id)
            db.commit()
            return {"duplicate": True, "coins": coins, "state": state_payload(db, player)}
        raise HTTPException(400, "already_owned")

    price, currency = item["price"], item["currency"]
    if currency == "coins" and player.coins < price:
        raise HTTPException(400, "insufficient_funds")
    if currency == "gems" and player.gems < price:
        raise HTTPException(400, "insufficient_funds")
    if currency == "coins":
        player.coins -= price
    else:
        player.gems -= price
    db.add(PlayerItem(player_id=player.id, item_id=item_id))
    log(db, player, "buy_item", coins=-price if currency == "coins" else 0, gems=-price if currency == "gems" else 0, note=item_id)
    db.commit()
    db.refresh(player)
    return {"duplicate": False, "item": item, "state": state_payload(db, player)}


def equip(db: Session, player: Player, item_id: str, equipped: bool) -> dict[str, Any]:
    item = rules.ITEM_BY_ID.get(item_id)
    if not item:
        raise HTTPException(404, "item_not_found")
    row = next((i for i in player.items if i.item_id == item_id), None)
    if not row:
        raise HTTPException(400, "not_owned")
    if item["kind"] == "cosmetic":
        if equipped:
            # Ограничение совместимости: не более двух эффектов одного слоя.
            same_layer = [
                i for i in player.items
                if i.equipped and rules.ITEM_BY_ID[i.item_id]["kind"] == "cosmetic"
                and rules.ITEM_BY_ID[i.item_id].get("layer") == item.get("layer") and i.item_id != item_id
            ]
            if same_layer:
                raise HTTPException(400, "layer_conflict")
        row.equipped = equipped
    elif item["kind"] == "world":
        if not equipped:
            raise HTTPException(400, "theme_must_be_selected")
        player.world_theme = item_id
    elif item["kind"] == "ui":
        if not equipped:
            raise HTTPException(400, "theme_must_be_selected")
        player.ui_theme = item_id
    db.commit()
    db.refresh(player)
    return state_payload(db, player)


# ---------------------------------------------------------------- tests
def submit_test(db: Session, player: Player, payload: dict[str, Any]) -> dict[str, Any]:
    level_id = int(payload["levelId"])
    if level_id not in rules.LEVEL_BY_ID:
        raise HTTPException(404, "level_not_found")
    stars = max(0, min(3, int(payload.get("stars", 0))))
    score = max(0, min(100, int(payload.get("score", 0))))
    difficulty = rules.difficulty_of(level_id)
    xp = rules.DIFFICULTY_XP[difficulty]

    db.add(
        TestRun(
            player_id=player.id, level_id=level_id, score=score, stars=stars,
            pairs=int(payload.get("pairs", 0)), moves=int(payload.get("moves", 0)),
            errors=int(payload.get("errors", 0)), duration_ms=int(payload.get("durationMs", 0)),
        )
    )
    coins = 40 + level_id * 6 + stars * 20
    gems = 4 if stars >= 3 else 2 if stars == 2 else 1
    add_wallet(player, coins=coins, gems=gems)
    log(db, player, "test", coins=coins, gems=gems, note=f"Уровень {level_id}, {stars}★")

    active = player.active_pet
    pet_levels: list[int] = []
    evo: list[int] = []
    if active is not None:
        active.xp += xp
        pet_levels = level_up_pet(active)
        evo = grant_evolution_items(active, pet_levels)

    player.xp += xp
    account_levels = 0
    while player.xp >= account_xp_needed(player.level) and account_levels < 50:
        player.xp -= account_xp_needed(player.level)
        player.level += 1
        account_levels += 1

    counter = daily_counter(db, player)
    counter.games += 1
    counter.pairs += int(payload.get("pairs", 0))
    counter.stars += stars
    log(db, player, "xp", note=f"+{xp} XP питомцу")
    db.commit()
    db.refresh(player)
    return {
        "reward": {"coins": coins, "gems": gems, "xp": xp, "petLevels": pet_levels, "evoItems": evo},
        "accountLevelUp": account_levels,
        "state": state_payload(db, player),
    }


def evolve(db: Session, player: Player, pet_id: str) -> dict[str, Any]:
    pet = next((p for p in player.pets if p.pet_id == pet_id), None)
    if not pet:
        raise HTTPException(404, "pet_not_found")
    if not can_evolve(pet):
        raise HTTPException(400, "evolution_not_ready")
    pet.evo_items -= 1
    pet.form = min(3, pet.form + 1)
    log(db, player, "evolve", note=pet_id)
    db.commit()
    db.refresh(player)
    return {"pet": pet_payload(pet), "state": state_payload(db, player)}


# ---------------------------------------------------------------- rewards
def claim_daily(db: Session, player: Player) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    last = aware(player.daily_last)
    if last and now - last < DAY:
        raise HTTPException(400, "already_claimed")
    streak = player.daily_streak + 1 if last and now - last < DAY * 2 else 1
    index = (streak - 1) % 7
    reward = rules.DAILY_REWARDS[index]
    coins, gems, eggs = reward["coins"], reward["gems"], reward.get("eggs", 0)
    pet_granted = None
    if reward.get("pet"):
        pet_id = reward["pet"]
        if not any(p.pet_id == pet_id for p in player.pets):
            db.add(PlayerPet(player_id=player.id, pet_id=pet_id, level=1, xp=0, form=1))
            pet_granted = pet_id
        else:
            gems += rules.RARITIES[rules.PET_BY_ID[pet_id]["rarity"]]["dupGems"]
    add_wallet(player, coins=coins, gems=gems, eggs=eggs)
    player.daily_streak = streak
    player.daily_last = now
    log(db, player, "daily", coins=coins, gems=gems, eggs=eggs, note=f"День {index + 1}")
    db.commit()
    db.refresh(player)
    return {
        "day": index + 1,
        "label": reward["label"],
        "reward": {"coins": coins, "gems": gems, "eggs": eggs},
        "pet": pet_granted,
        "state": state_payload(db, player),
    }


def claim_task(db: Session, player: Player, task_id: str) -> dict[str, Any]:
    task = next((t for t in rules.TASKS if t["id"] == task_id), None)
    if not task:
        raise HTTPException(404, "task_not_found")
    counter = daily_counter(db, player)
    row = db.scalar(
        select(DailyTask).where(DailyTask.player_id == player.id, DailyTask.day == counter.day, DailyTask.task_id == task_id)
    )
    if row and row.claimed:
        raise HTTPException(400, "already_claimed")
    progress = getattr(counter, task["metric"])
    if progress < task["goal"]:
        raise HTTPException(400, "task_incomplete")
    if not row:
        row = DailyTask(player_id=player.id, day=counter.day, task_id=task_id, claimed=True)
        db.add(row)
    row.claimed = True
    add_wallet(player, coins=task["coins"], gems=task["gems"])
    log(db, player, "task", coins=task["coins"], gems=task["gems"], note=task_id)
    db.commit()
    db.refresh(player)
    return {"reward": {"coins": task["coins"], "gems": task["gems"]}, "state": state_payload(db, player)}


def claim_event(db: Session, player: Player, event_id: str, step_id: str) -> dict[str, Any]:
    event = rules.STARTER_EVENT if event_id == rules.STARTER_EVENT["id"] else None
    if not event:
        raise HTTPException(404, "event_not_found")
    step = next((s for s in event["steps"] if s["id"] == step_id), None)
    if not step:
        raise HTTPException(404, "step_not_found")
    row = db.scalar(
        select(EventProgress).where(
            EventProgress.player_id == player.id, EventProgress.event_id == event_id, EventProgress.step_id == step_id
        )
    )
    if row and row.claimed:
        raise HTTPException(400, "already_claimed")

    counter = daily_counter(db, player)
    days = max(1, (datetime.now(timezone.utc) - aware(player.created_at)).days + 1)
    metrics = {
        "games": counter.games,
        "pairs": counter.pairs,
        "summons": counter.summons,
        "stars": counter.stars,
        "pets_patted": player.pets_patted,
        "days": days,
    }
    if metrics.get(step["metric"], 0) < step["goal"]:
        raise HTTPException(400, "step_incomplete")

    if not row:
        row = EventProgress(player_id=player.id, event_id=event_id, step_id=step_id)
        db.add(row)
    row.claimed = True
    row.claimed_at = datetime.now(timezone.utc)
    add_wallet(player, coins=step["coins"], gems=step["gems"], eggs=step.get("eggs", 0))
    log(db, player, "event", coins=step["coins"], gems=step["gems"], eggs=step.get("eggs", 0), note=f"{event_id}/{step_id}")
    db.commit()
    db.refresh(player)
    return {"reward": {"coins": step["coins"], "gems": step["gems"], "eggs": step.get("eggs", 0)}, "state": state_payload(db, player)}


def pat_pet(db: Session, player: Player) -> dict[str, Any]:
    player.pets_patted += 1
    db.commit()
    return {"petsPatted": player.pets_patted}
