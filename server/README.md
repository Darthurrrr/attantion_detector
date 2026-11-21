# Детектор внимания — сервер

FastAPI + PostgreSQL. Сервер — единственный источник истины: валюта, призыв,
гаранты, опыт и эволюции считаются здесь (ТЗ, разделы 2.3, 25).

## Запуск

```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export DATABASE_URL=postgresql+psycopg://attention:attention@localhost:5432/attention
export ADMIN_SECRET=change-me
uvicorn app.api:app --host 0.0.0.0 --port 8000
```

Или всё сразу: `docker compose up --build` (PostgreSQL + API на порту 8000).

## Роуты

| Метод | Путь | Назначение |
| --- | --- | --- |
| GET | `/api/config` | питомцы, уровни, магазин, задания, правила, таблица опыта |
| POST | `/api/register` | регистрация устройства, выдача токена и стартового набора |
| GET | `/api/state` | полное подтверждённое состояние игрока |
| PATCH | `/api/profile`, `/api/settings` | имя, аватар, звук, громкость |
| POST | `/api/pets/pat`, `/api/pets/active`, `/api/pets/evolve` | питомец |
| POST | `/api/shop/eggs`, `/api/shop/buy` | покупки |
| POST | `/api/inventory/equip` | экипировка эффектов и тем |
| POST | `/api/summon` | открытие 1 или 5 яиц (идемпотентно) |
| POST | `/api/tests/submit` | результат тренировки, награды и опыт (идемпотентно) |
| POST | `/api/daily/claim`, `/api/tasks/claim`, `/api/events/claim` | награды вручную |
| GET | `/api/history` | история призывов с фильтром по редкости |
| POST | `/api/admin/*` | админ-режим: валюта, питомцы, гаранты, предметы |
| GET | `/api/transactions` | журнал операций (админ) |

## Тесты

```bash
pip install pytest httpx
pytest -q
```

15 функциональных тестов по разделу 26 ТЗ: экономика, питомцы, призыв и гаранты,
инвентарь, события, права администратора.
