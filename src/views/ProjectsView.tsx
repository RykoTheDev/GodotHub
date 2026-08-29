import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { useProjectsContext } from '../hooks/projectsContext'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { useCategoriesContext } from '../hooks/categoriesContext'

import {
  IconArrowUpDown,
  IconCheck,
  IconFilter,
  IconGear,
  IconGitBranch,
  IconPin,
  IconPlay,
  IconPlus,
  IconTags,
  IconTrash,
  IconX,
} from '../lib/icons'
import { tagColor } from '../lib/colors'
import { Segmented } from '../components/reusables/Segmented'
import { CreateViewModal } from '../components/modals/CreateViewModal'
import { Dropdown } from '../components/ui/Dropdown'
import { ImportButton } from '../components/reusables/ImportButton'
import { Tooltip } from '../components/reusables/Tooltip'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ProjectCard } from '../components/cards/ProjectCard'
import { ProjectCardList } from '../components/cards/ProjectCardList'
import { ProjectCardKanban } from '../components/cards/ProjectCardKanban'
import { ProjectCardGrid } from '../components/cards/ProjectCardGrid'

type ProjectViewMode = 'list' | 'grid' | 'kanban'
import { useSettings } from '../hooks/useSettings'
import { useScrollCompensation } from '../hooks/useScrollCompensation'
import { api } from '../lib/api'
import type { GitStatus, Project } from '../types'
import {
  comparatorFor,
  SORT_OPTIONS,
  type ProjectSortOption,
} from '../lib/projectSort'
import { ScanButton } from '../components/reusables/ScanButton'
import { SearchBar } from '../components/ui/SearchBar'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { CreateProjectModal } from '../components/modals/CreateProjectModal'
import { CloneRepoModal } from '../components/modals/CloneRepoModal'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { CategoryManagerModal } from '../components/modals/CategoryManagerModal'

