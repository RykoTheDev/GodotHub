import { useEffect, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { useTranslation } from "react-i18next";

import { IconCheckCircle, IconChevronDown } from "../../lib/icons";
import { isPopupOpen } from "../../lib/openPopups";
import { ModalHeader } from "../modals/ModalHeader";
import { Dropdown } from "../ui/Dropdown";
import type { TodoArea } from "../../types/projectTodo";
import { useBackdropDismiss } from "../../hooks/useBackdropDismiss";

const AREAS: TodoArea[] = ["programming", "art", "audio", "design", "narrative", "other"];

type ProjectTodoListModalProps = {
  totalCount: number;
  pendingCount: number;
  createDisabled?: boolean;
  onCreate: () => void;
  onClose: () => void;
  search: string;
  onSearchChange: (value: string) => void;
  areaFilter: TodoArea | "all";
  onAreaFilterChange: (value: TodoArea | "all") => void;
  children: ReactNode;
};

export function ProjectTodoListModal({
  totalCount,
  pendingCount,
  createDisabled = false,
  onCreate,
  onClose,
  search,
  onSearchChange,
  areaFilter,
  onAreaFilterChange,
  children,
}: ProjectTodoListModalProps) {

  const completedCount = totalCount - pendingCount;
  const { t } = useTranslation("todos");

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape" && !isPopupOpen()) {
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

  const backdrop = useBackdropDismiss(onClose);

  return createPortal(
    <div


      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4"
      {...backdrop}
    >
      <div
        role="dialog"
        aria-modal="true"


        className="flex h-[min(760px,90vh)] w-full max-w-6xl flex-col overflow-clip rounded-modal bg-surface shadow-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <ModalHeader
          icon={<IconCheckCircle className="h-5 w-5 text-accent-bright" />}
          title={t("next_steps")}
          onClose={onClose}
          autoFocusBanner={false}
        />

        <div className="flex min-h-0 flex-1 flex-col p-6 pt-4">
          <div className="mb-4 flex shrink-0 items-center justify-between gap-4">
            <span className="text-2xs font-mono text-muted">
              {t("pending_count", { count: pendingCount })}
              <span className="mx-2 text-muted/40">•</span>
              {t("completed_count", { count: completedCount })}
            </span>

            <div className="flex min-w-0 flex-1 items-center justify-end gap-2">
              <input
                type="search"
                value={search}
                onChange={(event) => onSearchChange(event.target.value)}
                placeholder={t("search_tasks_placeholder")}
                aria-label={t("search_tasks_placeholder")}
                className="focus-ring w-full max-w-64 rounded-btn border border-outline/50 bg-overlay px-3 py-1.5 text-2xs text-ink placeholder:text-muted/60 focus:border-accent-dim"
              />

              <Dropdown
                align="right"
                compact
                trigger={({ open, toggle }) => (
                  <button
                    type="button"
                    onClick={toggle}
                    aria-expanded={open}
                    className="focus-ring inline-flex shrink-0 cursor-pointer items-center gap-1.5 rounded-btn border border-outline/50 bg-overlay px-3 py-1.5 text-2xs font-medium text-ink hover:border-accent-dim"
                  >
                    {areaFilter === "all" ? t("all_areas") : t(`area_${areaFilter}`)}
                    <IconChevronDown className="h-3 w-3 text-muted" />
                  </button>
                )}
                items={[
                  {
                    key: "all",
                    label: t("all_areas"),
                    active: areaFilter === "all",
                    onClick: () => onAreaFilterChange("all"),
                  },
                  ...AREAS.map((area) => ({
                    key: area,
                    label: t(`area_${area}`),
                    active: areaFilter === area,
                    onClick: () => onAreaFilterChange(area),
                  })),
                ]}
              />
            </div>

            <button
              type="button"
              disabled={createDisabled}
              onClick={onCreate}
              className="focus-ring inline-flex cursor-pointer items-center gap-1.5 rounded-btn border border-accent/30 bg-accent/10 px-3 py-1.5 text-2xs font-medium text-accent-bright hover:border-accent/50 hover:bg-accent/20 disabled:cursor-not-allowed disabled:opacity-50"
            >
              <span className="text-xs font-semibold">+</span>
              {t("new_task")}
            </button>
          </div>

          <div className="min-h-0 flex-1 overflow-auto pe-1">{children}</div>
        </div>
      </div>
    </div>,
    document.body,
  );
}
