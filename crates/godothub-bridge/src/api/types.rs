use flutter_rust_bridge::frb;

pub use godothub_core::addons::AddonUpdate;
pub use godothub_core::current_version::AliasBatchResult;
pub use godothub_core::current_version::AliasInfo;
pub use godothub_core::current_version::AliasRequest;
pub use godothub_core::current_version::AliasSkip;
pub use godothub_core::models::AppSettings;
pub use godothub_core::asset_library::AssetDownloadError;
pub use godothub_core::asset_library::AssetDownloadProgress;
pub use godothub_core::asset_library::AssetLibraryAsset;
pub use godothub_core::asset_library::AssetLibraryCategory;
pub use godothub_core::asset_library::AssetLibraryResponse;
pub use godothub_core::models::CardViewOverride;
pub use godothub_core::models::Category;
pub use godothub_core::changelog::ChangelogDraft;
pub use godothub_core::changelog::ChangelogDraftNote;
pub use godothub_core::changelog::ChangelogDraftSkipped;
pub use godothub_core::models::ChangelogEntry;
pub use godothub_core::models::ChangelogNote;
pub use godothub_core::cli_shim::CliToolStatus;
pub use godothub_core::console::ConsoleLine;
pub use godothub_core::console::ConsoleSnapshot;
pub use godothub_core::console::ConsoleStream;
pub use godothub_core::git_auth::CreateRepoResult;
pub use godothub_core::current_version::CurrentVersionInfo;
pub use godothub_core::models::DashboardCustomPreset;
pub use godothub_core::git_auth::DeviceFlowStart;
pub use godothub_core::models::DiscordProjectPresence;
pub use godothub_core::discovery::DiscoveredInstall;
pub use godothub_core::discovery::DiscoveredProject;
pub use godothub_core::models::DownloadProgress;
pub use godothub_core::export_runner::ExportRun;
pub use godothub_core::export_templates::ExportTemplatesError;
pub use godothub_core::export_templates::ExportTemplatesInstallResult;
pub use godothub_core::export_templates::ExportTemplatesOrphan;
pub use godothub_core::export_templates::ExportTemplatesProgress;
pub use godothub_core::export_templates::ExportTemplatesStage;
pub use godothub_core::export_templates::ExportTemplatesState;
pub use godothub_core::export_templates::ExportTemplatesVersionInfo;
pub use godothub_core::projects::FileSizeCategory;
pub use godothub_core::sync::GistSyncResult;
pub use godothub_core::git_auth::GitAccountInfo;
pub use godothub_core::git::GitAheadBehind;
pub use godothub_core::git_auth::GitAuthState;
pub use godothub_core::git::GitBranchInfo;
pub use godothub_core::git::GitChangedFile;
pub use godothub_core::git::GitCommitDetails;
pub use godothub_core::git::GitCommitFile;
pub use godothub_core::git::GitDiffHunk;
pub use godothub_core::git::GitDiffLine;
pub use godothub_core::git::GitDiffResult;
pub use godothub_core::git::GitInitOptions;
pub use godothub_core::git::GitInitOutcome;
pub use godothub_core::git::GitLogEntry;
pub use godothub_core::git_auth::GitPatInfo;
pub use godothub_core::git::GitRemoteInfo;
pub use godothub_core::git::GitStashEntry;
pub use godothub_core::git::GitStatus;
pub use godothub_core::git::GitWorktree;
pub use godothub_core::models::GodotRelease;
pub use godothub_core::models::GodotReleaseAsset;
pub use godothub_core::project_health::HealthAction;
pub use godothub_core::asset_library::InstallAssetResult;
pub use godothub_core::models::InstalledGodotVersion;
pub use godothub_core::persist::LoadStatus;
pub use godothub_core::mise::MiseStatus;
pub use godothub_core::models::NewsItem;
pub use godothub_core::news::NewsResponse;
pub use godothub_core::project_todos::OpenTodo;
pub use godothub_core::models::Project;
pub use godothub_core::addons::ProjectAddon;
pub use godothub_core::projects::ProjectFileEntry;
pub use godothub_core::projects::ProjectSizeInfo;
pub use godothub_core::models::ProjectTemplate;
pub use godothub_core::models::ProjectTodo;
pub use godothub_core::tool_runner::ProjectTool;
pub use godothub_core::models::ProjectUpdate;
pub use godothub_core::godot_versions::RateLimitInfo;
pub use godothub_core::storage::ReclaimFailure;
pub use godothub_core::storage::ReclaimResult;
pub use godothub_core::sync::RestorePreview;
pub use godothub_core::projects::RunningProjectInfo;
pub use godothub_core::models::ScanProjectsResult;
pub use godothub_core::storage::StorageExportTemplates;
pub use godothub_core::storage::StoragePartial;
pub use godothub_core::storage::StorageReport;
pub use godothub_core::storage::StorageTemplate;
pub use godothub_core::storage::StorageVersion;
pub use godothub_core::export_templates::archive::TemplateFile;
pub use godothub_core::models::TemplateFileEntry;
pub use godothub_core::export_templates::archive::TemplateOption;
pub use godothub_core::models::TemplateSyncResult;
pub use godothub_core::time_stats::TimeInsights;
pub use godothub_core::models::TodoArea;
pub use godothub_core::models::TodoChecklistItem;
pub use godothub_core::models::TodoClosure;
pub use godothub_core::todo_sync::TodoCommit;
pub use godothub_core::todo_sync::TodoGitActivity;
pub use godothub_core::models::TodoLink;
pub use godothub_core::models::TodoPriority;
pub use godothub_core::models::TodoSource;
pub use godothub_core::models::TodoStatus;
pub use godothub_core::todo_sync::TodoSyncResult;
pub use godothub_core::git_auth::UserRepoInfo;
pub use godothub_core::git_auth::UserRepoPage;
pub use godothub_core::models::VaultFileEntry;
pub use godothub_core::models::VaultItem;
pub use godothub_core::models::VaultProjectImportResult;
pub use godothub_core::models::VaultSaveSource;
pub use godothub_core::current_version::VersionAliases;
pub use godothub_core::models::Workspace;
pub use godothub_core::models::WorkspaceScanDirs;
pub use godothub_core::models::WorkspacesState;

