import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { createPortal } from "react-dom";

type DatePickerProps = {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  clearLabel?: string;
  locale?: string;
  markPastDates?: boolean;
  pastDateMessage?: string;
  compact?: boolean;
  displayValue?: ReactNode;
  disabled?: boolean;
};

type PopoverPosition = {
  top: number;
  left: number;
};

function toDate(value: string) {
  if (!value) return null;

  const [year, month, day] = value.split("-").map(Number);

  return new Date(year, month - 1, day);
}

function toValue(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

export function DatePicker({
  value,
  onChange,
  placeholder = "Selecionar data",
  clearLabel = "Remover data",
  locale = "pt-BR",
  markPastDates = false,
  pastDateMessage,
  compact = false,
  displayValue,
  disabled = false,
}: DatePickerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);

  const [open, setOpen] = useState(false);
  const [position, setPosition] = useState<PopoverPosition | null>(null);

  const selectedDate = toDate(value);

  const todayValue = toValue(new Date());

  const selectedIsPast = !!value && value < todayValue;

  const [viewDate, setViewDate] = useState(selectedDate ?? new Date());

  const formatValue = (dateValue: string) => {
    const date = toDate(dateValue);

    if (!date) return placeholder;

    return new Intl.DateTimeFormat(locale).format(date);
  };

  const monthFormatter = new Intl.DateTimeFormat(locale, {
    month: "long",
  });

  const weekdayFormatter = new Intl.DateTimeFormat(locale, {
    weekday: "short",
  });

  const weekDays = Array.from({ length: 7 }, (_, index) => {
    const date = new Date(2026, 0, 4 + index);

    return weekdayFormatter.format(date).replace(".", "").slice(0, 3);
  });

  const updatePosition = () => {
    const button = buttonRef.current;
    const popover = popoverRef.current;

    if (!button || !popover) return;

    const buttonRect = button.getBoundingClientRect();
    const popoverRect = popover.getBoundingClientRect();

    const gap = 8;
    const viewportPadding = 12;

    const spaceBelow = window.innerHeight - buttonRect.bottom - viewportPadding;

    const spaceAbove = buttonRect.top - viewportPadding;

    const openAbove =
      spaceBelow < popoverRect.height && spaceAbove > spaceBelow;

    let top = openAbove
      ? buttonRect.top - popoverRect.height - gap
      : buttonRect.bottom + gap;

    top = Math.max(
      viewportPadding,
      Math.min(top, window.innerHeight - popoverRect.height - viewportPadding),
    );

    let left = buttonRect.left;

    left = Math.max(
      viewportPadding,
      Math.min(left, window.innerWidth - popoverRect.width - viewportPadding),
    );

    setPosition({
      top,
      left,
    });
  };

  useLayoutEffect(() => {
    if (!open) {
      setPosition(null);
      return;
    }

    updatePosition();
  }, [open, viewDate, value]);

  useEffect(() => {
    if (!open) return;

    const handleOutsidePointerDown = (event: PointerEvent) => {
      const target = event.target as Node;

      const clickedTrigger = containerRef.current?.contains(target);

      const clickedPopover = popoverRef.current?.contains(target);

      if (clickedTrigger || clickedPopover) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();

      setOpen(false);
    };

    document.addEventListener("pointerdown", handleOutsidePointerDown, true);

    return () => {
      document.removeEventListener(
        "pointerdown",
        handleOutsidePointerDown,
        true,
      );
    };
  }, [open]);

  useEffect(() => {
    if (!open) return;

    const handlePositionChange = () => {
      updatePosition();
    };

    window.addEventListener("resize", handlePositionChange);

    document.addEventListener("scroll", handlePositionChange, true);

    return () => {
      window.removeEventListener("resize", handlePositionChange);

      document.removeEventListener("scroll", handlePositionChange, true);
    };
  }, [open]);

  const openPicker = () => {
    setViewDate(toDate(value) ?? new Date());
    setOpen(true);
  };

  const changeMonth = (offset: number) => {
    setViewDate(
      (current) =>
        new Date(current.getFullYear(), current.getMonth() + offset, 1),
    );
  };

  const year = viewDate.getFullYear();
  const month = viewDate.getMonth();

  const firstDay = new Date(year, month, 1);
  const startOffset = firstDay.getDay();

  const calendarStart = new Date(year, month, 1 - startOffset);

  const days = Array.from({ length: 42 }, (_, index) => {
    const date = new Date(calendarStart);

    date.setDate(calendarStart.getDate() + index);

    return date;
  });

  const selectDate = (date: Date) => {
    onChange(toValue(date));
    setOpen(false);
  };

  const clearDate = () => {
    onChange("");
    setOpen(false);
  };

  const calendar = open
    ? createPortal(
        <div
          ref={popoverRef}
          className="fixed z-[60] w-72 rounded-item border border-outline/50 bg-surface p-3 shadow-2xl"
          style={{
            top: position?.top ?? 0,
            left: position?.left ?? 0,
            visibility: position ? "visible" : "hidden",
          }}
        >
          <div className="mb-3 flex items-center justify-between">
            <button
              type="button"
              onClick={() => changeMonth(-1)}
              className="focus-ring cursor-pointer rounded-btn px-2 py-1 text-muted transition-colors hover:bg-raised hover:text-ink"
              aria-label="Mês anterior"
            >
              ‹
            </button>

            <div className="flex items-center gap-1 text-sm text-ink">
              <span className="capitalize">
                {monthFormatter.format(viewDate)}
              </span>

              <span className="text-muted">{year}</span>
            </div>

            <button
              type="button"
              onClick={() => changeMonth(1)}
              className="focus-ring cursor-pointer rounded-btn px-2 py-1 text-muted transition-colors hover:bg-raised hover:text-ink"
              aria-label="Próximo mês"
            >
              ›
            </button>
          </div>

          <div className="mb-1 grid grid-cols-7">
            {weekDays.map((day) => (
              <span
                key={day}
                className="py-1 text-center text-[10px] text-muted"
              >
                {day}
              </span>
            ))}
          </div>

          <div className="grid grid-cols-7 gap-0.5">
            {days.map((date) => {
              const dateValue = toValue(date);
              const selected = value === dateValue;
              const currentMonth = date.getMonth() === month;
              const past = markPastDates && dateValue < todayValue;
              return (
                <button
                  key={dateValue}
                  type="button"
                  onClick={() => selectDate(date)}
                  className={`focus-ring aspect-square cursor-pointer rounded-btn text-xs transition-colors ${
                    selected
                      ? "bg-accent text-white"
                      : currentMonth
                        ? past
                          ? "text-muted/40 hover:bg-raised hover:text-muted"
                          : "text-ink hover:bg-raised"
                        : "text-muted/35 hover:bg-raised hover:text-muted"
                  }`}
                >
                  {date.getDate()}
                </button>
              );
            })}
          </div>

          {value && (
            <div className="mt-3 border-t border-line pt-3">
              <button
                type="button"
                onClick={clearDate}
                className="focus-ring w-full cursor-pointer rounded-btn px-3 py-2 text-xs text-muted transition-colors hover:bg-raised hover:text-ink"
              >
                {clearLabel}
              </button>
            </div>
          )}
        </div>,
        document.body,
      )
    : null;

  return (
    <>
      <div ref={containerRef} className={compact ? "shrink-0" : undefined}>
        <button
          ref={buttonRef}
          type="button"
          disabled={disabled}
          aria-label={
            compact
              ? value
                ? `Alterar prazo: ${formatValue(value)}`
                : "Adicionar prazo"
              : undefined
          }
          onClick={() => {
            if (open) {
              setOpen(false);
            } else {
              openPicker();
            }
          }}
          className={
            compact
              ? "focus-ring min-w-[48px] cursor-pointer whitespace-nowrap rounded-btn px-1 py-1 text-right text-[10px] tabular-nums text-muted transition-colors hover:bg-raised hover:text-ink disabled:cursor-not-allowed disabled:opacity-50"
              : `focus-ring w-full cursor-pointer rounded-item border px-3.5 py-2.5 text-left text-sm font-mono transition-colors ${
                  value
                    ? "bg-overlay border-outline/50 text-ink hover:border-accent-dim"
                    : "bg-overlay border-outline/50 text-muted hover:border-accent-dim"
                }`
          }
        >
          {displayValue ?? formatValue(value)}
        </button>

        {!compact && markPastDates && selectedIsPast && pastDateMessage && (
          <p className="mt-1 pl-3 text-[10px] text-danger">{pastDateMessage}</p>
        )}
      </div>

      {calendar}
    </>
  );
}
