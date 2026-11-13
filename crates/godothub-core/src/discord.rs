use std::sync::mpsc::{self, Receiver, RecvTimeoutError, Sender};
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use discord_rich_presence::activity::{Activity, Timestamps};
use discord_rich_presence::{DiscordIpc, DiscordIpcClient};
use serde_json::Value;

use crate::AppHandle;

pub const CONNECTED_EVENT: &str = "discord-rpc://connected";

const LIVENESS: Duration = Duration::from_secs(2);
const IDLE: Duration = Duration::from_secs(60);

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct DiscordActivity {
    pub name: Option<String>,
    pub details: Option<String>,
    pub state: Option<String>,
    pub start_timestamp: Option<i64>,
}

enum Cmd {
    Connect(String, Sender<Result<(), String>>),
    Disconnect,
    Set(Option<DiscordActivity>),
}

fn sender(app: &AppHandle) -> Sender<Cmd> {
    static TX: OnceLock<Mutex<Sender<Cmd>>> = OnceLock::new();
    TX.get_or_init(|| {
        let (tx, rx) = mpsc::channel();
        let app = app.clone();
        std::thread::Builder::new()
            .name("godothub-discord".into())
            .spawn(move || Worker::new(app).run(rx))
            .expect("spawn discord worker");
        Mutex::new(tx)
    })
    .lock()
    .unwrap_or_else(std::sync::PoisonError::into_inner)
    .clone()
}

pub fn connect(app: &AppHandle, app_id: String) -> Result<(), String> {
    let (reply, result) = mpsc::channel();
    sender(app).send(Cmd::Connect(app_id, reply)).map_err(|e| e.to_string())?;
    result.recv().map_err(|e| e.to_string())?
}

pub fn disconnect(app: &AppHandle) {
    let _ = sender(app).send(Cmd::Disconnect);
}

pub fn set_activity(app: &AppHandle, activity: Option<DiscordActivity>) {
    let _ = sender(app).send(Cmd::Set(activity));
}

pub(crate) fn backoff_delay(attempt: u32) -> Duration {
    let ms = 500u64.saturating_mul(1u64 << attempt.min(16));
    Duration::from_millis(ms.min(8000))
}

fn build(activity: &DiscordActivity) -> Activity<'_> {
    let mut built = Activity::new();
    if let Some(name) = activity.name.as_deref().filter(|s| !s.is_empty()) {
        built = built.name(name);
    }
    if let Some(details) = activity.details.as_deref().filter(|s| !s.is_empty()) {
        built = built.details(details);
    }
    if let Some(state) = activity.state.as_deref().filter(|s| !s.is_empty()) {
        built = built.state(state);
    }
    if let Some(start) = activity.start_timestamp {
        built = built.timestamps(Timestamps::new().start(start));
    }
    built
}

fn alive(opcode: u32) -> bool {
    opcode != 2
}

fn ready(opcode: u32, data: &Value) -> bool {
    alive(opcode) && data.get("evt").and_then(Value::as_str) != Some("ERROR")
}

struct Worker {
    app: AppHandle,
    app_id: Option<String>,
    client: Option<DiscordIpcClient>,
    desired: Option<DiscordActivity>,
    attempt: u32,
    next_try: Option<Instant>,
    last_ping: Instant,
}

impl Worker {
    fn new(app: AppHandle) -> Self {
        Self {
            app,
            app_id: None,
            client: None,
            desired: None,
            attempt: 0,
            next_try: None,
            last_ping: Instant::now(),
        }
    }

    fn emit(&self, connected: bool) {
        let _ = self.app.emit(CONNECTED_EVENT, connected);
    }

    fn timeout(&self) -> Duration {
        let now = Instant::now();
        if self.client.is_some() {
            return LIVENESS.saturating_sub(now - self.last_ping);
        }
        match self.next_try {
            Some(at) => at.saturating_duration_since(now),
            None => IDLE,
        }
    }

    fn run(mut self, rx: Receiver<Cmd>) {
        loop {
            match rx.recv_timeout(self.timeout()) {
                Ok(Cmd::Connect(app_id, reply)) => {
                    let _ = reply.send(self.connect(app_id));
                }
                Ok(Cmd::Disconnect) => self.disconnect(),
                Ok(Cmd::Set(activity)) => {
                    self.desired = activity;
                    if self.client.is_some() {
                        self.apply();
                    }
                }
                Err(RecvTimeoutError::Timeout) => self.tick(),
                Err(RecvTimeoutError::Disconnected) => {
                    self.disconnect();
                    break;
                }
            }
        }
    }

