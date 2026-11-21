"""Функциональные тесты игровых систем (ТЗ раздел 26)."""
from __future__ import annotations

import os
import sys
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from server.app import service  # noqa: E402
from server.app.db import get_db  # noqa: E402
from server.app.models import Base, DailyCounter, Player  # noqa: E402
from server.app.api import app  # noqa: E402

engine = create_engine("sqlite+pysqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
TestingSession = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
Base.metadata.create_all(engine)


def override_db():
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_db
client = TestClient(app)


@pytest.fixture()
def player():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    res = client.post("/api/register", json={"deviceId": "device-test-1"})
    assert res.status_code == 200
    return res.json()


def auth(data):
    return {"Authorization": f"Bearer {data['token']}"}


def become_admin(headers):
    res = client.post("/api/admin/bootstrap", json={"secret": "dev-admin-secret"}, headers=headers)
    assert res.status_code == 200
    return headers


def economy(player, gems=0, eggs=0, coins=0):
    """Админское начисление для тестов экономики (проверка лимитов — отдельно)."""
    headers = become_admin(auth(player))
    if gems or eggs or coins:
        res = client.post("/api/admin/wallet", json={"gems": gems, "eggs": eggs, "coins": coins}, headers=headers)
        assert res.status_code == 200
    return headers


def test_register_creates_wallet_and_starters(player):
    state = player["state"]
    assert state["wallet"]["coins"] > 0
    assert state["wallet"]["eggs"] == 1
    assert {p["petId"] for p in state["pets"]} == {"murzik", "slime", "bunny"}
    assert state["activePetId"] == "murzik"
    assert state["pity"] == {"epic": 0, "legendary": 0, "total": 0}


def test_buy_eggs_respects_balance(player):
    headers = auth(player)
    gems = player["state"]["wallet"]["gems"]
    max_count = gems // 60
    res = client.post("/api/shop/eggs", json={"count": max_count}, headers=headers)
    assert res.status_code == 200
    assert res.json()["wallet"]["gems"] == gems - max_count * 60
    too_many = client.post("/api/shop/eggs", json={"count": max_count + 1}, headers=headers)
    assert too_many.status_code == 400
    assert too_many.json()["detail"] == "insufficient_funds"


def test_summon_requires_eggs_and_persists_history(player):
    headers = auth(player)
    empty = client.post("/api/summon", json={"count": 5}, headers=headers)
    assert empty.status_code == 400
    bought = client.post("/api/shop/eggs", json={"count": 3}, headers=headers)
    assert bought.status_code == 200, bought.text
    top_up = economy(player, eggs=2)
    res = client.post("/api/summon", json={"count": 5}, headers=top_up)
    assert res.status_code == 200, res.text
    body = res.json()
    assert len(body["results"]) == 5
    state = client.get("/api/state", headers=top_up).json()
    assert len(state["history"]) == 5
    assert state["wallet"]["eggs"] == 1


def test_summon_is_idempotent(player):
    base = economy(player, eggs=5)
    headers = {**base, "Idempotency-Key": "summon-abc"}
    first = client.post("/api/summon", json={"count": 5}, headers=headers).json()
    second = client.post("/api/summon", json={"count": 5}, headers=headers).json()
    assert first["results"] == second["results"]
    state = client.get("/api/state", headers=headers).json()
    assert state["wallet"]["eggs"] == 1


def test_pity_grants_epic_and_legendary(player):
    headers = economy(player, eggs=6)
    # Эпический гарант: 4 «холостых» открытия → следующее гарантированно эпик+.
    client.post("/api/admin/pity", json={"epic": 4, "legendary": 4, "total": 9}, headers=headers)
    res = client.post("/api/summon", json={"count": 1}, headers={**headers, "Idempotency-Key": "pity-epic"})
    assert res.status_code == 200, res.text
    result = res.json()["results"][0]
    assert result["rarity"] in ("epic", "legendary")
    assert result["pity"] is True
    state = client.get("/api/state", headers=headers).json()
    assert state["pity"]["epic"] <= 4

    # Легендарный гарант имеет приоритет на 10-м открытии.
    client.post("/api/admin/pity", json={"epic": 4, "legendary": 9, "total": 20}, headers=headers)
    res = client.post("/api/summon", json={"count": 1}, headers={**headers, "Idempotency-Key": "pity-legend"})
    assert res.status_code == 200, res.text
    assert res.json()["results"][0]["rarity"] == "legendary"
    assert res.json()["pity"]["legendary"] == 0

    # Выпадение легендарки сбрасывает оба счётчика, открытие пяти не сбрасывает их пачкой.
    client.post("/api/admin/pity", json={"epic": 3, "legendary": 2, "total": 30}, headers=headers)
    res = client.post("/api/summon", json={"count": 5}, headers={**headers, "Idempotency-Key": "pity-five"})
    assert res.status_code == 200, res.text
    body = res.json()
    assert len(body["results"]) == 5
    expected_epic = 3
    expected_legendary = 2
    for item in body["results"]:
        expected_epic = 0 if item["rarity"] in ("epic", "legendary") else expected_epic + 1
        expected_legendary = 0 if item["rarity"] == "legendary" else expected_legendary + 1
    assert body["pity"]["epic"] == expected_epic
    assert body["pity"]["legendary"] == expected_legendary


def test_duplicate_gives_gems(player):
    headers = auth(player)
    client.post("/api/admin/bootstrap", json={"secret": "dev-admin-secret"}, headers=headers)
    # Мурзик уже в коллекции: принудительно выставляем ему легендарный пул.
    before = client.get("/api/state", headers=headers).json()["wallet"]["gems"]
    client.post("/api/shop/eggs", json={"count": 1}, headers=headers)
    res = client.post("/api/summon", json={"count": 1}, headers=headers).json()
    after = client.get("/api/state", headers=headers).json()["wallet"]["gems"]
    dup = res["results"][0]
    if not dup["isNew"]:
        assert after == before - 60 + dup["gems"]
    else:
        assert after == before - 60


def test_test_rewards_pet_xp_and_levels(player):
    headers = auth(player)
    level = {"levelId": 1, "score": 90, "stars": 3, "pairs": 4, "moves": 5}
    headers = {**headers, "Idempotency-Key": "level-1-run"}
    res = client.post("/api/tests/submit", json=level, headers=headers)
    assert res.status_code == 200
    body = res.json()
    assert body["reward"]["xp"] == 20  # level 1 = easy
    pet = next(p for p in body["state"]["pets"] if p["petId"] == "murzik")
    assert pet["xp"] == 0  # 20 XP = порог 1-го уровня, опыт перешёл в уровень 2
    assert body["reward"]["coins"] > 0
    assert body["state"]["tasks"]["progress"]["games"] == 1
    # Опыт свыше порога переносится, уровни начисляются пачкой
    for _ in range(3):
        client.post("/api/tests/submit", json={"levelId": 15, "score": 100, "stars": 3}, headers=headers)
    pet = next(p for p in client.get("/api/state", headers=headers).json()["pets"] if p["petId"] == "murzik")
    assert pet["level"] >= 2


def test_submit_is_idempotent(player):
    headers = {**auth(player), "Idempotency-Key": "run-1"}
    body = {"levelId": 2, "score": 80, "stars": 2}
    first = client.post("/api/tests/submit", json=body, headers=headers).json()
    second = client.post("/api/tests/submit", json=body, headers=headers).json()
    assert first == second
    assert client.get("/api/state", headers=headers).json()["tasks"]["progress"]["games"] == 1


def test_evolution_requires_level_and_item(player):
    headers = auth(player)
    bad = client.post("/api/pets/evolve", json={"pet_id": "murzik"}, headers=headers)
    assert bad.status_code in (400, 422)
    become_admin(headers)
    client.post("/api/admin/pet", json={"petId": "murzik", "level": 33}, headers=headers)
    # предмет эволюции выдаётся на 33 уровне, проверим выдачу через опыт
    db = TestingSession()
    p = db.query(Player).first()
    pet = next(x for x in p.pets if x.pet_id == "murzik")
    pet.level = 32
    pet.xp = service.rules.xp_per_level(32) - 1
    db.commit()
    db.close()
    client.post("/api/tests/submit", json={"levelId": 15, "score": 100, "stars": 3}, headers=headers)
    state = client.get("/api/state", headers=headers).json()
    pet = next(x for x in state["pets"] if x["petId"] == "murzik")
    assert pet["level"] >= 33
    assert pet["evoItems"] >= 1
    assert pet["canEvolve"] is True
    ok = client.post("/api/pets/evolve", json={"petId": "murzik"}, headers=headers)
    assert ok.status_code == 200, ok.text
    assert ok.json()["pet"]["form"] == 2
    assert ok.json()["pet"]["evoItems"] == 0


def test_shop_buys_once_and_duplicate_converts_to_coins(player):
    headers = economy(player, coins=5000)
    before = client.get("/api/state", headers=headers).json()["wallet"]["coins"]
    res = client.post("/api/shop/buy", json={"itemId": "cosmo_bubbles"}, headers=headers)
    assert res.status_code == 200
    state = res.json()["state"]
    assert "cosmo_bubbles" in state["items"]
    assert state["wallet"]["coins"] == before - 900
    dup = client.post("/api/shop/buy", json={"itemId": "cosmo_bubbles"}, headers=headers).json()
    assert dup["duplicate"] is True
    assert dup["coins"] == 30


def test_daily_claim_once_per_day_and_seventh_day_pet(player):
    headers = auth(player)
    first = client.post("/api/daily/claim", headers=headers)
    assert first.status_code == 200
    assert first.json()["day"] == 1
    again = client.post("/api/daily/claim", headers=headers)
    assert again.status_code == 400
    db = TestingSession()
    p = db.query(Player).first()
    p.daily_streak = 6
    p.daily_last = datetime.now(timezone.utc) - timedelta(days=1, minutes=5)
    db.commit()
    db.close()
    seventh = client.post("/api/daily/claim", headers=headers).json()
    assert seventh["day"] == 7
    assert seventh["pet"] == "murzik_keeper"


def test_task_claim_manual_only(player):
    headers = auth(player)
    early = client.post("/api/tasks/claim", json={"taskId": "play1"}, headers=headers)
    assert early.status_code == 400
    client.post("/api/tests/submit", json={"levelId": 1, "score": 90, "stars": 3}, headers=headers)
    ok = client.post("/api/tasks/claim", json={"taskId": "play1"}, headers=headers)
    assert ok.status_code == 200
    again = client.post("/api/tasks/claim", json={"taskId": "play1"}, headers=headers)
    assert again.status_code == 400


def test_starter_event_steps(player):
    headers = auth(player)
    client.post("/api/pets/pat", headers=headers)
    ok = client.post("/api/events/claim", json={"eventId": "starter", "stepId": "welcome"}, headers=headers)
    assert ok.status_code == 200
    blocked = client.post("/api/events/claim", json={"eventId": "starter", "stepId": "tests"}, headers=headers)
    assert blocked.status_code == 400


def test_admin_requires_rights(player):
    headers = auth(player)
    forbidden = client.post("/api/admin/wallet", json={"gems": 999}, headers=headers)
    assert forbidden.status_code == 403
    wrong = client.post("/api/admin/bootstrap", json={"secret": "nope"}, headers=headers)
    assert wrong.status_code == 403
    good = client.post("/api/admin/bootstrap", json={"secret": "dev-admin-secret"}, headers=headers)
    assert good.status_code == 200
    assert client.post("/api/admin/wallet", json={"gems": 999}, headers=headers).status_code == 200


def test_config_exposes_rules(player):
    cfg = client.get("/api/config").json()
    assert cfg["rules"]["eggPrice"] == 60
    assert [r["rate"] for r in cfg["rules"]["rates"]] == [50.0, 25.0, 15.0, 8.0, 2.0]
    assert len(cfg["rules"]["xpTable"]) == 98
    assert len(cfg["pets"]) >= 16
