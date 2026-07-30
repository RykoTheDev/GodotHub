import { useEffect, useMemo, useState, useRef, useCallback } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  KeyboardSensor,
  pointerWithin,
  closestCorners,
  useSensor,
  useSensors,
  useDroppable,
  type CollisionDetection,
  type DragStartEvent,
  type DragOverEvent,
  type DragEndEvent,
} from '@dnd-kit/core'
import {
  SortableContext,
  useSortable,
  verticalListSortingStrategy,
  arrayMove,
  sortableKeyboardCoordinates,
} from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { useProjectsContext } from '../hooks/projectsContext'
import { useCategoriesContext } from '../hooks/categoriesContext'
import { useSettings } from '../hooks/useSettings'
import { ProjectCard } from '../components/ui/ProjectCard'
import { Tooltip } from '../components/ui/Tooltip'
import { CreateProjectModal } from '../components/modals/CreateProjectModal'
import { CloneRepoModal } from '../components/modals/CloneRepoModal'
import { CategoryManagerModal } from '../components/modals/CategoryManagerModal'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { ProjectPropertiesModal } from '../components/modals/ProjectPropertiesModal'
import { Dropdown } from '../components/ui/Dropdown'
import { api } from '../lib/api'
import {
  IconFolderPlus,
  IconGitBranch,
  IconImport,
  IconNode,
  IconPin,
  IconSearch,
  IconX,
  IconTags,
  IconRefresh,
  IconChevronDown,
  IconArrowUpDown,
} from '../components/Icons'
import {
  comparatorFor,
  SORT_OPTIONS,
  type ProjectSortOption,
} from '../lib/projectSort'
import type { GitStatus, Project } from '../types'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'

const UNCATEGORIZED = '__uncategorized__'
const COLLAPSED_CATS_KEY = 'godothub_collapsed_categories'
const SORT_BY_KEY = 'godothub_projects_sort_by'

type ZoneKind = 'category' | 'pinned' | 'flat'

const kindOfZone = (zoneKey: string): ZoneKind =>
  zoneKey === '__pinned__'
    ? 'pinned'
    : zoneKey === '__flat__'
      ? 'flat'
      : 'category'

function SortableProjectCard({
  project,
  disabled,
  ...cardProps
}: {
  project: Project
  disabled: boolean
} & Omit<
  React.ComponentProps<typeof ProjectCard>,
  'project' | 'setNodeRef' | 'style' | 'dragHandleProps' | 'isDragging'
>) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: project.id,
    disabled,
  })
  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
  }
  return (
      <ProjectCard
        project={project}
        setNodeRef={setNodeRef}
        style={style}
        isDragging={isDragging}
        dragHandleProps={{ ...attributes, ...listeners }}
        {...cardProps}
      />
  )
}

function ZoneDropArea({ zoneKey }: { zoneKey: string }) {
  const { t } = useTranslation('common')
  const { setNodeRef, isOver } = useDroppable({
    id: zoneKey,
    data: { type: 'zone', zoneKey },
  })
  return (
    <motion.div
      initial={{ opacity: 0, height: 0, scale: 0.96 }}
      animate={{ opacity: 1, height: 'auto', scale: 1 }}
      exit={{ opacity: 0, height: 0, scale: 0.96 }}
      transition={{ duration: 0.2, ease: 'easeOut' }}
    >
      <div
        ref={setNodeRef}
        className={`min-h-[56px] rounded-xl border-2 border-dashed transition-all duration-150 flex items-center justify-center ${
          isOver
            ? 'border-accent bg-accent/5'
            : 'border-line/20'
        }`}
      >
        <div className="flex flex-col items-center gap-1">
          <span className={`text-xs transition-all duration-150 ${
            isOver ? 'text-accent font-semibold' : 'text-muted/40'
          }`}>
            {isOver ? t('drop_here') : t('no_projects')}
          </span>
          <span className={`text-[10px] transition-all duration-150 ${
            isOver ? 'text-accent/70' : 'text-muted/30'
          }`}>
            {isOver ? t('release_to_move') : t('drag_to_add')}
          </span>
        </div>
      </div>
    </motion.div>
  )
}

