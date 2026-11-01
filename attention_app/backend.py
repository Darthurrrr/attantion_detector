import csv
import io
import json
import os
import sqlite3
from contextlib import closing
from datetime import datetime

from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel

import ai
import logic

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "attention_v2.db")
app = FastAPI(title="Детектор внимания API")


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with closing(get_db()) as c:
        c.execute(
            """CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL)"""
        )
        c.execute(
            """CREATE TABLE IF NOT EXISTS results (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                test TEXT NOT NULL,
                score INTEGER NOT NULL,
                level TEXT NOT NULL,
                metrics TEXT NOT NULL,
                created_at TEXT NOT NULL)"""
        )
        c.commit()


init_db()


def now():
    return datetime.now().isoformat(timespec="seconds")


def get_user(user_id):
    with closing(get_db()) as c:
        row = c.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Ученик не найден")
    return {"id": row["id"], "name": row["name"]}


def fetch_rows(user_id, limit=None):
    sql = "SELECT * FROM results WHERE user_id=? ORDER BY id DESC"
    if limit:
        sql += f" LIMIT {int(limit)}"
    with closing(get_db()) as c:
        rows = c.execute(sql, (user_id,)).fetchall()
    return [
        {
            "id": r["id"],
            "test": r["test"],
            "score": r["score"],
            "level": r["level"],
            "metrics": json.loads(r["metrics"]),
            "created_at": r["created_at"],
        }
        for r in rows
    ]


class UserIn(BaseModel):
    name: str


class ResultIn(BaseModel):
    user_id: int
    test: str
    metrics: dict


class ChatIn(BaseModel):
    user_id: int
    text: str


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/api/users")
def list_users():
    with closing(get_db()) as c:
        users = c.execute("SELECT * FROM users ORDER BY name").fetchall()
    out = []
    for u in users:
        s = logic.summary(fetch_rows(u["id"]))
        out.append({"id": u["id"], "name": u["name"], "overall": s["overall"],
                    "total": s["total"], "streak": s["streak"]})
    return out


@app.post("/api/users")
def create_user(item: UserIn):
    name = item.name.strip()[:30]
    if not name:
        raise HTTPException(status_code=400, detail="Введите имя")
    with closing(get_db()) as c:
        row = c.execute("SELECT * FROM users WHERE name=?", (name,)).fetchone()
        if row is None:
            cur = c.execute("INSERT INTO users (name, created_at) VALUES (?,?)", (name, now()))
            c.commit()
            return {"id": cur.lastrowid, "name": name}
    return {"id": row["id"], "name": row["name"]}


@app.post("/api/results")
def add_result(item: ResultIn):
    get_user(item.user_id)
    try:
        score = logic.score_result(item.test, item.metrics)
        rec = logic.recommendation(item.test, score, item.metrics)
    except (ValueError, KeyError, TypeError) as e:
        raise HTTPException(status_code=400, detail=f"Некорректные данные: {e}")
    level = logic.level_of(score)
    with closing(get_db()) as c:
        c.execute(
            "INSERT INTO results (user_id, test, score, level, metrics, created_at) VALUES (?,?,?,?,?,?)",
            (item.user_id, item.test, score, level, json.dumps(item.metrics), now()),
        )
        c.commit()
    return {"score": score, "level": level, "recommendation": rec}


@app.get("/api/history")
def history(user_id: int, limit: int = 30):
    return fetch_rows(user_id, limit)


@app.delete("/api/history")
def clear_history(user_id: int):
    with closing(get_db()) as c:
        c.execute("DELETE FROM results WHERE user_id=?", (user_id,))
        c.commit()
    return {"status": "cleared"}


@app.get("/api/summary")
def get_summary(user_id: int):
    return logic.summary(fetch_rows(user_id))


@app.get("/api/difficulty")
def get_difficulty(user_id: int):
    return logic.next_difficulty(fetch_rows(user_id))


@app.post("/api/chat")
def chat(item: ChatIn):
    user = get_user(item.user_id)
    rows = fetch_rows(item.user_id)
    reply = None
    try:
        reply = ai.external_reply(item.text, rows, user["name"])
    except Exception:
        reply = None  # внешний ИИ недоступен: откатываемся на правила
    if reply is None:
        reply = logic.coach_reply(item.text, rows, user["name"])
    return {"response": reply[0], "emotion": reply[1]}


@app.get("/api/export")
def export(user_id: int):
    get_user(user_id)
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["id", "тест", "балл", "уровень", "дата", "метрики"])
    for r in reversed(fetch_rows(user_id)):
        w.writerow([r["id"], logic.TEST_NAMES.get(r["test"], r["test"]), r["score"], r["level"],
                    r["created_at"], json.dumps(r["metrics"], ensure_ascii=False)])
    return PlainTextResponse(buf.getvalue(), media_type="text/csv; charset=utf-8")
