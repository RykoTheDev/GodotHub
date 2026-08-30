import { useCallback, useMemo, useState, type ReactNode, createContext, useContext } from 'react'
import { AnimatePresence, motion, type Transition } from 'framer-motion'
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  KeyboardSensor,
  useDroppable,
  useSensor,
  useSensors,
  closestCenter,
  type DragStartEvent,
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
import { AnimatedNumber } from '../reusables/AnimatedNumber'
import { useTranslation } from 'react-i18next'
import { IconChevronDown, IconNode, IconPin } from '../../lib/icons'
import { DragHandle } from '../reusables/DragHandle'
import { isReducedMotion } from '../../lib/appearance'
import type { Category, Project } from '../../types'

const DEFAULT_ANIMATION_THRESHOLD = 20
const UNCATEGORIZED = '__uncategorized__'

export interface PinChange {
  id: string
  pinned: boolean
}

export interface CategoryChange {
  id: string
  category: string
}

interface ProjectCardListProps {
  projects: Project[]
  renderCard: (project: Project) => ReactNode
  hasActiveFilters: boolean
  totalCount: number
  animationThreshold?: number
  categories?: Category[]
  categoriesEnabled?: boolean
  onReorder?: (orderedIds: string[]) => Promise<void>
  onMoveProject?: (id: string, category: string, destOrderedIds: string[]) => Promise<void>
}

interface DragContext {
  activeDragId: string | null
  categoryMap: Map<string, string>
}

const DragStateContext = createContext<DragContext>({
  activeDragId: null,
  categoryMap: new Map(),
})

function SortableProjectCard({
  id,
  disabled,
  children,
}: {
  id: string
  disabled?: boolean
  children: React.ReactNode
}) {
  const {
    setNodeRef,
    setActivatorNodeRef,
    attributes,
    listeners,
    transform,
    transition,
    isDragging,
  } = useSortable({ id, disabled })

  const { activeDragId, categoryMap } = useContext(DragStateContext)

  const activeCat = activeDragId ? categoryMap.get(activeDragId) : null
  const thisCat = categoryMap.get(id)
  const isCrossCategoryDrag = activeDragId != null && activeCat != null && thisCat != null && activeCat !== thisCat

  const isSameCategory = !isCrossCategoryDrag && activeDragId != null && thisCat === activeCat
  const suppressTransform = isCrossCategoryDrag || isSameCategory

  const style: React.CSSProperties = {
    transform: suppressTransform ? undefined : CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.35 : 1,
    zIndex: isDragging ? 50 : undefined,
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`group/drag relative transition-[box-shadow,border-color] duration-200 rounded-item ${
        isDragging ? 'shadow-lg shadow-accent/8 ring-1 ring-accent/20' : ''
      }`}
    >
      <DragHandle
        ref={setActivatorNodeRef}
        attributes={attributes}
        listeners={listeners}
        isDragging={isDragging}
        disabled={disabled}
        className="absolute top-1/2 -translate-y-1/2 "
      />
      {children}

    </div>
  )
}

