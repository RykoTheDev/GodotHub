use crate::models::{ProjectTodo, TodoStatus};
use serde::Serialize;
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
    #[serde(default)]
    pub counters: BTreeMap<String, u32>,
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

fn load_store(dir: &Path) -> Result<ProjectTodosStore, String> {
    let loaded = persist::load_json::<ProjectTodosStore>(&todos_path(dir));
    if loaded.status == LoadStatus::Corrupt {
        return Err(CORRUPT_MESSAGE.into());
    }
    Ok(loaded.value)
}

fn update_store(dir: &Path, mutate: impl FnOnce(&mut ProjectTodosStore)) -> Result<(), String> {
    load_store(dir)?;
    persist::update_json::<ProjectTodosStore, _>(&todos_path(dir), mutate)
        .map(|_| ())
        .map_err(|e| e.to_string())
}

pub(crate) fn ensure_numbers(todos: &mut [ProjectTodo], counter: &mut u32) -> bool {
    let highest = todos.iter().filter_map(|t| t.number).max().unwrap_or(0);
    *counter = (*counter).max(highest);
    let mut missing: Vec<usize> = todos
        .iter()
        .enumerate()
        .filter(|(_, t)| t.number.is_none())
        .map(|(i, _)| i)
        .collect();
    if missing.is_empty() {
        return false;
    }
    missing.sort_by(|a, b| todos[*a].created_at.cmp(&todos[*b].created_at).then(a.cmp(b)));
    for index in missing {
        *counter += 1;
        todos[index].number = Some(*counter);
    }
    true
}

pub(crate) fn normalize_completion(todos: &mut [ProjectTodo], now: &str) -> bool {
    let mut changed = false;
    for todo in todos.iter_mut() {
        if todo.status == TodoStatus::Done {
            if todo.completed_at.is_none() {
                todo.completed_at = Some(now.to_string());
                changed = true;
            }
        } else if todo.completed_at.take().is_some() {
            changed = true;
        }
    }
    changed
}

pub(crate) fn edit_project_todos<R>(
    dir: &Path,
    project_id: &str,
    edit: impl FnOnce(&mut Vec<ProjectTodo>, &mut u32) -> R,
) -> Result<(Vec<ProjectTodo>, R), String> {
    let mut outcome = None;
    update_store(dir, |store| {
        let mut counter = store.counters.get(project_id).copied().unwrap_or(0);
        let mut todos = store.projects.remove(project_id).unwrap_or_default();
        ensure_numbers(&mut todos, &mut counter);
        let result = edit(&mut todos, &mut counter);
        ensure_numbers(&mut todos, &mut counter);
        normalize_completion(&mut todos, &chrono::Utc::now().to_rfc3339());
        if !todos.is_empty() {
            store.projects.insert(project_id.to_string(), todos.clone());
        }
        if counter > 0 {
            store.counters.insert(project_id.to_string(), counter);
        }
        outcome = Some((todos, result));
    })?;
    outcome.ok_or_else(|| "Could not update the to-do list".to_string())
}

pub(crate) fn read_todos_from(dir: &Path) -> TodosByProject {
    load_store(dir).map(|s| s.projects).unwrap_or_default()
}

pub(crate) fn write_todos_to(dir: &Path, todos: &TodosByProject) -> Result<(), String> {
    persist::update_json::<ProjectTodosStore, _>(&todos_path(dir), |store| {
        store.projects = todos.clone()
    })
    .map(|_| ())
    .map_err(|e| e.to_string())
}

fn list_in(dir: &Path, project_id: &str) -> Result<Vec<ProjectTodo>, String> {
    let store = load_store(dir)?;
    let todos = store.projects.get(project_id).cloned().unwrap_or_default();
    if todos.iter().all(|t| t.number.is_some()) {
        return Ok(todos);
    }
    edit_project_todos(dir, project_id, |_, _| ()).map(|(todos, _)| todos)
}

fn save_in(dir: &Path, project_id: &str, todos: Vec<ProjectTodo>) -> Result<Vec<ProjectTodo>, String> {
    edit_project_todos(dir, project_id, |current, _| *current = todos).map(|(todos, _)| todos)
}

fn remove_in(dir: &Path, project_id: &str) -> Result<(), String> {
    let store = load_store(dir)?;
    if !store.projects.contains_key(project_id) && !store.counters.contains_key(project_id) {
        return Ok(());
    }
    update_store(dir, |store| {
        store.projects.remove(project_id);
        store.counters.remove(project_id);
    })
}

