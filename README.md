<p align="center">
  <a href="https://ryko.is-a.dev/godothub">
    <img width="800" height="340" alt="cover" src="https://github.com/user-attachments/assets/29ea1efa-e977-4417-9da6-69c81104fc97" />
  </a>
</p>
<p align="center">
  <img width="800" height="210" alt="warning-cover" src="https://github.com/user-attachments/assets/cc3c0d68-57a3-4ab6-b025-61f5b0bcef61" />
</p>
<p align="center">
  <a href="https://patreon.com/TheRyko">
  <img width="300" height="70" alt="patreon-badge" src="https://github.com/user-attachments/assets/931aa0ac-f46b-4155-81cd-3615ed55122b" />
  </a>
</p>

## Screenshots

<table>
  <tr>
    <td width="50%" align="center">
      <img src="assets/dashboard-view.png" alt="Dashboard View" width="400">
      <br><strong>Dashboard</strong>
    </td>
    <td width="50%" align="center">
      <img src="assets/projects-view.png" alt="Projects View" width="400">
      <br><strong>Projects</strong>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="assets/versions-view.png" alt="Versions View" width="400">
      <br><strong>Versions</strong>
    </td>
    <td width="50%" align="center">
      <img src="assets/templates-view.png" alt="Templates View" width="400">
      <br><strong>Templates</strong>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="assets/asset-store-view.png" alt="Asset Store View" width="400">
      <br><strong>Asset Store</strong>
    </td>
    <td width="50%" align="center">
      <img src="assets/git-view.png" alt="Git Integration" width="400">
      <br><strong>Git Integration</strong>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="assets/settings-view.png" alt="Settings & Appearance" width="400">
      <br><strong>Appearance & Settings</strong>
    </td>
    <td width="50%" align="center">
      <img src="assets/news-view.png" alt="News Feed" width="400">
      <br><strong>News Feed</strong>
    </td>
  </tr>
</table>

<p align="center"><sub>Screenshots show the dark theme with the default accent color. Everything shown is customizable.</sub></p>

---

<p align="center">
  <a href="https://discord.com/invite/nA7dus32Yv/">
    <img src="/assets/discord-banner.png" alt="Discord">
  </a>
  &nbsp;
  <a href="https://x.com/theRyko11">
    <img src="/assets/twitter-banner.png" alt="Twitter">
  </a>
</p>

---

## Features

### Project Management

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Create & Import** | Create new projects from scratch or from templates, import existing ones from disk, or clone directly from a Git repo. |
| **Drag & Drop Reorder** | Rearrange projects with drag-and-drop, within a category or between categories. |
| **Pin Projects** | Pin projects to a dedicated section at the top. |
| **Tags** | Tags are read straight from `project.godot`, so they stay in sync with the Godot launcher. Edit, add, or delete them and the sync follows. |
| **Batch Operations** | Select multiple projects at once to change versions, assign categories, toggle pins, or remove from the library. |
| **Search & Filter** | Search by name or path, filter by category, sort by custom order, name, date, last opened, or size. |
| **Version Warnings** | Flags when a project's bound Godot version is missing or there's a major version mismatch. |
| **Project Properties** | A file breakdown by type (scripts, scenes, images, audio, 3D models, etc.) with sizes and counts. |
| **Custom Launch Args** | Add custom command-line arguments when launching a project. |
| **Quick Actions** | Open the project folder, open in an external editor, or open a terminal at the project path, all from the project card. |

</details>

### Godot Version Management

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Browse Releases** | Pulls the full list of official Godot builds from GitHub, filtered for your platform. |
| **Download & Install** | Progress tracking, resume support, and concurrent downloads (configurable up to 10 at once). |
| **Import Versions** | Import an existing Godot install from any folder, or drag-and-drop a `.zip`. |
| **Grouped Display** | Versions grouped by `major.minor` with collapsible sections. |
| **Filtering** | Filter by build type (Standard / Mono / Both) and channel (Stable / Unstable / Both). |
| **Custom Names** | Give installed versions your own names. |
| **Auto-Cleanup** | Prunes missing executables from the registry automatically. |

</details>

