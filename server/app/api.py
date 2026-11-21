"""FastAPI-роуты «Детектора внимания»."""
from __future__ import annotations

import contextlib
import os
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import rules, service
from .db import get_db, init_models
from .models import Player, PlayerItem, PlayerPet, Transaction
from .schemas import (
    AdminBootstrapIn,
    AdminGrantIn,
    AdminItemIn,
    AdminPetIn,
    AdminPityIn,
    BuyEggsIn,
    BuyItemIn,
    EquipIn,
    EventClaimIn,
    PetActionIn,
    ProfileIn,
    RegisterIn,
    SettingsIn,
    SummonIn,
    TaskClaimIn,
    TestIn,
)

ADMIN_SECRET = os.environ.get("ADMIN_SECRET", "dev-admin-secret")

@contextlib.asynccontextmanager
async def _lifespan(app_: FastAPI):
    """Создаём таблицы при старте (в проде — миграции Alembic)."""
    init_models()
    yield


app = FastAPI(title="Детектор внимания API", version="1.0.0", lifespan=_lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def current_player(
    db: Session = Depends(get_db),
    authorization: str | None = Header(default=None),
) -> Player:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "no_token")
    token = authorization.split(" ", 1)[1].strip()
    player = db.scalar(select(Player).where(Player.token_hash == service.hash_token(token)))
    if not player:
        raise HTTPException(401, "bad_token")
    return player


def admin_player(player: Player = Depends(current_player), x_admin_secret: str | None = Header(default=None)) -> Player:
    if not player.is_admin and x_admin_secret != ADMIN_SECRET:
        raise HTTPException(403, "admin_only")
    return player


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/config")
def config() -> dict[str, Any]:
    return {
        "pets": rules.PETS,
        "levels": rules.LEVELS,
        "chapters": rules.CHAPTERS,
        "rarities": rules.RARITIES,
        "shop": rules.SHOP_ITEMS,
        "tasks": rules.TASKS,
        "daily": rules.DAILY_REWARDS,
        "events": [rules.STARTER_EVENT],
        "rules": rules.rules_payload(),
    }


@app.post("/api/register")
def register(body: RegisterIn, db: Session = Depends(get_db)) -> dict[str, Any]:
    existing = db.scalar(select(Player).where(Player.device_id == body.deviceId))
    if existing:
        # Тот же девайс: выдаём новый токен, состояние не теряется.
        import secrets

        token = secrets.token_urlsafe(32)
        existing.token_hash = service.hash_token(token)
        db.commit()
        db.refresh(existing)
        return {"token": token, "state": service.state_payload(db, existing)}
    player, token = service.create_player(db, body.deviceId, body.name)
    return {"token": token, "state": service.state_payload(db, player)}


