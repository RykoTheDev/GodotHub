//! Seekable HTTP access lets the ZIP crate discover the release's actual files
//! and CRC-check selected entries without downloading the entire TPZ bundle.
use super::*;
use serde::Deserialize;
use std::io::{self, Seek, SeekFrom};

#[derive(Clone, Serialize, Deserialize)]
pub struct TemplateFile {
    pub name: String,
    pub size_bytes: u64,
    pub download_bytes: u64,
    pub installed: bool,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct TemplateOption {
    pub id: String,
    pub label: String,
    pub files: Vec<TemplateFile>,
    pub size_bytes: u64,
    pub download_bytes: u64,
    pub installed: bool,
}

fn platform(path: &Path) -> Option<(String, String)> {
    let name = path
        .components()
        .next()?
        .as_os_str()
        .to_str()?
        .to_ascii_lowercase();
    if name == "version.txt" {
        return None;
    }
    let known = if name.starts_with("windows")
        || name.starts_with("win32")
        || name.starts_with("win64")
    {
        ("windows", "Windows")
    } else if name.starts_with("linux") || name.starts_with("x11") {
        ("linux", "Linux")
    } else if name.starts_with("macos") || name.starts_with("osx") {
        ("macos", "macOS")
    } else if name.starts_with("android") {
        ("android", "Android")
    } else if name.starts_with("ios") || name.starts_with("iphone") {
        ("ios", "iOS")
    } else if name.starts_with("web") || name.starts_with("javascript") || name.starts_with("html5")
    {
        ("web", "Web")
    } else if name.starts_with("uwp") {
        ("uwp", "UWP")
    } else if name.starts_with("visionos") {
        ("visionos", "visionOS")
    } else if name.starts_with("tvos") {
        ("tvos", "tvOS")
    } else if name.starts_with("server") {
        ("server", "Server")
    } else if name.starts_with("icudt") {
        ("icu", "ICU Data")
    } else {
        // New or less common targets remain selectable rather than disappearing.
        let id = name
            .split(['_', '.', '-'])
            .next()
            .unwrap_or(&name)
            .to_string();
        return Some((id.clone(), id));
    };
    Some((known.0.into(), known.1.into()))
}

pub fn installed_platforms(dir: &Path) -> Vec<String> {
    let mut result = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let Ok(kind) = entry.file_type() else {
                continue;
            };
            if kind.is_symlink() || (kind.is_dir() && dir_stats(&entry.path()).1 == 0) {
                continue;
            }
            if let Some((_, label)) = platform(Path::new(&entry.file_name())) {
                if !result.contains(&label) {
                    result.push(label);
                }
            }
        }
    }
    result.sort();
    result
}

struct Transfer {
    app: Option<AppHandle>,
    tag: String,
    platforms: Vec<String>,
    file: Option<String>,
    downloaded: u64,
    total: u64,
    last_emit: Instant,
    enabled: bool,
    payload_end: Option<u64>,
}

impl Transfer {
    fn emit(&mut self, force: bool) {
        if force || self.last_emit.elapsed() >= PROGRESS_INTERVAL {
            self.last_emit = Instant::now();
            if let Some(app) = &self.app {
                let _ = app.emit(
                    "export-templates-progress",
                    ExportTemplatesProgress {
                        tag: self.tag.clone(),
                        downloaded: self.downloaded.min(self.total),
                        total: self.total,
                        file: self.file.clone(),
                        platforms: self.platforms.clone(),
                    },
                );
            }
        }
    }
}

struct HttpArchive {
    client: reqwest::Client,
    runtime: tokio::runtime::Handle,
    url: String,
    length: u64,
    position: u64,
    tail_start: u64,
    tail: Vec<u8>,
    block_start: u64,
    block: Vec<u8>,
    cancel: Arc<AtomicBool>,
    transfer: Option<Arc<Mutex<Transfer>>>,
    validator: Option<String>,
}

