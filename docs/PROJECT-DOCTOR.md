# Project Doctor

Open **Project Doctor** from a project's menu in list, grid, or compact views.
Checks run on demand in a blocking worker, without modifying the project or
fetching remote data. Run checks again after making changes outside GodotHub.

The report covers engine availability, project format and recorded Godot feature
version, installed template platforms, `.godot` size and age, main scenes,
editor plugins, effective Git ignore/LFS rules, export resource references, and
duplicate or stale registrations in the active workspace.

## Fix behavior

- Missing engines can be downloaded through the existing download manager.
  Version selection updates the normal project binding; it does not convert
  project formats. Main scenes and migrations are handled in Godot.
- Export templates use the existing chooser and download only selected files.
- Cache cleanup moves `.godot` to Trash. Cache and addon changes require the
  project to be closed, including editors launched outside GodotHub.
- Missing addon entries can be removed. Disabled plugins can be enabled when
  their configured script exists, after confirmation. Other addon folders are
  informational and are not deleted.
- Ignore fixes append rules to the project's `.gitignore`. Metadata untracking
  explicitly stages removal of `.godothub.json`, keeping the local file. It
  refuses to overwrite existing staged edits to that file.
- LFS fixes add literal filename rules with `git lfs track --filename`. They do
  not rewrite history or stage project assets. Users re-add existing assets to
  convert their next revision. Git LFS must already be installed.
- Registration fixes remove library entries only. Project files stay on disk.

Setting and registry backups are stored under the active workspace's
`doctor-backups/<project-id>/<backup-id>/`. Each backend fix reruns diagnosis
before applying the requested finding, and fixes run serially.

## Inspection limits

Each filesystem walk stops after 50,000 entries or five seconds. Binary candidates
are files of at least 50 MiB, classified from an 8 KiB sample, with at most 100
candidates per scan. `.git`, `.godot`,
`.import`, `node_modules`, and `.godothub` are excluded from the project asset
walk; symbolic links are not followed. Cache scans have the same bounds.
Configuration reads are capped at 8 MiB. Partial scans are reported explicitly.

Cache notes use a 1 GiB size threshold and a 30-day age threshold; age does not
imply corruption. Export checks inspect explicit `res://` references, excluding
output paths, wildcard filters, and deliberately excluded resources. Main scenes
stored as `uid://` are recognized as configured but not resolved to a filename.
Template checks confirm platform presence, not completeness of every architecture.
Git checks inspect current files and effective attributes, not commit history.

## Validation

Run `npm run build`, `npm run i18n:check -- --check-values`, and
`cargo check --manifest-path src-tauri/Cargo.toml`.

Rust tests are in `project_health.rs`. Run
`cargo test --manifest-path src-tauri/Cargo.toml --lib project_health::tests`.
If the desktop shell's native runtime prevents its test executable from starting,
`node scripts/test-project-doctor.mjs` runs the same core tests against cached Rust
dependencies without linking Tauri. Set `CARGO_TARGET_DIR` when reusing a build
cache outside this worktree. This isolated runner substitutes app-data template
discovery and omits Tauri command wrappers; the full crate compiler checks those
integration boundaries. Locale files currently use English fallback copy.
