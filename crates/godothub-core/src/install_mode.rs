#[cfg(target_os = "windows")]
use std::path::Path;

pub fn is_portable_install() -> bool {
    #[cfg(not(target_os = "windows"))]
    {
        false
    }

    #[cfg(target_os = "windows")]
    {
        let Ok(exe) = std::env::current_exe() else {
            return false;
        };
        let Some(dir) = exe.parent() else {
            return false;
        };
        if godothub_launcher::Layout::of_app_exe(&exe).is_some() {
            return false;
        }

        !(dir_has_uninstaller(dir)
            || is_standard_install_location(dir)
            || registry_has_godot_hub_install())
    }
}

#[cfg(target_os = "windows")]
fn dir_has_uninstaller(dir: &Path) -> bool {
    dir.read_dir()
        .map(|entries| {
            entries.flatten().any(|entry| {
                let name = entry.file_name().to_string_lossy().to_lowercase();
                name.starts_with("uninstall") && name.ends_with(".exe")
            })
        })
        .unwrap_or(false)
}

#[cfg(target_os = "windows")]
fn is_standard_install_location(dir: &Path) -> bool {
    let mut install_dirs: Vec<std::path::PathBuf> = Vec::new();
    if let Some(local) = std::env::var_os("LOCALAPPDATA") {
        install_dirs.push(Path::new(&local).join("Programs").join("GodotHub"));
    }
    for var in ["ProgramFiles", "ProgramFiles(x86)", "ProgramW6432"] {
        if let Ok(pf) = std::env::var(var) {
            install_dirs.push(Path::new(&pf).join("GodotHub"));
        }
    }

    let exe_dir = dir.to_string_lossy().to_lowercase();
    install_dirs
        .iter()
        .any(|d| exe_dir == d.to_string_lossy().to_lowercase())
}

#[cfg(target_os = "windows")]
fn registry_has_godot_hub_install() -> bool {
    const UNINSTALL_ROOTS: [&str; 3] = [
        r"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        r"HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        r"HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    ];

    for root in UNINSTALL_ROOTS {
        let Ok(output) = std::process::Command::new("reg")
            .args(["query", root, "/s", "/d", "/e", "/f", "GodotHub"])
            .output()
        else {
            continue;
        };
        if output.status.success() {
            return true;
        }
    }
    false
}

pub fn versioned_install() -> Option<(godothub_launcher::Layout, String)> {
    std::env::current_exe().ok().and_then(|exe| godothub_launcher::Layout::of_app_exe(&exe))
}

fn replaced_executable(exe: std::path::PathBuf) -> std::path::PathBuf {
    let Some(text) = exe.to_str() else {
        return exe;
    };
    match text.strip_suffix(" (deleted)").map(std::path::PathBuf::from) {
        Some(original) if original.is_file() => original,
        _ => exe,
    }
}

pub fn launch_executable() -> std::io::Result<std::path::PathBuf> {
    #[cfg(target_os = "linux")]
    if let Some(image) = std::env::var_os("APPIMAGE").filter(|v| !v.is_empty()) {
        return Ok(std::path::PathBuf::from(image));
    }
    let exe = replaced_executable(std::env::current_exe()?);
    let launcher = godothub_launcher::Layout::of_app_exe(&exe)
        .and_then(|(layout, _)| exe.file_name().map(|name| layout.root().join(name)))
        .filter(|path| path.is_file());
    Ok(launcher.unwrap_or(exe))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_replaced_binary_relaunches_from_its_original_path() {
        let dir = std::env::temp_dir().join(format!("godothub-replaced-{}", uuid::Uuid::new_v4()));
        std::fs::create_dir_all(&dir).unwrap();
        let exe = dir.join("godothub");
        std::fs::write(&exe, b"new").unwrap();
        let deleted = std::path::PathBuf::from(format!("{} (deleted)", exe.display()));
        assert_eq!(replaced_executable(deleted), exe);
        assert_eq!(replaced_executable(exe.clone()), exe);
        let gone = dir.join("missing (deleted)");
        assert_eq!(replaced_executable(gone.clone()), gone);
        let _ = std::fs::remove_dir_all(&dir);
    }
}
