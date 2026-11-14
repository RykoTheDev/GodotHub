use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use crate::Channel;

pub type Storage = BTreeMap<String, String>;

pub fn read_tauri_local_storage() -> Result<Option<Storage>, String> {
    let identifier = Channel::Stable.info().identifier;
    #[cfg(windows)]
    {
        let Some(local) = dirs::data_local_dir() else {
            return Ok(None);
        };
        read_chromium(&local.join(identifier).join("EBWebView").join("Default").join("Local Storage").join("leveldb"))
    }
    #[cfg(not(windows))]
    {
        read_webkit(&webkit_roots(identifier))
    }
}

fn scratch_dir() -> PathBuf {
    std::env::temp_dir().join(format!("godothub-webview-storage-{}", uuid::Uuid::new_v4()))
}

fn utf16le(bytes: &[u8]) -> Option<String> {
    if !bytes.len().is_multiple_of(2) {
        return None;
    }
    let units: Vec<u16> = bytes.as_chunks::<2>().0.iter().map(|pair| u16::from_le_bytes(*pair)).collect();
    String::from_utf16(&units).ok()
}

#[cfg(any(test, windows))]
const CHROMIUM_ORIGINS: [&[u8]; 2] = [b"_http://tauri.localhost\0", b"_https://tauri.localhost\0"];

#[cfg(any(test, windows))]
fn decode_chromium(bytes: &[u8]) -> Option<String> {
    match bytes.split_first()? {
        (0, rest) => utf16le(rest),
        (1, rest) => Some(rest.iter().map(|&byte| char::from(byte)).collect()),
        _ => None,
    }
}

#[cfg(any(test, windows))]
pub(crate) fn read_chromium(dir: &Path) -> Result<Option<Storage>, String> {
    if !dir.join("CURRENT").is_file() {
        return Ok(None);
    }
    let copy = scratch_dir();
    let result = copy_chromium(dir, &copy).and_then(|()| read_chromium_copy(&copy));
    let _ = fs::remove_dir_all(&copy);
    result.map(Some)
}

#[cfg(any(test, windows))]
fn copy_chromium(from: &Path, to: &Path) -> Result<(), String> {
    fs::create_dir_all(to).map_err(|e| e.to_string())?;
    for entry in fs::read_dir(from).map_err(|e| format!("Could not list {}: {e}", from.display()))? {
        let entry = entry.map_err(|e| e.to_string())?;
        if !entry.file_type().map_err(|e| e.to_string())?.is_file() || entry.file_name() == "LOCK" {
            continue;
        }
        fs::copy(entry.path(), to.join(entry.file_name()))
            .map_err(|e| format!("Could not copy {}: {e}", entry.path().display()))?;
    }
    Ok(())
}

#[cfg(any(test, windows))]
fn read_chromium_copy(dir: &Path) -> Result<Storage, String> {
    use rusty_leveldb::{LdbIterator, Options, DB};

    let options = Options { create_if_missing: false, ..Options::default() };
    let mut db = DB::open(dir, options).map_err(|e| format!("Could not open the WebView storage: {e}"))?;
    let mut entries = db.new_iter().map_err(|e| format!("Could not read the WebView storage: {e}"))?;
    let mut storage = Storage::new();
    while let Some((key, value)) = entries.next() {
        let Some(name) = CHROMIUM_ORIGINS.iter().find_map(|origin| key.strip_prefix(*origin)) else {
            continue;
        };
        if let (Some(name), Some(value)) = (decode_chromium(name), decode_chromium(&value)) {
            storage.entry(name).or_insert(value);
        }
    }
    Ok(storage)
}

#[cfg(not(windows))]
fn webkit_roots(identifier: &str) -> Vec<PathBuf> {
    let mut roots = Vec::new();
    if cfg!(target_os = "macos") {
        if let Some(home) = dirs::home_dir() {
            let webkit = home.join("Library").join("WebKit");
            roots.push(webkit.join(identifier).join("WebsiteData"));
            roots.push(webkit.join("godothub").join("WebsiteData"));
        }
    } else {
        for base in [dirs::data_local_dir(), dirs::cache_dir()].into_iter().flatten() {
            let app = base.join(identifier);
            roots.push(app.join("localstorage"));
            roots.push(app.join("storage"));
        }
    }
    roots
}

#[cfg(any(test, not(windows)))]
const WEBKIT_SEARCH_DEPTH: usize = 6;

