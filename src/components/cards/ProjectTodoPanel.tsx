import { useEffect, useMemo, useRef, useState } from "react";
import { IconCheckCircle, IconCode } from "../../lib/icons";
import { pushToast } from "../../lib/toast";
import { projectTodosApi } from "../../api/projectTodos";
import { rankOf } from "../../lib/openTodos";

import { Trans, useTranslation } from "react-i18next";

import { useSettings } from "../../hooks/useSettings";
import { useProjectTodos } from "../../hooks/useProjectTodos";

import { formatDate, type LastOpenedDateFormat } from "../../lib/lastOpened";
import { ProjectTodoModal } from "./ProjectTodoModal";
import { ProjectTodoDetailsModal } from "./ProjectTodoDetailsModal";
import { ProjectTodoList } from "./ProjectTodoList";
import { ProjectTodoListModal } from "./ProjectTodoListModal";
import { ConfirmDialog } from "../modals/ConfirmDialog";

import type { ProjectTodo, TodoArea, TodoStatus } from "../../types/projectTodo";

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

        if (aDate && bDate) {
          const dateDifference = aDate.localeCompare(bDate);

          if (dateDifference !== 0) {
            return dueDateSort === "nearest-first"
              ? dateDifference
              : -dateDifference;
          }
        } else if (aDate) {
          return -1;
        } else if (bDate) {
          return 1;
        }
      }

      if (statusSort) {
        const direction = statusSort === "completed-first" ? -1 : 1;

        const statusDifference =
          (statusOrder[a.todo.status] - statusOrder[b.todo.status]) * direction;

        if (statusDifference !== 0) {
          return statusDifference;
        }
      }

      const priorityDifference = rankOf(a.todo.priority) - rankOf(b.todo.priority);

      if (priorityDifference !== 0) {
        return priorityDifference;
      }

      return a.index - b.index;
    })
    .map(({ todo }) => todo);
}

