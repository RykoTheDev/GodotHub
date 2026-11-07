import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import { IconPin } from '../../lib/icons'
import { AnimatedNumber } from '../reusables/AnimatedNumber'
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core'
import { SortableContext, rectSortingStrategy } from '@dnd-kit/sortable'
import type {
  Category,
  GitStatus,
  InstalledGodotVersion,
  Project,
} from '../../types'
import { ProjectCardGridItem } from './ProjectCardGridItem'
import {
  HiddenCategoriesSection,
  ProjectCategorySection,
  type HiddenCategoryEntry,
} from './CategorySections'
import { hasOnlyPinnedProjects, UNCATEGORIZED_KEY } from '../../lib/projectDrag'
import { AUTO_SCROLL_CONFIG } from '../../lib/dragFeel'
import { useProjectDnd } from '../../hooks/useProjectDnd'
import {
  DROP_ANIMATION,
  DragLiftOverlay,
  DropLine,
  SortableItem,
} from '../dnd/SortableDnd'

interface ProjectCardGridProps {
  projects: Project[]
  installedVersions: InstalledGodotVersion[]
  categories?: Category[]
  categoriesEnabled?: boolean
  searchActive?: boolean
  gitStatusMap: Record<string, GitStatus | null>
  launchWithConsole: boolean
  onTogglePin: (id: string) => void
  onVersionChange: (id: string, tag: string) => void
  onRemove: (id: string) => void
  onDelete?: (id: string) => void
  onCategoryChange?: (id: string, category: string) => void
  onDuplicate?: (project: Project) => void
  onLaunchArgsChange?: (id: string, args: string) => void
  onTagsSaved?: (project: Project) => void
  onTagClick?: (tag: string) => void
  onShowGitSidebar?: (project: Project, gitStatus: GitStatus | null) => void
  activeTag?: string | null
  selectedIds: Set<string>
  onToggleSelect?: (id: string, e: React.MouseEvent) => void
  onReorder?: (orderedIds: string[]) => Promise<void>
  onReorderPinned?: (orderedIds: string[]) => Promise<void>
  onMoveProjects?: (
    ids: string[],
    category: string,
    destOrderedIds: string[],
  ) => Promise<void>
  hiddenCategories?: HiddenCategoryEntry[]
  onUnhideCategory?: (id: string) => void
  onCategoryContextMenu?: (
    e: React.MouseEvent<HTMLElement>,
    category: Category,
  ) => void
}

const UNCATEGORIZED = UNCATEGORIZED_KEY

