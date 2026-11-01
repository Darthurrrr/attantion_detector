"""Генерирует мягкие звуки интерфейса в папку sounds/ (tap, success, whoosh).
Это синтетические заготовки. Любой файл можно заменить своим .wav
(например, из Pixabay или Zapsplat) с тем же именем."""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sounds")


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * 0.85)) * 32767)) for s in samples)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def tap():
    """Мягкое «тук»: короткий тёплый щелчок (средние частоты, слышно даже на ноутбуке)."""
    random.seed(3)
    n = int(RATE * 0.09)
    out, p1, p2 = [], 0.0, 0.0
    for i in range(n):
        t = i / RATE
        f = 520 + 140 * math.exp(-t * 60)
        p1 += 2 * math.pi * f / RATE
        p2 += 2 * math.pi * f * 2.02 / RATE
        env = math.exp(-t * 48) * min(1.0, t / 0.0015)
        click = (random.uniform(-1, 1) * math.exp(-t * 900)) * 0.35
        out.append((math.sin(p1) + 0.45 * math.sin(p2)) * env + click)
    return out


def success():
    """Тихий колокольчик «динь»."""
    n = int(RATE * 1.3)
    parts = [(988, 1.0, 3.2), (1482, 0.45, 4.5), (1976, 0.22, 6.0), (2964, 0.08, 9.0)]
    out = []
    for i in range(n):
        t = i / RATE
        v = sum(a * math.sin(2 * math.pi * f * t) * math.exp(-t * d) for f, a, d in parts)
        out.append(v * min(1.0, t / 0.006))
    return out


def whoosh():
    """Лёгкий «вжух» (полосовой шум 700-3500 Гц)."""
    random.seed(7)
    n = int(RATE * 0.40)
    out, lo, hi = [], 0.0, 0.0
    for i in range(n):
        t = i / n
        k_hi = 0.10 + 0.35 * math.sin(math.pi * t)
        k_lo = 0.55
        x = random.uniform(-1, 1)
        hi += k_hi * (x - hi)
        lo += k_lo * (x - lo)
        out.append((lo - hi) * math.sin(math.pi * t) ** 1.4)
    return out


if __name__ == "__main__":
    save("tap", tap())
    save("success", success())
    save("whoosh", whoosh())
    print("Звуки созданы в", OUT)