### Templates

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Save as Template** | Turn any existing project into a reusable template. |
| **Create from Template** | Start new projects pre-populated with a template's content. |
| **Preview Contents** | Browse a template's full directory tree before using it. |
| **Sync from Directory** | Auto-import templates from a configured scan folder. |
| **File Watcher** | The template directory is watched, so editing a template folder updates the library automatically. |

</details>

### Git Integration

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Status Overview** | Branch name, uncommitted changes, and repo status at a glance. |
| **Stage / Unstage** | Individual files or everything at once. |
| **Commit** | Commit messages with optional amend. |
| **Push / Pull / Fetch** | Sync with remotes. |
| **Branch Management** | List, switch, create, and delete branches. |
| **Stash** | Push, list, apply, and drop stashes. |
| **Diff Viewer** | Inline diff viewer with syntax-colored additions and deletions. |
| **Discard Changes** | Discard all uncommitted changes, with confirmation. |
| **Init & Remote** | Initialize a repo, set or remove remotes. |
| **Undo** | Undo the last commit, or undo a pull. |
| **Auto-Refresh** | Git status polls every 30 seconds. |

</details>

### Workspaces

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Multiple Workspaces** | Separate workspaces for different projects, clients, or game jams. |
| **Custom Icons & Colors** | Each workspace gets its own icon and color. |
| **Quick Switch** | Switch workspaces from the sidebar dropdown. |

</details>

### Categories

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Create & Customize** | Custom names and colors from a rich palette. |
| **Collapsible Sections** | Collapse and expand category sections. |
| **Drag Between Categories** | Drag projects between categories (`@dnd-kit`-powered). |
| **Filter by Category** | Filter the project list by any category. |
| **Enable / Disable** | Turn categories on or off globally from Settings. |

</details>

### News Feed

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **RSS Feed** | Godot-related news and updates. |
| **Cached** | Feed data is cached for performance. |
| **Open in Browser** | Click a news item to open the full article. |

</details>

### Appearance & Customization

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Dark / Light Mode** | Switch between dark and light themes. |
| **Accent Color** | 18 preset accent colors, or any custom hex color. |
| **Background Color** | Presets, or generate one at random. |
| **"Feeling Lucky"** | Randomly generate a whole color scheme in one click. |
| **Corner Radius** | 0 (sharp) to 20px (rounded), applied everywhere. |
| **UI Density** | Scale padding and spacing from 75% (compact) to 125% (spacious). |
| **Font Scale** | Scale all text from 85% to 130%. |
| **Reduce Motion** | Minimize animations for accessibility. |
| **Sidebar Width** | Set expanded and collapsed widths independently. |

</details>

### Settings & Preferences

<details>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Storage Locations** | Configure scan directories for projects, Godot versions, and templates. |
| **Auto-Scan on Startup** | Discover new projects and versions automatically on launch. |
| **File Watchers** | Real-time detection of changes in project, version, and template directories. |
| **Download Concurrency** | How many Godot versions download at once (1-10). |
| **Scan Depth** | How deep to scan folders (1-10 levels). |
| **Close on Launch** | Quit or minimize to tray when launching a project. |
| **Reopen After Godot Closes** | Restore GodotHub automatically when the editor closes. |
| **Tray Menu** | Recent projects in the system tray context menu (configurable count). |
| **Tooltip Delay** | 100ms to 1000ms. |
| **Command Palette Keybind** | Rebind `Ctrl/Cmd + <key>` to whatever you want. |
| **Export / Import** | Back up or transfer all settings as JSON. |
| **Reset & Wipe** | Reset settings to defaults, or wipe all app data. |

</details>

### Other Bits

<details open>
<summary><strong>Details</strong></summary>

| Feature | Description |
|---|---|
| **Drag & Drop Import** | Drag project folders or `.zip` version archives straight into the app window. |
| **Command Palette** | `Ctrl/Cmd + P` (or your own keybind) for quick navigation. |
| **System Tray** | Minimize to tray with a right-click menu of recently opened projects. |
| **Custom Titlebar** | Frameless window, custom title bar. |
| **Splash Screen** | An animated splash screen on startup. |
| **Onboarding Wizard** | Guided first-time setup for scan folders, categories, and appearance. |
| **Auto-Updates** | Checks for updates on startup, downloads them via the Tauri updater. |
| **Bug Reporting** | Report issues directly from the app. |
| **Changelog Viewer** | See what changed in each release. |
| **Keyboard Shortcuts** | Full shortcut cheatsheet, available anytime. |