function CategorySection({
  title,
  color,
  count,
  children,
  defaultOpen = true,
  disableAnimation = false,
  droppableId,
}: {
  title: string
  color?: string
  count: number
  children: ReactNode
  defaultOpen?: boolean
  disableAnimation?: boolean
  droppableId?: string
}) {
  const { t } = useTranslation('common')
  const [open, setOpen] = useState(defaultOpen)
  const isEmpty = count === 0
  const { isOver, setNodeRef } = useDroppable({
    id: droppableId ?? `list-cat-${title}`,
    disabled: !isEmpty,
  })

  return (
    <div className="flex flex-col">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
        className="focus-ring cursor-pointer w-full flex items-center gap-1.5 px-1 py-1 rounded-item text-left hover:bg-raised/60 transition-colors group"
      >
        <IconChevronDown
          className={`w-3 h-3 text-muted/50 shrink-0 transition-transform duration-200 ${
            open ? '' : '-rotate-90'
          }`}
        />
        {color && (
          <span
            className="w-2 h-2 rounded-full shrink-0"
            style={{ backgroundColor: color }}
          />
        )}
        <span className="text-xs font-semibold uppercase tracking-wider text-muted/50 group-hover:text-muted transition-colors">
          {title}
        </span>
        <div className="flex-1 h-px bg-outline/30 mx-1.5" />
        <span className="text-[10px] font-medium text-muted/50 tabular-nums shrink-0">
          · <AnimatedNumber value={count} />
        </span>
      </button>

      <div
        className={`grid ${disableAnimation ? '' : 'transition-[grid-template-rows] duration-200 ease-out'} ${
          open ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'
        }`}
      >
        <div className="overflow-hidden min-h-0">
          <div
            ref={isEmpty ? setNodeRef : undefined}
            className={`flex flex-col gap-2 pt-2 pb-0.5 rounded-item transition-colors duration-150 ${
              isOver ? 'bg-accent/10 ring-1 ring-accent/30' : ''
            }`}
          >
            {children}
            {isEmpty && !isOver && (
              <div className="flex items-center justify-center py-6">
                <span className="text-xs text-muted/40 select-none">{t('empty_category')}</span>
              </div>
            )}
            {isEmpty && isOver && (
              <div className="flex items-center justify-center py-6">
                <span className="text-xs text-accent-bright font-medium select-none">{t('release_to_drop')}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export function ProjectCardList({
  projects,
  renderCard,
  hasActiveFilters,
  totalCount,
  animationThreshold = DEFAULT_ANIMATION_THRESHOLD,
  categories = [],
  categoriesEnabled = false,
  onReorder,
  onMoveProject,
}: ProjectCardListProps) {
  const { t } = useTranslation('common')

  const animateList =
    totalCount <= animationThreshold && !isReducedMotion()
  const layoutTransition: Transition = {
    type: 'spring',
    stiffness: 350,
    damping: 30,
    mass: 0.8,
  }

  const cardFor = (p: Project) => {
    const card = renderCard(p)
    if (!animateList) {
      return <div key={p.id} className="min-w-0">{card}</div>
    }
    return (
      <motion.div
        key={p.id}
        layout
        layoutId={p.id}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, transition: { duration: 0.12 } }}
        transition={layoutTransition}
        className="min-w-0"
      >
        {card}
      </motion.div>
    )
  }

  const showPinnedSection = projects.some((p) => p.pinned)
  const pinnedProjects = showPinnedSection
    ? projects.filter((p) => p.pinned)
    : []
  const unpinnedProjects = showPinnedSection
    ? projects.filter((p) => !p.pinned)
    : projects

  const categoryGroups = useMemo(() => {
    if (!categoriesEnabled || categories.length === 0) {
      return null
    }
    const groups = new Map<string, Project[]>()
    for (const p of unpinnedProjects) {
      const cat = p.category || UNCATEGORIZED
      if (!groups.has(cat)) groups.set(cat, [])
      groups.get(cat)!.push(p)
    }
    return groups
  }, [categoriesEnabled, categories, unpinnedProjects])

  // --- Drag and Drop ---
  const isDndEnabled = categoriesEnabled && Boolean(onReorder)

  const dndSensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  )

  const [activeDragId, setActiveDragId] = useState<string | null>(null)

  const projectsById = useMemo(
    () => new Map(projects.map((p) => [p.id, p])),
    [projects],
  )

  const sortableIds = useMemo(
    () => unpinnedProjects.map((p) => p.id),
    [unpinnedProjects],
  )

  const categoryMap = useMemo(() => {
    const map = new Map<string, string>()
    for (const p of unpinnedProjects) {
      map.set(p.id, p.category || UNCATEGORIZED)
    }
    return map
  }, [unpinnedProjects])

  const handleDragStart = useCallback((e: DragStartEvent) => {
    setActiveDragId(e.active.id as string)
  }, [])

  const handleDragEnd = useCallback(
    async (e: DragEndEvent) => {
      const { active, over } = e
      setActiveDragId(null)
      if (!over || active.id === over.id) return

      const draggedId = active.id as string
      const targetId = over.id as string

      const draggedProject = projectsById.get(draggedId)
      if (!draggedProject) return

      if (!onReorder) return

      // Check if dropped onto a category droppable (empty category)
      const catDropMatch = targetId.match(/^list-cat-(.+)$/) 
      if (catDropMatch && onMoveProject) {
        const catId = catDropMatch[1]
        const targetCat = catId === 'uncategorized' 
          ? UNCATEGORIZED 
          : categories.find((c) => c.id === catId)?.name ?? catId
        const draggedCat = draggedProject.category || UNCATEGORIZED
        if (draggedCat === targetCat) return
        const destProjects = unpinnedProjects.filter(
          (p) => (p.category || UNCATEGORIZED) === targetCat,
        )
        const newDest = [...destProjects]
        newDest.push(draggedProject)
        await onMoveProject(draggedId, targetCat === UNCATEGORIZED ? '' : targetCat, newDest.map((p) => p.id))
        return
      }

      const targetProject = projectsById.get(targetId)
      if (!targetProject) return

      const draggedCat = draggedProject.category || UNCATEGORIZED
      const targetCat = targetProject.category || UNCATEGORIZED

      if (draggedCat !== targetCat && onMoveProject) {
        const destProjects = unpinnedProjects.filter(
          (p) => (p.category || UNCATEGORIZED) === targetCat,
        )
        const destTargetIdx = destProjects.findIndex((p) => p.id === targetId)
        const insertIdx = destTargetIdx >= 0 ? destTargetIdx : destProjects.length
        const newDest = [...destProjects]
        newDest.splice(insertIdx, 0, draggedProject)
        await onMoveProject(draggedId, targetCat === UNCATEGORIZED ? '' : targetCat, newDest.map((p) => p.id))
      } else if (draggedCat === targetCat) {
        const catProjects = unpinnedProjects.filter(
          (p) => (p.category || UNCATEGORIZED) === draggedCat,
        )
        const oldIdx = catProjects.findIndex((p) => p.id === draggedId)
        const newIdx = catProjects.findIndex((p) => p.id === targetId)
        if (oldIdx !== -1 && newIdx !== -1) {
          const reordered = arrayMove(catProjects, oldIdx, newIdx)
          await onReorder(reordered.map((p) => p.id))
        }
      }
    },
    [projectsById, unpinnedProjects, categories, onReorder, onMoveProject],
  )

  const draggedProject = activeDragId ? projectsById.get(activeDragId) ?? null : null

  const dragContextValue = useMemo(
    () => ({ activeDragId, categoryMap }),
    [activeDragId, categoryMap],
  )

  const pinnedHeader = (
    <div className="mt-1 mb-0.5 flex items-center gap-2 px-1 rounded-item">
      <IconPin className="w-3 h-3 text-accent-bright" fill="currentColor" />
      <span className="text-[10px] font-semibold uppercase tracking-wider text-muted">
        {t('pinned_section')}
      </span>
      <span className="text-[10px] font-medium text-muted/50 tabular-nums">
        · <AnimatedNumber value={pinnedProjects.length} />
      </span>
      <div className="flex-1 h-px bg-outline/50" />
    </div>
  )

  const emptyState = animateList ? (
    <motion.div
      key="empty"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.15 }}
      className="h-full flex flex-col items-center justify-center gap-2 text-center"
    >
      <IconNode className="w-5 h-5 text-muted/50" />
      <p className="text-sm text-muted">
        {hasActiveFilters ? t('no_projects_match') : t('no_projects_yet')}
      </p>
    </motion.div>
  ) : (
    <div
      key="empty"
      className="h-full flex flex-col items-center justify-center gap-2 text-center"
    >
      <IconNode className="w-5 h-5 text-muted/50" />
      <p className="text-sm text-muted">
        {hasActiveFilters ? t('no_projects_match') : t('no_projects_yet')}
      </p>
    </div>
  )

  const cardForDnd = (p: Project) => {
    const card = renderCard(p)
    return (
      <SortableProjectCard
        key={p.id}
        id={p.id}
      >
        <div className="px-2">{card}</div>
      </SortableProjectCard>
    )
  }

  const dndCategoryGroups = useMemo(() => {
    if (!categoriesEnabled || categories.length === 0 || !isDndEnabled) {
      return null
    }
    const groups = new Map<string, Project[]>()
    for (const p of unpinnedProjects) {
      const cat = p.category || UNCATEGORIZED
      if (!groups.has(cat)) groups.set(cat, [])
      groups.get(cat)!.push(p)
    }
    return groups
  }, [categoriesEnabled, categories, unpinnedProjects, isDndEnabled])

  const listChildren: ReactNode[] = projects.length === 0
    ? [emptyState]
    : showPinnedSection
      ? [
          <div
            key="pinned-top-divider"
            className="h-0.5 my-1 bg-outline"
            style={{ backgroundColor: 'var(--color-outline)' }}
          />,
          pinnedHeader,
          ...pinnedProjects.map((p) => cardFor(p)),
          <div
            key="pinned-bottom-divider"
            className="h-0.5 my-1 bg-outline"
            style={{ backgroundColor: 'var(--color-outline)' }}
          />,
          ...(dndCategoryGroups || categoryGroups
            ? renderCategoryGroups(
                (dndCategoryGroups || categoryGroups)!,
                categories,
                isDndEnabled ? cardForDnd : cardFor,
                isDndEnabled,
              )
            : unpinnedProjects.map((p) => isDndEnabled ? cardForDnd(p) : cardFor(p))),
        ]
      : (dndCategoryGroups || categoryGroups)
        ? renderCategoryGroups(
            (dndCategoryGroups || categoryGroups)!,
            categories,
            isDndEnabled ? cardForDnd : cardFor,
            isDndEnabled,
          )
        : projects.map((p) => isDndEnabled ? cardForDnd(p) : cardFor(p))

  if (isDndEnabled) {
    return (
      <div className="flex-1 min-h-0 relative flex flex-col gap-2">
        <DragStateContext.Provider value={dragContextValue}>
          <DndContext
            sensors={dndSensors}
            collisionDetection={closestCenter}
            onDragStart={handleDragStart}
            onDragEnd={handleDragEnd}
          >
            <SortableContext
              items={sortableIds}
              strategy={verticalListSortingStrategy}
            >
              {listChildren}
            </SortableContext>
            <DragOverlay
              dropAnimation={{
                duration: 280,
                easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
              }}
            >
              {draggedProject ? (
                <div className="rounded-item shadow-2xl shadow-black/30 scale-[1.015] ring-1 ring-accent/20 bg-overlay/95 backdrop-blur-sm">
                  {renderCard(draggedProject)}
                </div>
              ) : null}
            </DragOverlay>
          </DndContext>
        </DragStateContext.Provider>
        {projects.length > 0 && (
          <div className="shrink-0 h-4" aria-hidden="true" />
        )}
      </div>
    )
  }

  return (
    <div className="flex-1 min-h-0 relative flex flex-col gap-2">
      {animateList ? (
        <AnimatePresence initial={false}>{listChildren}</AnimatePresence>
      ) : (
        listChildren
      )}
      {projects.length > 0 && (
        <div className="shrink-0 h-4" aria-hidden="true" />
      )}
    </div>
  )
}

function renderCategoryGroups(
  groups: Map<string, Project[]>,
  categories: Category[],
  cardFor: (p: Project) => ReactNode,
  disableAnimation = false,
): ReactNode[] {
  const result: ReactNode[] = []

  for (const cat of categories) {
    const projs = groups.get(cat.name) ?? []
    if (projs.length === 0) continue
    result.push(
      <CategorySection
        key={`cat-${cat.id}`}
        title={cat.name}
        color={cat.color}
        count={projs.length}
        defaultOpen={projs.length > 0}
        disableAnimation={disableAnimation}
        droppableId={`list-cat-${cat.id}`}
      >
        {projs.map((p) => cardFor(p))}
      </CategorySection>,
    )
  }

  const uncategorized = groups.get(UNCATEGORIZED) ?? []
  if (uncategorized.length > 0) {
    result.push(
      <CategorySection
        key="cat-uncategorized"
        title="Uncategorized"
        count={uncategorized.length}
        defaultOpen={uncategorized.length > 0}
        disableAnimation={disableAnimation}
        droppableId="list-cat-uncategorized"
      >
        {uncategorized.map((p) => cardFor(p))}
      </CategorySection>,
    )
  }

  return result
}
