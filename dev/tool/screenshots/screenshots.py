"""Regenerates the README screenshots (Windows only).

    python dev/tool/screenshots/screenshots.py all
    python dev/tool/screenshots/screenshots.py capture compose --only git-view

Steps: build, seed, capture, compose (see README.md next to this file).
Needs Python 3.10+, Pillow, git, and the Flutter and Rust toolchains for `build`.
"""
import argparse, ctypes, ctypes.wintypes as wt, datetime as dt, json, os, random, shutil
import struct, subprocess, sys, time, uuid, zlib

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
APP = os.path.join(ROOT, "app")
WORK = os.path.join(APP, "build", "screenshots")
DATA = os.path.join(WORK, "data")
# Short, neutral folder: project paths show up in the list view. Override with GODOTHUB_SCREENSHOT_DEMO.
DEMO = os.environ.get("GODOTHUB_SCREENSHOT_DEMO", r"C:\GodotDemo")
RAW = os.path.join(WORK, "raw")
EXE = os.path.join(APP, "build", "windows", "x64", "runner", "Release", "godothub.exe")
OUT = os.path.join(ROOT, "assets")

ACCENT = (0x45, 0x7F, 0xF2)
PAD, RADIUS = 96, 14
WINDOW = (60, 20, 1500, 960)

# ---- capture script
NAV = dict(projects=(129, 180), versions=(129, 221), templates=(134, 262), asset_store=(138, 488),
           news=(140, 528), settings=(238, 903))
def _mode(x, y):  # Projects view-mode menu: toggle button, then List / Grid / Kanban
    return [("click", *NAV["projects"]), ("wait", 3), ("click", 1451, 224), ("wait", 1), ("click", x, y), ("wait", 7)]

SHOTS = [
    ("projects-list", _mode(1325, 277)),
    ("projects-grid", _mode(1325, 315)),
    ("projects-view", _mode(1335, 353)),   # Kanban; the final image blends all three (SPLITS)
    ("versions-view", [("click", *NAV["versions"]), ("wait", 3)]),
    ("templates-view", [("click", *NAV["templates"]), ("wait", 3)]),
    ("asset-store-view", [("click", *NAV["asset_store"]), ("wait", 9)]),   # live data
    ("news-view", [("click", *NAV["news"]), ("wait", 6)]),                 # live data
    ("settings-view", [("click", *NAV["settings"]), ("wait", 8)]),
    ("git-view", [("click", *NAV["projects"]), ("wait", 3), ("click", 385, 420), ("wait", 4),
                  ("shot_then", ("click", 1445, 70), ("wait", 1))]),
    ("doctor-view", [("click", 567, 525), ("wait", 1), ("click", 471, 125), ("wait", 4)]),
]

# Final images built from several captures: three diagonal slices side by side.
SPLITS = {"projects-view": [("projects-list", "List"), ("projects-grid", "Grid"), ("projects-view", "Kanban")]}
RAW_ONLY = {"projects-list", "projects-grid"}  # captured for a split, never written to assets/
SLANT = 150  # horizontal run of each dividing line

# --------------------------------------------------------------------------- build
def build():
    os.makedirs(DATA, exist_ok=True)
    define = "UPDATER_LAB_DATA=" + DATA.replace("\\", "/")  # runs the app on its own data folder
    subprocess.run(["flutter", "build", "windows", "--release", "--dart-define=" + define], cwd=APP, check=True, shell=True)
    subprocess.run(["git", "checkout", "--", "linux", "macos", "windows/flutter"], cwd=APP)

# --------------------------------------------------------------------------- seed (all dummy data)
GD = '''extends Node

@export var speed: float = 220.0
@export var health: int = 100

func _physics_process(delta: float) -> void:
\tvar dir := Input.get_vector("left", "right", "up", "down")
\tposition += dir * speed * delta

func take_damage(amount: int) -> void:
\thealth = max(health - amount, 0)
\tif health == 0:
\t\tqueue_free()
'''
TSCN = '[gd_scene format=3]\n\n[node name="Main" type="Node2D"]\n'