</details>

---

## AI Disclosure

Some parts of this codebase have been restructured and had small bugs fixed with the help of [DeepSeek AI](https://chat.deepseek.com/). I review and test every change myself before merging anything. The whole codebase was written by a freshly baked human from scratch.

For anyone who doesn't read commits: Copilot is **not** used here. It accidentally got added to the collaborators list after fixing a PR that literally just removed a space. I've since disabled it, and it has no authority over this repo, including reviews.
As for Codebuff AI, I never even had a subscription to it. I was just testing it out before realizing that, and it somehow snuck into a commit message.

Contributors can use AI during development, but every PR is manually reviewed before I merge it. I use AI myself for assistance, but I'm strictly against "vibe-coding" and don't allow unchecked AI output. I can't speak for how contributors use AI, nor am I responsible for it, as long as the PR does its job correctly.

---

## Installation

### Download Prebuilt Binaries

GodotHub is available as a desktop app for:

| Platform | Package Types |
|---|---|
| **Windows** | `.msi` or `.exe` installer |
| **macOS** | `.dmg` or `.app` bundle |
| **Linux** | `.deb`, `.AppImage`, or `.rpm` |

### Install via Winget (Windows)

GodotHub is on the **Windows Package Manager (winget)**. On Windows 10/11:

> [!NOTE]
> Winget can lag behind the latest release. Maintainers don't always merge updates right away.

```powershell
winget install Ryko.GodotHub
```

To update:

```powershell
winget upgrade Ryko.GodotHub
```

### Install via Scoop (Windows)

```powershell
scoop bucket add extras
scoop install godothub
```

To update:

```powershell
scoop update godothub
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
> The built app ends up in `src-tauri/target/release/bundle/`.

---

## Tech Stack

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

## License

MIT, see [LICENSE](LICENSE) for details.

---

## Acknowledgements

| Project | Why |
|---|---|
| [Godot Engine](https://godotengine.org) | The open-source engine this whole tool is built around. |
| [Tauri](https://v2.tauri.app) | Makes cross-platform desktop apps with web tech possible. |
| [React](https://react.dev) | The UI library the frontend is built on. |
| [Tailwind CSS](https://tailwindcss.com) | Utility-first CSS framework for styling. |
| [Font Awesome](https://fontawesome.com) | Icons used throughout the app. |

Plus every other open-source library that makes GodotHub possible, see `package.json` and `Cargo.toml` for the full list.

---

## Star History

<a href="https://www.star-history.com/?repos=RykoTheDev%2FGodotHub&type=timeline&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=RykoTheDev/GodotHub&type=timeline&theme=dark&legend=bottom-right&sealed_token=K0A_747qaDoioaDadvVke_xGw9V06vKC9raC8-6f9w3TolZ6o6E7nqnGAy1Syr-d2Au51bDwvMnagX21RPuTdf2AIKNUoToc8ijpaPEM5LMwTX3RQCznVM4K5g-S11xLT4rrCZYSk2AXLSeK2yyBxOijNAXYmFSJOW5jk0kEDqBFcDWTrIOnAWoGMWbP" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=RykoTheDev/GodotHub&type=timeline&legend=bottom-right&sealed_token=K0A_747qaDoioaDadvVke_xGw9V06vKC9raC8-6f9w3TolZ6o6E7nqnGAy1Syr-d2Au51bDwvMnagX21RPuTdf2AIKNUoToc8ijpaPEM5LMwTX3RQCznVM4K5g-S11xLT4rrCZYSk2AXLSeK2yyBxOijNAXYmFSJOW5jk0kEDqBFcDWTrIOnAWoGMWbP" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=RykoTheDev/GodotHub&type=timeline&legend=bottom-right&sealed_token=K0A_747qaDoioaDadvVke_xGw9V06vKC9raC8-6f9w3TolZ6o6E7nqnGAy1Syr-d2Au51bDwvMnagX21RPuTdf2AIKNUoToc8ijpaPEM5LMwTX3RQCznVM4K5g-S11xLT4rrCZYSk2AXLSeK2yyBxOijNAXYmFSJOW5jk0kEDqBFcDWTrIOnAWoGMWbP" />
 </picture>
</a>
