import { useUiMotion } from '../../hooks/useUiMotion'
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";

import { IconCheckCircle, IconExternalLink, IconGitBranch } from "../../lib/icons";
import { projectTodosApi } from "../../api/projectTodos";
import type {
  ProjectTodo,
  TodoArea,
  TodoGitActivity,
} from "../../types/projectTodo";

import { ModalHeader } from "../modals/ModalHeader";

type ProjectTodoDetailsModalProps = {
  projectId: string;
  todo: ProjectTodo;
  statusLabel: string;
  statusClassName: string;
  overdue: boolean;
  onOpenLink: (todo: ProjectTodo) => void;
  onClose: () => void;
};

function toLocalDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);

  return new Date(year, month - 1, day);
}

export function ProjectTodoDetailsModal({
  projectId,
  todo,
  statusLabel,
  statusClassName,
  overdue,
  onOpenLink,
  onClose,
}: ProjectTodoDetailsModalProps) {
  const uiMotion = useUiMotion()

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
  function formatDueDateContext(dueDate: string, overdue: boolean) {
    const date = toLocalDate(dueDate);
    const today = new Date();
    const millisecondsPerDay = 86_400_000;

    const differenceInDays = Math.round(
      (Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) -
        Date.UTC(today.getFullYear(), today.getMonth(), today.getDate())) /
        millisecondsPerDay,
    );

    if (differenceInDays === 0) {
      return t("time_today");
    }

    if (differenceInDays === 1) {
      return t("tomorrow");
    }

    if (differenceInDays > 1) {
      return t("due_in_days", { count: differenceInDays });
    }

    if (overdue && differenceInDays === -1) {
      return t("overdue_yesterday");
    }

    if (overdue) {
      return t("overdue_days", {
        count: Math.abs(differenceInDays),
      });
    }

    return null;
  }
  const fullDueDateLabel = todo.dueDate
    ? new Intl.DateTimeFormat(locale, {
        day: "numeric",
        month: "long",
        year: "numeric",
      }).format(toLocalDate(todo.dueDate))
    : t("no_due_date");

  const dueDateContextLabel = todo.dueDate
    ? formatDueDateContext(todo.dueDate, overdue)
    : null;

  const reference = todo.number !== undefined ? `#todo-${todo.number}` : null;
  const linkLabel = todo.link
    ? todo.link.line
      ? `${todo.link.path}:${todo.link.line}`
      : todo.link.path
    : null;
  const closure = todo.status === "done" ? todo.closedBy : undefined;

  const [activity, setActivity] = useState<TodoGitActivity | null>(null);
  const [activityLoading, setActivityLoading] = useState(false);

  useEffect(() => {
    if (todo.number === undefined) return;

    let cancelled = false;

    setActivityLoading(true);
    projectTodosApi
      .activity(projectId, todo.number)
      .then((result) => {
        if (!cancelled) setActivity(result);
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setActivityLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [projectId, todo.number]);
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [onClose]);

  useEffect(() => {
    window.dispatchEvent(new CustomEvent("app:dialog-open"));

    return () => {
      window.dispatchEvent(new CustomEvent("app:dialog-close"));
    };
  }, []);

  return createPortal(
    <motion.div
      {...uiMotion.surface('modal', `none`)}

      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <motion.div
        role="dialog"
        aria-modal="true"
        {...uiMotion.surface('modal', `scale(0.96)`)}

        className="flex h-[min(720px,88vh)] w-full max-w-lg flex-col overflow-clip rounded-modal bg-surface shadow-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <ModalHeader
          icon={<IconCheckCircle className="h-5 w-5 text-accent-bright" />}
          title={todo.title}
          titleClassName="line-clamp-2 leading-tight"
          description={t("task_details")}
          onClose={onClose}
          autoFocusBanner={false}
        />

        <div className="min-h-0 flex-1 overflow-y-auto p-6 pt-4 flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <span className="ps-3 text-xs font-medium text-muted">
              {t("area")}
            </span>

            <span className="w-fit rounded-tag border border-outline/50 bg-raised px-3 py-1.5 text-xs font-medium text-ink">
              {areaLabels[todo.area ?? "other"]}
            </span>
          </div>

          <div className="flex flex-col gap-1.5">
            <span className="ps-3 text-xs font-medium text-muted">
              {t("status")}
            </span>

            <span
              className={`w-fit rounded-tag px-3 py-1.5 text-xs font-medium ${statusClassName}`}
            >
              {statusLabel}
            </span>

            {closure && (
              <p className="ps-3 text-xs text-muted">
                {closure.kind === "commit"
                  ? t("closed_by_commit", {
                      hash: closure.commit?.slice(0, 7) ?? "",
                      subject: closure.subject ?? "",
                    })
                  : t("closed_by_comment_removed")}
              </p>
            )}
          </div>

          {linkLabel && todo.link && (
            <div className="flex flex-col gap-1.5">
              <span className="ps-3 text-xs font-medium text-muted">
                {t("linked_file")}
              </span>

              <div className="flex items-center gap-3 rounded-item border border-outline/50 bg-overlay px-3.5 py-2.5">
                <div className="min-w-0 flex-1">
                  <p
                    dir="ltr"
                    className="truncate font-mono text-xs text-ink"
                    title={linkLabel}
                  >
                    {linkLabel}
                  </p>
                  {todo.source && (
                    <p className="mt-0.5 text-xs text-muted">
                      {t("source_comment", { tag: todo.source.tag })}
                    </p>
                  )}
                </div>

                <button
                  type="button"
                  onClick={() => onOpenLink(todo)}
                  className="focus-ring inline-flex shrink-0 cursor-pointer items-center gap-1.5 rounded-btn border border-outline/50 px-2.5 py-1.5 text-[11px] font-medium text-muted transition-colors hover:border-accent-dim hover:bg-raised hover:text-ink"
                >
                  <IconExternalLink className="h-3 w-3" />
                  {t("open_file")}
                </button>
              </div>
            </div>
          )}

          <div className="flex flex-col gap-1.5">
            <span className="ps-3 text-xs font-medium text-muted">
              {t("project_template_desc_label")}
            </span>

            <div className="min-h-20 whitespace-pre-wrap break-words rounded-item border border-outline/50 bg-overlay px-3.5 py-2.5 text-sm text-ink">
              {todo.description || (
                <span className="text-muted">{t("no_description")}</span>
              )}
            </div>
          </div>

          <div className="flex flex-col gap-1.5">
            <span className="ps-3 text-xs font-medium text-muted">
              {t("due_date")}
            </span>

            <div
              className={`rounded-item border border-outline/50 bg-overlay px-3.5 py-2.5 ${
                !todo.dueDate
                  ? "text-muted"
                  : overdue
                    ? "text-danger"
                    : "text-ink"
              }`}
            >
              <div className="text-sm font-medium">
                {overdue}
                {fullDueDateLabel}
              </div>

              {dueDateContextLabel && (
                <div
                  className={`mt-1 text-xs ${
                    overdue ? "text-danger/80" : "text-muted"
                  }`}
                >
                  {dueDateContextLabel}
                </div>
              )}
            </div>
          </div>

          {reference && (
            <div className="flex flex-col gap-1.5">
              <span className="ps-3 text-xs font-medium text-muted">
                {t("todo_reference")}
              </span>

              <div className="flex flex-col gap-2 rounded-item border border-outline/50 bg-overlay px-3.5 py-2.5">
                <div className="flex flex-wrap items-center gap-2">
                  <code
                    dir="ltr"
                    className="rounded-tag border border-outline/50 bg-raised px-2 py-0.5 font-mono text-xs text-ink"
                  >
                    {reference}
                  </code>
                  <span className="text-xs text-muted">
                    {t("todo_reference_hint", { ref: reference })}
                  </span>
                </div>

                {activityLoading && !activity ? (
                  <p className="text-xs text-muted">{t("git_activity_loading")}</p>
                ) : activity && activity.isRepo ? (
                  activity.branches.length === 0 && activity.commits.length === 0 ? (
                    <p className="text-xs text-muted">
                      {t("git_activity_empty", { ref: reference })}
                    </p>
                  ) : (
                    <div className="flex flex-col gap-2 border-t border-outline/40 pt-2">
                      {activity.branches.length > 0 && (
                        <div className="flex flex-wrap items-center gap-1.5">
                          <IconGitBranch
                            aria-label={t("git_branches")}
                            className="h-3 w-3 text-muted"
                          />
                          {activity.branches.map((branch) => (
                            <span
                              key={branch}
                              dir="ltr"
                              className={`rounded-tag border px-2 py-0.5 font-mono text-[10px] ${
                                branch === activity.currentBranch
                                  ? "border-accent/40 bg-accent/10 text-accent-bright"
                                  : "border-outline/50 bg-raised text-ink"
                              }`}
                            >
                              {branch}
                            </span>
                          ))}
                        </div>
                      )}

                      {activity.commits.map((commit) => (
                        <div key={commit.hash} className="flex items-center gap-2 text-xs">
                          <code dir="ltr" className="shrink-0 font-mono text-muted">
                            {commit.shortHash}
                          </code>
                          <span
                            className="min-w-0 flex-1 truncate text-ink"
                            title={`${commit.subject} · ${commit.author}`}
                          >
                            {commit.subject}
                          </span>
                          {commit.closes && (
                            <span className="shrink-0 rounded-tag border border-mint/30 bg-mint/15 px-1.5 py-0.5 text-[10px] text-mint">
                              {t("git_commit_closes")}
                            </span>
                          )}
                        </div>
                      ))}
                    </div>
                  )
                ) : null}
              </div>
            </div>
          )}
        </div>

        <div className="flex justify-end p-5 pt-2">
          <motion.button
            type="button"

            data-press-feedback
            onClick={onClose}
            className="focus-ring cursor-pointer rounded-btn border border-outline/50 px-4 py-2.5 text-sm text-muted transition-colors hover:border-accent-dim hover:bg-raised hover:text-ink"
          >
            {t("close", { ns: "common" })}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>,
    document.body,
  );
}
