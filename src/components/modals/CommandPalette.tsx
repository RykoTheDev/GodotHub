import { useState, useEffect, useRef, useMemo, useCallback } from 'react'
import { motion } from 'framer-motion'
import {
  IconBug,
  IconLayoutGrid,
  IconLayoutList,
  IconNews,
  IconGear,
  IconFolderPlus,
  IconImport,
  IconSearch,
  IconBookOpen,
  IconRefresh,
  IconBriefcase,
  IconNode,
  IconPlay,
  IconClock,
  IconCopy,
} from '../Icons'
import { getWorkspaceIcon } from '../../lib/workspaceIcons'
import { formatLastOpened } from '../../lib/lastOpened'
import type { Project, InstalledGodotVersion, Workspace } from '../../types'

interface CommandItem {
  id: string
  label: string
  shortcut?: string
  icon: React.ReactNode
  section: string
  context?: 'projects' | 'versions'
  action: () => void
}

interface DynamicItem {
  id: string
  label: string
  sublabel: string
  shortcut?: string
  icon: React.ReactNode
  section: string
  action: () => void
}

function buildCommands(mod: string, paletteKey: string): CommandItem[] {
  return [
    {
      id: 'go-projects',
      label: 'Go to Projects',
      shortcut: `${mod}1`,
      icon: <IconLayoutGrid className="w-4 h-4" />,
      section: 'Navigation',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 0 }))
      },
    },
    {
      id: 'go-versions',
      label: 'Go to Versions',
      shortcut: `${mod}2`,
      icon: <IconLayoutList className="w-4 h-4" />,
      section: 'Navigation',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 1 }))
      },
    },
    {
      id: 'go-news',
      label: 'Go to News',
      shortcut: `${mod}3`,
      icon: <IconNews className="w-4 h-4" />,
      section: 'Navigation',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 2 }))
      },
    },
    {
      id: 'go-changelog',
      label: 'Open Changelog',
      icon: <IconBookOpen className="w-4 h-4" />,
      section: 'Navigation',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 4 }))
      },
    },
    {
      id: 'go-templates',
      label: 'Go to Templates',
      shortcut: `${mod}4`,
      icon: <IconCopy className="w-4 h-4" />,
      section: 'Navigation',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 3 }))
      },
    },
    {
      id: 'go-settings',
      label: 'Open Settings',
      shortcut: `${mod},`,
      icon: <IconGear className="w-4 h-4" />,
      section: 'Navigation',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 3 }))
      },
    },

    {
      id: 'new-project',
      label: 'New Project',
      shortcut: `${mod}N`,
      icon: <IconFolderPlus className="w-4 h-4" />,
      section: 'Projects',
      context: 'projects',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:new-project-request'))
      },
    },
    {
      id: 'import-project',
      label: 'Import Project',
      icon: <IconImport className="w-4 h-4" />,
      section: 'Projects',
      context: 'projects',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:import-project-request'))
      },
    },
    {
      id: 'scan-projects',
      label: 'Scan for Projects',
      icon: <IconRefresh className="w-4 h-4" />,
      section: 'Projects',
      context: 'projects',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:scan-projects-request'))
      },
    },

    {
      id: 'create-workspace',
      label: 'Create Workspace',
      icon: <IconBriefcase className="w-4 h-4" />,
      section: 'Workspaces',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:create-workspace-request'))
      },
    },

    {
      id: 'show-shortcuts',
      label: 'Keyboard Shortcuts',
      shortcut: `${mod}${paletteKey.toUpperCase()}`,
      icon: <IconSearch className="w-4 h-4" />,
      section: 'Help',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:show-shortcuts'))
      },
    },
    {
      id: 'report-bug',
      label: 'Report a Bug',
      icon: <IconBug className="w-4 h-4" />,
      section: 'Help',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:report-bug'))
      },
    },

    {
      id: 'scan-versions',
      label: 'Scan for Engines',
      icon: <IconSearch className="w-4 h-4" />,
      section: 'Engines',
      context: 'versions',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:scan-versions'))
      },
    },
    {
      id: 'import-version',
      label: 'Import Version',
      icon: <IconImport className="w-4 h-4" />,
      section: 'Engines',
      context: 'versions',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:import-version-request'))
      },
    },

    {
      id: 'sync-templates',
      label: 'Sync Templates from Directory',
      icon: <IconRefresh className="w-4 h-4" />,
      section: 'Templates',
      action: () => {
        window.dispatchEvent(new CustomEvent('app:sync-templates-request'))
      },
    },
  ]
}