#[frb(mirror(AddonUpdate))]
pub struct _AddonUpdate {
    pub folder: String,
    pub asset_id: String,
    pub title: String,
    pub latest_version: String,
    pub update_available: bool,
    pub matched_by: String,
    pub browse_url: Option<String>,
}

#[frb(mirror(AliasBatchResult))]
pub struct _AliasBatchResult {
    pub created: Vec<AliasInfo>,
    pub skipped: Vec<AliasSkip>,
}

#[frb(mirror(AliasInfo))]
pub struct _AliasInfo {
    pub name: String,
    pub tag: String,
    pub alias_path: String,
    pub aliases_dir: String,
    pub method: String,
}

#[frb(mirror(AliasRequest))]
pub struct _AliasRequest {
    pub name: String,
    pub tag: String,
}

#[frb(mirror(AliasSkip))]
pub struct _AliasSkip {
    pub name: String,
    pub tag: String,
    pub reason: String,
}

#[frb(mirror(AppSettings))]
pub struct _AppSettings {
    pub schema_version: u32,
    pub download_dir: Option<String>,
    pub default_project_location: Option<String>,
    pub project_scan_dirs: Vec<String>,
    pub version_scan_dirs: Vec<String>,
    pub scan_depth: u32,
    pub icon_scan_depth: u32,
    pub download_concurrency: u32,
    pub accent_color: String,
    pub background_color: String,
    pub corner_radius: f64,
    pub raised_contrast: u32,
    pub ui_density: f64,
    pub font_scale: f64,
    pub theme_mode: String,
    pub custom_css: String,
    pub animation_intensity: String,
    pub view_entrance: String,
    pub launch_with_console: bool,
    pub builtin_console: bool,
    pub git_auto_fetch: bool,
    pub close_on_project_open: bool,
    pub minimize_to_tray: bool,
    pub reopen_after_godot_closes: bool,
    pub last_opened_time_format: String,
    pub last_opened_date_format: String,
    pub setup_complete: bool,
    pub categories_enabled: bool,
    pub workspaces_enabled: bool,
    pub auto_scan_on_startup: bool,
    pub command_palette_keybind: String,
    pub external_editor_path: Option<String>,
    pub github_token: Option<String>,
    pub template_scan_dir: Option<String>,
    pub discord_app_id: Option<String>,
    pub discord_rpc_enabled: bool,
    pub discord_rpc_show_projects: bool,
    pub discord_rpc_excluded_projects: Vec<String>,
    pub discord_rpc_project_presences: Vec<DiscordProjectPresence>,
    pub tooltip_delay: u32,
    pub auto_watch_project_dirs: bool,
    pub auto_watch_version_dirs: bool,
    pub auto_watch_template_dir: bool,
    pub tray_recent_projects_count: u32,
    pub show_support_button: bool,
    pub show_star_button: bool,
    pub show_bug_button: bool,
    pub show_tray_button: bool,
    pub show_language_button: bool,
    pub show_changelog_button: bool,
    pub show_scrollbars: bool,
    pub animated_numbers: bool,
    pub screen_reader_announcements: bool,
    pub project_icon_opacity: u32,
    pub project_card_style: String,
    pub animation_threshold: u32,
    pub animation_speed: f64,
    pub motion_scroll_reveal: bool,
    pub motion_card_tilt: bool,
    pub motion_click_ripple: bool,
    pub motion_press_bounce: bool,
    pub language: String,
    pub use_os_decorations: bool,
    pub dismissed_project_paths: Vec<String>,
    pub directory_naming_convention: String,
    pub theme_preset: String,
    pub git_init_new_projects: bool,
    pub open_after_import: bool,
    pub card_layout: bool,
    pub dashboard_custom_name: Option<String>,
    pub default_landing_tab: String,
    pub dashboard_sections: Vec<String>,
    pub dashboard_section_order: Vec<String>,
    pub dashboard_section_spans: Vec<String>,
    pub dashboard_tall_sections: Vec<String>,
    pub dashboard_custom_presets: Vec<DashboardCustomPreset>,
    pub auto_backup_interval_minutes: u32,
    pub card_show_size: bool,
    pub card_show_time: bool,
    pub card_blur_path: bool,
    pub card_show_path: bool,
    pub card_show_tags: bool,
    pub card_show_last_opened: bool,
    pub card_show_play: bool,
    pub card_show_console: bool,
    pub card_show_session_timer: bool,
    pub card_view_overrides: std::collections::HashMap<String, CardViewOverride>,
    pub customize_view_enabled: bool,
    pub fixed_sidebar_resize_knob: bool,
    pub desktop_notifications_enabled: bool,
    pub colored_titlebar_buttons: bool,
    pub rtl_layout: bool,
    pub project_todos_enabled: bool,
    pub use_mise: bool,
    pub disabled_features: Vec<String>,
}

