# Settings Reference

Everything in Settings applies instantly and is saved automatically. This page goes through each category and what every option does.

In the new UI, Settings has a search box at the top, so you can type a setting name to jump straight to it.

---

## Appearance

Changes here apply instantly across the whole app.

### Card layout

- **Card layout**: show the sidebar, views, and titlebar as separate floating rounded cards. Turn it off for a connected layout where everything merges into one surface, like the classic UI.

### Theme preset

- **Theme preset**: pick a full color theme that controls every color in the app. Options include Atom One Dark, Nord, Dracula, Catppuccin, GitHub, Solarized, Gruvbox, Tokyo Night, Rosé Pine, Everforest, and Ayu, split into light and dark groups. Choose **Custom** to use your own accent and background instead.

With **Custom** selected you also get:

- **Theme mode**: Dark, Light, or System. System follows your OS preference and updates live when you switch the system appearance.
- **Accent color**: pick from preset swatches or any custom hex color.
- **Background color**: the base page color. In light mode the app derives card surfaces, borders, and overlays from it; in dark mode it sets the base page color.
- **Raised surface contrast**: how far raised surfaces (cards, inputs, menus) sit from your background color. Higher values give more separation; 0 makes them identical to the background.

### Corner radius

- **Corner radius**: controls every rounded corner in the app, from cards and buttons to inputs and dropdowns. 0 for sharp, square corners (0 to 20px).

### UI density

- **UI density**: scales padding, margins, and spacing everywhere. Lower for a tighter, compact layout (75% to 125%).

### Text size

- **Text size**: scales all text, and anything sized relative to it, across the app (85% to 130%).

### Motion

- **Animation intensity**: how much motion the app plays. Full keeps all animations, Subtle shortens them, and None disables them entirely.
- **View entrance animation**: the animation used when switching views and tabs (Fade, Slide, Scale, or None).

### List animation threshold

- **List animation threshold**: project lists larger than this render without entrance and exit animations, keeping the view fast on weaker machines. Lower values animate fewer cards.

### Scrollbar

- **Show scrollbar**: hides the scrollbar across the entire app when off. You can still scroll with keyboard, trackpad, or mouse wheel.

### Animated numbers

- **Animated numbers**: animate the counters in the new interface headers (projects, templates, versions, news, asset store). Turn off for plain static numbers.

### Project icon opacity

- **Project icon opacity**: the background icon opacity on project cards. Lower values make the icon more subtle, higher values more visible.

### Custom CSS

- **Custom CSS**: inject your own CSS to restyle anything in the app. Applies instantly on save. See the [[Custom CSS in the New UI]] guide for the full details, including all the CSS variables you can override.

---

## Display

Time and date formatting, language, and window chrome.

- **Time format**: 12-hour (`2:30 PM`) or 24-hour (`14:30`). Shown on project cards when a project was opened today.
- **Date format**: `DD-MM-YYYY`, `MM-DD-YYYY`, or `YYYY-MM-DD`. Shown for any other day.
- **Language**: the UI language. Each language shows its completion status (Complete, Beta, Incomplete).
- **Use OS window decorations**: use your operating system's native title bar and window controls instead of GodotHub's custom title bar. Requires a restart to take full effect.
- **Titlebar buttons**: show or hide the "Support" and "Star on GitHub" buttons in the titlebar.
- **Command palette key**: the shortcut that opens the command palette (default `P`). Click the button, then press any key to rebind. Press `Escape` to cancel.

---

## Storage

Folders GodotHub checks at startup. Star a folder to also use it as the default location for new projects or downloads.

- **Project scan folders**: scanned at startup for existing projects. The starred folder pre-fills the "Location" field in the New Project dialog.
- **Version scan folders**: scanned at startup for installed Godot executables. The starred folder is where new Godot versions are extracted when you install them.
- **Template scan directory**: any subfolders inside it are imported as templates when you click "Import from Directory" in the Templates view.
- **Scan depth**: how many folders deep to look inside each scan folder. Lower is faster and avoids picking up unrelated projects or versions in nested subfolders.
- **Simultaneous downloads**: how many Godot versions can download at the same time (1 to 10). Extra downloads wait in a queue and start automatically as slots free up.
- **Time tracking backup**: export your projects' open-time stats to a file, and restore them on a new computer or after a full app-data reset.

