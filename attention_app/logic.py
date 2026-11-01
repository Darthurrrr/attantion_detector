"""Логика оценки внимания: баллы, уровни, рекомендации, адаптивная сложность, коуч.
Без внешних зависимостей, чтобы её можно было тестировать отдельно."""

from datetime import date

TEST_NAMES = {
    "reaction": "Реакция",
    "stroop": "Тест Струпа",
    "schulte": "Таблица Шульте",
    "memory": "Память на числа",
}


def _clamp(x, lo=0.0, hi=100.0):
    return max(lo, min(hi, x))


def level_of(score):
    if score >= 80:
        return "высокий"
    if score >= 60:
        return "средний"
    return "низкий"


def score_result(test, m):
    """Переводит сырые метрики теста в балл 0..100."""
    if test == "reaction":
        avg = float(m["avg_ms"])
        false_starts = int(m.get("false_starts", 0))
        s = 100 - (avg - 220) * 0.15 - false_starts * 8
    elif test == "stroop":
        total = max(1, int(m["total"]))
        acc = int(m["correct"]) / total
        avg = float(m["avg_ms"])
        s = acc * 70 + _clamp(30 - (avg - 700) / 40, 0, 30)
    elif test == "schulte":
        size = int(m["size"])
        eff = float(m["seconds"]) + 2.0 * int(m.get("errors", 0))
        per_cell = eff / (size * size)
        s = 100 - (per_cell - 1.0) * 40
    elif test == "memory":
        s = (int(m["max_len"]) - 3) * 20
    else:
        raise ValueError(f"Неизвестный тест: {test}")
    return int(round(_clamp(s)))


def recommendation(test, score, m):
    name = TEST_NAMES[test]
    if test == "reaction" and int(m.get("false_starts", 0)) >= 2:
        return "Много ложных стартов: вы торопитесь. Попробуйте сначала дождаться сигнала, а потом реагировать."
    if test == "stroop" and int(m["correct"]) / max(1, int(m["total"])) < 0.8:
        return "Много ошибок в Струпе: замедлитесь и отвечайте на ЦВЕТ букв, а не на слово."
    if test == "schulte" and int(m.get("errors", 0)) >= 3:
        return "Много промахов в таблице Шульте: держите взгляд в центре и ищите цифру периферийным зрением."
    if test == "memory" and int(m.get("mistakes", 0)) >= 3:
        return "Попробуйте группировать цифры по 2-3 (например 48-215): так запоминать легче."
    if score >= 80:
        return f"{name}: отличный результат. Система предложит усложнение."
    if score >= 60:
        return f"{name}: хороший уровень. Ещё 2-3 тренировки, и можно усложнять."
    return f"{name}: пока ниже нормы. Тренируйтесь короткими сессиями по 5 минут и отдохните."


def streak_days(rows, today=None):
    """Сколько дней подряд (до сегодня/вчера) были тренировки."""
    days = sorted({r["created_at"][:10] for r in rows}, reverse=True)
    if not days:
        return 0
    today = today or date.today()
    cur = date.fromisoformat(days[0])
    if (today - cur).days > 1:
        return 0
    streak, prev = 1, cur
    for d in days[1:]:
        dd = date.fromisoformat(d)
        if (prev - dd).days == 1:
            streak += 1
            prev = dd
        else:
            break
    return streak


def summary(rows):
    """rows — результаты, новые сверху. Каждый: test, score, ..."""
    per = {}
    for r in rows:
        per.setdefault(r["test"], []).append(r["score"])
    tests = {}
    for t, scores in per.items():
        tests[t] = {
            "count": len(scores),
            "best": max(scores),
            "avg": round(sum(scores) / len(scores)),
            "last": scores[0],
        }
    overall = None
    if per:
        recent_avgs = [sum(s[:3]) / len(s[:3]) for s in per.values()]
        overall = int(round(sum(recent_avgs) / len(recent_avgs)))

    trend = None
    chrono = [r["score"] for r in reversed(rows)]
    if len(chrono) >= 4:
        last3 = sum(chrono[-3:]) / 3
        prev = chrono[-6:-3] or chrono[:-3]
        diff = last3 - sum(prev) / len(prev)
        trend = "up" if diff > 5 else "down" if diff < -5 else "flat"

    if not per:
        advice = "Пройдите первый тест, чтобы получить оценку внимания."
    else:
        weakest = min(tests, key=lambda t: tests[t]["avg"])
        missing = [t for t in TEST_NAMES if t not in tests]
        if missing:
            advice = f"Попробуйте ещё и «{TEST_NAMES[missing[0]]}», так оценка будет точнее."
        else:
            advice = f"Слабее всего у вас «{TEST_NAMES[weakest]}». Потренируйте именно этот тест."
    return {
        "overall": overall,
        "level": level_of(overall) if overall is not None else None,
        "trend": trend,
        "tests": tests,
        "advice": advice,
        "streak": streak_days(rows),
        "total": len(rows),
    }


