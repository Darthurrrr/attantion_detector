#!/usr/bin/env python3
"""Проверка каталога и синхронности общих ресурсов без внешних зависимостей."""

import json
import struct
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "ATTENTION_DETECTOR_ASSETS"
TARGETS = (ROOT / "flutter_app/assets", ROOT / "app/public/assets")


def image_info(data: bytes) -> tuple[str, int, int, bool]:
    if data.startswith(b"\x89PNG\r\n\x1a\n") and data[12:16] == b"IHDR":
        width, height = struct.unpack(">II", data[16:24])
        # В каталоге используются RGBA PNG, а не палитровые изображения с tRNS.
        alpha = data[25] in (4, 6)
        return "png", width, height, alpha
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        chunk = data[12:16]
        if chunk == b"VP8 " and data[23:26] == b"\x9d\x01\x2a":
            width, height = struct.unpack("<HH", data[26:30])
            return "webp", width & 0x3FFF, height & 0x3FFF, False
        if chunk == b"VP8X":
            width = 1 + int.from_bytes(data[24:27], "little")
            height = 1 + int.from_bytes(data[27:30], "little")
            return "webp", width, height, bool(data[20] & 0x10)
        if chunk == b"VP8L" and data[20] == 0x2F:
            bits = int.from_bytes(data[21:25], "little")
            return "webp", 1 + (bits & 0x3FFF), 1 + ((bits >> 14) & 0x3FFF), bool(bits & (1 << 28))
    raise ValueError("неподдерживаемый или повреждённый формат изображения")


def verify() -> int:
    manifest = json.loads((CATALOG / "manifest.json").read_text(encoding="utf-8"))
    seen_catalog: set[str] = set()
    seen_runtime: set[str] = set()
    errors: list[str] = []
    for asset in manifest["assets"]:
        catalog_name, runtime_name = asset["catalog"], asset["runtime"]
        if catalog_name in seen_catalog or runtime_name in seen_runtime:
            errors.append(f"{catalog_name}: повторяющийся путь")
        seen_catalog.add(catalog_name)
        seen_runtime.add(runtime_name)
        source = CATALOG / catalog_name
        try:
            data = source.read_bytes()
            if asset["format"] == "wav":
                with wave.open(str(source), "rb") as sound:
                    actual = (sound.getframerate(), sound.getnchannels())
                expected = (asset["sampleRate"], asset["channels"])
            else:
                actual = image_info(data)
                expected = (asset["format"], asset["width"], asset["height"], asset["alpha"])
            if actual != expected:
                errors.append(f"{catalog_name}: ожидается {expected}, получено {actual}")
            for target in TARGETS:
                copy = target / runtime_name
                if copy.read_bytes() != data:
                    errors.append(f"{copy.relative_to(ROOT)} отличается от каталога")
        except (OSError, ValueError, struct.error, wave.Error) as exc:
            errors.append(f"{catalog_name}: {exc}")
    if errors:
        print("Проверка ресурсов не пройдена:\n" + "\n".join(errors), file=sys.stderr)
        return 1
    print(f"Проверено ресурсов: {len(manifest['assets'])}; копии Flutter и веб-прототипа совпадают.")
    return 0


if __name__ == "__main__":
    sys.exit(verify())
