# Contributing to GodotHub

First off, thank you for wanting to contribute! 🎉 GodotHub is a community-driven
project, and every issue filed, translation added, bug fixed, or feature built
makes it better for everyone.

This guide covers everything you need to know: setting up a dev environment,
finding something to work on, code conventions, and in depth, how
**localization** works and how to add or improve a language.

---

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Ways to Contribute](#-ways-to-contribute)
- [Setting Up a Dev Environment](#-setting-up-a-dev-environment)
- [Running the App](#-running-the-app)
- [Project Structure](#-project-structure)
- [Development Workflow](#-development-workflow)
- [Code Conventions](#-code-conventions)
- [Localization](#-localization)
- [Testing & CI](#-testing--ci)
- [Release Process](#-release-process)
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
| **Report a bug** | Open an issue with steps to reproduce, expected vs. actual behavior, and your OS + app version. |
| **Request a feature** | Open an issue describing *what* you want and *why*. Screenshots/mockups help a lot. |
| **Translate** | Add or improve a language in `src/i18n/`. A Bit of Typescript and React Knowledge is needed. See the [Localization section](#-localization). |
| **Test** | The app is only heavily tested on Windows, Arch Linux (Hyprland), Fedora (Gnome) 43, and recent macOS. Try a nightly/dev build on your setup and report what breaks. |
| **Write docs** | Improve the README, this file, or add FAQ content. |
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
| **Node.js 20+** | Frontend tooling | Any recent LTS works. |
| **Bun** | Package manager & build tool | Install from [bun.sh](https://bun.sh). The repo's lockfile is `bun.lock`. |
| **Rust (stable)** | Tauri backend | Install via [rustup](https://rustup.rs). |
| **Tauri system deps** | Native webview | **Linux** needs `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `librsvg2-dev`, `patchelf`, and friends. **Windows/macOS** need nothing extra (see [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/)). |
| **Git** | Version control | Also required by the app's Git features. |

### 1. Clone & install

```bash
git clone https://github.com/RykoTheDev/GodotHub.git
cd GodotHub
bun install
```

### 2. Verify the toolchain

```bash
bun run lint          # ESLint
bunx tsc --noEmit     # TypeScript typecheck
cd src-tauri && cargo check   # Rust typecheck (first run is slow)
```

All three should pass before you start.

---

## ▶️ Running the App

### Dev mode (hot reload)

```bash
bun run tauri dev
```

This builds the Rust backend and starts Vite with hot-reload for the frontend.
The app window opens with the GodotHub UI.

### Building a release

```bash
bun run tauri:build
```

On Linux this also runs the AppImage Wayland patch script. The output lands in
`src-tauri/target/release/`.

### Useful scripts

| Command | Purpose |
|---|---|
| `bun run dev` | Frontend only (Vite dev server, no Tauri window) |
| `bun run lint` | Run ESLint |
| `bunx tsc --noEmit` | TypeScript typecheck |
| `cd src-tauri && cargo check` | Rust typecheck (no codegen, faster) |
| `bun run tauri dev` | Full app in dev mode |
| `bun run tauri:build` | Full release build |

---

## 📁 Project Structure

```
godothub/
├── src/                        # Frontend (React + TypeScript)
│   ├── main.tsx                # Entry point
│   ├── types.ts                # Shared TypeScript types
│   ├── api/                    # Tauri command bindings
│   ├── hooks/                  # React hooks & contexts
│   ├── lib/                    # Shared helpers (api.ts, useApiData, naming…)
│   ├── i18n/                   # Localization (see the dedicated section below)
│   └── interface/
│       ├── App.tsx             # Main app shell
│       ├── style.css           # Design tokens
│       ├── components/         #   cards/, git/, modals/, reusables/, titlebar/, ui/
│       ├── hooks/              #   useScrollCompensation, useSectionSearch
│       ├── lib/                #   icons, duration, toast, workspaceIcons
│       ├── views/              #   ProjectsView, SettingsView, VersionsView…
│       └── onboarding/         #   First-run setup wizard
├── src-tauri/                  # Backend (Rust)
│   ├── src/
│   │   ├── lib.rs              # Tauri setup + command registration
│   │   ├── git.rs              # Git operations
│   │   ├── git_auth.rs         # OAuth device flow, PATs, remote repo creation
│   │   ├── projects.rs         # Project CRUD, launch
│   │   ├── godot_versions.rs   # Version download/install
│   │   └── …                   # settings, workspace, news, tray, watcher…
│   ├── licenses/               # License texts (MIT, Apache-2.0, GPL-3.0, Unlicense)
│   └── Cargo.toml
├── .github/workflows/          # CI + release pipelines
└── package.json
```

**UI-specific components** live in `src/interface/components/ui/` (Checkbox, Toggle, Dropdown, Tooltip…)
and `reusables/` (OverlayScrollArea, ViewHeader, ScanButton…). Shared logic goes in `src/lib/` or `src/hooks/`.

---

## 🧑‍💻 Development Workflow

### Branch & PR basics

1. Create a branch off `main`:
   ```bash
   git checkout -b fix/your-descriptive-name
   # or: feat/…, refactor/…, docs/…
   ```
2. Make your changes. Keep commits small and focused.
3. Run the checks (see below), **the CI runs all three**, so passing locally
   is expected before opening a PR.
4. Push and open a pull request against `main`. Reference the issue number in
   the PR description (`Closes #123`).

### Checks that must pass

```bash
bun run lint
bunx tsc --noEmit
cd src-tauri && cargo check
```

The CI (`ci.yml`) runs all of these on Windows, macOS, and Linux for every push
and PR, so don't worry about cross-platform issues you can't test locally,
but do mention which platform you *did* test on in the PR.

### ⚠️ The locale rule (important!)

> **When you change or add any user-facing string, only touch the English
> locale files (`src/i18n/locales/en-US/`).**
>
> Do **not** translate into the other languages (zh-CN, ru-RU, ar-MA) yourself.
> Untranslated keys fall back to English automatically, so the app stays fully
> functional. Native speakers pick up the new keys afterwards, mixing machine
> or half-correct translations into other locales creates a mess that's hard
> to clean up.

### Commit style

- Write clear, imperative commit messages: `Fix project icon not refreshing`,
  not `fix stuff`.
- One logical change per commit. If you touched formatting, keep it in its own
  commit so review diffs stay readable.
- Reference issues where relevant.

---

## 🎨 Code Conventions

### TypeScript / React

- TypeScript stricts no `any` unless there is genuinely no better option.
- React function components with hooks; no class components.
- Follow the patterns already in the file you're editing (state shape,
  error handling, naming).
- Components use the existing primitives in
  `src/interface/components/ui/` (Checkbox, Toggle, Dropdown, Tooltip…)
  and `reusables/` (OverlayScrollArea, ViewHeader, ScanButton…) instead of
  re-implementing them inline. If the shared component doesn't fit, extend it,
  don't fork it.
- ESLint config lives in `eslint.config.js`. Run `bun run lint` after edits.

### Rust

- `cargo fmt` style (run `cargo fmt` before committing).
- Errors are `Result<_, String>` for Tauri command boundaries, matching the
  existing convention in the file.
- Blocking work (git subprocesses, file IO) must run inside
  `tokio::task::spawn_blocking` so the UI thread never freezes. Most git
  commands in `git.rs` already follow this pattern, keep it that way.
- Add new Tauri commands to the `invoke_handler` list in `lib.rs`.

### Naming

- Frontend: `camelCase` for variables/functions, `PascalCase` for components,
  `kebab-case` for files (`InstalledVersionCard.tsx`, `useSettings.ts`).
- Rust: `snake_case` for functions/variables, `PascalCase` for types, files
  match the module they contain (`git_auth.rs`).
- Tauri command names are `snake_case` on the Rust side and are invoked from
  the frontend as camelCase args (`invoke('git_init_project', { path })`).

---

## 🌍 Localization

Localization uses **i18next** + **react-i18next** with JSON resource files.
English is the source of truth; every other language falls back to English for
missing keys.

### Current Status

| Locale | Language | Status |
|--------|----------|--------|
| `en-US` | English | ✅ Complete |
| `ja-JP` | 日本語 | ✅ Complete |
| `es-MX` | Español | 🚧 Incomplete |
| `zh-CN` | 简体中文 | 🧪 Beta |
| `ru-RU` | Русский | 🚧 Incomplete |
| `ar-MA` | العربية | 🚧 Incomplete |

**Total keys:** ~1,321 across 8 namespaces

### How it's organized

```
src/i18n/
├── index.ts              # i18n setup: registers all locales & namespaces
├── languages.ts          # Language options & status badges
├── types.ts              # Auto-generated TypeScript types
└── locales/
    ├── en-US/            # Source of truth (ALWAYS complete, the fallback)
    │   ├── common.json       #   Shared strings (buttons, dialogs, modals)
    │   ├── settings.json     #   Settings view strings
    │   ├── git.json          #   Git sidebar & dialogs
    │   ├── versions.json     #   Versions view
    │   ├── onboarding.json   #   Onboarding flow
    │   ├── nav.json          #   Sidebar navigation labels
    │   ├── changelog.json    #   Changelog view
    │   └── dashboard.json    #   Dashboard greetings
    ├── ja-JP/
    ├── es-MX/
    ├── zh-CN/
    ├── ru-RU/
    └── ar-MA/
```

### Namespace Reference

| Namespace | Description | Keys |
|-----------|-------------|------|
| `common` | General UI strings, buttons, messages | ~773 |
| `settings` | Settings page labels & descriptions | ~314 |
| `git` | Git integration strings | ~146 |
| `versions` | Godot version management | ~46 |
| `onboarding` | First-run setup wizard | ~17 |
| `nav` | Navigation sidebar | ~11 |
| `changelog` | Changelog management | ~9 |
| `dashboard` | Dashboard greetings | ~5 |

### How strings are used in code

```tsx
// In a component:
const { t } = useTranslation('git')
const { t: tc } = useTranslation('common')   // different namespace alias

// Plain string:
<p>{t('pull_complete')}</p>

// With interpolation:
<p>{t('auth_connected_as', { username: 'ryko' })}</p>

// With a namespace override inline:
<p>{tc('cancel', { ns: 'common' })}</p>
```

Interpolation placeholders are written `{{name}}` in the JSON and passed as an
object to `t()`.

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
i18next supports `_one` and `_other` suffixes:
```json
{
  "file_count_one": "{{count}} file",
  "file_count_other": "{{count}} files"
}
```

Usage in code:
```typescript
t('file_count', { count: 5 })  // "5 files"
t('file_count', { count: 1 })  // "1 file"
```

### Adding a new string (English only!)

1. Open the right namespace file under `src/i18n/locales/en-US/`
   (e.g. `common.json` for a button label).
2. Add your key:
   ```json
   "project_created": "Project created",
   "greeting_user": "Hello, {{name}}!"
   ```
3. Use it in the component with `t('project_created')`.
4. **Do not** add the key to other languages, they'll fall back to English.
5. Run `bunx tsc --noEmit` and `bun run lint`.

That's it, the new string shows up in every language automatically until a
translator covers it.

### Adding a new language (step by step)

Say you want to add **Japanese** (`ja-JP`):

**Option A: Use the interactive wizard (recommended)**
```bash
bun run i18n:add ja-JP "日本語"
```
This automatically:
- Creates the locale folder with all namespace files
- Registers imports in `index.ts`
- Adds the language to `languages.ts`

**Option B: Manual setup**
1. **Create the locale folder** with all 8 namespace files, copied from English
   so the key structure is identical:
   ```bash
   mkdir src/i18n/locales/ja-JP
   cp src/i18n/locales/en-US/*.json src/i18n/locales/ja-JP/
   ```
2. **Register the resources** in `src/i18n/index.ts`:
   ```ts
   import jaJPNav from './locales/ja-JP/nav.json'
   import jaJPCommon from './locales/ja-JP/common.json'
   import jaJPSettings from './locales/ja-JP/settings.json'
   import jaJPGit from './locales/ja-JP/git.json'
   import jaJPChangelog from './locales/ja-JP/changelog.json'
   import jaJPOnboarding from './locales/ja-JP/onboarding.json'
   import jaJPVersions from './locales/ja-JP/versions.json'
   import jaJPDashboard from './locales/ja-JP/dashboard.json'

   const jaJPResources = {
     nav: jaJPNav,
     common: jaJPCommon,
     settings: jaJPSettings,
     git: jaJPGit,
     changelog: jaJPChangelog,
     onboarding: jaJPOnboarding,
     versions: jaJPVersions,
     dashboard: jaJPDashboard,
   }

   const resources = {
     'en-US': { … },
     'ja-JP': jaJPResources,
     ja: jaJPResources,  // optional shorthand
   }
   ```
3. **Add it to the language picker** in `src/i18n/languages.ts`:
   ```ts
   { value: 'ja-JP', label: '日本語', country: 'JP', status: 'incomplete' },
   ```

**Then for both options:**
4. **Translate** the values (not the keys!) in each file. Untranslated strings
   can be left in English, they fall back, but try to cover the common
   namespaces first (`common`, `nav`, `settings`).
5. **Set a status badge.** `status` is one of:
   - `complete`, every key translated and verified.
   - `beta`, mostly translated; minor gaps or needs a native-speaker review.
   - `incomplete`, new or partially translated; falls back to English in places.
6. **Verify** and open a PR:
   ```bash
   bun run i18n:check -- ja-JP   # Check your locale
   bun run i18n:types            # Regenerate TypeScript types
   bun run lint && bunx tsc --noEmit
   ```
   Native speakers are strongly preferred, get a review before marking
   `complete` or `beta`.

### Updating an existing translation

- Fix a wrong string: edit the value in that language's JSON file, same key.
- If the English source text changes, the old key stays; update the value and
  bump the translation so it still reads naturally.
- Translation status lives in `languages.ts`, if you complete a language,
  flip its status there and in the README table.

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

### i18n helper scripts

| Command | Purpose |
|---|---|
| `bun run i18n:add` | Interactive wizard to add a new language |
| `bun run i18n:check` | Check all locales against en-US |
| `bun run i18n:check -- zh-CN` | Check a single locale |
| `bun run i18n:check -- --check-values` | Detect untranslated keys (same as English) |
| `bun run i18n:sync` | Show missing keys (dry run) |
| `bun run i18n:sync -- --apply` | Add missing keys (copies English values) |
| `bun run i18n:sync -- --apply --empty` | Add missing keys (empty for translation) |
| `bun run i18n:types` | Regenerate TypeScript types |
| `bun run validate` | Run all checks (typecheck + i18n) |

### Automatic validation

**Pre-commit hook** runs `i18n:check -- --check-values` automatically when you commit changes to `src/i18n/locales/`. This checks for:
- Missing keys (in en-US but not in your locale)
- Extra keys (in your locale but not in en-US)
- Untranslated keys (same value as English)

If any issues are found, the commit is blocked with instructions to fix it. Skip with `git commit --no-verify` (not recommended).

**CI** (`.github/workflows/ci.yml`) runs `i18n:check -- --check-values` on every PR to `main`. PRs with missing, extra, or untranslated keys will fail the check.

### Locale file checklist

- Keys are always `snake_case`, quoted, with commas after every entry except
  the last.
- Values keep `{{placeholder}}` interpolation tokens intact.
- Never reorder or rename keys in non-English files without updating the
  English source first.

### Best Practices

#### Do's ✅
- **Keep keys identical** across all locales — only change values
- **Use interpolation** for dynamic content: `{{name}}`, `{{count}}`
- **Test your translations** in the app if possible
- **Maintain the same tone** as the English version
- **Use proper formatting** for dates/numbers per locale
- **Keep translations concise** — UI space is limited

#### Don'ts ❌
- **Don't translate keys** — only translate values
- **Don't add HTML** in translations (use interpolation instead)
- **Don't change interpolation variables** — keep `{{name}}` as-is
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

1. The UI already supports RTL layout via CSS
2. No special code changes needed
3. Test that the interface mirrors correctly
4. Pay attention to mixed LTR/RTL content (e.g., "Git branch main")

---

## 🧪 Testing & CI

- **CI** (`.github/workflows/ci.yml`) runs on every push/PR to `main` on
  **Windows, Ubuntu, and macOS**:
  1. TypeScript typecheck (`tsc --noEmit`)
  2. Rust `cargo check`
  3. Vite production build
- There's no unit-test suite yet, verification is typecheck + lint + manual
  testing. If you add a Rust module with non-trivial logic, `#[cfg(test)]`
  unit tests are very welcome.
- **Manual testing matters.** Before opening a PR, exercise the feature you
  touched: create/open projects, install a version, push/pull in the Git
  sidebar, switch themes. Mention what you tested and on which OS.

---

## 🚀 Release Process

Releases are cut by maintainers from `main` using the `release.yml` workflow
(builds installers for all platforms, publishes to GitHub Releases and
winget). You don't need to do anything special as a contributor, just get
your PR merged.

---

## ❓ Getting Help

- **Issues**, ask questions in an issue or a PR discussion. The maintainer
  is active and friendly.
- **Feature ideas / QoL suggestions**, issues are welcome; the project loves
  QoL improvements.
- **Translations**, if you want to start a new language, open an issue first
  so the team can add you and track it.

Thanks again for contributing, happy building! 🚀
