use flutter_rust_bridge::frb;
use godothub_core::diagnostics;

use super::error::CoreError;

pub struct CrashNotice {
    pub version: String,
    pub code: i64,
    pub rolled_back_to: Option<String>,
    pub summary: String,
}

#[frb(sync)]
pub fn record_diagnostic(source: String, message: String) {
    diagnostics::record(&source, &message);
}

pub fn diagnostic_log_tail(max_lines: u32) -> String {
    diagnostics::tail(max_lines as usize)
}

pub fn diagnostic_log_dir() -> Result<String, CoreError> {
    let dir = crate::host::app()?.path().app_data_dir().map_err(|e| CoreError::from(e.to_string()))?;
    Ok(diagnostics::log_dir(&dir).to_string_lossy().to_string())
}

pub fn debug_panic() {
    panic!("Debug crash test: Rust panic triggered from Settings > Debug");
}

pub fn debug_abort() {
    diagnostics::record("debug", "Debug crash test: aborting the process from Settings > Debug");
    std::process::abort();
}

pub fn take_crash_notice() -> Option<CrashNotice> {
    diagnostics::take_crash_notice().map(|crash| CrashNotice {
        summary: diagnostics::describe_crash(&crash),
        version: crash.version,
        code: crash.code,
        rolled_back_to: crash.rolled_back_to,
    })
}
