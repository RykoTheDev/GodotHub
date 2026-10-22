import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import {
  addDaysValue,
  daysBetween,
  localDateValue,
  rankOf,
  requestTodoFocus,
  useOpenTodos,
} from "../../lib/openTodos";
import type { OpenTodo } from "../../types/projectTodo";

const PRIORITY_DOT = {
  high: "bg-danger",
  medium: "bg-amber",
  low: "bg-muted/40",
} as const;

export function TodoDueTile({ tall = false }: { tall?: boolean }) {
  const { t } = useTranslation(["todos", "common"]);
  const { todos, loaded } = useOpenTodos();
  const today = localDateValue();
  const weekEnd = addDaysValue(today, 6);

  const { overdue, soon } = useMemo(() => {
    const dated = todos.filter((open) => open.todo.dueDate);
    const byDate = (a: OpenTodo, b: OpenTodo) =>
      (a.todo.dueDate ?? "").localeCompare(b.todo.dueDate ?? "") ||
      rankOf(a.todo.priority) - rankOf(b.todo.priority);

    return {
      overdue: dated.filter((open) => open.todo.dueDate! < today).sort(byDate),
      soon: dated
        .filter((open) => open.todo.dueDate! >= today && open.todo.dueDate! <= weekEnd)
        .sort(byDate),
    };
  }, [todos, today, weekEnd]);

  const rows = [...overdue, ...soon].slice(0, tall ? 10 : 5);
  const hidden = overdue.length + soon.length - rows.length;

  const dueLabel = (dueDate: string) => {
    const diff = daysBetween(today, dueDate);

    if (diff < 0) return t("overdue_days", { count: -diff });
    if (diff === 0) return t("time_today");
    if (diff === 1) return t("tomorrow");

    return t("due_in_days", { count: diff });
  };

  if (!loaded) {
    return <div className="h-16 rounded-item bg-overlay border border-outline/50 animate-pulse" />;
  }

  if (rows.length === 0) {
    return (
      <div className="flex items-center justify-center rounded-item bg-overlay border border-outline/50 px-4 py-6 text-xs text-muted">
        {t("tile_empty")}
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-2">
      <p className="text-[11px] text-muted">
        {t("tile_summary", { overdue: overdue.length, soon: soon.length })}
      </p>
      <div className="flex flex-col gap-1.5">
        {rows.map((open) => {
          const isOverdue = open.todo.dueDate! < today;

          return (
            <button
              key={`${open.projectId}:${open.todo.id}`}
              type="button"
              onClick={() => requestTodoFocus(open.projectId)}
              className="focus-ring cursor-pointer flex items-center gap-3 rounded-item bg-overlay border border-outline/50 px-3 py-2 text-start transition-colors hover:bg-raised hover:border-accent-dim/60"
            >
              {open.todo.priority && (
                <span
                  aria-label={t(`priority_${open.todo.priority}`)}
                  className={`h-1.5 w-1.5 shrink-0 rounded-full ${PRIORITY_DOT[open.todo.priority]}`}
                />
              )}
              <span className="min-w-0 flex-1">
                <span className="block truncate text-sm text-ink">{open.todo.title}</span>
                <span className="block truncate text-[11px] text-muted/70">{open.projectName}</span>
              </span>
              <span
                className={`shrink-0 text-[11px] tabular-nums ${
                  isOverdue ? "font-medium text-danger" : "text-muted"
                }`}
              >
                {dueLabel(open.todo.dueDate!)}
              </span>
            </button>
          );
        })}
      </div>
      {hidden > 0 && (
        <p className="text-[10px] text-muted/70">{t("due_notification_more", { count: hidden })}</p>
      )}
    </div>
  );
}
