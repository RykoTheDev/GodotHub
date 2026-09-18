import type {
  ComponentType,
  MouseEvent as ReactMouseEvent,
  ReactNode,
} from 'react'
import { IconChevronRight } from '../../lib/icons'
import type { IconProps } from '../../lib/icons'

export interface MenuItem {
  key: string
  label: string
  icon?: ComponentType<IconProps>
  leading?: ReactNode
  onClick?: () => void
  disabled?: boolean
  danger?: boolean
  active?: boolean
  dotColor?: string
  shortcut?: string
  dividerAfter?: boolean
  badge?: string
  children?: MenuItem[]
}

export const MENU_VIEWPORT_PAD = 8

export const MENU_GAP = 8

export function menuSurfaceClass(compact: boolean, extra = ''): string {
  return `rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 ${
    compact ? 'min-w-48 p-2' : 'min-w-60 p-2.5'
  } ${extra}`
}

export function MenuDivider({ compact }: { compact: boolean }) {
  return <div className={`h-px bg-white/6 ${compact ? 'my-0.5' : 'my-1'}`} />
}

export function MenuButton({
  item,
  compact,
  onSelect,
  caret = false,
}: {
  item: MenuItem
  compact: boolean
  onSelect: (e: ReactMouseEvent<HTMLButtonElement>) => void
  caret?: boolean
}) {
  const iconBox = compact ? 'w-6 h-6' : 'w-7 h-7'
  const iconSize = compact ? 'w-3 h-3' : 'w-3.5 h-3.5'

  return (
    <button
      type="button"
      role="menuitem"
      disabled={item.disabled}
      onClick={onSelect}
      className={`w-full flex items-center gap-1 rounded-item text-xs font-medium transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed ${
        compact ? 'px-2 py-1.5' : 'px-2.5 py-2'
      } ${
        item.danger
          ? 'text-red-400 hover:bg-red-500/10 hover:text-red-300'
          : item.active
            ? 'text-ink bg-accent hover:bg-accent'
            : 'text-muted hover:bg-raised hover:text-ink'
      }`}
    >
      {item.leading && <span className="shrink-0">{item.leading}</span>}
      {item.icon && (
        <span
          className={`${iconBox} rounded-btn flex items-center justify-center shrink-0 ${
            item.danger
              ? 'bg-red-500/10'
              : item.active
                ? 'bg-accent/20'
                : 'bg-transparent'
          }`}
        >
          <item.icon
            className={`${iconSize} ${
              item.danger
                ? 'text-red-400'
                : item.active
                  ? 'text-accent-bright'
                  : 'text-muted'
            }`}
          />
        </span>
      )}
      {item.dotColor && (
        <span
          aria-hidden="true"
          className="w-2 h-2 rounded-full shrink-0"
          style={{ backgroundColor: item.dotColor }}
        />
      )}
      <span className="flex-1 text-left truncate">{item.label}</span>
      {item.badge && (
        <span
          className={`shrink-0 text-[10px] font-semibold px-1.5 py-0.5 rounded-tag border ${
            item.active
              ? 'bg-black/15 text-ink border-black/10'
              : 'bg-accent/10 text-accent-bright border-accent-dim/40'
          }`}
        >
          {item.badge}
        </span>
      )}
      {item.shortcut && (
        <span className="text-[10px] text-muted font-mono shrink-0">
          {item.shortcut}
        </span>
      )}
      {caret && <IconChevronRight className="w-3 h-3 text-muted/80 shrink-0" />}
    </button>
  )
}
