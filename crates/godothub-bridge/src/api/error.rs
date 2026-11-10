#[flutter_rust_bridge::frb(dart_code = "@override
  String toString() => 'CoreError: $message';")]
#[derive(Debug, Clone)]
pub struct CoreError {
    pub message: String,
}

impl From<String> for CoreError {
    fn from(message: String) -> Self {
        Self { message }
    }
}

impl From<&str> for CoreError {
    fn from(message: &str) -> Self {
        Self {
            message: message.to_string(),
        }
    }
}

impl std::fmt::Display for CoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.message)
    }
}
