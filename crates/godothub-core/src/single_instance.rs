use std::io::{BufRead, BufReader, Write};

use interprocess::local_socket::{prelude::*, GenericNamespaced, ListenerOptions, Stream};

use crate::Channel;

fn socket_name(channel: Channel) -> String {
    let user: String = crate::system::get_os_username()
        .unwrap_or_default()
        .chars()
        .filter(char::is_ascii_alphanumeric)
        .collect();
    format!("{}.{user}.sock", channel.info().single_instance_key)
}

fn forward_to(name: &str, args: &[String]) -> bool {
    let Ok(name) = name.to_ns_name::<GenericNamespaced>() else {
        return false;
    };
    let Ok(mut stream) = Stream::connect(name) else {
        return false;
    };
    allow_foreground_handoff();
    let Ok(payload) = serde_json::to_string(args) else {
        return false;
    };
    stream
        .write_all(payload.as_bytes())
        .and_then(|()| stream.write_all(b"\n"))
        .and_then(|()| stream.flush())
        .is_ok()
}

fn listen_on<F>(name: &str, on_args: F) -> Result<(), String>
where
    F: Fn(Vec<String>) + Send + 'static,
{
    let ns_name = name.to_ns_name::<GenericNamespaced>().map_err(|e| e.to_string())?;
    let listener = ListenerOptions::new()
        .name(ns_name)
        .try_overwrite(true)
        .create_sync()
        .map_err(|e| e.to_string())?;
    std::thread::Builder::new()
        .name("godothub-single-instance".into())
        .spawn(move || {
            for connection in listener.incoming().filter_map(Result::ok) {
                let mut line = String::new();
                if BufReader::new(connection).read_line(&mut line).is_err() {
                    continue;
                }
                if let Ok(args) = serde_json::from_str::<Vec<String>>(line.trim()) {
                    on_args(args);
                }
            }
        })
        .map(|_| ())
        .map_err(|e| e.to_string())
}

pub fn forward_to_running_instance(channel: Channel, args: &[String]) -> bool {
    forward_to(&socket_name(channel), args)
}

pub fn listen_for_other_instances<F>(channel: Channel, on_args: F) -> Result<(), String>
where
    F: Fn(Vec<String>) + Send + 'static,
{
    listen_on(&socket_name(channel), on_args)
}

#[cfg(windows)]
fn allow_foreground_handoff() {
    use windows_sys::Win32::UI::WindowsAndMessaging::{AllowSetForegroundWindow, ASFW_ANY};
    unsafe {
        AllowSetForegroundWindow(ASFW_ANY);
    }
}

#[cfg(not(windows))]
fn allow_foreground_handoff() {}

#[no_mangle]
pub extern "C" fn godothub_forward_to_running_instance(channel: u32) -> bool {
    let channel = if channel == 0 { Channel::Stable } else { Channel::Beta };
    let args: Vec<String> = std::env::args().collect();
    std::panic::catch_unwind(|| forward_to_running_instance(channel, &args)).unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::mpsc;
    use std::time::Duration;

    #[test]
    fn a_second_launch_forwards_its_arguments() {
        let name = format!("godothub-test-{}.sock", uuid::Uuid::new_v4().simple());
        assert!(!forward_to(&name, &["nobody listening".into()]));

        let (tx, rx) = mpsc::channel();
        listen_on(&name, move |args| {
            let _ = tx.send(args);
        })
        .unwrap();

        let args = vec!["GodotHub Beta".to_string(), "--open-project=abc".to_string()];
        assert!(forward_to(&name, &args));
        assert_eq!(rx.recv_timeout(Duration::from_secs(5)).unwrap(), args);
        assert!(forward_to(&name, &["again".into()]));
        assert_eq!(rx.recv_timeout(Duration::from_secs(5)).unwrap(), vec!["again".to_string()]);
    }

    #[test]
    fn channels_use_different_sockets() {
        assert_ne!(socket_name(Channel::Stable), socket_name(Channel::Beta));
        assert!(socket_name(Channel::Beta).starts_with("Ryko.GodotHub.Beta."));
    }
}