impl HttpArchive {
    fn open(
        url: &str,
        runtime: tokio::runtime::Handle,
        cancel: Arc<AtomicBool>,
    ) -> Result<Self, String> {
        if cancel.load(Ordering::SeqCst) {
            return Err("__canceled__".into());
        }
        let client = reqwest::Client::builder()
            .user_agent("godot-hub")
            .timeout(Duration::from_secs(30))
            .build()
            .map_err(|e| e.to_string())?;
        let (start, length, tail, validator, resolved_url) = runtime.block_on(async {
            // Some mirrors/proxies reject suffix ranges. Probe the length with
            // one byte, then request the directory tail using explicit offsets.
            let response = client.get(url).header(reqwest::header::RANGE, "bytes=0-0")
                .header(reqwest::header::ACCEPT_ENCODING, "identity")
                .send().await.map_err(|e| e.to_string())?;
            if response.status() != reqwest::StatusCode::PARTIAL_CONTENT {
                return Err(format!("Could not read template options (HTTP {}). The server must support partial downloads.", response.status()));
            }
            let range = response.headers().get(reqwest::header::CONTENT_RANGE)
                .and_then(|h| h.to_str().ok()).ok_or("Missing archive range information")?;
            let length = parse_content_range_total(range).ok_or("Invalid archive size")?;
            if parse_content_range_start(range) != Some(0) || length == 0 {
                return Err("Invalid archive range response".into());
            }
            let validator = response.headers().get(reqwest::header::ETAG)
                .or_else(|| response.headers().get(reqwest::header::LAST_MODIFIED))
                .and_then(|h| h.to_str().ok()).map(str::to_string);
            let resolved_url = response.url().to_string();
            let probe = response.bytes().await.map_err(|e| e.to_string())?;
            if probe.len() != 1 { return Err("Invalid archive range response".into()); }
            if cancel.load(Ordering::SeqCst) { return Err("__canceled__".into()); }
            let start = length.saturating_sub(131072);
            let mut request = client.get(&resolved_url)
                .header(reqwest::header::RANGE, format!("bytes={start}-{}", length - 1))
                .header(reqwest::header::ACCEPT_ENCODING, "identity");
            if let Some(validator) = &validator { request = request.header(reqwest::header::IF_RANGE, validator); }
            let response = request.send().await.map_err(|e| e.to_string())?;
            let range = response.headers().get(reqwest::header::CONTENT_RANGE).and_then(|h| h.to_str().ok());
            if response.status() != reqwest::StatusCode::PARTIAL_CONTENT
                || range.and_then(parse_content_range_start) != Some(start)
                || range.and_then(parse_content_range_total) != Some(length) {
                return Err(format!("Could not read template options (HTTP {}). The archive changed or the server did not honor the requested range.", response.status()));
            }
            let tail = response.bytes().await.map_err(|e| e.to_string())?.to_vec();
            if length == 0 || tail.len() > 131072 || start + tail.len() as u64 != length {
                return Err("Invalid archive range response".into());
            }
            Ok((start, length, tail, validator, resolved_url))
        })?;
        Ok(Self {
            client,
            runtime,
            url: resolved_url,
            length,
            position: 0,
            tail_start: start,
            tail,
            block_start: 0,
            block: Vec::new(),
            cancel,
            transfer: None,
            validator,
        })
    }
}

impl Read for HttpArchive {
    fn read(&mut self, output: &mut [u8]) -> io::Result<usize> {
        if self.cancel.load(Ordering::SeqCst) {
            return Err(io::Error::other("__canceled__"));
        }
        if output.is_empty() || self.position >= self.length {
            return Ok(0);
        }
        let in_tail = self.position >= self.tail_start;
        if !in_tail
            && !(self.position >= self.block_start
                && self.position < self.block_start + self.block.len() as u64)
        {
            let start = self.position;
            let transfer_range = self.transfer.as_ref().and_then(|transfer| {
                transfer
                    .lock()
                    .ok()
                    .map(|progress| (progress.enabled, progress.payload_end))
            });
            let (block_size, payload_end) = match transfer_range {
                Some((true, end)) => (4 * 1024 * 1024, end),
                _ => (4096, None),
            };
            let end = (start + block_size - 1)
                .min(self.length - 1)
                .min(payload_end.unwrap_or(self.length - 1));
            self.block = self.runtime.block_on(async {
                let mut request = self.client.get(&self.url)
                    .header(reqwest::header::RANGE, format!("bytes={start}-{end}"))
                    .header(reqwest::header::ACCEPT_ENCODING, "identity");
                if let Some(validator) = &self.validator { request = request.header(reqwest::header::IF_RANGE, validator); }
                let response = request.send().await.map_err(io::Error::other)?;
                let range = response.headers().get(reqwest::header::CONTENT_RANGE).and_then(|h| h.to_str().ok());
                if response.status() != reqwest::StatusCode::PARTIAL_CONTENT
                    || range.and_then(parse_content_range_start) != Some(start)
                    || range.and_then(parse_content_range_total) != Some(self.length) {
                    return Err(io::Error::other("The template archive changed or could not be downloaded partially. Try again."));
                }
                let bytes = response.bytes().await.map_err(io::Error::other)?.to_vec();
                if bytes.len() as u64 != end - start + 1 { return Err(io::Error::other("Incomplete template download")); }
                Ok(bytes)
            })?;
            self.block_start = start;
        }
        let (data, start) = if in_tail {
            (&self.tail, self.tail_start)
        } else {
            (&self.block, self.block_start)
        };
        let offset = (self.position - start) as usize;
        let count = output.len().min(data.len() - offset);
        output[..count].copy_from_slice(&data[offset..offset + count]);
        self.position += count as u64;
        if let Some(transfer) = &self.transfer {
            let mut progress = transfer
                .lock()
                .map_err(|e| io::Error::other(e.to_string()))?;
            if progress.enabled {
                progress.downloaded += count as u64;
                progress.emit(false);
            }
        }
        Ok(count)
    }
}