#[frb(mirror(AssetDownloadError))]
pub struct _AssetDownloadError {
    pub asset_id: String,
    pub title: String,
    pub message: String,
}

#[frb(mirror(AssetDownloadProgress))]
pub struct _AssetDownloadProgress {
    pub asset_id: String,
    pub title: String,
    pub downloaded: u64,
    pub total: u64,
}

#[frb(mirror(AssetLibraryAsset))]
pub struct _AssetLibraryAsset {
    pub asset_id: String,
    pub title: String,
    pub author: String,
    pub category: String,
    pub godot_version: String,
    pub cost: String,
    pub support_level: String,
    pub asset_type: String,
    pub description: Option<String>,
    pub icon_url: Option<String>,
    pub download_url: Option<String>,
    pub browse_url: Option<String>,
    pub modify_date: Option<String>,
    pub rating: String,
    pub source: String,
}

#[frb(mirror(AssetLibraryCategory))]
pub struct _AssetLibraryCategory {
    pub id: String,
    pub name: String,
    pub category_type: String,
}

#[frb(mirror(AssetLibraryResponse))]
pub struct _AssetLibraryResponse {
    pub assets: Vec<AssetLibraryAsset>,
    pub page: u32,
    pub pages: u32,
    pub total: u32,
}

#[frb(mirror(CardViewOverride))]
pub struct _CardViewOverride {
    pub show_size: bool,
    pub show_time: bool,
    pub blur_path: bool,
    pub show_path: bool,
    pub show_tags: bool,
    pub show_last_opened: bool,
    pub show_play: bool,
    pub show_console: bool,
    pub show_session_timer: bool,
}

#[frb(mirror(Category))]
pub struct _Category {
    pub id: String,
    pub name: String,
    pub sort_order: i64,
    pub color: String,
    pub hidden: bool,
    pub folders: Vec<String>,
}

