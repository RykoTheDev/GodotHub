# README screenshots

`screenshots.py` regenerates the images in `assets/` that the repository README shows. It builds the app, fills a throwaway library with sample data, drives the real window, and puts each capture on a flat GodotHub-blue background with rounded corners and a shadow.

```bash
python dev/tool/screenshots/screenshots.py all
```

Windows only (the capture uses the Win32 window APIs). Needs Python 3.10+, `pip install pillow`, `git`, and the Flutter and Rust toolchains.

## Steps

| Step | What it does |
|---|---|
| `build` | `flutter build windows --release` with `UPDATER_LAB_DATA` pointing at `app/build/screenshots/data`, so the app runs on its own data and never touches your library. |
| `seed` | Writes the sample library (into `C:\GodotDemo`, or the folder in `GODOTHUB_SCREENSHOT_DEMO`; delete it when you are done): 9 projects (icons, tags, time history, git repos with uncommitted changes), 5 fake Godot versions, 3 templates, 2 workspaces. All names are made up; nothing comes from your machine. |
| `capture` | Starts the built app, sizes the window, clicks through each view and saves raw captures to `app/build/screenshots/raw`. |
| `compose` | Adds the background, rounded corners and shadow and writes the final PNGs into `assets/`. |

Run steps on their own, for example `python dev/tool/screenshots/screenshots.py capture compose --only git-view` to redo one image without rebuilding. `build` takes several minutes; skip it when only the sample data or the capture steps changed.

## When the layout changes

Views are opened by clicking at fixed positions in the window (1486 x 953 at 100% display scaling). They are listed at the top of `screenshots.py` in `NAV` and `SHOTS`. After a layout change:

1. Run the whole thing and look at every image in `app/build/screenshots/raw` before committing. A capture taken mid-animation looks washed out; raise that shot's `wait`.
2. If a click lands on the wrong control, fix the coordinates for that shot.
3. The Asset Store and News views show live data, so those two images differ on every run. Skip them with `--only` when only other views changed.

The image paths in the README carry a `?v=N` suffix so GitHub's image cache refreshes. Bump `N` for the images you replaced.

Keep the display at 100% scaling and nothing on top of the app window while capturing.
