use crate::models::ProjectTodo;
use std::collections::BTreeMap;
use std::fs;
use std::path::PathBuf;
use std::sync::{Mutex, OnceLock};
use tauri::AppHandle;

type ProjectTodosByProject = BTreeMap<String, Vec<ProjectTodo>>;

fn project_todos_lock() -> &'static Mutex<()> {
    static LOCK: OnceLock<Mutex<()>> = OnceLock::new();

    return LOCK.get_or_init(|| Mutex::new(()));
}

fn project_todos_file(app: &AppHandle) -> PathBuf {
    return crate::workspace::active_workspace_dir(app).join("project_todos.json");
}
fn read_project_todos(app: &AppHandle) -> Result<ProjectTodosByProject, String> {
    let file = project_todos_file(app);

    if !file.exists() {
        return Ok(BTreeMap::new());
    }

    let file_contents = fs::read_to_string(file).map_err(|error| error.to_string())?;

    let project_todos: ProjectTodosByProject =
        serde_json::from_str(&file_contents).map_err(|error| error.to_string())?;

    return Ok(project_todos);
}

pub(crate) fn remove_project_todos(
    app: &AppHandle,
    project_id: &str,
) -> Result<(), String> {
    let _guard = project_todos_lock()
        .lock()
        .map_err(|_| "Failed to lock project todos".to_string())?;

    let mut todos_by_project = read_project_todos(app)?;

    if todos_by_project.remove(project_id).is_none() {
        return Ok(());
    }

    return write_project_todos(app, &todos_by_project);
}

#[tauri::command]
pub fn list_project_todos(app: AppHandle, project_id: String) -> Result<Vec<ProjectTodo>, String> {
    let _guard = project_todos_lock()
        .lock()
        .map_err(|_| "Failed to lock project todos".to_string())?;

    let todos_by_project = read_project_todos(&app)?;

    let project_todos = todos_by_project
        .get(&project_id)
        .cloned()
        .unwrap_or_default();

    return Ok(project_todos);
}
fn write_project_todos(
    app: &AppHandle,
    project_todos: &ProjectTodosByProject,
) -> Result<(), String> {
    let file = project_todos_file(app);

    let result = crate::persist::write_json(&file, project_todos);

    return result.map_err(|error| error.to_string());
}

#[tauri::command]
pub fn save_project_todos(
    app: AppHandle,
    project_id: String,
    todos: Vec<ProjectTodo>,
) -> Result<(), String> {
    let _guard = project_todos_lock()
        .lock()
        .map_err(|_| "Failed to lock project todos".to_string())?;

    let mut todos_by_project = read_project_todos(&app)?;

    if todos.is_empty() {
        todos_by_project.remove(&project_id);
    } else {
        todos_by_project.insert(project_id, todos);
    }

    write_project_todos(&app, &todos_by_project)?;

    return Ok(());
}
