import { useSyncExternalStore } from "react";
import { projectTodosApi } from "../api/projectTodos";
import type { OpenTodo, TodoPriority } from "../types/projectTodo";

type OpenTodosSnapshot = {
  todos: OpenTodo[];
  loaded: boolean;
};

let snapshot: OpenTodosSnapshot = { todos: [], loaded: false };
const listeners = new Set<() => void>();
let inflight: Promise<void> | null = null;
let rerun = false;
let pendingFocusProjectId: string | null = null;

function emit() {
  listeners.forEach((listener) => listener());
}

function subscribe(listener: () => void) {
  listeners.add(listener);

  return () => {
    listeners.delete(listener);
  };
}

export function refreshOpenTodos(): Promise<void> {
  if (inflight) {
    rerun = true;

    return inflight;
  }

  inflight = projectTodosApi
    .open()
    .then((todos) => {
      snapshot = { todos, loaded: true };
      emit();
    })
    .catch(() => {})
    .finally(() => {
      inflight = null;

      if (rerun) {
        rerun = false;
        void refreshOpenTodos();
      }
    });

  return inflight;
}

export function clearOpenTodos() {
  snapshot = { todos: [], loaded: false };
  emit();
}

export function useOpenTodos(): OpenTodosSnapshot {
  return useSyncExternalStore(subscribe, () => snapshot, () => snapshot);
}

type TodoCounts = { open: number; overdue: number };

const NO_TODOS: TodoCounts = { open: 0, overdue: 0 };
let countsCache: {
  snapshot: OpenTodosSnapshot;
  today: string;
  byProject: Map<string, TodoCounts>;
} | null = null;

function todoCountsFor(projectId: string, today: string): TodoCounts {
  if (!countsCache || countsCache.snapshot !== snapshot || countsCache.today !== today) {
    const previous = countsCache?.byProject;
    const byProject = new Map<string, TodoCounts>();
    for (const open of snapshot.todos) {
      const counts = byProject.get(open.projectId) ?? { open: 0, overdue: 0 };
      counts.open += 1;
      if (open.todo.dueDate && open.todo.dueDate < today) counts.overdue += 1;
      byProject.set(open.projectId, counts);
    }
    for (const [id, counts] of byProject) {
      const prior = previous?.get(id);
      if (prior && prior.open === counts.open && prior.overdue === counts.overdue) {
        byProject.set(id, prior);
      }
    }
    countsCache = { snapshot, today, byProject };
  }
  return countsCache.byProject.get(projectId) ?? NO_TODOS;
}

export function useProjectTodoCounts(projectId: string | null, today: string): TodoCounts {
  const read = () => (projectId ? todoCountsFor(projectId, today) : NO_TODOS);
  return useSyncExternalStore(subscribe, read, read);
}

export function notifyTodosChanged() {
  window.dispatchEvent(new Event("app:todos-changed"));
}

export function requestTodoFocus(projectId: string) {
  pendingFocusProjectId = projectId;
  window.dispatchEvent(new CustomEvent("app:show-project-todos", { detail: projectId }));
}

export function consumeTodoFocus(projectId: string): boolean {
  if (pendingFocusProjectId !== projectId) return false;

  pendingFocusProjectId = null;

  return true;
}

export function localDateValue(date: Date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

export function addDaysValue(value: string, days: number): string {
  const [year, month, day] = value.split("-").map(Number);

  return localDateValue(new Date(year, month - 1, day + days));
}

export function daysBetween(from: string, to: string): number {
  const [fy, fm, fd] = from.split("-").map(Number);
  const [ty, tm, td] = to.split("-").map(Number);

  return Math.round((Date.UTC(ty, tm - 1, td) - Date.UTC(fy, fm - 1, fd)) / 86_400_000);
}

export const priorityRank: Record<TodoPriority | "none", number> = {
  high: 0,
  medium: 1,
  none: 2,
  low: 3,
};

export function rankOf(priority: TodoPriority | undefined): number {
  return priorityRank[priority ?? "none"];
}