---

## Behavior

How GodotHub acts in day-to-day use.

### Launch

- **Close application on project open**: quits GodotHub automatically as soon as a project is launched in Godot. On macOS it hides GodotHub instead, keeping it running in the Dock.
- **Minimize to system tray on closing app**: keeps GodotHub running in the system tray instead of quitting when you close the window.
- **Reopen after closing Godot**: brings GodotHub back automatically once the Godot editor for that project is closed.
- **Launch Godot with console**: shows engine output, `print()` calls, and errors in a console window, using the console executable Godot ships alongside the editor. Only available for versions that include one.

### Projects

- **Use categories**: turns categories on or off entirely. When off, Projects shows one plain list; existing category assignments are kept and come back if you turn this on again.
- **Use workspaces**: turns workspaces on or off entirely. When off, GodotHub behaves as if there were only the one currently active workspace.
- **Directory naming convention**: how the project folder is named when you create a new project. The project name always keeps the spaces you typed; only the folder name is transformed (keep as typed, kebab-case, snake_case, camelCase, PascalCase, or Title Case).
- **Initialize Git repository**: ticks the Git option by default in the New Project dialog. It adds a Godot `.gitignore`, a `.gitattributes`, and an initial commit on main.
- **Tray recent projects**: how many recently opened projects appear in the system tray context menu (1 to 10).
- **Tooltip delay**: how long to wait before showing tooltips when hovering over buttons, icons, and sidebar items (100ms to 1000ms).

### File Watchers

- **Watch project folders**: automatically scans for new or removed projects whenever files change inside your configured project scan folders. New project folders are added to your library; removed ones are left in place but unregistered.
- **Watch version folders**: automatically scans for new or removed Godot executables whenever files change inside your configured version scan folders.
- **Watch template directory**: automatically syncs templates whenever files change inside your template scan directory.
- **Auto-scan on startup**: automatically scans your configured project and version folders for new additions every time GodotHub starts.

Watchers use debounced file system events, so changes are detected within a few seconds of the last file save. Disabling a watcher frees system resources.

---

## Integrations

Connect GodotHub to external services like Git and GitHub.

- **Sign in with GitHub / GitLab**: authorize GodotHub with OAuth device sign-in to authenticate HTTPS push, pull, fetch, and clone.
- **Self-hosted GitLab**: connect to your own GitLab instance. Create an OAuth application on your instance (scopes: `read_repository`, `write_repository`, `read_user`) and paste its base URL and Application ID.
- **Other hosts (personal access tokens)**: add a personal access token for hosts that don't support OAuth device sign-in, such as Codeberg, Gitea, or Bitbucket. GodotHub uses it to authenticate HTTPS remotes on that host.
- **GitHub API Token**: optionally set a GitHub personal access token to raise the API rate limit from 60 to 5,000 requests per hour when fetching available Godot versions. No scopes are needed. Create one at `github.com/settings/tokens` and test it from Settings.

---

## Advanced

Power-user settings: API tokens, data, updates, and app-level controls.

- **Run Setup Wizard Again**: reopens the first-time setup flow to reconfigure scan folders, categories, accent color, and corner radius. Settings you already saved are kept.
- **Check for Updates**: checks whether a new version of GodotHub is available. Updates are downloaded and installed automatically, then applied on restart. GodotHub also checks on startup.
- **Report a Bug**: opens a bug report to file the issue on GitHub.
- **Reset Settings**: restores every setting to its defaults. Scan folders and download locations are kept; only toggles, sliders, and color picks are reset.
- **Delete App Data**: permanently deletes every workspace, project, category, installed-version record, and setting GodotHub has stored, then restarts you at first-time setup. Your actual project folders and Godot installs on disk are not touched, unless they live in the default download folder.

---

## Related

- [[Home]]
- [[Getting Started]]
- [[Keyboard Shortcuts]]
- [[Custom CSS in the New UI]]
- [[FAQ / Troubleshooting]]
