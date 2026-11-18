//! Joins the per-version files in `changelog/` (repository root) into one
//! JSON array that `src/changelog.rs` embeds. A file that is not valid JSON,
//! or whose name does not match its version, fails the build.

use std::{env, fs, path::PathBuf};

fn main() {
    let dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap()).join("../../changelog");
    println!("cargo:rerun-if-changed={}", dir.display());

    let mut paths: Vec<PathBuf> = fs::read_dir(&dir)
        .unwrap_or_else(|e| panic!("cannot read {}: {e}", dir.display()))
        .map(|entry| entry.unwrap().path())
        .filter(|path| path.extension().is_some_and(|ext| ext == "json"))
        .collect();
    paths.sort();

    let mut entries = Vec::with_capacity(paths.len());
    for path in &paths {
        let text = fs::read_to_string(path).unwrap_or_else(|e| panic!("cannot read {}: {e}", path.display()));
        let entry: serde_json::Value =
            serde_json::from_str(&text).unwrap_or_else(|e| panic!("{} is not valid JSON: {e}", path.display()));
        let version = entry["version"].as_str().unwrap_or_default().trim();
        let tag = version.split(' ').next().unwrap_or_default();
        let stem = path.file_stem().unwrap().to_string_lossy();
        if tag.is_empty() || tag != stem {
            panic!("{} has version {version:?}; the file must be named after it ({tag}.json)", path.display());
        }
        entries.push(entry);
    }

    let out = PathBuf::from(env::var("OUT_DIR").unwrap()).join("changelog.json");
    fs::write(out, serde_json::to_string(&entries).unwrap()).unwrap();
}
