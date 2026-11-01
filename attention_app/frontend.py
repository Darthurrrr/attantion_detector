import asyncio
import base64
import json
import math
import os
import random
import subprocess
import sys
import threading
import time
from datetime import datetime

import flet as ft
import requests

try:
    import winsound  # звуки на Windows без доп. библиотек
except ImportError:
    winsound = None

API = "http://127.0.0.1:8000/api"
HERE = os.path.dirname(os.path.abspath(__file__))
SETTINGS_FILE = os.path.join(HERE, "settings.json")

OK, BAD, WARN = "#22C55E", "#EF4444", "#F59E0B"
CYAN = "#5CE1FF"
SIDEBAR_W = 250
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets")
IMG_ASPECT = 380 / 560  # пропорции картинок робота

TEST_NAMES = {"reaction": "Реакция", "stroop": "Тест Струпа",
              "schulte": "Таблица Шульте", "memory": "Память на числа"}
TEST_ICONS = {"reaction": "🎯", "stroop": "⚡", "schulte": "➕", "memory": "🧠"}  # запасные значки
TEST_DESC = {
    "reaction": "5 попыток: жмите, как только круг станет зелёным.",
    "stroop": "Выбирайте ЦВЕТ букв, а не само слово.",
    "schulte": "Находите числа по порядку. Сложность подстраивается.",
    "memory": "Запомните число и введите его. С каждым успехом оно длиннее.",
}
TILE_COLORS = {
    "reaction": ["#6D4CFF", "#8B5CF6"], "schulte": ["#1E6FD9", "#2B8CFF"],
    "stroop": ["#12935F", "#1FBF7F"], "memory": ["#C2418E", "#E0529F"], "full": ["#D9722B", "#F59E0B"],
}
STROOP = [("КРАСНЫЙ", "#EF4444"), ("ЗЕЛЁНЫЙ", "#22C55E"), ("СИНИЙ", "#3B82F6"), ("ЖЁЛТЫЙ", "#EAB308")]
TIPS_UI = [
    ("⏱️", "Метод Помодоро", "Работайте 25 минут, затем отдыхайте 5. Внимание держится лучше короткими блоками."),
    ("📵", "Уберите телефон", "Даже лежащий рядом телефон отвлекает. Спрячьте его на время занятий."),
    ("😴", "Высыпайтесь", "Сон 8-9 часов напрямую влияет на скорость реакции и устойчивость внимания."),
    ("💧", "Пейте воду", "Небольшое обезвоживание снижает концентрацию. Стакан воды перед занятием помогает."),
    ("🚶", "Короткая прогулка", "10 минут на свежем воздухе перед уроками улучшают сосредоточенность."),
    ("🎯", "Одно дело за раз", "Переключение между задачами съедает внимание. Закончите одно, затем начинайте другое."),
]
MOTIVATION = ["Ты отлично справляешься!", "Маленькие шаги ведут к большим результатам!",
              "Я всегда рядом!", "Каждый день по чуть-чуть!"]

BOLD = ft.FontWeight.BOLD
CENTER = ft.TextAlign.CENTER


# ======================= Цвета и темы =======================
def alpha(color, a):
    """'#RRGGBB' -> '#AARRGGBB' (так Flet задаёт прозрачность)."""
    return f"#{int(a * 255):02X}{color[1:7]}"


THEMES = {
    "dark": dict(
        BG="#080C30", GRAD=["#070B2E", "#0F0F4A", "#1D1070"],
        CARD=alpha("#161B5A", 0.55), CARD2=alpha("#232A78", 0.60), SIDE=alpha("#050826", 0.70),
        TXT="#F1F4FF", MUTED="#9AA6D8", ACC="#6C63FF", BORDER=alpha("#FFFFFF", 0.12)),
    "light": dict(
        BG="#EAF3FF", GRAD=["#FFFFFF", "#E3EFFF", "#C9E2FF"],
        CARD=alpha("#FFFFFF", 0.62), CARD2=alpha("#D5E5FF", 0.70), SIDE=alpha("#1B2150", 0.94),
        TXT="#0F172A", MUTED="#52607F", ACC="#4F46E5", BORDER=alpha("#FFFFFF", 0.85)),
}


def apply_theme(name):
    globals().update(THEMES[name])


apply_theme("dark")


def _get(*paths):
    for path in paths:
        try:
            obj = ft
            for p in path:
                obj = getattr(obj, p)
            return obj
        except Exception:
            continue
    return None


def _align(upper, lower):
    A = getattr(ft, "Alignment", None)
    if A is not None and hasattr(A, upper):
        return getattr(A, upper)
    al = getattr(ft, "alignment", None)
    if al is not None and hasattr(al, lower):
        return getattr(al, lower)
    return None


def make_gradient(colors, vertical=False):
    kw = {"colors": colors}
    if vertical:
        b, e = _align("TOP_CENTER", "top_center"), _align("BOTTOM_CENTER", "bottom_center")
    else:
        b, e = _align("TOP_LEFT", "top_left"), _align("BOTTOM_RIGHT", "bottom_right")
    if b is not None and e is not None:
        kw.update(begin=b, end=e)
    try:
        return ft.LinearGradient(**kw)
    except Exception:
        return None


_ASSET_CACHE = {}
NEW_FLET = not hasattr(ft, "app")  # во Flet 1.0 функции ft.app больше нет
IMG_MODE = "bytes" if NEW_FLET else "base64"


def asset_bytes(rel):
    """Читает картинку из папки assets. Возвращает bytes или None, если файла нет."""
    if rel not in _ASSET_CACHE:
        try:
            with open(os.path.join(ASSETS_DIR, rel), "rb") as f:
                _ASSET_CACHE[rel] = f.read()
        except Exception:
            _ASSET_CACHE[rel] = None
    return _ASSET_CACHE[rel]


def make_image(data, **kw):
    global IMG_MODE
    if IMG_MODE == "bytes":
        try:
            return ft.Image(src=data, **kw)
        except Exception:
            IMG_MODE = "base64"
    b64 = base64.b64encode(data).decode("ascii")
    try:
        return ft.Image(src_base64=b64, **kw)
    except Exception:
        return ft.Image(src=b64, **kw)


def set_image(img, data):
    if data is None:
        return
    if IMG_MODE == "bytes":
        img.src = data
    else:
        try:
            img.src_base64 = base64.b64encode(data).decode("ascii")
        except Exception:
            img.src = base64.b64encode(data).decode("ascii")


def pic(rel, w=None, h=None, **kw):
    """Картинка из папки assets (путь вида 'ui/logo.png'). Если файла нет, остаётся пустое место."""
    if h is None and w is not None:
        h = w
    data = asset_bytes(rel)
    if data is None:
        return ft.Container(width=w, height=h)
    return make_image(data, width=w, height=h, **kw)


