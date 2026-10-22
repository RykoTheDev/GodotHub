import { DatePicker } from "../ui/DatePicker";
import { Dropdown } from "../ui/Dropdown";
import { IconCode, IconGrip, IconMore, IconPencil, IconTrash } from "../../lib/icons";
import { useTranslation } from "react-i18next";
import type { ReactNode } from "react";
import {
  DndContext,
  KeyboardSensor,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { localDateValue } from "../../lib/openTodos";

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

const PRIORITY_DOT = {
  high: "bg-danger",
  medium: "bg-amber",
  low: "bg-muted/40",
} as const;

function SortableRow({
  id,
  enabled,
  label,
  className,
  children,
}: {
  id: string;
  enabled: boolean;
  label: string;
  className: string;
  children: (grip: ReactNode) => ReactNode;
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    setActivatorNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id, disabled: !enabled });

  const grip = enabled ? (
    <button
      type="button"
      ref={setActivatorNodeRef}
      {...attributes}
      {...listeners}
      aria-label={label}
      className="focus-ring flex h-5 w-3.5 shrink-0 cursor-grab touch-none items-center justify-center rounded-btn text-muted/50 transition-colors hover:text-ink active:cursor-grabbing"
    >
      <IconGrip className="h-2.5 w-2.5" />
    </button>
  ) : null;

  return (
    <div
      ref={setNodeRef}
      style={{
        transform: CSS.Translate.toString(transform),
        transition,
        position: "relative",
        zIndex: isDragging ? 10 : undefined,
      }}
      className={`${className} ${isDragging ? "bg-raised shadow-md" : ""}`}
    >
      {children(grip)}
    </div>
  );
}

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
  onOpenLink?: (todo: ProjectTodo) => void;
  reorderable?: boolean;
  onReorder?: (activeId: string, overId: string) => void;
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
  onOpenLink,
  reorderable = false,
  onReorder,
}: ProjectTodoListProps) {
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 4 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;

    if (over && active.id !== over.id) {
      onReorder?.(String(active.id), String(over.id));
    }
  };

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
        {reorderable && <span className="w-3.5 shrink-0" />}
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

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
      <SortableContext
        items={todos.map((todo) => todo.id)}
        strategy={verticalListSortingStrategy}
      >
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
                className={`focus-ring shrink-0 cursor-pointer rounded-tag border px-2 py-1 text-center text-[10px] transition-[filter,background-color,color,border-color,box-shadow] hover:brightness-95 disabled:cursor-not-allowed disabled:opacity-50 ${status.className} ${
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
                    className={`me-1 block h-2 w-2 rounded-full ${statusConfig.todo.dotClassName}`}
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
                    className={`me-1 block h-2 w-2 rounded-full ${statusConfig.paused.dotClassName}`}
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
                    className={`me-1 block h-2 w-2 rounded-full ${statusConfig.in_progress.dotClassName}`}
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
                    className={`me-1 block h-2 w-2 rounded-full ${statusConfig.done.dotClassName}`}
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
            className={`shrink-0 truncate text-center text-[10px] text-mint/80 ${showArea ? "w-28" : "w-24"}`}
            title={todo.completedAt ? new Date(todo.completedAt).toLocaleString(locale) : undefined}
          >
            {todo.completedAt
              ? t("completed_on", {
                  date: formatDueDate(localDateValue(new Date(todo.completedAt)), today),
                })
              : ""}
          </span>
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
          <SortableRow
            key={todo.id}
            id={todo.id}
            enabled={reorderable}
            label={t("drag_to_reorder")}
            className={`flex items-center gap-3 px-3 py-2 ${
              index < todos.length - 1 ? "border-b border-outline/40" : ""
            }`}
          >
            {(grip) => (
          <>
            {grip}
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

            {todo.priority && (
              <span
                aria-label={t("priority_label", { priority: t(`priority_${todo.priority}`) })}
                title={t("priority_label", { priority: t(`priority_${todo.priority}`) })}
                className={`h-1.5 w-1.5 shrink-0 rounded-full ${PRIORITY_DOT[todo.priority]}`}
              />
            )}

            {todo.number !== undefined && (
              <span
                dir="ltr"
                className="shrink-0 font-mono text-[9px] text-muted/50"
              >
                #{todo.number}
              </span>
            )}

            <button
              type="button"
              onClick={() => onView(todo)}
              title={todo.title}
              aria-label={t("view_task_details", { title: todo.title })}
              className={`focus-ring min-w-0 flex-1 cursor-pointer truncate rounded-btn text-start text-[11px] transition-colors ${
                completed
                  ? "text-muted line-through hover:text-ink"
                  : "text-ink hover:text-accent-bright"
              }`}
            >
              {todo.title}
            </button>

            {todo.checklist && todo.checklist.length > 0 && (
              <span
                title={t("checklist_progress", {
                  done: todo.checklist.filter((item) => item.done).length,
                  total: todo.checklist.length,
                })}
                className="shrink-0 font-mono text-[9px] text-muted"
              >
                {todo.checklist.filter((item) => item.done).length}/{todo.checklist.length}
              </span>
            )}

            {todo.link && onOpenLink && (
              <button
                type="button"
                onClick={() => onOpenLink(todo)}
                title={t("open_linked_file", {
                  path: todo.link.line
                    ? `${todo.link.path}:${todo.link.line}`
                    : todo.link.path,
                })}
                aria-label={t("open_linked_file", { path: todo.link.path })}
                className="focus-ring flex h-5 w-5 shrink-0 cursor-pointer items-center justify-center rounded-btn text-muted transition-colors hover:bg-raised hover:text-accent-bright"
              >
                <IconCode className="h-3 w-3" />
              </button>
            )}

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
          </>
            )}
          </SortableRow>
        );
      })}
      </SortableContext>
      </DndContext>
    </div>
  );
}
