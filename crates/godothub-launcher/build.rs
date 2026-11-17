fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    static_vcruntime::metabuild();
    let manifest = std::path::PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    println!("cargo:rerun-if-env-changed=GODOTHUB_VERSION");
    let (product, binary) = ("GodotHub", "godothub.exe");
    let icon = manifest.join("../../app/windows/runner/resources/app_icon.ico");
    let icon = icon.canonicalize().expect("app icon");
    println!("cargo:rerun-if-changed={}", icon.display());
    let path = icon.to_string_lossy().trim_start_matches(r"\\?\").replace('\\', "/");

    let version = std::env::var("GODOTHUB_VERSION").unwrap_or_else(|_| std::env::var("CARGO_PKG_VERSION").unwrap());
    let numbers: Vec<u16> = version.split(['.', '-', '+']).take(3).map(|part| part.parse().unwrap_or(0)).collect();
    let [major, minor, patch] = [0, 1, 2].map(|i| numbers.get(i).copied().unwrap_or(0));
    let resource = format!(
        r#"1 ICON "{path}"
1 VERSIONINFO
FILEVERSION {major},{minor},{patch},0
PRODUCTVERSION {major},{minor},{patch},0
FILEOS 0x40004
FILETYPE 0x1
BEGIN
  BLOCK "StringFileInfo"
  BEGIN
    BLOCK "040904b0"
    BEGIN
      VALUE "CompanyName", "Rykode"
      VALUE "FileDescription", "{product}"
      VALUE "FileVersion", "{version}"
      VALUE "InternalName", "{product}"
      VALUE "LegalCopyright", "Copyright (C) 2026 Ryko"
      VALUE "OriginalFilename", "{binary}"
      VALUE "ProductName", "{product}"
      VALUE "ProductVersion", "{version}"
    END
  END
  BLOCK "VarFileInfo"
  BEGIN
    VALUE "Translation", 0x409, 1200
  END
END
"#
    );
    let out = std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("launcher.rc");
    std::fs::write(&out, resource).unwrap();
    embed_resource::compile(&out, embed_resource::NONE).manifest_optional().unwrap();
}
