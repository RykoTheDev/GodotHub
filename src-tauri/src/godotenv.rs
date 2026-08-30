use crate::models::InstalledGodotVersion;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GodotVersionNumber {
    pub major: u32,
    pub minor: u32,
    pub patch: u32,
    pub label: String,
    pub label_num: i32,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DetectedVersion {
    pub number: GodotVersionNumber,
    pub is_dotnet: bool,
}

fn parse_uint(s: &str) -> Option<u32> {
    if s.is_empty() || !s.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    s.parse().ok()
}

pub fn parse_release_version(s: &str) -> Option<GodotVersionNumber> {
    let (num_part, label_part) = s.split_once('-')?;
    let mut num_parts = num_part.split('.');
    let major = parse_uint(num_parts.next()?)?;
    let minor = parse_uint(num_parts.next()?)?;
    let patch = match num_parts.next() {
        Some(p) => {
            if p.starts_with('0') {
                return None;
            }
            parse_uint(p)?
        }
        None => 0,
    };
    if num_parts.next().is_some() {
        return None;
    }
    let (label, label_num) = parse_release_label(label_part)?;
    Some(GodotVersionNumber {
        major,
        minor,
        patch,
        label,
        label_num,
    })
}

fn parse_release_label(label: &str) -> Option<(String, i32)> {
    if label == "stable" {
        return Some(("stable".to_string(), -1));
    }
    let digit_start = label.find(|c: char| c.is_ascii_digit())?;
    let (letters, digits) = label.split_at(digit_start);
    if letters.is_empty() || !letters.bytes().all(|b| b.is_ascii_lowercase()) {
        return None;
    }
    let num = parse_uint(digits)?;
    Some((letters.to_string(), num as i32))
}

pub fn parse_sharp_version(s: &str) -> Option<GodotVersionNumber> {
    let (num_part, label_part) = match s.split_once('-') {
        Some((n, l)) => (n, Some(l)),
        None => (s, None),
    };
    let mut num_parts = num_part.split('.');
    let major = parse_uint(num_parts.next()?)?;
    let minor = parse_uint(num_parts.next()?)?;
    let patch = parse_uint(num_parts.next()?)?;
    if num_parts.next().is_some() {
        return None;
    }
    let (label, label_num) = match label_part {
        None => ("stable".to_string(), -1),
        Some(l) => {
            let (letters, digits) = l.split_once('.')?;
            if letters.is_empty() || !letters.bytes().all(|b| b.is_ascii_lowercase()) {
                return None;
            }
            let num = parse_uint(digits)?;
            (letters.to_string(), num as i32)
        }
    };
    Some(GodotVersionNumber {
        major,
        minor,
        patch,
        label,
        label_num,
    })
}

pub fn parse_version(s: &str) -> Option<GodotVersionNumber> {
    let trimmed = s.trim().trim_start_matches('v');
    parse_release_version(trimmed).or_else(|| parse_sharp_version(trimmed))
}

pub fn parse_installed_tag(tag: &str) -> Option<GodotVersionNumber> {
    let base = tag.trim().trim_end_matches("-mono");
    parse_version(base)
}

pub fn numbers_equal(a: &GodotVersionNumber, b: &GodotVersionNumber) -> bool {
    a.major == b.major
        && a.minor == b.minor
        && a.patch == b.patch
        && a.label == b.label
        && a.label_num == b.label_num
}

pub fn matches_detected(spec: &DetectedVersion, tag: &str) -> bool {
    parse_installed_tag(tag)
        .map(|n| numbers_equal(&spec.number, &n))
        .unwrap_or(false)
}

pub fn best_match<'a>(
    spec: &DetectedVersion,
    versions: &'a [InstalledGodotVersion],
) -> Option<&'a InstalledGodotVersion> {
    versions
        .iter()
        .filter(|v| matches_detected(spec, &v.tag))
        .min_by_key(|v| if v.is_mono == spec.is_dotnet { 0 } else { 1 })
}

fn ancestor_dirs(start: &Path) -> Vec<PathBuf> {
    let mut dirs = Vec::new();
    let mut current = Some(start.to_path_buf());
    while let Some(dir) = current {
        dirs.push(dir.clone());
        current = dir.parent().map(|p| p.to_path_buf());
    }
    dirs
}

