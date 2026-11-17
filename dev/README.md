# dev

Everything here is for working on GodotHub. Nothing in this folder ships in
the app or reaches users.

| Folder | What it holds |
|---|---|
| `tool/` | `ci_local.sh` (the CI checks, locally), the i18n checks (`i18n/`), the third-party Rust notices generator (`gen_rust_notices.mjs`), the collation table and date fixture generators, the benchmark (`bench/`), the updater lab (`updater_lab.dart`), the update path CI scripts (`update_ci/`) and the Windows update sandbox (`update_sandbox/`) |
| `docs/` | The bridge release runbook and the environment checks |
| `fixtures/` | Data from older GodotHub versions, read by the Rust tests |

Tests stay next to the code they test, where Flutter and Cargo look for them:
`app/test`, `app/integration_test` and the `#[cfg(test)]` modules in the
crates. The user FAQ stays at `docs/migration/FAQ.md` because published
release notes link to it.

Dart tools import the app package, so run them from `app/`:

```bash
cd app
dart run ../dev/tool/i18n/check_keys.dart --check-values
```

Node and shell tools run from the repository root, for example
`bash dev/tool/ci_local.sh` or `node dev/tool/gen_rust_notices.mjs`.

Some committed files came from generators that have since been removed: the
test fixtures in `app/test/fixtures` other than `intl_dates.json` (which
`gen_date_fixtures.ts` still writes) are fixed test data now, and new Font
Awesome icons are added to `app/lib/design/icons.g.dart` by hand.
