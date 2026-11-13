//! Choice of WebKitGTK rendering path on Linux.
//!
//! WebKitGTK's DMA-BUF renderer is the accelerated path: page layers live in
//! GPU-backed buffers, so scrolling, hover effects and repaints are not
//! CPU-rasterized. Turning it off is what made the UI (the dashboard most of
//! all) crawl on Linux, but a few driver/WebKitGTK combinations draw nothing at
//! all with it on, which is why the old code disabled it for everybody.
//!
//! This decides per machine instead of blanket-disabling it:
//!
//! * Accelerated path by default.
//! * Software path when the driver is known to break DMA-BUF, or when a
//!   previous launch never confirmed a painted frame.
//! * `GODOTHUB_RENDERER=software` / `=gpu` forces either path. A
//!   `WEBKIT_DISABLE_DMABUF_RENDERER` already present in the environment always
//!   wins and is left untouched.

use std::path::Path;

const FORCE_ENV: &str = "GODOTHUB_RENDERER";
const WEBKIT_ENV: &str = "WEBKIT_DISABLE_DMABUF_RENDERER";

/// Sticky decision: this machine must keep using the software renderer.
const SOFTWARE_MARKER: &str = ".software-renderer";
/// Written before the window is created, removed once a frame was painted.
const ATTEMPT_MARKER: &str = ".gpu-renderer-attempt";

#[cfg(target_os = "linux")]
pub fn prepare() {
    let dir = config_dir();
    let software = resolve(
        std::env::var_os(WEBKIT_ENV).is_some(),
        std::env::var(FORCE_ENV).ok().as_deref(),
        dir.as_deref(),
        driver_breaks_dmabuf(),
    );
    if software {
        std::env::set_var(WEBKIT_ENV, "1");
    }
}

#[cfg(not(target_os = "linux"))]
pub fn prepare() {}

/// The frontend painted a frame, so the accelerated path works on this machine.
#[cfg(target_os = "linux")]
pub fn mark_painted() {
    let Some(dir) = config_dir() else { return };
    let _ = std::fs::remove_file(dir.join(ATTEMPT_MARKER));
}

#[cfg(not(target_os = "linux"))]
pub fn mark_painted() {}

#[cfg(target_os = "linux")]
fn config_dir() -> Option<std::path::PathBuf> {
    crate::Paths::for_channel(crate::Channel::Stable)
        .app_config_dir()
        .ok()
}

/// The NVIDIA proprietary driver is the setup that renders nothing with
/// WebKitGTK's DMA-BUF renderer. nouveau does not expose this file.
#[cfg(target_os = "linux")]
fn driver_breaks_dmabuf() -> bool {
    Path::new("/proc/driver/nvidia/version").exists()
}

/// Whether the software renderer should be requested.
///
/// `dir` is the app config directory holding the markers; `None` means the
/// machine has no usable config directory, in which case nothing is persisted.
fn resolve(
    webkit_env_set: bool,
    force: Option<&str>,
    dir: Option<&Path>,
    driver_broken: bool,
) -> bool {
    // Whoever set the WebKit flag themselves knows better; don't touch it.
    if webkit_env_set {
        return false;
    }
    match force {
        Some("software") => return set_mode(dir, true),
        Some("gpu") => return set_mode(dir, false),
        _ => {}
    }

    let Some(dir) = dir else { return false };
    if dir.join(SOFTWARE_MARKER).is_file() {
        return true;
    }
    // A leftover attempt marker means the previous launch never reported a
    // painted frame, so the accelerated path does not work here.
    if dir.join(ATTEMPT_MARKER).is_file() {
        return set_mode(Some(dir), true);
    }
    if driver_broken {
        return set_mode(Some(dir), true);
    }

    // Assume the accelerated path works until the first frame proves otherwise.
    let _ = std::fs::write(dir.join(ATTEMPT_MARKER), b"");
    false
}

fn set_mode(dir: Option<&Path>, software: bool) -> bool {
    if let Some(dir) = dir {
        let _ = std::fs::create_dir_all(dir);
        let _ = std::fs::remove_file(dir.join(ATTEMPT_MARKER));
        if software {
            let _ = std::fs::write(dir.join(SOFTWARE_MARKER), b"");
        } else {
            let _ = std::fs::remove_file(dir.join(SOFTWARE_MARKER));
        }
    }
    software
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    struct TempDir(PathBuf);

    impl TempDir {
        fn new(name: &str) -> Self {
            let dir = std::env::temp_dir().join(format!(
                "godothub-renderer-{}-{name}",
                std::process::id()
            ));
            let _ = std::fs::remove_dir_all(&dir);
            std::fs::create_dir_all(&dir).unwrap();
            Self(dir)
        }

        fn path(&self) -> &Path {
            &self.0
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = std::fs::remove_dir_all(&self.0);
        }
    }

    #[test]
    fn fresh_machine_takes_the_accelerated_path() {
        let dir = TempDir::new("fresh");
        assert!(!resolve(false, None, Some(dir.path()), false));
        assert!(dir.path().join(ATTEMPT_MARKER).is_file());
        assert!(!dir.path().join(SOFTWARE_MARKER).is_file());
    }

    #[test]
    fn unfinished_previous_launch_falls_back_for_good() {
        let dir = TempDir::new("unfinished");
        assert!(!resolve(false, None, Some(dir.path()), false)); // launch 1: attempt
        assert!(resolve(false, None, Some(dir.path()), false)); // launch 2: no frame
        assert!(dir.path().join(SOFTWARE_MARKER).is_file());
        assert!(resolve(false, None, Some(dir.path()), false)); // stays on software
    }

    #[test]
    fn painted_frame_keeps_the_accelerated_path() {
        let dir = TempDir::new("painted");
        assert!(!resolve(false, None, Some(dir.path()), false));
        // The frontend confirms the frame and clears the marker.
        std::fs::remove_file(dir.path().join(ATTEMPT_MARKER)).unwrap();
        assert!(!resolve(false, None, Some(dir.path()), false));
    }

    #[test]
    fn known_broken_driver_starts_on_software() {
        let dir = TempDir::new("broken-driver");
        assert!(resolve(false, None, Some(dir.path()), true));
        assert!(dir.path().join(SOFTWARE_MARKER).is_file());
    }

    #[test]
    fn explicit_environment_wins() {
        let dir = TempDir::new("env");
        assert!(!resolve(true, Some("software"), Some(dir.path()), true));
        assert!(!dir.path().join(SOFTWARE_MARKER).is_file());
    }

    #[test]
    fn forcing_gpu_clears_the_fallback() {
        let dir = TempDir::new("force-gpu");
        assert!(resolve(false, None, Some(dir.path()), true));
        assert!(!resolve(false, Some("gpu"), Some(dir.path()), true));
        assert!(!dir.path().join(SOFTWARE_MARKER).is_file());
        assert!(!dir.path().join(ATTEMPT_MARKER).is_file());
    }
}