def fit_cover():
    return _get(("BoxFit", "COVER"), ("ImageFit", "COVER"))


def make_scale(sx, sy):
    cls = _get(("Scale",), ("transform", "Scale"))
    if cls is not None:
        try:
            return cls(scale_x=sx, scale_y=sy)
        except Exception:
            pass
    return 1.0


def make_border(color, width=1):
    fn = _get(("Border", "all"), ("border", "all"))
    if fn is not None:
        try:
            return fn(width, color)
        except Exception:
            pass
    return None


# ======================= Звук =======================
SOUND_ON = True


def set_sound(on):
    global SOUND_ON
    SOUND_ON = bool(on)


_SOUND_WARNED = set()


def _mci_play(path):
    """Запасной способ для Windows (системный MCI)."""
    import ctypes
    mci = ctypes.windll.winmm.mciSendStringW
    alias = f"snd{random.randrange(10 ** 6)}"
    mci(f'open "{path}" type waveaudio alias {alias}', None, 0, 0)
    mci(f"play {alias} wait", None, 0, 0)
    mci(f"close {alias}", None, 0, 0)


def _play_file(path):
    try:
        if winsound is not None:
            try:
                winsound.PlaySound(path, winsound.SND_FILENAME)  # синхронно, но мы в своём потоке
                return
            except Exception as e:
                print("[звук] winsound не сработал:", e)
                _mci_play(path)
                return
        if sys.platform == "darwin":
            subprocess.run(["afplay", path], check=False)
        else:
            subprocess.run(["aplay", "-q", path], check=False)
    except Exception as e:
        print("[звук] не удалось воспроизвести:", e)


def play(name):
    """Мягкие звуки: tap, success, whoosh (файлы в папке sounds)."""
    if not SOUND_ON:
        return
    path = os.path.join(HERE, "sounds", name + ".wav")
    if not os.path.exists(path):
        if name not in _SOUND_WARNED:
            _SOUND_WARNED.add(name)
            print(f"[звук] файл не найден: {path}")
        return
    threading.Thread(target=_play_file, args=(path,), daemon=True).start()


def startup_report():
    """Список проблем с установкой (показывается на экране и в консоли)."""
    problems = []
    if not os.path.isdir(ASSETS_DIR) or asset_bytes("robot/neutral.png") is None:
        problems.append("папка assets (картинки) не найдена рядом с frontend.py")
    if not os.path.exists(os.path.join(HERE, "sounds", "tap.wav")):
        problems.append("папка sounds (звуки) не найдена рядом с frontend.py")
    return problems


# ======================= Сеть и настройки =======================
def api(method, path, payload=None):
    try:
        r = requests.request(method, API + path, json=payload, timeout=6)
        r.raise_for_status()
        return r.json()
    except Exception:
        return None


def api_text(path):
    try:
        r = requests.get(API + path, timeout=10)
        r.raise_for_status()
        r.encoding = "utf-8"
        return r.text
    except Exception:
        return None


def load_settings():
    try:
        with open(SETTINGS_FILE, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def update_settings(**kw):
    data = load_settings()
    data.update(kw)
    try:
        with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f)
    except Exception:
        pass


# ======================= Компоненты =======================
def score_color(score):
    return OK if score >= 80 else WARN if score >= 60 else BAD


def fmt_date(iso):
    d = iso.replace("T", " ")
    y, m, dd = d[:10].split("-")
    return f"{dd}.{m}.{y} {d[11:16]}"


def short_date(iso):
    y, m, dd = iso[:10].split("-")
    return f"{dd}.{m}"


def label(value, size=14, bold=False, color=None, align=None):
    return ft.Text(value, size=size, weight=BOLD if bold else ft.FontWeight.NORMAL,
                   color=color or TXT, text_align=align)


def card(content, bg=None, radius=16, pad=16):
    """Карточка в стиле матового стекла."""
    kw = dict(content=content, bgcolor=bg or CARD, border_radius=radius, padding=pad)
    glass = dict(kw)
    if hasattr(ft, "Blur"):
        try:
            glass["blur"] = ft.Blur(14, 14)
        except Exception:
            pass
    border = make_border(BORDER)
    if border is not None:
        glass["border"] = border
    try:
        return ft.Container(**glass)
    except Exception:
        return ft.Container(**kw)


def tappable(fn):
    def handler(e):
        play("tap")
        return fn(e)
    return handler


def centered(controls):
    return ft.Column(controls, alignment=ft.MainAxisAlignment.CENTER,
                     horizontal_alignment=ft.CrossAxisAlignment.CENTER)


def button(text, on_click, color=None, width=None):
    """Основная кнопка (градиентная, если градиенты поддерживаются)."""
    base = color or ACC
    kw = dict(content=ft.Text(text, color="white", weight=BOLD, text_align=CENTER), bgcolor=base,
              border_radius=12, padding=14, width=width, on_click=tappable(on_click))
    if color is None:
        g = make_gradient(["#5B54F0", "#8B5CF6"])
        if g is not None:
            kw["gradient"] = g
    return ft.Container(**kw)


def ghost_button(text, on_click):
    c = card(label(text, 14, True), radius=12, pad=14)
    c.on_click = tappable(on_click)
    return c


def icon_box(emoji, color, size=40):
    return ft.Container(content=centered([ft.Text(emoji, size=int(size * 0.5))]), width=size, height=size,
                        border_radius=12, bgcolor=alpha(color, 0.30))


def test_icon(key, size=40, row=False):
    """Фирменный значок теста (из макета)."""
    return pic(f"ui/{'row' if row else 'tile'}_{key}.png", size, size)


def narrow(controls, w=720):
    """Контент по центру фиксированной ширины."""
    return [ft.Row([ft.Container(width=w, content=ft.Column(
        controls, spacing=14, horizontal_alignment=ft.CrossAxisAlignment.STRETCH))],
        alignment=ft.MainAxisAlignment.CENTER)]


def pointer_xy(e):
    """Координаты курсора из события (в разных версиях Flet по-разному)."""
    for xs, ys in (("global_x", "global_y"), ("local_x", "local_y")):
        x, y = getattr(e, xs, None), getattr(e, ys, None)
        if x is not None and y is not None:
            return float(x), float(y)
    for name in ("global_position", "local_position"):
        pos = getattr(e, name, None)
        if pos is not None:
            x, y = getattr(pos, "x", None), getattr(pos, "y", None)
            if x is not None and y is not None:
                return float(x), float(y)
    return None, None


