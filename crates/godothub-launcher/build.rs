fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    static_vcruntime::metabuild();
    let manifest = std::path::PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    println!("cargo:rerun-if-env-changed=GODOTHUB_CHANNEL");
    let name = match std::env::var("GODOTHUB_CHANNEL").as_deref() {
        Ok("stable") => "app_icon_stable.ico",
        _ => "app_icon.ico",
    };
    let icon = manifest.join("../../app/windows/runner/resources").join(name);
    let icon = icon.canonicalize().expect("app icon");
    println!("cargo:rerun-if-changed={}", icon.display());
    let out = std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("launcher.rc");
    let path = icon.to_string_lossy().trim_start_matches(r"\\?\").replace('\\', "/");
    std::fs::write(&out, format!("1 ICON \"{path}\"\n")).unwrap();
    embed_resource::compile(&out, embed_resource::NONE).manifest_optional().unwrap();
}