impl Seek for HttpArchive {
    fn seek(&mut self, from: SeekFrom) -> io::Result<u64> {
        let position = match from {
            SeekFrom::Start(offset) => i128::from(offset),
            SeekFrom::Current(offset) => i128::from(self.position) + i128::from(offset),
            SeekFrom::End(offset) => i128::from(self.length) + i128::from(offset),
        };
        self.position =
            u64::try_from(position).map_err(|_| io::Error::other("Invalid archive offset"))?;
        Ok(self.position)
    }
}

fn inspect<R: Read + Seek>(
    archive: &mut zip::ZipArchive<R>,
    destination: &Path,
) -> Result<Vec<TemplateOption>, String> {
    let mut options: Vec<TemplateOption> = Vec::new();
    let mut total = 0u64;
    for index in 0..archive.len() {
        let entry = archive.by_index(index).map_err(|e| e.to_string())?;
        if !entry.is_file() {
            continue;
        }
        let path = entry
            .enclosed_name()
            .ok_or("Unsafe template archive path")?;
        let relative = strip_templates_prefix(&path);
        let Some((id, label)) = platform(&relative) else {
            continue;
        };
        total = total.saturating_add(entry.size());
        if total > MAX_EXTRACTED_BYTES {
            return Err("Template archive exceeds the expected size".into());
        }
        let installed = fs::metadata(destination.join(&relative))
            .is_ok_and(|meta| meta.is_file() && meta.len() == entry.size());
        let file = TemplateFile {
            name: relative.to_string_lossy().replace('\\', "/"),
            size_bytes: entry.size(),
            download_bytes: entry.compressed_size(),
            installed,
        };
        if let Some(option) = options.iter_mut().find(|option| option.id == id) {
            option.size_bytes += file.size_bytes;
            option.download_bytes += file.download_bytes;
            option.installed &= installed;
            option.files.push(file);
        } else {
            options.push(TemplateOption {
                id: id.into(),
                label: label.into(),
                size_bytes: file.size_bytes,
                download_bytes: file.download_bytes,
                installed,
                files: vec![file],
            });
        }
    }
    options.sort_by(|a, b| a.label.cmp(&b.label));
    if options.is_empty() {
        return Err("This release has no export templates available".into());
    }
    Ok(options)
}

pub fn options(
    url: &str,
    destination: &Path,
    runtime: tokio::runtime::Handle,
) -> Result<Vec<TemplateOption>, String> {
    let reader = HttpArchive::open(url, runtime, Arc::new(AtomicBool::new(false)))?;
    let mut archive = zip::ZipArchive::new(reader)
        .map_err(|e| format!("Could not read template archive: {e}"))?;
    inspect(&mut archive, destination)
}

#[derive(Serialize, Deserialize)]
struct CachedCatalog {
    schema: u32,
    url: String,
    options: Vec<TemplateOption>,
}

fn refresh_installed(options: &mut [TemplateOption], destination: &Path) {
    for option in options {
        for file in &mut option.files {
            file.installed = fs::metadata(destination.join(&file.name))
                .is_ok_and(|metadata| metadata.is_file() && metadata.len() == file.size_bytes);
        }
        option.installed = option.files.iter().all(|file| file.installed);
    }
}

fn valid_catalog(catalog: &CachedCatalog, url: &str) -> bool {
    catalog.schema == 1
        && catalog.url == url
        && !catalog.options.is_empty()
        && catalog.options.iter().all(|option| {
            !option.files.is_empty()
                && option.files.iter().all(|file| {
                    !file.name.contains(['\\', ':'])
                        && !file
                            .name
                            .split('/')
                            .any(|part| matches!(part, "" | "." | ".."))
                        && Path::new(&file.name)
                            .components()
                            .all(|part| matches!(part, Component::Normal(_)))
                        && file.size_bytes <= MAX_EXTRACTED_BYTES
                })
        })
}

pub fn cached_options(
    url: &str,
    destination: &Path,
    cache_path: &Path,
    runtime: tokio::runtime::Handle,
    refresh: bool,
) -> Result<Vec<TemplateOption>, String> {
    if !refresh {
        if let Some(mut catalog) = fs::read(cache_path)
            .ok()
            .and_then(|bytes| serde_json::from_slice::<CachedCatalog>(&bytes).ok())
            .filter(|catalog| valid_catalog(catalog, url))
        {
            // Cache only the release manifest; installed flags always come
            // from disk so imports, removals and external installs stay current.
            refresh_installed(&mut catalog.options, destination);
            return Ok(catalog.options);
        }
    }
    let options = options(url, destination, runtime)?;
    let mut metadata = options.clone();
    for option in &mut metadata {
        option.installed = false;
        for file in &mut option.files {
            file.installed = false;
        }
    }
    let catalog = CachedCatalog {
        schema: 1,
        url: url.to_string(),
        options: metadata,
    };
    // Failure to persist must not prevent downloading templates. A unique
    // staging file keeps concurrent refreshes and interrupted writes safe.
    if let (Some(parent), Ok(bytes)) = (cache_path.parent(), serde_json::to_vec(&catalog)) {
        if fs::create_dir_all(parent).is_ok() {
            let staging = parent.join(format!(".{}.tmp", uuid::Uuid::new_v4()));
            if fs::write(&staging, bytes).is_ok() {
                let _ = fs::rename(&staging, cache_path);
            }
            let _ = fs::remove_file(staging);
        }
    }
    Ok(options)
}