GLYPHS = {
    "car": '<path d="M20 78l10-26h68l10 26v22H20z" fill="#fff" opacity=".95"/><circle cx="40" cy="100" r="9" fill="#1b1d24"/><circle cx="88" cy="100" r="9" fill="#1b1d24"/>',
    "tower": '<path d="M34 100V54l14-12 8 10 8-10 14 12v46z" fill="#fff" opacity=".95"/><rect x="54" y="74" width="20" height="26" rx="10" fill="#1b1d24" opacity=".8"/>',
    "cloud": '<path d="M36 90a18 18 0 010-36 26 26 0 0150-6 20 20 0 016 42z" fill="#fff" opacity=".95"/>',
    "leaf": '<path d="M28 100C28 56 60 30 100 28c0 42-24 72-62 74" fill="#fff" opacity=".95"/><path d="M34 104l44-44" stroke="#1b1d24" stroke-width="5" opacity=".5"/>',
    "planet": '<circle cx="64" cy="64" r="26" fill="#fff" opacity=".95"/><ellipse cx="64" cy="64" rx="46" ry="12" transform="rotate(-20 64 64)" fill="none" stroke="#fff" stroke-width="6" opacity=".8"/>',
    "mug": '<path d="M34 46h48v34a20 20 0 01-20 20h-8a20 20 0 01-20-20z" fill="#fff" opacity=".95"/><path d="M82 54h10a10 10 0 010 24H82" fill="none" stroke="#fff" stroke-width="7"/>',
    "flame": '<path d="M64 24c6 22 28 30 28 56a28 28 0 01-56 0c0-14 8-20 12-30 4 8 10 10 10 4 0-10-2-18 6-30z" fill="#fff" opacity=".95"/>',
    "cat": '<path d="M30 40l16 14h36l16-14v44a28 28 0 01-28 28h-12a28 28 0 01-28-28z" fill="#fff" opacity=".95"/><circle cx="52" cy="76" r="5" fill="#1b1d24"/><circle cx="76" cy="76" r="5" fill="#1b1d24"/>',
    "gem": '<path d="M40 44h48l18 22-42 42-42-42z" fill="#fff" opacity=".95"/><path d="M22 66h84M64 108L52 66l12-22 12 22z" fill="none" stroke="#1b1d24" stroke-width="3" opacity=".4"/>',
}

def svg_icon(c1, c2, glyph):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><defs>'
            f'<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c1}"/>'
            f'<stop offset="1" stop-color="{c2}"/></linearGradient></defs><rect width="128" height="128" rx="28" fill="url(#g)"/>{GLYPHS[glyph]}</svg>')

def png(w, h, rgb):
    raw = b"".join(b"\x00" + bytes(rgb) * w for _ in range(h))
    def chunk(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))

