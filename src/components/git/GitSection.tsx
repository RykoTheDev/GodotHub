import { useState, type ReactNode } from 'react'
import { IconChevronDown } from '../../lib/icons'

export function GitSection({
  title,
  count,
  storageKey,
  defaultOpen,
  onContextMenu,
  children,
}: {
  title: string
  count?: number
  storageKey?: string
  defaultOpen?: boolean
  onContextMenu?: (e: React.MouseEvent) => void
  children: ReactNode
}) {
  const [open, setOpen] = useState(() => {
    if (!storageKey) return defaultOpen ?? true
    try {
      const saved = localStorage.getItem(storageKey)
      return saved === null ? (defaultOpen ?? true) : saved !== '0'
    } catch {
      return defaultOpen ?? true
    }
  })
  const toggle = () => setOpen((v) => {
    if (storageKey) {
      try {
        localStorage.setItem(storageKey, v ? '0' : '1')
      } catch {}
    }
    return !v
  })
  return (
    <div className="flex flex-col gap-1.5">
      <button
        type="button"
        onClick={toggle}
        onContextMenu={onContextMenu}
        aria-expanded={open}
        className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-1 py-1 rounded-item text-left hover:bg-raised/60 transition-colors group"
      >
        <IconChevronDown
          className={`w-3 h-3 text-muted/50 shrink-0 transition-transform duration-200 ${
            open ? '' : '-rotate-90'
          }`}
        />
        <span className="flex-1 text-[10px] font-semibold uppercase tracking-wider text-muted/50 group-hover:text-muted transition-colors">
          {title}
        </span>
        {typeof count === 'number' && count > 0 && (
          <span className="text-[10px] font-mono font-medium tabular-nums text-muted/60 bg-overlay border border-outline/50 rounded-tag px-1.5 py-0.5 shrink-0">
            {count}
          </span>
        )}
      </button>

      <div
        className={`grid transition-[grid-template-rows] duration-200 ease-out ${
          open ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'
        }`}
      >
        <div className="overflow-hidden min-h-0">
          <div className="flex flex-col gap-1.5">{children}</div>
        </div>
      </div>
    </div>
  )
}

