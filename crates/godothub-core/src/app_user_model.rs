use crate::Channel;

#[cfg(windows)]
pub fn set_process_app_user_model_id(channel: Channel) -> bool {
    use windows_sys::Win32::UI::Shell::SetCurrentProcessExplicitAppUserModelID;
    let wide: Vec<u16> = channel.info().identifier.encode_utf16().chain(std::iter::once(0)).collect();
    unsafe { SetCurrentProcessExplicitAppUserModelID(wide.as_ptr()) >= 0 }
}

#[cfg(not(windows))]
pub fn set_process_app_user_model_id(_channel: Channel) -> bool {
    false
}

#[no_mangle]
pub extern "C" fn godothub_set_app_user_model_id(channel: u32) -> bool {
    let channel = if channel == 0 { Channel::Stable } else { Channel::Beta };
    std::panic::catch_unwind(|| set_process_app_user_model_id(channel)).unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[cfg(windows)]
    #[test]
    fn sets_the_channel_identifier_on_windows() {
        use windows_sys::Win32::System::Com::CoTaskMemFree;
        use windows_sys::Win32::UI::Shell::GetCurrentProcessExplicitAppUserModelID;
        assert!(set_process_app_user_model_id(Channel::Beta));
        let mut raw: windows_sys::core::PWSTR = std::ptr::null_mut();
        let hr = unsafe { GetCurrentProcessExplicitAppUserModelID(&mut raw) };
        assert!(hr >= 0);
        let len = (0..).take_while(|&i| unsafe { *raw.add(i) } != 0).count();
        let value = String::from_utf16_lossy(unsafe { std::slice::from_raw_parts(raw, len) });
        unsafe { CoTaskMemFree(raw as *const _) };
        assert_eq!(value, "Ryko.GodotHub.Beta");
    }

    #[cfg(not(windows))]
    #[test]
    fn is_a_no_op_elsewhere() {
        assert!(!set_process_app_user_model_id(Channel::Beta));
    }
}
