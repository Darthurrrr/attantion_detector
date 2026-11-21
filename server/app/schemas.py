"""Pydantic-схемы запросов и ответов."""
from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class RegisterIn(BaseModel):
    deviceId: str = Field(min_length=4, max_length=96)
    name: str | None = Field(default=None, max_length=24)


class RegisterOut(BaseModel):
    token: str
    state: dict[str, Any]


class ProfileIn(BaseModel):
    name: str | None = Field(default=None, max_length=24)
    avatar: str | None = Field(default=None, max_length=64)


class SettingsIn(BaseModel):
    sound: bool | None = None
    volume: float | None = Field(default=None, ge=0, le=1)


class BuyEggsIn(BaseModel):
    count: int = Field(ge=1, le=50)


class SummonIn(BaseModel):
    count: Literal[1, 5] = 1


class TestIn(BaseModel):
    levelId: int = Field(ge=1, le=999)
    score: int = Field(ge=0, le=100)
    stars: int = Field(ge=0, le=3)
    pairs: int = Field(default=0, ge=0, le=400)
    moves: int = Field(default=0, ge=0, le=2000)
    errors: int = Field(default=0, ge=0, le=2000)
    durationMs: int = Field(default=0, ge=0, le=3_600_000)


class TaskClaimIn(BaseModel):
    taskId: str


class EventClaimIn(BaseModel):
    eventId: str
    stepId: str


class PetActionIn(BaseModel):
    petId: str


class BuyItemIn(BaseModel):
    itemId: str
    qty: int = Field(default=1, ge=1, le=20)


class EquipIn(BaseModel):
    itemId: str


class AdminGrantIn(BaseModel):
    coins: int = Field(default=0, ge=-1_000_000, le=1_000_000)
    gems: int = Field(default=0, ge=-1_000_000, le=1_000_000)
    eggs: int = Field(default=0, ge=-1000, le=1000)
    note: str = Field(default="admin", max_length=120)


class AdminPetIn(BaseModel):
    petId: str
    level: int | None = Field(default=None, ge=1, le=99)
    xp: int | None = Field(default=None, ge=0, le=100_000)
    form: int | None = Field(default=None, ge=1, le=3)
    active: bool = False


class AdminPityIn(BaseModel):
    epic: int = Field(default=0, ge=0, le=4)
    legendary: int = Field(default=0, ge=0, le=9)
    total: int | None = Field(default=None, ge=0)


class AdminItemIn(BaseModel):
    itemId: str
    qty: int = Field(default=1, ge=1, le=99)


class AdminBootstrapIn(BaseModel):
    secret: str