    fn connect(&mut self, app_id: String) -> Result<(), String> {
        if self.app_id.as_deref() == Some(app_id.as_str()) && self.client.is_some() {
            return Ok(());
        }
        self.close();
        self.app_id = Some(app_id);
        self.attempt = 0;
        match self.try_connect() {
            Ok(()) => Ok(()),
            Err(error) => {
                self.schedule_retry();
                Err(error)
            }
        }
    }

    fn try_connect(&mut self) -> Result<(), String> {
        let Some(app_id) = self.app_id.clone() else {
            return Err("No Discord application id".into());
        };
        let mut client = DiscordIpcClient::new(&app_id);
        client.connect().map_err(|e| e.to_string())?;
        match client.recv() {
            Ok((opcode, data)) if ready(opcode, &data) => {}
            Ok(_) => {
                let _ = client.close();
                return Err("Discord rejected the connection".into());
            }
            Err(error) => {
                let _ = client.close();
                return Err(error.to_string());
            }
        }
        self.client = Some(client);
        self.attempt = 0;
        self.next_try = None;
        self.last_ping = Instant::now();
        self.emit(true);
        if self.desired.is_some() {
            self.apply();
        }
        Ok(())
    }

    fn schedule_retry(&mut self) {
        self.next_try = Some(Instant::now() + backoff_delay(self.attempt));
        self.attempt = self.attempt.saturating_add(1);
    }

    fn tick(&mut self) {
        if self.client.is_some() {
            self.ping();
            return;
        }
        if self.app_id.is_some() && self.next_try.is_some_and(|at| Instant::now() >= at) && self.try_connect().is_err() {
            self.schedule_retry();
        }
    }

    fn exchange(&mut self, send: impl FnOnce(&mut DiscordIpcClient) -> bool) {
        let Some(client) = self.client.as_mut() else {
            return;
        };
        let ok = send(client) && matches!(client.recv(), Ok((opcode, _)) if alive(opcode));
        self.last_ping = Instant::now();
        if !ok {
            self.drop_connection();
        }
    }

    fn apply(&mut self) {
        let desired = self.desired.clone();
        self.exchange(|client| match &desired {
            Some(activity) => client.set_activity(build(activity)).is_ok(),
            None => client.clear_activity().is_ok(),
        });
    }

    fn ping(&mut self) {
        self.exchange(|client| client.send(serde_json::json!({}), 3).is_ok());
    }

    fn drop_connection(&mut self) {
        if let Some(mut client) = self.client.take() {
            let _ = client.close();
            self.emit(false);
        }
        if self.app_id.is_some() {
            self.attempt = 0;
            self.schedule_retry();
        }
    }

    fn close(&mut self) {
        if let Some(mut client) = self.client.take() {
            let _ = client.clear_activity();
            let _ = client.close();
            self.emit(false);
        }
    }

    fn disconnect(&mut self) {
        self.close();
        self.app_id = None;
        self.next_try = None;
        self.attempt = 0;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn backoff_is_capped_exponential() {
        assert_eq!(backoff_delay(0), Duration::from_millis(500));
        assert_eq!(backoff_delay(1), Duration::from_millis(1000));
        assert_eq!(backoff_delay(3), Duration::from_millis(4000));
        assert_eq!(backoff_delay(4), Duration::from_millis(8000));
        assert_eq!(backoff_delay(30), Duration::from_millis(8000));
    }

    #[test]
    fn close_frames_end_the_connection_and_errors_only_fail_the_handshake() {
        assert!(!alive(2));
        assert!(alive(1));
        assert!(alive(3));
        assert!(ready(1, &serde_json::json!({"evt": "READY"})));
        assert!(!ready(1, &serde_json::json!({"evt": "ERROR"})));
        assert!(!ready(2, &serde_json::json!({})));
    }

    #[test]
    fn activity_skips_empty_fields() {
        let activity = DiscordActivity {
            name: Some("GodotHub".into()),
            details: Some(String::new()),
            state: Some("Godot 4.3".into()),
            start_timestamp: Some(1),
        };
        let json = serde_json::to_value(build(&activity)).unwrap();
        assert_eq!(json["name"], "GodotHub");
        assert_eq!(json["state"], "Godot 4.3");
        assert!(json.get("details").is_none());
        assert_eq!(json["timestamps"]["start"], 1);
    }
}