export function ProjectsView({
  onOpenSettings,
  connected = false,
  gitSidebarOpen = false,
}: {
  onOpenSettings?: () => void
  connected?: boolean
  gitSidebarOpen?: boolean
}) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')

  const {
    projects,
    refresh,
    remove,
    updateVersion,
    setPinned,
    updateTags,
    setCategory,
    reorder,
    moveProject,
  } = useProjectsContext()
  const { categories, create: createCategory, update: updateCategory, remove: removeCategory, reorder: reorderCategories } = useCategoriesContext()
  const { installed } = useGodotVersionsContext()
  const { settings } = useSettings()
  const [createProjectOpen, setCreateProjectOpen] = useState(false)
  const [cloneRepoOpen, setCloneRepoOpen] = useState(false)
  const [categoryManagerOpen, setCategoryManagerOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')
  useEffect(() => {
    const id = setTimeout(() => setDebouncedQuery(query), 150)
    return () => clearTimeout(id)
  }, [query])
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [selecting, setSelecting] = useState(false)

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === 'Control') {
        setSelecting(true)
      }
    }
    const up = (e: KeyboardEvent) => {
      if (e.key === 'Control') {
        setSelecting(false)
      }
    }
    window.addEventListener('keydown', down)
    window.addEventListener('keyup', up)
    return () => {
      window.removeEventListener('keydown', down)
      window.removeEventListener('keyup', up)
    }
  }, [])

  const [confirmBatchAction, setConfirmBatchAction] = useState<
    'remove' | 'delete' | null
  >(null)
  const [viewMode, setViewMode] = useState<ProjectViewMode>(() => {
    try {
      const raw = localStorage.getItem('godothub_projects_view_mode')
      if (raw === 'list' || raw === 'grid' || raw === 'kanban') return raw
    } catch {}
    return 'list'
  })
  useEffect(() => {
    try {
      localStorage.setItem('godothub_projects_view_mode', viewMode)
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
  const [savedViews, setSavedViews] = useState<ProjectViewMode[]>(() => {
    try {
      const raw = localStorage.getItem('godothub_saved_views')
      if (raw) {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed) && parsed.every((v: string) => ['list', 'grid', 'kanban'].includes(v))) {
          return parsed
        }
      }
    } catch {}
    return []
  })
  useEffect(() => {
    try {
      localStorage.setItem('godothub_saved_views', JSON.stringify(savedViews))
    } catch {}
  }, [savedViews])
  const [viewNames, setViewNames] = useState<Record<string, string>>(() => {
    try {
      const raw = localStorage.getItem('godothub_view_names')
      if (raw) return JSON.parse(raw)
    } catch {}
    return {}
  })
  useEffect(() => {
    try {
      localStorage.setItem('godothub_view_names', JSON.stringify(viewNames))
    } catch {}
  }, [viewNames])
  const [createViewModalOpen, setCreateViewModalOpen] = useState(false)
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
      const raw = localStorage.getItem('godothub_projects_sort_by')
      if (raw) return raw as ProjectSortOption
    } catch {}
    return 'categories'
  })
  const [sortNow, setSortNow] = useState(() => Date.now())
  useEffect(() => {
    if (sortBy !== 'time_desc') return
    if (!projects.some((p) => p.session_started_at_ms)) return
    setSortNow(Date.now())
    const id = setInterval(() => setSortNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [sortBy, projects])
  const [gitStatusMap, setGitStatusMap] = useState<Record<string, GitStatus>>({})
  const fetchingGitRef = useRef(false)
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

  const fetchGitStatuses = useCallback(async () => {
    if (fetchingGitRef.current) return
    const list = projectsRef.current
    if (list.length === 0) return
    fetchingGitRef.current = true
    try {
      const statuses = await api.batchGitStatus(list.map((p) => p.path))
      setGitStatusMap(statuses)
    } catch {
    } finally {
      fetchingGitRef.current = false
    }
  }, [])

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  useEffect(() => {
    fetchGitStatuses()
    const interval = setInterval(fetchGitStatuses, 30000)
    const handleRefresh = () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
      debounceRef.current = setTimeout(fetchGitStatuses, 300)
    }
    window.addEventListener('app:refresh-git-status', handleRefresh)
    return () => {
      clearInterval(interval)
      if (debounceRef.current) clearTimeout(debounceRef.current)
      window.removeEventListener('app:refresh-git-status', handleRefresh)
    }
  }, [fetchGitStatuses, projectPathsKey])

  useEffect(() => {
    try {
      localStorage.setItem('godothub_projects_sort_by', sortBy)
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
      localStorage.removeItem('godothub_projects_tag_filter')
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
    if (!categories.some((c) => c.name === categoryFilter)) {
      setCategoryFilter(null)
    }
  }, [categories, categoryFilter])

  const baseFiltered = useMemo(() => {
    const q = debouncedQuery.trim().toLowerCase()
    let list = projects
    if (q) {
      list = list.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.path.toLowerCase().includes(q),
      )
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
  }, [projects, debouncedQuery, tagFilter, categoryFilter])

  const filtered = useMemo(() => {
    let list = baseFiltered
    const cmp = comparatorFor(sortBy, sortNow)
    return [...list].sort((a, b) => {
      if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
      if (a.pinned) return a.name.localeCompare(b.name)
      return cmp ? cmp(a, b) : a.sort_order - b.sort_order
    })
  }, [baseFiltered, sortBy, sortNow])

  const hasActiveFilters =
    query.trim() !== '' || tagFilter !== null || categoryFilter !== null

  const categoriesEnabled = settings.categories_enabled && sortBy === 'categories'

  const visualOrder = useMemo(() => {
    if (!categoriesEnabled) return filtered
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
    for (const cat of categories) {
      const projs = groups.get(cat.name)
      if (projs) ordered.push(...projs)
    }
    const uncategorized = groups.get(UNCATEGORIZED_KEY)
    if (uncategorized) ordered.push(...uncategorized)
    return ordered
  }, [filtered, categoriesEnabled, categories])

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

  const executeBatchRemove = useCallback(async () => {
    setConfirmBatchAction(null)
    for (const id of selectedIds) await remove(id, false)
    clearSelection()
  }, [selectedIds, remove, clearSelection])

  const executeBatchDelete = useCallback(async () => {
    setConfirmBatchAction(null)
    for (const id of selectedIds) await remove(id, true)
    clearSelection()
  }, [selectedIds, remove, clearSelection])

  const handleLaunchArgsChange = useCallback(async (id: string, args: string) => {
    await api.updateProject(id, { launch_arguments: args })
    await refresh()
  }, [refresh])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && selectedIds.size > 0) clearSelection()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [selectedIds.size, clearSelection])

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <div className="shrink-0 flex flex-col gap-2">
      <ViewHeader
        connected={connected}
        title={t('projects')}
        leadingAction={
          <Tooltip content={tc('new_project')} side="bottom">
            <motion.button
              type="button"
              onClick={() => setCreateProjectOpen(true)}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.9 }}
              transition={{ type: 'spring', stiffness: 500, damping: 28 }}
              className="w-9 h-9 cursor-pointer flex items-center justify-center rounded-full bg-accent text-ink hover:bg-accent-bright transition-colors"
            >
              <IconPlus className="w-10 h-10" strokeWidth={3} />
            </motion.button>
          </Tooltip>
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
              <motion.button
                type="button"
                whileHover={{ scale: 1.04 }}
                whileTap={{ scale: 0.94 }}
                onClick={() => setCategoryManagerOpen(true)}
                aria-label={tc('manage_categories')}
                className="focus-ring cursor-pointer inline-flex items-center justify-center shadow-md shadow-black/10 border border-outline/50 w-10 h-10 shrink-0 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised transition-colors"
            >
                <IconTags className="w-4 h-4" />
              </motion.button>
            )}
          </>
        }
      >
        <SearchBar value={query} onChange={setQuery} />
      </ViewHeader>

      <div className={`shrink-0 flex items-center gap-2 mb-3 ${connected ? 'pl-5' : ''}`}>
        <Dropdown
          align="left"
          trigger={({ open, toggle }) => {
            const defaultSort: ProjectSortOption = 'categories'
            const isCustomSort = sortBy !== defaultSort
            const activeSortLabel = SORT_OPTIONS.find((o) => o.value === sortBy)
            return (
              <motion.button
                type="button"
                aria-expanded={open}
                whileHover={{ scale: 1.04 }}
                whileTap={{ scale: 0.94 }}
                onClick={toggle}
                className={`focus-ring cursor-pointer flex items-center justify-center gap-1 h-8 px-4 rounded-item transition-colors ${
                  isCustomSort
                    ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
                    : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
                }`}
              >
                <IconArrowUpDown className="w-3 h-3" />
                <span className="text-[16px] font-medium">{tc('sort')}</span>
                {activeSortLabel && (
                  <span className="text-[12px] tabular-nums text-muted/80 max-w-30 truncate leading-none">
                    {tc(activeSortLabel.labelKey)}
                  </span>
                )}
              </motion.button>
            )
          }}
          items={SORT_OPTIONS.map((opt) => ({
            key: opt.value,
            label: tc(opt.labelKey),
            active: opt.value === sortBy,
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
                <motion.button
                  type="button"
                  aria-expanded={open}
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.94 }}
                  onClick={toggle}
                  className={`focus-ring cursor-pointer flex items-center justify-center gap-1 h-8 px-4 rounded-item transition-colors ${
                    hasCategoryFilter
                      ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
                      : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
                  }`}
                >
                  <IconFilter className="w-3 h-3" />
                  <span className="text-[16px] font-medium">{tc('filter')}</span>
                  {hasCategoryFilter && (
                    <span className="text-[12px] tabular-nums text-muted/80 max-w-30 truncate">
                      {activeLabel}
                    </span>
                  )}
                </motion.button>
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
              ...categories.map((cat) => ({
                key: `filter-${cat.id}`,
                label: cat.name,
                active: categoryFilter === cat.name,
                dotColor: cat.color,
                onClick: () => setCategoryFilter(cat.name),
              })),
            ]}
          />
        )}        <div className="w-px h-5 bg-outline/50 shrink-0" />

        {savedViews.length >= 2 ? (
          <div className="flex items-center gap-1.5">
            <Segmented
              value={viewMode}
              onChange={(v) => setViewMode(v as ProjectViewMode)}
              options={savedViews.map((v) => ({
                value: v,
                label: viewNames[v] ?? (v === 'list' ? tc('view_list') : v === 'grid' ? tc('view_grid') : tc('view_kanban')),
              }))}
            />
            <motion.button
              type="button"
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.94 }}
              onClick={() => setCreateViewModalOpen(true)}
              aria-label={tc('manage_views')}
              className="focus-ring cursor-pointer flex items-center justify-center w-8 h-8 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised border border-outline/50 transition-colors"
            >
              <IconGear className="w-3.5 h-3.5" />
            </motion.button>
          </div>
        ) : (
          <motion.button
            type="button"
            whileHover={{ scale: 1.04 }}
            whileTap={{ scale: 0.94 }}
            onClick={() => setCreateViewModalOpen(true)}
            className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-8 px-4 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised border border-outline/50 transition-colors"
          >
            <IconPlus className="w-3 h-3" />
            <span className="text-[13px] font-medium">{tc('create_view')}</span>
          </motion.button>
        )}

        {tagFilter && (
            <button
              type="button"
              onClick={() => setTagFilter(null)}
              title={tc('clear_tag_filter')}
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-item bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70 hover:bg-accent/25 transition-colors"
            >
              <span
                className="w-1.5 h-1.5 rounded-full shrink-0"
                style={{ backgroundColor: tagColor(tagFilter) }}
              />
              <span className="text-[16px] font-medium">{tagFilter}</span>
              <IconX className="w-3 h-3" />
            </button>
        )}

      </div>

      <AnimatePresence>
        {createViewModalOpen && (
          <CreateViewModal
            savedViews={savedViews}
            viewNames={viewNames}
            onAdd={(mode) => {
              setSavedViews((prev) => [...prev, mode])
              setViewMode(mode)
            }}
            onRemove={(mode) => {
              setSavedViews((prev) => prev.filter((v) => v !== mode))
              if (viewMode === mode) {
                setViewMode(savedViews.find((v) => v !== mode) ?? 'list')
              }
            }}
            onRename={(mode, name) => {
              setViewNames((prev) => ({ ...prev, [mode]: name }))
            }}
            onClose={() => setCreateViewModalOpen(false)}
          />
        )}
      </AnimatePresence>
      <AnimatePresence>
        {selectedIds.size > 0 && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.18, ease: 'easeOut' }}
            className="overflow-hidden shrink-0"
          >
            <div className="flex items-center gap-2 mb-3 px-3 py-2 rounded-item bg-accent/10 border border-accent-dim/40">
              <button
                type="button"
                onClick={toggleSelectAllVisible}
                aria-label={tc('select_all_visible')}
                className={`focus-ring cursor-pointer w-5 h-5 rounded-item border-2 flex items-center justify-center transition-colors ${
                  allVisibleSelected
                    ? 'bg-accent border-accent text-white'
                    : 'border-muted/40 text-transparent hover:border-accent/60'
                }`}
              >
                <IconCheck className="w-3 h-3" />
              </button>
              <span className="text-sm font-medium text-ink tabular-nums">
                {tc('selected_count', { count: selectedIds.size })}
              </span>
              <div className="flex-1" />
              <button
                type="button"
                onClick={batchLaunch}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-accent text-ink hover:bg-accent-bright transition-colors"
              >
                <IconPlay className="w-3 h-3" />
                <span className="text-xs font-medium">{tc('bulk_launch')}</span>
              </button>
              <button
                type="button"
                onClick={batchPin}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-raised text-muted hover:text-ink hover:bg-overlay transition-colors"
              >
                <IconPin className="w-3 h-3" />
                <span className="text-xs font-medium">
                  {tc('bulk_pin')}
                </span>
              </button>
              <button
                type="button"
                onClick={() => setConfirmBatchAction('remove')}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-raised text-muted hover:text-ink hover:bg-overlay transition-colors"
              >
                <IconX className="w-3 h-3" />
                <span className="text-xs font-medium">
                  {tc('bulk_remove')}
                </span>
              </button>
              <button
                type="button"
                onClick={() => setConfirmBatchAction('delete')}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-btn bg-danger/10 text-danger hover:bg-danger/20 transition-colors"
              >
                <IconTrash className="w-3 h-3" />
                <span className="text-xs font-medium">
                  {tc('bulk_delete')}
                </span>
              </button>
              <button
                type="button"
                onClick={clearSelection}
                aria-label={tc('clear_selection')}
                className="focus-ring cursor-pointer w-8 h-8 rounded-btn flex items-center justify-center text-muted hover:text-ink hover:bg-overlay transition-colors"
              >
                <IconX className="w-3.5 h-3.5" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
      </div>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        scrollToTopOn={`${tagFilter ?? ''}-${categoryFilter ?? ''}`}
        scrollRef={viewportRef}
      >
        <div
          className={`h-full ${connected ? 'pl-5' : ''} pr-5 pb-4 flex flex-col gap-2`}
        >
        {viewMode === 'kanban' ? (
          <ProjectCardKanban
            projects={filtered}
            categories={settings.categories_enabled ? categories : []}
            installedVersions={installed}
            gitStatusMap={gitStatusMap}
            launchWithConsole={settings.launch_with_console}
            compact={gitSidebarOpen}
            onTogglePin={(id) => setPinned(id, !projects.find((p) => p.id === id)?.pinned)}
            onVersionChange={(id, tag) => updateVersion(id, tag)}
            onRemove={(id) => remove(id, false)}
            onDelete={(id) => remove(id, true)}
            onCategoryChange={(id, cat) => setCategory(id, cat)}
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
            selecting={selecting}
            onReorder={settings.categories_enabled && sortBy === 'categories' && !hasActiveFilters ? reorder : undefined}
            onMoveProject={settings.categories_enabled && sortBy === 'categories' && !hasActiveFilters ? moveProject : undefined}
          />
        ) : viewMode === 'grid' ? (
          <ProjectCardGrid
            projects={filtered}
            installedVersions={installed}
            categories={settings.categories_enabled ? categories : []}
            categoriesEnabled={settings.categories_enabled && sortBy === 'categories'}
            gitStatusMap={gitStatusMap}
            launchWithConsole={settings.launch_with_console}
            onTogglePin={(id) => setPinned(id, !projects.find((p) => p.id === id)?.pinned)}
            onVersionChange={(id, tag) => updateVersion(id, tag)}
            onRemove={(id) => remove(id, false)}
            onDelete={(id) => remove(id, true)}
            onCategoryChange={(id, cat) => setCategory(id, cat)}
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
            selecting={selecting}
            onReorder={settings.categories_enabled && sortBy === 'categories' && !hasActiveFilters ? reorder : undefined}
            onMoveProject={settings.categories_enabled && sortBy === 'categories' && !hasActiveFilters ? moveProject : undefined}
          />
        ) : (
          <ProjectCardList
            projects={filtered}
            totalCount={projects.length}
            animationThreshold={settings.animation_threshold}
            hasActiveFilters={hasActiveFilters}
            categories={settings.categories_enabled ? categories : []}
            categoriesEnabled={settings.categories_enabled && sortBy === 'categories'}
            onReorder={settings.categories_enabled && sortBy === 'categories' && !hasActiveFilters ? reorder : undefined}
            onMoveProject={settings.categories_enabled && sortBy === 'categories' && !hasActiveFilters ? moveProject : undefined}
            renderCard={(p) => (
              <ProjectCard
                project={p}
                installedVersions={installed}
                categories={settings.categories_enabled ? categories : []}
                gitStatus={gitStatusMap[p.path] ?? null}
                launchWithConsole={settings.launch_with_console}
                onTogglePin={() => setPinned(p.id, !p.pinned)}
                onVersionChange={(tag) => updateVersion(p.id, tag)}
                onRemove={() => remove(p.id, false)}
                onDelete={() => remove(p.id, true)}
                onCategoryChange={settings.categories_enabled && sortBy !== 'categories' ? (cat) => setCategory(p.id, cat) : undefined}
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
                onToggleSelect={(selecting || selectedIds.size > 0) ? (e) => toggleSelect(p.id, e) : undefined}
              />
            )}
          />
        )}

      <AnimatePresence>
        {createProjectOpen && (
          <CreateProjectModal
            installedVersions={installed}
            defaultLocation={settings.default_project_location}
            categories={categories}
            categoriesEnabled={settings.categories_enabled}
            onClose={() => setCreateProjectOpen(false)}
            onCreated={() => {
              setCreateProjectOpen(false)
              refresh()
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {cloneRepoOpen && (
          <CloneRepoModal
            defaultLocation={settings.default_project_location}
            categories={categories}
            categoriesEnabled={settings.categories_enabled}
            onClose={() => setCloneRepoOpen(false)}
            onCloned={() => {
              setCloneRepoOpen(false)
              refresh()
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {categoryManagerOpen && (
          <CategoryManagerModal
            categories={categories}
            onClose={() => setCategoryManagerOpen(false)}
            onCreate={createCategory}
            onUpdate={updateCategory}
            onDelete={removeCategory}
            onReorder={reorderCategories}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmBatchAction === 'remove' && (
          <ConfirmDialog
            title={tc('bulk_remove_title', {
              count: selectedIds.size,
            })}
            description={tc('bulk_remove_desc', {
              count: selectedIds.size,
            })}
            confirmLabel={tc('bulk_remove_confirm')}
            onConfirm={executeBatchRemove}
            onCancel={() => setConfirmBatchAction(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmBatchAction === 'delete' && (
          <ConfirmDialog
            title={tc('bulk_delete_title', { count: selectedIds.size })}
            description={tc('bulk_delete_desc', {
              count: selectedIds.size,
            })}
            confirmLabel={tc('bulk_delete_confirm')}
            variant="danger"
            onConfirm={executeBatchDelete}
            onCancel={() => setConfirmBatchAction(null)}
          />
        )}
      </AnimatePresence>
      </div>
      </OverlayScrollArea>
    </div>
  )
}
