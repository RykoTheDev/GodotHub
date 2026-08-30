#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    #[cfg(target_os = "linux")]
    {
        std::env::set_var("GDK_BACKEND", "wayland,x11");

        if std::env::var("WEBKIT_DISABLE_DMABUF_RENDERER").is_err() {
            std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");
        }

        if std::env::var("GSK_RENDERER").is_err() {
            std::env::set_var("GSK_RENDERER", "ngl");
        }

    }

    godothub_lib::run()
}
