import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import { useTranslation } from 'react-i18next'
import { useProjectsContext } from '../hooks/projectsContext'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { useCategoriesContext } from '../hooks/categoriesContext'

import {
  IconArrowUpDown,
  IconCheck,
  IconChevronDown,
  IconClock,
  IconEyeSlash,
  IconFilter,
  IconFolder,
  IconGitBranch,
  IconHardDrive,
  IconKanban,
  IconLayoutGrid,
  IconLayoutList,
  IconNode,
  IconPin,
  IconPlay,
  IconPlus,
  IconStopwatch,
  IconTags,
  IconTerminal,
  IconTrash,
  IconX,
} from '../lib/icons'
import { tagColor } from '../lib/colors'
import { kanbanColumnOrder } from '../lib/projectDrag'
import { Toggle } from '../components/ui/Toggle'
import {
  getCardViewSettings,
  setCardViewOverride,
} from '../lib/cardViewSettings'
import { Dropdown } from '../components/ui/Dropdown'
import { ContextMenu } from '../components/ui/ContextMenu'
import type { MenuItem } from '../components/ui/menu'
import type { HiddenCategoryEntry } from '../components/cards/CategorySections'
import { ImportButton } from '../components/reusables/ImportButton'
import { Tooltip } from '../components/reusables/Tooltip'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ProjectCard } from '../components/cards/ProjectCard'
import { ProjectCardList } from '../components/cards/ProjectCardList'
import { ProjectCardKanban } from '../components/cards/ProjectCardKanban'
import { ProjectCardGrid } from '../components/cards/ProjectCardGrid'
import { uiPrefs } from '../lib/uiPrefs'

type ProjectViewMode = 'list' | 'grid' | 'kanban'

const PROJECT_FIELD_ICONS: Record<ProjectSearchField, typeof IconNode> = {
  name: IconNode,
  tag: IconTags,
  category: IconFilter,
  version: IconGitBranch,
  path: IconFolder,
  pinned: IconPin,
}

const VIEW_MODE_OPTIONS: {
  value: ProjectViewMode
  labelKey: string
  icon: typeof IconLayoutList
}[] = [
  { value: 'list', labelKey: 'view_list', icon: IconLayoutList },
  { value: 'grid', labelKey: 'view_grid', icon: IconLayoutGrid },
  { value: 'kanban', labelKey: 'view_kanban', icon: IconKanban },
]

const CARD_TOGGLE_OPTIONS: {
  key: keyof ReturnType<typeof getCardViewSettings>
  icon: typeof IconHardDrive
  labelKey: string
}[] = [
  { key: 'show_size', icon: IconHardDrive, labelKey: 'customize_card_show_size' },
  { key: 'show_time', icon: IconStopwatch, labelKey: 'customize_card_show_time' },
  { key: 'show_session_timer', icon: IconStopwatch, labelKey: 'customize_card_show_session_timer' },
  { key: 'blur_path', icon: IconEyeSlash, labelKey: 'customize_card_blur_path' },
  { key: 'show_path', icon: IconFolder, labelKey: 'customize_card_show_path' },
  { key: 'show_tags', icon: IconTags, labelKey: 'customize_card_show_tags' },
  { key: 'show_last_opened', icon: IconClock, labelKey: 'customize_card_show_last_opened' },
  { key: 'show_play', icon: IconPlay, labelKey: 'customize_card_show_play' },
  { key: 'show_console', icon: IconTerminal, labelKey: 'customize_card_show_console' },
]

interface SlashMenuState {
  mode: 'field' | 'value'
  title: string
  footer?: string
  items: SlashMenuItem[]
  emptyLabel: string
  token: ProjectSearchToken
}
import { useSettings } from '../hooks/useSettings'
import { useScrollCompensation } from '../hooks/useScrollCompensation'
import { api } from '../lib/api'
import { pushToast, reportError } from '../lib/toast'
import type { Category, Project } from '../types'
import {
  comparatorFor,
  SORT_OPTIONS,
  type ProjectSortOption,
} from '../lib/projectSort'
import { ScanButton } from '../components/reusables/ScanButton'
import { SearchBar } from '../components/ui/SearchBar'
import { SlashMenu, type SlashMenuItem } from '../components/ui/SlashMenu'
import {
  collectTags,
  collectVersions,
  matchProject,
  parseProjectQuery,
  replaceToken,
  type ProjectSearchField,
  type ProjectSearchToken,
} from '../lib/projectSearch'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { Disclosure } from '../components/reusables/Disclosure'
import { spin } from '../lib/motion'
import { useGitStatusMap } from '../hooks/useGitStatusMap'
import { CreateProjectModal } from '../components/modals/CreateProjectModal'
import { CloneRepoModal } from '../components/modals/CloneRepoModal'
import { BulkTagModal } from '../components/modals/BulkTagModal'
import { DuplicateProjectModal } from '../components/modals/DuplicateProjectModal'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { CategoryManagerModal } from '../components/modals/CategoryManagerModal'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'