#[frb(mirror(ChangelogDraft))]
pub struct _ChangelogDraft {
    pub from: String,
    pub to: String,
    pub count: usize,
    pub next_version: String,
    pub notes: Vec<ChangelogDraftNote>,
    pub skipped: Vec<ChangelogDraftSkipped>,
}

#[frb(mirror(ChangelogDraftNote))]
pub struct _ChangelogDraftNote {
    pub category: String,
    pub text: String,
    pub hash: String,
    pub author: String,
}

#[frb(mirror(ChangelogDraftSkipped))]
pub struct _ChangelogDraftSkipped {
    pub hash: String,
    pub subject: String,
    pub reason: String,
}

#[frb(mirror(ChangelogEntry))]
pub struct _ChangelogEntry {
    pub id: String,
    pub version: String,
    pub date: String,
    pub notes: Vec<ChangelogNote>,
    pub known_issues: Vec<String>,
    pub created_at: i64,
}

#[frb(mirror(ChangelogNote))]
pub struct _ChangelogNote {
    pub category: String,
    pub text: String,
}

#[frb(mirror(CliToolStatus))]
pub struct _CliToolStatus {
    pub installed: bool,
    pub on_path: bool,
    pub bin_dir: String,
    pub shim_path: String,
    pub platform: String,
    pub needs_new_terminal: bool,
}

#[frb(mirror(ConsoleLine))]
pub struct _ConsoleLine {
    pub seq: u64,
    pub stream: ConsoleStream,
    pub text: String,
}

#[frb(mirror(ConsoleSnapshot))]
pub struct _ConsoleSnapshot {
    pub id: String,
    pub lines: Vec<ConsoleLine>,
    pub next_seq: u64,
    pub running: bool,
    pub exit_code: Option<i32>,
    pub restored: bool,
}

#[frb(mirror(ConsoleStream))]
pub enum _ConsoleStream {
    Stdout,
    Stderr,
}

#[frb(mirror(CreateRepoResult))]
pub struct _CreateRepoResult {
    pub url: String,
    pub slug: String,
}

#[frb(mirror(CurrentVersionInfo))]
pub struct _CurrentVersionInfo {
    pub tag: String,
    pub alias_path: String,
    pub aliases_dir: String,
    pub method: String,
}

#[frb(mirror(DashboardCustomPreset))]
pub struct _DashboardCustomPreset {
    pub id: String,
    pub name: String,
    pub sections: Vec<String>,
    pub order: Vec<String>,
    pub spans: Vec<String>,
    pub tall: Vec<String>,
}

#[frb(mirror(DeviceFlowStart))]
pub struct _DeviceFlowStart {
    pub provider: String,
    pub device_code: String,
    pub user_code: String,
    pub verification_uri: String,
    pub verification_uri_complete: String,
    pub interval: u64,
    pub expires_in: u64,
    pub base_url: Option<String>,
}

#[frb(mirror(DiscordProjectPresence))]
pub struct _DiscordProjectPresence {
    pub id: String,
    pub details: Option<String>,
    pub state: Option<String>,
}

#[frb(mirror(DiscoveredInstall))]
pub struct _DiscoveredInstall {
    pub path: String,
    pub name: String,
    pub source: String,
    pub version: Option<String>,
}

#[frb(mirror(DiscoveredProject))]
pub struct _DiscoveredProject {
    pub path: String,
    pub name: String,
    pub favorite: bool,
    pub engine: Option<String>,
}

#[frb(mirror(DownloadProgress))]
pub struct _DownloadProgress {
    pub tag: String,
    pub downloaded: u64,
    pub total: u64,
}

#[frb(mirror(ExportRun))]
pub struct _ExportRun {
    pub id: String,
    pub project_id: String,
    pub project_name: String,
    pub preset_name: String,
    pub output_path: String,
    pub status: String,
    pub size_bytes: Option<u64>,
    pub exit_code: Option<i32>,
    pub error: Option<String>,
    pub started_at_ms: u64,
}

#[frb(mirror(ExportTemplatesError))]
pub struct _ExportTemplatesError {
    pub tag: String,
    pub message: String,
}

#[frb(mirror(ExportTemplatesInstallResult))]
pub struct _ExportTemplatesInstallResult {
    pub tag: String,
    pub folder: String,
    pub verified: bool,
    pub size_bytes: u64,
    pub file_count: usize,
}

#[frb(mirror(ExportTemplatesOrphan))]
pub struct _ExportTemplatesOrphan {
    pub folder: String,
    pub path: String,
    pub root: String,
    pub size_bytes: u64,
    pub file_count: usize,
}

