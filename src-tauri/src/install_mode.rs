#[cfg(target_os = "windows")]
use std::path::Path;

#[tauri::command]
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
            .args(["query", root, "/s", "/f", "GodotHub"])
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
