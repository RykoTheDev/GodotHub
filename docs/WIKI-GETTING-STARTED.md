# Getting Started

This page walks you through installing GodotHub, the first-run setup, and what to do once everything is configured.

---

## Installation

### Windows

Download the installer from the [releases page](https://github.com/RykoTheDev/godothub/releases/latest):

- `GodotHub-<version>-windows-x64-setup.exe` - recommended installer
- `GodotHub-<version>-windows-x64.msi` - alternative installer
- `GodotHub-<version>-windows-x64-portable.exe` - runs without installing

Or install with winget:

```powershell
winget install Ryko.GodotHub
```

To update a winget install later:

```powershell
winget upgrade Ryko.GodotHub
```

> Winget can lag behind the latest release, since the package update isn't always merged right away. If you want the newest version, download it from the releases page instead.

### macOS

Download `GodotHub-<version>-darwin-universal.dmg` from the [releases page](https://github.com/RykoTheDev/godothub/releases/latest). It's a universal build, so it runs on both Apple Silicon and Intel Macs.

### Linux

Grab the package for your distro from the [releases page](https://github.com/RykoTheDev/godothub/releases/latest):

- `GodotHub-<version>-linux-amd64.deb` - Debian and Ubuntu based distros
- `GodotHub-<version>-linux-x86_64.rpm` - Fedora, RHEL, and openSUSE based distros
- `GodotHub-<version>-linux-amd64.AppImage` - single file, nothing to install

Replace `<version>` with the release you're downloading (for example `1.4.4`). Releases before v1.4.4 use the older file names.

Two things to know about Linux:

- The AppImage doesn't work on most distros right now. It's an upstream `linuxdeploy` issue that affects nearly all Tauri apps, so it can't be fixed from this project. Use the `.deb` or `.rpm` instead where possible.
- GodotHub is currently tested on Windows, Arch Linux (Hyprland), and the newest macOS. Other distros are untested. If you hit a problem on yours, please open an issue.

### Build from source

Prerequisites:

| Dependency | Purpose |
|---|---|
| [Bun](https://bun.sh) >= 1.0 | JavaScript runtime and package manager |
| [Rust](https://rustup.rs) (latest stable) | Backend compilation |
| [Tauri 2 prerequisites](https://v2.tauri.app/start/prerequisites/) | Platform-specific build tools |

```bash
git clone https://github.com/RykoTheDev/godothub.git
cd godothub

bun install

# Development mode with hot-reload
bun tauri dev

# Production build
bun tauri build
```

The built app ends up in `src-tauri/target/release/bundle/`.

---

## First launch

When GodotHub starts for the first time, the **onboarding wizard** walks you through the basic setup. You can skip any step and configure it later from Settings.

| Step | What it asks |
|---|---|
| Welcome | A quick overview of what GodotHub does. |
| Projects | Add folders GodotHub should scan for existing Godot projects. Star one to make it the default save location for new projects. |
| Godot versions | Add folders that contain installed Godot executables. Star one to set it as the download location for new versions. |
| Templates | Optionally set a folder of reusable project templates. Any subfolder inside it is imported as a template. |
| Categories | Set up folders for organizing your project list, or skip and manage them later. |
| Customize | Pick an accent color, background color, and corner radius to start. |
| Setting up | GodotHub scans your chosen folders and finishes. |

You can reopen the wizard anytime from **Settings → Advanced → Run Setup Wizard Again**. Settings you already saved are kept, and you can skip any step you don't need to change.

---

## After setup

- **Projects**: import existing Godot projects or create new ones, pin favorites, and organize them with categories and tags.
- **Versions**: browse and download official Godot builds, or import executables you already have.
- **Templates**: save any project as a template and start new projects from it.
- **Asset Store**: install assets from the old Asset Library or the new Asset Store straight into a project or template.
- **Git**: clone, commit, push, and manage branches for any project from inside the app.
- **Appearance**: switch to the [[Custom CSS in the New UI]] page when you want to restyle things the built-in settings can't.

---

## Searching projects

The search bar at the top of the **Projects** view filters as you type. There's no minimum length, so a project with a two- or three-letter name is just as searchable as one with a long name. Every word you type has to match something, and results are ranked so the closest name floats to the top instead of being buried under projects that only match on their folder path.

| Rank | Matches against |
|---|---|
| 1 | Project name - exact, then starts with, then a word inside the name, then anywhere in the name |
| 2 | Tags |
| 3 | Category |
| 4 | Engine version |
| 5 | Folder path on disk |

Filtering happens live, so `Enter` is only needed to confirm a highlighted suggestion in the slash menu below. The **✕** button clears the search.

### Slash commands

Type `/` in the search bar to open the list of things you can filter by. Keep typing to narrow it down, move with `↑`/`↓`, and pick with `Enter`, `Tab`, or a click. Tags, categories, and engine versions then show the values you actually have, so you pick from a list instead of typing them out. `Esc` closes the menu and leaves what you've typed alone.

| Field | What it filters | Example |
|---|---|---|
| `name:` | Project name | `name:boss` |
| `tag:` | Project tags | `tag:pixel-art` |
| `category:` | Category name | `category:Game Jam` |
| `version:` | Engine version | `version:4.3` |
| `path:` | Folder path on disk | `path:D:/dev` |
| `pinned:` | Pinned projects only | `pinned:` |

Use `pinned:false` to see everything that *isn't* pinned. `cat:` works as a shortcut for `category:`, and `engine:` for `version:`. The field names are spelled out on purpose so that pasting a path like `C:\dev` stays a normal search instead of being read as a filter.

Filters stack with each other and with plain words, so you can search for:

```
boss tag:pixel-art category:Game Jam
```

which means "projects matching *boss*, tagged *pixel-art*, in the *Game Jam* category".

> While a search or a tag/category filter is active, results show up as one ranked list instead of your category sections, so nothing can hide inside a collapsed section. Dragging to reorder is turned off until you clear the search.

---

## Related

- [[Home]]
- [[Custom CSS in the New UI]]
- [[Settings Reference]]
- [[FAQ / Troubleshooting]]