VERSIONS = [  # tag, version string, mono, custom name, installed N days ago
    ("4.7.2-stable", "4.7.2.stable.official.ed1daf0bf", False, None, 6),
    ("4.7.2-stable-mono", "4.7.2.stable.mono.official.ed1daf0bf", True, None, 6),
    ("4.8-beta3", "4.8.beta3.official.c51ff06e8", False, "Next (4.8 beta)", 3),
    ("4.6.1-stable", "4.6.1.stable.official.9a1c2f7d3", False, None, 40),
    ("4.5-stable", "4.5.stable.official.1c0e4f8aa", False, "Legacy 4.5", 90),
]
CATEGORIES = [("In Progress", "#457ff2"), ("Prototypes", "#f28b45"), ("Finished", "#45c97f"), ("Game Jams", "#e74c8a")]
PROJECTS = [  # name, folder, category, version tag, tags, icon colours, glyph, pinned, opened N days ago, hours, files, git, blurb
    ("Neon Drift", "NeonDrift", "In Progress", "4.7.2-stable", ["racing", "3d", "multiplayer"], ("#ff5f9e", "#7a3cff"), "car", True, 0.1, 38.5, 5, "dirty", "Arcade drift racing with rollback netcode."),
    ("Hollow Keep", "HollowKeep", "In Progress", "4.7.2-stable-mono", ["roguelike", "2d", "co-op"], ("#3a86ff", "#1b3a8a"), "tower", True, 0.4, 64.2, 5, "dirty", "Procedural dungeon crawler for up to four players."),
    ("Skybound", "Skybound", "In Progress", "4.7.2-stable", ["platformer", "2d"], ("#4cc9f0", "#4361ee"), "cloud", False, 1.2, 21.0, 4, "clean", "A cozy cloud-hopping platformer."),
    ("Orbit Defense", "OrbitDefense", "Prototypes", "4.8-beta3", ["tower-defense", "space"], ("#f9c74f", "#f3722c"), "planet", False, 2.6, 9.3, 3, "dirty", "Defend a space station with orbiting turrets."),
    ("Pixel Farm", "PixelFarm", "Prototypes", "4.6.1-stable", ["farming", "pixel-art"], ("#90be6d", "#43aa8b"), "leaf", False, 5.0, 14.7, 4, "clean", "A relaxing farming sim."),
    ("Tiny Tavern", "TinyTavern", "Finished", "4.5-stable", ["management", "cozy"], ("#f4a261", "#e76f51"), "mug", False, 21.0, 112.8, 5, "clean", "Run a tiny tavern."),
    ("Echoes of Ash", "EchoesOfAsh", "Finished", "4.6.1-stable", ["narrative", "2d"], ("#e63946", "#7a1f2b"), "flame", False, 33.0, 87.4, 4, "clean", "A short narrative adventure."),
    ("Gravity Cat", "GravityCat", "Game Jams", "4.6.1-stable", ["jam", "physics"], ("#b388eb", "#6a4c93"), "cat", False, 47.0, 11.9, 3, "none", "48-hour jam entry."),
    ("Crystal Caverns", "CrystalCaverns", "Game Jams", "4.5-stable", ["jam", "mining"], ("#2ec4b6", "#1b6a73"), "gem", False, 61.0, 7.2, 3, "none", "Jam entry: dig for crystals."),
]
TEMPLATES = [
    ("2D Platformer Starter", "Character controller, camera and tilemap setup.", "cloud", "#4cc9f0", "#4361ee"),
    ("First-Person Kit", "Mouse look, movement and interaction.", "gem", "#ffb703", "#fb8500"),
    ("Multiplayer Lobby", "ENet lobby, player spawner and chat.", "tower", "#8ecae6", "#219ebc"),
]
AUTHORS = [("Mara Lindqvist", "mara@example.com"), ("Dev Patel", "dev@example.com"), ("Sam Okafor", "sam@example.com")]
COMMITS = ["Add player controller", "Tune drift physics", "Fix collision on ramps", "Add HUD and speedometer",
           "Polish main menu", "Refactor input handling", "Add enemy spawner", "Balance difficulty curve", "Add save system"]

def _rmtree(path):
    if os.path.exists(path):
        shutil.rmtree(path, onerror=lambda f, p, e: (os.chmod(p, 0o700), f(p)))  # git objects are read-only

def _git(folder, *args, when=None, who=None):
    env = dict(os.environ)
    if who: env.update(GIT_AUTHOR_NAME=who[0], GIT_AUTHOR_EMAIL=who[1], GIT_COMMITTER_NAME=who[0], GIT_COMMITTER_EMAIL=who[1])
    if when: env.update(GIT_AUTHOR_DATE=when, GIT_COMMITTER_DATE=when)
    subprocess.run(["git", "-C", folder, *args], env=env, check=True, capture_output=True)

