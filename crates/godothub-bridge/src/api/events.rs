use std::sync::Mutex;

use serde::de::DeserializeOwned;
use serde::Deserialize;

use super::types::{
    AssetDownloadError, AssetDownloadProgress, DownloadProgress, ExportRun, ExportTemplatesError,
    ExportTemplatesProgress, ExportTemplatesStage,
};
use crate::frb_generated::StreamSink;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AppEventKind {
    ProjectLaunched,
    ProjectExited,
    ProjectConsoleExit,
    ExportStarted,
    ExportFinished,
    GodotDownloadQueued,
    GodotDownloadQueue,
    GodotDownloadProgress,
    GodotDownloadPaused,
    GodotDownloadCanceled,
    GodotDownloadError,
    GodotDownloadUnverified,
    GodotDownloadComplete,
    VersionsAvailableUpdated,
    VersionsAliasesChanged,
    ExportTemplatesQueued,
    ExportTemplatesProgress,
    ExportTemplatesStage,
    ExportTemplatesError,
    ExportTemplatesCanceled,
    ExportTemplatesComplete,
    AssetDownloadQueued,
    AssetDownloadProgress,
    AssetDownloadComplete,
    AssetDownloadError,
    ProjectScanProgress,
    ProjectScanDone,
    VersionScanProgress,
    VersionScanDone,
    TemplateSynced,
    GitProjectChanged,
    SecondInstance,
    Unknown,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProjectLaunched {
    pub id: String,
    pub name: String,
    pub version: String,
    pub console: bool,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProjectExited {
    pub id: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ConsoleExit {
    pub id: String,
    pub code: Option<i32>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DownloadFailure {
    pub tag: String,
    pub message: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DownloadUnverified {
    pub tag: String,
    pub reason: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ScanProgress {
    pub current: u32,
    pub total: u32,
}

#[derive(Clone)]
pub struct AppEvent {
    pub kind: AppEventKind,
    pub name: String,
    pub json: String,
    pub text: Option<String>,
    pub queue: Option<Vec<String>>,
    pub args: Option<Vec<String>>,
    pub scan_progress: Option<ScanProgress>,
    pub project_launched: Option<ProjectLaunched>,
    pub project_exited: Option<ProjectExited>,
    pub console_exit: Option<ConsoleExit>,
    pub export_run: Option<ExportRun>,
    pub download_progress: Option<DownloadProgress>,
    pub download_failure: Option<DownloadFailure>,
    pub download_unverified: Option<DownloadUnverified>,
    pub export_templates_progress: Option<ExportTemplatesProgress>,
    pub export_templates_stage: Option<ExportTemplatesStage>,
    pub export_templates_error: Option<ExportTemplatesError>,
    pub asset_download_progress: Option<AssetDownloadProgress>,
    pub asset_download_error: Option<AssetDownloadError>,
}

impl AppEvent {
    fn new(kind: AppEventKind, name: &str, json: &str) -> Self {
        Self {
            kind,
            name: name.to_string(),
            json: json.to_string(),
            text: None,
            queue: None,
            args: None,
            scan_progress: None,
            project_launched: None,
            project_exited: None,
            console_exit: None,
            export_run: None,
            download_progress: None,
            download_failure: None,
            download_unverified: None,
            export_templates_progress: None,
            export_templates_stage: None,
            export_templates_error: None,
            asset_download_progress: None,
            asset_download_error: None,
        }
    }
}

fn kind_of(name: &str) -> AppEventKind {
    use AppEventKind::*;
    match name {
        "project:launched" => ProjectLaunched,
        "project:exited" => ProjectExited,
        "project:console-exit" => ProjectConsoleExit,
        "export:started" => ExportStarted,
        "export:finished" => ExportFinished,
        "godot-download-queued" => GodotDownloadQueued,
        "godot-download-queue" => GodotDownloadQueue,
        "godot-download-progress" => GodotDownloadProgress,
        "godot-download-paused" => GodotDownloadPaused,
        "godot-download-canceled" => GodotDownloadCanceled,
        "godot-download-error" => GodotDownloadError,
        "godot-download-unverified" => GodotDownloadUnverified,
        "godot-download-complete" => GodotDownloadComplete,
        "versions:available-updated" => VersionsAvailableUpdated,
        "versions:aliases-changed" => VersionsAliasesChanged,
        "export-templates-queued" => ExportTemplatesQueued,
        "export-templates-progress" => ExportTemplatesProgress,
        "export-templates-stage" => ExportTemplatesStage,
        "export-templates-error" => ExportTemplatesError,
        "export-templates-canceled" => ExportTemplatesCanceled,
        "export-templates-complete" => ExportTemplatesComplete,
        "asset-download-queued" => AssetDownloadQueued,
        "asset-download-progress" => AssetDownloadProgress,
        "asset-download-complete" => AssetDownloadComplete,
        "asset-download-error" => AssetDownloadError,
        "project-scan-progress" => ProjectScanProgress,
        "watcher:project-scan-done" => ProjectScanDone,
        "version-scan-progress" => VersionScanProgress,
        "watcher:version-scan-done" => VersionScanDone,
        "watcher:template-synced" => TemplateSynced,
        "git:project-changed" => GitProjectChanged,
        "app:second-instance" => SecondInstance,
        _ => Unknown,
    }
}

fn parse<T: DeserializeOwned>(json: &str) -> Option<T> {
    serde_json::from_str(json).ok()
}

pub(crate) fn decode(name: &str, json: &str) -> AppEvent {
    use AppEventKind::*;
    let kind = kind_of(name);
    let mut event = AppEvent::new(kind, name, json);
    match kind {
        ProjectLaunched => event.project_launched = parse(json),
        ProjectExited => event.project_exited = parse(json),
        ProjectConsoleExit => event.console_exit = parse(json),
        ExportStarted | ExportFinished => event.export_run = parse(json),
        GodotDownloadQueue => event.queue = parse(json),
        SecondInstance => event.args = parse(json),
        GodotDownloadProgress => event.download_progress = parse(json),
        GodotDownloadError => event.download_failure = parse(json),
        GodotDownloadUnverified => event.download_unverified = parse(json),
        ExportTemplatesProgress => event.export_templates_progress = parse(json),
        ExportTemplatesStage => event.export_templates_stage = parse(json),
        ExportTemplatesError => event.export_templates_error = parse(json),
        AssetDownloadQueued | AssetDownloadProgress | AssetDownloadComplete => {
            event.asset_download_progress = parse(json)
        }
        AssetDownloadError => event.asset_download_error = parse(json),
        ProjectScanProgress | VersionScanProgress => {
            event.scan_progress = parse::<(u32, u32)>(json).map(|(current, total)| ScanProgress { current, total })
        }
        GodotDownloadQueued | GodotDownloadPaused | GodotDownloadCanceled | GodotDownloadComplete
        | VersionsAvailableUpdated | ExportTemplatesQueued | ExportTemplatesCanceled
        | ExportTemplatesComplete => event.text = parse(json),
        VersionsAliasesChanged | ProjectScanDone | VersionScanDone | TemplateSynced | GitProjectChanged
        | Unknown => {}
    }
    event
}

static SINKS: Mutex<Vec<StreamSink<AppEvent>>> = Mutex::new(Vec::new());

pub(crate) fn dispatch(name: &str, json: &str) {
    let event = decode(name, json);
    let mut sinks = SINKS.lock().unwrap_or_else(std::sync::PoisonError::into_inner);
    sinks.retain(|sink| sink.add(event.clone()).is_ok());
}

pub fn app_events(sink: StreamSink<AppEvent>) {
    SINKS
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
        .push(sink);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_known_event_name_has_a_kind() {
        for name in [
            "project:launched",
            "project:exited",
            "project:console-exit",
            "export:started",
            "export:finished",
            "godot-download-queued",
            "godot-download-queue",
            "godot-download-progress",
            "godot-download-paused",
            "godot-download-canceled",
            "godot-download-error",
            "godot-download-unverified",
            "godot-download-complete",
            "versions:available-updated",
            "versions:aliases-changed",
            "export-templates-queued",
            "export-templates-progress",
            "export-templates-stage",
            "export-templates-error",
            "export-templates-canceled",
            "export-templates-complete",
            "asset-download-queued",
            "asset-download-progress",
            "asset-download-complete",
            "asset-download-error",
            "project-scan-progress",
            "watcher:project-scan-done",
            "version-scan-progress",
            "watcher:version-scan-done",
            "watcher:template-synced",
            "git:project-changed",
            "app:second-instance",
        ] {
            assert_ne!(kind_of(name), AppEventKind::Unknown, "{name}");
        }
        assert_eq!(kind_of("something-else"), AppEventKind::Unknown);
    }

    #[test]
    fn decodes_download_progress() {
        let event = decode("godot-download-progress", r#"{"tag":"4.4.1-stable","downloaded":10,"total":40}"#);
        let progress = event.download_progress.expect("progress payload");
        assert_eq!(progress.tag, "4.4.1-stable");
        assert_eq!((progress.downloaded, progress.total), (10, 40));
    }

    #[test]
    fn decodes_scan_progress_pairs() {
        let event = decode("project-scan-progress", "[3,12]");
        assert_eq!(event.kind, AppEventKind::ProjectScanProgress);
        assert_eq!(event.scan_progress, Some(ScanProgress { current: 3, total: 12 }));
        let event = decode("version-scan-progress", "[0,2]");
        assert_eq!(event.scan_progress, Some(ScanProgress { current: 0, total: 2 }));
    }

    #[test]
    fn decodes_string_and_list_payloads() {
        assert_eq!(decode("godot-download-complete", r#""4.4.1-stable""#).text.as_deref(), Some("4.4.1-stable"));
        assert_eq!(
            decode("godot-download-queue", r#"["a","b"]"#).queue,
            Some(vec!["a".to_string(), "b".to_string()])
        );
        let second = decode("app:second-instance", r#"["GodotHub Beta","--open-project=abc"]"#);
        assert_eq!(second.args, Some(vec!["GodotHub Beta".to_string(), "--open-project=abc".to_string()]));
        let done = decode("watcher:project-scan-done", "null");
        assert_eq!(done.kind, AppEventKind::ProjectScanDone);
        assert_eq!(done.json, "null");
    }

    #[test]
    fn decodes_object_payloads() {
        let launched = decode("project:launched", r#"{"id":"p","name":"Game","version":"4.4","console":true}"#);
        assert!(launched.project_launched.unwrap().console);
        let exit = decode("project:console-exit", r#"{"id":"p","code":null}"#);
        assert_eq!(exit.console_exit.unwrap().code, None);
        let failure = decode("godot-download-error", r#"{"tag":"4.4","message":"checksum"}"#);
        assert_eq!(failure.download_failure.unwrap().message, "checksum");
        let stage = decode("export-templates-stage", r#"{"tag":"4.4","stage":"extracting"}"#);
        assert_eq!(stage.export_templates_stage.unwrap().stage, "extracting");
        let asset = decode("asset-download-error", r#"{"asset_id":"1","title":"","message":"nope"}"#);
        assert_eq!(asset.asset_download_error.unwrap().message, "nope");
    }

    #[test]
    fn decodes_export_runs() {
        let json = r#"{"id":"r","project_id":"p","project_name":"Game","preset_name":"Web","output_path":"out","status":"running","size_bytes":null,"exit_code":null,"error":null,"started_at_ms":1}"#;
        let event = decode("export:started", json);
        assert_eq!(event.export_run.unwrap().status, "running");
    }
}
