//! Makes rfd's file dialogs modal to the Flutter window without owning them.
//!
//! rfd shows dialogs on its own worker thread. Giving them the Flutter window
//! (which lives on the platform thread) as owner makes Windows attach the two
//! threads' input queues, so every stall inside the shell dialog froze the whole
//! app. Instead the dialog stays unowned and the main window is disabled while
//! it is open, then re-enabled and brought back to the foreground.

use windows::core::BOOL;
use windows::Win32::Foundation::{HWND, LPARAM};
use windows::Win32::UI::Input::KeyboardAndMouse::{EnableWindow, IsWindowEnabled};
use windows::Win32::UI::WindowsAndMessaging::{
    EnumWindows, GetClassNameW, GetWindowThreadProcessId, IsWindowVisible, SetForegroundWindow,
};

const RUNNER_CLASS: &str = "FLUTTER_RUNNER_WIN32_WINDOW";

fn is_runner_window(hwnd: HWND) -> bool {
    let mut pid = 0u32;
    unsafe { GetWindowThreadProcessId(hwnd, Some(&mut pid)) };
    if pid != std::process::id() {
        return false;
    }
    let mut name = [0u16; 64];
    let len = unsafe { GetClassNameW(hwnd, &mut name) } as usize;
    String::from_utf16_lossy(&name[..len]) == RUNNER_CLASS
}

unsafe extern "system" fn collect(hwnd: HWND, found: LPARAM) -> BOOL {
    if is_runner_window(hwnd) && unsafe { IsWindowVisible(hwnd) }.as_bool() {
        let slot = unsafe { &mut *(found.0 as *mut Option<HWND>) };
        *slot = Some(hwnd);
        return BOOL(0);
    }
    BOOL(1)
}

fn visible_main_window() -> Option<HWND> {
    let mut found: Option<HWND> = None;
    let _ = unsafe { EnumWindows(Some(collect), LPARAM(&mut found as *mut _ as isize)) };
    found
}

/// Keeps the main window disabled until dropped. Stores the handle as an
/// integer so the guard stays `Send` across the dialog's `.await`.
pub struct ModalGuard(Option<isize>);

impl Drop for ModalGuard {
    fn drop(&mut self) {
        if let Some(raw) = self.0 {
            let hwnd = HWND(raw as *mut _);
            unsafe {
                let _ = EnableWindow(hwnd, true);
                let _ = SetForegroundWindow(hwnd);
            }
        }
    }
}

/// Disables the visible main window for the lifetime of the returned guard.
/// Leaves it alone when it is already disabled (another dialog owns it).
pub fn disable_main_window() -> ModalGuard {
    let Some(hwnd) = visible_main_window() else { return ModalGuard(None) };
    if !unsafe { IsWindowEnabled(hwnd) }.as_bool() {
        return ModalGuard(None);
    }
    let _ = unsafe { EnableWindow(hwnd, false) };
    ModalGuard(Some(hwnd.0 as isize))
}
