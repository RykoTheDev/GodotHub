import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { api } from "../lib/api";
import {
  clearOpenTodos,
  localDateValue,
  refreshOpenTodos,
  useOpenTodos,
} from "../lib/openTodos";

const NOTIFIED_KEY = "godothub_todo_due_notified";
const RECHECK_MS = 60 * 60 * 1000;

type NotifiedState = { date: string; ids: string[] };

function readNotified(today: string): NotifiedState {
  try {
    const parsed = JSON.parse(localStorage.getItem(NOTIFIED_KEY) ?? "null");

    if (parsed && parsed.date === today && Array.isArray(parsed.ids)) {
      return { date: today, ids: parsed.ids.filter((id: unknown) => typeof id === "string") };
    }
  } catch {}

  return { date: today, ids: [] };
}

function writeNotified(state: NotifiedState) {
  try {
    localStorage.setItem(NOTIFIED_KEY, JSON.stringify(state));
  } catch {}
}

export function useOpenTodosSync(enabled: boolean, projectsKey: string) {
  useEffect(() => {
    if (!enabled) {
      clearOpenTodos();

      return;
    }

    void refreshOpenTodos();

    const handleChange = () => void refreshOpenTodos();

    window.addEventListener("app:todos-changed", handleChange);

    return () => window.removeEventListener("app:todos-changed", handleChange);
  }, [enabled, projectsKey]);
}

export function useTodoDueNotifications(enabled: boolean) {
  const { t } = useTranslation("todos");
  const { todos, loaded } = useOpenTodos();

  useEffect(() => {
    if (!enabled || !loaded) return;

    const check = () => {
      const today = localDateValue();
      const notified = readNotified(today);
      const due = todos.filter(
        (open) =>
          open.todo.dueDate &&
          open.todo.dueDate <= today &&
          !notified.ids.includes(`${open.projectId}:${open.todo.id}`),
      );

      if (due.length === 0) return;

      const [first] = due;
      const title =
        due.length === 1
          ? t("due_notification_title_one", { title: first.todo.title })
          : t("due_notification_title_other", { count: due.length });
      const body =
        due.length === 1
          ? first.projectName
          : [
              ...due.slice(0, 3).map((open) => `${open.todo.title} (${open.projectName})`),
              ...(due.length > 3 ? [t("due_notification_more", { count: due.length - 3 })] : []),
            ].join("\n");

      writeNotified({
        date: today,
        ids: [...notified.ids, ...due.map((open) => `${open.projectId}:${open.todo.id}`)],
      });
      api.notify(title, body).catch(() => {});
    };

    check();

    const timer = window.setInterval(check, RECHECK_MS);

    return () => window.clearInterval(timer);
  }, [enabled, loaded, todos, t]);
}
