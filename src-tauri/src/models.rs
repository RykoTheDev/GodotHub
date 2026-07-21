use serde::{Deserialize, Serialize};

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
    "#457ff2".to_string()
}

#[derive(Debug, Clone, Serialize)]
pub struct ChangelogNote {
    pub category: String,
    pub text: String,
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
    #[serde(default = "default_download_concurrency")]
    pub download_concurrency: u32,
    #[serde(default = "default_accent")]
    pub accent_color: String,
    #[serde(default = "default_background")]
    pub background_color: String,
    #[serde(default = "default_corner_radius")]
    pub corner_radius: f64,
    #[serde(default = "default_ui_density")]
    pub ui_density: f64,
    #[serde(default = "default_font_scale")]
    pub font_scale: f64,
    #[serde(default)]
    pub reduce_motion: bool,
    #[serde(default = "default_theme_mode")]
    pub theme_mode: String,
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
    pub template_scan_dir: Option<String>,
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
}

fn default_tray_recent_projects_count() -> u32 {
    5
}

fn default_accent() -> String {
    "#457ff2".to_string()
}
fn default_scan_depth() -> u32 {
    2
}
fn default_download_concurrency() -> u32 {
    3
}
fn default_background() -> String {
    "#15171c".to_string()
}
fn default_corner_radius() -> f64 {
    5.0
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
pub struct WorkspacesState {
    pub workspaces: Vec<Workspace>,
    pub active_id: String,
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

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            download_dir: None,
            default_project_location: None,
            project_scan_dirs: vec![],
            version_scan_dirs: vec![],
            scan_depth: default_scan_depth(),
            download_concurrency: default_download_concurrency(),
            accent_color: default_accent(),
            background_color: default_background(),
            corner_radius: default_corner_radius(),
            ui_density: default_ui_density(),
            font_scale: default_font_scale(),
            reduce_motion: false,
            theme_mode: default_theme_mode(),
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
            template_scan_dir: None,
            auto_watch_project_dirs: default_watch_projects(),
            auto_watch_version_dirs: default_watch_versions(),
            auto_watch_template_dir: default_watch_templates(),
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