export interface SettingSearchEntry {
  key: string
  label: string
  tab: string
}

export const SETTINGS_SEARCH_ITEMS: SettingSearchEntry[] = [
  { key: 'project_scan_dirs', label: 'Project scan folders', tab: 'storage' },
  { key: 'version_scan_dirs', label: 'Version scan folders', tab: 'storage' },
  { key: 'default_project_location', label: 'Default project location', tab: 'storage' },
  { key: 'download_dir', label: 'Download folder', tab: 'storage' },
  { key: 'scan_depth', label: 'Scan depth', tab: 'storage' },
  { key: 'download_concurrency', label: 'Simultaneous downloads', tab: 'storage' },
  { key: 'close_on_project_open', label: 'Close on project open', tab: 'behavior' },
  { key: 'minimize_to_tray', label: 'Minimize to tray', tab: 'behavior' },
  { key: 'reopen_after_godot_closes', label: 'Reopen after Godot closes', tab: 'behavior' },
  { key: 'auto_scan_on_startup', label: 'Auto-scan on startup', tab: 'behavior' },
  { key: 'categories_enabled', label: 'Use categories', tab: 'behavior' },
  { key: 'workspaces_enabled', label: 'Use workspaces', tab: 'behavior' },
  { key: 'tooltip_delay', label: 'Tooltip delay', tab: 'behavior' },
  { key: 'command_palette_keybind', label: 'Command palette key', tab: 'behavior' },
  { key: 'tray_recent_projects_count', label: 'Tray recent projects count', tab: 'behavior' },
  { key: 'last_opened_time_format', label: 'Time format', tab: 'display' },
  { key: 'last_opened_date_format', label: 'Date format', tab: 'display' },
  { key: 'theme_mode', label: 'Theme mode', tab: 'appearance' },
  { key: 'accent_color', label: 'Accent color', tab: 'appearance' },
  { key: 'background_color', label: 'Background color', tab: 'appearance' },
  { key: 'corner_radius', label: 'Corner radius', tab: 'appearance' },
  { key: 'ui_density', label: 'UI density', tab: 'appearance' },
  { key: 'font_scale', label: 'Text size', tab: 'appearance' },
  { key: 'reduce_motion', label: 'Reduce motion', tab: 'appearance' },
  { key: 'feeling_lucky', label: "I'm Feeling Lucky, random colors", tab: 'appearance' },
  { key: 'reset_colors', label: 'Reset colors to default', tab: 'appearance' },
  { key: 'sidebar_width', label: 'Sidebar width', tab: 'appearance' },
  { key: 'setup_wizard', label: 'Run setup wizard', tab: 'advanced' },
  { key: 'reset_settings', label: 'Reset settings to default', tab: 'advanced' },
  { key: 'delete_app_data', label: 'Delete app data', tab: 'advanced' },
  { key: 'export_settings', label: 'Export settings to JSON', tab: 'advanced' },
  { key: 'import_settings', label: 'Import settings from JSON', tab: 'advanced' },
  { key: 'check_updates', label: 'Check for updates', tab: 'advanced' },
]

interface Props {
  onClose: () => void
  currentTab: string
  projects?: Project[]
  installedVersions?: InstalledGodotVersion[]
  workspaces?: Workspace[]
  activeWorkspaceId?: string
  paletteKey?: string
}

type ResultItem = CommandItem | DynamicItem