#[cfg(any(test, not(windows)))]
fn is_tauri_webkit_store(path: &Path) -> bool {
    let Some(name) = path.file_name().and_then(|name| name.to_str()) else {
        return false;
    };
    if name.ends_with(".localstorage") {
        return name.starts_with("tauri_localhost");
    }
    if name != "localstorage.sqlite3" {
        return false;
    }
    let origin = path.parent().and_then(Path::parent).map(|dir| dir.join("origin"));
    match origin.and_then(|file| fs::read(file).ok()) {
        Some(bytes) => bytes.windows(5).any(|window| window == b"tauri"),
        None => true,
    }
}

#[cfg(any(test, not(windows)))]
fn find_webkit_stores(dir: &Path, depth: usize, found: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let Ok(kind) = entry.file_type() else {
            continue;
        };
        let path = entry.path();
        if kind.is_dir() && depth > 0 {
            find_webkit_stores(&path, depth - 1, found);
        } else if kind.is_file() && is_tauri_webkit_store(&path) {
            found.push(path);
        }
    }
}

#[cfg(any(test, not(windows)))]
pub(crate) fn read_webkit(roots: &[PathBuf]) -> Result<Option<Storage>, String> {
    let mut stores = Vec::new();
    for root in roots {
        find_webkit_stores(root, WEBKIT_SEARCH_DEPTH, &mut stores);
    }
    if stores.is_empty() {
        return Ok(None);
    }
    stores.sort();
    let mut storage = Storage::new();
    let mut failure = None;
    let mut read_any = false;
    for store in &stores {
        match read_webkit_store(store) {
            Ok(values) => {
                read_any = true;
                for (key, value) in values {
                    storage.entry(key).or_insert(value);
                }
            }
            Err(error) => failure = Some(error),
        }
    }
    match failure {
        Some(error) if !read_any => Err(error),
        _ => Ok(Some(storage)),
    }
}

#[cfg(any(test, not(windows)))]
fn read_webkit_store(store: &Path) -> Result<Storage, String> {
    let copy = scratch_dir();
    let result = copy_webkit_store(store, &copy).and_then(|file| read_webkit_copy(&file));
    let _ = fs::remove_dir_all(&copy);
    result
}

#[cfg(any(test, not(windows)))]
fn copy_webkit_store(store: &Path, to: &Path) -> Result<PathBuf, String> {
    fs::create_dir_all(to).map_err(|e| e.to_string())?;
    let name = store.file_name().ok_or_else(|| format!("Invalid store path {}", store.display()))?;
    let target = to.join(name);
    fs::copy(store, &target).map_err(|e| format!("Could not copy {}: {e}", store.display()))?;
    for suffix in ["-wal", "-shm"] {
        let mut side = store.as_os_str().to_owned();
        side.push(suffix);
        let side = PathBuf::from(side);
        if side.is_file() {
            let mut side_target = target.as_os_str().to_owned();
            side_target.push(suffix);
            fs::copy(&side, PathBuf::from(side_target)).map_err(|e| format!("Could not copy {}: {e}", side.display()))?;
        }
    }
    Ok(target)
}