fn copy_in(dir: &Path, from_id: &str, to_id: &str) -> Result<(), String> {
    let store = load_store(dir)?;
    let Some(source) = store.projects.get(from_id).cloned() else {
        return Ok(());
    };
    if source.is_empty() {
        return Ok(());
    }
    let counter = store.counters.get(from_id).copied().unwrap_or(0);
    let copied: Vec<ProjectTodo> = source
        .into_iter()
        .map(|mut todo| {
            todo.id = Uuid::new_v4().to_string();
            todo
        })
        .collect();
    update_store(dir, |store| {
        store.projects.insert(to_id.to_string(), copied);
        if counter > 0 {
            store.counters.insert(to_id.to_string(), counter);
        }
    })
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OpenTodo {
    pub project_id: String,
    pub project_name: String,
    pub todo: ProjectTodo,
}

fn open_todos_in(dir: &Path, projects: &[(String, String)]) -> Result<Vec<OpenTodo>, String> {
    let store = load_store(dir)?;
    let mut open = Vec::new();
    for (project_id, project_name) in projects {
        let Some(todos) = store.projects.get(project_id) else {
            continue;
        };
        for todo in todos.iter().filter(|t| t.status != TodoStatus::Done) {
            open.push(OpenTodo {
                project_id: project_id.clone(),
                project_name: project_name.clone(),
                todo: todo.clone(),
            });
        }
    }
    Ok(open)
}

pub(crate) fn active_dir(app: &AppHandle) -> PathBuf {
    crate::workspace::active_workspace_dir(app)
}

pub(crate) fn remove_project_todos(app: &AppHandle, project_id: &str) -> Result<(), String> {
    remove_in(&active_dir(app), project_id)
}

pub(crate) fn copy_project_todos(app: &AppHandle, from_id: &str, to_id: &str) -> Result<(), String> {
    copy_in(&active_dir(app), from_id, to_id)
}

#[tauri::command]
pub fn list_open_todos(app: AppHandle) -> Result<Vec<OpenTodo>, String> {
    let projects: Vec<(String, String)> = crate::projects::read_projects(&app)
        .into_iter()
        .map(|p| (p.id, p.name))
        .collect();
    open_todos_in(&active_dir(&app), &projects)
}

#[tauri::command]
pub fn list_project_todos(app: AppHandle, project_id: String) -> Result<Vec<ProjectTodo>, String> {
    list_in(&active_dir(&app), &project_id)
}

#[tauri::command]
pub fn save_project_todos(
    app: AppHandle,
    project_id: String,
    todos: Vec<ProjectTodo>,
) -> Result<Vec<ProjectTodo>, String> {
    save_in(&active_dir(&app), &project_id, todos)
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::models::{TodoArea, TodoStatus};
    use std::fs;

    pub(crate) fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("gh_todos_{name}_{}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    pub(crate) fn todo(id: &str, title: &str) -> ProjectTodo {
        ProjectTodo {
            id: id.into(),
            title: title.into(),
            status: TodoStatus::Todo,
            area: TodoArea::Programming,
            due_date: None,
            description: None,
            created_at: "2026-10-22T00:00:00Z".into(),
            number: None,
            link: None,
            source: None,
            closed_by: None,
            priority: None,
            checklist: Vec::new(),
            completed_at: None,
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
        let todos = list_in(&dir, "project-a").unwrap();
        assert_eq!(todos[0].title, "Fix jump");
        assert_eq!(todos[0].number, Some(1));

        save_in(&dir, "project-b", vec![todo("2", "Add music")]).unwrap();
        let raw: serde_json::Value =
            serde_json::from_str(&fs::read_to_string(todos_path(&dir)).unwrap()).unwrap();
        assert_eq!(raw["schema_version"], 1);
        assert_eq!(read_todos_from(&dir).len(), 2);
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn recovers_from_backup_and_refuses_to_overwrite_corrupt_file() {
        let dir = temp_dir("corrupt");
        save_in(&dir, "p", vec![todo("1", "First")]).unwrap();
        save_in(&dir, "p", vec![todo("1", "First"), todo("2", "Second")]).unwrap();
        fs::write(todos_path(&dir), "{ not json").unwrap();
        assert_eq!(list_in(&dir, "p").unwrap().len(), 1);

        fs::write(persist::backup_path(&todos_path(&dir)), "{ also broken").unwrap();
        assert!(list_in(&dir, "p").is_err());
        assert!(save_in(&dir, "p", vec![]).is_err());
        assert_eq!(fs::read_to_string(todos_path(&dir)).unwrap(), "{ not json");
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn numbers_are_assigned_in_creation_order_and_never_reused() {
        let dir = temp_dir("numbers");
        let mut older = todo("a", "Older");
        older.created_at = "2026-01-01T00:00:00Z".into();
        let mut newer = todo("b", "Newer");
        newer.created_at = "2026-02-01T00:00:00Z".into();
        let saved = save_in(&dir, "p", vec![newer, older]).unwrap();
        assert_eq!(saved.iter().find(|t| t.id == "a").unwrap().number, Some(1));
        assert_eq!(saved.iter().find(|t| t.id == "b").unwrap().number, Some(2));

        save_in(&dir, "p", vec![saved[0].clone()]).unwrap();
        let again = save_in(&dir, "p", vec![saved[0].clone(), todo("c", "Third")]).unwrap();
        assert_eq!(again.iter().find(|t| t.id == "c").unwrap().number, Some(3));

        save_in(&dir, "p", vec![]).unwrap();
        let fresh = save_in(&dir, "p", vec![todo("d", "After clearing")]).unwrap();
        assert_eq!(fresh[0].number, Some(4));
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn copies_todos_with_fresh_ids_and_removes_by_project() {
        let dir = temp_dir("copy");
        save_in(&dir, "src", vec![todo("a", "One"), todo("b", "Two")]).unwrap();
        copy_in(&dir, "src", "dst").unwrap();
        let copied = list_in(&dir, "dst").unwrap();
        assert_eq!(copied.len(), 2);
        assert_eq!(copied[0].title, "One");
        assert_ne!(copied[0].id, "a");
        assert_eq!(copied[0].number, Some(1));
        let added = save_in(&dir, "dst", [copied, vec![todo("x", "New")]].concat()).unwrap();
        assert_eq!(added.iter().find(|t| t.id == "x").unwrap().number, Some(3));

        copy_in(&dir, "missing", "other").unwrap();
        assert!(!read_todos_from(&dir).contains_key("other"));

        remove_in(&dir, "src").unwrap();
        let todos = read_todos_from(&dir);
        assert!(!todos.contains_key("src"));
        assert!(todos.contains_key("dst"));
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn completion_date_is_set_when_done_and_cleared_when_reopened() {
        let dir = temp_dir("completion");
        let mut done = todo("a", "Ship it");
        done.status = TodoStatus::Done;
        let saved = save_in(&dir, "p", vec![done, todo("b", "Later")]).unwrap();
        let first = saved.iter().find(|t| t.id == "a").unwrap().clone();
        assert!(first.completed_at.is_some());
        assert!(saved.iter().find(|t| t.id == "b").unwrap().completed_at.is_none());

        let again = save_in(&dir, "p", vec![first.clone()]).unwrap();
        assert_eq!(again[0].completed_at, first.completed_at);

        let mut reopened = first;
        reopened.status = TodoStatus::InProgress;
        let after = save_in(&dir, "p", vec![reopened]).unwrap();
        assert!(after[0].completed_at.is_none());
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn priority_and_checklist_round_trip_and_default_when_missing() {
        let dir = temp_dir("fields");
        let mut rich = todo("a", "Boss fight");
        rich.priority = Some(crate::models::TodoPriority::High);
        rich.checklist = vec![
            crate::models::TodoChecklistItem { id: "1".into(), text: "Phase one".into(), done: true },
            crate::models::TodoChecklistItem { id: "2".into(), text: "Phase two".into(), done: false },
        ];
        save_in(&dir, "p", vec![rich, todo("b", "Plain")]).unwrap();
        let raw = fs::read_to_string(todos_path(&dir)).unwrap();
        assert!(raw.contains("\"priority\": \"high\""));
        assert_eq!(raw.matches("\"checklist\"").count(), 1);
        let loaded = list_in(&dir, "p").unwrap();
        let boss = loaded.iter().find(|t| t.id == "a").unwrap();
        assert_eq!(boss.priority, Some(crate::models::TodoPriority::High));
        assert_eq!(boss.checklist.len(), 2);
        assert!(boss.checklist[0].done);
        let plain = loaded.iter().find(|t| t.id == "b").unwrap();
        assert!(plain.priority.is_none() && plain.checklist.is_empty());
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn open_todos_cover_every_listed_project_and_skip_done_or_unknown() {
        let dir = temp_dir("open");
        let mut done = todo("d", "Finished");
        done.status = TodoStatus::Done;
        save_in(&dir, "game", vec![todo("a", "Jump"), done]).unwrap();
        save_in(&dir, "tool", vec![todo("b", "Export")]).unwrap();
        save_in(&dir, "removed", vec![todo("c", "Orphan")]).unwrap();
        let projects = vec![("game".to_string(), "My Game".to_string()), ("tool".to_string(), "Tool".to_string())];
        let open = open_todos_in(&dir, &projects).unwrap();
        let titles: Vec<(&str, &str)> = open.iter().map(|o| (o.project_name.as_str(), o.todo.title.as_str())).collect();
        assert_eq!(titles, vec![("My Game", "Jump"), ("Tool", "Export")]);
        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn write_replaces_whole_store_for_backup_restore() {
        let dir = temp_dir("restore");
        save_in(&dir, "old", vec![todo("1", "Old")]).unwrap();
        let mut restored = TodosByProject::new();
        restored.insert("new".into(), vec![todo("2", "New")]);
        write_todos_to(&dir, &restored).unwrap();
        let todos = read_todos_from(&dir);
        assert!(todos.contains_key("new"));
        assert!(!todos.contains_key("old"));
        let _ = fs::remove_dir_all(&dir);
    }
}
