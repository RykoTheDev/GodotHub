import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";
import { ModalHeader } from "../modals/ModalHeader";
import { IconCheckCircle, IconPencil } from "../../lib/icons";

import type {
  ProjectTodo,
  TodoArea,
  TodoStatus,
} from "../../types/projectTodo";
import { DatePicker } from "../ui/DatePicker";

type ProjectTodoModalProps = {
  onClose: () => void;
  onSubmit: (todo: ProjectTodo) => Promise<boolean>;
  todo?: ProjectTodo;
};

export function ProjectTodoModal({
  onClose,
  onSubmit,
  todo,
}: ProjectTodoModalProps) {
  const editing = !!todo;
  const { t, i18n } = useTranslation(["todos", "common"]);
  const locale = i18n.resolvedLanguage ?? i18n.language;

  const areaOptions: Array<{
    value: TodoArea;
    label: string;
  }> = [
    { value: "programming", label: t("area_programming") },
    { value: "art", label: t("area_art") },
    { value: "audio", label: t("area_audio") },
    { value: "design", label: t("area_design") },
    { value: "narrative", label: t("area_narrative") },
    { value: "other", label: t("area_other") },
  ];

  const [title, setTitle] = useState(todo?.title ?? "");
  const [description, setDescription] = useState(todo?.description ?? "");
  const [dueDate, setDueDate] = useState(todo?.dueDate ?? "");
  const [status, setStatus] = useState<TodoStatus>(todo?.status ?? "todo");
  const [area, setArea] = useState<TodoArea>(todo?.area ?? "other");

  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState(false);

  const trimmedTitle = title.trim();

  const hasChanges =
    !editing ||
    trimmedTitle !== todo.title ||
    description.trim() !== (todo.description ?? "") ||
    dueDate !== (todo.dueDate ?? "") ||
    status !== todo.status ||
    area !== (todo.area ?? "other");

  const canSubmit = trimmedTitle.length > 0 && hasChanges && !submitting;

  const submit = async () => {
    if (!canSubmit) return;

    const savedTodo: ProjectTodo = {
      id: todo?.id ?? crypto.randomUUID(),
      title: trimmedTitle,
      status,
      area,
      description: description.trim() || undefined,
      dueDate: dueDate || undefined,
      createdAt: todo?.createdAt ?? new Date().toISOString(),
    };

    setSubmitting(true);
    setSubmitError(false);

    const saved = await onSubmit(savedTodo);

    setSubmitting(false);

    if (saved) {
      onClose();
    } else {
      setSubmitError(true);
    }
  };

  useEffect(() => {
    const handler = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keydown", handler);

    return () => {
      window.removeEventListener("keydown", handler);
    };
  }, [onClose]);

  useEffect(() => {
    window.dispatchEvent(new CustomEvent("app:dialog-open"));

    return () => {
      window.dispatchEvent(new CustomEvent("app:dialog-close"));
    };
  }, []);

  const optionButtonClass = (active: boolean) =>
    `focus-ring cursor-pointer px-3 py-2 rounded-btn border text-xs font-medium transition-colors ${
      active
        ? "border-accent bg-accent/10 text-accent-bright"
        : "border-outline/50 text-muted hover:border-accent-dim hover:text-ink hover:bg-raised"
    }`;

  // const canSubmit = title.trim().length > 0;

  return createPortal(
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        role="dialog"
        aria-modal="true"
        initial={{ opacity: 0, y: 14, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: "spring", stiffness: 380, damping: 30 }}
        className="bg-surface rounded-modal w-full max-w-lg max-h-[88vh] flex flex-col shadow-2xl overflow-clip"
        onClick={(event) => event.stopPropagation()}
      >
        <ModalHeader
          icon={
            editing ? (
              <IconPencil className="w-5 h-5 text-accent-bright" />
            ) : (
              <IconCheckCircle className="w-5 h-5 text-accent-bright" />
            )
          }
          title={editing ? t("edit_task") : t("new_task")}
          description={
            editing ? t("edit_task_description") : t("new_task_description")
          }
          onClose={onClose}
          autoFocusBanner={false}
        />

        <div className="p-6 pt-4 flex flex-col gap-4 overflow-y-auto">
          {/* Título */}
          <div className="flex flex-col gap-0.5">
            <label className="pl-3 text-xs font-medium text-muted">
              {t("title")}
            </label>

            <input
              type="text"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              placeholder={t("title_placeholder")}
              className="focus-ring bg-overlay border border-outline/50 focus:border-accent-dim rounded-item px-3.5 py-2.5 text-sm font-mono text-ink placeholder:text-muted/70 transition-colors"
            />
          </div>

          {/* Área */}
          <div className="flex flex-col gap-2">
            <label className="pl-3 text-xs font-medium text-muted">
              {t("area")}
            </label>

            <div className="flex flex-wrap gap-1.5">
              {areaOptions.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => setArea(option.value)}
                  className={optionButtonClass(area === option.value)}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {/* Status */}
          <div className="flex flex-col gap-2">
            <label className="pl-3 text-xs font-medium text-muted">
              {t("status")}
            </label>

            <div className="flex flex-wrap gap-1.5">
              <button
                type="button"
                onClick={() => setStatus("todo")}
                className={optionButtonClass(status === "todo")}
              >
                {t("status_todo")}
              </button>

              <button
                type="button"
                onClick={() => setStatus("paused")}
                className={optionButtonClass(status === "paused")}
              >
                {t("status_paused")}
              </button>

              <button
                type="button"
                onClick={() => setStatus("in_progress")}
                className={optionButtonClass(status === "in_progress")}
              >
                {t("status_in_progress")}
              </button>
              <button
                type="button"
                onClick={() => setStatus("done")}
                className={optionButtonClass(status === "done")}
              >
                {t("status_done")}
              </button>
            </div>
          </div>

          {/* Descrição */}
          <div className="flex flex-col gap-0.5">
            <label className="pl-3 text-xs font-medium text-muted">
              {t("description")}{" "}
              <span className="font-normal text-muted/60">{t("optional")}</span>
            </label>

            <textarea
              rows={4}
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              placeholder={t("description_placeholder")}
              className="focus-ring bg-overlay border border-outline/50 focus:border-accent-dim rounded-item px-3.5 py-2.5 text-sm text-ink placeholder:text-muted/70 transition-colors resize-none"
            />
          </div>

          {/* Prazo */}
          <div className="flex flex-col gap-0.5">
            <label className="pl-3 text-xs font-medium text-muted">
              {t("due_date")}{" "}
              <span className="font-normal text-muted/60">{t("optional")}</span>
            </label>

            <DatePicker
              value={dueDate}
              locale={locale}
              onChange={setDueDate}
              placeholder={t("no_due_date")}
              clearLabel={t("remove_due_date")}
              markPastDates
              pastDateMessage={t("past_due_date")}
            />
          </div>
        </div>

        {submitError && (
          <div
            role="alert"
            className="mx-6 rounded-item border border-danger/30 bg-danger/5 px-3 py-2 text-[11px] text-danger"
          >
            {t("save_task_failed")}
          </div>
        )}

        {/* Rodapé */}
        <div className="flex justify-end gap-2 p-5 pt-2">
          <motion.button
            type="button"
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm text-muted hover:text-ink transition-colors"
          >
            {t("cancel", { ns: "common" })}
          </motion.button>

          <motion.button
            type="button"
            whileHover={canSubmit ? { y: -1 } : undefined}
            whileTap={canSubmit ? { scale: 0.96 } : undefined}
            onClick={submit}
            disabled={!canSubmit}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn bg-accent text-white text-sm font-medium disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {submitting
              ? t("saving", { ns: "common" })
              : editing
                ? t("save_changes", { ns: "common" })
                : t("add_task")}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>,
    document.body,
  );
}
