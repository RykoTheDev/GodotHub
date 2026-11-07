use crate::models::Project;
use crate::{projects, settings, AppHandle};

pub const OPEN_PROJECT_ARG: &str = "--open-project=";

#[derive(Debug, Clone, PartialEq)]
pub struct RecentProject {
    pub id: String,
    pub label: String,
    pub path: String,
}

pub fn project_from_args(args: &[String]) -> Option<String> {
    args.iter()
        .find_map(|arg| arg.strip_prefix(OPEN_PROJECT_ARG))
        .map(str::to_string)
        .filter(|id| !id.is_empty())
}

pub fn open_from_args(app: &AppHandle, args: &[String]) -> bool {
    let Some(id) = project_from_args(args) else {
        return false;
    };
    crate::runtime::spawn(crate::projects::open_project(app.clone(), id, true, None));
    true
}

pub fn recent_projects(app: &AppHandle) -> Vec<RecentProject> {
    let count = settings::read_settings(app).tray_recent_projects_count as usize;
    let projects = projects::read_projects(app);
    let mut recent: Vec<&Project> = projects
        .iter()
        .filter(|p| p.last_opened.is_some())
        .collect();
    recent.sort_by(|a, b| {
        b.last_opened
            .as_deref()
            .unwrap()
            .cmp(a.last_opened.as_deref().unwrap())
    });
    recent
        .into_iter()
        .take(count)
        .map(|p| {
            let resolved = projects::resolve_project_name(&p.path)
                .filter(|n| !n.trim().is_empty())
                .unwrap_or_else(|| p.name.clone());
            let label = if resolved.chars().count() > 48 {
                format!("{}…", resolved.chars().take(47).collect::<String>())
            } else {
                resolved
            };
            RecentProject {
                id: p.id.clone(),
                label,
                path: p.path.clone(),
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_project_id_from_launch_arguments() {
        let args = vec!["GodotHub.exe".to_string(), "--open-project=abc-123".to_string()];
        assert_eq!(project_from_args(&args).as_deref(), Some("abc-123"));
        assert_eq!(project_from_args(&["--open-project=".to_string()]), None);
        assert_eq!(project_from_args(&["versions".to_string()]), None);
    }
}
