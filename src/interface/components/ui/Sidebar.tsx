import { motion } from 'framer-motion'
import { useRef, useState } from 'react'
import type { ComponentType } from 'react'
import { useTranslation } from 'react-i18next'
import { IconArrowUp, IconChevronsLeft, IconHouse, IconSearch, IconX } from '../../lib/icons'
import type { IconProps } from '../../lib/icons'
import { WorkspaceSwitcher } from './WorkspaceSwitcher'
import { useSettings } from '../../../hooks/useSettings'
import { useUpdatesBadge } from '../../../hooks/useUpdatesBadge'
import { useChangelogBadge } from '../../../hooks/useChangelogBadge'
import { useUpdateAvailable } from '../../../hooks/useUpdateAvailable'
import { Tooltip } from '../reusables/Tooltip'

export interface SidebarTab {
  id: string
  label: string
  icon: ComponentType<IconProps>
  footer?: boolean
  iconOnly?: boolean
}

const COLLAPSED_WIDTH = 68
const KNOB_HEIGHT = 40
const KNOB_MIN_TOP = 36
const KNOB_TRACK_DIST = 56
const KNOB_RESET_DIST = 72

export function Sidebar({
  tabs,
  activeTab,
  onTabChange,
  connected = false,
  paletteKey = 'p',
  onOpenCommandPalette,
  onOpenUpdatesModal,
}: {
  tabs: SidebarTab[]
  activeTab: string
  onTabChange: (id: string) => void
  connected?: boolean
  paletteKey?: string
  onOpenCommandPalette?: () => void
  onOpenUpdatesModal?: () => void
}) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const { hasUnseen } = useUpdatesBadge()
  const { hasNewEntry: hasNewChangelogEntry, markSeen: markChangelogSeen } = useChangelogBadge()
  const { updateAvailable, previewUpdate } = useUpdateAvailable()
  const [width, setWidth] = useState(() => {
    try {
      return Math.min(
        350,
        Math.max(180, Number(localStorage.getItem('new_ui_sidebar_width')) || 256),
      )
    } catch {
      return 256
    }
  })
  const [collapsed, setCollapsed] = useState(() => {
    try {
      return localStorage.getItem('new_ui_sidebar_collapsed') === '1'
    } catch {
      return false
    }
  })
  const [paletteHintDismissed, setPaletteHintDismissed] = useState(() => {
    try {
      return localStorage.getItem('new_ui_sidebar_palette_hint_dismissed') === '1'
    } catch {
      return false
    }
  })
  const [dragging, setDragging] = useState(false)
  const [revealed, setRevealed] = useState(false)
  const [knobY, setKnobY] = useState<number | null>(null)
  const showKnob = revealed || dragging
  const toggleCollapsed = () => {
    setKnobY(null)
    setCollapsed((prev) => {
      try {
        localStorage.setItem('new_ui_sidebar_collapsed', prev ? '0' : '1')
      } catch {}
      return !prev
    })
  }
  const widthRef = useRef(width)
  widthRef.current = width
  const startXRef = useRef(0)
  const startWidthRef = useRef(0)

  const mainTabs = tabs.filter((t) => !t.footer)
  const footerTabs = tabs.filter((t) => t.footer)

  const beginDrag = (e: React.PointerEvent) => {
    e.preventDefault()
    startXRef.current = e.clientX
    startWidthRef.current = widthRef.current
    setDragging(true)
    try {
      e.currentTarget.setPointerCapture(e.pointerId)
    } catch {}
  }

  const finishDrag = (e: React.PointerEvent) => {
    setDragging(false)
    try {
      e.currentTarget.releasePointerCapture(e.pointerId)
    } catch {}
    try {
      localStorage.setItem('new_ui_sidebar_width', String(widthRef.current))
    } catch {}
  }

  const clampKnobY = (y: number, height: number) =>
    Math.min(Math.max(KNOB_MIN_TOP, y), Math.max(KNOB_MIN_TOP, height - KNOB_HEIGHT))

  const handleStripMove = (e: React.PointerEvent) => {
    if (dragging) {
      if (e.buttons === 0) {
        finishDrag(e)
        return
      }
      const next = startWidthRef.current + (e.clientX - startXRef.current)
      setWidth(Math.min(350, Math.max(180, Math.round(next))))
      return
    }
    const rect = e.currentTarget.getBoundingClientRect()
    const y = e.clientY - rect.top
    setKnobY(clampKnobY(y, rect.height))
  }

  const endDrag = (e: React.PointerEvent) => {
    if (!dragging) return
    finishDrag(e)
  }

  const handleWrapperMove = (e: React.MouseEvent) => {
    if (dragging || collapsed) return
    const rect = e.currentTarget.getBoundingClientRect()
    const dist = rect.right - e.clientX
    if (dist > KNOB_RESET_DIST) {
      setKnobY(null)
      return
    }
    if (dist <= KNOB_TRACK_DIST) {
      const y = e.clientY - rect.top
      setKnobY(clampKnobY(y, rect.height))
    }
  }

  const renderTabButton = (tab: SidebarTab, layoutClass: string, collapsedView = false) => {
    const active = activeTab === tab.id
    const Icon = tab.icon
    const hideLabel = collapsedView || !!tab.iconOnly
    const btn = (
      <button
        key={tab.id}
        type="button"
        onClick={() => {
          if (tab.id === 'changelog') markChangelogSeen()
          onTabChange(tab.id)
        }}
        aria-label={hideLabel ? tab.label : undefined}
        className={`focus-ring cursor-pointer relative flex items-center rounded-item text-sm font-medium transition-colors ${layoutClass} ${
          active
            ? 'text-ink border border-transparent'
            : 'text-muted border border-transparent hover:text-ink hover:bg-raised/60'
        } ${
          hasNewChangelogEntry && tab.id === 'changelog' && !active
            ? 'changelog-shine'
            : ''
        }`}
      >
        {active && (
          <motion.span
            layoutId="new-ui-nav-pill"
            transition={{ type: 'spring', stiffness: 650, damping: 38 }}
            className="absolute inset-0 rounded-item bg-overlay border border-outline/50 shadow-md shadow-black/10 pointer-events-none"
          />
        )}
        <Icon
          className={`relative w-4 h-4 shrink-0 transition-colors duration-200 ${active ? 'text-accent' : 'text-muted'}`}
        />
        {!hideLabel && (
          <span className={`relative transition-colors duration-200 ${active ? 'text-ink' : ''}`}>{tab.label}</span>
        )}
        {hasUnseen && tab.id === 'updates' && !active && (
          <span className="absolute top-1.5 right-1.5 flex w-2 h-2" aria-hidden="true">
            <span className="absolute inline-flex h-full w-full rounded-full bg-accent-bright opacity-75 animate-ping" />
            <span className="relative inline-flex rounded-full w-2 h-2 bg-accent-bright shadow-[0_0_6px_2px] shadow-accent/50" />
          </span>
        )}
      </button>
    )
    return collapsedView ? (
      <span key={tab.id} className="contents">
        <Tooltip content={tab.label} side="right">
          {btn}
        </Tooltip>
      </span>
    ) : (
      btn
    )
  }

  const collapseBtn = (
    <button
      type="button"
      onClick={toggleCollapsed}
      aria-label={collapsed ? t('expand_sidebar') : t('collapse_sidebar')}
      className={`focus-ring cursor-pointer flex items-center justify-center rounded-item text-sm font-medium transition-colors text-muted hover:text-ink hover:bg-raised/60 border ${
        collapsed
          ? `absolute top-2 -right-4 w-8 h-8 shrink-0 bg-raised border-line shadow-md shadow-black/10 transition-opacity duration-200 ease-out ${
              revealed ? 'opacity-100' : 'opacity-0 pointer-events-none'
            }`
          : 'border-transparent w-9 h-9 ml-auto shrink-0'
      }`}
    >
      <motion.span
        className="inline-flex"
        initial={false}
        animate={{ rotate: collapsed ? 180 : 0 }}
        transition={{ type: 'spring', stiffness: 380, damping: 32 }}
      >
        <IconChevronsLeft className={`w-4 h-4 ${collapsed ? 'pr-0' : 'pr-2'}`} />
      </motion.span>
    </button>
  )

  return (
    <div
      className={`relative shrink-0 h-full ${dragging ? 'select-none' : ''}`}
      onMouseEnter={() => setRevealed(true)}
      onMouseMove={handleWrapperMove}
      onMouseLeave={(e) => {
        if (e.relatedTarget instanceof Node && e.currentTarget.contains(e.relatedTarget)) return
        setRevealed(false)
        setKnobY(null)
      }}
    >
      <motion.div
        animate={{ width: collapsed ? COLLAPSED_WIDTH : width }}
        transition={dragging ? { duration: 0 } : { type: 'spring', stiffness: 650, damping: 38 }}
        className={`flex flex-col h-full overflow-hidden ${
          connected
            ? 'rounded-none border-r border-line bg-raised'
            : 'rounded-card bg-raised'
        }`}
      >
      <div
        className={`shrink-0 flex items-center gap-2 h-12 border-b border-line ${
          collapsed ? 'justify-center px-0' : 'px-3'
        }`}
      >
        {!collapsed && (              <Tooltip content={t('dashboard')}>
              <button
                type="button"
                onClick={() => onTabChange('dashboard')}
                className="focus-ring cursor-pointer font-display pl-2 font-black text-2xl tracking-tight text-ink/50 hover:text-ink min-w-0 truncate text-left transition-colors"
              >
                GodotHub
              </button>
              </Tooltip>
        )}
        {collapsed ? (
          <Tooltip content={t('dashboard')}>
          <button
              type="button"
              onClick={() => onTabChange('dashboard')}
              aria-label={t('dashboard')}
              className="focus-ring cursor-pointer w-6 h-6 shrink-0 flex items-center justify-center rounded-item text-muted hover:text-ink hover:bg-raised/60 transition-colors"
            >
              <IconHouse className="w-4 h-4" />
            </button>
            </Tooltip>
        ) : (
          collapseBtn
        )}
      </div>

      {settings.workspaces_enabled && (
        <div className={`shrink-0 ${collapsed ? 'flex justify-center px-0 py-2' : 'px-3 pb-1'}`}>
          <WorkspaceSwitcher collapsed={collapsed} />
        </div>
      )}

      <nav className={`flex-1 p-3 pt-2 flex flex-col gap-1 ${collapsed ? 'items-center' : ''}`}>
        {mainTabs.map((tab) =>
          renderTabButton(
            tab,
            collapsed ? 'w-11 h-11 shrink-0 justify-center' : 'w-full gap-2.5 px-3 py-2.5',
            collapsed,
          ),
        )}
      </nav>
      {footerTabs.length > 0 && (
        <nav className={`shrink-0 p-3 flex flex-col gap-1.5 ${collapsed ? 'items-center' : 'items-stretch'}`}>
          <div
            className={`flex flex-col ${
              collapsed ? 'gap-1 items-center' : 'gap-1.5 items-stretch'
            }`}
          >
            {!collapsed && onOpenCommandPalette && !paletteHintDismissed && (
              <div className="relative">
                <button
                  type="button"
                  onClick={onOpenCommandPalette}
                  className="focus-ring cursor-pointer w-full flex items-center gap-2 px-3 py-2 rounded-item border border-dashed border-outline/50 text-[11px] font-medium text-muted/60 hover:text-muted hover:border-outline hover:bg-raised/50 transition-colors"
                >
                  <kbd className="font-mono text-[9px] px-1.5 py-0.5 rounded-tag bg-overlay border border-outline/50">
                    {navigator.platform.includes('Mac')
                      ? `⌘${paletteKey.toUpperCase()}`
                      : `Ctrl+${paletteKey.toUpperCase()}`}
                  </kbd>
                  <span className="flex items-center gap-1.5">
                    <IconSearch className="w-3 h-3" />
                    {tc('quick_commands')}
                  </span>
                </button>
                  <button
                    type="button"
                    onClick={() => {
                      try {
                        localStorage.setItem(
                          'new_ui_sidebar_palette_hint_dismissed',
                          '1',
                        )
                      } catch {}
                      setPaletteHintDismissed(true)
                    }}
                    aria-label={tc('close')}
                    className="focus-ring cursor-pointer w-4 h-4 rounded-full bg-raised border border-outline/60 text-muted/60 hover:text-ink hover:border-outline flex items-center justify-center transition-colors absolute -top-1.5 -right-1.5"
                  >
                    <IconX className="w-2.5 h-2.5" />
                  </button>
              </div>
            )}
            {(updateAvailable || previewUpdate) && onOpenUpdatesModal && !collapsed && (
              <button
                type="button"
                onClick={onOpenUpdatesModal}
                className="focus-ring cursor-pointer w-full flex items-center gap-2 px-3 py-2 rounded-item bg-accent/10 border border-accent/30 text-xs font-medium text-accent-bright hover:bg-accent/20 transition-colors"
              >
                <span className="relative flex w-2 h-2">
                  <span className="absolute inline-flex h-full w-full rounded-full bg-accent-bright opacity-75 animate-ping" />
                  <span className="relative inline-flex rounded-full w-2 h-2 bg-accent-bright" />
                </span>
                Update available
              </button>
            )}
            {(updateAvailable || previewUpdate) && onOpenUpdatesModal && collapsed && (
                <Tooltip content="Update available">
                <button
                  type="button"
                  onClick={onOpenUpdatesModal}
                  className="focus-ring cursor-pointer w-11 h-11 shrink-0 flex items-center justify-center rounded-item relative text-muted hover:text-ink hover:bg-raised/60 transition-colors"
                  aria-label="Update available"
                >
                  <IconArrowUp className="w-4 h-4" />
                  <span className="absolute top-2 right-2 flex w-2 h-2" aria-hidden="true">
                    <span className="absolute inline-flex h-full w-full rounded-full bg-accent-bright opacity-75 animate-ping" />
                    <span className="relative inline-flex rounded-full w-2 h-2 bg-accent-bright shadow-[0_0_6px_2px] shadow-accent/50" />
                  </span>
                </button>
                </Tooltip>
            )}
            {footerTabs.slice(0, -2).map((tab) =>
              renderTabButton(
                tab,
                collapsed || tab.iconOnly
                  ? 'w-11 h-11 shrink-0 justify-center'
                  : 'w-full gap-2.5 px-3 py-2.5',
                collapsed,
              ),
            )}
            {footerTabs.length >= 2 && (
              <div
                className={`flex ${
                  collapsed
                    ? 'flex-col gap-1 items-center'
                    : 'flex-row gap-1.5 items-stretch'
                }`}
              >
                {footerTabs.slice(-2).map((tab) =>
                  renderTabButton(
                    tab,
                    collapsed || tab.iconOnly
                      ? 'w-11 h-11 shrink-0 justify-center'
                      : 'flex-1 gap-2.5 px-3 py-2.5',
                    collapsed,
                  ),
                )}
              </div>
            )}
          </div>
        </nav>
      )}
      </motion.div>
      {collapsed && (
        <span title={t('expand_sidebar')} className="contents">
          {collapseBtn}
        </span>
      )}
      {!collapsed && (
      <div
        onPointerDown={beginDrag}
        onPointerMove={handleStripMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
        role="separator"
        aria-orientation="vertical"
        style={{ touchAction: 'none' }}
        onMouseEnter={() => setRevealed(true)}
        onMouseLeave={(e) => {
          if (e.relatedTarget instanceof Node && e.currentTarget.parentElement?.contains(e.relatedTarget)) return
          setRevealed(false)
          setKnobY(null)
        }}
        className="absolute inset-y-0 -right-3.5 w-7 cursor-col-resize group/edge z-10"
      >
        <div
          className={`absolute left-1/2 -translate-x-1/2 -translate-y-1/2 flex flex-col items-center pointer-events-none transition-[top,opacity] duration-200 ease-out ${
            knobY != null ? '' : 'top-1/2'
          } ${showKnob ? 'opacity-100' : 'opacity-0'}`}
          style={knobY != null ? { top: knobY } : undefined}
        >
          <div
            className={`absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 rounded-tag bg-raised border border-line shadow-md shadow-base text-[10px] font-mono text-muted tabular-nums whitespace-nowrap transition-all duration-200 ${
              dragging ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-1'
            }`}
          >
            {width}px
          </div>
          <div
            className={`flex items-center justify-center w-5 h-10 rounded-full border shadow-md shadow-base transition-all duration-200 ${
            dragging
              ? 'bg-accent border-accent scale-110 shadow-accent/30'
              : 'bg-raised border-line shadow-base group-hover/edge:border-accent-dim group-hover/edge:scale-110'
          }`}
        >
            <div className="flex flex-col items-center justify-center gap-1">
          <div
            className={`w-1 h-1 rounded-full transition-colors duration-200 ${
              dragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
            }`}
          />
          <div
            className={`w-1 h-1 rounded-full transition-colors duration-200 ${
              dragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
            }`}
          />
          <div
            className={`w-1 h-1 rounded-full transition-colors duration-200 ${
              dragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
            }`}
          />
            </div>
        </div>
        </div>
      </div>
      )}
    </div>
  )
}