export function ProjectCardGrid({
  projects,
  installedVersions,
  categories = [],
  categoriesEnabled = false,
  searchActive = false,
  gitStatusMap,
  launchWithConsole,
  onTogglePin,
  onVersionChange,
  onRemove,
  onDelete,
  onCategoryChange,
  onDuplicate,
  onLaunchArgsChange,
  onTagsSaved,
  onTagClick,
  onShowGitSidebar,
  activeTag,
  selectedIds,
  onToggleSelect,
  onReorder,
  onReorderPinned,
  onMoveProjects,
  hiddenCategories = [],
  onUnhideCategory,
  onCategoryContextMenu,
}: ProjectCardGridProps) {
  const { t: tc } = useTranslation('common')

  const grouped = categoriesEnabled && categories.length > 0
  const isDndEnabled = Boolean(onReorder)

  const showPinnedSection = !searchActive && projects.some((p) => p.pinned)
  const pinnedProjects = useMemo(
    () => (showPinnedSection ? projects.filter((p) => p.pinned) : []),
    [projects, showPinnedSection],
  )
  const unpinnedProjects = useMemo(
    () => (showPinnedSection ? projects.filter((p) => !p.pinned) : projects),
    [projects, showPinnedSection],
  )

  const sortableIds = useMemo(() => unpinnedProjects.map((p) => p.id), [unpinnedProjects])

  const dnd = useProjectDnd({
    projects: unpinnedProjects,
    categories,
    grouped,
    prefixes: { category: 'grid-cat-' },
    selectedIds,
    onReorder,
    onMoveProjects,
  })

  const pinnedDnd = useProjectDnd({
    projects: pinnedProjects,
    categories,
    grouped: false,
    prefixes: { category: 'grid-pinned-cat-' },
    selectedIds,
    onReorder: onReorderPinned,
  })

  const groupedProjects = useMemo(() => {
    if (!grouped) return null
    const map = new Map<string, Project[]>()
    for (const p of unpinnedProjects) {
      const key = p.category || UNCATEGORIZED
      const list = map.get(key)
      if (list) list.push(p)
      else map.set(key, [p])
    }
    return map
  }, [unpinnedProjects, grouped])

  const cardContent = (p: Project) => (
    <div className="h-full min-w-0">
      <ProjectCardGridItem
        project={p}
        installedVersions={installedVersions}
        categories={categories}
        gitStatus={gitStatusMap[p.path] ?? null}
        launchWithConsole={launchWithConsole}
        onTogglePin={() => onTogglePin(p.id)}
        onVersionChange={(tag) => onVersionChange(p.id, tag)}
        onRemove={() => onRemove(p.id)}
        onDelete={onDelete ? () => onDelete(p.id) : undefined}
        onCategoryChange={
          onCategoryChange ? (cat) => onCategoryChange(p.id, cat) : undefined
        }
        onDuplicate={onDuplicate ? () => onDuplicate(p) : undefined}
        onLaunchArgsChange={
          onLaunchArgsChange ? (args) => onLaunchArgsChange(p.id, args) : undefined
        }
        onTagsSaved={onTagsSaved}
        onTagClick={onTagClick}
        onShowGitSidebar={onShowGitSidebar ? () => onShowGitSidebar(p, gitStatusMap[p.path] ?? null) : undefined}
        activeTag={activeTag}
        selected={selectedIds.has(p.id)}
        onToggleSelect={(e) => onToggleSelect?.(p.id, e)}
      />
    </div>
  )

  const renderCard = (p: Project) => {
    const card = cardContent(p)

    if (isDndEnabled) {
      return (
        <SortableItem
          key={p.id}
          id={p.id}
          className="h-full min-w-0"
          static={dnd.activeIds.length > 1}
          carried={dnd.activeIds.includes(p.id)}
        >
          {card}
        </SortableItem>
      )
    }

    return <div key={p.id} className="h-full min-w-0">{card}</div>
  }

  const renderPinnedCard = (p: Project) =>
    onReorderPinned ? (
      <SortableItem
        key={p.id}
        id={p.id}
        className="h-full min-w-0"
        static={pinnedDnd.activeIds.length > 1}
        carried={pinnedDnd.activeIds.includes(p.id)}
      >
        {cardContent(p)}
      </SortableItem>
    ) : (
      <div key={p.id} className="h-full min-w-0">{cardContent(p)}</div>
    )

  const pinnedGrid = (
    <div className="grid grid-cols-[repeat(auto-fill,minmax(min(100%,260px),1fr))] items-stretch gap-3 pt-1 pb-1">
      {pinnedProjects.map(renderPinnedCard)}
    </div>
  )

  const pinnedSection = showPinnedSection ? (
    <div className="pb-2">
      <div className="mt-1 mb-0.5 flex items-center gap-2 px-1 rounded-item">
        <IconPin className="w-3 h-3 text-accent-bright" fill="currentColor" />
        <span className="text-3xs font-semibold uppercase tracking-wider text-muted">
          {tc('pinned_section')}
        </span>
        <span className="text-3xs font-medium text-muted/50 tabular-nums">
          · <AnimatedNumber value={pinnedProjects.length} />
        </span>
        <div className="flex-1 h-px bg-outline/50" />
      </div>
      {onReorderPinned ? (
        <DndContext
          sensors={pinnedDnd.sensors}
          collisionDetection={pinnedDnd.collisionDetection ?? closestCenter}
          autoScroll={AUTO_SCROLL_CONFIG}
          onDragStart={pinnedDnd.handleDragStart}
          onDragEnd={pinnedDnd.handleDragEnd}
          onDragCancel={pinnedDnd.handleDragCancel}
        >
          <SortableContext items={pinnedProjects.map((p) => p.id)} strategy={rectSortingStrategy}>
            {pinnedGrid}
          </SortableContext>
          <DropLine placement={pinnedDnd.placementRef} activeIds={pinnedDnd.activeIds} reflows={pinnedDnd.reflows} />
          <DragOverlay dropAnimation={DROP_ANIMATION}>
            {pinnedDnd.activeProject ? (
              <DragLiftOverlay innerRef={pinnedDnd.overlayRef} count={pinnedDnd.activeIds.length} className="h-full">
                {cardContent(pinnedDnd.activeProject)}
              </DragLiftOverlay>
            ) : null}
          </DragOverlay>
        </DndContext>
      ) : pinnedGrid}
      <div className="mt-2 h-0.5 bg-outline" style={{ backgroundColor: 'var(--color-outline)' }} />
    </div>
  ) : null

  const cardGrid = (list: Project[]) => (
    <div className="grid grid-cols-[repeat(auto-fill,minmax(min(100%,260px),1fr))] items-stretch gap-3 pt-1 pb-4">
      {list.map(renderCard)}
    </div>
  )

  const categoryContent = (
    <>
      {categories.map((cat) => {
        const catProjects = groupedProjects?.get(cat.name) ?? []
        if (!dnd.activeId && hasOnlyPinnedProjects(projects, cat.name)) return null
        return (
          <ProjectCategorySection
            key={cat.id}
            variant="grid"
            title={cat.name}
            color={cat.color}
            count={catProjects.length}
            defaultOpen={catProjects.length > 0}
            droppableId={`grid-cat-${cat.id}`}
            onContextMenu={
              onCategoryContextMenu
                ? (e) => onCategoryContextMenu(e, cat)
                : undefined
            }
          >
            <SortableContext items={catProjects.map((p) => p.id)} strategy={rectSortingStrategy}>
              {cardGrid(catProjects)}
            </SortableContext>
          </ProjectCategorySection>
        )
      })}
      {Array.from(groupedProjects?.entries() ?? [])
        .filter(([name]) => name !== UNCATEGORIZED && !categories.some(category => category.name === name))
        .map(([name, list]) => (
          <ProjectCategorySection key={name} variant="grid" title={name} count={list.length}
            defaultOpen droppableId={`grid-cat-${name}`}>
            <SortableContext items={list.map(project => project.id)} strategy={rectSortingStrategy}>
              {cardGrid(list)}
            </SortableContext>
          </ProjectCategorySection>
        ))}
      {(() => {
        const uncategorizedProjects = groupedProjects?.get(UNCATEGORIZED) ?? []
        if (!dnd.activeId && hasOnlyPinnedProjects(projects, UNCATEGORIZED)) return null
        return (
          <ProjectCategorySection
            variant="grid"
            title={tc('uncategorized')}
            count={uncategorizedProjects.length}
            defaultOpen={uncategorizedProjects.length > 0}
            droppableId="grid-cat-uncategorized"
          >
            <SortableContext items={uncategorizedProjects.map((p) => p.id)} strategy={rectSortingStrategy}>
              {cardGrid(uncategorizedProjects)}
            </SortableContext>
          </ProjectCategorySection>
        )
      })()}
    </>
  )

  const allContent = (
    <>
      {pinnedSection}
      {grouped ? categoryContent : cardGrid(unpinnedProjects)}
      {hiddenCategories.length > 0 && (
        <HiddenCategoriesSection
          entries={hiddenCategories}
          onUnhide={(id) => onUnhideCategory?.(id)}
          className="pb-4"
        />
      )}
    </>
  )

  if (isDndEnabled) {
    const activeProject = dnd.activeProject
    return (
      <div className="pb-4">
        <DndContext
          sensors={dnd.sensors}
          collisionDetection={dnd.collisionDetection ?? closestCenter}
          autoScroll={AUTO_SCROLL_CONFIG}
          onDragStart={dnd.handleDragStart}
          onDragEnd={dnd.handleDragEnd}
          onDragCancel={dnd.handleDragCancel}
        >
          <SortableContext items={sortableIds} strategy={rectSortingStrategy}>{allContent}</SortableContext>
          <DropLine ignorePrefix="grid-cat-" placement={dnd.placementRef} activeIds={dnd.activeIds} reflows={dnd.reflows} />
          <DragOverlay dropAnimation={DROP_ANIMATION}
          >
            {activeProject ? (
              <DragLiftOverlay
                innerRef={dnd.overlayRef}
                count={dnd.activeIds.length}
                className="h-full"
              >
                <ProjectCardGridItem
                  preview
                  project={activeProject}
                  installedVersions={installedVersions}
                  gitStatus={gitStatusMap[activeProject.path] ?? null}
                  launchWithConsole={launchWithConsole}
                  selected={selectedIds.has(activeProject.id)}
                  onShowGitSidebar={onShowGitSidebar ? () => {} : undefined}
                  activeTag={activeTag}
                  onTogglePin={() => {}}
                  onVersionChange={() => {}}
                  onRemove={() => {}}
                />
              </DragLiftOverlay>
            ) : null}
          </DragOverlay>
        </DndContext>
      </div>
    )
  }

  return <div className="pb-4">{allContent}</div>
}