export function CommandPalette({
  onClose,
  currentTab,
  projects = [],
  installedVersions = [],
  workspaces = [],
  activeWorkspaceId = '',
  paletteKey = 'k',
}: Props) {
  const [query, setQuery] = useState('')
  const [selectedIndex, setSelectedIndex] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const mod = navigator.platform.includes('Mac') ? '⌘' : 'Ctrl+'
  const allCommands = useMemo(() => buildCommands(mod, paletteKey), [mod, paletteKey])

  const visibleCommands = useMemo(
    () =>
      allCommands.filter(
        (cmd) => !cmd.context || cmd.context === currentTab,
      ),
    [allCommands, currentTab],
  )

  const navShortcuts: Record<string, string> = useMemo(
    () => ({
      projects: `${mod}1`,
      versions: `${mod}2`,
      settings: `${mod},`,
    }),
    [mod],
  )

  const dynamicItems = useMemo(() => {
    const items: DynamicItem[] = []

    const recent = [...projects]
      .filter((p) => p.last_opened)
      .sort(
        (a, b) =>
          new Date(b.last_opened!).getTime() -
          new Date(a.last_opened!).getTime(),
      )
      .slice(0, 5)
    for (const p of recent) {
      items.push({
        id: `recent:${p.id}`,
        label: p.name,
        sublabel: `Opened ${formatLastOpened(p.last_opened) || 'recently'}`,
        shortcut: navShortcuts.projects,
        icon: <IconClock className="w-4 h-4" />,
        section: 'Recent',
        action: () => {
          window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 0 }))
          window.dispatchEvent(
            new CustomEvent('app:open-project', { detail: p.id }),
          )
        },
      })
    }

    for (const p of projects) {
      items.push({
        id: `project:${p.id}`,
        label: p.name,
        sublabel: p.path,
        shortcut: navShortcuts.projects,
        icon: <IconNode className="w-4 h-4" />,
        section: 'Projects',
        action: () => {
          window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 0 }))
          window.dispatchEvent(
            new CustomEvent('app:open-project', { detail: p.id }),
          )
        },
      })
    }

    for (const v of installedVersions) {
      items.push({
        id: `version:${v.tag}`,
        label: v.custom_name || v.tag,
        sublabel: v.executable_path,
        shortcut: navShortcuts.versions,
        icon: <IconPlay className="w-4 h-4" />,
        section: 'Installed Versions',
        action: () => {
          window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 1 }))
        },
      })
    }

    for (const s of SETTINGS_SEARCH_ITEMS) {
      items.push({
        id: `setting:${s.key}`,
        label: s.label,
        sublabel: `Settings → ${s.tab.charAt(0).toUpperCase() + s.tab.slice(1)}`,
        shortcut: navShortcuts.settings,
        icon: <IconGear className="w-4 h-4" />,
        section: 'Settings',
        action: () => {
          window.dispatchEvent(
            new CustomEvent('app:open-setting', { detail: s.key }),
          )
        },
      })
    }

    for (const w of workspaces) {
      const WsIcon = getWorkspaceIcon(w.icon)
      const active = w.id === activeWorkspaceId
      items.push({
        id: `workspace:${w.id}`,
        label: active ? `${w.name} (active)` : w.name,
        sublabel: active ? 'Current workspace' : 'Switch workspace',
        icon: (
          <WsIcon
            className="w-4 h-4"
            style={{ color: w.color }}
          />
        ),
        section: 'Workspaces',
        action: () => {
          window.dispatchEvent(
            new CustomEvent('app:switch-workspace', { detail: w.id }),
          )
        },
      })
    }

    return items
  }, [projects, installedVersions, workspaces, activeWorkspaceId])

  const allItems = useMemo(
    () => [...visibleCommands, ...dynamicItems],
    [visibleCommands, dynamicItems],
  )

  const filteredSections = useMemo(() => {
    const q = query.trim().toLowerCase()
    const results = q
      ? allItems.filter((item) => {
          const label = 'label' in item ? item.label.toLowerCase() : ''
          const sublabel = 'sublabel' in item
            ? (item as DynamicItem).sublabel.toLowerCase()
            : ''
          const section = item.section.toLowerCase()
          return (
            label.includes(q) ||
            sublabel.includes(q) ||
            section.includes(q)
          )
        })
      : allItems

    const sections = new Map<string, ResultItem[]>()
    for (const item of results) {
      if (!sections.has(item.section)) sections.set(item.section, [])
      sections.get(item.section)!.push(item)
    }
    return [...sections.entries()]
  }, [query, allItems])

  useEffect(() => {
    setSelectedIndex(0)
  }, [filteredSections])

  const flatList = useMemo(
    () => filteredSections.flatMap(([, items]) => items),
    [filteredSections],
  )

  const executeSelected = useCallback(() => {
    const item = flatList[selectedIndex]
    if (item) {
      item.action()
      onClose()
    }
  }, [flatList, selectedIndex, onClose])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        setSelectedIndex((i) => Math.min(i + 1, flatList.length - 1))
        break
      case 'ArrowUp':
        e.preventDefault()
        setSelectedIndex((i) => Math.max(i - 1, 0))
        break
      case 'Enter':
        e.preventDefault()
        executeSelected()
        break
      case 'Escape':
        e.preventDefault()
        onClose()
        break
    }
  }

  useEffect(() => {
    if (!listRef.current) return
    const item = listRef.current.querySelector(`[data-index="${selectedIndex}"]`)
    if (item) {
      item.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
    }
  }, [selectedIndex])

  let itemIndex = 0

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.12 }}
      className="fixed inset-0 z-100 flex items-start justify-center pt-[12vh]"
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />

      <motion.div
        initial={{ opacity: 0, y: -12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: -12, scale: 0.96 }}
        transition={{ type: 'spring', stiffness: 400, damping: 30 }}
        className="relative w-full max-w-lg bg-surface border border-line rounded-2xl shadow-2xl shadow-black/60 overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 px-4 py-3 border-b border-line">
          <IconSearch
            fill="none"
            className="w-4 h-4 shrink-0 text-muted/60"
          />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search commands, projects, engines, settings…"
            className="flex-1 bg-transparent text-sm text-ink outline-none placeholder:text-muted/50"
          />
          <kbd className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-raised border border-line text-muted/60 shrink-0">
            ESC
          </kbd>
        </div>

        <div
          ref={listRef}
          className="max-h-[50vh] overflow-y-auto p-2"
        >
          {flatList.length === 0 ? (
            <div className="py-8 text-center">
              <p className="text-xs text-muted">
                No results match{' '}
                <span className="font-mono text-ink">"{query}"</span>
              </p>
            </div>
          ) : (
            filteredSections.map(([section, items]) => (
              <div key={section}>
                <div className="px-2 py-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted/50">
                  {section}
                </div>
                {items.map((item) => {
                  const idx = itemIndex++
                  const selected = selectedIndex === idx
                  const isDynamic = 'sublabel' in item
                  const shortcut =
                    'shortcut' in item ? item.shortcut : undefined
                  return (
                    <button
                      key={item.id}
                      data-index={idx}
                      onClick={() => {
                        item.action()
                        onClose()
                      }}
                      onMouseEnter={() => setSelectedIndex(idx)}
                      className={`focus-ring cursor-pointer w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-colors ${
                        selected
                          ? 'bg-accent/15 text-ink'
                          : 'text-muted hover:text-ink hover:bg-raised'
                      }`}
                    >
                      <span
                        className={`shrink-0 ${selected ? 'text-accent-bright' : 'text-muted/70'}`}
                      >
                        {item.icon}
                      </span>
                      <div className="flex-1 text-left min-w-0">
                        <span className="block truncate">{item.label}</span>
                        {isDynamic && (
                          <span className="block text-[10px] text-muted/50 truncate">
                            {(item as DynamicItem).sublabel}
                          </span>
                        )}
                      </div>
                      {shortcut && (
                        <kbd className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-raised border border-line text-muted/50 shrink-0">
                          {shortcut}
                        </kbd>
                      )}
                    </button>
                  )
                })}
              </div>
            ))
          )}
        </div>

        <div className="px-4 py-2 border-t border-line flex items-center gap-4 text-[10px] text-muted/50">
          <span>
            <kbd className="font-mono px-1 bg-raised rounded border border-line">↑↓</kbd>{' '}
            Navigate
          </span>
          <span>
            <kbd className="font-mono px-1 bg-raised rounded border border-line">↵</kbd>{' '}
            Select
          </span>
          <span>
            <kbd className="font-mono px-1 bg-raised rounded border border-line">Esc</kbd>{' '}
            Close
          </span>
        </div>
      </motion.div>
    </motion.div>
  )
}