pub fn detect_version(project_path: &str) -> Option<DetectedVersion> {
    let mut globals: Vec<PathBuf> = Vec::new();
    let mut csprojs: Vec<PathBuf> = Vec::new();
    let mut godotrcs: Vec<PathBuf> = Vec::new();

    for dir in ancestor_dirs(Path::new(project_path)) {
        let global = dir.join("global.json");
        if global.is_file() {
            globals.push(global);
        }

        if let Ok(entries) = fs::read_dir(&dir) {
            let mut files: Vec<PathBuf> = entries
                .flatten()
                .filter_map(|e| {
                    let p = e.path();
                    p.extension()
                        .map(|ext| ext == "csproj")
                        .unwrap_or(false)
                        .then_some(p)
                })
                .collect();
            files.sort();
            csprojs.extend(files);
        }

        let godotrc = dir.join(".godotrc");
        if godotrc.is_file() {
            godotrcs.push(godotrc);
        }
    }

    for path in globals.into_iter().chain(csprojs).chain(godotrcs) {
        if let Some(version) = parse_version_file(&path) {
            return Some(version);
        }
    }
    None
}

fn parse_version_file(path: &Path) -> Option<DetectedVersion> {
    let name = path.file_name()?.to_str()?;
    match name {
        "global.json" => parse_global_json(path),
        ".godotrc" => parse_godotrc(path),
        _ => parse_csproj(path),
    }
}

fn parse_global_json(path: &Path) -> Option<DetectedVersion> {
    let content = fs::read_to_string(path).ok()?;
    let json: serde_json::Value = serde_json::from_str(&content).ok()?;
    let version = json.get("msbuild-sdks")?.get("Godot.NET.Sdk")?;
    let version_str = match version {
        serde_json::Value::String(s) => s.clone(),
        serde_json::Value::Number(n) => n.to_string(),
        _ => return None,
    };
    let number = parse_version(&version_str)?;
    Some(DetectedVersion {
        number,
        is_dotnet: true,
    })
}

fn parse_csproj(path: &Path) -> Option<DetectedVersion> {
    let content = fs::read_to_string(path).ok()?;
    let open = content.find("<Project")?;
    let after = &content[open..];
    let close = after.find('>')?;
    let tag = &after[..close];
    let sdk = extract_attr(tag, "Sdk")?;
    let version = sdk.strip_prefix("Godot.NET.Sdk/")?;
    if version.is_empty() {
        return None;
    }
    let number = parse_version(version)?;
    Some(DetectedVersion {
        number,
        is_dotnet: true,
    })
}

fn extract_attr(tag: &str, name: &str) -> Option<String> {
    let bytes = tag.as_bytes();
    let name_bytes = name.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i..].starts_with(name_bytes) {
            let after = i + name_bytes.len();
            if bytes.get(after) == Some(&b'=') {
                if let Some(&q) = bytes.get(after + 1) {
                    if q == b'"' || q == b'\'' {
                        let value = &bytes[after + 2..];
                        if let Some(end) = value.iter().position(|&b| b == q) {
                            return std::str::from_utf8(&value[..end])
                                .ok()
                                .map(String::from);
                        }
                    }
                }
            }
        }
        i += 1;
    }
    None
}

fn parse_godotrc(path: &Path) -> Option<DetectedVersion> {
    let content = fs::read_to_string(path).ok()?;
    let line = content.lines().next()?.trim();
    if line.is_empty() {
        return None;
    }
    const NO_DOTNET: [&str; 4] = [" no-dotnet", " non-dotnet", " not-dotnet", " no dotnet"];
    const DOTNET: [&str; 2] = [" mono", " dotnet"];
    let mut is_dotnet = true;
    let mut version = line;
    for suffix in NO_DOTNET {
        if version.to_lowercase().ends_with(suffix) {
            is_dotnet = false;
            version = &version[..version.len() - suffix.len()];
            break;
        }
    }
    if is_dotnet {
        for suffix in DOTNET {
            if version.to_lowercase().ends_with(suffix) {
                version = &version[..version.len() - suffix.len()];
                break;
            }
        }
    }
    let number = parse_version(version)?;
    Some(DetectedVersion { number, is_dotnet })
}

pub fn release_string(n: &GodotVersionNumber) -> String {
    let mut s = format!("{}.{}", n.major, n.minor);
    if n.patch != 0 {
        s.push_str(&format!(".{}", n.patch));
    }
    if n.label == "stable" {
        s.push_str("-stable");
    } else {
        s.push_str(&format!("-{}{}", n.label, n.label_num));
    }
    s
}

pub fn sharp_string(n: &GodotVersionNumber) -> String {
    let mut s = format!("{}.{}.{}", n.major, n.minor, n.patch);
    if n.label != "stable" {
        s.push_str(&format!("-{}.{}", n.label, n.label_num));
    }
    s
}