# ======================= Робот-помощник: готовые картинки эмоций =======================
CAPTIONS = {
    "neutral": "", "happy": "Рад вас видеть!", "excited": "Ура!", "wink": "Подмигиваю :)",
    "curious": "Интересно...", "sleepy": "Хочется спать...", "sad": "Мне грустно...",
    "worried": "Я волнуюсь...", "angry": "Хмм!", "surprised": "Ого!", "thinking": "Думаю...",
    "shy": "Ой, смущаюсь", "confused": "Я растерян...", "stress": "Ух, непросто!", "support": "Я с вами!",
}


def robot_src(name):
    return f"robot/{name if name in CAPTIONS else 'neutral'}.png"


class Eyes:
    """Робот-помощник. 15 эмоций (картинки из макета), голова «следит» за курсором,
    плавно покачивается, а при бездействии (10 с) осматривается по сторонам."""

    def __init__(self, page, scale=1.0, cy=200, cxf=0.5):
        self.page = page
        self.s = scale
        self.cy = cy
        self.cxf = cxf  # где по горизонтали (доля ширины рабочей области) стоит голова
        self.active = True
        self.emotion = "neutral"
        self.lx = 0.0
        self.ly = 0.0
        self.bob = 0.0
        self.last_touch = time.time()
        self.W = int(300 * scale)
        self.H = int(self.W * IMG_ASPECT)
        self.pad = max(8, int(18 * scale))
        self.img = pic(robot_src("neutral"), self.W, self.H)
        self.can_swap = hasattr(self.img, "src") and not isinstance(self.img, ft.Container)
        self.holder = ft.Container(content=self.img, left=self.pad, top=self.pad,
                                   animate_position=ft.Animation(320, ft.AnimationCurve.EASE_OUT))
        self.head = ft.Stack([self.holder], width=self.W + 2 * self.pad, height=self.H + 2 * self.pad)
        self.caption = ft.Text("", size=13, color=MUTED, text_align=CENTER)
        self.control = card(
            ft.Column([self.head, self.caption], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=4),
            bg=alpha("#0A0E3D", 0.78), radius=24, pad=12)
        self.set_emotion("neutral")

    def apply(self):
        self.holder.left = self.pad + self.lx * self.pad * 0.8
        self.holder.top = self.pad + self.ly * self.pad * 0.5 + self.bob

    def set_emotion(self, name, caption=None, sound=False):
        new = name if name in CAPTIONS else "neutral"
        if sound and new != self.emotion:
            play("whoosh")
        self.emotion = new
        if self.can_swap:
            set_image(self.img, asset_bytes(robot_src(new)))
        self.caption.value = caption if caption is not None else CAPTIONS[new]
        self.apply()

    def touch(self):
        self.last_touch = time.time()

    def look_at(self, x, y, width):
        self.touch()
        cx = SIDEBAR_W + (width - SIDEBAR_W) * self.cxf
        dx, dy = x - cx, y - self.cy
        dist = math.hypot(dx, dy)
        if dist < 1:
            self.lx = self.ly = 0.0
        else:
            k = min(1.0, dist / 300)
            self.lx, self.ly = dx / dist * k, dy / dist * k
        self.apply()

    def look(self, lx, ly):
        self.touch()
        self.lx, self.ly = lx, ly
        self.apply()

    async def run_loop(self):
        """Лёгкое «дыхание» и осматривание при бездействии курсора."""
        t = 0.0
        phase = 0.0
        while self.active:
            await asyncio.sleep(0.25)
            if not self.active:
                break
            try:
                t += 0.25
                self.bob = math.sin(t * 1.6) * 3 * self.s
                if time.time() - self.last_touch > 10:
                    phase += 0.18
                    self.lx = math.sin(phase) * 0.9
                    self.ly = math.sin(phase * 0.5) * 0.25
                self.apply()
                self.page.update()
            except Exception:
                break


def emotion_for_score(score):
    return "excited" if score >= 85 else "happy" if score >= 70 else "wink" if score >= 50 else "support"


