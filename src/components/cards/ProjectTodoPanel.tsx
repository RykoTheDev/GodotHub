import { useEffect, useMemo, useRef, useState } from "react";
import { IconCheckCircle } from "../../lib/icons";

import { Trans, useTranslation } from "react-i18next";

import { useSettings } from "../../hooks/useSettings";
import { useProjectTodos } from "../../hooks/useProjectTodos";

import { formatDate, type LastOpenedDateFormat } from "../../lib/lastOpened";
import { ProjectTodoModal } from "./ProjectTodoModal";
import { ProjectTodoDetailsModal } from "./ProjectTodoDetailsModal";
import { ProjectTodoList } from "./ProjectTodoList";
import { ProjectTodoListModal } from "./ProjectTodoListModal";
import { ConfirmDialog } from "../modals/ConfirmDialog";

import type { ProjectTodo, TodoStatus } from "../../types/projectTodo";

// const mockTodos: ProjectTodo[] = [
//   {
//     id: "1",
//     title: "Adicionar ícone do projeto",
//     status: "done",
//     area: "art",
//     dueDate: "2026-08-20",
//     createdAt: "2026-08-15",
//   },
//   {
//     id: "2",
//     title: "Revisar traduções",
//     status: "done",
//     area: "other",
//     dueDate: "2026-08-23",
//     createdAt: "2026-08-16",
//   },
//   {
//     id: "3",
//     title: "Criar menu principal",
//     area: "programming",
//     status: "in_progress",
//     dueDate: "2026-08-29",
//     description: "Implementar o menu principal do jogo com transições suaves.",
//     createdAt: "2026-08-18",
//   },
//   {
//     id: "4",
//     title: "Melhorar interface do launcher",
//     area: "design",
//     status: "paused",
//     dueDate: "2026-09-02",
//     createdAt: "2026-08-20",
//   },
//   {
//     id: "5",
//     title: "Testar configurações de exportação fela da puta",
//     area: "other",
//     status: "todo",
//     createdAt: "2026-08-21",
//   },
// ];

type ProjectTodoPanelProps = {
  projectId: string;
  onLoaded: () => void;
  onClose: () => void;
};

type StatusSort = "completed-first" | "todo-first" | null;

type DueDateSort = "nearest-first" | "farthest-first" | null;

const statusOrder = {
  todo: 0,
  paused: 1,
  in_progress: 2,
  done: 3,
} satisfies Record<TodoStatus, number>;

function sortProjectTodos(
  todos: ProjectTodo[],
  statusSort: StatusSort,
  dueDateSort: DueDateSort,
) {
  if (!statusSort && !dueDateSort) {
    return todos;
  }

  return todos
    .map((todo, index) => ({ todo, index }))
    .sort((a, b) => {
      if (dueDateSort) {
        const aDate = a.todo.dueDate;
        const bDate = b.todo.dueDate;

        if (!aDate && !bDate) {
          return a.index - b.index;
        }

        if (!aDate) return 1;
        if (!bDate) return -1;

        const dateDifference = aDate.localeCompare(bDate);

        if (dateDifference !== 0) {
          return dueDateSort === "nearest-first"
            ? dateDifference
            : -dateDifference;
        }

        return a.index - b.index;
      }

      if (statusSort) {
        const direction = statusSort === "completed-first" ? -1 : 1;

        const statusDifference =
          (statusOrder[a.todo.status] - statusOrder[b.todo.status]) * direction;

        if (statusDifference !== 0) {
          return statusDifference;
        }
      }

      return a.index - b.index;
    })
    .map(({ todo }) => todo);
}

function haveSameTodoOrder(first: ProjectTodo[], second: ProjectTodo[]) {
  return (
    first.length === second.length &&
    first.every((todo, index) => todo.id === second[index]?.id)
  );
}