#[frb(mirror(ExportTemplatesProgress))]
pub struct _ExportTemplatesProgress {
    pub tag: String,
    pub downloaded: u64,
    pub total: u64,
    pub file: Option<String>,
    pub platforms: Vec<String>,
}

#[frb(mirror(ExportTemplatesStage))]
pub struct _ExportTemplatesStage {
    pub tag: String,
    pub stage: String,
}

#[frb(mirror(ExportTemplatesState))]
pub struct _ExportTemplatesState {
    pub default_dir: String,
    pub versions: Vec<ExportTemplatesVersionInfo>,
    pub orphans: Vec<ExportTemplatesOrphan>,
}

#[frb(mirror(ExportTemplatesVersionInfo))]
pub struct _ExportTemplatesVersionInfo {
    pub tag: String,
    pub folder: String,
    pub root: String,
    pub templates_dir: String,
    pub installed: bool,
    pub downloading: bool,
    pub size_bytes: u64,
    pub file_count: usize,
    pub platforms: Vec<String>,
}

#[frb(mirror(FileSizeCategory))]
pub struct _FileSizeCategory {
    pub label: String,
    pub size: u64,
    pub count: usize,
}

#[frb(mirror(GistSyncResult))]
pub struct _GistSyncResult {
    pub gist_url: String,
    pub gist_id: String,
    pub pushed_at: String,
}

#[frb(mirror(GitAccountInfo))]
pub struct _GitAccountInfo {
    pub username: String,
    pub host: Option<String>,
}

#[frb(mirror(GitAheadBehind))]
pub struct _GitAheadBehind {
    pub ahead: usize,
    pub behind: usize,
}

#[frb(mirror(GitAuthState))]
pub struct _GitAuthState {
    pub github: Option<GitAccountInfo>,
    pub gitlab: Option<GitAccountInfo>,
    pub pats: Vec<GitPatInfo>,
}

#[frb(mirror(GitBranchInfo))]
pub struct _GitBranchInfo {
    pub name: String,
    pub is_current: bool,
    pub has_upstream: bool,
}

#[frb(mirror(GitChangedFile))]
pub struct _GitChangedFile {
    pub path: String,
    pub status: String,
}

#[frb(mirror(GitCommitDetails))]
pub struct _GitCommitDetails {
    pub hash: String,
    pub message: String,
    pub author: String,
    pub date: String,
    pub files: Vec<GitCommitFile>,
    pub diff: GitDiffResult,
}

#[frb(mirror(GitCommitFile))]
pub struct _GitCommitFile {
    pub path: String,
    pub status: String,
}

#[frb(mirror(GitDiffHunk))]
pub struct _GitDiffHunk {
    pub old_start: u32,
    pub old_lines: u32,
    pub new_start: u32,
    pub new_lines: u32,
    pub lines: Vec<GitDiffLine>,
}

#[frb(mirror(GitDiffLine))]
pub struct _GitDiffLine {
    pub kind: String,
    pub content: String,
}

#[frb(mirror(GitDiffResult))]
pub struct _GitDiffResult {
    pub hunks: Vec<GitDiffHunk>,
}

#[frb(mirror(GitInitOptions))]
pub struct _GitInitOptions {
    pub gitignore: bool,
    pub gitattributes: bool,
    pub readme: bool,
    pub license: Option<String>,
}

#[frb(mirror(GitInitOutcome))]
pub struct _GitInitOutcome {
    pub initialized: bool,
    pub committed: bool,
    pub branch: Option<String>,
    pub warning: Option<String>,
}

#[frb(mirror(GitLogEntry))]
pub struct _GitLogEntry {
    pub hash: String,
    pub parents: Vec<String>,
    pub message: String,
    pub author: String,
    pub date: String,
}

#[frb(mirror(GitPatInfo))]
pub struct _GitPatInfo {
    pub host: String,
    pub username: String,
}

#[frb(mirror(GitRemoteInfo))]
pub struct _GitRemoteInfo {
    pub name: String,
    pub web_url: String,
    pub repo_name: String,
}

#[frb(mirror(GitStashEntry))]
pub struct _GitStashEntry {
    pub index: usize,
    pub message: String,
}

#[frb(mirror(GitStatus))]
pub struct _GitStatus {
    pub branch: Option<String>,
    pub has_uncommitted: bool,
    pub is_repo: bool,
}