def seed():
    rnd = random.Random(7)
    now = dt.datetime.now().astimezone()
    iso = lambda d: d.isoformat()
    uid = lambda: str(uuid.uuid4())
    for d in (DATA, DEMO): _rmtree(d)
    games, vers, tpl = (os.path.join(DEMO, n) for n in ("Games", "Versions", "Templates"))
    for d in (games, vers, tpl, DATA): os.makedirs(d)

    installed = []
    for tag, ver, mono, name, ago in VERSIONS:
        folder = os.path.join(vers, tag); os.makedirs(folder)
        exe = os.path.join(folder, f"Godot_v{tag.replace('-mono', '')}{'_mono' if mono else ''}_win64.exe")
        with open(exe, "wb") as f: f.write(b"MZ" + os.urandom(2048 * rnd.randint(40, 90)))
        installed.append({"tag": tag, "version": ver, "executable_path": exe, "is_mono": mono, "installed_at": iso(now - dt.timedelta(days=ago)),
                          "custom_name": name, "install_root": None, "supports_console": True, "managed_by": None})
    json.dump(installed, open(os.path.join(DATA, "godot-versions.json"), "w"), indent=2)

    ws_main, ws_jam = uid(), uid()
    ws_dir = os.path.join(DATA, "workspaces", ws_main)
    os.makedirs(os.path.join(ws_dir, "templates")); os.makedirs(os.path.join(ws_dir, "vault"))
    ws_info = lambda i, n, ic, c, days: {"id": i, "name": n, "icon": ic, "color": c, "created_at": iso(now - dt.timedelta(days=days))}
    infos = [ws_info(ws_main, "Main", "gamepad", "#457ff2", 120), ws_info(ws_jam, "Game Jams", "bolt", "#f0b132", 60)]
    json.dump({"workspaces": infos, "active_id": ws_main}, open(os.path.join(DATA, "workspaces.json"), "w"), indent=2)
    json.dump(infos[0], open(os.path.join(ws_dir, "workspace.json"), "w"), indent=2)
    jam_dir = os.path.join(DATA, "workspaces", ws_jam); os.makedirs(jam_dir)
    json.dump(infos[1], open(os.path.join(jam_dir, "workspace.json"), "w"), indent=2)

    cats = [{"id": uid(), "name": n, "sort_order": i, "color": c, "hidden": False, "folders": []} for i, (n, c) in enumerate(CATEGORIES)]
    projects = []
    for i, (name, folder, cat, ver, tags, (c1, c2), glyph, pinned, opened, hours, nfiles, git, blurb) in enumerate(PROJECTS):
        d = os.path.join(games, folder)
        for sub in ("scenes", "scripts", "assets/art", "assets/audio", "assets/models", "addons", ".godothub"): os.makedirs(os.path.join(d, sub))
        open(os.path.join(d, "icon.svg"), "w").write(svg_icon(c1, c2, glyph))
        feat = ".".join(ver.split("-")[0].split(".")[:2])
        open(os.path.join(d, "project.godot"), "w").write(
            f'config_version=5\n\n[application]\n\nconfig/name="{name}"\nconfig/tags=PackedStringArray({", ".join(chr(34) + t + chr(34) for t in tags)})\n'
            f'run/main_scene="res://scenes/main.tscn"\nconfig/features=PackedStringArray("{feat}", "Forward Plus")\nconfig/icon="res://icon.svg"\n')
        open(os.path.join(d, "scenes", "main.tscn"), "w").write(TSCN)
        for n in ("player", "enemy", "hud", "level_01", "level_02")[:nfiles]:
            open(os.path.join(d, "scenes", n + ".tscn"), "w").write(TSCN * 6)
            open(os.path.join(d, "scripts", n + ".gd"), "w").write(GD * rnd.randint(2, 6))
        for k in range(nfiles * 2):
            open(os.path.join(d, "assets/art", f"sprite_{k:02}.png"), "wb").write(png(96 + 16 * k, 96, (rnd.randint(40, 255), (90 + 12 * k) % 255, rnd.randint(40, 255))))
        for k in range(nfiles):
            open(os.path.join(d, "assets/audio", f"track_{k}.ogg"), "wb").write(os.urandom(rnd.randint(90, 400) * 1024))
            open(os.path.join(d, "assets/models", f"prop_{k}.glb"), "wb").write(os.urandom(rnd.randint(40, 260) * 1024))
        open(os.path.join(d, "README.md"), "w").write(f"# {name}\n\n{blurb}\n")
        open(os.path.join(d, ".gitignore"), "w").write(".godot/\n.godothub/\n")
        if git != "none": _seed_git(d, git, rnd, now)

        pid = uid()
        base = {"In Progress": 4200, "Prototypes": 1700}.get(cat, 0)
        daily = {}
        for k in range(14):
            if base and rnd.random() > 0.2:
                daily[(now - dt.timedelta(days=k)).strftime("%Y-%m-%d")] = int(base * rnd.uniform(0.2, 1.5) * (1.4 if k in (0, 1, 3) else 1))
        sessions = [{"start_ms": int((now - dt.timedelta(days=k, hours=3)).timestamp() * 1000), "seconds": s} for k, (_, s) in enumerate(sorted(daily.items(), reverse=True))]
        json.dump({"schema_version": 1, "project_id": pid, "sessions": sessions, "daily": daily, "applied": []}, open(os.path.join(d, ".godothub", "time_tracking.json"), "w"), indent=2)
        week = sum(v for k, v in daily.items() if (now.date() - dt.date.fromisoformat(k)).days < 7)
        projects.append({"id": pid, "name": name, "path": d, "godot_version": ver, "created_at": iso(now - dt.timedelta(days=120 - i * 9)),
                         "last_opened": iso(now - dt.timedelta(days=opened)), "category": cat, "pinned": pinned, "sort_order": i, "launch_arguments": "",
                         "tags": tags, "total_time_seconds": max(int(hours * 3600), sum(daily.values())), "session_started_at_ms": None,
                         "time_today_seconds": daily.get(now.strftime("%Y-%m-%d"), 0), "time_week_seconds": week})

    for name, desc, glyph, c1, c2 in TEMPLATES:
        tid = uid(); td = os.path.join(ws_dir, "templates", tid)
        for sub in ("scenes", "scripts", "addons"): os.makedirs(os.path.join(td, sub))
        open(os.path.join(td, "icon.svg"), "w").write(svg_icon(c1, c2, glyph))
        open(os.path.join(td, "project.godot"), "w").write(f'config_version=5\n\n[application]\n\nconfig/name="{name}"\nconfig/features=PackedStringArray("4.7", "Forward Plus")\nconfig/icon="res://icon.svg"\n')
        open(os.path.join(td, "scenes", "main.tscn"), "w").write(TSCN)
        open(os.path.join(td, "scripts", "player.gd"), "w").write(GD * 3)
        json.dump({"id": tid, "name": name, "description": desc, "godot_version": "4.7.2-stable", "created_at": iso(now - dt.timedelta(days=30)),
                   "source_project_id": None, "source_path": None, "path": td, "keep_name": False}, open(os.path.join(td, "template.json"), "w"), indent=2)

    settings = {"schema_version": 1, "download_dir": vers, "default_project_location": games, "template_scan_dir": tpl,
                "accent_color": "#%02x%02x%02x" % ACCENT, "background_color": "#15171c", "theme_mode": "dark",
                "setup_complete": True, "auto_scan_on_startup": False, "auto_watch_project_dirs": False,
                "auto_watch_version_dirs": False, "auto_watch_template_dir": False, "discord_rpc_enabled": False,
                "use_os_decorations": False, "colored_titlebar_buttons": False, "desktop_notifications_enabled": False,
                "show_support_button": False, "show_star_button": False}
    for d in (ws_dir, jam_dir): json.dump(settings, open(os.path.join(d, "settings.json"), "w"), indent=2)
    json.dump(projects, open(os.path.join(ws_dir, "projects.json"), "w"), indent=2)
    json.dump(cats, open(os.path.join(ws_dir, "categories.json"), "w"), indent=2)
    json.dump([], open(os.path.join(jam_dir, "projects.json"), "w"))
    # Quiet the first-run hints and show the Kanban board.
    json.dump({"schema_version": 1, "values": {
        "godothub_projects_view_mode": "kanban", "new_ui_sidebar_workspace_tip_seen": "1", "new_ui_sidebar_palette_hint_dismissed": "1",
        "new_ui_sidebar_seen_new_tabs": '["vault","storage"]', "godothub_announcement_dismissed": "1"}}, open(os.path.join(DATA, "ui_prefs.json"), "w"), indent=2)
    print(f"seeded {len(projects)} projects in {DEMO}")

