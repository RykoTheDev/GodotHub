<p align="center">
  <img src="https://raw.githubusercontent.com/RykoTheDev/godothub/main/src-tauri/icons/128x128@2x.png" alt="GodotHub Logo" width="128" height="128" style="border-radius: 24px;">
</p>

<h1 align="center">GodotHub</h1>
<h3 align="center">The Ultimate Project Manager for Godot Engine</h3>

<p align="center">
  <strong>Manage projects, versions, assets, templates, and Git, all in one place.</strong>
</p>

<p align="center">
  <a href="https://github.com/RykoTheDev/godothub/releases/latest">
    <img src="https://img.shields.io/github/v/release/RykoTheDev/godothub?style=flat-square&label=Latest&color=457ff2" alt="Latest Release">
  </a>
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-5865f2?style=flat-square" alt="Platforms">
  <img src="https://img.shields.io/badge/Godot-4.x-478cbf?style=flat-square" alt="Godot 4.x">
  <img src="https://img.shields.io/github/license/RykoTheDev/godothub?style=flat-square&color=23a55a" alt="License">
  <img src="https://img.shields.io/github/stars/RykoTheDev/godothub?style=flat-square&color=f0b132" alt="Stars">
  <img src="https://img.shields.io/badge/winget-available-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Winget Available">
  <a href="https://github.com/RykoTheDev/godothub/wiki"><img src="https://img.shields.io/badge/wiki-Docs-457ff2?style=flat-square" alt="Wiki"></a>
</p>


<p align="center">
  <a href="https://github.com/RykoTheDev/godothub/releases/latest"><kbd>⬇️ Download Now</kbd></a>
  &nbsp;&nbsp;
  <a href="#-screenshots"><kbd>📸 Screenshots</kbd></a>
  &nbsp;&nbsp;
  <a href="#-features"><kbd>📖 Features</kbd></a>
  &nbsp;&nbsp;
  <a href="#-installation"><kbd>🛠️ Installation</kbd></a>
  &nbsp;&nbsp;
  <a href="#️-keyboard-shortcuts"><kbd>⌨️ Shortcuts</kbd></a>
  &nbsp;&nbsp;
  <a href="https://github.com/RykoTheDev/godothub/wiki"><kbd>📚 Wiki</kbd></a>
</p>

