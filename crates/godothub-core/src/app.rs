use std::any::{Any, TypeId};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, OnceLock, PoisonError, RwLock};

use serde::Serialize;
use serde_json::value::RawValue;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Channel {
    Stable,
    Beta,
}

#[derive(Debug)]
pub struct ChannelInfo {
    pub identifier: &'static str,
    pub display_name: &'static str,
    pub cli_shim_name: &'static str,
    pub update_endpoint: &'static str,
    pub updater_public_keys: &'static [&'static str],
    pub single_instance_key: &'static str,
}

const UPDATER_PUBLIC_KEY_V2: &str = "dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IDQ2NUUyOUY1RUExQTIyMTQKUldRVUlocnE5U2xlUmtpOVRDZTAvWWtwM2dkUWpSb0ZadTkzeS8xOEhFVkU1UVlMUWRwN0h3VW8K";

const STABLE: ChannelInfo = ChannelInfo {
    identifier: "Ryko.GodotHub",
    display_name: "GodotHub",
    cli_shim_name: "godothub",
    update_endpoint: "https://github.com/RykoTheDev/godothub/releases/latest/download/latest-v2.json",
    updater_public_keys: &[UPDATER_PUBLIC_KEY_V2],
    single_instance_key: "Ryko.GodotHub",
};

const BETA: ChannelInfo = ChannelInfo {
    identifier: "Ryko.GodotHub.Beta",
    display_name: "GodotHub Beta",
    cli_shim_name: "godothub-beta",
    update_endpoint: "https://github.com/RykoTheDev/godothub/releases/download/flutter-beta/latest.json",
    updater_public_keys: &[UPDATER_PUBLIC_KEY_V2],
    single_instance_key: "Ryko.GodotHub.Beta",
};

impl Channel {
    pub const fn info(self) -> &'static ChannelInfo {
        match self {
            Channel::Stable => &STABLE,
            Channel::Beta => &BETA,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct UnknownPath;

impl std::fmt::Display for UnknownPath {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("unknown path")
    }
}

impl std::error::Error for UnknownPath {}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paths {
    data: Option<PathBuf>,
    config: Option<PathBuf>,
    cache: Option<PathBuf>,
}

impl Paths {
    pub fn for_channel(channel: Channel) -> Self {
        let identifier = channel.info().identifier;
        Self {
            data: dirs::data_dir().map(|dir| dir.join(identifier)),
            config: dirs::config_dir().map(|dir| dir.join(identifier)),
            cache: dirs::cache_dir().map(|dir| dir.join(identifier)),
        }
    }

    pub fn at(data: PathBuf, config: PathBuf, cache: PathBuf) -> Self {
        Self {
            data: Some(data),
            config: Some(config),
            cache: Some(cache),
        }
    }

    pub fn app_data_dir(&self) -> Result<PathBuf, UnknownPath> {
        self.data.clone().ok_or(UnknownPath)
    }

    pub fn app_config_dir(&self) -> Result<PathBuf, UnknownPath> {
        self.config.clone().ok_or(UnknownPath)
    }

    pub fn app_cache_dir(&self) -> Result<PathBuf, UnknownPath> {
        self.cache.clone().ok_or(UnknownPath)
    }

    pub fn download_dir(&self) -> Result<PathBuf, UnknownPath> {
        dirs::download_dir().ok_or(UnknownPath)
    }

    pub fn home_dir(&self) -> Result<PathBuf, UnknownPath> {
        dirs::home_dir().ok_or(UnknownPath)
    }
}

pub trait EventSink: Send + Sync {
    fn emit(&self, event: &str, payload: &RawValue);
}

pub trait Host: Send + Sync {
    fn show_main_window(&self);
    fn hide_main_window(&self);
    fn exit(&self, code: i32);
    fn refresh_menus(&self);
    fn main_window_visible(&self) -> Option<bool> {
        None
    }
}

type StateMap = HashMap<TypeId, Arc<dyn Any + Send + Sync>>;

struct Inner {
    channel: Channel,
    paths: Paths,
    events: Arc<dyn EventSink>,
    host: Arc<dyn Host>,
    states: RwLock<StateMap>,
}

#[derive(Clone)]
pub struct AppHandle(Arc<Inner>);

impl AppHandle {
    pub fn new(channel: Channel, paths: Paths, events: Arc<dyn EventSink>, host: Arc<dyn Host>) -> Self {
        Self(Arc::new(Inner {
            channel,
            paths,
            events,
            host,
            states: RwLock::new(HashMap::new()),
        }))
    }

