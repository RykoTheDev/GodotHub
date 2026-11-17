# GodotHub 1.6 migration FAQ

GodotHub 1.6.0 is the same app rebuilt with Flutter instead of Tauri. Projects, Godot versions, workspaces, templates, categories, settings and your Git sign-in carry over by themselves. This page covers what changed and what to do if something goes wrong.

## Where does my data live?

GodotHub 1.6 uses the same data folder as 1.5, so nothing is copied or converted when you update.

| System | Data and settings |
| --- | --- |
| Windows | `%APPDATA%\Ryko.GodotHub` |
| macOS | `~/Library/Application Support/Ryko.GodotHub` |
| Linux | `~/.local/share/Ryko.GodotHub` (settings in `~/.config/Ryko.GodotHub`) |

Your projects and Godot installs stay wherever you put them. GodotHub only keeps their paths.

Appearance choices from 1.5 (theme, sidebar width, card style and similar) were copied over by 1.6.0 and 1.6.1. Later versions start with the default appearance when updating straight from 1.5; set it again in Settings.

Uninstalling GodotHub removes the app but keeps this folder. Delete it yourself if you want a clean start.

## Where is the app installed?

| Install type | App files |
| --- | --- |
| Windows installer (`setup.exe`) | `%LOCALAPPDATA%\GodotHub`. `godothub.exe` there is a small launcher that starts the current version from its `app-<version>` folder. |
| Windows MSI | `C:\Program Files\GodotHub` |
| Windows portable | Wherever you unzip `GodotHub-<version>-windows-x64-portable.zip`. Run `godothub.exe` inside the folder. |
| macOS | `/Applications/GodotHub.app` |
| Linux `.deb` and `.rpm` | `/usr/lib/godothub`, with `/usr/bin/godothub` pointing to it |
| Linux AppImage | Wherever you keep the `.AppImage` file |

The Windows portable build used to be a single `.exe`. It is now a folder in a `.zip` because the app's engine and data files sit next to `godothub.exe`. The Visual C++ runtime is built into the app, so you do not need a separate Visual C++ install.

## Which systems are supported?

- Windows 10 or 11, x64.
- macOS 12 Monterey or newer, on Apple Silicon or Intel. Flutter does not run on older macOS.
- 64-bit Linux with GTK 3 and OpenGL ES (`libegl1` and `libgles2`, which the `.deb` and `.rpm` pull in).

On macOS 10.15 or 11, keep using [GodotHub 1.5.9](https://github.com/RykoTheDev/GodotHub/releases/tag/v1.5.9). It keeps working with your data.

## I'm on a Mac. Why didn't GodotHub 1.5 update itself to 1.6?

The old app cannot tell which macOS version it runs on, and 1.6 does not open on macOS 10.15 or 11. So that nobody ends up with an app that will not start, GodotHub 1.5 on a Mac is not offered 1.6. On macOS 12 or newer, download `GodotHub-<version>-darwin-universal.dmg` from the [latest release](https://github.com/RykoTheDev/GodotHub/releases/latest) and drag GodotHub into Applications, replacing the old one. Your data stays where it is. From then on, updates install from inside the app as usual.

## How do updates work now?

GodotHub checks for updates when it starts and shows **Update available** in the sidebar. You can also check from **Settings → Advanced → Check for Updates**.

- **Windows installer:** the update downloads, its signature is checked, and it installs inside the app with no installer window. Click **Restart Now** to switch. If you close the window first, the sidebar shows **Restart to Apply Update**.
- **Windows MSI:** the update downloads inside the app, then Windows Installer finishes it and GodotHub starts again.
- **Windows portable:** GodotHub tells you about the update but does not install it. Download the new portable `.zip` from the release page and unzip it over your folder or next to it.
- **macOS:** the app bundle is replaced in place. Coming from GodotHub 1.5 on a Mac, install 1.6 by hand once (see the Mac question above); after that it updates itself.
- **Linux:** the AppImage replaces itself. For `.deb` and `.rpm`, the app downloads the new package and asks for your password to install it.

The **Log** tab in the update window lists every step and file, which helps if you need to report a problem.

## What if an update fails?

- **It fails before restarting** (download, signature or disk space error): nothing has changed. The current version keeps working. Check your connection and free space, then try again from **Check for Updates**.
- **The new version does not start (Windows installer):** the launcher notices and starts the previous version again by itself. The previous version stays installed until a newer one starts properly.
- **Anything else:** download the installer for your system from the [latest release](https://github.com/RykoTheDev/GodotHub/releases/latest) and install it over the old one. Your data is not touched.

Then [open an issue](https://github.com/RykoTheDev/GodotHub/issues) with the contents of the update window's **Log** tab.

## How do I go back to the last Tauri version?

1. Uninstall GodotHub 1.6 (Windows: **Settings → Apps**, macOS: move GodotHub to the Trash, Linux: remove the `godothub` package). Your data folder stays.
2. Download the file for your system from [GodotHub 1.5.9](https://github.com/RykoTheDev/GodotHub/releases/tag/v1.5.9) and install it.
3. GodotHub 1.5.9 will offer 1.6 again as an update. It only installs when you click **Update**, so leave the button alone until you want to try again.

GodotHub 1.5.9 reads the same data folder, so your projects and settings are still there. Settings that only exist in 1.6 are ignored by 1.5.9.

## I used GodotHub Beta. What now?

GodotHub Beta was the test build of this rewrite. It installs next to GodotHub, has its own name, icon and data folder (`Ryko.GodotHub.Beta`), and started from a copy of your GodotHub data, so the two never touched each other's settings.

The beta ends with 0.2.5. Once GodotHub 1.6.0 is out, the beta shows a notice with a link to download it and, on Windows, a button to uninstall the beta. Nothing moves from the beta to GodotHub: GodotHub keeps using its own data, and the beta's data stays in its own folder until you delete it.

You can keep both installed while you switch. They can run at the same time, but they work on the same project folders and Godot installs on disk, so avoid changing the same project in both at once.
