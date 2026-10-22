import { invoke } from "@tauri-apps/api/core";
import type {
  OpenTodo,
  ProjectTodo,
  TodoGitActivity,
  TodoSyncResult,
} from "../types/projectTodo";

export const projectTodosApi = {
  list: listProjectTodos,
  save: saveProjectTodos,
  sync: syncProjectTodos,
  activity: todoGitActivity,
  resources: listProjectResources,
  openLink: openTodoLink,
  open: listOpenTodos,
}

async function listOpenTodos(): Promise<OpenTodo[]> {
  return invoke<OpenTodo[]>("list_open_todos");
}

async function listProjectTodos(projectId: string): Promise<ProjectTodo[]> {
  const projectTodos = await invoke<ProjectTodo[]>("list_project_todos", {projectId});

  return projectTodos;
}

async function saveProjectTodos(
  projectId: string,
  todos: ProjectTodo[],
): Promise<ProjectTodo[]> {
  return invoke<ProjectTodo[]>("save_project_todos", { projectId, todos });
}

async function syncProjectTodos(
  projectId: string,
  scanComments: boolean,
): Promise<TodoSyncResult> {
  return invoke<TodoSyncResult>("sync_project_todos", { projectId, scanComments });
}

async function todoGitActivity(
  projectId: string,
  number: number,
): Promise<TodoGitActivity> {
  return invoke<TodoGitActivity>("todo_git_activity", { projectId, number });
}

async function listProjectResources(projectId: string): Promise<string[]> {
  return invoke<string[]>("list_project_resources", { projectId });
}

async function openTodoLink(
  projectId: string,
  path: string,
  line?: number,
): Promise<void> {
  await invoke<void>("open_todo_link", { projectId, path, line: line ?? null });
}
