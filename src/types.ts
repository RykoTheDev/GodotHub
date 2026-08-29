export interface InstalledGodotVersion {
  tag: string
  version: string
  executable_path: string
  is_mono: boolean
  installed_at: string
  custom_name?: string | null
  install_root?: string | null
  supports_console?: boolean
}

export interface GodotReleaseAsset {
  name: string
  download_url: string
  size: number
  is_mono: boolean
}

export interface GodotRelease {
  tag: string
  assets: GodotReleaseAsset[]
}

export interface Category {
  id: string
  name: string
  sort_order: number
  color: string
}

export interface ChangelogNote {
  category: 'add' | 'fix' | 'improve'
  text: string
}

export interface ChangelogEntry {
  id: string
  version: string
  date: string
  notes: ChangelogNote[]
  known_issues: string[]
  created_at: number
}

export interface ChangelogDraftNote {
  category: ChangelogNote['category']
  text: string
  hash: string
  author: string
}

export interface ChangelogDraftSkipped {
  hash: string
  subject: string
  reason: 'merge' | 'revert' | 'bump' | 'unrecognized'
}

export interface ChangelogDraft {
  from: string
  to: string
  count: number
  next_version: string
  notes: ChangelogDraftNote[]
  skipped: ChangelogDraftSkipped[]
}

export type UpdateKind =
  | 'announcement'
  | 'new-feature'
  | 'improvement'
  | 'breaking-change'
  | 'known-issue'

export interface UpdateEntry {
  id: string
  kind: UpdateKind
  title: string
  body: string
  command?: string | null
  is_new: boolean
  featured: boolean
  link?: string | null
  created_at: number
}

export interface TimeInsights {
  total_seconds: number
  longest_streak_days: number
  current_streak_days: number
  most_productive_weekday: number | null
  this_month_seconds: number
  last_month_seconds: number
}

export interface UpdatesResponse {
  entries: UpdateEntry[]
  from_cache: boolean
  fetched_at: number
}

export interface Project {
  id: string
  name: string
  path: string
  godot_version: string
  created_at: string
  last_opened: string | null
  category: string | null
  pinned: boolean
  sort_order: number
  launch_arguments: string
  tags: string[]
  total_time_seconds: number
  session_started_at_ms: number | null
  time_today_seconds: number
  time_week_seconds: number
}

export interface ProjectUpdate {
  name?: string
  godot_version?: string
  category?: string
  pinned?: boolean
  launch_arguments?: string
  tags?: string[]
}

export interface GitStatus {
  branch: string | null
  has_uncommitted: boolean
  is_repo: boolean
}

export interface GitLogEntry {
  hash: string
  parents: string[]
  message: string
  author: string
  date: string
}

export interface GitBranchInfo {
  name: string
  is_current: boolean
  has_upstream: boolean
}

export interface GitStashEntry {
  index: number
  message: string
}

export interface GitChangedFile {
  path: string
  status: string
}

export interface GitRemoteInfo {
  name: string
  web_url: string
  repo_name: string
}

export interface GitAheadBehind {
  ahead: number
  behind: number
}

export interface GitCommitFile {
  path: string
  status: string
}

export interface GitCommitDetails {
  hash: string
  message: string
  author: string
  date: string
  files: GitCommitFile[]
  diff: GitDiffResult
}

export interface GitInitOutcome {
  initialized: boolean
  committed: boolean
  branch: string | null
  warning: string | null
}

export interface GitInitOptions {
  gitignore?: boolean
  gitattributes?: boolean
  readme?: boolean
  license?: string | null
}

export interface GitDiffLine {
  kind: 'context' | 'add' | 'delete'
  content: string
}

export interface GitDiffHunk {
  old_start: number
  old_lines: number
  new_start: number
  new_lines: number
  lines: GitDiffLine[]
}

export interface GitDiffResult {
  hunks: GitDiffHunk[]
}

export interface DownloadProgress {
  tag: string
  downloaded: number
  total: number
}

export interface NewsItem {
  id: string
  title: string
  link: string
  published: string | null
  summary: string | null
  author: string | null
  category: string | null
  image: string | null
}

export interface NewsResponse {
  items: NewsItem[]
  from_cache: boolean
}

export interface Workspace {
  id: string
  name: string
  icon: string
  color: string
  created_at: string
}

export interface WorkspacesState {
  workspaces: Workspace[]
  active_id: string
}

export interface WorkspaceScanDirs {
  workspace_id: string
  workspace_name: string
  project_scan_dirs: string[]
  version_scan_dirs: string[]
  template_scan_dir: string | null
}

export interface TemplateFileEntry {
  path: string
  is_dir: boolean
  size: number
}

export interface TemplateSyncResult {
  imported: ProjectTemplate[]
  updated: string[]
  removed: string[]
}

export interface FileSizeCategory {
  label: string
  size: number
  count: number
}

export interface ProjectSizeInfo {
  total_size: number
  categories: FileSizeCategory[]
  file_count: number
}

export interface ProjectTemplate {
  id: string
  name: string
  description: string
  godot_version: string
  created_at: string
  source_project_id: string | null
  source_path: string | null
  path: string
  keep_name: boolean
}