def next_difficulty(rows):
    """Адаптивная сложность по последним результатам каждого теста."""
    def recent(test):
        return [r for r in rows if r["test"] == test][:3]

    size = 4
    rs = recent("schulte")
    if rs:
        avg = sum(r["score"] for r in rs) / len(rs)
        size = int(rs[0]["metrics"].get("size", 4)) + (1 if avg >= 80 else -1 if avg < 50 else 0)
    size = int(_clamp(size, 3, 5))

    trials = 10
    rs = recent("stroop")
    if rs and sum(r["score"] for r in rs) / len(rs) >= 80:
        trials = 15

    mem = 4
    rs = recent("memory")
    if rs:
        mem = int(_clamp(int(rs[0]["metrics"].get("max_len", 4)) - 1, 3, 8))
    return {"schulte_size": size, "stroop_trials": trials, "memory_start": mem}


TIPS = [
    "Работайте блоками 25 минут, затем 5 минут перерыв (метод Помодоро).",
    "Уберите телефон из поля зрения на время занятий: даже лежащий рядом он отвлекает.",
    "Сон 8-9 часов напрямую влияет на скорость реакции и устойчивость внимания.",
    "Короткая прогулка или вода перед занятием помогают сосредоточиться.",
    "Делайте одно дело за раз: переключение между задачами съедает внимание.",
]


def detect_emotion(text):
    t = (text or "").lower()
    if any(w in t for w in ("спасибо", "круто", "класс", "ура", "супер", "отлично", "здорово", "люблю")):
        return "excited"
    if any(w in t for w in ("молодец", "умница", "ты крутой", "красавчик")):
        return "shy"
    if any(w in t for w in ("привет", "здравств", "добрый", "хай")):
        return "happy"
    if any(w in t for w in ("устал", "груст", "плохо", "тяжело", "не получается", "надоел", "бесит", "скучно")):
        return "support"
    if any(w in t for w in ("спать", "сон", "сонн", "ночь", "не выспал")):
        return "sleepy"
    if any(w in t for w in ("вау", "ого", "серьезно", "серьёзно", "невероятно")) or "!!" in t:
        return "surprised"
    if any(w in t for w in ("волнуюсь", "страшно", "боюсь", "переживаю", "экзамен")):
        return "worried"
    return "neutral"


def coach_reply(text, rows, name=""):
    """Возвращает (ответ, эмоция). Эмоция управляет лицом робота."""
    t = (text or "").lower()
    s = summary(rows)
    who = f", {name}" if name else ""
    mood = detect_emotion(text)

    if mood == "excited":
        return f"Пожалуйста{who}! Мне приятно, что это помогает. Продолжим?", "excited"
    if mood == "shy":
        return "Ой, спасибо! Мне приятно, но главная заслуга ваша. Продолжим тренировку?", "shy"
    if mood == "support":
        return ("Бывает, внимание проседает у всех. Сделайте паузу на 5 минут, попейте воды, "
                "а потом пройдите один короткий тест. Я с вами."), "support"
    if mood == "worried":
        return "Понимаю, это волнительно. Дышите медленно и разбейте подготовку на короткие блоки по 25 минут.", "support"
    if mood == "sleepy":
        return "Похоже, вы не выспались. Сон 8-9 часов важнее любых тренировок. Отдохните и возвращайтесь.", "sleepy"
    if mood == "happy" and len(t) < 25:
        return f"Привет{who}! Я помогу разобраться с вашим вниманием. Спросите про результаты или тренировки.", "happy"
    if mood == "surprised":
        return "Ого! Расскажите подробнее, что случилось? Или спросите про свои результаты.", "surprised"

    if any(w in t for w in ("результат", "прогресс", "как мои", "статист", "оценк", "как дела")):
        if s["overall"] is None:
            return "Пока нет данных. Пройдите хотя бы один тест на вкладке «Тесты».", "curious"
        trend = {"up": "растёт", "down": "снижается", "flat": "стабильна", None: "пока недостаточно данных для тренда"}[s["trend"]]
        emo = "happy" if s["overall"] >= 80 else "wink" if s["overall"] >= 60 else "support"
        return (f"Общая оценка внимания: {s['overall']}/100 ({s['level']}). Динамика: {trend}. "
                f"{s['advice']}"), emo
    if any(w in t for w in ("тренир", "упражн", "что делать", "что мне", "посоветуй")):
        return s["advice"], "curious"
    if any(w in t for w in ("совет", "концентр", "внимани", "отвлека", "сосредот")):
        return TIPS[len(rows) % len(TIPS)], "happy"
    if any(w in t for w in ("серия", "стрик", "дней подряд")):
        return f"Серия тренировок: {s['streak']} дн. подряд. Занимайтесь каждый день хотя бы по 5 минут.", "excited"
    return ("Я умею: рассказать о ваших результатах, подсказать что тренировать и дать совет по "
            "концентрации. Спросите, например: «Как мои результаты?»"), "confused"
