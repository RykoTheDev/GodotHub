# Update path CI

`.github/workflows/flutter-update-paths.yml` proves the macOS and Linux update paths with real signed packages, a throwaway key and a server on 127.0.0.1. Nothing is published and the v2 key is never used. Windows runs in Windows Sandbox through `dev/tool/update_sandbox`.

- Flutter builds use `--dart-define=UPDATER_LAB_AUTO=true` (`lib/api/updater_lab.dart`): the app checks for an update five seconds after start, downloads it, restarts into it, and appends each step to `godothub-updater-lab.txt` in the temp folder. The workflow reads that file to see which version started.
- The Tauri 1.5.9 build is test only: `tauri-auto-update.ts` is appended to `src/main.tsx` inside the runner so it installs the update and relaunches on its own, and `--config` points its updater at the local server and the throwaway key.
- deb and rpm installs go through `pkexec`; the runner adds a polkit rule so it succeeds without a password prompt.
