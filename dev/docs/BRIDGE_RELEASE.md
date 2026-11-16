# Bridge release

The bridge release (1.6.0) is the first GodotHub built with Flutter. It is published where the Tauri updater already looks, so every Tauri user from 1.5.6 on is offered it on the same day. This file covers how to stop that rollout quickly if 1.6.0 turns out to be broken, and how users recover.

## Who reads which feed

| Installed version | Reads | Effect of the bridge release |
| --- | --- | --- |
| Tauri 0.5.0 to 1.5.5 | `latest.json` (frozen, offers 1.5.6) | Updates to 1.5.6 first, then reads `latest-v2.json` |
| Tauri 1.5.6 to 1.5.9 | `latest-v2.json` | Offered 1.6.0 on Windows and Linux. Not offered on macOS (see [macOS](#macos-updates-by-hand-once)) |
| Flutter 1.6.0 and later | `latest-v2.json` | Offered whatever is newer than itself. Macs read the `darwin-*-flutter` entries |
| GodotHub Beta 0.2.5 | `latest-v2.json` (only to see whether 1.6.0 is out) | Shows "GodotHub Beta has ended" once it reports 1.6.0 or later |

All of them fetch `https://github.com/<owner>/GodotHub/releases/latest/download/<feed>`, so the feed attached to the latest release decides what everyone is offered. Apps check once at startup and whenever the user opens Check for Updates.

## Kill switch

`app/packaging/release/kill_switch.sh` swaps `latest-v2.json` on a release. It needs the GitHub CLI signed in with write access to the repository, plus `node` and `curl`.

```bash
bash app/packaging/release/kill_switch.sh status
bash app/packaging/release/kill_switch.sh pause v1.6.0 v1.5.9
bash app/packaging/release/kill_switch.sh resume v1.6.0
```

- `status` prints the latest release and the version its live feed offers.
- `pause v1.6.0 v1.5.9` saves the current feed of v1.6.0 to `kill-switch-backups/v1.6.0-latest-v2.json`, uploads the feed of v1.5.9 to v1.6.0 under the same name, and waits until the public URL serves version 1.5.9. It refuses to run if the replacement is not older than the release, or if a different backup is already there. `--dry-run` shows what it would do.
- `resume v1.6.0` uploads the saved feed again. Usually you do not need it: publishing 1.6.1 replaces the paused release as the latest one.

Run `pause` as soon as reports suggest 1.6.0 is broken. It takes about a minute. Set `REPO=<owner>/GodotHub` if you run it outside the repository folder.

### Also stopping new downloads

`pause` stops update offers, but the website, README and release page still hand out 1.6.0 to people downloading it fresh. If 1.6.0 is broken for everyone, also make the previous release the latest one:

```bash
gh release edit v1.5.9 --latest
```

Now `releases/latest` points at v1.5.9: its own `latest-v2.json` and `latest.json` are served, and the download page lists 1.5.9. Undo it with `gh release edit v1.6.0 --latest`, or simply publish 1.6.1. If a winget or Scoop update for 1.6.0 is still open, close it; if it was merged, the 1.6.1 update supersedes it.

### What users see while the rollout is paused

- **Tauri 1.5.9, not yet updated:** the next check finds nothing new. An update already shown in the open window disappears after a restart. Nobody is moved anywhere.
- **Tauri 1.5.6 to 1.5.8:** offered 1.5.9, the last Tauri version, which is a safe place to wait.
- **Tauri before 1.5.6:** unchanged; they are offered 1.5.6 by the frozen `latest.json`.
- **Already on 1.6.0:** Check for Updates says they are up to date. The updater only ever installs a version newer than the installed one, so a feed that goes back to 1.5.9 never downgrades anyone (tested in `crates/godothub-core/src/updater.rs`, `a_paused_rollout_never_downgrades_any_install`).
- **Downloading 1.6.0 at that moment:** the download finishes, because the 1.6.0 files stay on the release. Do not delete them: the paused feed no longer points at them, and deleting them would only break downloads that are already running.
- **GodotHub Beta:** the "beta has ended" notice waits until a 1.6.0 or later feed is back.

## Recovering users who already have a broken 1.6.0

| Situation | Recovery |
| --- | --- |
| 1.6.0 starts but something is broken | Fix it and publish 1.6.1 through the normal release. 1.6.0 users are offered it in the app; paused Tauri users go straight from 1.5.x to 1.6.1. |
| 1.6.0 does not start (Windows, updated from Tauri) | The launcher can only go back to a Flutter version it installed itself, and the Tauri-to-Flutter update leaves none, so these users cannot update from inside the app. They install 1.6.1 from the release page over 1.6.0, or go back to 1.5.9 (below). Their data is not touched either way. |
| 1.6.0 does not start (macOS, Linux) | Same: install 1.6.1 from the release page, or go back to 1.5.9. |
| A later Flutter update fails to start (Windows setup.exe installs) | The launcher goes back to the previous version by itself and the next start shows "GodotHub closed unexpectedly" with a prefilled bug report. Publish a fix as usual. |

Point affected users to the "How do I go back to the last Tauri version?" and "What if an update fails?" answers in [FAQ.md](../../docs/migration/FAQ.md): uninstall 1.6.0 (the data folder stays), install 1.5.9 from its release page, and leave the update button alone until a fixed version is out.

If 1.6.x cannot be fixed quickly and many users are stuck, the last resort is to rebuild the 1.5.9 Tauri code under a new, higher version number (for example 1.6.2) and release it through the Tauri `release.yml` from git history. Updaters only install higher versions, so this is the only way to move everyone back through the updater. Check that the data written by 1.6.x still loads in that build first.

## Rehearsal with local servers

The update lab rehearses the same steps on this computer with a throwaway signing key, the Windows in-app updater and version numbers standing in for the real ones: 0.0.1 for 1.5.9, 0.0.2 for the bad 1.6.0, and 0.0.3 for the fix 1.6.1. Lab builds keep their data in `app/build/updater_lab/data`, so your real GodotHub data is never touched. Run from `app/`:

```bash
dart run ../dev/tool/updater_lab.dart prepare --from 0.0.1 --to 0.0.2 --fix 0.0.3 --auto
dart run ../dev/tool/updater_lab.dart serve
```

With `--auto` each started copy checks, downloads and restarts by itself and appends a line per step to `%TEMP%\godothub-updater-lab.txt`. In a second terminal (Git Bash):

```bash
export LOCAL_RELEASES=build/updater_lab/releases LOCAL_URL=http://127.0.0.1:47821 MANIFEST=latest.json
dart run ../dev/tool/updater_lab.dart start
bash packaging/release/kill_switch.sh pause 0.0.2 0.0.1
dart run ../dev/tool/updater_lab.dart start
dart run ../dev/tool/updater_lab.dart reset
dart run ../dev/tool/updater_lab.dart start
bash packaging/release/kill_switch.sh resume 0.0.2
bash packaging/release/kill_switch.sh pause 0.0.2 0.0.1
dart run ../dev/tool/updater_lab.dart publish 0.0.3
dart run ../dev/tool/updater_lab.dart reset --version 0.0.2
dart run ../dev/tool/updater_lab.dart start
dart run ../dev/tool/updater_lab.dart reset
dart run ../dev/tool/updater_lab.dart start
```

Close the running copy between steps. Expected results:

1. 0.0.1 updates itself to 0.0.2 (a user who already got the bad release).
2. After `pause`, `status` shows 0.0.1, and 0.0.2 reports `no-update`: nothing is downgraded.
3. A fresh 0.0.1 install also reports `no-update`: users who had not updated stay put.
4. `resume` brings 0.0.2 back, `pause` stops it again.
5. After `publish 0.0.3`, both 0.0.2 and 0.0.1 update straight to 0.0.3.

### Rehearsal result (2026-11-15, Windows 11)

| Step | Live feed | Result |
| --- | --- | --- |
| Bad release out | 0.0.2 | 0.0.1 downloaded 0.0.2, restarted on it, then reported `no-update` |
| `pause 0.0.2 0.0.1` | 0.0.1 within one check | 0.0.2 reported `no-update` (no downgrade); a fresh 0.0.1 reported `no-update` |
| `resume 0.0.2`, `pause` again | 0.0.2, then 0.0.1 | A second `pause` said the rollout was already paused and changed nothing |
| `publish 0.0.3` | 0.0.3 | 0.0.2 and 0.0.1 each downloaded 0.0.3 and restarted on it |
| `pause 0.0.1 0.0.3` | unchanged | Refused: the replacement feed is newer than the release, and the release is not the latest |

## Before the real release

- Build the Linux packages on `ubuntu-22.04`, as the stable packaging workflow does, so they run on glibc 2.35 (Ubuntu 22.04, Debian 12). See [ENVIRONMENTS.md](ENVIRONMENTS.md).
- Make sure `gh` is signed in with write access on the machine you would run the kill switch from, and run `kill_switch.sh status` once so you know it works.
- Keep the v1.5.9 release and its `latest-v2.json` untouched: `pause` copies it.

## Release checklist

`.github/workflows/release.yml` builds and publishes a stable release when a `v*` tag is pushed. It builds the Flutter packages on Windows, macOS and Ubuntu 22.04, refuses builds that still contain test switches, signs the update files with the v2 key (`TAURI_SIGNING_PRIVATE_KEY` and its password), writes the release notes from `changelog.json` (repository root), fails if a download link in the notes has no matching file, writes `latest-v2.json`, uploads the frozen `.github/updater/legacy-latest.json` unchanged as `latest.json`, publishes the release as the latest one and opens the winget update from the MSI. Beta builds keep using `flutter-v*` tags and `flutter-release.yml`.

### Before tagging

- [ ] **Version.** Higher than the last Tauri release (1.5.9), so 1.6.0 for the bridge. Updaters only install higher versions, and the workflow refuses a tag that is not higher than the current latest release.
- [ ] **Version everywhere.** `app/pubspec.yaml` and the `v1.6.0` entry in `changelog.json` at the repository root (`"version": "v1.6.0"`) carry the same number. The workflow fails without a changelog entry.
- [ ] **CI green on `main`.** Flutter CI and the Tauri jobs in `ci.yml` pass on the commit you tag. Run the stable packaging workflow (`flutter-stable-package.yml`) once on that commit too: it rehearses the Tauri-to-Flutter upgrade on all three systems with a throwaway key.
- [ ] **Secrets.** `TAURI_SIGNING_PRIVATE_KEY`, `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` (v2 key) and `WINGET_TOKEN` are set on the repository.
- [ ] **Kill switch ready.** `bash app/packaging/release/kill_switch.sh status` works on the machine you would use.
- [ ] **Scoop pull request drafted** (below), not yet opened.

Tag and push from `main`:

```bash
git tag v1.6.0
git push origin v1.6.0
```

### Release notes and feeds

- Notes keep their format: what's new, the 1.6.0 switch notice, changelog sections, then a divider and `## Downloads`. Every row in the Downloads table is a file the Flutter build uploads; the portable row is `GodotHub-<version>-windows-x64-portable.zip`.
- `check_note_links.mjs` fails the job if any `releases/download` link in the notes points at another repository, another tag or a file that is not uploaded.
- `latest-v2.json` carries the notes without the divider and everything after it, so the update window shows no download table.
- `latest.json` is a byte-for-byte copy of `.github/updater/legacy-latest.json`. Never edit that file: it moves Tauri 0.5.0 to 1.5.5 up to 1.5.6, the first version that reads `latest-v2.json`.

### macOS: updates by hand, once

Flutter needs macOS 12 or newer. The Tauri updater cannot tell which macOS version it runs on, so if it were offered 1.6.0, a Mac on 10.15 or 11 would install an app that does not start.

Decision: **the Tauri updater on a Mac is never offered a Flutter build.** The stable `latest-v2.json` has no `darwin-aarch64`, `darwin-x86_64` or `darwin-universal` entries. The Mac update sits under `darwin-aarch64-flutter`, `darwin-x86_64-flutter` and `darwin-universal-flutter`, which only the Flutter updater looks for (`FLUTTER_ONLY_SUFFIX` in `crates/godothub-core/src/updater.rs`), and `latest_json.mjs` refuses to write a stable feed with a Mac key the Tauri updater would read. Tauri users on macOS 12 or newer download the disk image once; the release notes and the FAQ ("I'm on a Mac. Why didn't GodotHub 1.5 update itself to 1.6?") tell them so. Users on 10.15 or 11 stay on 1.5.9.

- [ ] After publishing, `latest-v2.json` lists only `-flutter` keys for macOS.

### Manual upgrade test after publishing

Start from the last Tauri release on each install type, with a project, a Godot version and a workspace in the data, and check that 1.6.0 starts with all of them. Do this on real machines, not only the CI rehearsal.

| Install type | Start from | Expected |
| --- | --- | --- |
| Windows installer (`setup.exe`) | 1.5.9 from its setup | Offered 1.6.0 in the app, installs, restarts into 1.6.0. `%LOCALAPPDATA%\GodotHub` has `godothub.exe`, `app-1.6.0` and `launcher.json`; Start menu and desktop shortcuts start 1.6.0 |
| Windows MSI | 1.5.9 from its MSI | Offered 1.6.0, Windows Installer finishes, 1.6.0 starts from `C:\Program Files\GodotHub`; one GodotHub entry in Settings → Apps |
| Windows portable | 1.5.9 portable `.exe` | Told about 1.6.0, nothing installed. Unzip the 1.6.0 portable `.zip` and run `godothub.exe`: same data |
| Windows, winget | `winget install Ryko.GodotHub --version 1.5.9` | Once the winget update is merged, `winget upgrade Ryko.GodotHub` installs the 1.6.0 MSI |
| Windows, Scoop | `scoop install godothub` at 1.5.9 | Once the Scoop pull request is merged, `scoop update godothub` installs 1.6.0 and the shortcut starts it |
| macOS 12 or newer | 1.5.9 from its disk image | Check for Updates finds nothing. Install the 1.6.0 disk image over it: same data. Later updates then install in the app |
| macOS 10.15 or 11 | 1.5.9 | Finds nothing, keeps working |
| Linux `.deb` | 1.5.9 `.deb` | Offered 1.6.0, asks for the password, installs into `/usr/lib/godothub`; `godothub` on PATH starts 1.6.0 |
| Linux `.rpm` | 1.5.9 `.rpm` | Same as `.deb` |
| Linux AppImage | 1.5.9 AppImage | Offered 1.6.0, the AppImage replaces itself and starts 1.6.0 |
| Tauri 1.5.5 or older | for example 1.4.8 | Offered 1.5.6 by `latest.json`, then 1.6.0 (Windows, Linux) |
| GodotHub Beta 0.2.5 | next to GodotHub | Shows "GodotHub Beta has ended" with the 1.6.0 link |

### Rolling back

Updaters only install higher versions, so publishing an older release never takes anyone back.

1. Stop the rollout with the kill switch (above).
2. If 1.6.x can be fixed, publish 1.6.1 through this workflow.
3. If it cannot, release the last Tauri code under a new, higher version number. Branch from the v1.5.9 tag, which still has the Tauri `release.yml`; set the version (for example 1.6.2) in `src-tauri/tauri.conf.json`, `src-tauri/Cargo.toml` and `package.json`; add a changelog entry; then tag `v1.6.2` on that branch. That workflow publishes Tauri packages and a `latest-v2.json` with the standard keys, so Flutter installs on Windows and Linux move back to Tauri through their updater. First check that data written by 1.6.x still loads in that build. Afterwards, the next Flutter release must be numbered higher again (1.6.3 or later).

```bash
git switch -c rollback-tauri v1.5.9
```

### Scoop

The ScoopInstaller/Extras manifest `bucket/godothub.json` downloads `GodotHub-$version-windows-x64-portable.exe` and renames it to `GodotHub.exe`, in both `url` and `autoupdate`. From 1.6.0 the portable build is a `.zip`, so Scoop's autoupdate would look for a file that does not exist. Open a pull request to ScoopInstaller/Extras as soon as the 1.6.0 release is published (not before: Scoop's checks download the file). It changes both URLs to the zip and keeps the GodotHub shortcut. The zip has `godothub.exe` at its root, so no `extract_dir` is needed, and the hash is the SHA-256 of the uploaded zip.

```json
{
    "version": "1.6.0",
    "description": "The Ultimate Project Manager for Godot Engine.",
    "homepage": "https://ryko.is-a.dev/godothub",
    "license": "MIT",
    "architecture": {
        "64bit": {
            "url": "https://github.com/Rykode/GodotHub/releases/download/v1.6.0/GodotHub-1.6.0-windows-x64-portable.zip",
            "hash": "<sha256 of GodotHub-1.6.0-windows-x64-portable.zip>"
        }
    },
    "shortcuts": [
        [
            "godothub.exe",
            "GodotHub"
        ]
    ],
    "checkver": {
        "github": "https://github.com/Rykode/GodotHub"
    },
    "autoupdate": {
        "architecture": {
            "64bit": {
                "url": "https://github.com/Rykode/GodotHub/releases/download/v$version/GodotHub-$version-windows-x64-portable.zip"
            }
        }
    }
}
```

- [ ] Hash taken from the published zip: `sha256sum GodotHub-1.6.0-windows-x64-portable.zip`.
- [ ] If Scoop's bot already tried 1.6.0 with the old `.exe` URL and failed, say so in the pull request.
