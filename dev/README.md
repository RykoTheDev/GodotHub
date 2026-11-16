# dev

Everything here is for working on GodotHub. Nothing in this folder ships in
the app or reaches users.

| Folder | What it holds |
|---|---|
| `tool/` | `ci_local.sh` (the CI checks, locally), i18n conversion and checks, icon, notice and fixture generators, the benchmark, the updater lab and the Windows, macOS and Linux update sandboxes |
| `scripts/` | i18n helpers for the legacy React app, run through `bun run i18n:*` |
| `docs/` | The bridge release runbook and the environment checks |
| `fixtures/` | Data from older GodotHub versions, read by the Rust tests |

Tests stay next to the code they test, where Flutter and Cargo look for them:
`app/test`, `app/integration_test` and the `#[cfg(test)]` modules in the
crates. The user FAQ stays at `docs/migration/FAQ.md` because published
release notes link to it.

Dart tools import the app package, so run them from `app/`:

```bash
cd app
dart run ../dev/tool/i18n_convert.dart && dart run slang
```

Node and shell tools run from the repository root, for example
`bash dev/tool/ci_local.sh`.
