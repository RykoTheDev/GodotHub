use std::num::NonZeroIsize;

use raw_window_handle::{
    DisplayHandle, HandleError, HasDisplayHandle, HasWindowHandle, RawDisplayHandle, RawWindowHandle, Win32WindowHandle,
    WindowHandle, WindowsDisplayHandle,
};
use windows::core::BOOL;
use windows::Win32::Foundation::{HWND, LPARAM};
use windows::Win32::UI::WindowsAndMessaging::{EnumWindows, GetClassNameW, GetWindowThreadProcessId, IsWindowVisible};

const RUNNER_CLASS: &str = "FLUTTER_RUNNER_WIN32_WINDOW";

pub struct DialogParent(NonZeroIsize);

impl HasWindowHandle for DialogParent {
    fn window_handle(&self) -> Result<WindowHandle<'_>, HandleError> {
        let raw = RawWindowHandle::Win32(Win32WindowHandle::new(self.0));
        Ok(unsafe { WindowHandle::borrow_raw(raw) })
    }
}

impl HasDisplayHandle for DialogParent {
    fn display_handle(&self) -> Result<DisplayHandle<'_>, HandleError> {
        Ok(unsafe { DisplayHandle::borrow_raw(RawDisplayHandle::Windows(WindowsDisplayHandle::new())) })
    }
}

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
    if is_runner_window(hwnd) {
        let slot = unsafe { &mut *(found.0 as *mut Option<(HWND, bool)>) };
        let visible = unsafe { IsWindowVisible(hwnd) }.as_bool();
        if slot.is_none() || (visible && !slot.is_some_and(|(_, v)| v)) {
            *slot = Some((hwnd, visible));
        }
    }
    BOOL(1)
}

pub fn main_window() -> Option<DialogParent> {
    let mut found: Option<(HWND, bool)> = None;
    let _ = unsafe { EnumWindows(Some(collect), LPARAM(&mut found as *mut _ as isize)) };
    found.and_then(|(hwnd, _)| NonZeroIsize::new(hwnd.0 as isize)).map(DialogParent)
}
