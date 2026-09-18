import { DatePicker } from "../ui/DatePicker";
import { Dropdown } from "../ui/Dropdown";
import { IconMore, IconPencil, IconTrash } from "../../lib/icons";
import { useTranslation } from "react-i18next";

import type {
  ProjectTodo,
  TodoArea,
  TodoStatus,
} from "../../types/projectTodo";

type StatusSort = "completed-first" | "todo-first" | null;
type DueDateSort = "nearest-first" | "farthest-first" | null;

type StatusConfig = Record<
  TodoStatus,
  {
    label: string;
    className: string;
    dotClassName: string;
  }
>;

type ProjectTodoListProps = {
  todos: ProjectTodo[];
  today: string;
  statusSort: StatusSort;
  dueDateSort: DueDateSort;
  statusConfig: StatusConfig;
  showArea?: boolean;
  className?: string;
  disabled?: boolean;
  formatDueDate: (dueDate: string | undefined, today: string) => string;
  onToggleStatusSort: () => void;
  onToggleDueDateSort: () => void;
  onToggleCompleted: (todo: ProjectTodo) => void;
  onSetStatus: (todo: ProjectTodo, status: TodoStatus) => void;
  onUpdate: (todo: ProjectTodo) => void;
  onView: (todo: ProjectTodo) => void;
  onEdit: (todo: ProjectTodo) => void;
  onDelete: (todo: ProjectTodo) => void;
};

