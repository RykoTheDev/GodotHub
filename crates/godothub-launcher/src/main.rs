#![cfg_attr(windows, windows_subsystem = "windows")]

use std::ffi::OsString;
use std::process::Command;

use godothub_launcher::Layout;

fn main() {
    let code = run().unwrap_or_else(|message| {
        show_error(&message);
        1
    });
    std::process::exit(code);
}

fn run() -> Result<i32, String> {
    let exe = std::env::current_exe().map_err(|e| e.to_string())?;
    let root = exe.parent().ok_or("The launcher has no folder")?;
    let name = exe.file_name().ok_or("The launcher has no file name")?;
    let layout = Layout::new(root);
    let args: Vec<OsString> = std::env::args_os().skip(1).collect();
    if !args.is_empty() {
        attach_console();
    }
    let mut version = layout
        .read_state()
        .map_err(|e| format!("Could not read {}: {e}", layout.state_path().display()))?
        .current;
    loop {
        let app = layout.app_dir(&version).join(name);
        let result = Command::new(&app).args(&args).status();
        let should_roll_back = match &result {
            Ok(status) => !status.success() && args.is_empty(),
            Err(_) => true,
        };
        if should_roll_back {
            if let Ok(Some(previous)) = layout.rollback_after_failure(&version) {
                version = previous;
                continue;
            }
        }
        return match result {
            Ok(status) => Ok(status.code().unwrap_or(1)),
            Err(e) => Err(format!("Could not start {}: {e}", app.display())),
        };
    }
}

#[cfg(windows)]
fn attach_console() {
    use windows_sys::Win32::System::Console::{AttachConsole, ATTACH_PARENT_PROCESS};
    unsafe {
        AttachConsole(ATTACH_PARENT_PROCESS);
    }
}

#[cfg(not(windows))]
fn attach_console() {}

#[cfg(windows)]
fn show_error(message: &str) {
    use windows_sys::Win32::UI::WindowsAndMessaging::{MessageBoxW, MB_ICONERROR, MB_OK};
    let wide = |s: &str| s.encode_utf16().chain(std::iter::once(0)).collect::<Vec<u16>>();
    let text = wide(message);
    let caption = wide("GodotHub");
    unsafe {
        MessageBoxW(std::ptr::null_mut(), text.as_ptr(), caption.as_ptr(), MB_ICONERROR | MB_OK);
    }
}

#[cfg(not(windows))]
fn show_error(message: &str) {
    eprintln!("{message}");
}
