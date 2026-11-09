use std::sync::OnceLock;
use std::time::Duration;

pub fn client() -> Result<reqwest::Client, String> {
    static CLIENT: OnceLock<Result<reqwest::Client, String>> = OnceLock::new();
    CLIENT
        .get_or_init(|| {
            reqwest::Client::builder()
                .user_agent(format!("godot-hub/{}", crate::app_version()))
                .connect_timeout(Duration::from_secs(30))
                .gzip(true)
                .build()
                .map_err(|e| e.to_string())
        })
        .clone()
}