> [!WARNING]
> This app has only been tested on **Windows**, **Arch Linux (Hyprland) / Fedora 43 (Gnome)**, and the **newest macOS version** (thanks to a contributor). I can't guarantee how it behaves on other Linux distros, and I don't have a Mac to test on personally. Found a bug? [Open an issue](https://github.com/RykoTheDev/godothub/issues), or reach out if you'd like to help with cross-platform testing.
>
> On Linux, AppImage doesn't work for most distros right now. It's an upstream `linuxdeploy` issue that affects nearly all Tauri apps, so it's not something I can fix on my end. I'll update as soon as a fix lands upstream.

---

## 📸 Screenshots

<p align="center">
  <img src="assets/hero-screenshot.png" alt="GodotHub Main Window" width="820">
  <br>
  <em>The Projects view with search, categories, and drag-and-drop sorting</em>
</p>

<br>

<table>
  <tr>
    <td width="50%" align="center">
      <img src="assets/versions-view.png" alt="Versions View" width="400">
      <br><strong>🎯 Versions</strong>
      <br><sub>Browse, download, and manage Godot versions</sub>
    </td>
    <td width="50%" align="center">
      <img src="assets/templates-view.png" alt="Templates View" width="400">
      <br><strong>📦 Templates</strong>
      <br><sub>Save and reuse project templates</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="assets/asset-store-view.png" alt="Asset Store View" width="400">
      <br><strong>🛒 Asset Store</strong>
      <br><sub>Install assets from old and new asset store directly into projects or templates</sub>
    </td>
    <td width="50%" align="center">
      <img src="assets/git-view.png" alt="Git Integration" width="400">
      <br><strong>🔄 Git Integration</strong>
      <br><sub>Full Git management inside GodotHub</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="assets/settings-appearance-view.png" alt="Settings & Appearance" width="400">
      <br><strong>🎨 Appearance & Settings</strong>
      <br><sub>Deep customization with themes, accent colors, corner radius, and more</sub>
    </td>
    <td width="50%" align="center">
      <img src="assets/news-view.png" alt="News Feed" width="400">
      <br><strong>📰 News Feed</strong>
      <br><sub>Stay up to date with Godot community news</sub>
    </td>
  </tr>
</table>

<p align="center"><sub>💡 Screenshots show the dark theme with the default accent color. Every visual is customizable.</sub></p>

---

<p align="center">
  <a href="https://discord.com/invite/nA7dus32Yv/" target="_blank" rel="noopener noreferrer">
    <img src="/assets/discord-banner.png" alt="Discord">
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://patreon.com/TheRyko" target="_blank" rel="noopener noreferrer">
    <img src="/assets/patreon-banner.png" alt="Patreon">
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://x.com/theRyko11" target="_blank" rel="noopener noreferrer">
    <img src="/assets/twitter-banner.png" alt="Twitter">
  </a>
</p>

---

## 📖 Features

### 🗂️ Project Management

Take full control of your Godot projects with a rich, intuitive interface.

<details>
<summary><strong>See all Project Management features</strong></summary>

| Feature | Description |
|---|---|
| **Create & Import** | Create new projects from scratch or from templates, import existing ones from disk, or clone directly from Git repositories. |
| **Drag & Drop Reorder** | Rearrange projects with smooth drag-and-drop. Reorder within categories, or move between them. |
| **Pin Projects** | Pin your most important projects to a dedicated Pinned section at the top. |
| **Tags Support** | Tags are fetched directly from `project.godot`, so they stay in sync with your Godot launcher. Edit, add, or delete them and the sync follows. |
| **Batch Operations** | Select multiple projects at once to change versions, assign categories, toggle pins, or remove from the library. |
| **Search & Filter** | Search by name or path, filter by category, and sort by custom order, name, date, last opened, or project size. |
| **Version Warnings** | Visual indicators when a project's bound Godot version is missing or has a major version mismatch. |
| **Project Properties** | Inspect detailed project info including a file breakdown by type (scripts, scenes, images, audio, 3D models, etc.) with sizes and counts. |
| **Custom Launch Args** | Add custom command-line arguments when launching projects. |
| **Quick Actions** | Open project folder, open in external editor, or open a terminal at the project path, all from the project card. |

</details>

### 🎯 Godot Version Management

Download, install, and manage any Godot version effortlessly.

<details>
<summary><strong>See all Version Management features</strong></summary>

| Feature | Description |
|---|---|
| **Browse Releases** | Fetch the full list of official Godot builds directly from GitHub, filtered for your platform. |
| **Download & Install** | Download with progress tracking, resume support, and concurrent downloading (configurable up to 10 simultaneous). |
| **Import Versions** | Import existing Godot installations from any folder, or drag-and-drop a `.zip` archive. |
| **Grouped Display** | Versions are grouped by `major.minor` with collapsible sections for easy browsing. |
| **Filtering** | Filter by build type (Standard / Mono / Both) and channel (Stable / Unstable / Both). |
| **Custom Names** | Give your installed versions friendly, custom names. |
| **Auto-Cleanup** | Automatically prunes missing executables from the registry. |

</details>

### 📦 Templates

Save time by reusing project structures.

<details>
<summary><strong>See all Templates features</strong></summary>

| Feature | Description |
|---|---|
| **Save as Template** | Convert any existing project into a reusable template. |
| **Create from Template** | Start new projects pre-populated with template content. |
| **Preview Contents** | Browse the full directory tree of any template before using it. |
| **Sync from Directory** | Automatically import templates from a configured scan folder. |
| **File Watcher** | The template directory is watched for changes, so editing a template folder updates the library automatically. |

</details>

### 🔄 Git Integration

Full-featured Git management right inside GodotHub.

<details>
<summary><strong>See all Git Integration features</strong></summary>

| Feature | Description |
|---|---|
| **Status Overview** | See branch name, uncommitted changes, and repo status at a glance. |
| **Stage / Unstage** | Stage and unstage individual files or all at once. |
| **Commit** | Write commit messages with optional amend. |
| **Push / Pull / Fetch** | Sync with remotes. |
| **Branch Management** | List, switch, create, and delete branches. |
| **Stash** | Push, list, apply, and drop stashes. |
| **Diff Viewer** | Inline diff viewer for changed files with syntax-colored additions and deletions. |
| **Discard Changes** | Discard all uncommitted changes with confirmation. |
| **Init & Remote** | Initialize a new Git repo, set or remove remotes. |
| **Undo** | Undo the last commit or undo a pull. |
| **Auto-Refresh** | Git status is polled every 30 seconds automatically. |

</details>

### 🧭 Workspaces

Keep your projects organized with multiple workspaces.

<details>
<summary><strong>See all Workspaces features</strong></summary>

| Feature | Description |
|---|---|
| **Multiple Workspaces** | Create separate workspaces for different projects, clients, or game jams. |
| **Custom Icons & Colors** | Each workspace gets a unique icon and color for quick visual identification. |
| **Quick Switch** | Switch between workspaces from the sidebar dropdown. |

</details>

### 🏷️ Categories

Organize projects with flexible, colorful categories.

<details>
<summary><strong>See all Categories features</strong></summary>

| Feature | Description |
|---|---|
| **Create & Customize** | Create categories with custom names and colors from a rich palette. |
| **Collapsible Sections** | Collapse and expand category sections to keep the view clean. |
| **Drag Between Categories** | Drag projects between categories using `@dnd-kit`-powered sorting. |
| **Filter by Category** | Filter the project list by any category. |
| **Enable / Disable** | Turn categories on or off globally from Settings. |

</details>

### 📰 News Feed

Stay up to date with the Godot community.

<details>
<summary><strong>See all News Feed features</strong></summary>

| Feature | Description |
|---|---|
| **RSS Feed** | Fetches and displays Godot-related news and updates. |
| **Cached** | Feed data is cached for performance. |
| **Open in Browser** | Click any news item to open the full article. |

</details>

### 🎨 Appearance & Customization

Make GodotHub truly yours.

<details>
<summary><strong>See all Appearance features</strong></summary>

| Feature | Description |
|---|---|
| **Dark / Light Mode** | Switch between dark and light themes. |
| **Accent Color** | Choose from 18 preset accent colors or pick any custom hex color. |
| **Background Color** | Customize the background with presets or random generation. |
| **"Feeling Lucky"** | Randomly generate a unique color scheme in one click. |
| **Corner Radius** | Adjust from 0 (sharp) to 20px (rounded), applied to every element. |
| **UI Density** | Scale padding and spacing from 75% (compact) to 125% (spacious). |
| **Font Scale** | Scale all text from 85% to 130%. |
| **Reduce Motion** | Minimize animations for accessibility. |
| **Sidebar Width** | Independently adjust expanded and collapsed sidebar widths. |

</details>

### ⚙️ Settings & Preferences

Deep configuration options for every aspect of the app.

<details>
<summary><strong>See all Settings features</strong></summary>

| Feature | Description |
|---|---|
| **Storage Locations** | Configure scan directories for projects, Godot versions, and templates. |
| **Auto-Scan on Startup** | Automatically discover new projects and versions when the app starts. |
| **File Watchers** | Real-time detection of changes in project, version, and template directories. |
| **Download Concurrency** | Control how many Godot versions download simultaneously (1 to 10). |
| **Scan Depth** | Configure how deeply to scan folders (1 to 10 levels). |
| **Close on Launch** | Quit or minimize to tray when launching a project. |
| **Reopen After Godot Closes** | Automatically restore GodotHub when the editor closes. |
| **Tray Menu** | Recent projects in the system tray context menu (configurable count). |
| **Tooltip Delay** | Adjust tooltip hover delay from 100ms to 1000ms. |
| **Command Palette Keybind** | Rebind `Ctrl/Cmd + <key>` to your preferred key. |
| **Export / Import** | Back up or transfer all settings as JSON. |
| **Reset & Wipe** | Reset settings to defaults or wipe all app data entirely. |

</details>

### ✨ Other Highlights

<details open>
<summary><strong>See more</strong></summary>

| Feature | Description |
|---|---|
| **Drag & Drop Import** | Drag project folders or `.zip` version archives directly into the app window. |
| **Command Palette** | `Ctrl/Cmd + P` (or your custom key) opens a powerful command palette for quick navigation. |
| **System Tray** | Minimize to tray with a right-click menu showing recently opened projects. |
| **Custom Titlebar** | A frameless window with a custom title bar for a polished, modern feel. |
| **Splash Screen** | An animated splash screen greets you on startup. |
| **Onboarding Wizard** | Guided first-time setup to configure scan folders, categories, and appearance. |
| **Auto-Updates** | Checks for updates on startup and downloads new versions automatically via the Tauri updater. |
| **Bug Reporting** | Report issues directly from the app. |
| **Changelog Viewer** | Track what's new in each GodotHub release. |
| **Keyboard Shortcuts** | Full shortcut cheatsheet available at any time. |

</details>

---

## 🤖 AI Disclosure

Some parts of this codebase have been restructured and small bugs fixed with the assistance of [DeepSeek AI](https://chat.deepseek.com/). All changes are reviewed and tested by me before being merged. Whole Code is written by a freshly baked Human from scratch.

For those who don't know how to read commits, Copilot is **not** used here. I Accidentally had it fix the PR where it literally only removed a Space and now its in Collaborators list. I've since disabled it, and it has no authority over this repository, including reviews.
As for Codebuff AI, I didnt even have its subscription, Was testing it before realizing that and this thing somehow sneaked in with the commit message..... =_=

---

## 🛠️ Installation

### Download Prebuilt Binaries

GodotHub is available as a desktop application for:

| Platform | Package Types |
|---|---|
| 🪟 **Windows** | `.msi` or `.exe` installer |
| 🍎 **macOS** | `.dmg` or `.app` bundle |
| 🐧 **Linux** | `.deb`, `.AppImage`, or `.rpm` packages |

<p align="center"><a href="https://github.com/RykoTheDev/godothub/releases/latest"><strong>⬇️ Download the latest release</strong></a></p>

### Install via Winget (Windows)

GodotHub is available on the **Windows Package Manager (winget)**. On Windows 10 or 11, install it with a single command:

> [!NOTE]
> Winget can lag behind the latest release since maintainers don't always merge the update promptly.

```powershell
winget install Ryko.GodotHub
```

To update manually:

```powershell
winget upgrade Ryko.GodotHub
```

### Build from Source

<details>
<summary><strong>Prerequisites</strong></summary>

| Dependency | Version | Purpose |
|---|---|---|
| [Bun](https://bun.sh) | >= 1.0 | JavaScript runtime & package manager |
| [Rust](https://rustup.rs) | Latest stable | Backend compilation |
| [Tauri 2 Prerequisites](https://v2.tauri.app/start/prerequisites/) | n/a | Platform-specific build tools |

</details>

```bash
# Clone the repository
git clone https://github.com/RykoTheDev/godothub.git
cd godothub

# Install frontend dependencies
bun install

# Run in development mode (with hot-reload)
bun tauri dev

# Build for production
bun tauri build
```

> [!TIP]
> You'll find the built app in `src-tauri/target/release/bundle/`.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl/Cmd + 1` | Go to Projects |
| `Ctrl/Cmd + 2` | Go to Versions |
| `Ctrl/Cmd + 3` | Go to News |
| `Ctrl/Cmd + 4` | Go to Templates |
| `Ctrl/Cmd + N` | New Project |
| `Ctrl/Cmd + ,` | Open Settings |
| `Ctrl/Cmd + P` | Toggle Command Palette |
| `Escape` | Close overlay / Clear selection |

> The command palette keybind can be customized in Settings.

---

## 📚 Wiki

The [project wiki](https://github.com/RykoTheDev/godothub/wiki) covers GodotHub in more depth than this README, split into a few pages:

| Page | What it covers |
|---|---|
| [Getting Started](https://github.com/RykoTheDev/godothub/wiki/Getting-Started) | Installation, the first-run setup wizard, and what to do after |
| [Keyboard Shortcuts](https://github.com/RykoTheDev/godothub/wiki/Keyboard-Shortcuts) | Every global shortcut, plus how lists, menus, and forms behave on the keyboard |
| [Settings Reference](https://github.com/RykoTheDev/godothub/wiki/Settings-Reference) | What every setting does, grouped by category |
| [Custom CSS in the New UI](https://github.com/RykoTheDev/godothub/wiki/Custom-CSS-in-the-New-UI) | Restyle the new interface with your own CSS |
| [FAQ / Troubleshooting](https://github.com/RykoTheDev/godothub/wiki/FAQ-Troubleshooting) | Answers to common questions and fixes for common problems |

---

## 🧰 Tech Stack

<details>
<summary><strong>View full tech stack</strong></summary>

| Layer | Technology |
|---|---|
| **Frontend Framework** | [React 19](https://react.dev) + [TypeScript](https://www.typescriptlang.org/) |
| **Styling** | [Tailwind CSS 4](https://tailwindcss.com) |
| **Animations** | [Framer Motion](https://www.framer.com/motion/) |
| **Drag & Drop** | [@dnd-kit](https://dndkit.com/) |
| **Desktop Framework** | [Tauri 2](https://v2.tauri.app/) (Rust) |
| **Icons** | [Font Awesome Free](https://fontawesome.com) via [react-fontawesome](https://github.com/FortAwesome/react-fontawesome) |
| **HTTP Client** | [reqwest](https://docs.rs/reqwest/) (Rust) |
| **File Watchers** | [notify](https://docs.rs/notify/) (Rust) |
| **RSS Parsing** | [feed-rs](https://docs.rs/feed-rs/) (Rust) |
| **Build Tool** | [Vite](https://vitejs.dev) + [Bun](https://bun.sh) |

</details>

---

## 📁 Project Structure

<details>
<summary><strong>Click to expand the full directory tree</strong></summary>

```
godothub/
├── assets/                         # Screenshots & media
├── src/                            # Frontend (React + TypeScript)
│   ├── main.tsx                    # Entry point
│   ├── types.ts                    # TypeScript type definitions
│   ├── index.css                   # Global styles (Tailwind)
│   ├── api/                        # Tauri command bindings
│   ├── hooks/                      # Custom React hooks & contexts
│   ├── lib/                        # Utility libraries & shared helpers
│   ├── i18n/                       # Localization (en-US, zh-CN, ja-JP, es-MX, ru-RU, ar-MA)
│   └── interface/                  # All UI code
│       ├── App.tsx                 # Main app shell + root component
│       ├── index.ts                # Public exports
│       ├── style.css               # Design tokens
│       ├── components/
│       │   ├── cards/              # Card components (ProjectCard, InstalledVersionCard)
│       │   ├── git/                # Git sidebar, diff viewer, result dialog
│       │   ├── modals/             # Modal dialogs
│       │   ├── reusables/          # App-level reuse (Tooltip, ScanButton, ViewHeader, SplashScreen…)
│       │   ├── titlebar/           # Titlebar, TaskTray, RunningProjectsChip
│       │   ├── ui/                 # Form controls & primitives (Checkbox, Dropdown, Slider…)
│       │   └── …                   # DirList, OverlayScrollArea, Sidebar, etc.
│       ├── hooks/                  # UI-only React hooks
│       ├── lib/                    # UI helpers (duration, icons, toast)
│       ├── views/                  # Main application views
│       └── onboarding/             # First-run setup wizard
│   └── …
├── src-tauri/                      # Backend (Rust)
│   ├── src/
│   │   ├── main.rs                 # Application entry point
│   │   ├── lib.rs                  # Tauri setup, commands, tray menu
│   │   ├── models.rs               # Data models (serde)
│   │   ├── projects.rs             # Project CRUD, launch, icon resolution
│   │   ├── godot_versions.rs       # Version download, install, manage
│   │   ├── godotenv.rs             # Godot version detection & pinning (.godotrc, global.json)
│   │   ├── git.rs                  # Git operations
│   │   ├── settings.rs             # Settings persistence
│   │   ├── templates.rs            # Template management
│   │   ├── categories.rs           # Category CRUD
│   │   ├── changelog.rs            # Changelog CRUD
│   │   ├── workspace.rs            # Workspace management
│   │   ├── news.rs                 # RSS news fetching
│   │   ├── scan.rs                 # File system scanning
│   │   ├── watcher.rs              # File system watchers
│   │   ├── asset_library.rs        # Asset library fetching
│   │   ├── time_stats.rs           # Project time tracking
│   │   ├── tray.rs                 # System tray menu
│   │   └── …                       # error, git_helpers, persist, terminal, etc.
│   ├── Cargo.toml                  # Rust dependencies
│   └── tauri.conf.json             # Tauri configuration
│
├── package.json                    # Frontend dependencies
├── vite.config.ts                  # Vite configuration
├── tsconfig.json                   # TypeScript configuration
└── README.md                       # This file
```

</details>

---

## 🌍 Languages
In beta phase (languages other than english might be incomplete)

| Languages | Status          |
| ------- | ------------------ |
| English   | Completed |
| Chinese   | Beta               |
| Russian   | Incomplete               |
| Arabic    | Incomplete               |

---

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

| Project | Why We're Grateful |
|---|---|
| [Godot Engine](https://godotengine.org) | The amazing open-source game engine this tool is built for. |
| [Tauri](https://v2.tauri.app) | The framework that makes cross-platform desktop apps with web technologies possible. |
| [React](https://react.dev) | The UI library we use for the frontend. |
| [Tailwind CSS](https://tailwindcss.com) | The utility-first CSS framework for styling. |
| [Font Awesome](https://fontawesome.com) | The icon library we use throughout the app. |

And every other open-source library that makes GodotHub possible, see `package.json` and `Cargo.toml` for the full list.

---

---

## ⭐ Star History

<a href="https://www.star-history.com/?repos=RykoTheDev%2FGodotHub&type=timeline&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=RykoTheDev/GodotHub&type=timeline&theme=dark&legend=bottom-right&sealed_token=K0A_747qaDoioaDadvVke_xGw9V06vKC9raC8-6f9w3TolZ6o6E7nqnGAy1Syr-d2Au51bDwvMnagX21RPuTdf2AIKNUoToc8ijpaPEM5LMwTX3RQCznVM4K5g-S11xLT4rrCZYSk2AXLSeK2yyBxOijNAXYmFSJOW5jk0kEDqBFcDWTrIOnAWoGMWbP" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=RykoTheDev/GodotHub&type=timeline&legend=bottom-right&sealed_token=K0A_747qaDoioaDadvVke_xGw9V06vKC9raC8-6f9w3TolZ6o6E7nqnGAy1Syr-d2Au51bDwvMnagX21RPuTdf2AIKNUoToc8ijpaPEM5LMwTX3RQCznVM4K5g-S11xLT4rrCZYSk2AXLSeK2yyBxOijNAXYmFSJOW5jk0kEDqBFcDWTrIOnAWoGMWbP" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=RykoTheDev/GodotHub&type=timeline&legend=bottom-right&sealed_token=K0A_747qaDoioaDadvVke_xGw9V06vKC9raC8-6f9w3TolZ6o6E7nqnGAy1Syr-d2Au51bDwvMnagX21RPuTdf2AIKNUoToc8ijpaPEM5LMwTX3RQCznVM4K5g-S11xLT4rrCZYSk2AXLSeK2yyBxOijNAXYmFSJOW5jk0kEDqBFcDWTrIOnAWoGMWbP" />
 </picture>
</a>

---

<p align="center">Made with ❤️ by <a href="https://github.com/RykoTheDev">RykoTheDev</a></p>

<p align="center">
  <a href="https://github.com/RykoTheDev/godothub/releases/latest">⬇️ Download GodotHub</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/RykoTheDev/godothub/issues">🐛 Report a Bug</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/RykoTheDev/godothub/discussions">💬 Discussions</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/RykoTheDev/godothub/wiki">📚 Wiki</a>
</p>
