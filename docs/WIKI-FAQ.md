# FAQ / Troubleshooting

Answers to common questions, plus what to do when something isn't working.

---

## Installation and updates

### The AppImage doesn't start on my Linux distro

The AppImage doesn't work on most distros right now. This is an upstream `linuxdeploy` issue that affects nearly all Tauri apps, so it can't be fixed from this project. Use the `.deb` or `.rpm` package instead where possible.

### My distro isn't Arch Linux. Is GodotHub tested on it?

GodotHub is currently tested on Windows, Arch Linux (Hyprland), and the newest macOS. Other distros are untested. If you find a problem on yours, please open an issue so it can be fixed or documented.

### Winget says my version is outdated

Winget can lag behind the latest release because the package update isn't always merged right away. Download the newest version from the releases page, or run `winget upgrade Ryko.GodotHub` to check.

### How do updates work?

GodotHub checks for updates on startup and in Settings under Advanced. Updates are downloaded and installed automatically, then applied on restart.

---

## Data and settings

### How do I reset all settings?

**Settings → Advanced → Reset Settings**. This restores every toggle, slider, and color pick to its defaults. Your scan folders and download locations are kept, and nothing on disk is touched.

### How do I delete all app data?

**Settings → Advanced → Delete App Data**. This permanently deletes every workspace, project, category, installed-version record, and setting, then restarts you at first-time setup. Your actual project folders and Godot installs on disk are not touched, unless they live in the default download folder (in which case they're deleted too). This can't be undone.

### Can I move my setup to a new computer?

- **Settings**: there isn't a single "export all settings" button, but the time-tracking stats can be exported and re-imported from **Settings → Storage → Time tracking backup**. Re-run the setup wizard on the new machine to reconfigure scan folders and appearance.
- **Projects and versions**: point GodotHub at your existing folders via the setup wizard or Settings → Storage. GodotHub rescans and re-registers everything.

### I accidentally changed colors and want the default back

Use **Reset colors to default** next to the accent and background pickers, or **Reset appearance to default** for the whole Appearance section.

---

## Projects and versions

### A project shows a version warning

GodotHub shows a visual warning when a project's bound Godot version is missing, or has a major version mismatch. Install the version it expects (Versions view), or rebind the project to an installed version from the project card.

### My project or version isn't showing up

Check that its folder is inside one of your scan folders (Settings → Storage), then use **Scan Now** from the Projects or Versions view. If you enabled file watchers, new additions are picked up automatically within a few seconds of the change. If you're scanning a deep folder tree, increase the scan depth.

### Downloads are slow or stuck

Downloads run up to the configured concurrency (Settings → Storage → Simultaneous downloads). Extra downloads wait in a queue and start automatically as slots free up. The list also supports resuming interrupted downloads.

### The asset download failed

Check your connection and try again. Asset downloads save into the folder you configured, and GodotHub opens it in your file manager so you can find the file.

---

## Git and GitHub

### HTTPS push or pull asks for credentials every time

Sign in from **Settings → Integrations**. GitHub and GitLab use OAuth device sign-in; other hosts (Codeberg, Gitea, Bitbucket, and so on) use a personal access token that GodotHub stores per host.

### I hit GitHub's API rate limit when browsing versions

GodotHub uses the unauthenticated GitHub API limit of 60 requests per hour when fetching the version list. Add a personal access token in **Settings → Integrations → GitHub API Token** to raise it to 5,000 per hour. No scopes are needed.

---

## Other

### How do I report a bug or request a feature?

Use **Settings → Advanced → Report a Bug** to file an issue directly from the app, or open an issue on the [GitHub repository](https://github.com/RykoTheDev/godothub/issues). Include your platform, GodotHub version, and what you did when the problem happened.

### The new UI feels broken or unresponsive

Altough new UI is now stable, Some areas might still contain bugs. If you find a reproducible problem, please report it.

### How do I change the command palette shortcut?

**Settings → Display → Command palette key**. Click the button, then press any key to rebind. Press `Escape` to cancel.

### GodotHub quit when I opened a project, is that a bug?

No. "Close application on project open" is a setting under **Settings → Behavior → Launch**. On Windows and Linux it quits GodotHub when a project launches; on macOS it hides the window instead. Turn it off if you'd rather keep GodotHub open.

---

## Related

- [[Home]]
- [[Getting Started]]
- [[Settings Reference]]
- [[Keyboard Shortcuts]]
- [[Custom CSS in the New UI]]
