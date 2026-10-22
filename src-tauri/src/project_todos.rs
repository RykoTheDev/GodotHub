use crate::models::ProjectTodo;
use crate::persist::{self, LoadStatus};
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use tauri::AppHandle;
use uuid::Uuid;

pub(crate) type TodosByProject = BTreeMap<String, Vec<ProjectTodo>>;

#[derive(serde::Serialize, serde::Deserialize, Default)]
pub(crate) struct ProjectTodosStore {
    #[serde(default)]
    pub schema_version: u32,
    #[serde(default)]
    pub projects: TodosByProject,
}

impl persist::Versioned for ProjectTodosStore {
    const VERSION: u32 = 1;
    fn migrate(value: serde_json::Value, from: u32) -> serde_json::Value {
        if from == 0 && value.is_object() && value.get("schema_version").is_none() {
            return serde_json::json!({ "schema_version": 1, "projects": value });
        }
        value
    }
}

const CORRUPT_MESSAGE: &str =
    "Your to-do list file is damaged and its backup couldn't be read, so it was left untouched.";

fn todos_path(dir: &Path) -> PathBuf {
    dir.join("project_todos.json")
}

fn load_in(dir: &Path) -> Result<TodosByProject, String> {
    let loaded = persist::load_json::<ProjectTodosStore>(&todos_path(dir));
    if loaded.status == LoadStatus::Corrupt {
        return Err(CORRUPT_MESSAGE.into());
    }
    Ok(loaded.value.projects)
}

fn update_in(dir: &Path, mutate: impl FnOnce(&mut TodosByProject)) -> Result<(), String> {
    load_in(dir)?;
    persist::update_json::<ProjectTodosStore, _>(&todos_path(dir), |store| {
        mutate(&mut store.projects)
    })
    .map(|_| ())
    .map_err(|e| e.to_string())
}

pub(crate) fn read_todos_from(dir: &Path) -> TodosByProject {
    load_in(dir).unwrap_or_default()
}

pub(crate) fn write_todos_to(dir: &Path, todos: &TodosByProject) -> Result<(), String> {
    persist::update_json::<ProjectTodosStore, _>(&todos_path(dir), |store| {
        store.projects = todos.clone()
    })
    .map(|_| ())
    .map_err(|e| e.to_string())
}

fn remove_in(dir: &Path, project_id: &str) -> Result<(), String> {
    if !load_in(dir)?.contains_key(project_id) {
        return Ok(());
    }
    update_in(dir, |todos| {
        todos.remove(project_id);
    })
}

fn copy_in(dir: &Path, from_id: &str, to_id: &str) -> Result<(), String> {
    let Some(source) = load_in(dir)?.get(from_id).cloned() else {
        return Ok(());
    };
    if source.is_empty() {
        return Ok(());
    }
    let copied: Vec<ProjectTodo> = source
        .into_iter()
        .map(|mut todo| {
            todo.id = Uuid::new_v4().to_string();
            todo
        })
        .collect();
    update_in(dir, |todos| {
        todos.insert(to_id.to_string(), copied);
    })
}

fn active_dir(app: &AppHandle) -> PathBuf {
    crate::workspace::active_workspace_dir(app)
}

pub(crate) fn remove_project_todos(app: &AppHandle, project_id: &str) -> Result<(), String> {
    remove_in(&active_dir(app), project_id)
}

pub(crate) fn copy_project_todos(app: &AppHandle, from_id: &str, to_id: &str) -> Result<(), String> {
    copy_in(&active_dir(app), from_id, to_id)
}

#[tauri::command]
pub fn list_project_todos(app: AppHandle, project_id: String) -> Result<Vec<ProjectTodo>, String> {
    Ok(load_in(&active_dir(&app))?
        .get(&project_id)
        .cloned()
        .unwrap_or_default())
}

#[tauri::command]
pub fn save_project_todos(
    app: AppHandle,
    project_id: String,
    todos: Vec<ProjectTodo>,
) -> Result<(), String> {
    update_in(&active_dir(&app), |all| {
        if todos.is_empty() {
            all.remove(&project_id);
        } else {
            all.insert(project_id, todos);
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{TodoArea, TodoStatus};
    use std::fs;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("gh_todos_{name}_{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn todo(id: &str, title: &str) -> ProjectTodo {
        ProjectTodo {
            id: id.into(),
            title: title.into(),
            status: TodoStatus::Todo,
            area: TodoArea::Programming,
            due_date: None,
            description: None,
            created_at: "2026-10-22T00:00:00Z".into(),
        }
    }

    #[test]
    fn migrates_legacy_unversioned_file() {
        let dir = temp_dir("legacy");
        fs::write(
            todos_path(&dir),
            r#"{"project-a":[{"id":"1","title":"Fix jump","status":"todo","area":"programming","createdAt":"2026-10-01T00:00:00Z"}]}"#,
        )
        .unwrap();
        let todos = load_in(&dir).unwrap();
        assert_eq!(todos["project-a"][0].title, "Fix jump");

        update_in(&dir, |all| {
            all.insert("project-b".into(), vec![todo("2", "Add music")]);
        })
        .unwrap();
        let raw = fs::read_to_string(todos_path(&dir)).unwrap();
        assert!(raw.contains("\"schema_version\": 1"));
        let todos = load_in(&dir).unwrap();
        assert_eq!(todos.len(), 2);
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn recovers_from_backup_and_refuses_to_overwrite_corrupt_file() {
        let dir = temp_dir("corrupt");
        update_in(&dir, |all| {
            all.insert("p".into(), vec![todo("1", "First")]);
        })
        .unwrap();
        update_in(&dir, |all| {
            all.insert("p".into(), vec![todo("1", "First"), todo("2", "Second")]);
        })
        .unwrap();
        fs::write(todos_path(&dir), "{ not json").unwrap();
        assert_eq!(load_in(&dir).unwrap()["p"].len(), 1);

        fs::write(persist::backup_path(&todos_path(&dir)), "{ also broken").unwrap();
        assert!(load_in(&dir).is_err());
        assert!(update_in(&dir, |all| all.clear()).is_err());
        assert_eq!(fs::read_to_string(todos_path(&dir)).unwrap(), "{ not json");
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn copies_todos_with_fresh_ids_and_removes_by_project() {
        let dir = temp_dir("copy");
        update_in(&dir, |all| {
            all.insert("src".into(), vec![todo("a", "One"), todo("b", "Two")]);
        })
        .unwrap();
        copy_in(&dir, "src", "dst").unwrap();
        let todos = load_in(&dir).unwrap();
        assert_eq!(todos["dst"].len(), 2);
        assert_eq!(todos["dst"][0].title, "One");
        assert_ne!(todos["dst"][0].id, "a");
        assert_eq!(todos["src"][0].id, "a");

        copy_in(&dir, "missing", "other").unwrap();
        assert!(!load_in(&dir).unwrap().contains_key("other"));

        remove_in(&dir, "src").unwrap();
        let todos = load_in(&dir).unwrap();
        assert!(!todos.contains_key("src"));
        assert!(todos.contains_key("dst"));
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_replaces_whole_store_for_backup_restore() {
        let dir = temp_dir("restore");
        update_in(&dir, |all| {
            all.insert("old".into(), vec![todo("1", "Old")]);
        })
        .unwrap();
        let mut restored = TodosByProject::new();
        restored.insert("new".into(), vec![todo("2", "New")]);
        write_todos_to(&dir, &restored).unwrap();
        let todos = read_todos_from(&dir);
        assert!(todos.contains_key("new"));
        assert!(!todos.contains_key("old"));
        let _ = fs::remove_dir_all(&dir);
    }
}