#[frb(mirror(GitWorktree))]
pub struct _GitWorktree {
    pub path: String,
    pub branch: Option<String>,
    pub head: String,
    pub has_uncommitted: bool,
    pub is_main: bool,
}

#[frb(mirror(GodotRelease))]
pub struct _GodotRelease {
    pub tag: String,
    pub assets: Vec<GodotReleaseAsset>,
}

#[frb(mirror(GodotReleaseAsset))]
pub struct _GodotReleaseAsset {
    pub name: String,
    pub download_url: String,
    pub size: u64,
    pub is_mono: bool,
}

#[frb(mirror(HealthAction))]
pub struct _HealthAction {
    pub kind: String,
    pub target: Option<String>,
    pub confirm: bool,
}

#[frb(mirror(InstallAssetResult))]
pub struct _InstallAssetResult {
    pub asset_id: String,
    pub title: String,
    pub target_type: String,
    pub target_name: String,
    pub path: String,
    pub addon_folders: Vec<String>,
}

#[frb(mirror(InstalledGodotVersion))]
pub struct _InstalledGodotVersion {
    pub tag: String,
    pub version: String,
    pub executable_path: String,
    pub is_mono: bool,
    pub installed_at: String,
    pub custom_name: Option<String>,
    pub install_root: Option<String>,
    pub supports_console: bool,
    pub managed_by: Option<String>,
}

#[frb(mirror(LoadStatus))]
pub enum _LoadStatus {
    Missing,
    Ok,
    RecoveredFromBackup,
    Corrupt,
}

#[frb(mirror(MiseStatus))]
pub struct _MiseStatus {
    pub available: bool,
    pub path: Option<String>,
    pub version: Option<String>,
    pub source_url: Option<String>,
}

#[frb(mirror(NewsItem))]
pub struct _NewsItem {
    pub id: String,
    pub title: String,
    pub link: String,
    pub published: Option<String>,
    pub summary: Option<String>,
    pub author: Option<String>,
    pub category: Option<String>,
    pub image: Option<String>,
}

#[frb(mirror(NewsResponse))]
pub struct _NewsResponse {
    pub items: Vec<NewsItem>,
    pub from_cache: bool,
}

#[frb(mirror(OpenTodo))]
pub struct _OpenTodo {
    pub project_id: String,
    pub project_name: String,
    pub todo: ProjectTodo,
}

#[frb(mirror(Project))]
pub struct _Project {
    pub id: String,
    pub name: String,
    pub path: String,
    pub godot_version: String,
    pub created_at: String,
    pub last_opened: Option<String>,
    pub category: Option<String>,
    pub pinned: bool,
    pub sort_order: i64,
    pub launch_arguments: String,
    pub tags: Vec<String>,
    pub total_time_seconds: u64,
    pub session_started_at_ms: Option<u64>,
    pub time_today_seconds: u64,
    pub time_week_seconds: u64,
}

#[frb(mirror(ProjectAddon))]
pub struct _ProjectAddon {
    pub folder: String,
    pub name: String,
    pub description: String,
    pub author: String,
    pub version: String,
    pub has_plugin: bool,
    pub enabled: bool,
    pub asset_id: Option<String>,
}

#[frb(mirror(ProjectFileEntry))]
pub struct _ProjectFileEntry {
    pub path: String,
    pub is_dir: bool,
    pub size: u64,
}

#[frb(mirror(ProjectSizeInfo))]
pub struct _ProjectSizeInfo {
    pub total_size: u64,
    pub categories: Vec<FileSizeCategory>,
    pub file_count: usize,
}

#[frb(mirror(ProjectTemplate))]
pub struct _ProjectTemplate {
    pub id: String,
    pub name: String,
    pub description: String,
    pub godot_version: String,
    pub created_at: String,
    pub source_project_id: Option<String>,
    pub source_path: Option<String>,
    pub path: String,
    pub keep_name: bool,
}

#[frb(mirror(ProjectTodo))]
pub struct _ProjectTodo {
    pub id: String,
    pub title: String,
    pub status: TodoStatus,
    pub area: TodoArea,
    pub due_date: Option<String>,
    pub description: Option<String>,
    pub created_at: String,
    pub number: Option<u32>,
    pub link: Option<TodoLink>,
    pub source: Option<TodoSource>,
    pub closed_by: Option<TodoClosure>,
    pub priority: Option<TodoPriority>,
    pub checklist: Vec<TodoChecklistItem>,
    pub completed_at: Option<String>,
}

