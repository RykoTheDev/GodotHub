pub fn get_os_username() -> Option<String> {
    for var in ["USERNAME", "USER", "LOGNAME"] {
        if let Ok(v) = std::env::var(var) {
            if !v.trim().is_empty() {
                return Some(v);
            }
        }
    }
    let home = std::env::var("HOME")
        .or_else(|_| std::env::var("USERPROFILE"))
        .ok()?;
    std::path::Path::new(&home)
        .file_name()
        .map(|s| s.to_string_lossy().to_string())
}
