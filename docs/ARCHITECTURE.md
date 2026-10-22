# Architecture

GodotHub is a desktop app for managing Godot Engine versions and projects. It is
built with [Tauri](https://tauri.app): a Rust backend owns the filesystem,
processes, Git, and network access, and a React + TypeScript frontend renders the
UI inside a system webview. The two halves talk over Tauri's IPC.

```
+--------------------------------------------------------------+
|  Webview (React + TypeScript)        src/                    |
|  views, components, hooks, i18n                              |
|            |  api.* -> invoke('command', args)              |
|            |  <- app.emit('event', payload)                 |
+------------|-------------------------------------------------+
             v
+--------------------------------------------------------------+
|  Rust backend (Tauri)                src-tauri/src/          |
|  #[tauri::command] handlers, background threads, plugins     |
|            |                                                 |
|            v                                                 |
|  Filesystem (JSON stores + Godot installs), Git, processes,  |
|  GitHub / Godot web APIs                                     |
+--------------------------------------------------------------+
```

## Frontend (`src/`)

| Area | Path | Responsibility |
| --- | --- | --- |
| App shell | `main.tsx`, `App.tsx` | Mounts context providers, routes between views (lazy-loaded), hosts the git sidebar and project console overlays. |
| Views | `views/` | One screen per tab: `ProjectsView`, `DashboardView`, `VersionsView`, `TemplatesView`, `AssetStoreView`, `NewsView`, `ChangelogView`, `SettingsView`, and `OnboardingView`. |
| Project cards | `components/cards/` | `ProjectCard` and its grid / list / kanban layouts. |
| Git UI | `components/git/` | `GitSidebar` and its panels (status, branches, stashes, worktrees). |
| Console | `components/console/` | The in-app console window for running projects. |
| Other UI | `components/{modals,titlebar,ui,reusables,asset-library,dnd}/` | Dialogs, the custom titlebar, primitives, and drag-and-drop. |
| State | `hooks/` | Context providers (`settings`, `projects`, `godotVersions`, `categories`, `workspaces`) and data hooks (`useProjects`, `useNews`, `useGodotVersions`, `useNow`, ...). |
| Platform bridge | `lib/api.ts`, `api/` | Typed wrappers around `invoke(...)`, grouped by domain (`projects`, `versions`, `git`, `settings`, `assetLibrary`, ...). All backend calls go through here. |
| i18n | `i18n/` | Locale files under `i18n/locales/<lang>/` plus generated key types in `i18n/types.ts`. |
| Shared types | `types.ts` | TypeScript mirrors of the Rust structs that cross the IPC boundary. |

Conventions: function components with hooks, shared logic in `lib/` or `hooks/`,
and all IPC funnelled through `lib/api.ts` so a command is defined in exactly one
place on each side.

## Backend (`src-tauri/src/`)

Grouped by responsibility; each file is a module registered from `lib.rs`.

**Entry and wiring**

- `main.rs` / `lib.rs` - Tauri builder setup, command registration
  (`invoke_handler`), window and tray events, plugin wiring.
- `cli.rs`, `cli_shim.rs` - the optional `godothub` command-line interface.
- `install_mode.rs`, `licenses.rs` - portable-install detection and license info.

**Data model and persistence**

- `models.rs` - the structs shared with the frontend.
- `persist.rs` - the storage layer: atomic writes, `.bak` recovery, corruption
  reporting, a serialized read-modify-write to prevent lost updates, and a
  `schema_version` migration framework.
- `error.rs` - the `AppError` / `AppResult` types.
- `settings.rs`, `workspace.rs` - app settings and the per-workspace data dirs.
- `backup.rs`, `sync.rs` - local backups and Gist-based settings sync.
- `categories.rs`, `project_todos.rs`, `changelog.rs`, `news.rs`,
  `time_stats.rs` - the smaller JSON-backed stores.

**Projects**

- `projects.rs` - the project registry, launching Godot, and session time
  tracking.
- `project_health.rs` - the "Project Doctor" checks and fixes.
- `project_identity.rs`, `project_metadata.rs` - reading `project.godot`.
- `discovery.rs`, `scan.rs`, `watcher.rs`, `resolve.rs`, `current_version.rs` -
  finding projects on disk, filesystem watching, and version resolution.

**Godot versions and exports**

- `godot_versions.rs` - listing, downloading (resumable, checksum-verified),
  installing, and registering engine versions.
- `export_templates.rs`, `export_template_archive.rs` - the matching export
  template packages.
- `export_runner.rs` - headless builds and exports.
- `mise.rs`, `godotenv.rs` - integration with `mise` and env detection.

**Assets and templates**

- `asset_library.rs` - the Godot Asset Library / Store, including safe archive
  extraction.
- `templates.rs`, `template_files.rs` - user project templates.

**Git**

- `git.rs` - status, commit, branch, stash, and worktree operations.
- `git_auth.rs` - GitHub device-flow and personal-access-token auth.
- `git_helpers.rs` - shared `git` command plumbing.

**Processes, console, and tray**

- `process.rs` - detecting running Godot processes.
- `console.rs`, `terminal.rs` - the in-app console and opening an external
  terminal.
- `tray.rs` - the system tray menu.

## Cross-cutting concerns

**IPC.** The frontend calls `api.<domain>.<method>()`, which calls
`invoke('<command>', args)`. Each command is a `#[tauri::command]` function
registered in `lib.rs`. For push updates the backend calls `app.emit('<event>',
payload)` and the frontend listens with `useTauriEvent` or a window event. Command
arguments are camelCase on the JS side and snake_case in Rust; Tauri converts
between them.

**Persistence.** State lives as JSON files under the active workspace's data dir
(`projects.json`, `settings.json`, `time_tracking.json`, and the smaller stores).
Everything goes through `persist.rs`, which writes atomically, keeps a `.bak`
copy, carries a `schema_version`, and serializes concurrent writes.

**Updates.** The Tauri updater plugin checks
`github.com/RykoTheDev/godothub/releases/latest/download/latest.json` on startup
and applies signed updates. See [RELEASING.md](RELEASING.md) for how release
artifacts are signed.
