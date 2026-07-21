export interface InstalledGodotVersion {
  tag: string
  version: string
  executable_path: string
  is_mono: boolean
  installed_at: string
  custom_name?: string | null
  install_root?: string | null
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
  created_at: number
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
}

export interface ProjectUpdate {
  name?: string
  godot_version?: string
  category?: string
  pinned?: boolean
  launch_arguments?: string
}

export interface GitStatus {
  branch: string | null
  has_uncommitted: boolean
  is_repo: boolean
}

export interface GitLogEntry {
  hash: string
  message: string
  author: string
  date: string
}

export interface GitBranchInfo {
  name: string
  is_current: boolean
}

export interface GitStashEntry {
  index: number
  message: string
}

export interface GitChangedFile {
  path: string
  status: string
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
}

export interface AppSettings {
  download_dir: string | null
  default_project_location: string | null
  project_scan_dirs: string[]
  version_scan_dirs: string[]
  scan_depth: number
  download_concurrency: number
  accent_color: string
  background_color: string
  corner_radius: number
  ui_density: number
  font_scale: number
  reduce_motion: boolean
  theme_mode: 'dark' | 'light'
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
  template_scan_dir: string | null
  auto_watch_project_dirs: boolean
  auto_watch_version_dirs: boolean
  auto_watch_template_dir: boolean
  tooltip_delay: number
  tray_recent_projects_count: number
}