function matchesSearch(todo: ProjectTodo, query: string) {
  if (!query) return true;

  return [
    todo.title,
    todo.description ?? "",
    todo.link?.path ?? "",
    todo.number !== undefined ? `#todo-${todo.number}` : "",
    ...(todo.checklist ?? []).map((item) => item.text),
  ]
    .join("\n")
    .toLowerCase()
    .includes(query);
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
  if (!dueDate) return "-";

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
    sync,
  } = useProjectTodos(projectId);

  const [scanning, setScanning] = useState(false);
  const autoSyncedRef = useRef<string | null>(null);

  useEffect(() => {
    if (!loaded || error || autoSyncedRef.current === projectId) return;

    autoSyncedRef.current = projectId;

    sync(false)
      .then((result) => {
        if (result.closedByCommits > 0) {
          pushToast("success", t("commit_closed", { count: result.closedByCommits }));
        }
      })
      .catch(() => {});
  }, [loaded, error, projectId, sync, t]);

  const scanCode = async () => {
    setScanning(true);

    try {
      const result = await sync(true);
      const changed = result.imported + result.closed + result.reopened;

      pushToast(
        "success",
        changed === 0
          ? t("comment_scan_none")
          : t("comment_scan_summary", {
              imported: result.imported,
              closed: result.closed,
              reopened: result.reopened,
            }),
      );

      if (result.closedByCommits > 0) {
        pushToast("success", t("commit_closed", { count: result.closedByCommits }));
      }
    } catch (scanError) {
      pushToast("error", String(scanError));
    } finally {
      setScanning(false);
    }
  };

  const openLink = (todo: ProjectTodo) => {
    if (!todo.link) return;

    projectTodosApi
      .openLink(projectId, todo.link.path, todo.link.line)
      .catch((openError) => pushToast("error", String(openError)));
  };

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
      ...todos
        .filter((todo) => todo.status === "done")
        .sort((a, b) => (b.completedAt ?? "").localeCompare(a.completedAt ?? "")),
    ],
    [sortedTodos, todos],
  );

  const toggleStatusSort = () => {
    setDueDateSort(null);
    setStatusSort(
      statusSort === null
        ? "todo-first"
        : statusSort === "todo-first"
          ? "completed-first"
          : null,
    );
  };

  const toggleDueDateSort = () => {
    setStatusSort(null);
    setDueDateSort(
      dueDateSort === null
        ? "nearest-first"
        : dueDateSort === "nearest-first"
          ? "farthest-first"
          : null,
    );
  };

  const manualOrder = !statusSort && !dueDateSort;

  const reorderTodos = (activeId: string, overId: string) => {
    const from = todos.findIndex((todo) => todo.id === activeId);
    const to = todos.findIndex((todo) => todo.id === overId);

    if (from < 0 || to < 0 || from === to) return;

    const nextTodos = [...todos];
    const [moved] = nextTodos.splice(from, 1);

    nextTodos.splice(to, 0, moved);
    void saveTodos(nextTodos);
  };

  const [quickTitle, setQuickTitle] = useState("");

  const quickAdd = async () => {
    const title = quickTitle.trim();

    if (!title || saving) return;

    const added = await addTodo({
      id: crypto.randomUUID(),
      title,
      status: "todo",
      area: "other",
      createdAt: new Date().toISOString(),
    });

    if (added) {
      setQuickTitle("");
    } else {
      pushToast("error", t("save_task_failed"));
    }
  };

  const [search, setSearch] = useState("");
  const [areaFilter, setAreaFilter] = useState<TodoArea | "all">("all");
  const searchQuery = search.trim().toLowerCase();

  const visibleAllTodos = fullTodos.filter(
    (todo) =>
      (areaFilter === "all" || (todo.area ?? "other") === areaFilter) &&
      matchesSearch(todo, searchQuery),
  );

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
            disabled={saving || scanning || !loaded || !!error}
            onClick={() => void scanCode()}
            title={t("scan_code_hint")}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 rounded-btn border border-outline/50 px-2.5 py-1.5 text-[10px] font-medium text-muted transition-colors hover:border-accent-dim hover:bg-raised hover:text-ink disabled:cursor-not-allowed disabled:opacity-50"
          >
            <IconCode className={`h-3 w-3 ${scanning ? "animate-pulse" : ""}`} />
            {scanning ? t("scanning") : t("scan_code")}
          </button>

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

      {loaded && !error && (
        <form
          onSubmit={(event) => {
            event.preventDefault();
            void quickAdd();
          }}
          className="mx-3.5 mb-2"
        >
          <input
            type="text"
            value={quickTitle}
            disabled={saving}
            onChange={(event) => setQuickTitle(event.target.value)}
            placeholder={t("quick_add_placeholder")}
            aria-label={t("quick_add_placeholder")}
            className="focus-ring w-full rounded-item border border-dashed border-outline/60 bg-base/40 px-3 py-2 text-[11px] text-ink placeholder:text-muted/60 transition-colors focus:border-solid focus:border-accent-dim disabled:opacity-50"
          />
        </form>
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
              onOpenLink={openLink}
              reorderable={manualOrder && !saving}
              onReorder={reorderTodos}
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
            search={search}
            onSearchChange={setSearch}
            areaFilter={areaFilter}
            onAreaFilterChange={setAreaFilter}
          >
            {visibleAllTodos.length === 0 ? (
              <p className="py-10 text-center text-[11px] text-muted">
                {t("no_matching_tasks")}
              </p>
            ) : (
            <ProjectTodoList
              todos={visibleAllTodos}
              today={today}
              disabled={saving}
              statusSort={statusSort}
              dueDateSort={dueDateSort}
              statusConfig={statusConfig}
              showArea
              formatDueDate={formatTodoDueDate}
              onOpenLink={openLink}
              reorderable={manualOrder && !saving}
              onReorder={reorderTodos}
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
          </ProjectTodoListModal>
        )}
      {viewingTodo && (
        <ProjectTodoDetailsModal
          projectId={projectId}
          todo={todos.find((todo) => todo.id === viewingTodo.id) ?? viewingTodo}
          statusLabel={statusConfig[viewingTodo.status].label}
          statusClassName={statusConfig[viewingTodo.status].className}
          overdue={viewingTodoOverdue}
          onOpenLink={openLink}
          onUpdate={(todo) => void updateTodo(todo)}
          onClose={() => setViewingTodo(null)}
        />
      )}
      {isCreating && (
        <ProjectTodoModal
          projectId={projectId}
          onClose={() => setIsCreating(false)}
          onSubmit={addTodo}
        />
      )}

      {editingTodo && (
        <ProjectTodoModal
          projectId={projectId}
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
