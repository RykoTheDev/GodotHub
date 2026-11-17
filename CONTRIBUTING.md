# Contributing to GodotHub

First off, thank you for wanting to contribute! 🎉 GodotHub is a community-driven
project, and every issue filed, translation added, bug fixed, or feature built
makes it better for everyone.

This guide covers everything you need to know: setting up a dev environment for
the Flutter app, finding something to work on, code and UI conventions, and in
depth, how **localization** works and how to add or improve a language.

> [!NOTE]
> GodotHub is now a **Flutter + Rust** desktop app. The Flutter app lives in
> `app/` and talks to the shared Rust core in `crates/`. The old React + Tauri
> app in `src/` and `src-tauri/` is legacy: it still builds the last Tauri
> releases, but new features and fixes go into the Flutter app. The one part of
> `src/` everyone still uses is `src/i18n/locales/`, the translation source.

---

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Ways to Contribute](#-ways-to-contribute)
- [AI Usage Policy](#-ai-usage-policy)
- [Setting Up a Dev Environment](#️-setting-up-a-dev-environment)
- [Running the App](#️-running-the-app)
- [Project Structure](#-project-structure)
- [Development Workflow](#-development-workflow)
- [Code Conventions](#-code-conventions)
- [UI Conventions and Shared Components](#-ui-conventions-and-shared-components)
- [Localization](#-localization)
- [Testing & CI](#-testing--ci)
- [Release Process](#-release-process)
- [Legacy Tauri App](#-legacy-tauri-app)
- [Getting Help](#-getting-help)

---

## 🤝 Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md). Be kind,
be patient, and assume good intent. This project is made by people from all
over the world.

---

## 💡 Ways to Contribute

You don't have to write code to help:

| Contribution | What it involves |
|---|---|
| **Report a bug** | Open an issue with steps to reproduce, expected vs. actual behavior, and your OS + app version. The in-app bug report fills in most of that for you. |
| **Request a feature** | Open an issue describing *what* you want and *why*. Screenshots/mockups help a lot. |
| **Translate** | Add or improve a language by editing the JSON files in `src/i18n/locales/`. No coding, Flutter or Dart knowledge is needed. See the [Localization section](#-localization). |
| **Test** | The app is only heavily tested on Windows, Arch Linux (Hyprland), Fedora (Gnome) 43, and recent macOS. Try a build on your setup and report what breaks. |
| **Write docs** | Improve the README, this file, or the [docs site](https://ryko.is-a.dev/godothub-docs). |
| **Fix a bug / build a feature** | The traditional path, see below. |

### Finding something to work on

- Look through the [issues](https://github.com/RykoTheDev/GodotHub/issues) for
  `good first issue` labels.
- If you want to take on an issue, **comment on it first** so nobody else
  starts the same work. Maintainers will happily assign it to you.
- **Open an issue before starting large changes**. A quick "I'd like to
  refactor X / add Y" saves everyone from a PR that goes in a direction the
  project doesn't want.

---

## 🤖 AI Usage Policy

Contributors are permitted to use AI-assisted development tools (such as Copilot, Deepseek, ChatGPT, Claude) to help write code. However, all AI-generated contributions must meet the same quality standards as human-written code.

### Guidelines

**Do's ✅**

- Use AI as a productivity aid for boilerplate, refactoring suggestions, or
  debugging assistance.
- Review and understand every line of AI-generated code before submitting it.
- Test AI-generated code thoroughly, just as you would with your own work.
- Mention in your PR description if you used AI assistance (helps reviewers
  understand the context).

**Don'ts ❌**

- **Do not submit AI-generated code without thorough review.** We do not accept
  "vibe-coded" PRs code that is submitted without the contributor understanding
  what it does or verifying it works.
- Do not rely on AI to write critical logic that you don't understand.
- Do not use AI to generate translations for localization files if you don't know they are correct or not (see
  [Localization](#-localization) for the correct workflow).
- Do not commit/push via AI Agent (or have it Co-Authored) like Claude Code or GitHub Copilot. Push it manually or your PR will be instantly closed without any explaination. (We already have fake calls with Copilot and Codebuff in our Collab. List, I don't want a new one)

### Why this policy exists

AI tools are powerful, but they can introduce subtle bugs, security issues, or
code that doesn't align with the project's style and architecture. By requiring
human review and understanding, we ensure that:

- Every line of code has a purpose and is understood by someone.
- The project remains maintainable and consistent over time.
- Contributors grow their skills rather than outsourcing them.

If you're unsure whether your use of AI is acceptable, open an issue or ask in
your PR I'm happy to discuss it.

---

## 🛠️ Setting Up a Dev Environment

### Prerequisites

| Tool | Why | Notes |
|---|---|---|
| **Flutter (stable)** | App framework and Dart SDK | CI uses Flutter 3.50.0. Install from [docs.flutter.dev](https://docs.flutter.dev/get-started/install) and run `flutter doctor`. |
| **Rust (stable)** | Shared core (`crates/`) and the Flutter bridge | CI uses Rust 1.99.1. Install via [rustup](https://rustup.rs). |
| **Desktop toolchain** | Native build of the Flutter desktop shell | **Windows:** Visual Studio with *Desktop development with C++*. **macOS:** Xcode and its command-line tools. **Linux:** `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libx11-dev`, `libxi-dev`, `liblzma-dev`. |
| **Git** | Version control | Also required by the app's Git features. |
| **Node.js 20+ / Bun** *(optional)* | Legacy i18n helper scripts (`bun run i18n:*`) and the legacy Tauri app | Not needed to build or run the Flutter app. |
| **flutter_rust_bridge_codegen 2.13** *(only when changing the bridge API)* | Regenerates the Dart/Rust bindings | `cargo install flutter_rust_bridge_codegen --version 2.13.0` |

### 1. Clone & install

```bash
git clone https://github.com/RykoTheDev/GodotHub.git
cd GodotHub/app
flutter pub get
```

If you use Bun, `bun install` at the repository root also points git at the
repo's hooks (see [Git hooks](#git-hooks)).

### 2. Verify the toolchain

```bash
cd app
flutter analyze                                    # Dart static analysis
flutter test                                       # Widget and unit tests
cd ..
cargo test -p godothub_core -p godothub_bridge     # Rust core and bridge tests
```

All three should pass before you start. The first Rust build is slow.

---

## ▶️ Running the App

### Dev mode

```bash
cd app
flutter run -d windows   # or: -d macos, -d linux
```

The Rust core and the bridge are compiled automatically as part of the Flutter
build (`app/rust_builder`). Press `r` for hot reload and `R` for hot restart.
Changes to Rust code need a full restart (`q`, then `flutter run` again).

### Building a release

```bash
cd app
flutter build windows --release   # or macos / linux
```

Build outputs land under `app/build/`. Installers and update packages are made
by the release workflows (see [Release Process](#-release-process)), not by
hand.

### Useful commands

| Command (from `app/`) | Purpose |
|---|---|
| `flutter run -d <platform>` | Run the app in debug mode |
| `flutter analyze` | Static analysis (must be clean) |
| `flutter test` | All widget and unit tests |
| `flutter test test/projects` | Tests for one area |
| `dart format -l 140 <files>` | Format the files you touched (the repo uses 140 columns) |
| `dart run ../dev/tool/i18n_convert.dart && dart run slang` | Regenerate Flutter translations from `src/i18n/locales` |
| `dart run ../dev/tool/i18n/check_keys.dart --check-values` | Locale completeness report |
| `flutter_rust_bridge_codegen generate` | Regenerate the bridge after changing `crates/godothub-bridge/src/api` |

| Command (from the repo root) | Purpose |
|---|---|
| `cargo test -p godothub_core -p godothub_bridge` | Rust tests |
| `cargo check --workspace` | Type-check every crate, including the legacy Tauri one |
| `cargo fmt` | Format Rust code |

---

## 📁 Project Structure

```
godothub/
├── app/                              # The Flutter desktop app
│   ├── lib/
│   │   ├── main.dart                 # Entry point
│   │   ├── shell/                    # App shell: sidebar, routing, overlays
│   │   ├── projects/                 # Projects view, cards, list/grid/Kanban layouts
│   │   ├── versions/                 # Godot versions, downloads, export templates
│   │   ├── templates/                # Local templates and the Asset Library templates
│   │   ├── assets/                   # Asset Store and Asset Library browsers and cards
│   │   ├── vault/                    # The workspace vault
│   │   ├── news/ changelog/          # News feed, in-app changelog
│   │   ├── dashboard/ storage/       # Dashboard and storage views
│   │   ├── git/                      # Git sidebar, worktrees, diffs
│   │   ├── todos/                    # Project Next Steps (todos)
│   │   ├── settings/                 # Settings view and its categories
│   │   ├── onboarding/               # First-run setup
│   │   ├── modals/                   # Every dialog (create project, doctor, build...)
│   │   ├── titlebar/ window/ console/ discord/
│   │   ├── ui/                       # Shared widgets (see UI Conventions)
│   │   │   ├── core/                 #   Buttons, interaction, tooltips, i18n helpers
│   │   │   ├── controls/             #   Text input, toggle, slider, checkbox...
│   │   │   ├── reusables/            #   Cards, grids, form fields, path field, states...
│   │   │   ├── feedback/             #   Modal shell, toasts, confirm dialog, errors
│   │   │   ├── overlays/             #   Menus, dropdowns, context menu, date picker
│   │   │   └── shell/ dnd/ splash/
│   │   ├── design/                   # Design tokens (GhTheme), palette, typography, icons
│   │   ├── motion/                   # Animation primitives that respect Reduce Motion
│   │   ├── state/                    # Riverpod providers and notifiers
│   │   ├── logic/                    # Pure helpers (sorting, search, formatting)
│   │   ├── api/                      # Thin Dart wrappers over the Rust bridge
│   │   ├── i18n/                     # Generated translations (do not edit by hand)
│   │   └── src/rust/                 # Generated bridge bindings (do not edit by hand)
│   ├── test/                         # Widget and unit tests, mirroring lib/
│   ├── integration_test/             # End-to-end tests
│   ├── packaging/                    # Installers, release notes, kill switch
│   └── windows/ macos/ linux/        # Native desktop runners
├── crates/
│   ├── godothub-core/                # All app logic in Rust: projects, versions, git,
│   │                                 #   templates, asset library, settings, persistence
│   ├── godothub-bridge/              # flutter_rust_bridge API exposed to Dart
│   └── godothub-launcher/            # Windows launcher that starts and rolls back updates
├── src/i18n/locales/                 # Translation source of truth (JSON per locale)
├── src/, src-tauri/                  # Legacy React + Tauri app
├── dev/                              # Everything for developers, nothing that ships
│   ├── tool/                         # Local CI, i18n conversion and checks, generators,
│   │                                 #   benchmarks, update labs and sandboxes
│   ├── scripts/                      # Legacy i18n helper scripts (Node)
│   ├── docs/                         # Bridge release runbook, environment checks
│   └── fixtures/                     # Old-version data used by the Rust tests
├── docs/migration/FAQ.md             # User FAQ (linked from release notes, keep the path)
├── .githooks/                        # pre-commit & commit-msg hooks
└── .github/workflows/                # Flutter CI, release and packaging pipelines
```

Logic that touches the disk, the network or other processes belongs in
`crates/godothub-core`; the bridge exposes it, `app/lib/api` wraps it, and
`app/lib/state` turns it into Riverpod state for the UI.

---

## 🧑‍💻 Development Workflow

### Branch & PR basics

1. Create a branch:
   ```bash
   git checkout -b fix/your-descriptive-name
   # or: feat/…, refactor/…, docs/…
   ```
2. Make your changes. Keep commits small and focused.
3. Run the checks below. **CI runs them too**, so passing locally is expected
   before opening a PR.
4. Push and open a pull request. Reference the issue number in the PR
   description (`Closes #123`) and say which OS you tested on.

### Checks that must pass

```bash
cd app
flutter analyze
flutter test
cd ..
cargo test -p godothub_core -p godothub_bridge
```

Flutter CI (`flutter-ci.yml`) runs these on every push and pull request, along
with the i18n checks and a release build on Windows, macOS and Linux, so don't
worry about platforms you can't test locally.

To run every step of the CI `checks` job before pushing, in the same order:

```bash
bash dev/tool/ci_local.sh           # Rust tests, notices, i18n checks, analyze, widget tests
bash dev/tool/ci_local.sh --fast    # the same without the Rust tests
bash dev/tool/ci_local.sh --linux   # inside WSL on a copy of the tree, like the Ubuntu runner
```

CI runs on Ubuntu, so a test that only passes on Windows (a `C:\` path, a `\`
separator) fails there. `--linux` catches that; it needs Flutter, Rust, Node and
rsync installed inside WSL. In PowerShell, `bash` is WSL's bash, so a run
started there always goes the `--linux` way; use Git Bash to check on Windows.
Keep the script in step with `flutter-ci.yml`.

### Changing the bridge

The Dart side only sees what `crates/godothub-bridge/src/api` exposes. After
adding or changing a function or a mirrored type there (for example a new field
on `Project` in `crates/godothub-core/src/models.rs` and its `#[frb(mirror)]`
in `crates/godothub-bridge/src/api/types.rs`):

```bash
cd app
flutter_rust_bridge_codegen generate
dart format -l 140 lib/src/rust
```

Commit the regenerated `app/lib/src/rust` and
`crates/godothub-bridge/src/frb_generated.rs` together with your change.

### ⚠️ The locale rule (important!)

> **When you add or change a user-facing string, write it in English only.**
>
> Add new keys to `src/i18n/locales/en-US/` and copy the English text into the
> same key in every other locale (`bun run i18n:sync -- --apply` does this), so
> translators can see what is new. Do **not** translate into other languages
> yourself: native speakers pick up the new keys afterwards. Mixing machine or
> half-correct translations into other locales creates a mess that's hard to
> clean up.

### Commit style

- Write clear, imperative commit messages: `Fix project icon not refreshing`,
  not `fix stuff`.
- One logical change per commit. If you touched formatting, keep it in its own
  commit so review diffs stay readable.
- Reference issues where relevant.
- No em-dashes (U+2014) in code, strings, docs or commit messages; the hooks
  reject them.

---

## 🎨 Code Conventions

### Dart / Flutter

- Follow the patterns already in the file you're editing (state shape, error
  handling, naming). Format with `dart format -l 140`.
- State lives in Riverpod providers under `lib/state/`. Widgets read the
  smallest piece they need with `ref.watch(provider.select(...))` when a
  provider changes often (download progress, for example).
- Read colors, spacing, radii and text styles from `GhTheme.of(context)`
  (`theme.space(n)`, `theme.radiusItem`, `theme.text(size:, weight:)`). Never
  hard-code a color or pixel value that a token covers: users can change the
  accent, corner radius, UI density and font scale.
- Animate through `lib/motion/` (`GhMotion.of(context)`) so **Reduce Motion**
  is respected. Prefer transform and opacity over layout animations.
- Every interactive element must work with the keyboard and have a semantic
  label. `GhPressable` gives you focus rings, hover and press states for free.
- Generated files (`lib/i18n/strings*.g.dart`, `lib/i18n/json`,
  `lib/src/rust`) are never edited by hand.

### Rust

- `cargo fmt` style (run `cargo fmt` before committing).
- Most core functions return `Result<_, String>`; `error.rs` defines
  `AppError` and `AppResult`, which some modules use. Match the file you are
  editing.
- Blocking work (git subprocesses, file IO) runs inside
  `tokio::task::spawn_blocking` so the UI never freezes.
- Read-modify-write on a registry file goes through its locked helper (for
  projects, `projects::update_projects`) so concurrent updates are not lost.
- **Never drop user data because something is unavailable right now.** A
  project on an unplugged drive or an offline network share stays in the
  library and is marked `missing`; only an explicit user action removes it.
  Code that writes into a project folder must not recreate a folder that is
  gone.
- Use `crate::http::client()` for network requests instead of building a new
  `reqwest::Client`, so connections are reused.
- Add `#[cfg(test)]` unit tests for non-trivial logic; CI runs them.

### Naming

- Dart: `lowerCamelCase` for variables and functions, `UpperCamelCase` for
  types and widgets, `snake_case.dart` file names. Shared widgets are
  prefixed `Gh` (`GhCard`, `GhPathField`).
- Rust: `snake_case` for functions/variables, `PascalCase` for types, files
  match the module they contain (`git_auth.rs`).
- Bridge functions are `snake_case` in Rust and appear as `lowerCamelCase` in
  the generated Dart (`list_projects` becomes `listProjects`).

---

## 🧩 UI Conventions and Shared Components

GodotHub's look comes from a small set of shared widgets. Use them instead of
building one-off versions, and if one doesn't fit, extend it rather than fork
it, so a fix in one place reaches every screen.

| Need | Use | Where |
|---|---|---|
| A labelled form field with hint, error and required/optional state | `GhLabelledField` + `GhFieldInput` | `ui/reusables/labelled_field.dart` |
| A path the user can type, paste or browse for | `GhPathField` (`ghPathError` for submit-time checks) | `ui/reusables/path_field.dart` |
| A content card (assets, templates, news, versions) | `GhCard`, `GhCardMedia`, `GhCardFooter` | `ui/reusables/card_kit.dart` |
| A status pill or badge | `GhBadge` with a `GhTone` | `ui/reusables/card_kit.dart` |
| A showcase card (assets, templates, news): cover art, glass chips and actions, hover lift | `GhCard(lift: true)`, `GhCover`, `GhGlassChip`, `GhGlassIconButton`, `GhInitialsAvatar` | `ui/reusables/showcase_card.dart` |
| A toolbar of filters above a grid | `GhFilterBar` | `ui/reusables/filter_bar.dart` |
| Sections beside a view's search box | `GhViewTabs` | `ui/reusables/view_tabs.dart` |
| A selectable chip | `GhChoiceChip` | `ui/reusables/modal_kit.dart` |
| A responsive grid of cards | `GhCardGrid` with `GhGridBreakpoints.cards` or `.reading` | `ui/reusables/card_grid.dart` |
| Empty, loading and error states, skeletons | `GhStatePanel.empty/.loading/.error`, `GhSkeleton` | `ui/reusables/state_panel.dart` |
| Buttons | `GhButton` (primary, danger, ghost, subtle, outline), `GhIconButton`, `GhBusyButton` | `ui/core/button.dart`, `ui/reusables/modal_kit.dart` |
| A dialog | `GhModalShell` with `ghModalActions` for the footer | `ui/feedback/modal_shell.dart` |
| Inline alerts | `GhAlertBox` | `ui/reusables/modal_kit.dart` |

Guidelines the redesigned screens follow:

- **One primary action** per card, dialog footer or empty state. Everything else
  is secondary (outline, ghost or a menu). In dialog footers the primary action
  sits at the end.
- **Sentence case** for labels, captions, buttons and headings. Don't
  `.toUpperCase()` body captions; brand names, badges like `MONO` and code
  identifiers keep their own casing.
- **Errors say what's wrong and how to fix it**, sit next to the field or item
  they belong to, and offer the fixing action there (for example "Manage
  versions" next to the missing-engine problem in Project Doctor).
- **Every screen has deliberate empty, loading and error states** built from
  `GhStatePanel`, with a retry or a next step where one exists.
- **Grids adapt to the space they have**, not the window size: card grids go
  from 1 to 6 columns by available width and font scale.
- **Path fields accept typed and pasted paths.** Quotes from "Copy as path" and
  a leading `~` are handled for you; validation runs when the value is
  committed (Enter, Apply, Browse or submitting the form).

Debug builds include a widget gallery (`lib/debug/gallery`) that shows the
shared components in every state. Open it from the app in a debug build, or run
it on its own with `flutter run -d <platform> -t lib/gallery_main.dart`.

---

## 🌍 Localization

The Flutter app uses typed translations generated by
[Slang](https://pub.dev/packages/slang) from shared JSON resource files.
English is the source of truth; every other language falls back to English for
missing keys. The `common` namespace is the primary home for shared strings,
and all other namespaces (`git`, `settings`, `versions`, etc.) fall back to
`common`.

### Current Status

| Locale | Language | Status |
|--------|----------|--------|
| `ar-MA` | العربية | 🧪 Beta |
| `en-US` | English | ✅ Complete |
| `es-MX` | Español | 🚧 Incomplete |
| `fr-FR` | Français | ✅ Complete |
| `ja-JP` | 日本語 | ✅ Complete |
| `pt-BR` | Português (Brasil) | 🧪 Beta |
| `ru-RU` | Русский | 🚧 Incomplete |
| `vi-VN` | Tiếng Việt | ✅ Complete |
| `zh-CN` | 简体中文 | ✅ Complete |

**Total keys:** 1,742 in en-US across 9 namespaces (counted 2026-11-05)

### How it's organized

```
src/i18n/locales/                 # Source of truth, edited by translators
├── en-US/                        # English (ALWAYS complete, the fallback)
│   ├── common.json               #   Shared strings (buttons, dialogs, modals)
│   ├── settings.json             #   Settings view strings
│   ├── git.json                  #   Git sidebar & dialogs
│   ├── versions.json             #   Versions view
│   ├── onboarding.json           #   Onboarding flow
│   ├── nav.json                  #   Sidebar navigation labels
│   ├── changelog.json            #   Changelog view
│   ├── dashboard.json            #   Dashboard greetings
│   └── todos.json                #   Project Next Steps (todos)
├── ar-MA/  es-MX/  fr-FR/  ja-JP/  pt-BR/  ru-RU/  vi-VN/  zh-CN/

app/lib/i18n/                     # Generated, never edited by hand
├── json/<namespace>/<namespace>_<locale>.i18n.json
└── strings*.g.dart
```

To translate, edit values in the relevant locale and namespace JSON file under
`src/i18n/locales/`; no Flutter or Dart knowledge is required.

The Flutter files are generated from those JSON files:

- If you have the Flutter SDK installed, the pre-commit hook regenerates and
  stages the Flutter locale files when you commit a locale change.
- If you don't, the hook lets the commit through and the **i18n sync** workflow
  handles generation for your pull request. For pull requests from forks, it
  opens a follow-up pull request after merge.
- By hand: `cd app && dart run ../dev/tool/i18n_convert.dart && dart run slang`.

Do not edit `app/lib/i18n/json/`, `app/lib/i18n/strings*.g.dart`,
`app/slang.yaml` or `dev/tool/i18n_convert.dart` for a translation.

### Namespace Reference

| Namespace | Description |
|-----------|-------------|
| `common` | General UI strings, buttons, messages (the fallback for every namespace) |
| `settings` | Settings page labels & descriptions |
| `git` | Git integration strings |
| `versions` | Godot version management |
| `onboarding` | First-run setup wizard |
| `nav` | Navigation sidebar |
| `changelog` | Changelog management |
| `dashboard` | Dashboard greetings |
| `todos` | Project Next Steps |

### Duplicate key policy

Duplicate keys across namespace files are **not allowed**. The `common` namespace
is the single source of truth for any string shared across views. If a key
exists in `common.json`, it must **not** also exist in `git.json`, `settings.json`,
`versions.json`, or any other namespace file, even with the same value.

**Why?** i18next's `fallbackNS: ['common']` config means every namespace
automatically falls back to `common` for missing keys. Duplicates bloat the
locale files and create confusion about where a string lives.

**Rules:**
- Shared strings (buttons, labels, messages used in multiple views) go in `common.json`.
- Namespace-specific strings (only used in one view) go in that namespace's file.
- Never copy a key from `common.json` into another file, even for translation.
- Run `cd app && dart run ../dev/tool/i18n/duplicate_keys.dart` (or `bun run i18n:dupes`)
  to find any duplicate keys across namespace files.

```bash
bun run i18n:dupes            # Check all locales
bun run i18n:dupes -- en-US   # Check one locale
bun run i18n:dupes -- --same  # Only same-value dupes (safe to remove)
bun run i18n:dupes -- --diff  # Only different-value dupes (need review)
```

### How strings are used in code

```dart
// Typed accessor, preferred: the compiler catches typos and missing keys.
final tr = context.tr.common;
Text(tr.open_project);

// With interpolation:
Text(tr.project_card_last_opened.args({'date': date}));

// Runtime lookup by key, for keys built at runtime or from another namespace:
Text(ghTr('asset_source_${asset.source}'));
Text(ghTr('git:branch_name_required'));
Text(ghTr('asset_store_count', count: total));
```

Interpolation placeholders are written `{{name}}` in the JSON.

### Interpolation & Pluralization

#### Interpolation
Use `{{variable}}` for dynamic values:
```json
{
  "project_count": "{{count}} projects",
  "welcome_user": "Welcome, {{name}}!"
}
```

#### Pluralization
Use `_one` and `_other` suffixes (and `_zero`, `_two`, `_few`, `_many` where the
language needs them):
```json
{
  "file_count_one": "{{count}} file",
  "file_count_other": "{{count}} files"
}
```

### Adding a new string (English only!)

1. Decide where the key belongs:
   - **`common.json`** if the string is a button, label, or message shared
     across multiple views (the default for most new strings).
   - **Namespace file** (`git.json`, `settings.json`, etc.) only if the
     string is exclusively used in that one view.
2. Add the key to `src/i18n/locales/en-US/<namespace>.json`:
   ```json
   "project_created": "Project created",
   "greeting_user": "Hello, {{name}}!"
   ```
3. Copy the English text to the other locales so translators can see it:
   `bun run i18n:sync -- --apply` (or add the same key by hand). Don't translate.
4. Regenerate: `cd app && dart run ../dev/tool/i18n_convert.dart && dart run slang`
   (the pre-commit hook does this for you if Dart is installed).
5. Use it with `context.tr.common.project_created`.
6. Run `flutter analyze` and the tests for the screen you touched.

### Adding a new language (step by step)

Say you want to add **Japanese** (`ja-JP`):

1. **Create the locale folder** with all 9 namespace files, copied from English
   so the key structure is identical:
   ```bash
   mkdir src/i18n/locales/ja-JP
   cp src/i18n/locales/en-US/*.json src/i18n/locales/ja-JP/
   ```
   (`bun run i18n:add ja-JP "日本語"` does the same if you have Bun.)
2. **Add it to the language picker** in `app/lib/i18n/languages.dart`, next to
   the existing entries:
   ```dart
   GhLanguageOption(value: 'ja-JP', label: '日本語', country: 'JP', status: GhLanguageStatus.incomplete),
   ```
3. **Translate** the values (not the keys!) in each file. Untranslated strings
   can be left in English, they fall back, but try to cover the common
   namespaces first (`common`, `nav`, `settings`).
4. **Set a status badge.** `status` is one of:
   - `complete`, every key translated and verified.
   - `beta`, mostly translated; minor gaps or needs a native-speaker review.
   - `incomplete`, new or partially translated; falls back to English in places.
5. **Verify** and open a PR:
   ```bash
   cd app
   dart run ../dev/tool/i18n_convert.dart && dart run slang
   dart run ../dev/tool/i18n/check_keys.dart --check-values
   flutter analyze
   ```
   If you don't have Flutter, skip this step: CI and the i18n sync workflow
   regenerate and check the files for you. Native speakers are strongly
   preferred, get a review before marking `complete` or `beta`.

### Updating an existing translation

- Fix a wrong string: edit the value in that language's JSON file, same key.
- If the English source text changes, the old key stays; update the value and
  bump the translation so it still reads naturally.
- Translation status lives in `app/lib/i18n/languages.dart`; if you complete a
  language, flip its status there and in the table above.

### Sync Missing Keys

If en-US has new keys your locale is missing, sync them:
```bash
bun run i18n:sync              # Dry run (shows what would change)
bun run i18n:sync -- --apply   # Add missing keys (copies English values)
bun run i18n:sync -- --apply --empty  # Add missing keys (empty for translation)
bun run i18n:sync -- zh-CN     # Sync only one locale
bun run i18n:sync -- --remove-extras  # Also remove stale keys
```

By default, `--apply` copies the English text as a placeholder.
Use `--empty` if you want empty strings instead (for translators to fill in).

### Checking locales

```bash
cd app
dart run ../dev/tool/i18n/check_keys.dart --check-values   # missing and untranslated keys
dart run ../dev/tool/i18n/duplicate_keys.dart              # keys duplicated across namespaces
dart run ../dev/tool/i18n/unused_keys.dart                 # keys no source file references
```

Missing keys fail CI. Untranslated keys (the same text as English) are reported
but allowed, because new strings start out in English.

The older Node scripts still work if you have Bun installed:

| Command | Purpose |
|---|---|
| `bun run i18n:add` | Interactive wizard to add a new language |
| `bun run i18n:check -- --check-values` | Check all locales against en-US |
| `bun run i18n:sync -- --apply` | Add missing keys (copies English values) |
| `bun run i18n:dupes` | Find duplicate keys across namespace files |

### Locale file checklist

- Keys are always `snake_case`, quoted, with commas after every entry except
  the last.
- Values keep `{{placeholder}}` interpolation tokens intact.
- Never reorder or rename keys in non-English files without updating the
  English source first.

### Best Practices

#### Do's ✅
- **Keep keys identical** across all locales, only change values
- **Use interpolation** for dynamic content: `{{name}}`, `{{count}}`
- **Test your translations** in the app if possible
- **Maintain the same tone** as the English version
- **Use proper formatting** for dates/numbers per locale
- **Keep translations concise**, UI space is limited

#### Don'ts ❌
- **Don't translate keys**, only translate values
- **Don't add HTML** in translations (use interpolation instead)
- **Don't change interpolation variables**, keep `{{name}}` as-is
- **Don't translate technical terms** that should stay in English (e.g., "Git", "Godot")
- **Don't remove keys** that exist in en-US

#### Translation Tips
- **UI labels:** Keep short and clear
- **Error messages:** Be helpful and specific
- **Tooltips:** Explain what the feature does
- **Placeholders:** Use natural phrasing for your language
- **Formal vs informal:** Match the existing tone (GodotHub uses informal)

### Handling RTL (Right-to-Left) Languages

For languages like Arabic, Urdu, etc.:

1. The Flutter UI mirrors automatically for RTL languages (it uses
   `Directionality` and `EdgeInsetsDirectional` throughout)
2. No special code changes needed
3. Test that the interface mirrors correctly
4. Pay attention to mixed LTR/RTL content (e.g., "Git branch main")

---

## 🧪 Testing & CI

- **Flutter CI** (`.github/workflows/flutter-ci.yml`) runs on every push and
  pull request:
  1. Rust tests for `godothub_core` and `godothub_bridge`
  2. A check that third-party Rust notices are up to date
  3. Flutter locale regeneration from `src/i18n/locales`, then the i18n
     checks (missing keys, duplicates, unused keys)
  4. `flutter analyze`
  5. `flutter test`
  6. A release build on Windows, macOS and Linux
- **Write tests for what you change.** Widget tests live in `app/test/`,
  mirroring `app/lib/`, and use the fake Rust API in
  `app/test/support/fake_rust.dart`, so they never touch your real data. Rust
  logic gets `#[cfg(test)]` tests next to the code.
- **Manual testing matters.** Before opening a PR, exercise the feature you
  touched: create/open projects, install a version, push/pull in the Git
  sidebar, switch themes, and resize the window from narrow to fullscreen.
  Mention what you tested and on which OS.

### Git hooks

This repo keeps its hooks in `.githooks/`. Point git at them once per clone:

```bash
git config core.hooksPath .githooks
```

(`bun install` does this for you through the `prepare` script.) On macOS and
Linux the hook files also need the executable bit: `chmod +x .githooks/*`.

- **`pre-commit`** blocks em-dashes (U+2014) in staged files and regenerates
  the Flutter locale files when a locale JSON changes.
- **`commit-msg`** blocks AI or bot co-author trailers, AI attribution terms and
  em-dashes in commit messages. Human co-authors are allowed.

Bypass a hook with `git commit --no-verify` only when you know what you are doing.

---

## 🚀 Release Process

Releases are cut by maintainers with the Flutter release workflows
(`flutter-release.yml` for beta builds, `flutter-stable-package.yml` for stable
installers), which build and sign packages for every platform and publish the
update feed. See [dev/docs/BRIDGE_RELEASE.md](dev/docs/BRIDGE_RELEASE.md)
for how updates roll out and how a release can be paused. You don't need to do
anything special as a contributor, just get your PR merged.

---

## 🗄️ Legacy Tauri App

The React + Tauri app in `src/` and `src-tauri/` produced every release before
1.6.0 and is being removed over time. It still shares the Rust core, so
`cargo check --workspace` must keep passing. If you need to run it:

```bash
bun install
bun run tauri dev
```

Please don't add features there; open them against the Flutter app instead.

---

## ❓ Getting Help

- **Issues**, ask questions in an issue or a PR discussion. The maintainer
  is active and friendly.
- **Feature ideas / QoL suggestions**, issues are welcome; the project loves
  QoL improvements.
- **Translations**, if you want to start a new language, open an issue first
  so the team can add you and track it.

Thanks again for contributing, happy building! 🚀
