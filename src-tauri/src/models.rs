use serde::{Deserialize, Serialize};
use std::sync::OnceLock;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstalledGodotVersion {
    pub tag: String,
    pub version: String,
    pub executable_path: String,
    pub is_mono: bool,
    pub installed_at: String,
    #[serde(default)]
    pub custom_name: Option<String>,
    #[serde(default)]
    pub install_root: Option<String>,
    #[serde(default)]
    pub supports_console: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewsItem {
    pub id: String,
    pub title: String,
    pub link: String,
    pub published: Option<String>,
    pub summary: Option<String>,
    pub author: Option<String>,
    pub category: Option<String>,
    #[serde(default)]
    pub image: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GodotReleaseAsset {
    pub name: String,
    pub download_url: String,
    pub size: u64,
    #[serde(default)]
    pub is_mono: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GodotRelease {
    pub tag: String,
    pub assets: Vec<GodotReleaseAsset>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Project {
    pub id: String,
    pub name: String,
    pub path: String,
    pub godot_version: String,
    #[serde(default)]
    pub created_at: String,
    pub last_opened: Option<String>,
    #[serde(default)]
    pub category: Option<String>,
    #[serde(default)]
    pub pinned: bool,
    #[serde(default)]
    pub sort_order: i64,
    #[serde(default)]
    pub launch_arguments: String,
    #[serde(default)]
    pub tags: Vec<String>,
    #[serde(default)]
    pub total_time_seconds: u64,
    #[serde(default)]
    pub session_started_at_ms: Option<u64>,
    #[serde(default)]
    pub time_today_seconds: u64,
    #[serde(default)]
    pub time_week_seconds: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Category {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub sort_order: i64,
    #[serde(default = "default_category_color")]
    pub color: String,
}

fn default_category_color() -> String {
    default_accent()
}

#[derive(Debug, Clone, Serialize)]
pub struct ChangelogNote {
    pub category: String,
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateEntry {
    pub id: String,
    pub kind: String,
    pub title: String,
    pub body: String,
    #[serde(default)]
    pub command: Option<String>,
    #[serde(default)]
    pub is_new: bool,
    #[serde(default)]
    pub featured: bool,
    #[serde(default)]
    pub link: Option<String>,
    #[serde(default)]
    pub created_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangelogEntry {
    pub id: String,
    pub version: String,
    #[serde(default)]
    pub date: String,
    #[serde(default)]
    pub notes: Vec<ChangelogNote>,
    #[serde(default)]
    pub known_issues: Vec<String>,
    #[serde(default)]
    pub created_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectUpdate {
    pub name: Option<String>,
    pub godot_version: Option<String>,
    #[serde(default)]
    pub category: Option<String>,
    #[serde(default)]
    pub pinned: Option<bool>,
    #[serde(default)]
    pub launch_arguments: Option<String>,
    #[serde(default)]
    pub tags: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DownloadProgress {
    pub tag: String,
    pub downloaded: u64,
    pub total: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppSettings {
    pub download_dir: Option<String>,
    #[serde(default)]
    pub default_project_location: Option<String>,
    #[serde(default)]
    pub project_scan_dirs: Vec<String>,
    #[serde(default)]
    pub version_scan_dirs: Vec<String>,
    #[serde(default = "default_scan_depth")]
    pub scan_depth: u32,
    #[serde(default = "default_icon_scan_depth")]
    pub icon_scan_depth: u32,
    #[serde(default = "default_download_concurrency")]
    pub download_concurrency: u32,
    #[serde(default = "default_accent")]
    pub accent_color: String,
    #[serde(default = "default_background")]
    pub background_color: String,
    #[serde(default = "default_corner_radius")]
    pub corner_radius: f64,
    #[serde(default = "default_raised_contrast")]
    pub raised_contrast: u32,
    #[serde(default = "default_ui_density")]
    pub ui_density: f64,
    #[serde(default = "default_font_scale")]
    pub font_scale: f64,
    #[serde(default = "default_theme_mode")]
    pub theme_mode: String,
    #[serde(default)]
    pub custom_css: String,
    #[serde(default = "default_animation_intensity")]
    pub animation_intensity: String,
    #[serde(default = "default_view_entrance")]
    pub view_entrance: String,
    #[serde(default)]
    pub launch_with_console: bool,
    #[serde(default)]
    pub close_on_project_open: bool,
    #[serde(default)]
    pub minimize_to_tray: bool,
    #[serde(default)]
    pub reopen_after_godot_closes: bool,
    #[serde(default = "default_last_opened_time_format")]
    pub last_opened_time_format: String,
    #[serde(default = "default_last_opened_date_format")]
    pub last_opened_date_format: String,
    #[serde(default)]
    pub setup_complete: bool,
    #[serde(default = "default_categories_enabled")]
    pub categories_enabled: bool,
    #[serde(default = "default_workspaces_enabled")]
    pub workspaces_enabled: bool,
    #[serde(default = "default_auto_scan")]
    pub auto_scan_on_startup: bool,
    #[serde(default = "default_palette_keybind")]
    pub command_palette_keybind: String,
    #[serde(default)]
    pub external_editor_path: Option<String>,
    #[serde(default)]
    pub github_token: Option<String>,
    #[serde(default)]
    pub template_scan_dir: Option<String>,
    #[serde(default)]
    pub discord_app_id: Option<String>,
    #[serde(default)]
    pub discord_rpc_enabled: bool,
    #[serde(default = "default_true")]
    pub discord_rpc_show_projects: bool,
    #[serde(default)]
    pub discord_rpc_excluded_projects: Vec<String>,
    #[serde(default)]
    pub discord_rpc_project_presences: Vec<DiscordProjectPresence>,
    #[serde(default = "default_tooltip_delay")]
    pub tooltip_delay: u32,
    #[serde(default = "default_watch_projects")]
    pub auto_watch_project_dirs: bool,
    #[serde(default = "default_watch_versions")]
    pub auto_watch_version_dirs: bool,
    #[serde(default = "default_watch_templates")]
    pub auto_watch_template_dir: bool,
    #[serde(default = "default_tray_recent_projects_count")]
    pub tray_recent_projects_count: u32,
    #[serde(default = "default_true")]
    pub show_support_button: bool,
    #[serde(default = "default_true")]
    pub show_star_button: bool,
    #[serde(default = "default_true")]
    pub show_bug_button: bool,
    #[serde(default = "default_true")]
    pub show_tray_button: bool,
    #[serde(default = "default_true")]
    pub show_language_button: bool,
    #[serde(default = "default_true")]
    pub show_scrollbars: bool,
    #[serde(default = "default_true")]
    pub animated_numbers: bool,
    #[serde(default = "default_true")]
    pub screen_reader_announcements: bool,
    #[serde(default = "default_project_icon_opacity")]
    pub project_icon_opacity: u32,
    #[serde(default = "default_animation_threshold")]
    pub animation_threshold: u32,
    #[serde(default = "default_language")]
    pub language: String,
    #[serde(default = "default_os_decorations")]
    pub use_os_decorations: bool,
    #[serde(default)]
    pub dismissed_project_paths: Vec<String>,
    #[serde(default = "default_naming_convention")]
    pub directory_naming_convention: String,
    #[serde(default = "default_theme_preset")]
    pub theme_preset: String,
    #[serde(default)]
    pub git_init_new_projects: bool,
    #[serde(default = "default_true")]
    pub open_after_import: bool,
    #[serde(default = "default_true")]
    pub card_layout: bool,
    #[serde(default)]
    pub dashboard_custom_name: Option<String>,
    #[serde(default = "default_landing_tab")]
    pub default_landing_tab: String,
    #[serde(default)]
    pub dashboard_sections: Vec<String>,
    #[serde(default)]
    pub dashboard_section_order: Vec<String>,
    #[serde(default)]
    pub dashboard_section_spans: Vec<String>,
    #[serde(default)]
    pub dashboard_tall_sections: Vec<String>,
    #[serde(default)]
    pub dashboard_custom_presets: Vec<DashboardCustomPreset>,
    #[serde(default)]
    pub auto_backup_interval_minutes: u32,
    #[serde(default = "default_true")]
    pub card_show_size: bool,
    #[serde(default = "default_true")]
    pub card_show_time: bool,
    #[serde(default)]
    pub card_blur_path: bool,
    #[serde(default = "default_true")]
    pub card_show_path: bool,
    #[serde(default = "default_true")]
    pub card_show_tags: bool,
    #[serde(default = "default_true")]
    pub card_show_last_opened: bool,
    #[serde(default = "default_true")]
    pub card_show_play: bool,
    #[serde(default = "default_true")]
    pub card_show_console: bool,
    #[serde(default)]
    pub card_view_overrides: std::collections::HashMap<String, CardViewOverride>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, Default)]
pub struct CardViewOverride {
    #[serde(default = "default_true")]
    pub show_size: bool,
    #[serde(default = "default_true")]
    pub show_time: bool,
    #[serde(default)]
    pub blur_path: bool,
    #[serde(default = "default_true")]
    pub show_path: bool,
    #[serde(default = "default_true")]
    pub show_tags: bool,
    #[serde(default = "default_true")]
    pub show_last_opened: bool,
    #[serde(default = "default_true")]
    pub show_play: bool,
    #[serde(default = "default_true")]
    pub show_console: bool,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DashboardCustomPreset {
    pub id: String,
    pub name: String,
    pub sections: Vec<String>,
    pub order: Vec<String>,
    pub spans: Vec<String>,
    pub tall: Vec<String>,
}

fn default_language() -> String {
    "en-US".to_string()
}

fn default_naming_convention() -> String {
    "keep".to_string()
}

fn default_theme_preset() -> String {
    "custom".to_string()
}

fn default_landing_tab() -> String {
    "projects".to_string()
}

fn default_project_icon_opacity() -> u32 {
    14
}

fn default_animation_threshold() -> u32 {
    20
}

fn default_true() -> bool {
    true
}

fn default_tray_recent_projects_count() -> u32 {
    5
}

#[derive(Debug, Clone, Deserialize)]
struct ThemeDefaults {
    accent: String,
    background: String,
}

const THEME_DEFAULTS_JSON: &str = include_str!("../theme-defaults.json");

fn theme_defaults() -> &'static ThemeDefaults {
    static DEFAULTS: OnceLock<ThemeDefaults> = OnceLock::new();
    DEFAULTS.get_or_init(|| {
        serde_json::from_str(THEME_DEFAULTS_JSON)
            .expect("theme-defaults.json must be valid JSON")
    })
}

pub(crate) fn default_accent() -> String {
    theme_defaults().accent.clone()
}
fn default_scan_depth() -> u32 {
    2
}
fn default_icon_scan_depth() -> u32 {
    4
}
fn default_download_concurrency() -> u32 {
    3
}
fn default_background() -> String {
    theme_defaults().background.clone()
}
fn default_corner_radius() -> f64 {
    12.0
}
fn default_raised_contrast() -> u32 {
    8
}
fn default_ui_density() -> f64 {
    1.05
}
fn default_font_scale() -> f64 {
    1.00
}
fn default_theme_mode() -> String {
    "dark".to_string()
}
fn default_animation_intensity() -> String {
    "full".to_string()
}
fn default_view_entrance() -> String {
    "fade".to_string()
}
fn default_last_opened_time_format() -> String {
    "12h".to_string()
}
fn default_last_opened_date_format() -> String {
    "DD-MM-YYYY".to_string()
}
fn default_categories_enabled() -> bool {
    true
}
fn default_workspaces_enabled() -> bool {
    true
}
fn default_auto_scan() -> bool {
    true
}
fn default_palette_keybind() -> String {
    "p".to_string()
}
fn default_watch_projects() -> bool {
    true
}
fn default_tooltip_delay() -> u32 {
    350
}
fn default_watch_versions() -> bool {
    true
}
fn default_watch_templates() -> bool {
    true
}

fn default_os_decorations() -> bool {
    false
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Workspace {
    pub id: String,
    pub name: String,
    #[serde(default = "default_workspace_icon")]
    pub icon: String,
    #[serde(default = "default_accent")]
    pub color: String,
    #[serde(default)]
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DiscordProjectPresence {
    pub id: String,
    #[serde(default)]
    pub details: Option<String>,
    #[serde(default)]
    pub state: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkspacesState {
    pub workspaces: Vec<Workspace>,
    pub active_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkspaceScanDirs {
    pub workspace_id: String,
    pub workspace_name: String,
    pub project_scan_dirs: Vec<String>,
    pub version_scan_dirs: Vec<String>,
    pub template_scan_dir: Option<String>,
}

fn default_workspace_icon() -> String {
    "briefcase".to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectTemplate {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub godot_version: String,
    #[serde(default)]
    pub created_at: String,
    #[serde(default)]
    pub source_project_id: Option<String>,
    pub source_path: Option<String>,
    pub path: String,
    #[serde(default)]
    pub keep_name: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemplateSyncResult {
    pub imported: Vec<ProjectTemplate>,
    pub updated: Vec<String>,
    pub removed: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemplateFileEntry {
    pub path: String,
    pub is_dir: bool,
    pub size: u64,
}

#[derive(Debug, Clone, Serialize)]
pub struct GodotFolderPreview {
    pub name: String,
    pub icon: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanProjectsResult {
    pub added: Vec<Project>,
    pub found_dismissed: Vec<String>,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            download_dir: None,
            default_project_location: None,
            project_scan_dirs: vec![],
            version_scan_dirs: vec![],
            scan_depth: default_scan_depth(),
            icon_scan_depth: default_icon_scan_depth(),
            download_concurrency: default_download_concurrency(),
            accent_color: default_accent(),
            background_color: default_background(),
            corner_radius: default_corner_radius(),
            raised_contrast: default_raised_contrast(),
            ui_density: default_ui_density(),
            font_scale: default_font_scale(),
            launch_with_console: false,
            theme_mode: default_theme_mode(),
            custom_css: String::new(),
            animation_intensity: default_animation_intensity(),
            view_entrance: default_view_entrance(),
            close_on_project_open: false,
            minimize_to_tray: false,
            reopen_after_godot_closes: false,
            last_opened_time_format: default_last_opened_time_format(),
            last_opened_date_format: default_last_opened_date_format(),
            setup_complete: false,
            categories_enabled: default_categories_enabled(),
            workspaces_enabled: default_workspaces_enabled(),
            auto_scan_on_startup: default_auto_scan(),
            command_palette_keybind: default_palette_keybind(),
tooltip_delay: default_tooltip_delay(),
            tray_recent_projects_count: default_tray_recent_projects_count(),
            external_editor_path: None,
            github_token: None,
            template_scan_dir: None,
            discord_app_id: None,
            discord_rpc_enabled: true,
            discord_rpc_show_projects: true,
            discord_rpc_excluded_projects: vec![],
            discord_rpc_project_presences: vec![],
            auto_watch_project_dirs: default_watch_projects(),
            auto_watch_version_dirs: default_watch_versions(),
            auto_watch_template_dir: default_watch_templates(),
            show_support_button: true,
            show_star_button: true,
            show_bug_button: true,
            show_tray_button: true,
            show_language_button: true,
            show_scrollbars: true,
            animated_numbers: true,
            screen_reader_announcements: true,
            project_icon_opacity: 14,
            animation_threshold: default_animation_threshold(),
            language: default_language(),
            use_os_decorations: default_os_decorations(),
            dismissed_project_paths: vec![],
            directory_naming_convention: default_naming_convention(),
            theme_preset: default_theme_preset(),
            git_init_new_projects: false,
            open_after_import: true,
            card_layout: true,
            dashboard_custom_name: None,
            default_landing_tab: default_landing_tab(),
            dashboard_sections: vec![],
            dashboard_section_order: vec![],
            dashboard_section_spans: vec![],
            dashboard_tall_sections: vec![],
            dashboard_custom_presets: vec![],
            auto_backup_interval_minutes: 0,
            card_show_size: true,
            card_show_time: true,
            card_blur_path: false,
            card_show_path: true,
            card_show_tags: true,
            card_show_last_opened: true,
            card_show_play: true,
            card_show_console: true,
            card_view_overrides: std::collections::HashMap::new(),
        }
    }
}

impl<'de> serde::Deserialize<'de> for ChangelogNote {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(Deserialize)]
        #[serde(untagged)]
        enum Raw {
            Plain(String),
            Full { category: String, text: String },
        }
        Ok(match Raw::deserialize(deserializer)? {
            Raw::Plain(text) => ChangelogNote {
                category: "add".to_string(),
                text,
            },
            Raw::Full { category, text } => ChangelogNote { category, text },
        })
    }
}
