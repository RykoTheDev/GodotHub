# Environment checks for the Flutter build

Environments the Tauri app handled without special code, checked against the stable Flutter build. "Tested" means an automated test or a run on real hardware; "reviewed" means checked from the code and packaging only.

## Windows

| Environment | Result | How it was checked | Notes |
| --- | --- | --- | --- |
| Non-ASCII and space-containing user names and project paths | Works | Tested: core test `projects::path_environment_tests` and `app/test/platform/paths_test.dart` (Cyrillic, CJK, accents, emoji, spaces) | The installer is a Unicode NSIS build and installs under `%LOCALAPPDATA%`. A real Windows account with a non-ASCII name has not been tried. |
| Paths over 260 characters | Fixed | Tested: the same tests use paths over 300 characters | Rust handles long paths itself. Dart listed long folders only in long-path-aware programs, so the runner manifest now declares `longPathAware`. That still needs "Enable Win32 long paths" (LongPathsEnabled) in Windows; Godot and other tools have their own limits. |
| AppData redirected to OneDrive or a network share | Same as Tauri | Reviewed | Data stays in the Roaming folder, which follows the redirection, exactly as Tauri did. App files and updates live in `%LOCALAPPDATA%`, which Windows does not redirect. Saves write a temporary file in the same folder and rename it, which works on SMB shares. Not run on a redirected profile. |
| Standard (non-admin) account | Works for setup.exe and portable | Reviewed | The setup installs per user (`RequestExecutionLevel user`) and in-app updates only write to `%LOCALAPPDATA%\GodotHub`. The MSI installs per machine, so installing and updating it asks for an administrator, as the Tauri MSI did. |
| AppLocker or Smart App Control | Blocked, same as Tauri | Reviewed | Default AppLocker rules only allow programs in Program Files and Windows, so per-user installs (Tauri's and Flutter's) are blocked; managed machines should use the MSI. Smart App Control blocks unsigned apps entirely, which only code signing fixes. The launcher layout adds no new folder: Tauri's setup already ran from `%LOCALAPPDATA%`. |
| Windows 10 22H2 and older Windows 10 builds | Not tested | Reviewed | The runner declares Windows 10 and 11 support and ships the Visual C++ runtime next to the app. Needs a run on a Windows 10 22H2 machine. |
| Windows on ARM running the x64 build | Not tested | Reviewed | Windows 11 on ARM runs x64 apps under emulation; Windows 10 on ARM cannot, for Tauri as well. The updater picks the x64 package because the build itself is x64. |
| 100 to 200 percent scaling, mixed-DPI monitors | Not tested | Reviewed | The runner is Per-Monitor V2 DPI aware and Flutter rescales when the window moves between monitors. Needs a manual check on a mixed-DPI setup, including that the saved window size and position come back right. |
| High contrast mode | Fixed, needs a manual check | Tested: `app/test/design/high_contrast_test.dart` (WCAG contrast of both palettes) and the Appearance settings test | While Windows high contrast is on, GodotHub switches to its own black or white high-contrast palette (dark or light follows the theme mode setting) and Appearance settings explains why the chosen theme is not shown. It switches back when high contrast is turned off. The app does not take the exact colors of the Windows contrast theme. Turn high contrast on (Left Alt + Left Shift + Print Screen) once to confirm the switch on a real machine. |

## Linux

| Environment | Result | How it was checked | Notes |
| --- | --- | --- | --- |
| Oldest supported distros (glibc) | Fixed, needs a CI run | Reviewed, CI added | Packages were built on `ubuntu-latest` (24.04, glibc 2.39), the same runner Tauri 1.5.9 used. The stable Linux build now runs on `ubuntu-22.04` (glibc 2.35), fails if any binary needs a newer glibc, and the launch checks add Ubuntu 22.04 and Debian 12. The bridge release workflow must build Linux on `ubuntu-22.04` too. |
| Wayland fractional scaling | Same as Tauri | Reviewed | Both use GTK 3, which scales by whole numbers; the compositor scales fractional settings, which can look soft. |
| Missing libayatana-appindicator | Fixed | Tested: `app/test/window/tray_test.dart` | The tray talks to the desktop over D-Bus and needs no appindicator library, so the app always starts. On desktops with no tray (GNOME without the AppIndicator extension), "minimize to tray" hid the window with no icon to bring it back; it now only hides to the tray when a tray host is running. |
| Read-only home or NFS home | Not tested | Reviewed | The single-instance check uses an abstract socket, not a file in home. A read-only home stops GodotHub from saving anything, as it did for Tauri. Needs a run on an NFS home. |

## macOS

| Environment | Result | How it was checked | Notes |
| --- | --- | --- | --- |
| Case-sensitive APFS volume | Not tested | Reviewed | Needs a run on a case-sensitive volume. |
| Run from Downloads (App Translocation) | Fixed | Tested: `updater::tests::translocated_bundles_are_recognised` | macOS runs such apps from a read-only temporary copy, so an update could not be installed and failed with an unclear error. The updater now says to move GodotHub to Applications first. |
| External display scaling | Not tested | Reviewed | Flutter redraws at the new scale when the window moves to another display. Needs a manual check. |

## Still to run by hand before the bridge release

1. A Windows 10 22H2 machine: install, start, update.
2. A mixed-DPI Windows setup: move the window between monitors, restart, check size and position.
3. Windows on ARM (Windows 11): start the x64 build.
4. The stable packaging workflow, to confirm the Ubuntu 22.04 build, the glibc check and the new launch checks.
5. A Linux NFS home, and GNOME without the AppIndicator extension with "minimize to tray" on.
6. macOS on a case-sensitive volume and with an external display.