export function ProjectsView({
  onShowGitSidebar,
}: {
  onShowGitSidebar?: (project: Project, gitStatus: GitStatus | null) => void
}) {
  const { t } = useTranslation('common')
  const {
    projects,
    loaded,
    refresh,
    remove,
    updateVersion,
    setPinned,
    setCategory,
    moveProject,
    reorder,
    scanProgress,
  } = useProjectsContext()
  const {
    categories,
    create: createCategory,
    update: updateCategory,
    remove: removeCategory,
    reorder: reorderCategories,
  } = useCategoriesContext()
  const { installed } = useGodotVersionsContext()
  const { settings } = useSettings()
  const categoriesEnabled = settings.categories_enabled
  const [modalOpen, setModalOpen] = useState(false)
  const [categoryModalOpen, setCategoryModalOpen] = useState(false)
  const [cloneRepoOpen, setCloneRepoOpen] = useState(false)
  const [activeId, setActiveId] = useState<string | null>(null)
  const [overContainer, setOverContainer] = useState<string | null>(null)
  const [query, setQuery] = useState('')
  const [sortBy, setSortBy] = useState<ProjectSortOption>(
    () => {
      try {
        const raw = localStorage.getItem(SORT_BY_KEY)
        if (raw) return raw as ProjectSortOption
      } catch {}
      return 'categories'
    },
  )

  const [scanning, setScanning] = useState(false)
  const [importing, setImporting] = useState(false)
  const [dialogMinimized, setDialogMinimized] = useState(false)
  const [gitStatusMap, setGitStatusMap] = useState<Record<string, GitStatus>>({})
  const fetchingGitRef = useRef(false)
  const [collapsedCats, setCollapsedCats] = useState<Record<string, boolean>>(
    () => {
      try {
        const raw = localStorage.getItem(COLLAPSED_CATS_KEY)
        if (raw) return JSON.parse(raw)
      } catch {}
      return {}
    },
  )
  const [propertiesProject, setPropertiesProject] = useState<Project | null>(null)

  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const lastClickedIdRef = useRef<string | null>(null)
  const [confirmBatchRemove, setConfirmBatchRemove] = useState(false)
  const [confirmBatchPin, setConfirmBatchPin] = useState(false)
  const [confirmBatchVersion, setConfirmBatchVersion] = useState<string | null>(null)
  const [confirmBatchCategory, setConfirmBatchCategory] = useState<string | null>(null)
  const [undoBatchData, setUndoBatchData] = useState<{ paths: string[] } | null>(null)
  const undoBatchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [importDropdownOpen, setImportDropdownOpen] = useState(false)
  const importDropdownRef = useRef<HTMLDivElement>(null)

  const handleImport = async () => {
    const folder = await api.pickFolder()
    if (!folder) return
    setDialogMinimized(false)
    setImporting(true)
    try {
      await api.importProject(folder, '')
      refresh()
    } catch (e) {
      alert(e)
    } finally {
      setImporting(false)
    }
  }

  const handleCloneResult = (projectId: string) => {
    setCloneRepoOpen(false)
    refresh()
    setTimeout(() => {
      const el = document.getElementById(`project-${projectId}`)
      if (!el) return
      el.scrollIntoView({ behavior: 'smooth', block: 'center' })
      el.classList.add('ring-2', 'ring-accent', 'rounded-xl')
      setTimeout(() => {
        el.classList.remove('ring-2', 'ring-accent', 'rounded-xl')
      }, 2000)
    }, 200)
  }

  const handleScanNow = async () => {
    if (scanning) return
    setDialogMinimized(false)
    setScanning(true)
    try {
      if (settings.project_scan_dirs.length) {
        await api.scanForProjects(
          settings.project_scan_dirs,
          settings.scan_depth,
        )
        await refresh()
      }
    } finally {
      setScanning(false)
    }
  }

  const importRef = useRef(handleImport)
  importRef.current = handleImport
  const scanRef = useRef(handleScanNow)
  scanRef.current = handleScanNow

  useEffect(() => {
    const handleScrollToProject = (e: Event) => {
      const projectId = (e as CustomEvent).detail as string
      if (!projectId) return

      setTimeout(() => {
        const el = document.getElementById(`project-${projectId}`)
        if (!el) return

        el.scrollIntoView({ behavior: 'smooth', block: 'center' })

        el.classList.add('ring-2', 'ring-accent', 'rounded-xl')
        setTimeout(() => {
          el.classList.remove('ring-2', 'ring-accent', 'rounded-xl')
        }, 2000)
      }, 150)
    }

    window.addEventListener('app:scroll-to-project', handleScrollToProject)
    return () =>
      window.removeEventListener(
        'app:scroll-to-project',
        handleScrollToProject,
      )
  }, [])

  useEffect(() => {
    const handleNewProject = () => setModalOpen(true)
    const handleImportProject = () => importRef.current()
    const handleScanProjects = () => scanRef.current()
    window.addEventListener('app:new-project', handleNewProject)
    window.addEventListener('app:import-project', handleImportProject)
    window.addEventListener('app:scan-projects', handleScanProjects)
    return () => {
      window.removeEventListener('app:new-project', handleNewProject)
      window.removeEventListener('app:import-project', handleImportProject)
      window.removeEventListener('app:scan-projects', handleScanProjects)
    }
  }, [])

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (importDropdownRef.current && !importDropdownRef.current.contains(e.target as Node)) {
        setImportDropdownOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])



  const allVisibleIdsRef = useRef<string[]>([])

  const selectedIdsRef = useRef(selectedIds)
  selectedIdsRef.current = selectedIds

  const toggleSelect = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
      } else {
        next.add(id)
      }
      return next
    })
    lastClickedIdRef.current = id
  }, [])

  const handleClearSelection = useCallback(() => {
    setSelectedIds(new Set())
    lastClickedIdRef.current = null
  }, [])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (activeId) {
          setActiveId(null)
          setOverContainer(null)
        }
        if (selectedIdsRef.current.size > 0) {
          handleClearSelection()
        }
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [activeId, handleClearSelection])

  const isSearching = query.trim().length > 0
  const isSortingCategories = sortBy === 'categories'
  const dragDisabled = isSearching || !isSortingCategories

  const availableCategories = useMemo(
    () => [...categories.map((c) => c.name), UNCATEGORIZED],
    [categories],
  )

  const filteredProjects = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return projects
    return projects.filter(
      (p) =>
        p.name.toLowerCase().includes(q) ||
        p.path.toLowerCase().includes(q),
    )
  }, [projects, query])

  const cmp = comparatorFor(sortBy)

  const sortProjects = useCallback(
    (list: Project[]) => {
      if (cmp) return [...list].sort(cmp)
      return [...list].sort((a, b) => a.sort_order - b.sort_order)
    },
    [cmp],
  )

  const pinned = useMemo(() => {
    return sortProjects(filteredProjects.filter((p) => p.pinned))
  }, [filteredProjects, sortProjects])

  const showCategories = sortBy === 'categories'

  const categorySections = useMemo(() => {
    if (!showCategories) return []
    const groups = new Map<string, Project[]>()
    for (const key of availableCategories) groups.set(key, [])
    for (const p of filteredProjects) {
      if (p.pinned) continue
      const key = p.category ?? UNCATEGORIZED
      if (!groups.has(key)) groups.set(key, [])
      groups.get(key)!.push(p)
    }
    for (const [key, list] of groups) {
      groups.set(key, sortProjects(list))
    }
    const keys = [...groups.keys()].filter((k) => k !== UNCATEGORIZED)
    keys.push(UNCATEGORIZED)
    return keys.map((key) => ({
      key,
      label: key === UNCATEGORIZED ? t('uncategorized') : key,
      items: groups.get(key)!,
    }))
  }, [filteredProjects, availableCategories, showCategories, sortProjects])

  const flatList = useMemo(() => {
    return sortProjects(filteredProjects.filter((p) => !p.pinned))
  }, [filteredProjects, sortProjects])

  const versionWarningMap = useMemo(() => {
    const map: Record<string, 'not_found' | 'major_mismatch' | null> = {}
    for (const p of filteredProjects) {
      const isInstalled = installed.some((v) => v.tag === p.godot_version)
      if (isInstalled) {
        map[p.id] = null
        continue
      }
      const projectMajor = p.godot_version.split('.')[0]
      const hasMatchingMajor = installed.some((v) => {
        const installedMajor = v.tag.split('.')[0]
        return installedMajor === projectMajor || v.version?.split('.')[0] === projectMajor
      })
      map[p.id] = hasMatchingMajor ? 'not_found' : 'major_mismatch'
    }
    return map
  }, [filteredProjects, installed])

  const projectsById = useMemo(
    () => new Map(projects.map((p) => [p.id, p])),
    [projects],
  )

  const sourceContainers = useMemo(() => {
    const map: Record<string, string[]> = {
      __pinned__: pinned.map((p) => p.id),
    }
    if (showCategories && categoriesEnabled) {
      for (const s of categorySections) map[s.key] = s.items.map((p) => p.id)
    } else {
      map.__flat__ = flatList.map((p) => p.id)
    }
    return map
  }, [pinned, categorySections, flatList, categoriesEnabled, showCategories])

  const [containers, setContainers] = useState<Record<string, string[]>>(
    () => sourceContainers,
  )
  useEffect(() => {
    if (!activeId) setContainers(sourceContainers)
  }, [sourceContainers])

  useMemo(() => {
    const ids: string[] = []
    for (const list of Object.values(containers)) {
      ids.push(...list)
    }
    allVisibleIdsRef.current = ids
  }, [containers])

  useEffect(() => {
    try {
      localStorage.setItem(COLLAPSED_CATS_KEY, JSON.stringify(collapsedCats))
    } catch {}
  }, [collapsedCats])

  useEffect(() => {
    try {
      localStorage.setItem(SORT_BY_KEY, sortBy)
    } catch {}
  }, [sortBy])

  const draggedProject = activeId ? (projectsById.get(activeId) ?? null) : null
  const canDropInZone = (kind: ZoneKind) =>
    draggedProject
      ? kind === 'pinned'
        ? draggedProject.pinned
        : !draggedProject.pinned
      : false

  const findContainer = (id: string): string | undefined =>
    id in containers
      ? id
      : Object.keys(containers).find((key) => containers[key].includes(id))

  const customCollisionDetection: CollisionDetection = useCallback((args) => {
    const pointerCollisions = pointerWithin(args)
    if (pointerCollisions.length > 0) return pointerCollisions
    return closestCorners(args)
  }, [])

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 4 } }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  )

  const handleDragStart = (e: DragStartEvent) => {
    setActiveId(e.active.id as string)
    const container = findContainer(e.active.id as string)
    setOverContainer(container ?? null)
  }

  const handleDragOver = (e: DragOverEvent) => {
    const { active, over } = e
    if (!over) {
      setOverContainer(null)
      return
    }
    const activeContainer = findContainer(active.id as string)
    const overContainer = findContainer(over.id as string)
    setOverContainer(overContainer ?? null)
    if (
      !activeContainer ||
      !overContainer ||
      activeContainer === overContainer ||
      !canDropInZone(kindOfZone(overContainer))
    )
      return
    setContainers((prev) => {
      const activeItems = prev[activeContainer]
      const overItems = prev[overContainer]
      const activeIndex = activeItems.indexOf(active.id as string)
      if (activeIndex === -1) return prev
      const overIndex = overItems.indexOf(over.id as string)
      const newIndex = overIndex >= 0 ? overIndex : overItems.length
      return {
        ...prev,
        [activeContainer]: activeItems.filter((id) => id !== active.id),
        [overContainer]: [
          ...overItems.slice(0, newIndex),
          active.id as string,
          ...overItems.slice(newIndex),
        ],
      }
    })
  }

  const handleDragEnd = async (e: DragEndEvent) => {
    const { active, over } = e
    setActiveId(null)
    setOverContainer(null)
    if (!over) return
    const id = active.id as string
    const activeContainer = findContainer(id)
    const overContainer = findContainer(over.id as string)
    if (!activeContainer || !overContainer || activeContainer !== overContainer)
      return

    let finalItems = containers[activeContainer]
    const oldIndex = finalItems.indexOf(id)
    const newIndex = finalItems.indexOf(over.id as string)
    if (oldIndex !== -1 && newIndex !== -1 && oldIndex !== newIndex) {
      finalItems = arrayMove(finalItems, oldIndex, newIndex)
      setContainers((prev) => ({ ...prev, [activeContainer]: finalItems }))
    }

    const kind = kindOfZone(activeContainer)
    if (kind === 'category') {
      const dragged = projectsById.get(id)
      const draggedZoneKey = dragged?.category ?? UNCATEGORIZED
      if (draggedZoneKey !== activeContainer) {
        await moveProject(
          id,
          activeContainer === UNCATEGORIZED ? '' : activeContainer,
          finalItems,
        )
        return
      }
    }
    await reorder(finalItems)
  }


  const fetchGitStatuses = useCallback(async () => {
    if (fetchingGitRef.current) return
    if (projects.length === 0) return
    fetchingGitRef.current = true
    try {
      const paths = projects.map((p) => p.path)
      const statuses = await api.batchGitStatus(paths)
      setGitStatusMap(statuses)
    } catch {
    } finally {
      fetchingGitRef.current = false
    }
  }, [projects])

  useEffect(() => {
    fetchGitStatuses()
    const interval = setInterval(fetchGitStatuses, 30000)

    const handleRefresh = () => fetchGitStatuses()
    window.addEventListener('app:refresh-git-status', handleRefresh)

    return () => {
      clearInterval(interval)
      window.removeEventListener('app:refresh-git-status', handleRefresh)
    }
  }, [fetchGitStatuses])

  const handleLaunchArgsChange = useCallback(async (id: string, args: string) => {
    await api.updateProject(id, { launch_arguments: args })
    await refresh()
  }, [refresh])

  const handleGitAction = useCallback(
    async (id: string, action: 'terminal' | 'pull' | 'push' | 'fetch' | 'log') => {
      const project = projects.find((p) => p.id === id)
      if (!project) return
      try {
        if (action === 'terminal') {
          await api.openTerminal(project.path)
        } else if (action === 'pull') {
          const result = await api.gitPull(project.path)
          alert(result || t('pull_completed'))
          setTimeout(fetchGitStatuses, 2000)
        } else if (action === 'push') {
          const result = await api.gitPush(project.path)
          alert(result || t('push_completed'))
          setTimeout(fetchGitStatuses, 2000)
        } else if (action === 'fetch') {
          await api.gitFetch(project.path)
          setTimeout(fetchGitStatuses, 2000)
        } else if (action === 'log') {
          await api.gitLog(project.path)
        }
      } catch (e) {
        alert(String(e))
      }
    },
    [projects, fetchGitStatuses],
  )

  const selectedCount = selectedIds.size

  const handleSelectAll = useCallback(() => {
    setSelectedIds(new Set(allVisibleIdsRef.current))
    lastClickedIdRef.current = null
  }, [])

  const handleBatchPin = useCallback(() => {
    if (selectedCount === 0) return
    setConfirmBatchPin(true)
  }, [selectedCount])

  const executeBatchPin = useCallback(async () => {
    setConfirmBatchPin(false)
    const allPinned = [...selectedIds].every((id) => projectsById.get(id)?.pinned)
    for (const id of selectedIds) {
      await setPinned(id, !allPinned)
    }
    handleClearSelection()
  }, [selectedIds, projectsById, setPinned, handleClearSelection])

  const handleBatchVersionChange = useCallback(
    (tag: string) => {
      if (selectedCount === 0) return
      setConfirmBatchVersion(tag)
    },
    [selectedCount],
  )

  const executeBatchVersionChange = useCallback(
    async () => {
      const tag = confirmBatchVersion
      setConfirmBatchVersion(null)
      if (!tag) return
      for (const id of selectedIds) {
        await updateVersion(id, tag)
      }
      handleClearSelection()
    },
    [confirmBatchVersion, selectedIds, updateVersion, handleClearSelection],
  )

  const handleBatchCategoryChange = useCallback(
    (category: string) => {
      if (selectedCount === 0) return
      setConfirmBatchCategory(category)
    },
    [selectedCount],
  )

  const executeBatchCategoryChange = useCallback(
    async () => {
      const category = confirmBatchCategory
      setConfirmBatchCategory(null)
      if (category == null) return
      for (const id of selectedIds) {
        await setCategory(id, category)
      }
      handleClearSelection()
    },
    [confirmBatchCategory, selectedIds, setCategory, handleClearSelection],
  )

  const handleBatchRemove = useCallback(() => {
    if (selectedCount === 0) return
    setConfirmBatchRemove(true)
  }, [selectedCount])

  const executeBatchRemove = useCallback(async () => {
    setConfirmBatchRemove(false)
    const removedPaths: string[] = []
    for (const id of selectedIds) {
      const project = projectsById.get(id)
      if (project) removedPaths.push(project.path)
      await remove(id, false)
    }
    handleClearSelection()
    if (undoBatchTimerRef.current) clearTimeout(undoBatchTimerRef.current)
    setUndoBatchData({ paths: removedPaths })
    undoBatchTimerRef.current = setTimeout(() => setUndoBatchData(null), 5000)
  }, [selectedIds, projectsById, remove, handleClearSelection])

  const handleUndoBatchRemove = useCallback(async () => {
    if (!undoBatchData) return
    const data = undoBatchData
    setUndoBatchData(null)
    for (const path of data.paths) {
      try {
        await api.importProject(path, '')
      } catch {}
    }
    refresh()
  }, [undoBatchData, refresh])

  const hasAnyProjects = projects.length > 0
  const hasVisibleProjects = filteredProjects.length > 0

  const renderCards = (zoneKey: string) => {
    const ids = containers[zoneKey] ?? []
    return (
      <SortableContext items={ids} strategy={verticalListSortingStrategy}>
        <div className="flex flex-col gap-3 min-h-[8px]">
          <AnimatePresence initial={false}>
            {ids.map((id) => {
              const entry = projectsById.get(id)
              if (!entry) return null
              return (
                <motion.div
                  layout="position"
                  key={id}
                  id={`project-${entry.id}`}
                  transition={{ duration: 0.18 }}
                >
                  <SortableProjectCard
                    project={entry}
                    disabled={dragDisabled}
                    installedVersions={installed}
                    categories={categories}
                    categoriesEnabled={categoriesEnabled}
                    launchWithConsole={settings.launch_with_console}
                    onRemove={() => remove(entry.id, false)}
                    onDelete={() => remove(entry.id, true)}
                    onVersionChange={(tag) => updateVersion(entry.id, tag)}
                    onCategoryChange={(category) => setCategory(entry.id, category)}
                    onTogglePin={() => setPinned(entry.id, !entry.pinned)}
                    onLaunchArgsChange={(args) => handleLaunchArgsChange(entry.id, args)}
                    gitStatus={gitStatusMap[entry.path] ?? null}
                    onGitAction={(action) => handleGitAction(entry.id, action)}
                    onOpenProperties={() => setPropertiesProject(entry)}
                    onShowGitSidebar={() => onShowGitSidebar?.(entry, gitStatusMap[entry.path] ?? null)}
                    draggable={!dragDisabled}
                    selected={selectedIds.has(entry.id)}
                    onToggleSelect={() => toggleSelect(entry.id)}
                    versionWarning={versionWarningMap[entry.id] ?? null}
                    lastOpenedTimeFormat={settings.last_opened_time_format}
                    lastOpenedDateFormat={settings.last_opened_date_format}
                  />
                </motion.div>
              )
            })}
          </AnimatePresence>
        </div>
      </SortableContext>
    )
  }

  return (
    <div className="p-10 pt-6 max-w-8xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="font-body font-semibold text-3xl tracking-tight">
            {t('projects_title')}
          </h2>
          <p className="text-xs text-muted">
            {t('project_count', { count: projects.length })}
            {isSearching && (
              <> · {t('showing_count', { count: filteredProjects.length })}</>
            )}
          </p>
        </div>
        <div className="flex items-center gap-3">
          {/* New Project, primary CTA */}
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={() => setModalOpen(true)}
            className="focus-ring flex cursor-pointer items-center gap-2 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
          >
            <span className="icon-wiggle inline-flex">
              <IconFolderPlus className="w-4 h-4" />
            </span>
            {t('new_project')}
          </motion.button>

          {/* Import split button, main action + clone dropdown */}
          <div ref={importDropdownRef} className="relative flex">
            <div className="flex rounded-lg border border-line">
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={handleImport}
                disabled={scanning || importing}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-ink transition-colors disabled:opacity-40 disabled:cursor-not-allowed border-r border-line"
              >
                <span className="icon-wiggle inline-flex">
                  <IconImport className="w-4 h-4" />
                </span>
                {t('import')}
              </motion.button>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setImportDropdownOpen((prev) => !prev)}
                className="focus-ring cursor-pointer px-2 py-2.5 text-muted hover:text-ink transition-colors"
                aria-label={t('more_import_options')}
              >
                <IconChevronDown className={`w-3 h-3 transition-transform duration-200 ${importDropdownOpen ? 'rotate-180 text-accent' : ''}`} />
              </motion.button>
            </div>
            <AnimatePresence>
              {importDropdownOpen && (
                <motion.div
                  initial={{ opacity: 0, y: -6, scale: 0.96 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: -6, scale: 0.96 }}
                  transition={{ duration: 0.15, ease: 'easeOut' }}
                  className="absolute right-0 top-full z-30 mt-2 min-w-44 rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-1.5 origin-top"
                >
                  <button
                    type="button"
                    onClick={() => { setImportDropdownOpen(false); setCloneRepoOpen(true) }}
                    className="w-full flex items-center cursor-pointer gap-2.5 px-5 py-2 rounded-lg text-xs font-medium text-ink hover:bg-raised transition-colors"
                  >
                    <IconGitBranch className="w-4 h-4 text-muted" />
                    {t('clone_import_repo')}
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Scan Now, icon only with tooltip */}
          <Tooltip content={scanning ? t('scanning') : t('scan_for_projects')} side="bottom">
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={handleScanNow}
              disabled={scanning || settings.project_scan_dirs.length === 0}
              className="focus-ring cursor-pointer p-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-muted hover:text-ink transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <IconRefresh className={`w-4 h-4 ${scanning ? 'animate-spin' : ''}`} />
            </motion.button>
          </Tooltip>

          {/* Categories, icon only with tooltip */}
          {categoriesEnabled && (
            <Tooltip content={t('manage_categories')} side="bottom">
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setCategoryModalOpen(true)}
                className="focus-ring cursor-pointer p-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-muted hover:text-ink transition-colors"
                aria-label={t('manage_categories')}
              >
                <IconTags className="w-4 h-4" />
              </motion.button>
            </Tooltip>
          )}
        </div>
      </div>

      {hasAnyProjects && (
        <div className="flex items-center gap-3 mb-8">
          <div className="relative flex-1">
            <IconSearch
              fill="none"
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted"
            />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={t('search_projects_placeholder')}
              className="focus-ring w-full bg-surface border border-line rounded-lg pl-9 pr-9 py-2.5 text-sm text-ink placeholder:text-muted transition-colors focus:border-accent-dim"
            />
            {isSearching && (
              <button
                type="button"
                onClick={() => setQuery('')}
                aria-label={t('clear_search')}
                className="focus-ring cursor-pointer absolute right-2.5 top-1/2 -translate-y-1/2 p-1 rounded-md text-muted hover:text-ink hover:bg-raised transition-colors"
              >
                <IconX className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            <IconArrowUpDown className="w-3.5 h-3.5 text-muted shrink-0" />
            <Dropdown
              className="w-44"
              value={sortBy}
              onChange={(v) => setSortBy((v || 'categories') as ProjectSortOption)}
              emptyLabel={t('sort')}
              options={SORT_OPTIONS.filter(
                (opt) => categoriesEnabled || opt.value !== 'categories',
              ).map((opt) => ({ ...opt, label: t(opt.labelKey) }))}
            />
          </div>
        </div>
      )}

      {!loaded ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
            <IconRefresh className="w-5 h-5 text-muted animate-spin" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {t('loading_projects')}
          </p>
        </div>
      ) : !hasAnyProjects ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
            <IconNode className="w-5 h-5 text-muted" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {t('no_projects_yet')}
          </p>
        </div>
      ) : !hasVisibleProjects ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
            <IconSearch fill="none" className="w-5 h-5 text-muted" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {t('no_projects_match')} &ldquo;{query.trim()}&rdquo;.
          </p>
        </div>
      ) : (
        <AnimatePresence mode="wait">

        <motion.div
          key="list"
          initial={{ opacity: 0, scale: 0.97 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.97 }}
          transition={{ duration: 0.18, ease: 'easeOut' }}
        >
        <DndContext
          sensors={sensors}
          collisionDetection={customCollisionDetection}
          onDragStart={(e) => {
            handleDragStart(e)
            handleClearSelection()
          }}
          onDragOver={handleDragOver}
          onDragEnd={handleDragEnd}
          onDragCancel={() => {
            setActiveId(null)
            setOverContainer(null)
            setContainers(sourceContainers)
          }}
        >
          <div className="flex flex-col gap-8">
            {(containers.__pinned__?.length ?? 0) > 0 && (() => {
              const pinnedIds = containers.__pinned__!
              const isOverPinned = overContainer === '__pinned__'
              return (
                <section className={activeId ? (isOverPinned ? 'relative' : 'opacity-60') : ''}>
                  <div className="flex items-center gap-2 mb-4">
                    <IconPin
                      className="w-3.5 h-3.5 text-accent-bright"
                      fill="currentColor"
                    />
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-muted">
                      {t('pinned_section')}
                    </h3>
                    {activeId && isOverPinned && (
                      <span className="ml-1 text-[10px] font-medium text-accent animate-pulse">
                        {t('drop_here_animated')}
                      </span>
                    )}
                  </div>
                  <SortableContext items={pinnedIds} strategy={verticalListSortingStrategy}>
                    <div className={`flex flex-col gap-3 min-h-[8px] rounded-xl transition-colors duration-150 ${activeId && isOverPinned ? 'bg-accent/5 ring-1 ring-accent/20 -mx-2 px-2 py-2' : ''}`}>
                      <AnimatePresence initial={false}>
                        {pinnedIds.map((id) => {
                          const entry = projectsById.get(id)
                          if (!entry) return null
                          return (
                            <motion.div
                              layout="position"
                              key={id}
                              transition={{ duration: 0.18 }}
                            >
                              <SortableProjectCard
                                project={entry}
                                disabled={dragDisabled}
                                installedVersions={installed}
                                categories={categories}
                                categoriesEnabled={categoriesEnabled}
                                launchWithConsole={settings.launch_with_console}
                                onRemove={() => remove(entry.id, false)}
                                onDelete={() => remove(entry.id, true)}
                                onVersionChange={(tag) => updateVersion(entry.id, tag)}
                                onCategoryChange={(category) => setCategory(entry.id, category)}
                                onTogglePin={() => setPinned(entry.id, !entry.pinned)}
                                onLaunchArgsChange={(args) => handleLaunchArgsChange(entry.id, args)}
                                gitStatus={gitStatusMap[entry.path] ?? null}
                                onGitAction={(action) => handleGitAction(entry.id, action)}
                                onOpenProperties={() => setPropertiesProject(entry)}
                                onShowGitSidebar={() => onShowGitSidebar?.(entry, gitStatusMap[entry.path] ?? null)}
                                draggable={!dragDisabled}
                                selected={selectedIds.has(entry.id)}
                                onToggleSelect={() => toggleSelect(entry.id)}
                                versionWarning={versionWarningMap[entry.id] ?? null}
                                lastOpenedTimeFormat={settings.last_opened_time_format}
                                lastOpenedDateFormat={settings.last_opened_date_format}
                              />
                            </motion.div>
                          )
                        })}
                      </AnimatePresence>
                    </div>
                  </SortableContext>
                </section>
              )
            })()}

            {showCategories && categoriesEnabled ? (
              (activeId ? categorySections : categorySections.filter(({ items }) => items.length > 0))
                .map(({ key, label }) => {
                const ids = containers[key] ?? []
                const collapsed = collapsedCats[key]
                const isOver = overContainer === key
                const catColor =
                  label === t('uncategorized')
                    ? undefined
                    : categories.find((c) => c.name === label)?.color
                const isEmpty = ids.length === 0
                return (
                  <section key={key} className={activeId && !isOver && !isEmpty ? 'opacity-60' : ''}>
                    <div className="flex items-center gap-1.5 text-xs font-semibold text-muted uppercase tracking-wide mb-4">
                      <button
                        onClick={() =>
                          setCollapsedCats((prev) => ({
                            ...prev,
                            [key]: !prev[key],
                          }))
                        }
                        onPointerDown={(e) => e.stopPropagation()}
                        className="focus-ring cursor-pointer inline-flex items-center justify-center w-5 h-5 rounded hover:ring-1 hover:bg-raised transition-all"
                        aria-label={collapsed ? t('expand_category', { name: label }) : t('collapse_category', { name: label })}
                        style={
                          catColor
                            ? ({ '--tw-ring-color': catColor } as React.CSSProperties)
                            : undefined
                        }
                      >
                        <IconChevronDown
                          className={`w-3 h-3 transition-transform ${collapsed ? '-rotate-90' : ''}`}
                          style={catColor ? { color: catColor } : undefined}
                        />
                      </button>
                      {label}{' '}
                      <span className="text-muted/50 normal-case font-normal">
                        · {ids.length}
                      </span>
                      {activeId && isOver && (
                        <span className="ml-1 text-[10px] font-medium text-accent animate-pulse normal-case">
                          {t('drop_here_animated')}
                        </span>
                      )}
                    </div>
                    <AnimatePresence initial={false}>
                      {!collapsed && (
                        <motion.div
                          initial={{ opacity: 0, height: 0 }}
                          animate={{ opacity: 1, height: 'auto' }}
                          exit={{ opacity: 0, height: 0 }}
                          transition={{ duration: 0.15 }}
                        >
                          <div className={activeId && isOver && !isEmpty ? 'bg-accent/5 rounded-xl ring-1 ring-accent/20 -mx-2 px-2 py-2 transition-colors duration-150' : ''}>
                            {isEmpty ? (
                              <div className={activeId ? 'group -mx-2 px-2 py-1' : ''}>
                                <ZoneDropArea zoneKey={key} />
                              </div>
                            ) : (
                              renderCards(key)
                            )}
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </section>
                )
              })
            ) : (
              <section>
                <div className={activeId && overContainer === '__flat__' ? 'bg-accent/5 rounded-xl ring-1 ring-accent/20 -mx-2 px-2 py-2 transition-colors duration-150' : ''}>
                  {renderCards('__flat__')}
                </div>
              </section>
            )}
          </div>

          <DragOverlay
            dropAnimation={{
              duration: 300,
              easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
            style={{
              cursor: 'grabbing',
              filter: 'drop-shadow(0 8px 24px rgba(0,0,0,0.4))',
            }}
          >
            {draggedProject ? (
              <ProjectCard
                project={draggedProject}
                installedVersions={installed}
                categories={categories}
                categoriesEnabled={categoriesEnabled}
                launchWithConsole={settings.launch_with_console}
                onRemove={() => {}}
                onDelete={() => {}}
                onVersionChange={() => {}}
                onCategoryChange={() => {}}
                onTogglePin={() => {}}
                onLaunchArgsChange={() => {}}
                onGitAction={() => {}}
                onOpenProperties={() => {}}
                onShowGitSidebar={() => {}}
                draggable
                lastOpenedTimeFormat={settings.last_opened_time_format}
                lastOpenedDateFormat={settings.last_opened_date_format}
              />
            ) : null}
          </DragOverlay>          </DndContext>
        </motion.div>
      </AnimatePresence>
      )}

      {/* Floating batch action bar */}
      <AnimatePresence>
        {selectedCount > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.96 }}
            transition={{ duration: 0.18, ease: 'easeOut' }}
            className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-surface border border-line shadow-2xl shadow-black/40"
          >
            <span className="text-xs font-medium text-muted whitespace-nowrap mr-1">
              {t('n_selected', { count: selectedCount })}
            </span>

            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={() => {
                const allSelected = selectedIds.size === allVisibleIdsRef.current.length && allVisibleIdsRef.current.length > 0
                if (allSelected) {
                  handleClearSelection()
                } else {
                  handleSelectAll()
                }
              }}
              className="focus-ring cursor-pointer px-2.5 py-1.5 rounded-lg text-xs font-semibold text-muted hover:text-ink hover:bg-raised transition-colors"
              aria-label={selectedIds.size === allVisibleIdsRef.current.length && allVisibleIdsRef.current.length > 0 ? t('deselect_all') : t('select_all')}
            >
              {selectedIds.size === allVisibleIdsRef.current.length && allVisibleIdsRef.current.length > 0 ? t('deselect_all') : t('select_all')}
            </motion.button>

            <div className="h-5 w-px bg-line/60" />

            <Tooltip content={selectedIds.size === 1 ? t('toggle_pin') : t('pin_unpin_all')} side="top">
              <motion.button
                whileTap={{ scale: 0.92 }}
                onClick={handleBatchPin}
                className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors"
                aria-label={t('toggle_pin')}
              >
                <IconPin className="w-3.5 h-3.5" fill="none" />
              </motion.button>
            </Tooltip>

            <Dropdown
              className="w-44"
              value=""
              onChange={(tag) => tag && handleBatchVersionChange(tag)}
              emptyLabel={t('set_version')}
              openUp
              options={installed.map((v) => ({
                value: v.tag,
                label: v.custom_name || v.version,
                dotClassName: 'bg-mint',
                badge: v.is_mono ? 'Mono' : undefined,
              }))}
            />

            <Dropdown
              className="w-36"
              value=""
              onChange={(cat) => {
                if (cat != null) {
                  const resolved = cat === UNCATEGORIZED ? '' : cat
                  handleBatchCategoryChange(resolved)
                }
              }}
              emptyLabel={t('set_category')}
              openUp
              options={availableCategories.map((c) => ({
                value: c,
                label: c === UNCATEGORIZED ? t('uncategorized') : c,
              }))}
            />

            <div className="h-5 w-px bg-line/60" />

            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={handleBatchRemove}
              className="focus-ring cursor-pointer px-2.5 py-1.5 rounded-lg text-xs font-semibold text-muted hover:text-danger hover:bg-danger/10 transition-colors"
              aria-label={t('remove_selected')}
            >
              {t('remove_selected')}
            </motion.button>

            <div className="h-5 w-px bg-line/60" />

            <Tooltip content={t('clear_selection')} side="top">
              <motion.button
                whileTap={{ scale: 0.92 }}
                onClick={handleClearSelection}
                className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors ml-1"
                aria-label={t('clear_selection')}
              >
                <IconX className="w-3.5 h-3.5" />
              </motion.button>
            </Tooltip>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmBatchRemove && (
          <ConfirmDialog
            title={t('remove_count_title', { count: selectedCount })}
            description={t('remove_count_desc', { count: selectedCount })}
            confirmLabel={t('remove_count_confirm', { count: selectedCount })}
            variant="danger"
            onConfirm={executeBatchRemove}
            onCancel={() => setConfirmBatchRemove(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmBatchPin && (
          <ConfirmDialog
            title={selectedCount === 1 ? t('pin_unpin_title_one', { count: selectedCount }) : t('pin_unpin_title_other', { count: selectedCount })}
            description={t('pin_unpin_desc', { action: [...selectedIds].every((id) => projectsById.get(id)?.pinned) ? 'unpin' : 'pin' })}
            confirmLabel={t('confirm')}
            variant="default"
            onConfirm={executeBatchPin}
            onCancel={() => setConfirmBatchPin(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmBatchVersion && (
          <ConfirmDialog
            title={t('set_version_title', { count: selectedCount })}
            description={t('set_version_desc', { version: confirmBatchVersion })}
            confirmLabel={t('set_to_version', { version: confirmBatchVersion })}
            variant="default"
            onConfirm={executeBatchVersionChange}
            onCancel={() => setConfirmBatchVersion(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmBatchCategory != null && (
          <ConfirmDialog
            title={t('set_category_title', { count: selectedCount })}
            description={t('set_category_desc', { category: confirmBatchCategory === '' ? t('uncategorized') : confirmBatchCategory })}
            confirmLabel={t('set_to_category', { category: confirmBatchCategory === '' ? t('uncategorized') : confirmBatchCategory })}
            variant="default"
            onConfirm={executeBatchCategoryChange}
            onCancel={() => setConfirmBatchCategory(null)}
          />
        )}
      </AnimatePresence>

      {/* Undo snackbar after batch remove */}
      <AnimatePresence>
        {undoBatchData && (
          <motion.div
            initial={{ opacity: 0, y: -30, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.95 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="fixed top-20 left-1/2 -translate-x-1/2 z-110 flex items-center gap-3 px-5 py-3 rounded-xl bg-surface/95 border border-line/60 shadow-2xl backdrop-blur-md max-w-lg"
          >
            <div className="w-8 h-8 rounded-full bg-raised flex items-center justify-center shrink-0">
              <IconRefresh className="w-4 h-4 text-muted" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-ink uppercase tracking-wide">
                {t('removed_from_library')}
              </p>
              <p className="text-sm text-muted mt-0.5 truncate">
                {t('n_removed', { count: undoBatchData.paths.length })}
              </p>
            </div>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={handleUndoBatchRemove}
              className="focus-ring cursor-pointer shrink-0 px-3 py-1.5 rounded-lg bg-accent/10 border border-accent/20 text-accent-bright text-xs font-semibold hover:bg-accent/20 transition-colors"
            >
              {t('undo')}
            </motion.button>
            <Tooltip content={t('dismiss')} side="bottom">
              <button
                onClick={() => setUndoBatchData(null)}
                className="focus-ring cursor-pointer shrink-0 p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors"
                aria-label={t('dismiss')}
              >
                <IconX className="w-3.5 h-3.5" />
              </button>
            </Tooltip>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {cloneRepoOpen && (
          <CloneRepoModal
            defaultLocation={settings.default_project_location}
            onClose={() => setCloneRepoOpen(false)}
            onCloned={handleCloneResult}
          />
        )}
      </AnimatePresence>

      {modalOpen && (
        <CreateProjectModal
          installedVersions={installed}
          defaultLocation={settings.default_project_location}
          categories={categories}
          onClose={() => setModalOpen(false)}
          onCreated={() => {
            setModalOpen(false)
            refresh()
          }}
        />
      )}

      <AnimatePresence>
        {propertiesProject && (
          <ProjectPropertiesModal
            project={propertiesProject}
            onClose={() => setPropertiesProject(null)}
          />
        )}
      </AnimatePresence>

      {categoryModalOpen && (
        <CategoryManagerModal
          categories={categories}
          onClose={() => { setCategoryModalOpen(false); refresh() }}
          onCreate={createCategory}
          onUpdate={updateCategory}
          onDelete={async (id) => {
            await removeCategory(id)
            refresh()
          }}
          onReorder={reorderCategories}
        />
      )}
      {(scanning || importing) && !dialogMinimized && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-surface border border-line rounded-2xl px-8 py-6 flex flex-col items-center gap-3 min-w-64">
            <IconRefresh className="w-6 h-6 animate-spin text-accent" />
            <p className="text-sm font-medium text-ink">
              {importing
                ? t('importing_project')
                : scanProgress && scanProgress.total > 0
                  ? t('importing_progress', { current: scanProgress.current, total: scanProgress.total })
                  : t('scanning_projects')}
            </p>
            {scanProgress && scanProgress.total > 0 && (
              <div className="h-1.5 w-full rounded-full bg-line overflow-hidden">
                <div
                  className="h-full bg-accent transition-all duration-200"
                  style={{
                    width: `${(scanProgress.current / scanProgress.total) * 100}%`,
                  }}
                />
              </div>
            )}
            <button
              onClick={() => setDialogMinimized(true)}
              className="focus-ring cursor-pointer text-xs text-muted hover:text-ink transition-colors mt-1"
            >
              {t('resume_background')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