#[cfg(any(test, not(windows)))]
fn read_webkit_copy(file: &Path) -> Result<Storage, String> {
    use rusqlite::types::ValueRef;

    let connection = rusqlite::Connection::open(file).map_err(|e| format!("Could not open {}: {e}", file.display()))?;
    let mut query = connection.prepare("SELECT key, value FROM ItemTable").map_err(|e| e.to_string())?;
    let mut rows = query.query([]).map_err(|e| e.to_string())?;
    let mut storage = Storage::new();
    while let Some(row) = rows.next().map_err(|e| e.to_string())? {
        let key = match row.get_ref(0).map_err(|e| e.to_string())? {
            ValueRef::Text(bytes) => String::from_utf8(bytes.to_vec()).ok(),
            ValueRef::Blob(bytes) => utf16le(bytes),
            _ => None,
        };
        let value = match row.get_ref(1).map_err(|e| e.to_string())? {
            ValueRef::Blob(bytes) => utf16le(bytes),
            ValueRef::Text(bytes) => String::from_utf8(bytes.to_vec()).ok(),
            _ => None,
        };
        if let (Some(key), Some(value)) = (key, value) {
            storage.insert(key, value);
        }
    }
    Ok(storage)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fixture() -> PathBuf {
        Path::new(env!("CARGO_MANIFEST_DIR")).join("tests").join("fixtures").join("tauri-1.5.7-local-storage")
    }

    fn snapshot(dir: &Path) -> Vec<(PathBuf, Vec<u8>)> {
        let mut files: Vec<_> = fs::read_dir(dir)
            .unwrap()
            .map(|entry| entry.unwrap().path())
            .map(|path| {
                let bytes = fs::read(&path).unwrap();
                (path, bytes)
            })
            .collect();
        files.sort();
        files
    }

    #[test]
    fn reads_the_tauri_origin_from_a_real_webview_leveldb() {
        let before = snapshot(&fixture());
        let storage = read_chromium(&fixture()).unwrap().unwrap();
        assert_eq!(storage.len(), 25);
        assert_eq!(storage["godothub_projects_view_mode"], "list");
        assert_eq!(storage["godothub_projects_sort_by"], "categories");
        assert_eq!(storage["godothub_version_filters"], r#"{"buildType":"standard","channel":"unstable"}"#);
        assert_eq!(storage["new_ui_sidebar_seen_new_tabs"], r#"["storage","vault"]"#);
        assert_eq!(storage["new_ui_git_sidebar_width"], "328");
        assert_eq!(storage["i18nextLng"], "en-US");
        assert!(!storage.contains_key("godothub_debug_unlocked"));
        assert!(!storage.contains_key("new_ui_sidebar_width"));
        assert_eq!(snapshot(&fixture()), before);
    }

    #[test]
    fn missing_leveldb_reads_as_nothing() {
        assert_eq!(read_chromium(&scratch_dir()).unwrap(), None);
    }

    #[test]
    fn chromium_values_decode_latin1_and_utf16() {
        assert_eq!(decode_chromium(b"\x01caf\xe9").as_deref(), Some("café"));
        assert_eq!(decode_chromium(&[0, 0x3b, 0x04, 0x4e, 0x00]).as_deref(), Some("лN"));
        assert_eq!(decode_chromium(&[2, b'x']), None);
        assert_eq!(decode_chromium(&[]), None);
    }

    fn webkit_store(path: &Path, rows: &[(&str, &str)]) {
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        let connection = rusqlite::Connection::open(path).unwrap();
        connection
            .execute("CREATE TABLE ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB NOT NULL ON CONFLICT FAIL)", [])
            .unwrap();
        for (key, value) in rows {
            let blob: Vec<u8> = value.encode_utf16().flat_map(u16::to_le_bytes).collect();
            connection.execute("INSERT INTO ItemTable (key, value) VALUES (?1, ?2)", rusqlite::params![key, blob]).unwrap();
        }
    }

    #[test]
    fn reads_webkit_stores_for_the_tauri_origin_only() {
        let root = scratch_dir();
        webkit_store(
            &root.join("LocalStorage").join("tauri_localhost_0.localstorage"),
            &[("godothub_projects_view_mode", "list"), ("i18nextLng", "ja-JP")],
        );
        webkit_store(&root.join("LocalStorage").join("http_localhost_1420.localstorage"), &[("i18nextLng", "en-US")]);
        let modern = root.join("Default").join("a1").join("b2");
        webkit_store(&modern.join("LocalStorage").join("localstorage.sqlite3"), &[("new_ui_sidebar_width", "300")]);
        fs::write(modern.join("origin"), b"\x05tauri\x09localhost").unwrap();
        let dev = root.join("Default").join("c3").join("d4");
        webkit_store(&dev.join("LocalStorage").join("localstorage.sqlite3"), &[("new_ui_sidebar_width", "999")]);
        fs::write(dev.join("origin"), b"\x04http\x09localhost").unwrap();

        let storage = read_webkit(std::slice::from_ref(&root)).unwrap().unwrap();
        assert_eq!(storage.get("godothub_projects_view_mode").map(String::as_str), Some("list"));
        assert_eq!(storage.get("i18nextLng").map(String::as_str), Some("ja-JP"));
        assert_eq!(storage.get("new_ui_sidebar_width").map(String::as_str), Some("300"));
        assert_eq!(storage.len(), 3);
        let _ = fs::remove_dir_all(&root);
    }

    #[test]
    fn no_webkit_store_reads_as_nothing() {
        assert_eq!(read_webkit(&[scratch_dir()]).unwrap(), None);
    }
}