def _seed_git(d, state, rnd, now):
    _git(d, "init", "-q", "-b", "main")
    _git(d, "config", "user.name", AUTHORS[0][0]); _git(d, "config", "user.email", AUTHORS[0][1]); _git(d, "config", "core.autocrlf", "false")
    n = rnd.randint(5, 8)
    for i in range(n):
        open(os.path.join(d, "scripts", f"log_{i}.gd"), "w").write(GD)
        _git(d, "add", "-A")
        _git(d, "commit", "-q", "-m", COMMITS[i % len(COMMITS)], when=(now - dt.timedelta(days=(n - i) * 3 + 1)).strftime("%Y-%m-%dT%H:%M:%S"), who=AUTHORS[i % 2 if i % 3 else 2])
    if state == "dirty":
        _git(d, "checkout", "-q", "-b", "feature/boss-fight")
        open(os.path.join(d, "scripts", "boss.gd"), "w").write(GD * 3)
        with open(os.path.join(d, "scripts", "player.gd"), "a") as f: f.write("\nfunc dash() -> void:\n\tposition.x += 120.0\n")
        open(os.path.join(d, "scripts", "log_1.gd"), "w").write(GD.replace("220.0", "260.0"))
        os.remove(os.path.join(d, "scripts", "log_0.gd"))
        open(os.path.join(d, "scenes", "boss.tscn"), "w").write(TSCN)
        _git(d, "add", os.path.join(d, "scenes", "boss.tscn"))

