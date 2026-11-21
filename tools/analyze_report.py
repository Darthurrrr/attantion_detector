"""Преобразует вывод `flutter analyze` в аннотации GitHub Actions.

Запуск: python3 tools/analyze_report.py /tmp/analyze.txt
Ошибки и предупреждения показываются в аннотациях, информационные подсказки
только подсчитываются. Исходный код клиента находится в flutter_app/.
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
    found.sort(key=lambda g: ORDER[g[0]])

    counts: dict[str, int] = {}
    for level, *_ in found:
        counts[level] = counts.get(level, 0) + 1

    actionable = [entry for entry in found if entry[0] != "info"]
    for level, message, file, row, col, rule in actionable[:80]:
        # Анализ запускается из flutter_app, а аннотации привязаны к корню репозитория.
        if not file.startswith("flutter_app/"):
            file = f"flutter_app/{file}"
        print(f"::{level} file={file},line={row},col={col}::{message} ({rule})")

    summary = ", ".join(f"{k}: {v}" for k, v in sorted(counts.items())) or "нет замечаний"
    print(f"::notice::замечаний анализа — {summary}")

    errors = counts.get("error", 0)
    if errors:
        print(f"::error::сборка не пройдёт из-за {errors} ошибок анализа")
        return 1
    if not found and "No issues found!" not in raw:
        tail = " ".join(lines)[-900:] or "пустой вывод"
        print(f"::warning::flutter analyze не дал разбираемых строк: {tail}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