#[frb(mirror(ProjectTool))]
pub struct _ProjectTool {
    pub id: String,
    pub kind: String,
    pub available: bool,
    pub reason: Option<String>,
    pub detail: Option<String>,
}

#[frb(mirror(ProjectUpdate))]
pub struct _ProjectUpdate {
    pub name: Option<String>,
    pub godot_version: Option<String>,
    pub category: Option<String>,
    pub pinned: Option<bool>,
    pub launch_arguments: Option<String>,
    pub tags: Option<Vec<String>>,
    pub path: Option<String>,
}

#[frb(mirror(RateLimitInfo))]
pub struct _RateLimitInfo {
    pub remaining: u64,
    pub limit: u64,
    pub reset_at: i64,
    pub used_token: bool,
}

#[frb(mirror(ReclaimFailure))]
pub struct _ReclaimFailure {
    pub label: String,
    pub error: String,
}

#[frb(mirror(ReclaimResult))]
pub struct _ReclaimResult {
    pub freed_bytes: u64,
    pub removed: usize,
    pub failed: Vec<ReclaimFailure>,
}

#[frb(mirror(RestorePreview))]
pub struct _RestorePreview {
    pub workspace_count: usize,
    pub workspace_names: Vec<String>,
    pub project_count: usize,
    pub category_count: usize,
    pub template_count: usize,
    pub has_time_stats: bool,
    pub todo_count: usize,
    pub version_scan_dirs: Vec<String>,
    pub project_scan_dirs: Vec<String>,
}

#[frb(mirror(RunningProjectInfo))]
pub struct _RunningProjectInfo {
    pub id: String,
    pub name: String,
    pub version: String,
    pub launched_at_ms: u64,
    pub console: bool,
}

#[frb(mirror(ScanProjectsResult))]
pub struct _ScanProjectsResult {
    pub added: Vec<Project>,
    pub found_dismissed: Vec<String>,
}

#[frb(mirror(StorageExportTemplates))]
pub struct _StorageExportTemplates {
    pub tag: Option<String>,
    pub folder: String,
    pub root: String,
    pub path: String,
    pub size_bytes: u64,
    pub orphan: bool,
}

#[frb(mirror(StoragePartial))]
pub struct _StoragePartial {
    pub kind: String,
    pub name: String,
    pub path: String,
    pub size_bytes: u64,
}

#[frb(mirror(StorageReport))]
pub struct _StorageReport {
    pub versions: Vec<StorageVersion>,
    pub partials: Vec<StoragePartial>,
    pub templates: Vec<StorageTemplate>,
    pub export_templates: Vec<StorageExportTemplates>,
    pub export_templates_error: Option<String>,
}

#[frb(mirror(StorageTemplate))]
pub struct _StorageTemplate {
    pub id: String,
    pub name: String,
    pub workspace: String,
    pub path: String,
    pub size_bytes: u64,
}

#[frb(mirror(StorageVersion))]
pub struct _StorageVersion {
    pub tag: String,
    pub name: String,
    pub path: String,
    pub size_bytes: u64,
    pub managed_by: Option<String>,
    pub external: bool,
    pub projects: Vec<String>,
    pub templates: Vec<String>,
    pub is_current: bool,
    pub aliases: Vec<String>,
    pub unused: bool,
}

#[frb(mirror(TemplateFile))]
pub struct _TemplateFile {
    pub name: String,
    pub size_bytes: u64,
    pub download_bytes: u64,
    pub installed: bool,
}

#[frb(mirror(TemplateFileEntry))]
pub struct _TemplateFileEntry {
    pub path: String,
    pub is_dir: bool,
    pub size: u64,
}

#[frb(mirror(TemplateOption))]
pub struct _TemplateOption {
    pub id: String,
    pub label: String,
    pub files: Vec<TemplateFile>,
    pub size_bytes: u64,
    pub download_bytes: u64,
    pub installed: bool,
}

#[frb(mirror(TemplateSyncResult))]
pub struct _TemplateSyncResult {
    pub imported: Vec<ProjectTemplate>,
    pub updated: Vec<String>,
    pub removed: Vec<String>,
}

