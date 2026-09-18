import { invoke } from "@tauri-apps/api/core";
import type { ProjectTodo } from "../types/projectTodo";

export const projectTodosApi = {
  list: listProjectTodos,
  save: saveProjectTodos,
}

async function listProjectTodos(projectId: string): Promise<ProjectTodo[]> {
  const projectTodos = await invoke<ProjectTodo[]>("list_project_todos", {projectId});

  return projectTodos;
}

async function saveProjectTodos(
  projectId: string,
  todos: ProjectTodo[],
): Promise<void> {
  await invoke<void>("save_project_todos", { projectId, todos });
}