# --------------------------------------------------------------------------- capture
user32 = ctypes.windll.user32
dwm = ctypes.windll.dwmapi

def _window_of(pid):
    found = []
    @ctypes.WINFUNCTYPE(wt.BOOL, wt.HWND, wt.LPARAM)
    def cb(h, _):
        owner = wt.DWORD(); user32.GetWindowThreadProcessId(h, ctypes.byref(owner))
        if owner.value == pid and user32.IsWindowVisible(h) and user32.GetWindowTextLengthW(h) > 0: found.append(h)
        return True
    user32.EnumWindows(cb, 0)
    return found[0] if found else None

def _frame(h):
    r = wt.RECT(); dwm.DwmGetWindowAttribute(h, 9, ctypes.byref(r), ctypes.sizeof(r))  # extended frame bounds
    return r.left, r.top, r.right, r.bottom

def _click(h, x, y):
    l, t, _, _ = _frame(h); user32.SetCursorPos(l + x, t + y)
    user32.mouse_event(2, 0, 0, 0, 0); user32.mouse_event(4, 0, 0, 0, 0)

def _grab(h, name):
    from PIL import ImageGrab
    l, t, _, _ = _frame(h); user32.SetCursorPos(l + 900, t + 945)  # park the pointer on empty space
    time.sleep(0.6); user32.SetForegroundWindow(h)
    ImageGrab.grab(bbox=_frame(h), all_screens=True).save(os.path.join(RAW, name + ".png"))

def capture(only):
    if not os.path.exists(EXE): sys.exit("No build found. Run the build step first.")
    if not os.path.isdir(os.path.join(DATA, "workspaces")): sys.exit("No sample data. Run the seed step first.")
    user32.SetProcessDPIAware()
    os.makedirs(RAW, exist_ok=True)
    proc = subprocess.Popen([EXE], cwd=os.path.dirname(EXE))
    try:
        h = None
        for _ in range(80):
            time.sleep(0.5); h = _window_of(proc.pid)
            if h: break
        if not h: sys.exit("The app window never appeared.")
        user32.ShowWindow(h, 9); user32.SetWindowPos(h, 0, *WINDOW, 0x0040); user32.SetForegroundWindow(h)
        time.sleep(3)
        for name, steps in SHOTS:
            if only and name not in only: continue
            after = None
            for step in steps:
                if step[0] == "click": _click(h, step[1], step[2])
                elif step[0] == "wait": time.sleep(step[1])
                elif step[0] == "shot_then": after = step[1:]
            _grab(h, name); print("captured", name)
            for step in after or ():
                if step[0] == "click": _click(h, step[1], step[2])
                elif step[0] == "wait": time.sleep(step[1])
    finally:
        proc.terminate()

