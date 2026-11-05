use std::sync::OnceLock;
use std::time::Duration;

pub fn client() -> Result<reqwest::Client, String> {
    static CLIENT: OnceLock<Result<reqwest::Client, String>> = OnceLock::new();
    CLIENT
        .get_or_init(|| {
            reqwest::Client::builder()
                .user_agent(concat!("godot-hub/", env!("CARGO_PKG_VERSION")))
                .connect_timeout(Duration::from_secs(30))
                .gzip(true)
                .build()
                .map_err(|e| e.to_string())
        })
        .clone()
}
