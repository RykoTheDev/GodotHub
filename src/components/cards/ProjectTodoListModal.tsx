import { useEffect, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";

import { IconCheckCircle } from "../../lib/icons";
import { ModalHeader } from "../modals/ModalHeader";

type ProjectTodoListModalProps = {
  totalCount: number;
  pendingCount: number;
  createDisabled?: boolean;
  onCreate: () => void;
  onClose: () => void;
  children: ReactNode;
};

export function ProjectTodoListModal({
  totalCount,
  pendingCount,
  createDisabled = false,
  onCreate,
  onClose,
  children,
}: ProjectTodoListModalProps) {
  const completedCount = totalCount - pendingCount;
  const { t } = useTranslation("todos");

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
        className="flex h-[min(760px,90vh)] w-full max-w-6xl flex-col overflow-clip rounded-modal bg-surface shadow-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <ModalHeader
          icon={<IconCheckCircle className="h-5 w-5 text-accent-bright" />}
          title={t("next_steps")}
          description={t("all_tasks_description")}
          onClose={onClose}
          autoFocusBanner={false}
        />

        <div className="flex min-h-0 flex-1 flex-col p-6 pt-4">
          <div className="mb-4 flex shrink-0 items-center justify-between gap-4">
            <span className="text-[11px] font-mono text-muted">
              {t("pending_count", { count: pendingCount })}
              <span className="mx-2 text-muted/40">•</span>
              {t("completed_count", { count: completedCount })}
            </span>

            <button
              type="button"
              disabled={createDisabled}
              onClick={onCreate}
              className="focus-ring inline-flex cursor-pointer items-center gap-1.5 rounded-btn border border-accent/30 bg-accent/10 px-3 py-1.5 text-[11px] font-medium text-accent-bright transition-colors hover:border-accent/50 hover:bg-accent/20 disabled:cursor-not-allowed disabled:opacity-50"
            >
              <span className="text-xs font-semibold">+</span>
              {t("new_task")}
            </button>
          </div>

          <div className="min-h-0 flex-1 overflow-auto pr-1">{children}</div>
        </div>
      </motion.div>
    </motion.div>,
    document.body,
  );
}
