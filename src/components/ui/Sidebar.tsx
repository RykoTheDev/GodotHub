import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import type { ComponentType } from 'react'
import { useTranslation } from 'react-i18next'
import { IconArrowUp, IconChevronRight, IconChevronsLeft, IconGear, IconInfo, IconSearch, IconUser, IconX } from '../../lib/icons'
import type { IconProps } from '../../lib/icons'
import { WorkspaceModals } from './WorkspaceSwitcher'
import { AccountMenu } from './AccountMenu'
import { Disclosure, DisclosureChevron } from '../reusables/Disclosure'
import { useSettings } from '../../hooks/useSettings'
import { useUpdateAvailable } from '../../hooks/useUpdateAvailable'
import { Tooltip } from '../reusables/Tooltip'
import { OverlayScrollArea } from '../reusables/OverlayScrollArea'
import { isRtl } from '../../lib/locale'
import { registerSettingsClick } from '../../lib/debugMode'
import { busy, ease, gsap } from '../../lib/motion'

export interface SidebarTab {
  id: string
  label: string
  icon: ComponentType<IconProps>
  isNew?: boolean
  group?: { id: string; label: string; icon: ComponentType<IconProps> }
  shortcut?: number
  badge?: number
}

const COLLAPSED_WIDTH = 68
const DEFAULT_SIDEBAR_WIDTH = 256
const MIN_SIDEBAR_WIDTH = 195
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
  const { updateAvailable, previewUpdate } = useUpdateAvailable()
  const [width, setWidth] = useState(() => {
    try {
      return Math.min(
        350,
        Math.max(MIN_SIDEBAR_WIDTH, Number(localStorage.getItem('new_ui_sidebar_width')) || DEFAULT_SIDEBAR_WIDTH),
      )
    } catch {
      return DEFAULT_SIDEBAR_WIDTH
    }
  })
  const [collapsed, setCollapsed] = useState(() => {
    try {
      return localStorage.getItem('new_ui_sidebar_collapsed') === '1'
    } catch {
      return false
    }
  })
  const [seenNewTabs, setSeenNewTabs] = useState<string[]>(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('new_ui_sidebar_seen_new_tabs') ?? '[]')
      return Array.isArray(saved) ? saved.filter((id): id is string => typeof id === 'string') : []
    } catch {
      return []
    }
  })
  const markTabSeen = (id: string) => {
    if (seenNewTabs.includes(id)) return
    const next = [...seenNewTabs, id]
    setSeenNewTabs(next)
    try {
      localStorage.setItem('new_ui_sidebar_seen_new_tabs', JSON.stringify(next))
    } catch {}
  }
  const [workspaceTipSeen, setWorkspaceTipSeen] = useState(() => {
    try {
      return localStorage.getItem('new_ui_sidebar_workspace_tip_seen') === '1'
    } catch {
      return true
    }
  })
  const dismissWorkspaceTip = () => {
    setWorkspaceTipSeen(true)
    try {
      localStorage.setItem('new_ui_sidebar_workspace_tip_seen', '1')
    } catch {}
  }
  const [closedGroups, setClosedGroups] = useState<string[]>(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('new_ui_sidebar_closed_groups') ?? '[]')
      return Array.isArray(saved) ? saved.filter((id): id is string => typeof id === 'string') : []
    } catch {
      return []
    }
  })
  const saveClosedGroups = (next: string[]) => {
    setClosedGroups(next)
    try {
      localStorage.setItem('new_ui_sidebar_closed_groups', JSON.stringify(next))
    } catch {}
  }
  const toggleGroup = (id: string) =>
    saveClosedGroups(closedGroups.includes(id) ? closedGroups.filter((g) => g !== id) : [...closedGroups, id])
  const activeGroupId = tabs.find((tab) => tab.id === activeTab)?.group?.id
  const previousActiveTab = useRef(activeTab)
  useEffect(() => {
    if (previousActiveTab.current === activeTab) return
    previousActiveTab.current = activeTab
    if (activeGroupId && closedGroups.includes(activeGroupId)) {
      saveClosedGroups(closedGroups.filter((g) => g !== activeGroupId))
    }
  }, [activeTab])
  const [dragging, setDragging] = useState(false)
  const [revealed, setRevealed] = useState(false)
  const [knobY, setKnobY] = useState<number | null>(null)
  const showKnob = revealed || dragging
  const lastDownRef = useRef(0)
  const [widthAnimating, setWidthAnimating] = useState(false)
  const panelRef = useRef<HTMLDivElement>(null)
  const wasCollapsed = useRef(collapsed)
  useLayoutEffect(() => {
    const panel = panelRef.current
    const expanded = wasCollapsed.current && !collapsed
    wasCollapsed.current = collapsed
    if (!expanded || !panel) return
    const labels = Array.from(
      panel.querySelectorAll<HTMLElement>('button > :not(svg, [data-motion-shared], .absolute, .opacity-0)'),
    )
    if (!labels.length) return
    const release = busy(...labels)
    gsap.from(labels, {
      opacity: 0,
      x: isRtl() ? 10 : -10,
      duration: 0.4,
      delay: 0.08,
      stagger: { amount: Math.min(0.2, labels.length * 0.012) },
      ease: ease.out,
      clearProps: 'opacity,transform',
      onComplete: release,
      onInterrupt: release,
    })
  }, [collapsed])
  const toggleCollapsed = () => {
    setKnobY(null)
    setWidthAnimating(true)
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

  const tabGroups = tabs.reduce<{ id: string; group?: SidebarTab['group']; tabs: SidebarTab[] }[]>((groups, tab) => {
    const id = tab.group?.id ?? tab.id
    const last = groups[groups.length - 1]
    if (last && tab.group && last.id === id) last.tabs.push(tab)
    else groups.push({ id, group: tab.group, tabs: [tab] })
    return groups
  }, [])

  const beginDrag = (e: React.PointerEvent) => {
    const now = Date.now()
    if (now - lastDownRef.current < 350) {
      lastDownRef.current = now
      setWidth(DEFAULT_SIDEBAR_WIDTH)
      setKnobY(null)
      try {
        localStorage.setItem('new_ui_sidebar_width', String(DEFAULT_SIDEBAR_WIDTH))
      } catch {}
      return
    }
    lastDownRef.current = now
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

  /** Knob offset from the rail's vertical center, so the position can ride on a transform. */
  const knobOffsetY = (y: number, height: number) => clampKnobY(y, height) - height / 2

  const handleStripMove = (e: React.PointerEvent) => {
    if (dragging) {
      if (e.buttons === 0) {
        finishDrag(e)
        return
      }
      const delta = e.clientX - startXRef.current
      const next = startWidthRef.current + (isRtl() ? -delta : delta)
      setWidth(Math.min(350, Math.max(MIN_SIDEBAR_WIDTH, Math.round(next))))
      return
    }
    if (settings.fixed_sidebar_resize_knob) return
    const rect = e.currentTarget.getBoundingClientRect()
    const y = e.clientY - rect.top
    setKnobY(knobOffsetY(y, rect.height))
  }

  const endDrag = (e: React.PointerEvent) => {
    if (!dragging) return
    finishDrag(e)
  }

  const handleWrapperMove = (e: React.MouseEvent) => {
    if (dragging || collapsed || settings.fixed_sidebar_resize_knob) return
    const rect = e.currentTarget.getBoundingClientRect()
    const dist = isRtl() ? e.clientX - rect.left : rect.right - e.clientX
    if (dist > KNOB_RESET_DIST) {
      setKnobY(null)
      return
    }
    if (dist <= KNOB_TRACK_DIST) {
      const y = e.clientY - rect.top
      setKnobY(knobOffsetY(y, rect.height))
    }
  }

  const badgeLabel = (count: number) => (count > 9 ? '9+' : String(count))
  const modLabel = (key: string) => (navigator.platform.includes('Mac') ? `⌘${key}` : `Ctrl+${key}`)

  const renderTabButton = (
    tab: SidebarTab,
    layoutClass: string,
    collapsedView = false,
    menu?: { open: boolean; toggle: () => void },
  ) => {
    const active = activeTab === tab.id
    const Icon = tab.icon
    const hideLabel = collapsedView
    const showNew = !!tab.isNew && !seenNewTabs.includes(tab.id)
    const shortcut = tab.shortcut ? modLabel(String(tab.shortcut)) : undefined
    const btn = (
      <button
        key={tab.id}
        type="button"
        aria-haspopup={menu ? 'menu' : undefined}
        aria-expanded={menu?.open}
        onClick={() => {
          if (menu) return menu.toggle()
          if (tab.id === 'settings') registerSettingsClick()
          if (tab.isNew) markTabSeen(tab.id)
          onTabChange(tab.id)
        }}
        aria-label={hideLabel || tab.badge ? (tab.badge ? `${tab.label} (${tab.badge})` : tab.label) : undefined}
        aria-keyshortcuts={tab.shortcut ? `${navigator.platform.includes('Mac') ? 'Meta' : 'Control'}+${tab.shortcut}` : undefined}
        className={`group/tab focus-ring cursor-pointer relative flex items-center rounded-item text-sm font-medium  ${layoutClass} ${
          showNew ? 'border border-dashed border-accent/70' : 'border border-transparent'
        } ${
          active
            ? 'text-ink'
            : 'text-muted hover:text-ink hover:bg-raised/60'
        }`}
      >
        {active && (
          <span
            data-motion-shared="sidebar-tab"
            className="absolute inset-0 rounded-item bg-overlay border border-outline/50 shadow-md shadow-black/10 pointer-events-none"
          />
        )}
        <Icon
          className={` relative w-4 h-4 shrink-0 ${active ? 'text-accent' : 'text-muted'}`}
        />
        {!hideLabel && (
          <span className={`relative min-w-0 flex-1 truncate text-start ${active ? 'text-ink' : ''}`}>{tab.label}</span>
        )}
        {showNew && !hideLabel && (
          <span className="relative ms-auto shrink-0 px-1.5 py-0.5 rounded-tag bg-accent text-white text-3xs font-semibold leading-none">
            {tc('new_badge')}
          </span>
        )}
        {!!tab.badge && !showNew && !hideLabel && (
          <span className="relative ms-auto shrink-0 min-w-5 h-5 px-1.5 inline-flex items-center justify-center rounded-full bg-accent text-white text-3xs font-semibold tabular-nums leading-none">
            {badgeLabel(tab.badge)}
          </span>
        )}
        {!!tab.badge && !showNew && hideLabel && (
          <span className="absolute top-0.5 inset-e-0.5 min-w-4 h-4 px-1 inline-flex items-center justify-center rounded-full bg-accent text-white text-4xs font-semibold tabular-nums leading-none" aria-hidden="true">
            {badgeLabel(tab.badge)}
          </span>
        )}
        {shortcut && !tab.badge && !showNew && !hideLabel && (
          <kbd className="relative ms-auto shrink-0 font-mono text-4xs px-1.5 py-0.5 rounded-tag bg-raised border border-outline/50 text-muted/70 opacity-0 group-hover/tab:opacity-100 group-focus-visible/tab:opacity-100">
            {shortcut}
          </kbd>
        )}
        {showNew && hideLabel && (
          <span className="absolute top-1 inset-e-1 w-2 h-2 rounded-full bg-accent" aria-hidden="true" />
        )}
      </button>
    )
    return collapsedView ? (
      <span key={tab.id} className="contents">
        <Tooltip
          content={
            shortcut ? (
              <span className="inline-flex items-center gap-2">
                {tab.label}
                <kbd className="font-mono text-4xs text-muted">{shortcut}</kbd>
              </span>
            ) : (
              tab.label
            )
          }
          side="right"
        >
          {btn}
        </Tooltip>
      </span>
    ) : (
      btn
    )
  }

  const collapseBtn = (
    <Tooltip content={collapsed ? t('expand_sidebar') : t('collapse_sidebar')} side="right">
    <button
      type="button"
      onClick={toggleCollapsed}
      className={`focus-ring cursor-pointer flex items-center justify-center rounded-item text-sm font-medium text-muted hover:text-ink hover:bg-raised/60 border ${
        collapsed
          ? `absolute top-2 -inset-e-4 w-8 h-8 shrink-0 bg-raised border-line shadow-md shadow-black/10  ${
              revealed ? 'opacity-100' : 'opacity-0 pointer-events-none'
            }`
          : 'border-transparent w-9 h-9 ms-auto shrink-0'
      }`}
    >
      <span
        className="inline-flex transition-transform duration-500 ease-spring"
        style={{ transform: collapsed ? 'rotate(180deg)' : 'rotate(0deg)' }}
      >
        <IconChevronsLeft className="w-4 h-4 rtl:-scale-x-100" />
      </span>
    </button>
    </Tooltip>
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
      <div
        ref={panelRef}
        style={{width:collapsed ? COLLAPSED_WIDTH : width}}
        onTransitionEnd={(e) => {
          if (e.target === e.currentTarget && e.propertyName === 'width') setWidthAnimating(false)
        }}
        className={`flex flex-col h-full overflow-hidden ${widthAnimating ? 'whitespace-nowrap' : ''} ${dragging ? '' : 'transition-[width] duration-500 ease-out-expo'} ${
          connected
            ? 'rounded-none border-e border-line bg-raised'
            : 'rounded-card bg-raised'
        }`}
      >
      {!collapsed && (
        <div className="shrink-0 flex items-center justify-end gap-2 px-3 h-14">
            {onOpenCommandPalette && (
              <button
                type="button"
                onClick={onOpenCommandPalette}
                className="focus-ring cursor-pointer flex-1 min-w-0 flex items-center gap-2 px-3 h-9 rounded-item bg-overlay/60 border border-outline/50 text-sm text-muted hover:text-ink hover:border-outline hover:bg-overlay "
              >
                <IconSearch className="w-4 h-4 shrink-0" />
                <span className="flex-1 text-start truncate">{tc('search')}</span>
                <kbd className="font-mono text-4xs px-1.5 py-0.5 rounded-tag bg-raised border border-outline/50 text-muted/70">
                  {modLabel(paletteKey.toUpperCase())}
                </kbd>
              </button>
            )}
            {collapseBtn}
        </div>
      )}

      {onOpenCommandPalette && collapsed && (
        <div className="shrink-0 flex justify-center px-0 pt-3">
          <Tooltip content={tc('search')} side="right">
            <button
              type="button"
              onClick={onOpenCommandPalette}
              aria-label={tc('search')}
              className="focus-ring cursor-pointer w-11 h-11 shrink-0 flex items-center justify-center rounded-item text-muted hover:text-ink hover:bg-raised/60 "
            >
              <IconSearch className="w-4 h-4" />
            </button>
          </Tooltip>
        </div>
      )}

      {settings.workspaces_enabled && <WorkspaceModals />}

      <OverlayScrollArea className="flex-1 min-h-0" hideTopButton>
      <nav className={`p-3 pt-2 flex flex-col ${collapsed ? 'items-center gap-1' : 'gap-1.5'}`}>
        {tabGroups.map((group) => {
          const buttons = group.tabs.map((tab) =>
            renderTabButton(
              tab,
              collapsed ? 'w-11 h-11 shrink-0 justify-center' : 'w-full gap-2 px-3 py-2',
              collapsed,
            ),
          )
          if (collapsed) {
            return (
              <div key={group.id} className="contents">
                {buttons}
              </div>
            )
          }
          if (!group.group) return <div key={group.id} className="contents">{buttons}</div>
          const GroupIcon = group.group.icon
          const activeInGroup = group.tabs.find((tab) => tab.id === activeTab)
          const hasActive = !!activeInGroup
          const groupBadge = group.tabs.reduce((sum, tab) => sum + (tab.badge ?? 0), 0)
          const open = !closedGroups.includes(group.id)
          const panelId = `sidebar-group-${group.id}`
          return (
            <div key={group.id} className="flex flex-col">
              <button
                type="button"
                onClick={() => toggleGroup(group.id)}
                aria-expanded={open}
                aria-controls={panelId}
                className={`focus-ring cursor-pointer w-full flex items-center gap-2 px-2 py-2 rounded-item border text-sm font-medium  ${
                  hasActive
                    ? 'bg-overlay/50 border-outline/30 text-ink'
                    : 'border-transparent text-muted hover:text-ink hover:bg-raised/60'
                }`}
              >
                <GroupIcon className={` w-4 h-4 shrink-0 ${hasActive ? 'text-ink' : 'text-muted'}`} />
                <span className="shrink-0">{group.group.label}</span>
                {!open && activeInGroup && (
                  <>
                    <IconChevronRight className="w-2 h-2 shrink-0 text-muted rtl:rotate-180" aria-hidden="true" />
                    <span className="truncate text-xs text-muted">{activeInGroup.label}</span>
                  </>
                )}
                <span className="ms-auto inline-flex items-center gap-2">
                  {!open && groupBadge > 0 && (
                    <span className="min-w-5 h-5 px-1.5 inline-flex items-center justify-center rounded-full bg-accent text-white text-3xs font-semibold tabular-nums leading-none">
                      {badgeLabel(groupBadge)}
                    </span>
                  )}
                  <DisclosureChevron open={open} />
                </span>
              </button>
              <Disclosure id={panelId} open={open} className="flex flex-col gap-0.5 ms-5 ps-2 border-s border-line pt-1 pb-1">
                {buttons}
              </Disclosure>
            </div>
          )
        })}
      </nav>
      </OverlayScrollArea>
      <div className={`shrink-0 p-3 flex flex-col ${collapsed ? 'items-center gap-1' : 'items-stretch gap-1.5'}`}>
        {(updateAvailable || previewUpdate) && onOpenUpdatesModal && (collapsed ? (
            <Tooltip content={tc('update_available')}>
              <button
                type="button"
                onClick={onOpenUpdatesModal}
                className="focus-ring cursor-pointer w-11 h-11 shrink-0 flex items-center justify-center rounded-item relative text-muted hover:text-ink hover:bg-raised/60 "
              >
                <IconArrowUp className="w-4 h-4" />
                <span className="absolute top-2 inset-e-2 flex w-2 h-2" aria-hidden="true">
                  <span className="relative inline-flex rounded-full w-2 h-2 bg-accent-bright shadow-[0_0_6px_2px] shadow-accent/50" />
                </span>
              </button>
            </Tooltip>
          ) : (
            <button
              type="button"
              onClick={onOpenUpdatesModal}
              className="focus-ring cursor-pointer w-full flex items-center gap-2.5 px-3 py-2.5 rounded-item bg-accent/10 border border-accent/30 text-xs font-medium text-accent-bright hover:bg-accent/20 "
            >
              <span className="relative flex w-2 h-2">
                <span className="relative inline-flex rounded-full w-2 h-2 bg-accent-bright" />
              </span>
              {tc('update_available')}
            </button>
          ))}
        {settings.workspaces_enabled && !collapsed && !workspaceTipSeen && (
          <div className="flex items-start gap-2.5 rounded-item bg-accent/10 border border-accent/30 p-3 text-start">
            <IconInfo className="w-4 h-4 shrink-0 text-accent-bright mt-0.5" />
            <div className="min-w-0 flex-1">
              <p className="text-xs font-semibold text-ink">{t('workspace_tip_title')}</p>
              <p className="text-2xs text-muted leading-relaxed mt-0.5">{t('workspace_tip_body')}</p>
            </div>
            <button
              type="button"
              onClick={dismissWorkspaceTip}
              aria-label={t('workspace_tip_dismiss')}
              className="focus-ring cursor-pointer -m-1 p-1 rounded-btn text-muted/50 hover:text-ink shrink-0"
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          </div>
        )}
        <div className={`flex ${collapsed ? 'flex-col gap-1 items-center' : 'flex-row gap-1.5 items-stretch'}`}>
          <AccountMenu
            className={collapsed ? 'w-fit' : 'flex-1 min-w-0'}
            onNavigate={onTabChange}
            trigger={(menu) =>
              renderTabButton(
                { id: 'account', label: t('you'), icon: IconUser },
                `bg-overlay/40 ${collapsed ? 'w-11 h-11 shrink-0 justify-center' : 'w-full gap-2 px-3 py-2'}`,
                collapsed,
                menu,
              )
            }
          />
          {renderTabButton(
            { id: 'settings', label: t('settings'), icon: IconGear },
            `bg-overlay/40 w-11 shrink-0 justify-center ${collapsed ? 'h-11' : ''}`,
            true,
          )}
        </div>
      </div>
      </div>
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
        className="absolute inset-y-0 -inset-e-3.5 w-7 cursor-col-resize group/edge z-10"
      >
        <div
          className={`absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none  ${
            showKnob ? 'opacity-100' : 'opacity-0'
          }`}
        >
          <div
            className={`flex flex-col items-center ${
              knobY != null && !settings.fixed_sidebar_resize_knob
                ? ''
                : ' '
            }`}
            style={
              knobY != null && !settings.fixed_sidebar_resize_knob
                ? { transform: `translateY(${knobY}px)` }
                : undefined
            }
          >
          <div
            className={`absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 rounded-tag bg-raised border border-line shadow-md shadow-base text-3xs font-mono text-muted tabular-nums whitespace-nowrap  ${
              dragging ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-1'
            }`}
          >
            {width}px
          </div>
          <div
            className={`flex items-center justify-center w-5 h-10 rounded-full border shadow-md shadow-base  ${
            dragging
              ? 'bg-accent border-accent scale-110 shadow-accent/30'
              : 'bg-raised border-line shadow-base group-hover/edge:border-accent-dim'
          }`}
        >
            <div className="flex flex-col items-center justify-center gap-1">
          <div
            className={`w-1 h-1 rounded-full  ${
              dragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
            }`}
          />
          <div
            className={`w-1 h-1 rounded-full  ${
              dragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
            }`}
          />
          <div
            className={`w-1 h-1 rounded-full  ${
              dragging ? 'bg-white' : 'bg-line group-hover/edge:bg-accent'
            }`}
          />
            </div>
        </div>
        </div>
        </div>
      </div>
      )}
    </div>
  )
}