# --------------------------------------------------------------------------- compose
def _blend(paths):
    from PIL import Image, ImageDraw, ImageFont
    shots = [Image.open(p).convert("RGBA") for p, _ in paths]
    w, h = shots[0].size
    cuts = [w * (i + 1) / len(shots) for i in range(len(shots) - 1)]
    edges = [-SLANT] + cuts + [w + SLANT]  # x of each boundary at mid-height
    out = shots[0].copy()
    for i, shot in enumerate(shots):
        left, right = edges[i], edges[i + 1]
        poly = [(left + SLANT / 2, 0), (right + SLANT / 2, 0), (right - SLANT / 2, h), (left - SLANT / 2, h)]
        mask = Image.new("L", (w * 4, h * 4), 0)
        ImageDraw.Draw(mask).polygon([(x * 4, y * 4) for x, y in poly], fill=255)
        out.paste(shot, (0, 0), mask.resize((w, h), Image.LANCZOS))
    draw = ImageDraw.Draw(out)
    for c in cuts: draw.line([(c + SLANT / 2, 0), (c - SLANT / 2, h)], fill=ACCENT + (255,), width=4)
    try: font = ImageFont.truetype("segoeuib.ttf", 22)  # Windows UI font, bold
    except OSError: font = ImageFont.load_default()
    for i, (_, label) in enumerate(paths):  # name each slice with a pill near the bottom
        cx = (max(edges[i], w * 0.27) + edges[i + 1]) / 2 - SLANT * 0.4  # content area only; the lines lean left toward the bottom
        cx = min(max(cx, 90), w - 90)
        box = draw.textbbox((0, 0), label, font=font)
        tw, th = box[2] - box[0], box[3] - box[1]
        x0, y0, x1, y1 = cx - tw / 2 - 20, h - 74, cx + tw / 2 + 20, h - 74 + th + 22
        draw.rounded_rectangle((x0, y0, x1, y1), (y1 - y0) / 2, fill=ACCENT + (255,))
        draw.text((cx - tw / 2 - box[0], y0 + 11 - box[1]), label, font=font, fill=(255, 255, 255, 255))
    return out

def compose(only):
    from PIL import Image, ImageDraw, ImageFilter
    for name, _ in SHOTS:
        src = os.path.join(RAW, name + ".png")
        if name in RAW_ONLY or (only and name not in only) or not os.path.exists(src): continue
        im = _blend([(os.path.join(RAW, n + ".png"), label) for n, label in SPLITS[name]]) if name in SPLITS else Image.open(src).convert("RGBA")
        im = im.crop((2, 3, im.width - 2, im.height - 2))  # drop the invisible resize border
        w, h = im.size
        mask = Image.new("L", (w * 4, h * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, w * 4 - 1, h * 4 - 1), RADIUS * 4, fill=255)
        im.putalpha(mask.resize((w, h), Image.LANCZOS))
        cw, ch = w + PAD * 2, h + PAD * 2
        canvas = Image.new("RGBA", (cw, ch), ACCENT + (255,))
        shadow = Image.new("L", (cw, ch), 0)
        ImageDraw.Draw(shadow).rounded_rectangle((PAD, PAD + 22, PAD + w, PAD + h + 22), RADIUS, fill=150)
        black = Image.new("RGBA", (cw, ch), (0, 0, 0, 0)); black.putalpha(shadow.filter(ImageFilter.GaussianBlur(26)))
        canvas = Image.alpha_composite(canvas, black)
        canvas.alpha_composite(im, (PAD, PAD))
        rim = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        ImageDraw.Draw(rim).rounded_rectangle((PAD, PAD, PAD + w - 1, PAD + h - 1), RADIUS, outline=(255, 255, 255, 40), width=1)
        dst = os.path.join(OUT, name + ".png")
        Image.alpha_composite(canvas, rim).convert("RGB").save(dst, optimize=True)
        print("wrote", os.path.relpath(dst, ROOT), os.path.getsize(dst) // 1024, "KB")

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("steps", nargs="+", choices=["all", "build", "seed", "capture", "compose"])
    p.add_argument("--only", nargs="*", help="limit capture and compose to these shot names")
    a = p.parse_args()
    steps = ["build", "seed", "capture", "compose"] if "all" in a.steps else a.steps
    if "build" in steps: build()
    if "seed" in steps: seed()
    if "capture" in steps: capture(a.only)
    if "compose" in steps: compose(a.only)

if __name__ == "__main__":
    main()