pub fn pin_version(project_dir: &str, tag: &str) -> Result<(), String> {
    let number = match parse_installed_tag(tag) {
        Some(n) => n,
        None => return Ok(())
    };
    let is_mono = tag.trim().ends_with("-mono");
    let root = Path::new(project_dir);
    if is_mono {
        write_global_json_pin(root, &number)?;
        if parse_global_json(&root.join("global.json")).is_some() {
            let _ = fs::remove_file(root.join(".godotrc"));
        }
        Ok(())
    } else {
        write_godotrc_pin(root, &number)?;
        remove_godot_sdk_pin(root);
        Ok(())
    }
}

fn remove_godot_sdk_pin(root: &Path) {
    let path = root.join("global.json");
    let Ok(existing) = fs::read_to_string(&path) else {
        return;
    };
    let Ok(mut json) = serde_json::from_str::<serde_json::Value>(&existing) else {
        return;
    };
    let Some(obj) = json.as_object_mut() else {
        return;
    };
    let Some(msbuild) = obj.get_mut("msbuild-sdks").and_then(|v| v.as_object_mut()) else {
        return;
    };
    if msbuild.remove("Godot.NET.Sdk").is_none() {
        return;
    }
    if msbuild.is_empty() {
        obj.remove("msbuild-sdks");
    }
    let Ok(out) = serde_json::to_string_pretty(&json) else {
        return;
    };
    let _ = fs::write(&path, out + "\n");
}

fn write_godotrc_pin(root: &Path, number: &GodotVersionNumber) -> Result<(), String> {
    let content = format!("{} no-dotnet\n", release_string(number));
    fs::write(root.join(".godotrc"), content).map_err(|e| e.to_string())
}

fn write_global_json_pin(root: &Path, number: &GodotVersionNumber) -> Result<(), String> {
    let path = root.join("global.json");
    let version = sharp_string(number);
    let existing = fs::read_to_string(&path).unwrap_or_default();

    if existing.trim().is_empty() {
        let fresh = format!(
            "{{\n  \"msbuild-sdks\": {{\n    \"Godot.NET.Sdk\": \"{}\"\n  }}\n}}\n",
            version
        );
        return fs::write(&path, fresh).map_err(|e| e.to_string());
    }

    if let Ok(mut json) = serde_json::from_str::<serde_json::Value>(&existing) {
        let obj = json
            .as_object_mut()
            .ok_or_else(|| "global.json is not a JSON object".to_string())?;
        let msbuild = obj
            .entry("msbuild-sdks")
            .or_insert_with(|| serde_json::json!({}));
        let msbuild_obj = msbuild
            .as_object_mut()
            .ok_or_else(|| "global.json msbuild-sdks is not an object".to_string())?;
        msbuild_obj.insert(
            "Godot.NET.Sdk".to_string(),
            serde_json::Value::String(version.clone()),
        );
        let out = serde_json::to_string_pretty(&json).map_err(|e| e.to_string())?;
        return fs::write(&path, out + "\n").map_err(|e| e.to_string());
    }

    let mut lines: Vec<String> = existing.lines().map(str::to_string).collect();
    if let Some(line) = lines.iter_mut().find(|l| l.contains("Godot.NET.Sdk")) {
        *line = replace_sdk_value(line, &version);
        return fs::write(&path, lines.join("\n")).map_err(|e| e.to_string());
    }
    if let Some(idx) = lines.iter().position(|l| l.trim().contains("msbuild-sdks")) {
        lines.insert(idx + 1, format!("    \"Godot.NET.Sdk\": \"{}\",", version));
        return fs::write(&path, lines.join("\n")).map_err(|e| e.to_string());
    }
    Ok(())
}

fn replace_sdk_value(line: &str, version: &str) -> String {
    let Some(key_idx) = line.find("\"Godot.NET.Sdk\"") else {
        return line.to_string();
    };
    let Some(colon_rel) = line[key_idx..].find(':') else {
        return line.to_string();
    };
    let Some(qstart_rel) = line[key_idx + colon_rel + 1..].find('"') else {
        return line.to_string();
    };
    let qstart = key_idx + colon_rel + 1 + qstart_rel;
    let Some(qend_rel) = line[qstart + 1..].find('"') else {
        return line.to_string();
    };
    let qend = qstart + 1 + qend_rel;
    let mut out = String::with_capacity(line.len() + version.len());
    out.push_str(&line[..qstart + 1]);
    out.push_str(version);
    out.push_str(&line[qend..]);
    out
}
