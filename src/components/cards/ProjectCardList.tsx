import { useId, useMemo, type MouseEvent as ReactMouseEvent, type ReactNode } from 'react'
import { AnimatePresence, LayoutGroup, motion, type Transition } from 'framer-motion'
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core'
import {
  SortableContext,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable'
import { AnimatedNumber } from '../reusables/AnimatedNumber'
import { useTranslation } from 'react-i18next'
import { IconNode, IconPin } from '../../lib/icons'
import {
  HiddenCategoriesSection,
  ProjectCategorySection,
  type HiddenCategoryEntry,
} from './CategorySections'
import { useUiMotion } from '../../hooks/useUiMotion'
import { hasOnlyPinnedProjects, UNCATEGORIZED_KEY } from '../../lib/projectDrag'
import { AUTO_SCROLL_CONFIG } from '../../lib/dragFeel'
import { useProjectDnd } from '../../hooks/useProjectDnd'
import {
  ProjectDragOverlay,
  ProjectDropLine,
  SortableProjectItem,
} from '../dnd/ProjectDnd'
import type { Category, Project } from '../../types'

const DEFAULT_ANIMATION_THRESHOLD = 20
const UNCATEGORIZED = UNCATEGORIZED_KEY

interface ProjectCardListProps {
  projects: Project[]
  renderCard: (project: Project) => ReactNode
  hasActiveFilters: boolean
  totalCount: number
  animationThreshold?: number
  categories?: Category[]
  categoriesEnabled?: boolean
  onReorder?: (orderedIds: string[]) => Promise<void>
  onMoveProjects?: (
    ids: string[],
    category: string,
    destOrderedIds: string[],
  ) => Promise<void>
  hiddenCategories?: HiddenCategoryEntry[]
  onUnhideCategory?: (id: string) => void
  onCategoryContextMenu?: (
    e: ReactMouseEvent<HTMLElement>,
    category: Category,
  ) => void
  selectedIds?: Set<string>
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
  onMoveProjects,
  hiddenCategories = [],
  onUnhideCategory,
  onCategoryContextMenu,
  selectedIds,
}: ProjectCardListProps) {
  const { t } = useTranslation('common')
  const layoutGroupId = useId()

  const uiMotion = useUiMotion()
  const animateList = totalCount <= animationThreshold && !uiMotion.reduced && !uiMotion.instant
  const layoutTransition: Transition = uiMotion.transition('press')

  const showPinnedSection = projects.some((p) => p.pinned)
  const pinnedProjects = showPinnedSection
    ? projects.filter((p) => p.pinned)
    : []
  const unpinnedProjects = showPinnedSection
    ? projects.filter((p) => !p.pinned)
    : projects

  const grouped = categoriesEnabled && categories.length > 0

  const groups = useMemo(() => {
    const map = new Map<string, Project[]>()
    for (const p of unpinnedProjects) {
      const key = p.category || UNCATEGORIZED
      const list = map.get(key)
      if (list) list.push(p)
      else map.set(key, [p])
    }
    return map
  }, [unpinnedProjects])

  const orderedCategoryKeys = useMemo(() => {
    const keys: string[] = []
    for (const cat of categories) {
      if (groups.has(cat.name)) keys.push(cat.name)
    }
    if (groups.has(UNCATEGORIZED)) keys.push(UNCATEGORIZED)
    for (const key of groups.keys()) {
      if (!keys.includes(key)) keys.push(key)
    }
    return keys
  }, [categories, groups])

  const sortableProjects = useMemo(() => {
    if (!grouped) return unpinnedProjects
    const ordered: Project[] = []
    for (const key of orderedCategoryKeys) {
      ordered.push(...(groups.get(key) ?? []))
    }
    return ordered
  }, [grouped, unpinnedProjects, orderedCategoryKeys, groups])

  const sortableIds = useMemo(
    () => sortableProjects.map((p) => p.id),
    [sortableProjects],
  )

  const isDndEnabled = Boolean(onReorder)

  const dnd = useProjectDnd({
    projects: sortableProjects,
    categories,
    grouped,
    prefixes: { category: 'list-cat-' },
    selectedIds,
    onReorder,
    onMoveProjects,
  })

  const cardBody = (p: Project) => renderCard(p)

  const animatedCard = (p: Project) =>
    animateList ? (
      <motion.div
        key={p.id}
        layoutId={dnd.activeId ? undefined : p.id}
        initial={false}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0, transition: { duration: 0.12 } }}
        transition={layoutTransition}
        className="min-w-0"
      >
        {cardBody(p)}
      </motion.div>
    ) : (
      <div key={p.id} className="min-w-0">
        {cardBody(p)}
      </div>
    )

  const pinnedCard = (p: Project) =>
    animateList ? (
      <motion.div
        key={p.id}
        layout
        layoutId={p.id}
        initial={false}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0, transition: { duration: 0.12 } }}
        transition={layoutTransition}
        className="min-w-0"
      >
        {cardBody(p)}
      </motion.div>
    ) : (
      <div key={p.id} className="min-w-0">
        {cardBody(p)}
      </div>
    )

  const sortableCard = (p: Project) => (
    <SortableProjectItem
      key={p.id}
      id={p.id}
      carried={dnd.activeIds.includes(p.id)}
      static={dnd.activeIds.length > 1}
      className="px-2"
      gripClassName="left-0.5"
    >
      {animatedCard(p)}
    </SortableProjectItem>
  )

  const cardFor = isDndEnabled ? sortableCard : animatedCard

  // Exiting sections leave the flex layout immediately while their card transfers.
  const categorySection = (key: string, children: ReactNode) => animateList ? (
    <motion.div
      key={key}
      layout="position"
      initial={false}
      exit={{ opacity: 0, transition: { duration: 0.12 } }}
      transition={layoutTransition}
      className="min-w-0"
    >
      {children}
    </motion.div>
  ) : <div key={key} className="min-w-0">{children}</div>

  const pinnedHeader = (
    <div
      key="pinned-header"
      className="mt-1 mb-0.5 flex items-center gap-2 px-1 rounded-item"
    >
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

  const renderGrouped = (): ReactNode[] => {
    const result: ReactNode[] = []
    for (const cat of categories) {
      const projs = groups.get(cat.name) ?? []
      if (!dnd.activeId && hasOnlyPinnedProjects(projects, cat.name)) continue
      result.push(categorySection(`cat-${cat.id}`,
        <ProjectCategorySection
          key={`cat-${cat.id}`}
          title={cat.name}
          color={cat.color}
          count={projs.length}
          defaultOpen={projs.length > 0}
          disableAnimation={isDndEnabled}
          droppableId={`list-cat-${cat.id}`}
          onContextMenu={
            onCategoryContextMenu
              ? (e) => onCategoryContextMenu(e, cat)
              : undefined
          }
        >
          <SortableContext items={projs.map((p) => p.id)} strategy={verticalListSortingStrategy}>
            {projs.map((p) => cardFor(p))}
          </SortableContext>
        </ProjectCategorySection>,
      ))
    }
    const uncategorized = groups.get(UNCATEGORIZED) ?? []
    if (dnd.activeId || !hasOnlyPinnedProjects(projects, UNCATEGORIZED)) result.push(categorySection('cat-uncategorized',
      <ProjectCategorySection
        key="cat-uncategorized"
        title={t('uncategorized')}
        count={uncategorized.length}
        defaultOpen={uncategorized.length > 0}
        disableAnimation={isDndEnabled}
        droppableId="list-cat-uncategorized"
      >
        <SortableContext items={uncategorized.map((p) => p.id)} strategy={verticalListSortingStrategy}>
          {uncategorized.map((p) => cardFor(p))}
        </SortableContext>
      </ProjectCategorySection>,
    ))
    for (const key of orderedCategoryKeys) {
      if (key === UNCATEGORIZED || categories.some((c) => c.name === key)) {
        continue
      }
      const projs = groups.get(key) ?? []
      result.push(categorySection(`cat-stray-${key}`,
        <ProjectCategorySection
          key={`cat-stray-${key}`}
          title={key}
          count={projs.length}
          defaultOpen={projs.length > 0}
          disableAnimation={isDndEnabled}
          droppableId={`list-cat-${key}`}
        >
          <SortableContext items={projs.map((p) => p.id)} strategy={verticalListSortingStrategy}>
            {projs.map((p) => cardFor(p))}
          </SortableContext>
        </ProjectCategorySection>,
      ))
    }
    return result
  }

  const unpinnedContent = grouped
    ? renderGrouped()
    : unpinnedProjects.map((p) => cardFor(p))

  const hiddenSection =
    hiddenCategories.length > 0 ? (
      <HiddenCategoriesSection
        key="hidden-categories"
        entries={hiddenCategories}
        onUnhide={(id) => onUnhideCategory?.(id)}
        className="mt-3"
      />
    ) : null

  const listChildren: ReactNode[] =
    projects.length === 0
      ? [emptyState, hiddenSection]
      : showPinnedSection
        ? [
            <div
              key="pinned-top-divider"
              className="h-0.5 my-1 bg-outline"
              style={{ backgroundColor: 'var(--color-outline)' }}
            />,
            pinnedHeader,
            ...pinnedProjects.map((p) => pinnedCard(p)),
            <div
              key="pinned-bottom-divider"
              className="h-0.5 my-1 bg-outline"
              style={{ backgroundColor: 'var(--color-outline)' }}
            />,
            ...unpinnedContent,
            hiddenSection,
          ]
        : [...unpinnedContent, hiddenSection]

  const list = animateList ? (
    <LayoutGroup id={layoutGroupId}>
      <AnimatePresence initial={false} mode="popLayout">{listChildren}</AnimatePresence>
    </LayoutGroup>
  ) : (
    listChildren
  )

  return (
    <div className="flex-1 min-h-0 relative flex flex-col gap-2">
      {isDndEnabled ? (
        <DndContext
          sensors={dnd.sensors}
          collisionDetection={dnd.collisionDetection ?? closestCenter}
          autoScroll={AUTO_SCROLL_CONFIG}
          onDragStart={dnd.handleDragStart}
          onDragMove={dnd.handleDragMove}
          onDragEnd={dnd.handleDragEnd}
          onDragCancel={dnd.handleDragCancel}
        >
          <SortableContext
            items={sortableIds}
            strategy={verticalListSortingStrategy}
          >
            {list}
          </SortableContext>
          <ProjectDropLine ignorePrefix="list-cat-" placement={dnd.placementRef} activeIds={dnd.activeIds} />
          <DragOverlay
            dropAnimation={dnd.dropAnimation}
          >
            {dnd.activeProject ? (
              <ProjectDragOverlay
                innerRef={dnd.overlayRef}
                count={dnd.activeIds.length}
              >
                <div className="px-2">{cardBody(dnd.activeProject)}</div>
              </ProjectDragOverlay>
            ) : null}
          </DragOverlay>
        </DndContext>
      ) : (
        list
      )}
      {projects.length > 0 && (
        <div className="shrink-0 h-4" aria-hidden="true" />
      )}
    </div>
  )
}
