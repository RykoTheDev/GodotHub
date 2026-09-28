import type { ComponentType } from 'react'
import type { IconProps } from '../../lib/icons'
import { menuSurfaceClass } from './menu'

export interface SlashMenuItem {
  key: string
  label: string
  /** Right-aligned monospace hint, e.g. the `tag:` syntax or the field name. */
  hint?: string
  icon?: ComponentType<IconProps>
  dotColor?: string
}

/**
 * Discord-style suggestion list shown under the search bar while the user is
 * typing a `/command` or a `field:` value.
 */
export function SlashMenu({
  title,
  footer,
  items,
  selectedIndex,
  emptyLabel,
  onSelect,
  onHighlight,
}: {
  title: string
  footer?: string
  items: SlashMenuItem[]
  selectedIndex: number
  emptyLabel: string
  onSelect: (item: SlashMenuItem, index: number) => void
  onHighlight: (index: number) => void
}) {
  return (
    <div
      role="listbox"
      aria-label={title}
      className={`absolute left-0 right-0 top-full mt-2 z-50 max-h-64 overflow-y-auto ${menuSurfaceClass(
        false,
      )}`}
    >
      <div className="flex items-center gap-2 px-2 pb-1 pt-0.5">
        <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">
          {title}
        </span>
        <div className="flex-1 h-px bg-outline/40" />
      </div>
      {items.length === 0 ? (
        <p className="px-2 py-2 text-xs text-muted/70">{emptyLabel}</p>
      ) : (
        items.map((item, index) => {
          const active = index === selectedIndex
          return (
            <button
              key={item.key}
              type="button"
              role="option"
              aria-selected={active}
              onMouseEnter={() => onHighlight(index)}
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => onSelect(item, index)}
              className={`w-full flex items-center gap-2 px-2.5 py-2 rounded-item text-xs font-medium transition-colors cursor-pointer ${
                active
                  ? 'text-ink bg-accent hover:bg-accent'
                  : 'text-muted hover:bg-raised hover:text-ink'
              }`}
            >
              {item.dotColor ? (
                <span
                  aria-hidden="true"
                  className="w-2 h-2 rounded-full shrink-0"
                  style={{ backgroundColor: item.dotColor }}
                />
              ) : item.icon ? (
                <item.icon className="w-3.5 h-3.5 shrink-0" strokeWidth={2} />
              ) : null}
              <span className="flex-1 text-left truncate">{item.label}</span>
              {item.hint && (
                <span
                  className={`shrink-0 font-mono text-[10px] ${
                    active ? 'text-ink/70' : 'text-muted/50'
                  }`}
                >
                  {item.hint}
                </span>
              )}
            </button>
          )
        })
      )}
      {footer && (
        <p className="px-2 pb-1 pt-2 text-[10px] text-muted/60">{footer}</p>
      )}
    </div>
  )
}