#[frb(mirror(TimeInsights))]
pub struct _TimeInsights {
    pub total_seconds: u64,
    pub longest_streak_days: u32,
    pub current_streak_days: u32,
    pub most_productive_weekday: Option<u32>,
    pub this_month_seconds: u64,
    pub last_month_seconds: u64,
}

#[frb(mirror(TodoArea))]
pub enum _TodoArea {
    Programming,
    Art,
    Audio,
    Design,
    Narrative,
    Other,
}

#[frb(mirror(TodoChecklistItem))]
pub struct _TodoChecklistItem {
    pub id: String,
    pub text: String,
    pub done: bool,
}

#[frb(mirror(TodoClosure))]
pub struct _TodoClosure {
    pub kind: String,
    pub commit: Option<String>,
    pub subject: Option<String>,
    pub at: String,
}

#[frb(mirror(TodoCommit))]
pub struct _TodoCommit {
    pub hash: String,
    pub short_hash: String,
    pub subject: String,
    pub author: String,
    pub date: String,
    pub closes: bool,
}

#[frb(mirror(TodoGitActivity))]
pub struct _TodoGitActivity {
    pub is_repo: bool,
    pub current_branch: Option<String>,
    pub branches: Vec<String>,
    pub commits: Vec<TodoCommit>,
}

#[frb(mirror(TodoLink))]
pub struct _TodoLink {
    pub path: String,
    pub line: Option<u32>,
}

#[frb(mirror(TodoPriority))]
pub enum _TodoPriority {
    Low,
    Medium,
    High,
}

#[frb(mirror(TodoSource))]
pub struct _TodoSource {
    pub kind: String,
    pub tag: String,
    pub key: String,
}

#[frb(mirror(TodoStatus))]
pub enum _TodoStatus {
    Todo,
    Paused,
    InProgress,
    Done,
}

#[frb(mirror(TodoSyncResult))]
pub struct _TodoSyncResult {
    pub todos: Vec<ProjectTodo>,
    pub scanned: bool,
    pub imported: usize,
    pub closed: usize,
    pub reopened: usize,
    pub updated: usize,
    pub closed_by_commits: usize,
    pub git_available: bool,
}

#[frb(mirror(UserRepoInfo))]
pub struct _UserRepoInfo {
    pub name: String,
    pub full_name: String,
    pub description: Option<String>,
    pub clone_url: String,
    pub html_url: String,
    pub private: bool,
    pub language: Option<String>,
    pub default_branch: Option<String>,
}

#[frb(mirror(UserRepoPage))]
pub struct _UserRepoPage {
    pub repos: Vec<UserRepoInfo>,
    pub has_more: bool,
}

#[frb(mirror(VaultFileEntry))]
pub struct _VaultFileEntry {
    pub path: String,
    pub is_dir: bool,
    pub size: u64,
}

#[frb(mirror(VaultItem))]
pub struct _VaultItem {
    pub id: String,
    pub name: String,
    pub description: String,
    pub godot_version: String,
    pub created_at: String,
    pub source_project_id: Option<String>,
    pub source_project_ids: Vec<String>,
    pub tags: Vec<String>,
    pub files: Vec<VaultFileEntry>,
    pub path: String,
}

#[frb(mirror(VaultProjectImportResult))]
pub struct _VaultProjectImportResult {
    pub project_id: String,
    pub installed: Vec<String>,
    pub conflicts: Vec<String>,
    pub skipped: bool,
}

#[frb(mirror(VaultSaveSource))]
pub struct _VaultSaveSource {
    pub project_id: String,
    pub paths: Vec<String>,
}

#[frb(mirror(VersionAliases))]
pub struct _VersionAliases {
    pub aliases: Vec<AliasInfo>,
    pub aliases_dir: String,
}

#[frb(mirror(Workspace))]
pub struct _Workspace {
    pub id: String,
    pub name: String,
    pub icon: String,
    pub color: String,
    pub created_at: String,
}

#[frb(mirror(WorkspaceScanDirs))]
pub struct _WorkspaceScanDirs {
    pub workspace_id: String,
    pub workspace_name: String,
    pub project_scan_dirs: Vec<String>,
    pub version_scan_dirs: Vec<String>,
    pub template_scan_dir: Option<String>,
}

#[frb(mirror(WorkspacesState))]
pub struct _WorkspacesState {
    pub workspaces: Vec<Workspace>,
    pub active_id: String,
}