function getTodayValue() {
  const today = new Date();

  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, "0");
  const day = String(today.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

function formatDueDate(
  dueDate: string | undefined,
  today: string,
  dateFormat: LastOpenedDateFormat,
  locale: string,
) {
  if (!dueDate) return "—";

  const millisecondsPerDay = 86_400_000;
  const differenceInDays = Math.round(
    (new Date(`${dueDate}T00:00:00Z`).getTime() -
      new Date(`${today}T00:00:00Z`).getTime()) /
      millisecondsPerDay,
  );

  if (differenceInDays >= -1 && differenceInDays <= 1) {
    const relativeDate = new Intl.RelativeTimeFormat(locale, {
      numeric: "auto",
    }).format(differenceInDays, "day");

    return relativeDate.replace(/^./u, (character) =>
      character.toLocaleUpperCase(locale),
    );
  }

  const date = new Date(`${dueDate}T00:00:00`);

  if (dueDate.slice(0, 4) !== today.slice(0, 4)) {
    return formatDate(date, dateFormat);
  }

  return new Intl.DateTimeFormat(locale, {
    day: "numeric",
    month: "short",
  }).format(date);
}

export function ProjectTodoPanel({
  projectId,
  onLoaded,
  onClose,
}: ProjectTodoPanelProps) {
  const { settings } = useSettings();
  const { t, i18n } = useTranslation(["todos", "common"]);
  const locale = i18n.resolvedLanguage ?? i18n.language;
  const statusConfig = {
    todo: {
      label: t("status_todo"),
      className: "bg-raised text-ink border border-outline/40",
      dotClassName: "bg-muted",
    },
    paused: {
      label: t("status_paused"),
      className: "bg-amber/20 text-ink border border-amber/30",
      dotClassName: "bg-amber",
    },
    in_progress: {
      label: t("status_in_progress"),
      className: "bg-accent/15 text-ink border border-accent/30",
      dotClassName: "bg-accent",
    },
    done: {
      label: t("status_done"),
      className: "bg-mint/15 text-ink border border-mint/30",
      dotClassName: "bg-mint",
    },
  } satisfies Record<
    TodoStatus,
    { label: string; className: string; dotClassName: string }
  >;
  const formatTodoDueDate = (dueDate: string | undefined, todayValue: string) =>
    formatDueDate(
      dueDate,
      todayValue,
      settings.last_opened_date_format,
      locale,
    );

  const {
    todos,
    loaded,
    loading,
    error,
    saving,
    saveError,
    refresh,
    saveTodos,
    retrySave,
  } = useProjectTodos(projectId);

  useEffect(() => {
    if (loaded) {
      onLoaded();
    }
  }, [loaded, onLoaded]);
  const [statusSort, setStatusSort] = useState<StatusSort>(null);
  const [dueDateSort, setDueDateSort] = useState<DueDateSort>("nearest-first");

  const addTodo = (todo: ProjectTodo): Promise<boolean> => {
    const nextTodos = [...todos, todo];

    return saveTodos(nextTodos, false);
  };

  const updateTodo = async (
    updatedTodo: ProjectTodo,
    rememberFailure = true,
  ): Promise<boolean> => {
    const nextTodos = todos.map((todo) =>
      todo.id === updatedTodo.id ? updatedTodo : todo,
    );

    return saveTodos(nextTodos, rememberFailure);
  };

  const setTodoStatus = (todo: ProjectTodo, status: TodoStatus) => {
    previousStatusRef.current.delete(todo.id);

    updateTodo({
      ...todo,
      status,
    });
  };

  const toggleTodoCompleted = (todo: ProjectTodo) => {
    if (todo.status === "done") {
      const previousStatus = previousStatusRef.current.get(todo.id) ?? "todo";

      previousStatusRef.current.delete(todo.id);

      updateTodo({
        ...todo,
        status: previousStatus,
      });

      return;
    }

    previousStatusRef.current.set(todo.id, todo.status);

    updateTodo({
      ...todo,
      status: "done",
    });
  };

  const [isCreating, setIsCreating] = useState(false);
  const [viewingTodo, setViewingTodo] = useState<ProjectTodo | null>(null);
  const [editingTodo, setEditingTodo] = useState<ProjectTodo | null>(null);
  const [showAllTodos, setShowAllTodos] = useState(false);
  const [deletingTodo, setDeletingTodo] = useState<ProjectTodo | null>(null);

  const previousStatusRef = useRef<Map<string, TodoStatus>>(new Map());
  const pendingCount = todos.filter((todo) => todo.status !== "done").length;

  const sortedTodos = useMemo(
    () => sortProjectTodos(todos, statusSort, dueDateSort),
    [todos, statusSort, dueDateSort],
  );

  const compactTodos = sortedTodos
    .filter((todo) => todo.status !== "done")
    .slice(0, 5);

  const fullTodos = useMemo(
    () => [
      ...sortedTodos.filter((todo) => todo.status !== "done"),
      ...todos.filter((todo) => todo.status === "done"),
    ],
    [sortedTodos, todos],
  );

  const toggleStatusSort = () => {
    const preferredDirection =
      statusSort === "completed-first" ? "todo-first" : "completed-first";

    const oppositeDirection =
      preferredDirection === "completed-first"
        ? "todo-first"
        : "completed-first";

    const preferredOrder = sortProjectTodos(todos, preferredDirection, null);

    const oppositeOrder = sortProjectTodos(todos, oppositeDirection, null);

    const nextDirection =
      haveSameTodoOrder(preferredOrder, sortedTodos) &&
      !haveSameTodoOrder(oppositeOrder, sortedTodos)
        ? oppositeDirection
        : preferredDirection;

    setDueDateSort(null);
    setStatusSort(nextDirection);
  };

  const toggleDueDateSort = () => {
    const preferredDirection =
      dueDateSort === "nearest-first" ? "farthest-first" : "nearest-first";

    const oppositeDirection =
      preferredDirection === "nearest-first"
        ? "farthest-first"
        : "nearest-first";

    const preferredOrder = sortProjectTodos(todos, null, preferredDirection);

    const oppositeOrder = sortProjectTodos(todos, null, oppositeDirection);

    const nextDirection =
      haveSameTodoOrder(preferredOrder, sortedTodos) &&
      !haveSameTodoOrder(oppositeOrder, sortedTodos)
        ? oppositeDirection
        : preferredDirection;

    setStatusSort(null);
    setDueDateSort(nextDirection);
  };

  const today = getTodayValue();

  const viewingTodoOverdue = viewingTodo
    ? !!viewingTodo.dueDate &&
      viewingTodo.dueDate < today &&
      viewingTodo.status !== "done"
    : false;

  return (
    <div className="rounded-b-item border-x border-b border-outline/50 bg-overlay">
      <div className="flex items-center justify-between px-3.5 py-2.5">
        <div className="flex items-center gap-2">
          <span className="text-[11px] font-semibold uppercase tracking-wide text-muted">
            {t("next_steps")}
          </span>
        </div>

        <span className="flex h-3 w-3 shrink-0 items-center justify-center">
          {saving && (
            <span
              aria-label={t("saving_tasks")}
              className="h-3 w-3 animate-spin rounded-full border-2 border-accent-dim/30 border-t-accent-bright"
            />
          )}
        </span>
        <div className="flex items-center gap-3">
          <span className="text-[10px] font-mono text-muted">
            {t("pending_count", { count: pendingCount })}
          </span>

          <button
            type="button"
            disabled={saving}
            onClick={() => setIsCreating(true)}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 rounded-btn border border-accent/30 bg-accent/10 px-2.5 py-1.5 text-[10px] font-medium text-accent-bright transition-colors hover:border-accent/50 hover:bg-accent/20 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:border-accent/30 disabled:hover:bg-accent/10"
          >
            <span className="text-xs font-semibold">+</span>
            {t("new_task")}
          </button>

          <button
            type="button"
            onClick={onClose}
            aria-label={t("hide_next_steps")}
            className="text-muted cursor-pointer"
          >
            ⌃
          </button>
        </div>
      </div>

      {saveError && (
        <div
          role="alert"
          title={saveError}
          className="mx-3.5 mb-2 flex items-center justify-between gap-3 rounded-item border border-danger/30 bg-danger/5 px-3 py-2 text-[11px] text-danger"
        >
          <span>{t("save_changes_failed")}</span>

          <button
            type="button"
            onClick={() => void retrySave()}
            disabled={saving}
            className="focus-ring shrink-0 cursor-pointer rounded-btn border border-danger/30 px-2.5 py-1 transition-colors hover:bg-danger/10 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {t("try_again", { ns: "common" })}
          </button>
        </div>
      )}

      {/* Tarefas */}
      {loading ? (
        <div className="mx-3.5 mb-2 flex items-center justify-center rounded-item border border-outline/50 px-4 py-10">
          <span className="text-[11px] text-muted">{t("loading_tasks")}</span>
        </div>
      ) : error ? (
        <div
          className="mx-3.5 mb-2 flex flex-col items-center justify-center rounded-item border border-danger/30 bg-danger/5 px-4 py-10 text-center"
          title={error}
        >
          <p className="text-sm font-medium text-danger">
            {t("load_tasks_failed")}
          </p>

          <p className="mt-1 text-[11px] text-muted">{t("data_unchanged")}</p>

          <button
            type="button"
            onClick={() => void refresh()}
            className="focus-ring mt-4 cursor-pointer rounded-btn border border-outline/50 px-3 py-1.5 text-[11px] text-muted transition-colors hover:bg-raised hover:text-ink"
          >
            {t("try_again", { ns: "common" })}
          </button>
        </div>
      ) : todos.length === 0 ? (
        <div className="mx-3.5 mb-2 flex flex-col items-center justify-center rounded-item border border-outline/50 px-4 py-10 text-center">
          <span className="mb-3 flex h-9 w-9 items-center justify-center rounded-full bg-accent/10 text-accent-bright">
            <IconCheckCircle aria-hidden="true" className="h-4 w-4" />
          </span>

          <p className="text-sm font-medium text-ink">{t("empty_title")}</p>

          <p className="mt-1 text-[11px] text-muted">
            {t("empty_description")}
          </p>

          <button
            type="button"
            disabled={saving}
            onClick={() => setIsCreating(true)}
            className="focus-ring mt-4 inline-flex cursor-pointer items-center gap-1.5 rounded-btn border border-accent/30 bg-accent/10 px-3 py-1.5 text-[11px] font-medium text-accent-bright transition-colors hover:border-accent/50 hover:bg-accent/20"
          >
            <span className="text-xs font-semibold">+</span>
            {t("create_task")}
          </button>
        </div>
      ) : (
        <>
          {pendingCount === 0 ? (
            <div className="mx-3.5 mb-2 flex flex-col items-center justify-center rounded-item border border-outline/50 px-4 py-10 text-center">
              <span className="mb-3 flex h-9 w-9 items-center justify-center rounded-full bg-mint/10 text-mint">
                <IconCheckCircle aria-hidden="true" className="h-4 w-4" />
              </span>

              <p className="text-sm font-medium text-ink">
                {t("all_completed_title")}
              </p>

              <p className="mt-1 text-[11px] text-muted">
                {t("all_completed_description")}
              </p>
            </div>
          ) : (
            <ProjectTodoList
              todos={compactTodos}
              today={today}
              disabled={saving}
              statusSort={statusSort}
              dueDateSort={dueDateSort}
              statusConfig={statusConfig}
              className="mx-3.5 mb-2"
              formatDueDate={formatTodoDueDate}
              onToggleStatusSort={toggleStatusSort}
              onToggleDueDateSort={toggleDueDateSort}
              onToggleCompleted={toggleTodoCompleted}
              onSetStatus={setTodoStatus}
              onUpdate={updateTodo}
              onView={setViewingTodo}
              onEdit={setEditingTodo}
              onDelete={setDeletingTodo}
            />
          )}
          {/* Rodapé */}
          <div className="flex items-center justify-between px-3.5 pb-2.5">
            <span className="text-[10px] text-muted">{t("footer_hint")}</span>

            <button
              type="button"
              className="focus-ring cursor-pointer rounded-btn border border-outline/50 px-2.5 py-1.5 text-[10px] text-muted transition-colors hover:border-accent-dim hover:bg-raised hover:text-ink"
              onClick={() => setShowAllTodos(true)}
            >
              {t("view_all")}
            </button>
          </div>
        </>
      )}
      {showAllTodos &&
        !viewingTodo &&
        !isCreating &&
        !editingTodo &&
        !deletingTodo && (
          <ProjectTodoListModal
            totalCount={todos.length}
            pendingCount={pendingCount}
            createDisabled={saving}
            onCreate={() => setIsCreating(true)}
            onClose={() => setShowAllTodos(false)}
          >
            <ProjectTodoList
              todos={fullTodos}
              today={today}
              disabled={saving}
              statusSort={statusSort}
              dueDateSort={dueDateSort}
              statusConfig={statusConfig}
              showArea
              formatDueDate={formatTodoDueDate}
              onToggleStatusSort={toggleStatusSort}
              onToggleDueDateSort={toggleDueDateSort}
              onToggleCompleted={toggleTodoCompleted}
              onSetStatus={setTodoStatus}
              onUpdate={updateTodo}
              onView={setViewingTodo}
              onEdit={setEditingTodo}
              onDelete={setDeletingTodo}
            />
          </ProjectTodoListModal>
        )}
      {viewingTodo && (
        <ProjectTodoDetailsModal
          todo={viewingTodo}
          statusLabel={statusConfig[viewingTodo.status].label}
          statusClassName={statusConfig[viewingTodo.status].className}
          overdue={viewingTodoOverdue}
          onClose={() => setViewingTodo(null)}
        />
      )}
      {isCreating && (
        <ProjectTodoModal
          onClose={() => setIsCreating(false)}
          onSubmit={addTodo}
        />
      )}

      {editingTodo && (
        <ProjectTodoModal
          todo={editingTodo}
          onClose={() => setEditingTodo(null)}
          onSubmit={(todo) => updateTodo(todo, false)}
        />
      )}

      {deletingTodo && (
        <ConfirmDialog
          title={t("delete_task_title")}
          description={
            <Trans
              i18nKey="delete_task_description"
              ns="todos"
              values={{ title: deletingTodo.title }}
              components={{ strong: <strong /> }}
            />
          }
          confirmLabel={t("delete", { ns: "common" })}
          variant="danger"
          onConfirm={async () => {
            const nextTodos = todos.filter(
              (todo) => todo.id !== deletingTodo.id,
            );

            await saveTodos(nextTodos);

            setDeletingTodo(null);
          }}
          onCancel={() => setDeletingTodo(null)}
        />
      )}
    </div>
  );
}