    pub fn channel(&self) -> Channel {
        self.0.channel
    }

    pub fn path(&self) -> &Paths {
        &self.0.paths
    }

    pub fn host(&self) -> &dyn Host {
        self.0.host.as_ref()
    }

    pub fn emit<S: Serialize>(&self, event: &str, payload: S) -> Result<(), serde_json::Error> {
        let raw = serde_json::value::to_raw_value(&payload)?;
        self.0.events.emit(event, &raw);
        Ok(())
    }

    pub fn manage<T: Send + Sync + 'static>(&self, state: T) -> bool {
        let mut states = self.0.states.write().unwrap_or_else(PoisonError::into_inner);
        if states.contains_key(&TypeId::of::<T>()) {
            return false;
        }
        states.insert(TypeId::of::<T>(), Arc::new(state));
        true
    }

    pub fn try_state<T: Send + Sync + 'static>(&self) -> Option<Arc<T>> {
        let states = self.0.states.read().unwrap_or_else(PoisonError::into_inner);
        states.get(&TypeId::of::<T>()).cloned().and_then(|state| state.downcast::<T>().ok())
    }

    pub fn state<T: Send + Sync + 'static>(&self) -> Arc<T> {
        self.try_state::<T>()
            .unwrap_or_else(|| panic!("state not managed for {}", std::any::type_name::<T>()))
    }
}

static APP_VERSION: OnceLock<&'static str> = OnceLock::new();

pub fn set_app_version(version: &'static str) {
    let _ = APP_VERSION.set(version);
}

pub fn app_version() -> &'static str {
    APP_VERSION.get().copied().unwrap_or(env!("CARGO_PKG_VERSION"))
}

#[cfg(test)]
mod tests {
    use super::*;

    struct Recorder(std::sync::Mutex<Vec<(String, String)>>);

    impl EventSink for Recorder {
        fn emit(&self, event: &str, payload: &RawValue) {
            self.0.lock().unwrap().push((event.to_string(), payload.get().to_string()));
        }
    }

    struct NoHost;

    impl Host for NoHost {
        fn show_main_window(&self) {}
        fn hide_main_window(&self) {}
        fn exit(&self, _code: i32) {}
        fn refresh_menus(&self) {}
    }

    #[derive(Serialize)]
    struct Payload {
        zeta: u32,
        alpha: &'static str,
    }

    fn handle(recorder: Arc<Recorder>) -> AppHandle {
        AppHandle::new(Channel::Stable, Paths::for_channel(Channel::Stable), recorder, Arc::new(NoHost))
    }

    #[test]
    fn emit_keeps_payload_json_exactly() {
        let recorder = Arc::new(Recorder(std::sync::Mutex::new(Vec::new())));
        let app = handle(recorder.clone());
        app.emit("thing-happened", Payload { zeta: 1, alpha: "a" }).unwrap();
        assert_eq!(
            recorder.0.lock().unwrap().as_slice(),
            &[("thing-happened".to_string(), r#"{"zeta":1,"alpha":"a"}"#.to_string())]
        );
    }

    #[test]
    fn state_is_managed_once_per_type() {
        let app = handle(Arc::new(Recorder(std::sync::Mutex::new(Vec::new()))));
        assert!(app.try_state::<u32>().is_none());
        assert!(app.manage(7u32));
        assert!(!app.manage(9u32));
        assert_eq!(*app.state::<u32>(), 7);
    }

    #[test]
    fn channels_map_to_their_own_identity() {
        assert_eq!(Channel::Stable.info().identifier, "Ryko.GodotHub");
        assert_eq!(Channel::Beta.info().identifier, "Ryko.GodotHub.Beta");
        assert_eq!(Channel::Stable.info().cli_shim_name, "godothub");
        assert_eq!(Channel::Beta.info().cli_shim_name, "godothub-beta");
        assert_eq!(Channel::Stable.info().single_instance_key, Channel::Stable.info().identifier);
        assert_ne!(Channel::Stable.info().update_endpoint, Channel::Beta.info().update_endpoint);
        let stable = Paths::for_channel(Channel::Stable).app_data_dir().unwrap();
        let beta = Paths::for_channel(Channel::Beta).app_data_dir().unwrap();
        assert_ne!(stable, beta);
        assert_eq!(stable.parent(), beta.parent());
    }
}
