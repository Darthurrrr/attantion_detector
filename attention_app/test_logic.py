from datetime import date, timedelta

import ai
import logic

# --- баллы ---
assert logic.score_result("reaction", {"avg_ms": 250, "false_starts": 0}) >= 90
assert logic.score_result("reaction", {"avg_ms": 700, "false_starts": 0}) < 50
assert logic.score_result("stroop", {"correct": 10, "total": 10, "avg_ms": 800}) >= 90
assert logic.score_result("stroop", {"correct": 5, "total": 10, "avg_ms": 1500}) < 50
assert logic.score_result("schulte", {"size": 4, "seconds": 25, "errors": 0}) >= 60
assert logic.score_result("schulte", {"size": 4, "seconds": 60, "errors": 3}) < 40
assert logic.score_result("memory", {"max_len": 8}) == 100
assert logic.score_result("memory", {"max_len": 6}) == 60
assert logic.score_result("memory", {"max_len": 0}) == 0

# --- серия дней ---
today = date(2026, 10, 31)
mk = lambda d: {"created_at": (today - timedelta(days=d)).isoformat() + "T10:00:00"}
assert logic.streak_days([mk(0), mk(1), mk(2), mk(4)], today) == 3
assert logic.streak_days([mk(3)], today) == 0
assert logic.streak_days([], today) == 0

# --- сводка и сложность ---
rows = [
    {"test": "schulte", "score": 90, "metrics": {"size": 4}, "created_at": today.isoformat() + "T10:00:00"},
    {"test": "schulte", "score": 85, "metrics": {"size": 4}, "created_at": today.isoformat() + "T09:00:00"},
    {"test": "reaction", "score": 55, "metrics": {}, "created_at": today.isoformat() + "T08:00:00"},
    {"test": "memory", "score": 60, "metrics": {"max_len": 6}, "created_at": today.isoformat() + "T07:00:00"},
]
s = logic.summary(rows)
assert s["overall"] is not None and s["total"] == 4
d = logic.next_difficulty(rows)
assert d["schulte_size"] == 5 and d["memory_start"] == 5

# --- коуч и эмоции ---
assert logic.coach_reply("спасибо!", rows, "Аня")[1] == "excited"
assert logic.coach_reply("я устал", rows, "Аня")[1] == "support"
assert logic.coach_reply("ты молодец", rows, "Аня")[1] == "shy"
assert logic.coach_reply("боюсь экзамена", rows, "Аня")[1] == "support"
assert logic.coach_reply("привет", rows, "Аня")[1] == "happy"
assert logic.coach_reply("как мои результаты", rows, "Аня")[1] in ("happy", "wink", "support")
assert logic.coach_reply("", [], "")[1] == "confused"

# --- разбор ответа внешнего ИИ ---
assert ai.parse_emotion("[emotion=happy] Отлично!") == ("Отлично!", "happy")
assert ai.parse_emotion("Без тега")[0] == "Без тега"
assert ai.external_reply("привет", rows, "Аня") is None  # по умолчанию правила

print("ВСЕ ТЕСТЫ ПРОШЛИ")
