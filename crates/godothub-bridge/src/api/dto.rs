use std::collections::HashMap;

use serde_json::{Map, Value};

use super::error::CoreError;
use super::types::HealthAction;
use crate::host::app;

pub struct ExportPreset {
    pub id: u32,
    pub name: String,
    pub platform: String,
    pub output_path: String,
    pub missing_templates: Vec<String>,
    pub template_error: Option<String>,
}

pub struct ExportCatalog {
    pub version_tag: String,
    pub engine_error: Option<String>,
    pub presets: Vec<ExportPreset>,
}

impl From<godothub_core::export_runner::ExportCatalog> for ExportCatalog {
    fn from(catalog: godothub_core::export_runner::ExportCatalog) -> Self {
        Self {
            version_tag: catalog.version_tag,
            engine_error: catalog.engine_error,
            presets: catalog
                .presets
                .into_iter()
                .map(|preset| ExportPreset {
                    id: preset.id,
                    name: preset.name,
                    platform: preset.platform,
                    output_path: preset.output_path,
                    missing_templates: preset.missing_templates,
                    template_error: preset.template_error,
                })
                .collect(),
        }
    }
}

pub struct HealthCheck {
    pub id: String,
    pub category: String,
    pub severity: String,
    pub code: String,
    pub details: Vec<String>,
    pub values: HashMap<String, String>,
    pub action: Option<HealthAction>,
}

pub struct HealthReport {
    pub project_id: String,
    pub scanned_at_ms: u64,
    pub checks: Vec<HealthCheck>,
}

impl From<godothub_core::project_health::HealthReport> for HealthReport {
    fn from(report: godothub_core::project_health::HealthReport) -> Self {
        Self {
            project_id: report.project_id,
            scanned_at_ms: report.scanned_at_ms,
            checks: report
                .checks
                .into_iter()
                .map(|check| HealthCheck {
                    id: check.id,
                    category: check.category,
                    severity: check.severity,
                    code: check.code,
                    details: check.details,
                    values: check.values.into_iter().collect(),
                    action: check.action,
                })
                .collect(),
        }
    }
}

pub enum DeviceFlowStatus {
    Pending,
    Success,
    Error,
}

pub struct DeviceFlowPoll {
    pub status: DeviceFlowStatus,
    pub username: Option<String>,
    pub message: Option<String>,
}

impl From<godothub_core::git_auth::DeviceFlowPoll> for DeviceFlowPoll {
    fn from(poll: godothub_core::git_auth::DeviceFlowPoll) -> Self {
        use godothub_core::git_auth::DeviceFlowPoll as Core;
        match poll {
            Core::Pending => Self {
                status: DeviceFlowStatus::Pending,
                username: None,
                message: None,
            },
            Core::Success { username } => Self {
                status: DeviceFlowStatus::Success,
                username: Some(username),
                message: None,
            },
            Core::Error { message } => Self {
                status: DeviceFlowStatus::Error,
                username: None,
                message: Some(message),
            },
        }
    }
}

pub enum ReclaimKind {
    Version,
    Partial,
    ExportTemplates,
}

pub struct ReclaimItem {
    pub kind: ReclaimKind,
    pub tag: Option<String>,
    pub path: Option<String>,
    pub folder: Option<String>,
    pub root: Option<String>,
}

impl TryFrom<ReclaimItem> for godothub_core::storage::ReclaimItem {
    type Error = CoreError;

    fn try_from(item: ReclaimItem) -> Result<Self, Self::Error> {
        let missing = |field: &str| CoreError::from(format!("missing field `{field}`"));
        Ok(match item.kind {
            ReclaimKind::Version => Self::Version {
                tag: item.tag.ok_or_else(|| missing("tag"))?,
            },
            ReclaimKind::Partial => Self::Partial {
                path: item.path.ok_or_else(|| missing("path"))?,
            },
            ReclaimKind::ExportTemplates => Self::ExportTemplates {
                folder: item.folder.ok_or_else(|| missing("folder"))?,
                root: item.root.ok_or_else(|| missing("root"))?,
            },
        })
    }
}

pub struct UiPrefs {
    pub migrated_from_local_storage: bool,
    pub values: HashMap<String, String>,
}

impl From<godothub_core::ui_prefs::UiPrefs> for UiPrefs {
    fn from(prefs: godothub_core::ui_prefs::UiPrefs) -> Self {
        Self {
            migrated_from_local_storage: prefs.migrated_from_local_storage,
            values: prefs
                .values
                .into_iter()
                .map(|(key, value)| (key, value.to_string()))
                .collect(),
        }
    }
}

fn parse_json(raw: &str) -> Result<Value, CoreError> {
    serde_json::from_str(raw).map_err(|e| CoreError::from(format!("Invalid JSON value: {e}")))
}

pub async fn get_project_export_presets(id: String) -> Result<ExportCatalog, CoreError> {
    let app = app()?;
    Ok(godothub_core::export_runner::get_project_export_presets(app, id).await?.into())
}

pub async fn poll_device_flow(
    provider: String,
    device_code: String,
    base_url: Option<String>,
    client_id: Option<String>,
) -> Result<DeviceFlowPoll, CoreError> {
    let app = app()?;
    Ok(godothub_core::git_auth::poll_device_flow(app, provider, device_code, base_url, client_id)
        .await?
        .into())
}

pub async fn diagnose_project(id: String) -> Result<HealthReport, CoreError> {
    let app = app()?;
    Ok(godothub_core::project_health::diagnose_project(app, id).await?.into())
}

pub async fn reclaim_storage(items: Vec<ReclaimItem>) -> Result<super::types::ReclaimResult, CoreError> {
    let app = app()?;
    let items = items
        .into_iter()
        .map(godothub_core::storage::ReclaimItem::try_from)
        .collect::<Result<Vec<_>, _>>()?;
    Ok(godothub_core::storage::reclaim_storage(app, items).await?)
}

pub async fn get_ui_prefs() -> Result<UiPrefs, CoreError> {
    let app = app()?;
    Ok(crate::lane::serial(move || godothub_core::ui_prefs::get_ui_prefs_with_webview_import(app)).await?.into())
}

pub async fn get_ui_pref(key: String) -> Result<Option<String>, CoreError> {
    let app = app()?;
    let value = crate::lane::serial(move || godothub_core::ui_prefs::get_ui_pref(app, key)).await?;
    Ok(value.map(|value| value.to_string()))
}

pub async fn set_ui_pref(key: String, value: String) -> Result<(), CoreError> {
    let app = app()?;
    let value = parse_json(&value)?;
    Ok(crate::lane::serial(move || godothub_core::ui_prefs::set_ui_pref(app, key, value)).await?)
}

pub async fn import_ui_prefs(values: HashMap<String, String>) -> Result<UiPrefs, CoreError> {
    let app = app()?;
    let values = values
        .into_iter()
        .map(|(key, raw)| parse_json(&raw).map(|value| (key, value)))
        .collect::<Result<Map<String, Value>, _>>()?;
    Ok(crate::lane::serial(move || godothub_core::ui_prefs::import_ui_prefs(app, values)).await?.into())
}
