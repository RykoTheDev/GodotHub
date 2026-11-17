# Update path CI

`.github/workflows/flutter-update-paths.yml` proves the macOS and Linux update paths with real signed packages, a throwaway key and a server on 127.0.0.1. Nothing is published and the v2 key is never used. Windows runs in Windows Sandbox through `dev/tool/update_sandbox`.

- Flutter builds use `--dart-define=UPDATER_LAB_AUTO=true` (`lib/api/updater_lab.dart`): the app checks for an update five seconds after start, downloads it, restarts into it, and appends each step to `godothub-updater-lab.txt` in the temp folder. The workflow reads that file to see which version started.
- `build.sh` builds 1.9.0 and 1.9.1, signs every package with the throwaway key (the Tauri CLI `signer` command is used only as the minisign tool) and writes the 1.9.1 manifest. `linux.sh` runs AppImage, deb and rpm (in a Fedora container) from 1.9.0 to 1.9.1; `macos.sh` runs the app bundle swap.
- deb and rpm installs go through `pkexec`; the runner adds a polkit rule so it succeeds without a password prompt.