# ======================= Приложение =======================
def main(page: ft.Page):
    settings = load_settings()
    apply_theme("dark" if settings.get("dark", True) else "light")
    set_sound(settings.get("sound", True))

    page.title = "Детектор внимания"
    page.padding = 0
    try:
        page.theme = ft.Theme(font_family="Segoe UI")
    except Exception:
        pass
    try:
        page.window.width = 1280
        page.window.height = 820
        page.window.min_width = 1000
        page.window.min_height = 700
    except Exception:
        pass

    body = ft.Column(scroll=ft.ScrollMode.AUTO, spacing=14,
                     horizontal_alignment=ft.CrossAxisAlignment.STRETCH, expand=True)
    state = {"token": 0, "eyes": [], "pending": [], "last_move": 0.0, "user": None, "queue": [],
             "dark": settings.get("dark", True), "view": None, "nav": "home",
             "tip": random.choice(MOTIVATION)}
    chat_log = ft.Column(spacing=8, height=260, scroll=ft.ScrollMode.AUTO, auto_scroll=True)
    chat_state = {"msgs": []}
    screens = {}

    status_dot = ft.Container(width=10, height=10, border_radius=5, bgcolor=BAD)
    status_text = label("Офлайн", 13, color=MUTED)
    theme_text = ft.Text("☀️" if state["dark"] else "🌙", size=20)
    sound_text = ft.Text("🔊" if SOUND_ON else "🔇", size=20)

    def page_width():
        w = getattr(page, "width", None)
        return float(w) if w else 1280.0

    def new_eyes(scale=1.0, cy=200, cxf=0.5):
        eyes = Eyes(page, scale, cy, cxf)
        state["pending"].append(eyes)
        return eyes

    # ---------- боковое меню ----------
    NAV = [("home", "ui/nav_home.png", "Главная"), ("train", "ui/nav_train.png", "Тренировки"),
           ("tests", "ui/nav_tests.png", "Тесты"), ("history", "ui/nav_history.png", "История"),
           ("tips", "ui/nav_tips.png", "Советы"), ("coach", "ui/nav_coach.png", "Коуч"),
           ("profile", "ui/nav_profile.png", "Профиль")]

    def go(key):
        state["queue"] = []
        screens[key]()

    def sidebar_content():
        items = []
        for key, icon, name in NAV:
            active = key == state["nav"]
            kw = dict(content=ft.Row([pic(icon, 26, 26),
                                      label(name, 15, True, "#FFFFFF" if active else "#C3CBF0")], spacing=14),
                      padding=12, border_radius=14, on_click=tappable(lambda e, k=key: go(k)))
            if active:
                kw["bgcolor"] = ACC
                g = make_gradient(["#5B54F0", "#8B5CF6"])
                if g is not None:
                    kw["gradient"] = g
            items.append(ft.Container(**kw))
        user = state["user"]["name"] if state["user"] else ""
        logo = ft.Column([pic("ui/logo.png", 64, 64), label("Детектор\nвнимания", 20, True, "#FFFFFF"),
                          label(user, 13, color="#9AA6D8")], spacing=2)
        tip = card(ft.Row([pic("ui/nav_tips.png", 26, 26), label(state["tip"] + " ♥", 12, True, "#FFFFFF")],
                          spacing=10), bg=alpha("#232A78", 0.6), radius=16, pad=12)
        return ft.Column([logo, ft.Container(height=14)] + items + [ft.Container(expand=True), tip],
                         expand=True, spacing=6)

    def set_view(controls):
        state["token"] += 1  # отменяет таймеры предыдущего экрана
        for e in state["eyes"]:
            e.active = False
        state["eyes"] = state["pending"]
        state["pending"] = []
        body.controls = controls
        sidebar.content = sidebar_content()
        page.update()
        for e in state["eyes"]:
            page.run_task(e.run_loop)
        return state["token"]

    def on_hover(e):
        now = time.time()
        if now - state["last_move"] < 0.04 or not state["eyes"]:
            return
        state["last_move"] = now
        x, y = pointer_xy(e)
        if x is None:
            return
        for eyes in state["eyes"]:
            eyes.look_at(x, y, page_width())
        page.update()

    def check_server():
        ok = api("GET", "/health") is not None
        status_dot.bgcolor = OK if ok else BAD
        status_text.value = "Онлайн" if ok else "Офлайн"
        page.update()
        return ok

    def uid():
        return state["user"]["id"] if state["user"] else 0

    def set_user(user):
        state["user"] = user
        update_settings(user_id=user["id"] if user else None)
        chat_state["msgs"] = []
        chat_log.controls.clear()

    def offline_card():
        return card(ft.Column([
            label("Нет связи с сервером", 16, True, BAD),
            label("Запустите в соседнем окне:\nuvicorn backend:app", 13, color=MUTED),
            button("Проверить снова", lambda e: show_home()),
        ]))

    def back_bar(title, back=None):
        return ft.Row([
            ft.Container(content=label("← Назад", 14, True, ACC),
                         on_click=tappable(back or (lambda e: show_tests())), padding=6),
            label(title, 20, True),
        ])

    def section_title(text, link=None, action=None):
        row = [label(text, 17, True)]
        if link:
            row.append(ft.Container(content=label(link, 13, True, ACC), on_click=tappable(action)))
        return ft.Row(row, alignment=ft.MainAxisAlignment.SPACE_BETWEEN)

    # ---------- запуск тестов ----------
    def run_test(name):
        {"reaction": run_reaction, "stroop": run_stroop, "schulte": run_schulte, "memory": run_memory}[name]()

    def start_full(e=None):
        state["queue"] = ["reaction", "stroop", "schulte", "memory"]
        next_in_queue()

    def next_in_queue(e=None):
        if state["queue"]:
            run_test(state["queue"].pop(0))

    def recommended(data):
        tests = data["tests"]
        for t in ("reaction", "schulte", "stroop", "memory"):
            if t not in tests:
                return t, f"Попробуйте «{TEST_NAMES[t]}»: вы ещё не проходили этот тест."
        weakest = min(tests, key=lambda t: tests[t]["avg"])
        return weakest, (f"Попробуйте «{TEST_NAMES[weakest]}». Это ваше слабое место, "
                         "и тренировка поможет лучше концентрироваться в повседневных задачах.")

    def tile(title, key, action):
        c = card(ft.Row([test_icon(key, 46), label(title, 13, True)], spacing=12), radius=16, pad=12)
        g = make_gradient([alpha(TILE_COLORS[key][0], 0.55), alpha(TILE_COLORS[key][1], 0.18)])
        if g is not None:
            c.gradient = g
        c.width = 210
        c.on_click = tappable(lambda e: action())
        return c

    def quick_tiles():
        return ft.Row([
            tile("Тренировка на реакцию", "reaction", lambda: run_reaction()),
            tile("Таблица Шульте", "schulte", lambda: run_schulte()),
            tile("Тест Струпа", "stroop", lambda: run_stroop()),
            tile("Память на числа", "memory", lambda: run_memory()),
            tile("Полный тест", "full", lambda: start_full()),
        ], wrap=True, spacing=10, run_spacing=10)

    def bar_chart(rows, height=130):
        """rows — результаты от старых к новым."""
        axis = ft.Column([label("100", 11, color=MUTED), label("50", 11, color=MUTED), label("0", 11, color=MUTED)],
                         height=height, alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
        bars = [ft.Column([
            ft.Container(width=24, height=max(4, int(r["score"] * height / 100)), border_radius=8,
                         bgcolor=score_color(r["score"]),
                         gradient=make_gradient([score_color(r["score"]), alpha(score_color(r["score"]), 0.55)],
                                                vertical=True)),
            label(short_date(r["created_at"]), 11, color=MUTED)],
            height=height + 20, alignment=ft.MainAxisAlignment.END,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER) for r in rows]
        return ft.Row([axis, ft.Row(bars, alignment=ft.MainAxisAlignment.SPACE_AROUND, expand=True)],
                      vertical_alignment=ft.CrossAxisAlignment.START)

    def result_row(r):
        t = r["test"]
        row = ft.Container(content=ft.Row([
            test_icon(t, 40, row=True),
            ft.Column([label(TEST_NAMES.get(t, t), 14, True), label(fmt_date(r["created_at"]), 12, color=MUTED)],
                      spacing=0, expand=True),
            label(str(r["score"]), 22, True, score_color(r["score"])),
            label("›", 18, color=MUTED)], spacing=12), padding=8,
            on_click=tappable(lambda e: show_history()))
        return row

    # ---------------- Знакомство ----------------
    def show_welcome(e=None):
        state["view"] = show_welcome
        state["nav"] = "home"
        users = api("GET", "/users") or []
        eyes = new_eyes(1.0, cy=230)
        eyes.set_emotion("happy", "Привет! Я ваш помощник по вниманию.")
        name_field = ft.TextField(hint_text="Как вас зовут?", bgcolor=CARD2, color=TXT, border_color=CARD2,
                                  border_radius=12)
        msg = label("", 13, color=BAD)

        def start(ev):
            name = (name_field.value or "").strip()
            if not name:
                msg.value = "Введите имя"
                page.update()
                return
            user = api("POST", "/users", {"name": name})
            if user is None:
                msg.value = "Сервер недоступен"
                page.update()
                return
            set_user(user)
            show_home()

        name_field.on_submit = start
        controls = [eyes.control, label("Добро пожаловать!", 26, True, None, CENTER), name_field, msg,
                    button("Начать", start)]
        if users:
            controls.append(label("или выберите ученика:", 13, color=MUTED))
            for u in users:
                row = card(label(u["name"], 15, True), CARD2)
                row.on_click = tappable(lambda ev, u=u: (set_user({"id": u["id"], "name": u["name"]}), show_home()))
                controls.append(row)
        set_view(narrow(controls, 560))

    # ---------------- Главная (дашборд) ----------------
    def show_home(e=None):
        state["view"] = show_home
        state["nav"] = "home"
        if state["user"] is None:
            show_welcome()
            return
        set_view([label("Загрузка...", 14, color=MUTED)])
        if not check_server():
            set_view(narrow([label("Главная", 26, True), offline_card()]))
            return
        data = api("GET", f"/summary?user_id={uid()}")
        hist = api("GET", f"/history?user_id={uid()}&limit=8")
        if data is None or hist is None:
            set_view(narrow([label("Главная", 26, True), offline_card()]))
            return
        name = state["user"]["name"]
        has = data["overall"] is not None
        rec_test, rec_text = recommended(data) if has else ("reaction", "Начните с теста на реакцию: он занимает минуту.")

        eyes = new_eyes(1.15, cy=300, cxf=0.74)
        eyes.caption.color = TXT
        if has:
            eyes.set_emotion(emotion_for_score(data["overall"]), data["advice"])
        else:
            eyes.set_emotion("happy", "Я здесь, чтобы помочь тебе развивать внимание :)")
        bubble = ft.Container(content=card(eyes.caption, radius=18, pad=14), width=300)

        hero_left = ft.Column([
            ft.Row([label("Привет, ", 34, True), label(f"{name}!", 34, True, ACC), ft.Text("👋", size=30)]),
            label("Я твой помощник в развитии внимания.\nДавай немного потренируемся сегодня?", 15, color=MUTED),
            ft.Container(height=4),
            button("▶   Начать тренировку   ›", lambda e: run_test(rec_test), width=300),
            ft.Row([ghost_button("📋  Пройти тест  ›", lambda e: show_tests()),
                    ghost_button("💡  Посмотреть советы", lambda e: show_tips())], spacing=12),
        ], spacing=12, expand=3)
        head_box = eyes.head if state["dark"] else card(eyes.head, bg=alpha("#0A0E3D", 0.9), radius=24, pad=0)
        hero_right = ft.Column([bubble, head_box], horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                               spacing=4, expand=2)
        hero = card(ft.Row([hero_left, hero_right], vertical_alignment=ft.CrossAxisAlignment.CENTER),
                    radius=24, pad=24)

        tests = data["tests"]
        best = max([v["best"] for v in tests.values()], default=None)
        cnt = sum(v["count"] for v in tests.values())
        avg = round(sum(v["avg"] * v["count"] for v in tests.values()) / cnt) if cnt else None

        def stat(icon, value, caption, action):
            c = card(ft.Row([pic(icon, 44, 48),
                             ft.Column([label(value, 24, True), label(caption, 12, color=MUTED)], spacing=0, expand=True),
                             label("›", 18, color=MUTED)], spacing=12), pad=14)
            c.expand = 1
            c.on_click = tappable(action)
            return c

        stats = ft.Row([
            stat("ui/stat_fire.png", str(data["streak"]), "дней подряд", lambda e: show_profile()),
            stat("ui/stat_bars.png", str(data["total"]), "тестов пройдено", lambda e: show_history()),
            stat("ui/stat_trophy.png", "—" if best is None else str(best), "лучший результат",
                 lambda e: show_history()),
            stat("ui/stat_star.png", "—" if avg is None else str(avg), "средний результат",
                 lambda e: show_history()),
        ], spacing=14)

        chart_body = (bar_chart(list(reversed(hist))) if hist
                      else label("Пока нет результатов. Пройдите первый тест!", 13, color=MUTED))
        chart_card = card(ft.Column([section_title("Последние результаты", "Все ›", lambda e: show_history()),
                                     chart_body], spacing=12))
        chart_card.expand = 2
        rec_card = card(ft.Row([
            ft.Column([ft.Row([pic("ui/nav_tips.png", 24, 24), label("Рекомендация на сегодня", 15, True)],
                              spacing=8),
                       label(rec_text, 13, color=MUTED),
                       button("Начать  ›", lambda e: run_test(rec_test), width=140)], spacing=10, expand=True),
            pic("ui/target.png", 190, 144)], vertical_alignment=ft.CrossAxisAlignment.CENTER))
        rec_card.expand = 1

        recent = ft.Column([result_row(r) for r in hist[:4]], spacing=2) if hist else label("Пока пусто", 13, color=MUTED)
        last_card = card(ft.Column([section_title("Последние тесты", "Все результаты ›", lambda e: show_history()),
                                    recent], spacing=8))
        last_card.expand = 2
        quick_card = card(ft.Column([label("Быстрые действия", 17, True), quick_tiles()], spacing=12))
        quick_card.expand = 1

        problems = startup_report()
        banner = [card(label("⚠ Не хватает файлов: " + "; ".join(problems) +
                             ". Распакуйте архив целиком в папку приложения.", 13, True, WARN))] if problems else []
        set_view(banner + [hero, stats,
                  ft.Row([chart_card, rec_card], spacing=14, vertical_alignment=ft.CrossAxisAlignment.START),
                  ft.Row([last_card, quick_card], spacing=14, vertical_alignment=ft.CrossAxisAlignment.START)])

    # ---------------- Тренировки ----------------
    def show_train(e=None):
        state["view"] = show_train
        state["nav"] = "train"
        if state["user"] is None:
            show_welcome()
            return
        data = api("GET", f"/summary?user_id={uid()}") if check_server() else None
        if data is None:
            set_view(narrow([label("Тренировки", 26, True), offline_card()]))
            return
        rec_test, rec_text = recommended(data) if data["overall"] is not None else (
            "reaction", "Начните с теста на реакцию: он занимает минуту.")
        eyes = new_eyes(0.8, cy=200)
        eyes.set_emotion("curious", "Что потренируем сегодня?")
        set_view(narrow([
            label("Тренировки", 26, True), eyes.control,
            card(ft.Column([label("Тренировка на сегодня", 16, True), label(rec_text, 13, color=MUTED),
                            button(f"Начать: {TEST_NAMES[rec_test]}", lambda e: run_test(rec_test))], spacing=10)),
            label("Выберите самостоятельно", 16, True), quick_tiles()], 760))

    # ---------------- Тесты ----------------
    def show_tests(e=None):
        state["view"] = show_tests
        state["nav"] = "tests"
        if state["user"] is None:
            show_welcome()
            return

        def tcard(key):
            c = card(ft.Column([ft.Row([test_icon(key, 44), label(TEST_NAMES[key], 17, True)], spacing=12),
                                label(TEST_DESC[key], 13, color=MUTED),
                                button("Пройти", lambda e, k=key: run_test(k))], spacing=10))
            c.width = 330
            return c
        full = card(ft.Column([ft.Row([test_icon("full", 44), label("Полный тест", 17, True)], spacing=12),
                               label("Все четыре теста подряд. Лучший способ оценить внимание целиком.", 13, color=MUTED),
                               button("Пройти всё", start_full, "#D9722B")], spacing=10))
        full.width = 330
        set_view([label("Тесты", 26, True),
                  ft.Row([tcard("reaction"), tcard("stroop"), tcard("schulte"), tcard("memory"), full],
                         wrap=True, spacing=14, run_spacing=14)])

    # ---------------- Результат ----------------
    def finish(test, metrics, retry):
        res = api("POST", "/results", {"user_id": uid(), "test": test, "metrics": metrics})
        if res is None:
            set_view(narrow([back_bar("Результат", lambda e: show_home()),
                             card(label("Результат не сохранён: сервер недоступен.", 15, True, BAD)),
                             button("Ещё раз", lambda e: retry())], 560))
            return
        eyes = new_eyes(0.75, cy=230)
        eyes.set_emotion(emotion_for_score(res["score"]),
                         "Отлично!" if res["score"] >= 80 else "Неплохо, продолжаем" if res["score"] >= 60
                         else "Ничего, в следующий раз получится")
        if res["score"] >= 60:
            play("success")
        if state["queue"]:
            primary = button("Следующий тест  ›", next_in_queue)
        else:
            primary = button("Ещё раз", lambda e: retry())
        set_view(narrow([
            back_bar(f"Результат: {TEST_NAMES[test]}", lambda e: show_home()),
            eyes.control,
            card(centered([label(str(res["score"]), 64, True, score_color(res["score"])),
                           label(f"уровень: {res['level']}", 15, color=MUTED)])),
            card(label(res["recommendation"], 14)),
            primary,
            button("Все тесты", lambda e: show_tests(), CARD2),
        ], 560))

    # ---------------- Реакция ----------------
    def run_reaction():
        state["view"] = show_tests
        TOTAL = 5
        st = {"phase": "idle", "n": 0, "times": [], "false": 0, "t0": 0.0, "attempt": 0}
        area_label = label("Нажмите, чтобы начать", 22, True, "white", CENTER)

        def alive(attempt):
            return state["token"] == tok and st["attempt"] == attempt

        async def wait_task(attempt):
            await asyncio.sleep(random.uniform(1.0, 3.0))
            if not alive(attempt):
                return
            st["phase"] = "go"
            area.bgcolor = OK
            area_label.value = "ЖМИТЕ!"
            page.update()
            st["t0"] = time.perf_counter()

        async def pause_task(attempt):
            await asyncio.sleep(0.9)
            if alive(attempt):
                wait_phase()

        def wait_phase(msg="Ждите зелёного..."):
            st["attempt"] += 1
            st["phase"] = "wait"
            area.bgcolor = BAD
            area_label.value = msg
            info.value = f"Попытка {st['n'] + 1} из {TOTAL}"
            page.update()
            page.run_task(wait_task, st["attempt"])

        def on_click(ev):
            ph = st["phase"]
            if ph == "idle":
                wait_phase()
            elif ph == "wait":
                st["false"] += 1
                wait_phase("Слишком рано! Ждите...")
            elif ph == "go":
                rt = (time.perf_counter() - st["t0"]) * 1000
                st["times"].append(rt)
                st["n"] += 1
                st["phase"] = "pause"
                if st["n"] >= TOTAL:
                    finish("reaction", {"avg_ms": round(sum(st["times"]) / TOTAL, 1),
                                        "false_starts": st["false"]}, run_reaction)
                    return
                area.bgcolor = ACC
                area_label.value = f"{rt:.0f} мс"
                page.update()
                page.run_task(pause_task, st["attempt"])

        # ВАЖНО: обработчик задаётся при создании, до показа на экране
        area = ft.Container(width=300, height=300, border_radius=24, bgcolor=ACC,
                            content=centered([area_label]), on_click=lambda ev: on_click(ev))
        info = label("", 14, color=MUTED, align=CENTER)
        tok = set_view(narrow([back_bar("Реакция"),
                               card(label("Ждите зелёного и жмите по кругу как можно быстрее.", 13, color=MUTED)),
                               ft.Row([area], alignment=ft.MainAxisAlignment.CENTER), info], 560))

    # ---------------- Струп ----------------
    def run_stroop():
        state["view"] = show_tests
        diff = api("GET", f"/difficulty?user_id={uid()}") or {}
        total = int(diff.get("stroop_trials", 10))
        st = {"i": 0, "correct": 0, "times": [], "ink": 0, "t0": 0.0}
        word = ft.Text("", size=52, weight=BOLD)
        info = label("", 13, color=MUTED, align=CENTER)

        def next_trial():
            w = random.randrange(4)
            ink = random.randrange(4) if random.random() < 0.3 else random.choice([k for k in range(4) if k != w])
            st["ink"] = ink
            word.value = STROOP[w][0]
            word.color = STROOP[ink][1]
            info.value = f"{st['i'] + 1} из {total}"
            page.update()
            st["t0"] = time.perf_counter()

        def answer(k):
            st["times"].append((time.perf_counter() - st["t0"]) * 1000)
            if k == st["ink"]:
                st["correct"] += 1
            st["i"] += 1
            if st["i"] >= total:
                finish("stroop", {"correct": st["correct"], "total": total,
                                  "avg_ms": round(sum(st["times"]) / total, 1)}, run_stroop)
            else:
                next_trial()

        buttons = ft.Row(
            [ft.Container(content=label(name.capitalize(), 14, True, None, CENTER), bgcolor=CARD2,
                          border_radius=12, padding=14, width=160, on_click=lambda e, k=k: answer(k))
             for k, (name, _) in enumerate(STROOP)],
            wrap=True, alignment=ft.MainAxisAlignment.CENTER)
        set_view(narrow([back_bar("Тест Струпа"),
                         card(label("Выбирайте, КАКОГО ЦВЕТА буквы, а не что написано.", 13, color=MUTED)),
                         card(centered([word])), info, buttons], 560))
        next_trial()

    # ---------------- Шульте ----------------
    def run_schulte():
        state["view"] = show_tests
        diff = api("GET", f"/difficulty?user_id={uid()}") or {}
        n = int(diff.get("schulte_size", 4))
        size = 70 if n <= 4 else 60
        numbers = list(range(1, n * n + 1))
        random.shuffle(numbers)
        st = {"cur": 1, "errors": 0, "t0": time.perf_counter()}
        target = label("Найдите: 1", 18, True, ACC, CENTER)
        cells = {}

        def click(num):
            if num == st["cur"]:
                cells[num].bgcolor = OK
                st["cur"] += 1
                if st["cur"] > n * n:
                    secs = time.perf_counter() - st["t0"]
                    finish("schulte", {"size": n, "seconds": round(secs, 2),
                                       "errors": st["errors"]}, run_schulte)
                    return
                target.value = f"Найдите: {st['cur']}"
            else:
                st["errors"] += 1
            page.update()

        rows = []
        for r in range(n):
            row_cells = []
            for c in range(n):
                num = numbers[r * n + c]
                cell = ft.Container(width=size, height=size, bgcolor=CARD2, border_radius=12,
                                    content=centered([label(str(num), 22, True)]),
                                    on_click=lambda e, num=num: click(num))
                cells[num] = cell
                row_cells.append(cell)
            rows.append(ft.Row(row_cells, alignment=ft.MainAxisAlignment.CENTER, spacing=8))
        set_view(narrow([back_bar(f"Шульте {n}×{n}"), target, ft.Column(rows, spacing=8)], 560))
        st["t0"] = time.perf_counter()

    # ---------------- Память на числа ----------------
    def run_memory():
        state["view"] = show_tests
        diff = api("GET", f"/difficulty?user_id={uid()}") or {}
        MAXR = 8
        st = {"L": int(diff.get("memory_start", 4)), "round": 0, "mistakes": 0, "best": 0, "seq": ""}
        display = ft.Text("", size=56, weight=BOLD, color=TXT, text_align=CENTER)
        hint = label("", 14, color=MUTED, align=CENTER)

        def check(ev):
            if not field.visible:
                return
            ans = (field.value or "").strip()
            field.visible = False
            check_btn.visible = False
            if ans == st["seq"]:
                st["best"] = max(st["best"], st["L"])
                st["L"] = min(9, st["L"] + 1)
                hint.value = "Верно!"
            else:
                st["mistakes"] += 1
                st["L"] = max(3, st["L"] - 1)
                hint.value = f"Неверно. Было: {st['seq']}"
            page.update()
            page.run_task(after_task, st["round"])

        async def after_task(rnd):
            await asyncio.sleep(1.0)
            if state["token"] != tok or st["round"] != rnd:
                return
            if st["round"] >= MAXR or st["mistakes"] >= 3:
                finish("memory", {"max_len": st["best"], "rounds": st["round"],
                                  "mistakes": st["mistakes"]}, run_memory)
            else:
                start_round()

        async def hide_task(rnd):
            await asyncio.sleep(0.8 + 0.45 * st["L"])
            if state["token"] != tok or st["round"] != rnd:
                return
            display.value = "?"
            hint.value = "Введите число, которое видели"
            field.value = ""
            field.visible = True
            check_btn.visible = True
            page.update()

        def start_round():
            st["round"] += 1
            st["seq"] = "".join(random.choice("0123456789") for _ in range(st["L"]))
            display.value = st["seq"]
            hint.value = f"Раунд {st['round']} из {MAXR}. Запомните!"
            field.visible = False
            check_btn.visible = False
            page.update()
            page.run_task(hide_task, st["round"])

        field = ft.TextField(hint_text="Число", visible=False, bgcolor=CARD2, color=TXT,
                             border_color=CARD2, border_radius=12, text_align=CENTER,
                             on_submit=lambda ev: check(ev))
        check_btn = button("Проверить", lambda ev: check(ev))
        check_btn.visible = False
        tok = set_view(narrow([back_bar("Память на числа"),
                               card(label("Запомните число. Оно исчезнет через пару секунд.", 13, color=MUTED)),
                               card(centered([display])), hint, field, check_btn], 560))
        start_round()

    # ---------------- История ----------------
    def show_history(e=None):
        state["view"] = show_history
        state["nav"] = "history"
        if state["user"] is None:
            show_welcome()
            return
        data = api("GET", f"/history?user_id={uid()}&limit=20") if check_server() else None
        if data is None:
            set_view(narrow([label("История", 26, True), offline_card()]))
            return
        if not data:
            set_view(narrow([label("История", 26, True),
                             card(label("Пока пусто. Пройдите любой тест.", 14, color=MUTED))]))
            return
        controls = [label("История", 26, True),
                    card(ft.Column([label("Последние результаты", 14, color=MUTED),
                                    bar_chart(list(reversed(data[:12])))], spacing=12))]
        controls.append(card(ft.Column([result_row(r) for r in data], spacing=2)))
        set_view(narrow(controls, 900))

    # ---------------- Советы ----------------
    def show_tips(e=None):
        state["view"] = show_tips
        state["nav"] = "tips"
        if state["user"] is None:
            show_welcome()
            return
        data = api("GET", f"/summary?user_id={uid()}") if check_server() else None
        eyes = new_eyes(0.8, cy=200)
        eyes.set_emotion("curious", (data or {}).get("advice", "Давайте потренируем внимание!"))
        tips = [card(ft.Row([ft.Text(ic, size=28), ft.Column(
            [label(t, 15, True), label(txt, 13, color=MUTED)], spacing=2, expand=True)], spacing=14))
            for ic, t, txt in TIPS_UI]
        set_view(narrow([label("Советы", 26, True), eyes.control] + tips, 760))

    # ---------------- Коуч (чат) ----------------
    def bubble(text, mine):
        return ft.Row([ft.Container(
            content=ft.Text(text, color="white" if mine else TXT, size=14, selectable=True),
            bgcolor=ACC if mine else CARD2, border_radius=14, padding=12, width=440)],
            alignment=ft.MainAxisAlignment.END if mine else ft.MainAxisAlignment.START)

    def add_msg(text, mine):
        chat_state["msgs"].append((text, mine))
        chat_log.controls.append(bubble(text, mine))

    def show_coach(e=None):
        state["view"] = show_coach
        state["nav"] = "coach"
        if state["user"] is None:
            show_welcome()
            return
        eyes = new_eyes(0.9, cy=230)
        eyes.set_emotion("happy", "Я слежу за вами :)")
        field = ft.TextField(hint_text="Спросите коуча...", expand=True, bgcolor=CARD2, color=TXT,
                             border_radius=12, border_color=CARD2)
        if not chat_state["msgs"]:
            chat_state["msgs"].append((
                f"Привет, {state['user']['name']}! Я коуч по вниманию. Спросите про результаты, "
                "что тренировать или как лучше концентрироваться.", False))
        chat_log.controls = [bubble(t, m) for t, m in chat_state["msgs"]]

        async def reply_flow(text):
            eyes.set_emotion("curious", "Получил!", sound=True)
            page.update()
            await asyncio.sleep(0.5)
            eyes.set_emotion("thinking", "Думаю...", sound=True)
            page.update()
            res = await asyncio.to_thread(api, "POST", "/chat", {"user_id": uid(), "text": text})
            await asyncio.sleep(0.3)
            if res:
                add_msg(res["response"], False)
                eyes.set_emotion(res.get("emotion", "neutral"), sound=True)
            else:
                add_msg("Сервер недоступен.", False)
                eyes.set_emotion("stress", "Нет связи", sound=True)
            page.update()

        def send(text):
            text = (text or "").strip()
            if not text:
                return
            field.value = ""
            add_msg(text, True)
            page.update()
            page.run_task(reply_flow, text)

        def typing(ev):
            eyes.look(0.0, 0.8)
            page.update()

        chips = ft.Row([
            ft.Container(content=label(t, 12, True), bgcolor=CARD2, border_radius=20, padding=10,
                         on_click=tappable(lambda ev, t=t: send(t)))
            for t in ("Как мои результаты?", "Что тренировать?", "Совет", "Я устал", "Ты молодец")
        ], wrap=True, alignment=ft.MainAxisAlignment.CENTER)
        field.on_submit = lambda ev: send(field.value)
        field.on_change = typing
        set_view(narrow([eyes.control, chips, card(chat_log),
                         ft.Row([field, ft.Container(content=label("➤", 18, True, "white"), bgcolor=ACC,
                                                     border_radius=12, padding=14,
                                                     on_click=tappable(lambda ev: send(field.value)))])], 760))

    # ---------------- Профиль ----------------
    def show_profile(e=None):
        state["view"] = show_profile
        state["nav"] = "profile"
        if state["user"] is None:
            show_welcome()
            return
        if not check_server():
            set_view(narrow([label("Профиль", 26, True), offline_card()]))
            return
        users = api("GET", "/users") or []
        msg = label("", 13, color=OK, align=CENTER)

        def export(ev):
            text = api_text(f"/export?user_id={uid()}")
            if text is None:
                msg.value = "Не удалось выгрузить"
                msg.color = BAD
            else:
                folder = os.path.join(HERE, "exports")
                os.makedirs(folder, exist_ok=True)
                path = os.path.join(folder, f"{state['user']['name']}_{datetime.now():%Y%m%d_%H%M}.csv")
                with open(path, "w", encoding="utf-8-sig", newline="") as f:
                    f.write(text)
                msg.value = f"Сохранено: {path}"
                msg.color = OK
            page.update()

        def clear(ev):
            api("DELETE", f"/history?user_id={uid()}")
            show_profile()

        controls = [label("Профиль", 26, True),
                    card(centered([label(state["user"]["name"], 22, True),
                                   label("текущий ученик", 12, color=MUTED)])),
                    button("Выгрузить результаты в CSV (Excel)", export), msg,
                    label("Ученики (класс)", 16, True)]
        for u in users:
            overall = "—" if u["overall"] is None else str(u["overall"])
            row = card(ft.Row([
                ft.Column([label(u["name"], 15, True),
                           label(f"тестов: {u['total']}, серия: {u['streak']} дн.", 12, color=MUTED)], expand=True),
                label(overall, 24, True, MUTED if u["overall"] is None else score_color(u["overall"])),
            ]), ACC if u["id"] == uid() else CARD2)
            row.on_click = tappable(lambda ev, u=u: (set_user({"id": u["id"], "name": u["name"]}), show_profile()))
            controls.append(row)
        controls.append(button("+ Новый ученик", lambda ev: show_welcome(), CARD2))
        controls.append(button("Очистить мою историю", clear, BAD))
        set_view(narrow(controls, 720))

    screens.update({"home": show_home, "train": show_train, "tests": show_tests, "history": show_history,
                    "tips": show_tips, "coach": show_coach, "profile": show_profile})

    # ---------------- Каркас, темы, звук ----------------
    def toggle_sound(e):
        set_sound(not SOUND_ON)
        update_settings(sound=SOUND_ON)
        sound_text.value = "🔊" if SOUND_ON else "🔇"
        play("tap")
        page.update()

    def refresh_chrome():
        """Перекрашивает фон, боковое меню и верхнюю панель под текущую тему."""
        page.bgcolor = BG
        try:
            page.theme_mode = ft.ThemeMode.DARK if state["dark"] else ft.ThemeMode.LIGHT
        except Exception:
            pass
        bg_box.bgcolor = BG
        bg_box.gradient = make_gradient(GRAD)
        set_image(bg_image, asset_bytes("ui/bg_dark.jpg" if state["dark"] else "ui/bg_light.jpg"))
        sidebar.bgcolor = SIDE
        status_text.color = MUTED
        pill.bgcolor = CARD
        theme_text.value = "☀️" if state["dark"] else "🌙"

    def toggle_theme(e):
        state["dark"] = not state["dark"]
        apply_theme("dark" if state["dark"] else "light")
        update_settings(dark=state["dark"])
        refresh_chrome()
        play("tap")
        (state["view"] or show_home)()  # перерисовать экран в новых цветах

    pill = card(ft.Row([status_dot, status_text], spacing=8), radius=20, pad=10)
    topbar = ft.Row([ft.Container(expand=True), pill,
                     ft.Container(content=sound_text, padding=8, on_click=toggle_sound),
                     ft.Container(content=theme_text, padding=8, on_click=toggle_theme)],
                    alignment=ft.MainAxisAlignment.END)

    sidebar = ft.Container(width=SIDEBAR_W, padding=18, bgcolor=SIDE, content=ft.Column([]))
    main_col = ft.Column([topbar, ft.Container(content=body, expand=True)], expand=True, spacing=8)

    bg_kw = dict(left=0, top=0, right=0, bottom=0)
    if fit_cover() is not None:
        bg_kw["fit"] = fit_cover()
    bg_name = "ui/bg_dark.jpg" if state["dark"] else "ui/bg_light.jpg"
    bg_data = asset_bytes(bg_name)
    bg_image = make_image(bg_data, **bg_kw) if bg_data else ft.Container(left=0, top=0, right=0, bottom=0)
    content_layer = ft.Container(
        content=ft.GestureDetector(
            content=ft.Row([sidebar, ft.Container(content=main_col, expand=True, padding=24)],
                           expand=True, spacing=0, vertical_alignment=ft.CrossAxisAlignment.STRETCH),
            on_hover=on_hover, expand=True),
        left=0, top=0, right=0, bottom=0)
    bg_box = ft.Container(content=ft.Stack([bg_image, content_layer], expand=True),
                          expand=True, bgcolor=BG, gradient=make_gradient(GRAD))
    refresh_chrome()
    page.add(bg_box)

    # восстановить последнего ученика
    saved = settings.get("user_id")
    if saved:
        for u in api("GET", "/users") or []:
            if u["id"] == saved:
                state["user"] = {"id": u["id"], "name": u["name"]}
    show_home()


ft.run(main)