export function ProjectTodoList({
  todos,
  today,
  statusSort,
  dueDateSort,
  statusConfig,
  showArea = false,
  className = "",
  disabled = false,
  formatDueDate,
  onToggleStatusSort,
  onToggleDueDateSort,
  onToggleCompleted,
  onSetStatus,
  onUpdate,
  onView,
  onEdit,
  onDelete,
}: ProjectTodoListProps) {
  const { t, i18n } = useTranslation(["todos", "common"]);
  const locale = i18n.resolvedLanguage ?? i18n.language;
  const areaLabels = {
    programming: t("area_programming"),
    art: t("area_art"),
    audio: t("area_audio"),
    design: t("area_design"),
    narrative: t("area_narrative"),
    other: t("area_other"),
  } satisfies Record<TodoArea, string>;
  const statusHeader = (
    <button
      type="button"
      onClick={onToggleStatusSort}
      className={`focus-ring cursor-pointer rounded-btn text-center text-[9px] font-medium uppercase tracking-wide text-muted/60 transition-colors hover:bg-raised hover:text-ink ${
        showArea ? "w-28" : "min-w-[88px]"
      }`}
      title={t("sort_by_status")}
    >
      {t("status")}{" "}
      {statusSort === "completed-first"
        ? "↓"
        : statusSort === "todo-first"
          ? "↑"
          : ""}
    </button>
  );

  const dueDateHeader = (
    <button
      type="button"
      onClick={onToggleDueDateSort}
      className={`focus-ring cursor-pointer rounded-btn text-[9px] font-medium uppercase tracking-wide text-muted/60 transition-colors hover:bg-raised hover:text-ink ${
        showArea ? "w-28 text-center" : "w-24 text-center"
      }`}
      title={t("sort_by_due_date")}
    >
      {t("due_date")}{" "}
      {dueDateSort === "nearest-first"
        ? "↑"
        : dueDateSort === "farthest-first"
          ? "↓"
          : ""}
    </button>
  );

  return (
    <div
      className={`overflow-hidden rounded-item border border-outline/50 ${
        showArea ? "min-w-[640px]" : ""
      } ${className}`}
    >
      <div className="flex items-center gap-3 border-b border-outline/40 px-3 py-3">
        <span className="w-3.5 shrink-0" />

        <span className="min-w-0 flex-1 text-[9px] font-medium uppercase tracking-wide text-muted/60">
          {t("task")}
        </span>

        {showArea && (
          <span className="w-28 shrink-0 text-center text-[9px] font-medium uppercase tracking-wide text-muted/60">
            {t("area")}
          </span>
        )}

        <div className="flex shrink-0 items-center gap-2">
          {showArea ? (
            <>
              {dueDateHeader}
              {statusHeader}
            </>
          ) : (
            <>
              {statusHeader}
              {dueDateHeader}
            </>
          )}

          <span className="w-6 shrink-0" />
        </div>
      </div>

      {todos.map((todo, index) => {
        const status = statusConfig[todo.status];
        const completed = todo.status === "done";
        const overdue = !!todo.dueDate && todo.dueDate < today && !completed;

        const statusControl = (
          <Dropdown
            align="right"
            compact
            activeItemClassName="bg-raised text-ink hover:bg-raised"
            menuClassName="!min-w-40!"
            trigger={({ open, toggle }) => (
              <button
                type="button"
                disabled={disabled}
                onClick={toggle}
                aria-label={t("change_status", { status: status.label })}
                aria-expanded={open}
                className={`focus-ring shrink-0 cursor-pointer rounded-tag border px-2 py-1 text-center text-[10px] transition-all hover:brightness-95 disabled:cursor-not-allowed disabled:opacity-50 ${status.className} ${
                  showArea ? "w-28" : "min-w-[88px]"
                } ${open ? "ring-1 ring-accent/40" : ""}`}
              >
                {status.label}
              </button>
            )}
            items={[
              {
                key: "todo",
                label: t("status_todo"),
                leading: (
                  <span
                    aria-hidden="true"
                    className={`mr-1 block h-2 w-2 rounded-full ${statusConfig.todo.dotClassName}`}
                  />
                ),
                shortcut: todo.status === "todo" ? "✓" : undefined,
                active: todo.status === "todo",
                onClick: () => onSetStatus(todo, "todo"),
              },
              {
                key: "paused",
                label: t("status_paused"),
                leading: (
                  <span
                    aria-hidden="true"
                    className={`mr-1 block h-2 w-2 rounded-full ${statusConfig.paused.dotClassName}`}
                  />
                ),
                shortcut: todo.status === "paused" ? "✓" : undefined,
                active: todo.status === "paused",
                onClick: () => onSetStatus(todo, "paused"),
              },
              {
                key: "in-progress",
                label: t("status_in_progress"),
                leading: (
                  <span
                    aria-hidden="true"
                    className={`mr-1 block h-2 w-2 rounded-full ${statusConfig.in_progress.dotClassName}`}
                  />
                ),
                shortcut: todo.status === "in_progress" ? "✓" : undefined,
                active: todo.status === "in_progress",
                onClick: () => onSetStatus(todo, "in_progress"),
              },
              {
                key: "done",
                label: t("status_done"),
                leading: (
                  <span
                    aria-hidden="true"
                    className={`mr-1 block h-2 w-2 rounded-full ${statusConfig.done.dotClassName}`}
                  />
                ),
                shortcut: todo.status === "done" ? "✓" : undefined,
                active: todo.status === "done",
                onClick: () => onSetStatus(todo, "done"),
              },
            ]}
          />
        );

        const dueDateControl = completed ? (
          <span
            aria-hidden="true"
            className={`shrink-0 ${showArea ? "w-28" : "w-24"}`}
          />
        ) : (
          <div
            className={
              showArea
                ? "w-28 shrink-0 [&>div]:w-full [&_button]:w-full [&_button]:text-center"
                : "w-24 shrink-0 [&>div]:w-full [&_button]:w-full [&_button]:text-center"
            }
          >
            <DatePicker
              value={todo.dueDate ?? ""}
              locale={locale}
              clearLabel={t("remove_due_date")}
              disabled={disabled}
              onChange={(dueDate) =>
                onUpdate({
                  ...todo,
                  dueDate: dueDate || undefined,
                })
              }
              compact
              markPastDates
              displayValue={
                <span
                  className={overdue ? "font-medium text-danger" : "text-muted"}
                  title={overdue ? t("overdue") : undefined}
                >
                  {formatDueDate(todo.dueDate, today)}
                </span>
              }
            />
          </div>
        );

        return (
          <div
            key={todo.id}
            className={`flex items-center gap-3 px-3 py-2 ${
              index < todos.length - 1 ? "border-b border-outline/40" : ""
            }`}
          >
            <button
              type="button"
              disabled={disabled}
              onClick={() => onToggleCompleted(todo)}
              aria-label={
                completed ? t("mark_not_completed") : t("mark_completed")
              }
              className="focus-ring flex h-5 w-5 shrink-0 cursor-pointer items-center justify-center rounded-btn disabled:cursor-not-allowed disabled:opacity-50"
            >
              {completed ? (
                <span className="text-mint">✓</span>
              ) : (
                <span className="h-3.5 w-3.5 rounded border border-outline transition-colors hover:border-mint" />
              )}
            </button>

            <button
              type="button"
              onClick={() => onView(todo)}
              title={todo.title}
              aria-label={t("view_task_details", { title: todo.title })}
              className={`focus-ring min-w-0 flex-1 cursor-pointer truncate rounded-btn text-left text-[11px] transition-colors ${
                completed
                  ? "text-muted line-through hover:text-ink"
                  : "text-ink hover:text-accent-bright"
              }`}
            >
              {todo.title}
            </button>

            {showArea && (
              <span className="w-28 shrink-0 text-center">
                <span className="inline-flex w-full justify-center truncate rounded-tag border border-outline/50 bg-raised px-2 py-1 text-[10px] font-medium text-ink">
                  {areaLabels[todo.area ?? "other"]}
                </span>
              </span>
            )}

            <div className="flex shrink-0 items-center gap-2">
              {showArea ? (
                <>
                  {dueDateControl}
                  {statusControl}
                </>
              ) : (
                <>
                  {statusControl}
                  {dueDateControl}
                </>
              )}

              <Dropdown
                align="right"
                compact
                trigger={({ open, toggle }) => (
                  <button
                    type="button"
                    disabled={disabled}
                    aria-label={t("task_actions")}
                    aria-expanded={open}
                    onClick={toggle}
                    className={`focus-ring flex h-6 w-6 shrink-0 cursor-pointer items-center justify-center rounded-btn transition-colors disabled:cursor-not-allowed disabled:opacity-50 ${
                      open
                        ? "bg-raised text-ink"
                        : "text-muted hover:bg-raised hover:text-ink"
                    }`}
                  >
                    <IconMore className="h-3.5 w-3.5" />
                  </button>
                )}
                items={[
                  {
                    key: "edit",
                    label: t("edit"),
                    icon: IconPencil,
                    onClick: () => onEdit(todo),
                    dividerAfter: true,
                  },
                  {
                    key: "delete",
                    label: t("delete", { ns: "common" }),
                    icon: IconTrash,
                    danger: true,
                    onClick: () => onDelete(todo),
                  },
                ]}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}
