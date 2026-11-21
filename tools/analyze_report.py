"""Разбирает вывод `flutter analyze` и превращает его в аннотации GitHub Actions.

Запуск: python3 tools/analyze_report.py /tmp/analyze.txt
Скрипт печатает команды `::error`/`::warning` для строк с замечаниями, чтобы их было
видно в интерфейсе запуска и можно было прочитать через API, не скачивая логи.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LINE = re.compile(
    r"^\s*(error|warning|info)\s+•\s+(.*?)\s+•\s+(.+?):(\d+):(\d+)\s+•\s+(\S+)\s*$"
)
ORDER = {"error": 0, "warning": 1, "info": 2}


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else Path("/tmp/analyze.txt")
    raw = path.read_text(errors="replace") if path.exists() else ""
    lines = raw.splitlines()

    found = [m.groups() for m in (LINE.match(line) for line in lines) if m]
    found.sort(key=lambda g: ORDER.get(g[0], 3))

    counts: dict[str, int] = {}
    for level, *rest in found:
        counts[level] = counts.get(level, 0) + 1

    for level, message, file, row, col, rule in found[:80]:
        kind = "error" if level == "error" else "warning"
        print(f"::{kind} file={file},line={row},col={col}::{message} ({rule})")

    summary = ", ".join(f"{k}: {v}" for k, v in sorted(counts.items())) or "нет разбираемых строк"
    print(f"::notice::замечаний анализа — {summary}")

    errors = [g for g in found if g[0] == "error"]
    if errors:
        print(f"::error::сборка не пройдёт из-за {len(errors)} ошибок анализа")
        return 1
    if not found:
        tail = " ".join(lines)[-900:] or "пустой вывод"
        print(f"::error::flutter analyze не дал разбираемых строк: {tail}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
