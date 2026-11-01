"""Проверка установки: запустите  python diagnostics.py  и пришлите вывод, если что-то не работает."""
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
print("Python:", sys.version.split()[0], "| система:", sys.platform)
try:
    from importlib.metadata import version
    print("Flet:", version("flet"))
except Exception as e:
    print("Flet не найден:", e)

print("\n--- Картинки ---")
for rel in ("robot/neutral.png", "robot/support.png", "ui/logo.png", "ui/bg_dark.jpg"):
    p = os.path.join(HERE, "assets", rel)
    print(("OK      " if os.path.exists(p) else "НЕТ     ") + p)

print("\n--- Звук ---")
try:
    import winsound
except ImportError:
    winsound = None
    print("winsound недоступен (не Windows)")
for name in ("tap", "success", "whoosh"):
    p = os.path.join(HERE, "sounds", name + ".wav")
    if not os.path.exists(p):
        print("НЕТ файла:", p)
        continue
    print("Играю", name, "...")
    if winsound:
        try:
            winsound.PlaySound(p, winsound.SND_FILENAME)
            print("   winsound: без ошибок (если не слышно, проверьте громкость и микшер громкости Windows)")
        except Exception as e:
            print("   winsound ошибка:", e)
    time.sleep(0.4)
print("\nГотово.")
