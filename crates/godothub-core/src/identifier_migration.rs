use std::fs;
use std::path::Path;

const LEGACY_IDENTIFIER: &str = "com.ryko.godothub";

const IDENTIFIER_MIGRATION_MARKER: &str = "identifier-migration.done";

#[derive(Debug, Default, PartialEq, Eq)]
pub struct IdentifierMigration {
    pub moved: usize,
    pub kept: usize,
    pub failed: usize,
}

pub fn migrate_app_data(new_dir: &Path, old_dir: &Path) -> IdentifierMigration {
    let mut result = IdentifierMigration::default();
    let Ok(entries) = fs::read_dir(old_dir) else {
        return result;
    };

    for entry in entries.flatten() {
        let from = entry.path();
        let Some(name) = from.file_name().map(|n| n.to_string_lossy().to_string()) else {
            continue;
        };

        let dest = new_dir.join(&name);
        if !dest.exists() {
            match fs::rename(&from, &dest) {
                Ok(()) => result.moved += 1,
                Err(_) => result.failed += 1,
            }
            continue;
        }

        let aside = {
            let mut counter = 0;
            loop {
                let candidate = if counter == 0 {
                    new_dir.join(format!("{name}.legacy"))
                } else {
                    new_dir.join(format!("{name}.legacy-{counter}"))
                };
                if !candidate.exists() {
                    break candidate;
                }
                counter += 1;
            }
        };
        match fs::rename(&from, &aside) {
            Ok(()) => result.kept += 1,
            Err(_) => result.failed += 1,
        }
    }

    result
}

pub fn migrate_identifier(app: &crate::AppHandle) {
    if app.channel() != crate::Channel::Stable {
        return;
    }

    let Ok(new_dir) = app.path().app_data_dir() else {
        return;
    };

    let marker = new_dir.join(IDENTIFIER_MIGRATION_MARKER);
    if marker.exists() {
        return;
    }

    let old_dir = new_dir
        .parent()
        .map(|p| p.join(LEGACY_IDENTIFIER))
        .unwrap_or_default();

    if old_dir == new_dir || !old_dir.exists() {
        return;
    }

    let _ = fs::create_dir_all(&new_dir);
    let result = migrate_app_data(&new_dir, &old_dir);

    let emptied = fs::read_dir(&old_dir)
        .map(|mut entries| entries.next().is_none())
        .unwrap_or(false);
    if emptied {
        let _ = fs::remove_dir(&old_dir);
    }

    let _ = fs::write(
        &marker,
        format!(
            "{} legacy={} moved={} kept={} failed={} old_folder_removed={}\n",
            chrono::Utc::now().to_rfc3339(),
            LEGACY_IDENTIFIER,
            result.moved,
            result.kept,
            result.failed,
            emptied
        ),
    );
}