export interface AssetLibraryAsset {
  asset_id: string
  title: string
  author: string
  category: string
  godot_version: string
  cost: string
  support_level: string
  asset_type: string
  description: string | null
  icon_url: string | null
  download_url: string | null
  browse_url: string | null
  modify_date: string | null
  rating?: string
  source?: 'library' | 'store'
}

export interface AssetLibraryResponse {
  assets: AssetLibraryAsset[]
  page: number
  pages: number
  total: number
}

export interface AssetDownloadProgress {
  asset_id: string
  title: string
  downloaded: number
  total: number
}

export interface AssetDownloadError {
  asset_id: string
  title: string
  message: string
}

export interface AssetLibraryCategory {
  id: string
  name: string
  category_type: string
}

export interface InstallAssetResult {
  asset_id: string
  title: string
  target_type: 'project' | 'template'
  target_name: string
  path: string
}

export type NamingConvention =
  | 'keep'
  | 'kebab-case'
  | 'snake_case'
  | 'camelCase'
  | 'PascalCase'
  | 'Title Case'

export interface DiscordProjectPresence {
  id: string
  details: string | null
  state: string | null
}

export interface AppSettings {
  download_dir: string | null
  default_project_location: string | null
  project_scan_dirs: string[]
  version_scan_dirs: string[]
  scan_depth: number
  icon_scan_depth: number
  download_concurrency: number
  accent_color: string
  background_color: string
  corner_radius: number
  raised_contrast: number
  ui_density: number
  font_scale: number
  theme_mode: 'dark' | 'light' | 'system'
  custom_css: string
  animation_intensity: 'full' | 'subtle' | 'none'
  view_entrance: 'fade' | 'slide' | 'scale' | 'none'
  launch_with_console: boolean
  close_on_project_open: boolean
  minimize_to_tray: boolean
  reopen_after_godot_closes: boolean
  last_opened_time_format: '12h' | '24h'
  last_opened_date_format: 'DD-MM-YYYY' | 'MM-DD-YYYY' | 'YYYY-MM-DD'
  setup_complete: boolean
  categories_enabled: boolean
  workspaces_enabled: boolean
  auto_scan_on_startup: boolean
  command_palette_keybind: string
  external_editor_path: string | null
  github_token: string | null
  discord_app_id: string | null
  discord_rpc_enabled: boolean
  discord_rpc_show_projects: boolean
  discord_rpc_excluded_projects: string[]
  discord_rpc_project_presences: DiscordProjectPresence[]
  template_scan_dir: string | null
  auto_watch_project_dirs: boolean
  auto_watch_version_dirs: boolean
  auto_watch_template_dir: boolean
  tooltip_delay: number
  tray_recent_projects_count: number
  show_support_button: boolean
  show_star_button: boolean
  show_bug_button: boolean
  show_tray_button: boolean
  show_language_button: boolean
  show_scrollbars: boolean
  animated_numbers: boolean
  screen_reader_announcements: boolean
  project_icon_opacity: number
  animation_threshold: number
  language: string
  use_os_decorations: boolean
  directory_naming_convention: NamingConvention
  theme_preset: string
  git_init_new_projects: boolean
  open_after_import: boolean
  card_layout: boolean
  dashboard_custom_name: string | null
  default_landing_tab: string
  dashboard_sections: string[]
  dashboard_section_order: string[]
  dashboard_section_spans: string[]
  dashboard_tall_sections: string[]
  dashboard_custom_presets: DashboardCustomPreset[]
  auto_backup_interval_minutes: number
  card_show_size: boolean
  card_show_time: boolean
  card_blur_path: boolean
  card_show_path: boolean
  card_show_tags: boolean
  card_show_last_opened: boolean
  card_show_play: boolean
  card_show_console: boolean
  card_view_overrides: Record<string, Partial<CardViewSettings>>
}

export interface CardViewSettings {
  show_size: boolean
  show_time: boolean
  blur_path: boolean
  show_path: boolean
  show_tags: boolean
  show_last_opened: boolean
  show_play: boolean
  show_console: boolean
}

export type ProjectViewMode = 'list' | 'grid' | 'kanban'

export interface DashboardCustomPreset {
  id: string
  name: string
  sections: string[]
  order: string[]
  spans: string[]
  tall: string[]
}

export interface ScanResult {
  added: Project[]
  found_dismissed: string[]
}

export interface GitAccountInfo {
  username: string
  host?: string | null
}

export interface GitPatInfo {
  host: string
  username: string
}

export interface GitAuthState {
  github: GitAccountInfo | null
  gitlab: GitAccountInfo | null
  pats: GitPatInfo[]
}

export interface DeviceFlowStart {
  provider: string
  device_code: string
  user_code: string
  verification_uri: string
  verification_uri_complete: string
  interval: number
  expires_in: number
  base_url?: string | null
}

export type DeviceFlowPoll =
  | { status: 'pending' }
  | { status: 'success'; username: string }
  | { status: 'error'; message: string }

export interface CreateRepoResult {
  url: string
  slug: string
}

export interface UserRepoInfo {
  name: string
  full_name: string
  description: string | null
  clone_url: string
  html_url: string
  private: boolean
  language: string | null
  default_branch: string | null
}

export interface UserRepoPage {
  repos: UserRepoInfo[]
  has_more: boolean
}

