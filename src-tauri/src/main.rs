#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    if let Some(code) = godothub_lib::run_cli() {
        std::process::exit(code);
    }

    #[cfg(target_os = "linux")]
    {
        std::env::set_var("GDK_BACKEND", "wayland,x11");

        // Stay on WebKitGTK's accelerated (DMA-BUF) path so the UI is painted on
        // the GPU. The software fallback is only requested on machines where the
        // accelerated path is known to fail. See `godothub_core::renderer`.
        godothub_core::renderer::prepare();

        if std::env::var("GSK_RENDERER").is_err() {
            std::env::set_var("GSK_RENDERER", "ngl");
        }
    }

    godothub_lib::run()
}