export function ProjectsView({
  onOpenSettings,
  connected = false,
  gitSidebarOpen = false,
  active = true,
}: {
  onOpenSettings?: () => void
  connected?: boolean
  gitSidebarOpen?: boolean
  active?: boolean
}) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')

  const {
    projects,
    error,
    refresh,
    remove,
    updateVersion,
    setPinned,
    updateTags,
    setCategory,
    reorder,
    moveProjects,
  } = useProjectsContext()
  const {
    categories,
    create: createCategory,
    update: updateCategory,
    remove: removeCategory,
    reorder: reorderCategories,
    setHidden: setCategoryHidden,
    assignFolder: assignCategoryFolder,
    unassignFolder: unassignCategoryFolder,
  } = useCategoriesContext()
  const installed = useGodotVersionsContext((v) => v.installed)
  const { settings, update } = useSettings()
  const searchRef = useRef<HTMLInputElement | null>(null)
  const [createProjectOpen, setCreateProjectOpen] = useState(false)
  const [cloneRepoOpen, setCloneRepoOpen] = useState(false)
  const [categoryManagerOpen, setCategoryManagerOpen] = useState(false)
  const [categoryMenu, setCategoryMenu] = useState<{
    x: number
    y: number
    category: Category
  } | null>(null)
  const [query, setQuery] = useState('')
  const [caret, setCaret] = useState(0)
  const [menuIndex, setMenuIndex] = useState(0)
  const [menuDismissed, setMenuDismissed] = useState(false)

  const parsedQuery = useMemo(
    () => parseProjectQuery(query, caret),
    [query, caret],
  )

  const handleQueryChange = (value: string) => {
    setQuery(value)
    setCaret(searchRef.current?.selectionStart ?? value.length)
    setMenuDismissed(false)
    setMenuIndex(0)
  }

  const allTags = useMemo(() => collectTags(projects), [projects])
  const allVersions = useMemo(() => collectVersions(projects), [projects])

  const fieldLabels = useMemo<Record<ProjectSearchField, string>>(
    () => ({
      name: tc('search_filter_name'),
      tag: tc('search_filter_tag'),
      category: tc('category'),
      version: tc('search_filter_version'),
      path: tc('search_filter_path'),
      pinned: tc('pinned_section'),
    }),
    [tc],
  )

  const slashMenu = useMemo<SlashMenuState | null>(() => {
    if (menuDismissed) return null
    const token = parsedQuery.activeToken
    if (!token) return null

    if (token.field) {
      if (token.field === 'name' || token.field === 'path') return null
      const partial = token.value.trim().toLowerCase()
      let items: SlashMenuItem[] = []
      if (token.field === 'tag') {
        items = allTags
          .filter((tag) => tag.toLowerCase().includes(partial))
          .map((tag) => ({
            key: `tag:${tag}`,
            label: tag,
            hint: 'tag',
            icon: IconTags,
          }))
      } else if (token.field === 'category') {
        items = categories
          .filter((cat) => cat.name.toLowerCase().includes(partial))
          .map((cat) => ({
            key: `category:${cat.name}`,
            label: cat.name,
            hint: 'category',
            dotColor: cat.color,
          }))
      } else if (token.field === 'version') {
        items = allVersions
          .filter((version) => version.toLowerCase().includes(partial))
          .map((version) => ({
            key: `version:${version}`,
            label: version,
            hint: 'version',
            icon: IconGitBranch,
          }))
      } else {
        items = [
          {
            key: 'pinned:true',
            label: tc('search_filter_pinned_yes'),
            hint: 'true',
            icon: IconPin,
          },
          {
            key: 'pinned:false',
            label: tc('search_filter_pinned_no'),
            hint: 'false',
            icon: IconPin,
          },
        ].filter(
          (item) =>
            !partial ||
            item.label.toLowerCase().includes(partial) ||
            item.key.includes(partial),
        )
      }
      return {
        mode: 'value',
        title: fieldLabels[token.field],
        items,
        emptyLabel: tc('search_filter_no_values'),
        token,
      }
    }

    if (!token.raw.startsWith('/')) return null
    const partial = token.raw.slice(1).toLowerCase()
    const fields: ProjectSearchField[] = [
      'name',
      'tag',
      'category',
      'version',
      'path',
      'pinned',
    ]
    const items: SlashMenuItem[] = fields
      .filter(
        (field) =>
          !partial ||
          field.startsWith(partial) ||
          fieldLabels[field].toLowerCase().startsWith(partial),
      )
      .map((field) => ({
        key: field,
        label: fieldLabels[field],
        hint: `${field}:`,
        icon: PROJECT_FIELD_ICONS[field],
      }))
    return {
      mode: 'field',
      title: tc('search_filter_title'),
      footer: tc('search_slash_hint'),
      items,
      emptyLabel: tc('search_filter_no_matches'),
      token,
    }
  }, [
    menuDismissed,
    parsedQuery.activeToken,
    allTags,
    allVersions,
    categories,
    fieldLabels,
    tc,
  ])

  const applySlashItem = (item: SlashMenuItem) => {
    if (!slashMenu) return
    const replacement =
      slashMenu.mode === 'field'
        ? item.key === 'name' || item.key === 'path'
          ? `${item.key}: `
          : `${item.key}:`
        : `${item.key} `
    const next = replaceToken(query, slashMenu.token, replacement)
    setQuery(next.value)
    setCaret(next.caret)
    setMenuIndex(0)
    requestAnimationFrame(() => {
      const el = searchRef.current
      if (!el) return
      el.focus()
      el.setSelectionRange(next.caret, next.caret)
    })
  }

  const handleSearchKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (slashMenu && slashMenu.items.length > 0) {
      const count = slashMenu.items.length
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setMenuIndex((i) => (i + 1) % count)
        return
      }
      if (e.key === 'ArrowUp') {
        e.preventDefault()
        setMenuIndex((i) => (i - 1 + count) % count)
        return
      }
      if (e.key === 'Enter' || e.key === 'Tab') {
        e.preventDefault()
        applySlashItem(slashMenu.items[Math.min(menuIndex, count - 1)])
        return
      }
    } else if (e.key === 'Enter') {
      e.preventDefault()
      setCaret(searchRef.current?.selectionStart ?? query.length)
      setMenuDismissed(true)
      return
    }
    if (e.key === 'Escape' && slashMenu) {
      e.preventDefault()
      setMenuDismissed(true)
    }
  }

  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())

  const [bulkTagsOpen, setBulkTagsOpen] = useState(false)
  const [duplicateProject, setDuplicateProject] = useState<Project | null>(null)
  const [confirmBatchAction, setConfirmBatchAction] = useState<
    'remove' | 'delete' | null
  >(null)
  const [viewMode, setViewMode] = useState<ProjectViewMode>(() => {
    try {
      const raw = uiPrefs.getItem('godothub_projects_view_mode')
      if (raw === 'list' || raw === 'grid' || raw === 'kanban') return raw
    } catch {}
    return 'list'
  })
  useEffect(() => {
    try {
      uiPrefs.setItem('godothub_projects_view_mode', viewMode)
    } catch {}
  }, [viewMode])
  useEffect(() => {
    const handler = (e: Event) => {
      const mode = (e as CustomEvent<ProjectViewMode>).detail
      if (mode === 'list' || mode === 'grid' || mode === 'kanban') {
        setViewMode(mode)
      }
    }
    window.addEventListener('app:switch-view', handler)
    return () => window.removeEventListener('app:switch-view', handler)
  }, [])
  useEffect(() => {
    if (!settings.customize_view_enabled) {
      setViewMode('list')
    }
  }, [settings.customize_view_enabled])
  const [tagFilter, setTagFilter] = useState<string | null>(() => {
    try {
      const raw = sessionStorage.getItem('godothub_projects_tag_filter')
      if (raw) return raw
    } catch {}
    return null
  })
  const UNCATEGORIZED = '__uncategorized__'
  const [categoryFilter, setCategoryFilter] = useState<string | null>(() => {
    try {
      const raw = sessionStorage.getItem('godothub_projects_category_filter')
      if (raw === UNCATEGORIZED) return ''
      if (raw) return raw
    } catch {}
    return null
  })

  const [sortBy, setSortBy] = useState<ProjectSortOption>(() => {
    try {
      const raw = uiPrefs.getItem('godothub_projects_sort_by')
      if (raw) return raw as ProjectSortOption
    } catch {}
    return 'categories'
  })
  const [sortNow, setSortNow] = useState(() => Date.now())
  useEffect(() => {
    if (!active || sortBy !== 'time_desc') return
    if (!projects.some((p) => p.session_started_at_ms)) return
    setSortNow(Date.now())
    const id = setInterval(() => {
      if (!document.hidden) setSortNow(Date.now())
    }, 30_000)
    return () => clearInterval(id)
  }, [active, sortBy, projects])
  const { viewportRef, restoreScroll } = useScrollCompensation()
  const pinnedSignature = useMemo(
    () => projects.filter((p) => p.pinned).map((p) => p.id).join(','),
    [projects],
  )
  useLayoutEffect(() => {
    restoreScroll()
  }, [pinnedSignature, tagFilter, restoreScroll])
  const projectsRef = useRef(projects)
  projectsRef.current = projects
  const projectPathsKey = useMemo(
    () => projects.map((p) => p.path).join('|'),
    [projects],
  )

  const projectPaths = useMemo(() => (projectPathsKey ? projectPathsKey.split('|') : []), [projectPathsKey])
  const { statusMap: gitStatusMap, loading: gitStatusLoading } = useGitStatusMap(projectPaths, active)

  useEffect(() => {
    try {
      uiPrefs.setItem('godothub_projects_sort_by', sortBy)
    } catch {}
  }, [sortBy])

  useEffect(() => {
    try {
      if (tagFilter) {
        sessionStorage.setItem('godothub_projects_tag_filter', tagFilter)
      } else {
        sessionStorage.removeItem('godothub_projects_tag_filter')
      }
    } catch {}
  }, [tagFilter])

  useEffect(() => {
    try {
      if (categoryFilter !== null) {
        if (categoryFilter === '') {
          sessionStorage.setItem('godothub_projects_category_filter', UNCATEGORIZED)
        } else {
          sessionStorage.setItem('godothub_projects_category_filter', categoryFilter)
        }
      } else {
        sessionStorage.removeItem('godothub_projects_category_filter')
      }
    } catch {}
  }, [categoryFilter])

  useEffect(() => {
    try {
      uiPrefs.removeItem('godothub_projects_tag_filter')
    } catch {}
  }, [])

  useEffect(() => {
    if (tagFilter && !projects.some((p) => p.tags.includes(tagFilter))) {
      setTagFilter(null)
    }
  }, [projects, tagFilter])

  useEffect(() => {
    if (!settings.categories_enabled && categoryFilter !== null) {
      setCategoryFilter(null)
    }
  }, [settings.categories_enabled, categoryFilter])

  useEffect(() => {
    if (categoryFilter === null || categoryFilter === '') return
    const match = categories.find((c) => c.name === categoryFilter)
    if (!match || match.hidden) {
      setCategoryFilter(null)
    }
  }, [categories, categoryFilter])

  const searchScores = useMemo(() => {
    const scores = new Map<string, number>()
    if (!parsedQuery.active) return scores
    for (const project of projects) {
      const score = matchProject(project, parsedQuery)
      if (score !== null) scores.set(project.id, score)
    }
    return scores
  }, [projects, parsedQuery])

  const baseFiltered = useMemo(() => {
    let list = projects
    if (parsedQuery.active) {
      list = list.filter((p) => searchScores.has(p.id))
    }
    if (tagFilter) {
      list = list.filter((p) => p.tags.includes(tagFilter))
    }
    if (categoryFilter !== null) {
      if (categoryFilter === '') {
        list = list.filter((p) => !p.category)
      } else {
        list = list.filter((p) => (p.category ?? '') === categoryFilter)
      }
    }
    return list
  }, [projects, searchScores, parsedQuery.active, tagFilter, categoryFilter])

  const effectiveSortBy: ProjectSortOption =
    sortBy === 'categories' && !settings.categories_enabled ? 'manual' : sortBy

  const categoriesEnabled =
    settings.categories_enabled && effectiveSortBy === 'categories'

  const groupingEnabled = categoriesEnabled && !parsedQuery.active

  const visibleCategories = useMemo(
    () => categories.filter((c) => !c.hidden),
    [categories],
  )

  const hiddenCategories = useMemo<HiddenCategoryEntry[]>(() => {
    const hidden = categories.filter((c) => c.hidden)
    if (hidden.length === 0) return []
    const counts = new Map<string, number>()
    for (const p of baseFiltered) {
      if (!p.category) continue
      counts.set(p.category, (counts.get(p.category) ?? 0) + 1)
    }
    return hidden.map((category) => ({
      category,
      count: counts.get(category.name) ?? 0,
    }))
  }, [categories, baseFiltered])

  const hiddenCategoryNames = useMemo(
    () => new Set(hiddenCategories.map((h) => h.category.name)),
    [hiddenCategories],
  )

  const surfaceCategories = useMemo(
    () => (settings.categories_enabled ? visibleCategories : []),
    [settings.categories_enabled, visibleCategories],
  )

  const hiddenEntries = categoriesEnabled ? hiddenCategories : []

  const filtered = useMemo(() => {
    const list =
      groupingEnabled && hiddenCategoryNames.size > 0
        ? baseFiltered.filter(
            (p) => !p.category || !hiddenCategoryNames.has(p.category),
          )
        : baseFiltered
    const cmp = comparatorFor(effectiveSortBy, sortNow)
    return [...list].sort((a, b) => {
      if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
      if (a.pinned) return a.sort_order - b.sort_order || a.name.localeCompare(b.name)
      if (parsedQuery.active) {
        const scoreA = searchScores.get(a.id) ?? 0
        const scoreB = searchScores.get(b.id) ?? 0
        if (scoreA !== scoreB) return scoreB - scoreA
      }
      return cmp ? cmp(a, b) : a.sort_order - b.sort_order
    })
  }, [
    baseFiltered,
    groupingEnabled,
    hiddenCategoryNames,
    effectiveSortBy,
    sortNow,
    parsedQuery.active,
    searchScores,
  ])

  const hasActiveFilters =
    query.trim() !== '' || tagFilter !== null || categoryFilter !== null

  const dragEnabled = !hasActiveFilters

  const visualOrder = useMemo(() => {
    if (viewMode === 'kanban') return kanbanColumnOrder(filtered, surfaceCategories)
    if (!groupingEnabled) return filtered
    const pinned = filtered.filter((p) => p.pinned)
    const unpinned = filtered.filter((p) => !p.pinned)
    const UNCATEGORIZED_KEY = '__uncategorized__'
    const groups = new Map<string, Project[]>()
    for (const p of unpinned) {
      const cat = p.category || UNCATEGORIZED_KEY
      if (!groups.has(cat)) groups.set(cat, [])
      groups.get(cat)!.push(p)
    }
    const ordered: Project[] = [...pinned]
    for (const cat of visibleCategories) {
      const projs = groups.get(cat.name)
      if (projs) ordered.push(...projs)
    }
    const uncategorized = groups.get(UNCATEGORIZED_KEY)
    if (uncategorized) ordered.push(...uncategorized)
    return ordered
  }, [filtered, groupingEnabled, visibleCategories, viewMode, surfaceCategories])

  const lastClickedIndexRef = useRef<number | null>(null)

  const toggleSelect = useCallback((id: string, e?: React.MouseEvent) => {
    const clickedIndex = visualOrder.findIndex((p) => p.id === id)

    if (e?.shiftKey && lastClickedIndexRef.current !== null) {
      const start = Math.min(lastClickedIndexRef.current, clickedIndex)
      const end = Math.max(lastClickedIndexRef.current, clickedIndex)
      const rangeIds = visualOrder.slice(start, end + 1).map((p) => p.id)
      setSelectedIds((prev) => {
        const next = new Set(prev)
        for (const rid of rangeIds) next.add(rid)
        return next
      })
    } else if (e?.ctrlKey || e?.metaKey) {
      setSelectedIds((prev) => {
        const next = new Set(prev)
        if (next.has(id)) {
          next.delete(id)
        } else {
          next.add(id)
        }
        return next
      })
    } else {
      setSelectedIds((prev) => {
        const next = new Set(prev)
        if (next.has(id)) {
          next.delete(id)
        } else {
          next.add(id)
        }
        return next
      })
    }
    lastClickedIndexRef.current = clickedIndex
  }, [visualOrder])

  const clearSelection = useCallback(() => {
    setSelectedIds(new Set())
    lastClickedIndexRef.current = null
  }, [])

  useEffect(() => {
    if (active) return
    clearSelection()
  }, [active, clearSelection])

  const lastSelectionCount = useRef(0)
  if (selectedIds.size > 0) lastSelectionCount.current = selectedIds.size
  const shownSelectionCount = selectedIds.size || lastSelectionCount.current

  const allVisibleSelected =
    filtered.length > 0 && filtered.every((p) => selectedIds.has(p.id))

  const toggleSelectAllVisible = useCallback(() => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (allVisibleSelected) {
        for (const p of filtered) next.delete(p.id)
      } else {
        for (const p of filtered) next.add(p.id)
      }
      return next
    })
  }, [allVisibleSelected, filtered])

  const batchLaunch = useCallback(() => {
    for (const id of selectedIds) {
      window.dispatchEvent(
        new CustomEvent('app:open-project', {
          detail: { id, console: settings.launch_with_console },
        }),
      )
    }
    clearSelection()
  }, [selectedIds, settings.launch_with_console, clearSelection])

  const batchPin = useCallback(() => {
    const ids = [...selectedIds]
    const allPinned = ids.every(
      (id) => projects.find((p) => p.id === id)?.pinned,
    )
    for (const id of ids) setPinned(id, !allPinned)
    clearSelection()
  }, [selectedIds, projects, setPinned, clearSelection])

  const reimportForUndo = useCallback(
    async (removed: Project[]) => {
      await Promise.all(
        removed.map((p) =>
          api.importProject(p.path, p.godot_version, p.category).catch(reportError),
        ),
      )
      await refresh()
    },
    [refresh],
  )

  const removeWithUndo = useCallback(
    async (id: string, deleteFiles: boolean) => {
      if (deleteFiles) {
        await remove(id, true)
        return
      }
      const target = projects.find((p) => p.id === id)
      await remove(id, false)
      if (!target) return
      pushToast('info', tc('removed_from_library', { count: 1 }), 6000, {
        label: tc('undo'),
        onClick: () => reimportForUndo([target]),
      })
    },
    [projects, remove, tc, reimportForUndo],
  )

  const executeBatchRemove = useCallback(async () => {
    setConfirmBatchAction(null)
    const targets = [...selectedIds]
      .map((id) => projects.find((p) => p.id === id))
      .filter((p): p is Project => !!p)
    for (const p of targets) await remove(p.id, false)
    clearSelection()
    if (targets.length > 0) {
      pushToast('info', tc('removed_from_library', { count: targets.length }), 6000, {
        label: tc('undo'),
        onClick: () => reimportForUndo(targets),
      })
    }
  }, [selectedIds, projects, remove, clearSelection, tc, reimportForUndo])

  const executeBatchDelete = useCallback(async () => {
    setConfirmBatchAction(null)
    for (const id of selectedIds) await remove(id, true)
    clearSelection()
  }, [selectedIds, remove, clearSelection])

  const handleLaunchArgsChange = useCallback(async (id: string, args: string) => {
    await api.updateProject(id, { launch_arguments: args })
    await refresh()
  }, [refresh])

  const handleListReorder = useCallback(
    async (orderedIds: string[]) => {
      if (!categoriesEnabled) setSortBy('manual')
      await reorder(orderedIds)
    },
    [categoriesEnabled, reorder],
  )

  const handleKanbanReorder = useCallback(
    async (orderedIds: string[]) => {
      setSortBy(settings.categories_enabled ? 'categories' : 'manual')
      await reorder(orderedIds)
    },
    [settings.categories_enabled, reorder],
  )

  const handleMoveProjects = useCallback(
    async (ids: string[], category: string, destOrderedIds: string[]) => {
      setSortBy(settings.categories_enabled ? 'categories' : 'manual')
      await moveProjects(ids, category, destOrderedIds)
    },
    [settings.categories_enabled, moveProjects],
  )

  const openCategoryMenu = useCallback(
    (e: React.MouseEvent<HTMLElement>, category: Category) => {
      setCategoryMenu({ x: e.clientX, y: e.clientY, category })
    },
    [],
  )

  const hideCategory = useCallback(
    async (category: Category) => {
      setSelectedIds((prev) => {
        if (prev.size === 0) return prev
        const next = new Set(prev)
        for (const p of projects) {
          if ((p.category ?? '') === category.name) next.delete(p.id)
        }
        return next
      })
      await setCategoryHidden(category.id, true)
      pushToast('info', tc('category_hidden_toast', { name: category.name }))
    },
    [projects, setCategoryHidden, tc],
  )

  const unhideCategory = useCallback(
    async (id: string) => {
      await setCategoryHidden(id, false)
    },
    [setCategoryHidden],
  )

  const categoryMenuItems: MenuItem[] = categoryMenu
    ? [
        {
          key: 'hide-category',
          label: tc('hide_category'),
          icon: IconEyeSlash,
          onClick: () => void hideCategory(categoryMenu.category),
        },
      ]
    : []

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && selectedIds.size > 0) clearSelection()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [selectedIds.size, clearSelection])

  useEffect(() => {
    const focusSearch = () => searchRef.current?.focus()
    const launchSelection = () => {
      if (selectedIds.size > 0) batchLaunch()
    }
    const deleteSelection = () => {
      if (selectedIds.size > 0) setConfirmBatchAction('remove')
    }
    const setCategoryFilterEvent = (e: Event) => {
      const detail = (e as CustomEvent).detail as string | undefined
      if (typeof detail !== 'string') return
      setCategoryFilter(detail === '' ? null : detail)
      clearSelection()
    }
    window.addEventListener('app:focus-search', focusSearch)
    window.addEventListener('app:launch-selection', launchSelection)
    window.addEventListener('app:delete-selection', deleteSelection)
    window.addEventListener('app:set-category-filter', setCategoryFilterEvent)
    return () => {
      window.removeEventListener('app:focus-search', focusSearch)
      window.removeEventListener('app:launch-selection', launchSelection)
      window.removeEventListener('app:delete-selection', deleteSelection)
      window.removeEventListener('app:set-category-filter', setCategoryFilterEvent)
    }
  }, [selectedIds.size, batchLaunch, clearSelection])

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <div className="shrink-0 flex flex-col gap-2">
      <ViewHeader
        connected={connected}
        title={t('projects')}
        leadingAction={
          <button
            type="button"
            onClick={(e) => {
              spin(e.currentTarget.querySelector('svg'))
              setCreateProjectOpen(true)
            }}
            aria-label={tc('new_project')}
            className="group h-9 min-w-9 ps-2 cursor-pointer inline-flex items-center justify-start rounded-full bg-accent text-ink hover:bg-accent-bright "
          >
            <IconPlus className="w-5 h-5 shrink-0 transition-[rotate,transform] duration-500 ease-spring group-hover:rotate-90" strokeWidth={3} />
            <span className="grid grid-cols-[0fr] group-hover:grid-cols-[1fr] transition-[grid-template-columns] duration-500 ease-out-expo">
              <span className="overflow-hidden">
                <span className="block whitespace-nowrap ps-1 pe-3 text-sm font-semibold opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-[opacity,translate] duration-500 ease-out-expo">
                  {tc('new')}
                </span>
              </span>
            </span>
          </button>
        }
        metric={
          <>
            <h2 className="text-4xl font-bold text-muted">
              <AnimatedNumber value={filtered.length} />
            </h2>
            <p className="text-lg font-medium uppercase text-muted">
              {t('projects_count', { count: filtered.length })}
            </p>
          </>
        }
        actions={
          <>
            <ImportButton
              onImport={async (folder) => {
                await api.importProject(folder, '')
                await refresh()
              }}
              options={[
                {
                  key: 'clone-repo',
                  label: tc('clone_import_repo'),
                  icon: IconGitBranch,
                  onClick: () => setCloneRepoOpen(true),
                },
              ]}
            />
            <ScanButton
              onOpenSettings={onOpenSettings}
              scanDirs={settings.project_scan_dirs}
              scan={() =>
                api.scanForProjectsWithInfo(
                  settings.project_scan_dirs,
                  settings.scan_depth,
                )
              }
              onComplete={() => refresh().catch(() => {})}
              onReadd={(paths) =>
                api
                  .reintroduceDismissedProjects(paths)
                  .then(() => refresh().catch(() => {}))
              }
            />
            {settings.categories_enabled && (
              <Tooltip content={tc('manage_categories')} side="bottom">
                <button
                  type="button"


                  onClick={() => setCategoryManagerOpen(true)}
                  aria-label={tc('manage_categories')}
                  className="focus-ring cursor-pointer inline-flex items-center justify-center shadow-md shadow-black/10 border border-outline/50 w-10 h-10 shrink-0 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised "
              >
                  <IconTags className="w-4 h-4" />
                </button>
              </Tooltip>
            )}
          </>
        }
      >
        <SearchBar
          value={query}
          onChange={handleQueryChange}
          onKeyDown={handleSearchKeyDown}
          onCaretChange={setCaret}
          onBlur={() => setMenuDismissed(true)}
          inputRef={searchRef}
        >
          {slashMenu && (
            <SlashMenu
              title={slashMenu.title}
              footer={slashMenu.footer}
              items={slashMenu.items}
              selectedIndex={Math.min(
                menuIndex,
                Math.max(0, slashMenu.items.length - 1),
              )}
              emptyLabel={slashMenu.emptyLabel}
              onSelect={applySlashItem}
              onHighlight={setMenuIndex}
            />
          )}
        </SearchBar>
      </ViewHeader>

      <div className={`shrink-0 flex items-center gap-2 mb-3 ${connected ? 'ps-5' : ''}`}>
        <Dropdown
          align="left"
          trigger={({ open, toggle }) => {
            const defaultSort: ProjectSortOption = settings.categories_enabled
              ? 'categories'
              : 'manual'
            const isCustomSort = effectiveSortBy !== defaultSort
            const activeSortLabel = SORT_OPTIONS.find(
              (o) => o.value === effectiveSortBy,
            )
            return (
              <button
                type="button"
                aria-expanded={open}


                onClick={toggle}
                className={`focus-ring cursor-pointer flex items-center justify-center gap-1 h-8 px-4 rounded-item  ${
                  isCustomSort
                    ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
                    : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
                }`}
              >
                <IconArrowUpDown className="w-3 h-3 shrink-0" />
                <span className="flex min-w-0 items-baseline gap-1">
                  <span className="text-base font-medium text-ink">{tc('sort')}</span>
                  {activeSortLabel && (
                    <span className="text-xs tabular-nums text-muted max-w-30 truncate">
                      {tc(activeSortLabel.labelKey)}
                    </span>
                  )}
                </span>
              </button>
            )
          }}
          items={SORT_OPTIONS.filter(
            (opt) => opt.value !== 'categories' || settings.categories_enabled,
          ).map((opt) => ({
            key: opt.value,
            label: tc(opt.labelKey),
            active: opt.value === effectiveSortBy,
            onClick: () => setSortBy(opt.value),
          }))}
        />

        {settings.categories_enabled && (
          <Dropdown
            align="left"
            trigger={({ open, toggle }) => {
              const hasCategoryFilter = categoryFilter !== null
              const activeLabel =
                categoryFilter === ''
                  ? tc('uncategorized')
                  : categoryFilter
              return (
                <button
                  type="button"
                  aria-expanded={open}


                  onClick={toggle}
                  className={`focus-ring cursor-pointer flex items-center justify-center gap-1 h-8 px-4 rounded-item  ${
                    hasCategoryFilter
                      ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
                      : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
                  }`}
                >
                  <IconFilter className="w-3 h-3 shrink-0" />
                  <span className="flex min-w-0 items-baseline gap-1">
                    <span className="text-base font-medium text-ink">{tc('filter')}</span>
                    {hasCategoryFilter && (
                      <span className="text-xs tabular-nums text-muted max-w-30 truncate">
                        {activeLabel}
                      </span>
                    )}
                  </span>
                </button>
              )
            }}
            items={[
              {
                key: 'filter-all',
                label: tc('no_filter'),
                active: categoryFilter === null,
                onClick: () => setCategoryFilter(null),
              },
              {
                key: 'filter-uncategorized',
                label: tc('uncategorized'),
                active: categoryFilter === '',
                dotColor: '#949ba4',
                onClick: () => setCategoryFilter(''),
              },
              ...visibleCategories.map((cat) => ({
                key: `filter-${cat.id}`,
                label: cat.name,
                active: categoryFilter === cat.name,
                dotColor: cat.color,
                onClick: () => setCategoryFilter(cat.name),
              })),
            ]}
          />
        )}

        {tagFilter && (
          <button
            type="button"
            onClick={() => setTagFilter(null)}
            title={tc('clear_tag_filter')}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-item bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70 hover:bg-accent/25 "
          >
            <span
              className="w-1.5 h-1.5 rounded-full shrink-0"
              style={{ backgroundColor: tagColor(tagFilter) }}
            />
            <span className="text-base font-medium">{tagFilter}</span>
            <IconX className="w-3 h-3" />
          </button>
        )}

        {settings.customize_view_enabled && (
          <div className="ms-auto flex items-center gap-2">
            <Dropdown
              align="right"
              compact
              trigger={({ open, toggle }) => (
                <button
                  type="button"
                  aria-expanded={open}

                  onClick={toggle}
                  className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised border border-outline/50 "
                >
                  <span className="text-sm font-medium">{tc('customize_card_section')}</span>
                  <IconChevronDown
                    className={`w-2.5 h-2.5  ${open ? 'rotate-180' : ''}`}
                  />
                </button>
              )}
            >
              {(() => {
                const cardOptions = getCardViewSettings(settings, viewMode)
                return (
                  <div className="flex flex-col gap-0.5">
                    {CARD_TOGGLE_OPTIONS.map((opt) => {
                      const Icon = opt.icon
                      const checked = cardOptions[opt.key]
                      const disabled =
                        opt.key === 'blur_path' && !cardOptions.show_path
                      return (
                        <div
                          key={opt.key}
                          className="flex items-center gap-2.5 rounded-item px-2.5 py-1.5"
                        >
                          <Icon
                            className={`w-3.5 h-3.5 shrink-0 text-muted/70 ${disabled ? 'opacity-50' : ''}`}
                          />
                          <span
                            className={`flex-1 text-start text-xs font-medium truncate ${disabled ? 'text-muted/50' : 'text-ink'}`}
                          >
                            {tc(opt.labelKey)}
                          </span>
                          <Toggle
                            checked={checked}
                            disabled={disabled}
                            onChange={(v) =>
                              update(setCardViewOverride(settings, viewMode, opt.key, v))
                            }
                            label={tc(opt.labelKey)}
                          />
                        </div>
                      )
                    })}
                  </div>
                )
              })()}
            </Dropdown>
            <Dropdown
              align="right"
              compact
              trigger={({ open, toggle }) => {
                const ViewIcon =
                  viewMode === 'grid'
                    ? IconLayoutGrid
                    : viewMode === 'kanban'
                      ? IconKanban
                      : IconLayoutList
                const viewLabel = tc(
                  viewMode === 'grid'
                    ? 'view_grid'
                    : viewMode === 'kanban'
                      ? 'view_kanban'
                      : 'view_list',
                )
                return (
                  <button
                    type="button"
                    aria-expanded={open}
                    aria-label={viewLabel}
                    title={viewLabel}

                    onClick={toggle}
                    className="focus-ring cursor-pointer flex items-center justify-center w-8 h-8 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised border border-outline/50 "
                  >
                    <ViewIcon className="w-3.5 h-3.5" />
                  </button>
                )
              }}
              items={VIEW_MODE_OPTIONS.map((opt) => ({
                key: opt.value,
                label: tc(opt.labelKey),
                icon: opt.icon,
                active: viewMode === opt.value,
                onClick: () => setViewMode(opt.value),
              }))}
            />
          </div>
        )}

      </div>


        <Disclosure
          id="project-selection-bar"
          open={selectedIds.size > 0}
          className="flex items-center gap-2 mb-3 px-3 py-2 rounded-item bg-accent/10 border border-accent-dim/40"
        >
          <Tooltip content={tc('select_all_visible')} side="bottom">
            <button
              type="button"
              onClick={toggleSelectAllVisible}
              aria-label={tc('select_all_visible')}
              className={`focus-ring cursor-pointer w-5 h-5 rounded-item border-2 flex items-center justify-center  ${
                allVisibleSelected
                  ? 'bg-accent border-accent text-white'
                  : 'border-muted/40 text-transparent hover:border-accent/60'
              }`}
            >
              <IconCheck className="w-3 h-3" />
            </button>
          </Tooltip>
          <span className="text-sm font-medium text-ink tabular-nums">
            {tc('selected_count', { count: shownSelectionCount })}
          </span>
          <div className="flex-1" />
          <button
            type="button"
            onClick={batchLaunch}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-accent text-ink hover:bg-accent-bright "
          >
            <IconPlay className="w-3 h-3" />
            <span className="text-xs font-medium">{tc('bulk_launch')}</span>
          </button>
          <button
            type="button"
            onClick={batchPin}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-raised text-muted hover:text-ink hover:bg-overlay "
          >
            <IconPin className="w-3 h-3" />
            <span className="text-xs font-medium">
              {tc('bulk_pin')}
            </span>
          </button>
          <button
            type="button"
            onClick={() => setBulkTagsOpen(true)}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-raised text-muted hover:text-ink hover:bg-overlay "
          >
            <IconTags className="w-3 h-3" />
            <span className="text-xs font-medium">
              {tc('bulk_tags')}
            </span>
          </button>
          <button
            type="button"
            onClick={() => setConfirmBatchAction('remove')}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-raised text-muted hover:text-ink hover:bg-overlay "
          >
            <IconX className="w-3 h-3" />
            <span className="text-xs font-medium">
              {tc('bulk_remove')}
            </span>
          </button>
          <button
            type="button"
            onClick={() => setConfirmBatchAction('delete')}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-danger/10 text-danger hover:bg-danger/20 "
          >
            <IconTrash className="w-3 h-3" />
            <span className="text-xs font-medium">
              {tc('delete')}
            </span>
          </button>
          <Tooltip content={tc('clear_selection')} side="bottom">
            <button
              type="button"
              onClick={clearSelection}
              aria-label={tc('clear_selection')}
              className="focus-ring cursor-pointer w-8 h-8 rounded-btn flex items-center justify-center text-muted hover:text-ink hover:bg-overlay "
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          </Tooltip>
        </Disclosure>

      </div>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-ms-2 -me-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        scrollToTopOn={`${tagFilter ?? ''}-${categoryFilter ?? ''}`}
        scrollRef={viewportRef}
      >
        <div
          className={`h-full ${connected ? 'ps-5' : 'ps-2'} pe-5 pb-4 flex flex-col gap-2`}
        >
        {error && projects.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-3 text-center py-16">
            <p className="text-sm text-muted max-w-sm">
              {tc('projects_load_error')}
            </p>
            <button
              type="button"

              onClick={() => void refresh()}
              className="focus-ring cursor-pointer px-4 py-2 rounded-btn text-sm bg-accent text-ink hover:bg-accent-bright "
            >
              {tc('retry')}
            </button>
          </div>
        ) : viewMode === 'kanban' ? (
          <ProjectCardKanban
            projects={filtered}
            categories={surfaceCategories}
            installedVersions={installed}
            gitStatusMap={gitStatusMap}
            gitStatusLoading={gitStatusLoading}
            launchWithConsole={settings.launch_with_console}
            compact={gitSidebarOpen}
            onTogglePin={(id) => setPinned(id, !projects.find((p) => p.id === id)?.pinned)}
            onVersionChange={(id, tag) => updateVersion(id, tag)}
            onRemove={(id) => void removeWithUndo(id, false)}
            onDelete={(id) => remove(id, true)}
            onCategoryChange={(id, cat) => setCategory(id, cat)}
            onDuplicate={(project) => setDuplicateProject(project)}
            onLaunchArgsChange={(id, args) => handleLaunchArgsChange(id, args)}
            onTagsSaved={(updated) => updateTags(updated.id, updated.tags)}
            onTagClick={(tag) => setTagFilter((cur) => (cur === tag ? null : tag))}
            onShowGitSidebar={(project, gitStatus) =>
              window.dispatchEvent(
                new CustomEvent('app:show-git-sidebar', {
                  detail: { project, gitStatus },
                }),
              )
            }
            activeTag={tagFilter}
            selectedIds={selectedIds}
            onToggleSelect={(id, e) => toggleSelect(id, e)}
            onReorder={dragEnabled ? handleKanbanReorder : undefined}
            onMoveProjects={
              dragEnabled && settings.categories_enabled
                ? handleMoveProjects
                : undefined
            }
            hiddenCategories={hiddenEntries}
            onUnhideCategory={unhideCategory}
            onCategoryContextMenu={openCategoryMenu}
          />
        ) : viewMode === 'grid' ? (
          <ProjectCardGrid
            projects={filtered}
            installedVersions={installed}
            categories={surfaceCategories}
            categoriesEnabled={groupingEnabled}
            searchActive={parsedQuery.active}
            gitStatusMap={gitStatusMap}
            gitStatusLoading={gitStatusLoading}
            launchWithConsole={settings.launch_with_console}
            onTogglePin={(id) => setPinned(id, !projects.find((p) => p.id === id)?.pinned)}
            onVersionChange={(id, tag) => updateVersion(id, tag)}
            onRemove={(id) => void removeWithUndo(id, false)}
            onDelete={(id) => remove(id, true)}
            onCategoryChange={(id, cat) => setCategory(id, cat)}
            onDuplicate={(project) => setDuplicateProject(project)}
            onLaunchArgsChange={(id, args) => handleLaunchArgsChange(id, args)}
            onTagsSaved={(updated) => updateTags(updated.id, updated.tags)}
            onTagClick={(tag) => setTagFilter((cur) => (cur === tag ? null : tag))}
            onShowGitSidebar={(project, gitStatus) =>
              window.dispatchEvent(
                new CustomEvent('app:show-git-sidebar', {
                  detail: { project, gitStatus },
                }),
              )
            }
            activeTag={tagFilter}
            selectedIds={selectedIds}
            onToggleSelect={(id, e) => toggleSelect(id, e)}
            onReorder={dragEnabled ? handleListReorder : undefined}
            onReorderPinned={dragEnabled ? reorder : undefined}
            onMoveProjects={
              dragEnabled && categoriesEnabled ? handleMoveProjects : undefined
            }
            hiddenCategories={hiddenEntries}
            onUnhideCategory={unhideCategory}
            onCategoryContextMenu={openCategoryMenu}
          />
        ) : (
          <ProjectCardList
            projects={filtered}
            hasActiveFilters={hasActiveFilters}
            searchActive={parsedQuery.active}
            categories={surfaceCategories}
            categoriesEnabled={groupingEnabled}
            onReorder={dragEnabled ? handleListReorder : undefined}
            onReorderPinned={dragEnabled ? reorder : undefined}
            onMoveProjects={
              dragEnabled && categoriesEnabled ? handleMoveProjects : undefined
            }
            hiddenCategories={hiddenEntries}
            onUnhideCategory={unhideCategory}
            onCategoryContextMenu={openCategoryMenu}
            selectedIds={selectedIds}
            renderCard={(p) => (
              <ProjectCard
                project={p}
                installedVersions={installed}
                categories={surfaceCategories}
                gitStatus={gitStatusMap[p.path] ?? null}
                gitLoading={gitStatusLoading && !gitStatusMap[p.path]}
                launchWithConsole={settings.launch_with_console}
                onTogglePin={() => setPinned(p.id, !p.pinned)}
                onVersionChange={(tag) => updateVersion(p.id, tag)}
                onRemove={() => void removeWithUndo(p.id, false)}
                onDelete={() => remove(p.id, true)}
                onCategoryChange={settings.categories_enabled && sortBy !== 'categories' ? (cat) => setCategory(p.id, cat) : undefined}
                onDuplicate={() => setDuplicateProject(p)}
                onTagsSaved={(updated) => updateTags(updated.id, updated.tags)}
                onTagClick={(tag) => setTagFilter((cur) => (cur === tag ? null : tag))}
                onLaunchArgsChange={(args) => handleLaunchArgsChange(p.id, args)}
                onShowGitSidebar={() =>
                  window.dispatchEvent(
                    new CustomEvent('app:show-git-sidebar', {
                      detail: {
                        project: p,
                        gitStatus: gitStatusMap[p.path] ?? null,
                      },
                    }),
                  )
                }
                activeTag={tagFilter}
                selected={selectedIds.has(p.id)}
                onToggleSelect={(e) => toggleSelect(p.id, e)}
                viewMode={viewMode}
              />
            )}
          />
        )}


        {createProjectOpen && (
          <CreateProjectModal
            installedVersions={installed}
            defaultLocation={settings.default_project_location}
            categories={surfaceCategories}
            categoriesEnabled={settings.categories_enabled}
            onClose={() => setCreateProjectOpen(false)}
            onCreated={() => {
              setCreateProjectOpen(false)
              refresh()
            }}
          />
        )}



        {cloneRepoOpen && (
          <CloneRepoModal
            defaultLocation={settings.default_project_location}
            categories={surfaceCategories}
            categoriesEnabled={settings.categories_enabled}
            onClose={() => setCloneRepoOpen(false)}
            onCloned={() => {
              setCloneRepoOpen(false)
              refresh()
            }}
          />
        )}



        {categoryManagerOpen && (
          <CategoryManagerModal
            categories={categories}
            projects={projects}
            onClose={() => setCategoryManagerOpen(false)}
            onCreate={createCategory}
            onUpdate={updateCategory}
            onDelete={removeCategory}
            onReorder={reorderCategories}
            onAssignFolder={async (id, folder) => {
              const updated = await assignCategoryFolder(id, folder)
              await refresh()
              return updated
            }}
            onUnassignFolder={async (id, folder) => {
              const updated = await unassignCategoryFolder(id, folder)
              await refresh()
              return updated
            }}
          />
        )}



        {duplicateProject && (
          <DuplicateProjectModal
            project={duplicateProject}
            onClose={() => setDuplicateProject(null)}
            onDuplicated={() => void refresh()}
          />
        )}



        {bulkTagsOpen && (
          <BulkTagModal
            projects={[...selectedIds]
              .map((id) => projects.find((p) => p.id === id))
              .filter((p): p is Project => !!p)}
            onClose={() => setBulkTagsOpen(false)}
            onApplied={() => void refresh()}
          />
        )}



        {confirmBatchAction === 'remove' && (
          <ConfirmDialog
            title={tc('bulk_remove_title', {
              count: selectedIds.size,
            })}
            description={tc('bulk_remove_desc', {
              count: selectedIds.size,
            })}
            confirmLabel={tc('bulk_remove')}
            onConfirm={executeBatchRemove}
            onCancel={() => setConfirmBatchAction(null)}
          />
        )}



        {confirmBatchAction === 'delete' && (
          <ConfirmDialog
            title={tc('bulk_delete_title', { count: selectedIds.size })}
            description={tc('bulk_delete_desc', {
              count: selectedIds.size,
            })}
            confirmLabel={tc('project_delete_confirm')}
            variant="danger"
            onConfirm={executeBatchDelete}
            onCancel={() => setConfirmBatchAction(null)}
          />
        )}



        {categoryMenu && (
          <ContextMenu
            key="category-context-menu"
            label={categoryMenu.category.name}
            x={categoryMenu.x}
            y={categoryMenu.y}
            items={categoryMenuItems}
            compact
            onClose={() => setCategoryMenu(null)}
          />
        )}

      </div>
      </OverlayScrollArea>
    </div>
  )
}