fn copy_existing(source: &Path, destination: &Path, cancel: &AtomicBool) -> Result<(), String> {
    if !source.is_dir() {
        return Ok(());
    }
    for entry in fs::read_dir(source).map_err(|e| e.to_string())? {
        if cancel.load(Ordering::SeqCst) {
            return Err("__canceled__".into());
        }
        let entry = entry.map_err(|e| e.to_string())?;
        let kind = entry.file_type().map_err(|e| e.to_string())?;
        let target = destination.join(entry.file_name());
        if kind.is_dir() {
            fs::create_dir_all(&target).map_err(|e| e.to_string())?;
            copy_existing(&entry.path(), &target, cancel)?;
        } else if kind.is_file() {
            fs::copy(entry.path(), target).map_err(|e| e.to_string())?;
        }
    }
    Ok(())
}

/// Resolve the entire removal batch before changing any files. Uninstall works
/// offline and cannot remove directories, shared version metadata or symlinks.
pub fn removal_paths(directory: &Path, files: &[String]) -> Result<Vec<PathBuf>, String> {
    if files.is_empty() {
        return Err("Choose at least one installed template".into());
    }
    if fs::symlink_metadata(directory)
        .map_err(|error| error.to_string())?
        .file_type()
        .is_symlink()
    {
        return Err("Refusing to uninstall through a linked template folder".into());
    }
    let root = directory
        .canonicalize()
        .map_err(|error| error.to_string())?;
    let mut paths = Vec::new();
    for name in files {
        let normalized = name.replace('\\', "/");
        if normalized.contains(':')
            || normalized
                .split('/')
                .any(|part| matches!(part, "" | "." | ".."))
        {
            return Err("Invalid export template file name".into());
        }
        let relative = Path::new(&normalized);
        if !relative
            .components()
            .all(|part| matches!(part, Component::Normal(_)))
            || platform(relative).is_none()
        {
            return Err("Invalid export template file name".into());
        }
        let mut path = root.clone();
        for component in relative.components() {
            path.push(component.as_os_str());
            if fs::symlink_metadata(&path)
                .map_err(|error| error.to_string())?
                .file_type()
                .is_symlink()
            {
                return Err("Refusing to uninstall through a linked template path".into());
            }
        }
        if !path.is_file()
            || !path
                .canonicalize()
                .map_err(|error| error.to_string())?
                .starts_with(&root)
        {
            return Err("This template file is not installed".into());
        }
        if !paths.contains(&path) {
            paths.push(path);
        }
    }
    Ok(paths)
}

