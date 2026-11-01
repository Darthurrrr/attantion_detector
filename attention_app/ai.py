"""Точка подключения внешних ИИ (GigaChat, YandexGPT и т.д.).

Сейчас коуч работает по правилам из logic.py. Чтобы включить внешний ИИ:
1. Задайте переменную окружения AI_PROVIDER (например, gigachat или yandex).
2. Реализуйте вызов в call_provider() ниже.
Если внешний ИИ недоступен или вернул ошибку, приложение само откатится на правила.
"""
import os
import re

import logic

PROVIDER = os.getenv("AI_PROVIDER", "rules").lower()
EMOTIONS = {"neutral", "happy", "excited", "wink", "curious", "sleepy", "sad", "worried", "angry",
            "surprised", "thinking", "shy", "confused", "stress", "support"}


def build_prompt(text, rows, name):
    """Системный промпт + контекст ученика. Годится для любого провайдера."""
    s = logic.summary(rows)
    stats = ", ".join(
        f"{logic.TEST_NAMES.get(t, t)}: лучший {v['best']}, средний {v['avg']}"
        for t, v in s["tests"].items()
    ) or "данных пока нет"
    system = (
        "Ты дружелюбный коуч по вниманию для школьников. Отвечай коротко (2-4 предложения), "
        "по-русски, без медицинских диагнозов. В самом начале ответа поставь тег эмоции "
        "[emotion=X], где X одно из: neutral, happy, excited, wink, curious, sleepy, sad, worried, surprised, "
        "thinking, shy, confused, stress, support."
    )
    context = (
        f"Ученик: {name or 'не указано'}. Общая оценка: {s['overall']}. "
        f"Динамика: {s['trend']}. Серия дней: {s['streak']}. Результаты: {stats}."
    )
    return system, f"{context}\n\nСообщение ученика: {text}"


def parse_emotion(raw):
    """Достаёт тег [emotion=X] из ответа модели."""
    m = re.match(r"\s*\[emotion=(\w+)\]\s*", raw or "")
    if m and m.group(1) in EMOTIONS:
        return raw[m.end():].strip(), m.group(1)
    return (raw or "").strip(), logic.detect_emotion(raw or "")


def call_provider(system, user_message):
    """TODO: здесь HTTP-запрос к вашему ИИ. Должен вернуть строку с ответом модели."""
    raise NotImplementedError(f"Провайдер «{PROVIDER}» ещё не подключён")


def external_reply(text, rows, name):
    """Возвращает (ответ, эмоция) или None, если нужно использовать правила."""
    if PROVIDER == "rules":
        return None
    system, user_message = build_prompt(text, rows, name)
    return parse_emotion(call_provider(system, user_message))
