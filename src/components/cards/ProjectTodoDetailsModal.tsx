import { useEffect } from "react";
import { createPortal } from "react-dom";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";

import { IconCheckCircle } from "../../lib/icons";
import type { ProjectTodo, TodoArea } from "../../types/projectTodo";

import { ModalHeader } from "../modals/ModalHeader";

type ProjectTodoDetailsModalProps = {
  todo: ProjectTodo;
  statusLabel: string;
  statusClassName: string;
  overdue: boolean;
  onClose: () => void;
};

function toLocalDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);

  return new Date(year, month - 1, day);
}

export function ProjectTodoDetailsModal({
  todo,
  statusLabel,
  statusClassName,
  overdue,
  onClose,
}: ProjectTodoDetailsModalProps) {
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
      return t("today");
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
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <motion.div
        role="dialog"
        aria-modal="true"
        initial={{ opacity: 0, y: 14, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: "spring", stiffness: 380, damping: 30 }}
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
            <span className="pl-3 text-xs font-medium text-muted">
              {t("area")}
            </span>

            <span className="w-fit rounded-tag border border-outline/50 bg-raised px-3 py-1.5 text-xs font-medium text-ink">
              {areaLabels[todo.area ?? "other"]}
            </span>
          </div>

          <div className="flex flex-col gap-1.5">
            <span className="pl-3 text-xs font-medium text-muted">
              {t("status")}
            </span>

            <span
              className={`w-fit rounded-tag px-3 py-1.5 text-xs font-medium ${statusClassName}`}
            >
              {statusLabel}
            </span>
          </div>

          <div className="flex flex-col gap-1.5">
            <span className="pl-3 text-xs font-medium text-muted">
              {t("description")}
            </span>

            <div className="min-h-20 whitespace-pre-wrap break-words rounded-item border border-outline/50 bg-overlay px-3.5 py-2.5 text-sm text-ink">
              {todo.description || (
                <span className="text-muted">{t("no_description")}</span>
              )}
            </div>
          </div>

          <div className="flex flex-col gap-1.5">
            <span className="pl-3 text-xs font-medium text-muted">
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
        </div>

        <div className="flex justify-end p-5 pt-2">
          <motion.button
            type="button"
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
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