#[allow(clippy::too_many_arguments)]
pub fn install(
    url: &str,
    root: &Path,
    folder: &str,
    selected: &[String],
    app: Option<AppHandle>,
    tag: String,
    cancel: Arc<AtomicBool>,
    runtime: tokio::runtime::Handle,
) -> Result<(u64, usize), String> {
    if selected.is_empty() {
        return Err("Choose at least one export template".into());
    }
    let transfer = Arc::new(Mutex::new(Transfer {
        app: app.clone(),
        tag: tag.clone(),
        platforms: Vec::new(),
        file: None,
        downloaded: 0,
        total: 0,
        last_emit: Instant::now() - PROGRESS_INTERVAL,
        enabled: false,
        payload_end: None,
    }));
    let mut reader = HttpArchive::open(url, runtime, cancel.clone())?;
    reader.transfer = Some(transfer.clone());
    let mut archive = zip::ZipArchive::new(reader).map_err(|e| e.to_string())?;
    let options = inspect(&mut archive, &root.join(folder))?;
    let selected: HashSet<&str> = selected.iter().map(String::as_str).collect();
    if selected.iter().any(|name| {
        !options
            .iter()
            .flat_map(|option| &option.files)
            .any(|file| file.name == *name)
    }) {
        return Err("A selected template is not available for this Godot release".into());
    }
    if options
        .iter()
        .flat_map(|option| &option.files)
        .any(|file| file.installed && selected.contains(file.name.as_str()))
    {
        return Err(
            "Selected templates are already installed. Uninstall them before downloading again."
                .into(),
        );
    }
    transfer.lock().map_err(|e| e.to_string())?.total = options
        .iter()
        .flat_map(|option| &option.files)
        .filter(|file| selected.contains(file.name.as_str()))
        .map(|file| file.download_bytes)
        .sum();
    transfer.lock().map_err(|e| e.to_string())?.platforms = options
        .iter()
        .filter(|option| {
            option
                .files
                .iter()
                .any(|file| selected.contains(file.name.as_str()))
        })
        .map(|option| option.label.clone())
        .collect();
    fs::create_dir_all(root).map_err(|e| e.to_string())?;
    let target = root.join(folder);
    let staging = root.join(format!(".{folder}.installing"));
    let previous = root.join(format!(".{folder}.previous"));
    if !target.exists() && previous.exists() {
        fs::rename(&previous, &target).map_err(|e| e.to_string())?;
    }
    if staging.exists() {
        fs::remove_dir_all(&staging).map_err(|e| e.to_string())?;
    }
    fs::create_dir_all(&staging).map_err(|e| e.to_string())?;
    let result = (|| {
        copy_existing(&target, &staging, &cancel)?;
        let mut extracted = 0u64;
        for index in 0..archive.len() {
            let mut entry = archive.by_index(index).map_err(|e| e.to_string())?;
            if !entry.is_file() {
                continue;
            }
            let path = entry
                .enclosed_name()
                .ok_or("Unsafe template archive path")?;
            let relative = strip_templates_prefix(&path);
            if relative.as_os_str().is_empty() {
                continue;
            }
            if platform(&relative).is_some() {
                if !selected.contains(relative.to_string_lossy().replace('\\', "/").as_str()) {
                    continue;
                }
            }
            if cancel.load(Ordering::SeqCst) {
                return Err("__canceled__".into());
            }
            {
                let mut progress = transfer.lock().map_err(|e| e.to_string())?;
                progress.file = Some(relative.to_string_lossy().into());
                progress.enabled = platform(&relative).is_some();
                progress.payload_end = entry
                    .data_start()
                    .and_then(|start| start.checked_add(entry.compressed_size()))
                    .and_then(|end| end.checked_sub(1));
                progress.emit(true);
            }
            let output = staging.join(&relative);
            if let Some(parent) = output.parent() {
                fs::create_dir_all(parent).map_err(|e| e.to_string())?;
            }
            let mut output = fs::File::create(&output).map_err(|e| e.to_string())?;
            // Reading to EOF checks each selected file's CRC. No whole-bundle
            // SHA512 claim is made for a partial download.
            let mut buffer = vec![0; 128 * 1024];
            loop {
                if cancel.load(Ordering::SeqCst) {
                    return Err("__canceled__".into());
                }
                let count = entry.read(&mut buffer).map_err(|e| e.to_string())?;
                if count == 0 {
                    break;
                }
                extracted = extracted.saturating_add(count as u64);
                if extracted > MAX_EXTRACTED_BYTES {
                    return Err("Template archive exceeds the expected size".into());
                }
                output
                    .write_all(&buffer[..count])
                    .map_err(|e| e.to_string())?;
            }
            #[cfg(unix)]
            if let Some(mode) = entry.unix_mode() {
                use std::os::unix::fs::PermissionsExt;
                fs::set_permissions(
                    staging.join(&relative),
                    fs::Permissions::from_mode(mode & 0o777),
                )
                .map_err(|e| e.to_string())?;
            }
            transfer.lock().map_err(|e| e.to_string())?.enabled = false;
        }
        if cancel.load(Ordering::SeqCst) {
            return Err("__canceled__".into());
        }
        if let Some(app) = &app {
            let _ = app.emit(
                "export-templates-stage",
                ExportTemplatesStage {
                    tag,
                    stage: "extracting".into(),
                },
            );
        }
        if previous.exists() {
            fs::remove_dir_all(&previous).map_err(|e| e.to_string())?;
        }
        if target.exists() {
            fs::rename(&target, &previous).map_err(|e| e.to_string())?;
        }
        if let Err(error) = fs::rename(&staging, &target) {
            if previous.exists() {
                let _ = fs::rename(&previous, &target);
            }
            return Err(format!("Could not finish installing templates: {error}"));
        }
        let _ = fs::remove_dir_all(&previous);
        Ok(dir_stats(&target))
    })();
    if result.is_err() {
        let _ = fs::remove_dir_all(&staging);
    }
    if cancel.load(Ordering::SeqCst) && result.is_err() {
        return Err("__canceled__".into());
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;
    use std::net::TcpListener;
    use std::sync::atomic::AtomicU64;

    fn fixture() -> Vec<u8> {
        let mut writer = zip::ZipWriter::new(Cursor::new(Vec::new()));
        let options = zip::write::SimpleFileOptions::default()
            .compression_method(zip::CompressionMethod::Stored);
        for (name, content) in [
            (
                "templates/windows_debug_x86_64.exe",
                b"windows debug".to_vec(),
            ),
            (
                "templates/windows_release_x86_64.exe",
                b"windows release".to_vec(),
            ),
            (
                "templates/windows_debug_x86_32.exe",
                b"windows x86 debug".to_vec(),
            ),
            (
                "templates/windows_release_arm64.exe",
                b"windows arm release".to_vec(),
            ),
            ("templates/android_debug.apk", vec![42; 4 * 1024 * 1024]),
            ("templates/linux_debug.x86_64", b"linux debug".to_vec()),
            ("templates/version.txt", b"4.5.stable".to_vec()),
        ] {
            writer.start_file(name, options).unwrap();
            writer.write_all(&content).unwrap();
        }
        writer.finish().unwrap().into_inner()
    }

    struct Server {
        url: String,
        bytes: Arc<AtomicU64>,
        stopped: Arc<AtomicBool>,
        thread: Option<std::thread::JoinHandle<()>>,
    }

    impl Drop for Server {
        fn drop(&mut self) {
            self.stopped.store(true, Ordering::SeqCst);
            if let Some(thread) = self.thread.take() {
                thread.join().unwrap();
            }
        }
    }

    fn server(archive: Vec<u8>, bad_range: bool) -> Server {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let url = format!("http://{}/templates.tpz", listener.local_addr().unwrap());
        listener.set_nonblocking(true).unwrap();
        let bytes = Arc::new(AtomicU64::new(0));
        let counter = bytes.clone();
        let stopped = Arc::new(AtomicBool::new(false));
        let stop = stopped.clone();
        let thread = std::thread::spawn(move || {
            while !stop.load(Ordering::SeqCst) {
                let Ok((mut socket, _)) = listener.accept() else {
                    std::thread::sleep(Duration::from_millis(5));
                    continue;
                };
                socket.set_nonblocking(false).unwrap();
                socket
                    .set_read_timeout(Some(Duration::from_secs(5)))
                    .unwrap();
                let mut request = Vec::new();
                let mut buffer = [0u8; 1024];
                while !request.windows(4).any(|part| part == b"\r\n\r\n") {
                    let count = socket.read(&mut buffer).unwrap();
                    if count == 0 {
                        break;
                    }
                    request.extend_from_slice(&buffer[..count]);
                }
                let request = String::from_utf8(request).unwrap().to_ascii_lowercase();
                let range = request
                    .lines()
                    .find_map(|line| line.strip_prefix("range: bytes="))
                    .unwrap();
                let (start, end) = if let Some(suffix) = range.strip_prefix('-') {
                    (
                        archive
                            .len()
                            .saturating_sub(suffix.parse::<usize>().unwrap()),
                        archive.len() - 1,
                    )
                } else {
                    let (start, end) = range.split_once('-').unwrap();
                    (
                        start.parse::<usize>().unwrap(),
                        end.parse::<usize>().unwrap().min(archive.len() - 1),
                    )
                };
                let body = &archive[start..=end];
                let reported_start = if bad_range { start + 1 } else { start };
                let header = format!("HTTP/1.1 206 Partial Content\r\nContent-Range: bytes {reported_start}-{end}/{}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n", archive.len(), body.len());
                socket.write_all(header.as_bytes()).unwrap();
                let _ = socket.write_all(body);
                counter.fetch_add(body.len() as u64, Ordering::SeqCst);
            }
        });
        Server {
            url,
            bytes,
            stopped,
            thread: Some(thread),
        }
    }

    #[test]
    fn discovers_real_platforms_and_reads_only_selected_payloads() {
        let data = fixture();
        let length = data.len() as u64;
        let server = server(data, false);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let reader = HttpArchive::open(
            &server.url,
            runtime.handle().clone(),
            Arc::new(AtomicBool::new(false)),
        )
        .unwrap();
        let mut archive = zip::ZipArchive::new(reader).unwrap();
        let destination =
            std::env::temp_dir().join(format!("godothub-templates-{}", uuid::Uuid::new_v4()));
        fs::create_dir_all(&destination).unwrap();
        fs::write(
            destination.join("windows_debug_x86_64.exe"),
            b"windows debug",
        )
        .unwrap();
        let options = inspect(&mut archive, &destination).unwrap();
        assert_eq!(
            options
                .iter()
                .map(|option| option.id.as_str())
                .collect::<Vec<_>>(),
            vec!["android", "linux", "windows"]
        );
        let windows = options
            .iter()
            .find(|option| option.id == "windows")
            .unwrap();
        assert_eq!(windows.files.len(), 4);
        assert!(windows.files[0].installed);
        assert!(!windows.installed); // One architecture/build file is not a full platform.
        let mut content = String::new();
        archive
            .by_name("templates/windows_release_x86_64.exe")
            .unwrap()
            .read_to_string(&mut content)
            .unwrap();
        assert_eq!(content, "windows release");
        assert!(
            server.bytes.load(Ordering::SeqCst) < length / 4,
            "catalog discovery must not download the bundled Android payload"
        );
        fs::remove_dir_all(destination).unwrap();
    }

    #[test]
    fn rejects_incorrect_range_responses_and_honors_cancellation() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let bad = server(fixture(), true);
        assert!(HttpArchive::open(
            &bad.url,
            runtime.handle().clone(),
            Arc::new(AtomicBool::new(false))
        )
        .is_err());
        let valid = server(fixture(), false);
        let cancel = Arc::new(AtomicBool::new(false));
        let mut reader =
            HttpArchive::open(&valid.url, runtime.handle().clone(), cancel.clone()).unwrap();
        cancel.store(true, Ordering::SeqCst);
        assert!(reader
            .read(&mut [0u8; 8])
            .unwrap_err()
            .to_string()
            .contains("__canceled__"));
    }

    #[test]
    fn recognizes_legacy_and_future_targets() {
        for (name, expected) in [
            ("windows_release_x86_64.exe", "windows"),
            ("win64_debug.exe", "windows"),
            ("linux_debug.arm64", "linux"),
            ("x11_64_release", "linux"),
            ("osx.zip", "macos"),
            ("iphone.zip", "ios"),
            ("javascript_release.zip", "web"),
            ("uwp_x64_release.zip", "uwp"),
            ("freebsd_release.arm64", "freebsd"),
            ("icudt_godot.dat", "icu"),
        ] {
            assert_eq!(platform(Path::new(name)).unwrap().0, expected);
        }
        assert!(platform(Path::new("version.txt")).is_none());
    }

    #[test]
    fn individual_files_do_not_install_sibling_architectures_or_builds() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let root =
            std::env::temp_dir().join(format!("godothub-individual-{}", uuid::Uuid::new_v4()));
        let target = root.join("4.5.stable");
        let source = server(fixture(), false);
        install(
            &source.url,
            &root,
            "4.5.stable",
            &["windows_debug_x86_32.exe".into()],
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone(),
        )
        .unwrap();
        assert_eq!(
            fs::read(target.join("windows_debug_x86_32.exe")).unwrap(),
            b"windows x86 debug"
        );
        assert!(!target.join("windows_debug_x86_64.exe").exists());
        assert!(!target.join("windows_release_x86_64.exe").exists());
        assert!(!target.join("windows_release_arm64.exe").exists());
        assert!(!target.join("android_debug.apk").exists());
        assert!(target.join("version.txt").is_file());
        let repeated = install(
            &source.url,
            &root,
            "4.5.stable",
            &[
                "windows_debug_x86_32.exe".into(),
                "windows_release_arm64.exe".into(),
            ],
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone(),
        )
        .unwrap_err();
        assert!(repeated.contains("already installed"));
        assert!(!target.join("windows_release_arm64.exe").exists());
        install(
            &source.url,
            &root,
            "4.5.stable",
            &["windows_release_arm64.exe".into()],
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone(),
        )
        .unwrap();
        assert_eq!(
            fs::read(target.join("windows_release_arm64.exe")).unwrap(),
            b"windows arm release"
        );
        assert!(target.join("windows_debug_x86_32.exe").is_file());
        assert!(!target.join("windows_debug_x86_64.exe").exists());
        assert!(!target.join("windows_release_x86_64.exe").exists());
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn selective_installs_preserve_existing_platforms_and_roll_back_corruption() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let root = std::env::temp_dir().join(format!("godothub-install-{}", uuid::Uuid::new_v4()));
        let target = root.join("4.5.stable");
        fs::create_dir_all(&target).unwrap();
        fs::write(
            target.join("linux_debug.x86_64"),
            b"existing linux template",
        )
        .unwrap();
        let good = server(fixture(), false);
        let selection = vec![
            "windows_debug_x86_64.exe".to_string(),
            "windows_release_x86_64.exe".to_string(),
        ];
        install(
            &good.url,
            &root,
            "4.5.stable",
            &selection,
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone(),
        )
        .unwrap();
        assert_eq!(
            fs::read(target.join("windows_release_x86_64.exe")).unwrap(),
            b"windows release"
        );
        assert_eq!(
            fs::read(target.join("linux_debug.x86_64")).unwrap(),
            b"existing linux template"
        );
        assert_eq!(fs::read(target.join("version.txt")).unwrap(), b"4.5.stable");
        assert!(!target.join("android_debug.apk").exists());
        let mut damaged = fixture();
        let position = damaged
            .windows(b"windows arm release".len())
            .position(|part| part == b"windows arm release")
            .unwrap();
        damaged[position] ^= 0xff;
        let corrupt = server(damaged, false);
        assert!(install(
            &corrupt.url,
            &root,
            "4.5.stable",
            &["windows_release_arm64.exe".into()],
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone()
        )
        .is_err());
        assert_eq!(
            fs::read(target.join("windows_release_x86_64.exe")).unwrap(),
            b"windows release"
        );
        assert_eq!(
            fs::read(target.join("linux_debug.x86_64")).unwrap(),
            b"existing linux template"
        );
        assert!(!root.join(".4.5.stable.installing").exists());
        assert!(install(
            &good.url,
            &root,
            "4.5.stable",
            &["unknown".into()],
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone()
        )
        .is_err());
        assert!(install(
            &good.url,
            &root,
            "4.5.stable",
            &[],
            None,
            "4.5-stable".into(),
            Arc::new(AtomicBool::new(false)),
            runtime.handle().clone()
        )
        .is_err());
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn uninstall_resolves_only_requested_template_files() {
        let root = std::env::temp_dir().join(format!("godothub-removal-{}", uuid::Uuid::new_v4()));
        fs::create_dir_all(root.join("nested")).unwrap();
        for name in [
            "windows_debug_x86_32.exe",
            "windows_release_arm64.exe",
            "version.txt",
            "nested/linux_debug.x86_64",
        ] {
            fs::write(root.join(name), b"installed template").unwrap();
        }
        let paths = removal_paths(
            &root,
            &[
                "windows_debug_x86_32.exe".into(),
                "windows_debug_x86_32.exe".into(),
            ],
        )
        .unwrap();
        assert_eq!(
            paths,
            vec![root
                .canonicalize()
                .unwrap()
                .join("windows_debug_x86_32.exe")]
        );
        for invalid in [
            "../outside.exe",
            "nested/../windows_debug_x86_32.exe",
            "nested/../../outside.exe",
            "C:/outside.exe",
            "/outside.exe",
            "version.txt",
            "nested",
            "windows_debug_x86_32.exe:stream",
            "missing.exe",
        ] {
            assert!(
                removal_paths(&root, &[invalid.into()]).is_err(),
                "{invalid}"
            );
        }
        assert!(removal_paths(&root, &[]).is_err());
        assert!(removal_paths(
            &root,
            &["windows_debug_x86_32.exe".into(), "missing.exe".into()]
        )
        .is_err());
        assert!(root.join("windows_release_arm64.exe").is_file());
        assert!(root.join("version.txt").is_file());
        assert!(root.join("nested/linux_debug.x86_64").is_file());
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn cached_catalog_avoids_network_and_refreshes_local_installation_state() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        let root = std::env::temp_dir().join(format!("godothub-catalog-{}", uuid::Uuid::new_v4()));
        let destination = root.join("templates");
        fs::create_dir_all(&destination).unwrap();
        let cache = root.join("cache/catalog.json");
        let source = server(fixture(), false);
        let first = cached_options(
            &source.url,
            &destination,
            &cache,
            runtime.handle().clone(),
            false,
        )
        .unwrap();
        assert!(cache.is_file());
        assert!(!first.iter().any(|option| option.installed));
        let downloaded = source.bytes.load(Ordering::SeqCst);
        fs::write(
            destination.join("windows_debug_x86_64.exe"),
            b"windows debug",
        )
        .unwrap();
        let reopened = cached_options(
            &source.url,
            &destination,
            &cache,
            runtime.handle().clone(),
            false,
        )
        .unwrap();
        assert!(
            reopened
                .iter()
                .flat_map(|option| &option.files)
                .find(|file| file.name == "windows_debug_x86_64.exe")
                .unwrap()
                .installed
        );
        assert_eq!(source.bytes.load(Ordering::SeqCst), downloaded);
        fs::remove_file(destination.join("windows_debug_x86_64.exe")).unwrap();
        let reopened = cached_options(
            &source.url,
            &destination,
            &cache,
            runtime.handle().clone(),
            false,
        )
        .unwrap();
        assert!(!reopened
            .iter()
            .flat_map(|option| &option.files)
            .any(|file| file.installed));
        assert_eq!(source.bytes.load(Ordering::SeqCst), downloaded);
        cached_options(
            &source.url,
            &destination,
            &cache,
            runtime.handle().clone(),
            true,
        )
        .unwrap();
        assert!(source.bytes.load(Ordering::SeqCst) > downloaded);
        let refreshed = source.bytes.load(Ordering::SeqCst);
        fs::write(&cache, b"interrupted cache write").unwrap();
        cached_options(
            &source.url,
            &destination,
            &cache,
            runtime.handle().clone(),
            false,
        )
        .unwrap();
        assert!(source.bytes.load(Ordering::SeqCst) > refreshed);
        let different_release = server(fixture(), false);
        cached_options(
            &different_release.url,
            &destination,
            &cache,
            runtime.handle().clone(),
            false,
        )
        .unwrap();
        assert!(
            different_release.bytes.load(Ordering::SeqCst) > 0,
            "a different release URL must not reuse another release's manifest"
        );
        let url = different_release.url.clone();
        drop(different_release);
        cached_options(&url, &destination, &cache, runtime.handle().clone(), false).unwrap();
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    #[ignore = "requires access to official Godot release assets"]
    fn official_release_catalogs() {
        let runtime = tokio::runtime::Runtime::new().unwrap();
        for (tag, mono) in [
            ("4.5-stable", false),
            ("4.5-stable-mono", true),
            ("3.6-stable", false),
        ] {
            let options = options(
                &tpz_url(tag, mono),
                Path::new("nonexistent-template-test-folder"),
                runtime.handle().clone(),
            )
            .unwrap();
            println!(
                "{tag}: {:?}",
                options
                    .iter()
                    .map(|option| (&option.label, option.files.len()))
                    .collect::<Vec<_>>()
            );
            assert!(options.iter().any(|option| option.id == "windows"));
            assert!(options.iter().any(|option| option.id == "linux"));
            assert!(options.iter().any(|option| option.id == "android"));
        }
    }
}
