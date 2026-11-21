"""SQLAlchemy-модели: игрок, кошелёк, питомцы, инвентарь, призывы, задания."""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class Base(DeclarativeBase):
    pass


class Player(Base):
    __tablename__ = "players"

    id: Mapped[int] = mapped_column(primary_key=True)
    device_id: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    token_hash: Mapped[str] = mapped_column(String(128))
    name: Mapped[str] = mapped_column(String(32), default="Игрок123")
    avatar: Mapped[str] = mapped_column(String(32), default="assets/hero_avatar.png")
    level: Mapped[int] = mapped_column(Integer, default=1)
    xp: Mapped[int] = mapped_column(Integer, default=0)
    coins: Mapped[int] = mapped_column(Integer, default=1500)
    gems: Mapped[int] = mapped_column(Integer, default=120)
    eggs: Mapped[int] = mapped_column(Integer, default=1)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    active_pet_id: Mapped[str | None] = mapped_column(String(32), nullable=True)
    pity_epic: Mapped[int] = mapped_column(Integer, default=0)
    pity_legendary: Mapped[int] = mapped_column(Integer, default=0)
    pity_total: Mapped[int] = mapped_column(Integer, default=0)
    daily_streak: Mapped[int] = mapped_column(Integer, default=0)
    daily_last: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    world_theme: Mapped[str] = mapped_column(String(32), default="world_meadow")
    ui_theme: Mapped[str] = mapped_column(String(32), default="ui_violet")
    sound: Mapped[bool] = mapped_column(Boolean, default=True)
    volume: Mapped[float] = mapped_column(Float, default=0.8)
    pets_patted: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    pets: Mapped[list["PlayerPet"]] = relationship(back_populates="player", cascade="all, delete-orphan")
    items: Mapped[list["PlayerItem"]] = relationship(back_populates="player", cascade="all, delete-orphan")

    @property
    def active_pet(self) -> "PlayerPet | None":
        for pet in self.pets:
            if pet.pet_id == self.active_pet_id:
                return pet
        return None


class PlayerPet(Base):
    __tablename__ = "player_pets"
    __table_args__ = (UniqueConstraint("player_id", "pet_id", name="uq_player_pet"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    pet_id: Mapped[str] = mapped_column(String(32))
    level: Mapped[int] = mapped_column(Integer, default=1)
    xp: Mapped[int] = mapped_column(Integer, default=0)
    form: Mapped[int] = mapped_column(Integer, default=1)
    evo_items: Mapped[int] = mapped_column(Integer, default=0)
    obtained_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    player: Mapped[Player] = relationship(back_populates="pets")


class PlayerItem(Base):
    __tablename__ = "player_items"
    __table_args__ = (UniqueConstraint("player_id", "item_id", name="uq_player_item"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    item_id: Mapped[str] = mapped_column(String(48))
    equipped: Mapped[bool] = mapped_column(Boolean, default=False)
    obtained_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    player: Mapped[Player] = relationship(back_populates="items")


class SummonLog(Base):
    __tablename__ = "summon_log"

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    pet_id: Mapped[str] = mapped_column(String(32))
    rarity: Mapped[str] = mapped_column(String(16))
    is_new: Mapped[bool] = mapped_column(Boolean, default=True)
    gems: Mapped[int] = mapped_column(Integer, default=0)
    pity: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class TestRun(Base):
    __tablename__ = "test_runs"

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    level_id: Mapped[int] = mapped_column(Integer)
    score: Mapped[int] = mapped_column(Integer)
    stars: Mapped[int] = mapped_column(Integer)
    pairs: Mapped[int] = mapped_column(Integer, default=0)
    moves: Mapped[int] = mapped_column(Integer, default=0)
    errors: Mapped[int] = mapped_column(Integer, default=0)
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class DailyTask(Base):
    __tablename__ = "daily_tasks"
    __table_args__ = (UniqueConstraint("player_id", "day", "task_id", name="uq_task"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    day: Mapped[str] = mapped_column(String(16))
    task_id: Mapped[str] = mapped_column(String(32))
    claimed: Mapped[bool] = mapped_column(Boolean, default=False)


class DailyCounter(Base):
    __tablename__ = "daily_counters"
    __table_args__ = (UniqueConstraint("player_id", "day", name="uq_counter"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    day: Mapped[str] = mapped_column(String(16))
    games: Mapped[int] = mapped_column(Integer, default=0)
    pairs: Mapped[int] = mapped_column(Integer, default=0)
    summons: Mapped[int] = mapped_column(Integer, default=0)
    stars: Mapped[int] = mapped_column(Integer, default=0)


class EventProgress(Base):
    __tablename__ = "event_progress"
    __table_args__ = (UniqueConstraint("player_id", "event_id", "step_id", name="uq_event_step"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    event_id: Mapped[str] = mapped_column(String(32))
    step_id: Mapped[str] = mapped_column(String(32))
    claimed: Mapped[bool] = mapped_column(Boolean, default=False)
    claimed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(32))
    coins: Mapped[int] = mapped_column(Integer, default=0)
    gems: Mapped[int] = mapped_column(Integer, default=0)
    eggs: Mapped[int] = mapped_column(Integer, default=0)
    note: Mapped[str] = mapped_column(String(160), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class IdempotencyKey(Base):
    __tablename__ = "idempotency_keys"
    __table_args__ = (UniqueConstraint("player_id", "key", name="uq_idem"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id", ondelete="CASCADE"), index=True)
    key: Mapped[str] = mapped_column(String(96))
    payload: Mapped[str] = mapped_column(String(20000), default="{}")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
