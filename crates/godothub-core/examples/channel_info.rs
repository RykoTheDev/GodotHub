use godothub_core::Channel;

fn main() {
    let channel = match std::env::args().nth(1).as_deref() {
        Some("stable") => Channel::Stable,
        Some("beta") | None => Channel::Beta,
        Some(other) => {
            eprintln!("unknown channel {other:?}, expected stable or beta");
            std::process::exit(2);
        }
    };
    let info = channel.info();
    let json = serde_json::json!({
        "identifier": info.identifier,
        "display_name": info.display_name,
        "cli_shim_name": info.cli_shim_name,
        "update_endpoint": info.update_endpoint,
        "single_instance_key": info.single_instance_key,
    });
    println!("{json}");
}
