use std::process::Command;

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct RunningProcess {
    pub pid: u32,
    pub project_path: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ProcessLiveness {
    Alive,
    Exited,
    Unknown,
}

pub(crate) fn parse_path_arg(cmdline: &str) -> Option<String> {
    let start = cmdline
        .match_indices("--path")
        .find(|(index, _)| {
            let before_ok = *index == 0
                || cmdline[..*index]
                    .chars()
                    .last()
                    .map(|c| c.is_ascii_whitespace())
                    .unwrap_or(false);
            let after = &cmdline[*index + "--path".len()..];
            let after_ok = after
                .chars()
                .next()
                .map(|c| c.is_ascii_whitespace() || c == '=')
                .unwrap_or(true);
            before_ok && after_ok
        })
        .map(|(index, _)| index + "--path".len())?;

    let rest = cmdline[start..]
        .trim_start()
        .strip_prefix('=')
        .unwrap_or_else(|| cmdline[start..].trim_start());
    if let Some(rest) = rest.strip_prefix('"') {
        let end = rest.find('"')?;
        let path = &rest[..end];
        return (!path.is_empty()).then(|| path.to_string());
    }
    let end = rest.find(char::is_whitespace).unwrap_or(rest.len());
    let path = &rest[..end];
    (!path.is_empty()).then(|| path.to_string())
}

#[cfg(target_os = "windows")]
fn parse_windows_process_output(output: &str) -> Vec<RunningProcess> {
    let mut processes = output
        .lines()
        .filter_map(|line| {
            let (pid, command_line) = line.split_once('\t')?;
            let pid = pid.trim().parse().ok()?;
            let project_path = parse_path_arg(command_line.trim())?;
            Some(RunningProcess { pid, project_path })
        })
        .collect::<Vec<_>>();

    let mut pid = None;
    let mut command_line: Option<&str> = None;
    for line in output.lines().map(str::trim) {
        if let Some(value) = line.strip_prefix("ProcessId=") {
            pid = value.trim().parse().ok();
        } else if let Some(value) = line.strip_prefix("CommandLine=") {
            command_line = Some(value.trim());
        }
        if let (Some(pid_value), Some(command_value)) = (pid, command_line) {
            if let Some(project_path) = parse_path_arg(command_value) {
                processes.push(RunningProcess {
                    pid: pid_value,
                    project_path,
                });
            }
            pid = None;
            command_line = None;
        }
    }

    processes
}

#[cfg(unix)]
fn parse_unix_process_output(output: &str) -> Vec<RunningProcess> {
    output
        .lines()
        .filter_map(|line| {
            let line = line.trim();
            let (pid, command_line) = line.split_once(char::is_whitespace)?;
            let pid = pid.trim().parse().ok()?;
            if !command_line.to_ascii_lowercase().contains("godot") {
                return None;
            }
            let project_path = parse_path_arg(command_line.trim())?;
            Some(RunningProcess { pid, project_path })
        })
        .collect()
}

pub(crate) fn find_running_godot_processes() -> Result<Vec<RunningProcess>, String> {
    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;

        const POWERSHELL_QUERY: &str = r#"
$processes = if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
    Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'"
} else {
    Get-WmiObject Win32_Process -Filter "Name LIKE 'Godot%'"
}
$processes | Where-Object { $_.CommandLine } | ForEach-Object {
    "{0}`t{1}" -f $_.ProcessId, $_.CommandLine
}
"#;

        let powershell = Command::new("powershell.exe")
            .args([
                "-NoLogo",
                "-NoProfile",
                "-NonInteractive",
                "-Command",
                POWERSHELL_QUERY,
            ])
            .creation_flags(crate::terminal::CREATE_NO_WINDOW)
            .output();

        return match powershell {
            Ok(output) if output.status.success() => Ok(parse_windows_process_output(
                &String::from_utf8_lossy(&output.stdout),
            )),
            _ => {
                let output = Command::new("wmic")
                    .args([
                        "process",
                        "where",
                        "name like 'Godot%'",
                        "get",
                        "processid,commandline",
                        "/format:list",
                    ])
                    .creation_flags(crate::terminal::CREATE_NO_WINDOW)
                    .output()
                    .map_err(|e| e.to_string())?;
                if !output.status.success() {
                    return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
                }
                Ok(parse_windows_process_output(&String::from_utf8_lossy(
                    &output.stdout,
                )))
            }
        };
    }

    #[cfg(unix)]
    {
        let output = Command::new("ps")
            .args(["-eo", "pid=,args="])
            .output()
            .map_err(|e| e.to_string())?;
        if !output.status.success() {
            return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
        }
        Ok(parse_unix_process_output(&String::from_utf8_lossy(
            &output.stdout,
        )))
    }
}

pub(crate) fn process_liveness(pid: u32) -> ProcessLiveness {
    #[cfg(target_os = "windows")]
    {
        use windows_sys::Win32::Foundation::CloseHandle;
        use windows_sys::Win32::System::Threading::{
            GetExitCodeProcess, OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION,
        };

        let handle = unsafe { OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid) };
        if handle.is_null() {
            return ProcessLiveness::Unknown;
        }
        let mut exit_code = 0u32;
        let queried = unsafe { GetExitCodeProcess(handle, &mut exit_code) != 0 };
        unsafe { CloseHandle(handle) };
        if !queried {
            ProcessLiveness::Unknown
        } else if exit_code == 259 {
            ProcessLiveness::Alive
        } else {
            ProcessLiveness::Exited
        }
    }

    #[cfg(unix)]
    {
        let result = unsafe { libc::kill(pid as libc::pid_t, 0) };
        if result == 0 {
            return ProcessLiveness::Alive;
        }
        match std::io::Error::last_os_error().raw_os_error() {
            Some(code) if code == libc::ESRCH => ProcessLiveness::Exited,
            _ => ProcessLiveness::Unknown,
        }
    }
}

pub(crate) fn terminate_process(pid: u32) -> Result<(), String> {
    #[cfg(target_os = "windows")]
    {
        use windows_sys::Win32::Foundation::CloseHandle;
        use windows_sys::Win32::System::Threading::{
            OpenProcess, TerminateProcess, PROCESS_TERMINATE,
        };

        let handle = unsafe { OpenProcess(PROCESS_TERMINATE, 0, pid) };
        if handle.is_null() {
            return Err(std::io::Error::last_os_error().to_string());
        }
        let result = unsafe { TerminateProcess(handle, 1) };
        unsafe { CloseHandle(handle) };
        if result == 0 {
            return Err(std::io::Error::last_os_error().to_string());
        }
        return Ok(());
    }

    #[cfg(unix)]
    {
        if unsafe { libc::kill(pid as libc::pid_t, libc::SIGKILL) } == 0 {
            return Ok(());
        }
        Err(std::io::Error::last_os_error().to_string())
    }
}

#[cfg(test)]
#[path = "../tests/common/process.rs"]
mod process_common_tests;

#[cfg(target_os = "windows")]
#[cfg(test)]
#[path = "../tests/windows/process.rs"]
mod windows_process_tests;

#[cfg(unix)]
#[cfg(test)]
#[path = "../tests/unix/process.rs"]
mod unix_process_tests;
