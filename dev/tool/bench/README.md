# GodotHub benchmark

`bench.mjs` measures the Flutter app on Windows, Linux and macOS. One command builds, runs and writes a report:

```bash
cd app
node ../dev/tool/bench/bench.mjs all
```

The report lands in `app/build/bench_lab/results/<os>/REPORT.md`, next to the raw JSON of every run. Close every GodotHub window first; the script refuses to start while one is open.

## Requirements

| | Windows | Linux | macOS |
|---|---|---|---|
| Node.js 18+ | yes | yes | yes |
| Flutter and Rust toolchain (for `build`) | yes | yes | yes |
| Window detection (for `window`) | built in | `xdotool` or `wmctrl` in an X11 session; skipped without one | Accessibility permission for the terminal (System Events) |

On a Wayland desktop, run with `GDK_BACKEND=x11` so the app opens an XWayland window that `xdotool` can see:

```bash
GDK_BACKEND=x11 node ../dev/tool/bench/bench.mjs all
```

## Commands

| Command | What it does |
|---|---|
| `setup [--from DIR]` | Copies your GodotHub data folder into `build/bench_lab/real` (git credentials are left out) and generates a 120-project data set in `build/bench_lab/bench`. Without existing data only the generated set is used. |
| `build` | `flutter build <os> --release` with `--dart-define=GODOTHUB_BENCH=true`. That define compiles the in-app benchmark driver (`lib/bench/bench_mode.dart`); normal builds contain none of it. |
| `flutter [tasks] [--data real\|bench] [--runs N]` | Runs the Flutter tasks: `coldstart`, `window`, `memory`, `views`, `scroll`, `drag`. Scroll and drag run on the bench data set only. Default 5 runs (3 for memory). |
| `report` | Writes `REPORT.md` from the saved results. |
| `all [--skip-build]` | `setup` (if needed), `build`, `flutter` and `report`. |

The app always runs on a fresh scratch copy under `build/bench_lab/work`, so your real data is never touched.

Set `GODOTHUB_REFRESH_HZ` if the display refresh rate is detected wrong (it is used to count slow frames), and `GODOTHUB_BENCH_LAB` to put the lab somewhere other than `app/build/bench_lab`.

## What is measured

| Metric | How |
|---|---|
| First window | Process spawn to the first visible top-level window, seen from outside the app. |
| Cold start, ready | Process spawn to the first frame that shows project items (from inside the app). |
| Cold start, interactive | Ready plus three timer probes answered within 16 ms. |
| Memory | Sum over the process tree after 30 s idle. Private memory: Windows private working set, Linux `Private_Clean + Private_Dirty` from `smaps_rollup`, macOS `footprint`. Resident memory: working set / RSS. |
| View switches | Versions, Settings, Projects: first open, then 5 cycles. "Content" is the first frame showing the view, "settled" the last frame before 250 ms without frames (includes the 0.7 s slide animation). |
| Scroll | 1500 px/s over the whole list and back, 3 times, frame times from `FrameTiming`. |
| Drag | Drag the 2nd project to the 8th row and back, 3 passes. |

Numbers vary with the machine, power plan and what else is running. Plug laptops in, close heavy apps, and compare runs made on the same machine.