@app.get("/api/state")
def state(player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.state_payload(db, player)


@app.patch("/api/profile")
def profile(body: ProfileIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    if body.name is not None and body.name.strip():
        player.name = body.name.strip()[:24]
    if body.avatar:
        player.avatar = body.avatar
    db.commit()
    db.refresh(player)
    return service.state_payload(db, player)


@app.patch("/api/settings")
def settings(body: SettingsIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    if body.sound is not None:
        player.sound = body.sound
    if body.volume is not None:
        player.volume = round(body.volume, 2)
    db.commit()
    return {"settings": {"sound": player.sound, "volume": player.volume}}


@app.post("/api/pets/pat")
def pat(player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.pat_pet(db, player)


@app.post("/api/pets/active")
def set_active(body: PetActionIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    if not any(p.pet_id == body.petId for p in player.pets):
        raise HTTPException(400, "not_owned")
    player.active_pet_id = body.petId
    db.commit()
    db.refresh(player)
    return service.state_payload(db, player)


@app.post("/api/pets/evolve")
def evolve(body: PetActionIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.evolve(db, player, body.petId)


@app.post("/api/shop/eggs")
def buy_eggs(body: BuyEggsIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.buy_eggs(db, player, body.count)


@app.post("/api/shop/buy")
def buy(body: BuyItemIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.buy_item(db, player, body.itemId, body.qty)


@app.post("/api/inventory/equip")
def equip(body: EquipIn, equipped: bool = Query(default=True), player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.equip(db, player, body.itemId, equipped)


@app.post("/api/summon")
def summon(
    body: SummonIn,
    player: Player = Depends(current_player),
    db: Session = Depends(get_db),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
) -> dict[str, Any]:
    cached = service.idem_get(db, player, idempotency_key)
    if cached is not None:
        return cached
    payload = service.summon(db, player, body.count)
    service.idem_put(db, player, idempotency_key, payload)
    db.commit()
    return payload


@app.post("/api/tests/submit")
def submit(
    body: TestIn,
    player: Player = Depends(current_player),
    db: Session = Depends(get_db),
    idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"),
) -> dict[str, Any]:
    cached = service.idem_get(db, player, idempotency_key)
    if cached is not None:
        return cached
    payload = service.submit_test(db, player, body.model_dump())
    service.idem_put(db, player, idempotency_key, payload)
    db.commit()
    return payload


@app.post("/api/daily/claim")
def daily(player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.claim_daily(db, player)


@app.post("/api/tasks/claim")
def task(body: TaskClaimIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.claim_task(db, player, body.taskId)


@app.post("/api/events/claim")
def event(body: EventClaimIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    return service.claim_event(db, player, body.eventId, body.stepId)


@app.get("/api/history")
def history(
    rarity: str | None = None,
    player: Player = Depends(current_player),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    rows = service.state_payload(db, player)["history"]
    if rarity:
        rows = [r for r in rows if r["rarity"] == rarity]
    return {"history": rows}


@app.get("/api/transactions")
def transactions(admin: Player = Depends(admin_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    rows = db.scalars(
        select(Transaction).where(Transaction.player_id == admin.id).order_by(Transaction.id.desc()).limit(100)
    ).all()
    return {
        "transactions": [
            {"kind": r.kind, "coins": r.coins, "gems": r.gems, "eggs": r.eggs, "note": r.note, "at": r.created_at.isoformat()}
            for r in rows
        ]
    }


# ------------------------------------------------------------------ admin
@app.post("/api/admin/bootstrap")
def admin_bootstrap(body: AdminBootstrapIn, player: Player = Depends(current_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    if body.secret != ADMIN_SECRET:
        raise HTTPException(403, "bad_secret")
    player.is_admin = True
    db.commit()
    return {"isAdmin": True}


@app.post("/api/admin/wallet")
def admin_wallet(body: AdminGrantIn, player: Player = Depends(admin_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    service.add_wallet(player, body.coins, body.gems, body.eggs)
    service.log(db, player, "admin", body.coins, body.gems, body.eggs, body.note)
    db.commit()
    db.refresh(player)
    return service.state_payload(db, player)


@app.post("/api/admin/pet")
def admin_pet(body: AdminPetIn, player: Player = Depends(admin_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    if body.petId not in rules.PET_BY_ID:
        raise HTTPException(404, "pet_not_found")
    pet = next((p for p in player.pets if p.pet_id == body.petId), None)
    if not pet:
        pet = PlayerPet(player_id=player.id, pet_id=body.petId, level=1, xp=0, form=1)
        db.add(pet)
    if body.level is not None:
        pet.level = body.level
        pet.form = rules.form_for_level(pet.level)
    if body.xp is not None:
        pet.xp = body.xp
    if body.form is not None:
        pet.form = body.form
    if body.active:
        player.active_pet_id = pet.pet_id
    db.commit()
    db.refresh(player)
    return service.state_payload(db, player)


@app.post("/api/admin/pity")
def admin_pity(body: AdminPityIn, player: Player = Depends(admin_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    player.pity_epic = body.epic
    player.pity_legendary = body.legendary
    if body.total is not None:
        player.pity_total = body.total
    db.commit()
    return {"pity": {"epic": player.pity_epic, "legendary": player.pity_legendary, "total": player.pity_total}}


@app.post("/api/admin/item")
def admin_item(body: AdminItemIn, player: Player = Depends(admin_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    if body.itemId not in rules.ITEM_BY_ID:
        raise HTTPException(404, "item_not_found")
    owned = {i.item_id for i in player.items}
    if body.itemId in owned:
        coins = rules.RARITIES[rules.ITEM_BY_ID[body.itemId]["rarity"]]["itemCoins"]
        player.coins += coins
        service.log(db, player, "dup_item", coins=coins, note=body.itemId)
    else:
        db.add(PlayerItem(player_id=player.id, item_id=body.itemId))
        service.log(db, player, "admin_item", note=body.itemId)
    db.commit()
    db.refresh(player)
    return service.state_payload(db, player)


@app.post("/api/admin/unlock-all")
def admin_unlock_all(player: Player = Depends(admin_player), db: Session = Depends(get_db)) -> dict[str, Any]:
    owned = {p.pet_id for p in player.pets}
    for pet in rules.PETS:
        if pet["id"] not in owned:
            db.add(PlayerPet(player_id=player.id, pet_id=pet["id"], level=1, xp=0, form=1))
    for item in rules.SHOP_ITEMS:
        if item["id"] not in {i.item_id for i in player.items}:
            db.add(PlayerItem(player_id=player.id, item_id=item["id"]))
    db.commit()
    db.refresh(player)
    return service.state_payload(db, player)
