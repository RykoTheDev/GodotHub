import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'
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
import { UNCATEGORIZED_KEY } from '../../lib/projectDrag'
import { AUTO_SCROLL_CONFIG } from '../../lib/dragFeel'
import { useProjectDnd } from '../../hooks/useProjectDnd'
import {
  ProjectDragOverlay,
  ProjectDropLine,
  SortableProjectItem,
} from '../dnd/ProjectDnd'

interface ProjectCardGridProps {
  projects: Project[]
  installedVersions: InstalledGodotVersion[]
  categories?: Category[]
  categoriesEnabled?: boolean
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
  selecting: boolean
  onReorder?: (orderedIds: string[]) => Promise<void>
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
  selecting,
  onReorder,
  onMoveProjects,
  hiddenCategories = [],
  onUnhideCategory,
  onCategoryContextMenu,
}: ProjectCardGridProps) {
  const { t: tc } = useTranslation('common')

  const grouped = categoriesEnabled && categories.length > 0
  const isDndEnabled = Boolean(onReorder)

  const sortableIds = useMemo(() => projects.map((p) => p.id), [projects])

  const dnd = useProjectDnd({
    projects,
    categories,
    grouped,
    prefixes: { category: 'grid-cat-' },
    selectedIds,
    onReorder,
    onMoveProjects,
  })

  const groupedProjects = useMemo(() => {
    if (!grouped) return null
    const map = new Map<string, Project[]>()
    for (const p of projects) {
      const key = p.category || UNCATEGORIZED
      const list = map.get(key)
      if (list) list.push(p)
      else map.set(key, [p])
    }
    return map
  }, [projects, grouped])

  const renderCard = (p: Project) => {
    const card = (
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
          onToggleSelect={
            selecting || selectedIds.size > 0
              ? (e) => onToggleSelect?.(p.id, e)
              : undefined
          }
        />
      </div>
    )

    if (isDndEnabled) {
      return (
        <SortableProjectItem
          key={p.id}
          id={p.id}
          className="h-full min-w-0"
          static={dnd.activeIds.length > 1}
          carried={dnd.activeIds.includes(p.id)}
          gripClassName="start-1"
        >
          {card}
        </SortableProjectItem>
      )
    }

    return <div key={p.id} className="h-full min-w-0">{card}</div>
  }

  const cardGrid = (list: Project[]) => (
    <div className="grid grid-cols-[repeat(auto-fill,minmax(min(100%,260px),1fr))] items-stretch gap-3 pb-4">
      {list.map(renderCard)}
    </div>
  )

  const categoryContent = (
    <>
      {categories.map((cat) => {
        const catProjects = groupedProjects?.get(cat.name) ?? []
        return (
          <ProjectCategorySection
            key={cat.id}
            variant="grid"
            title={cat.name}
            color={cat.color}
            count={catProjects.length}
            defaultOpen={catProjects.length > 0}
            disableAnimation={isDndEnabled}
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
            defaultOpen disableAnimation={isDndEnabled} droppableId={`grid-cat-${name}`}>
            <SortableContext items={list.map(project => project.id)} strategy={rectSortingStrategy}>
              {cardGrid(list)}
            </SortableContext>
          </ProjectCategorySection>
        ))}
      {(() => {
        const uncategorizedProjects = groupedProjects?.get(UNCATEGORIZED) ?? []
        return (
          <ProjectCategorySection
            variant="grid"
            title={tc('uncategorized')}
            count={uncategorizedProjects.length}
            defaultOpen={uncategorizedProjects.length > 0}
            disableAnimation={isDndEnabled}
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
      {grouped ? categoryContent : cardGrid(projects)}
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
          onDragMove={dnd.handleDragMove}
          onDragEnd={dnd.handleDragEnd}
          onDragCancel={dnd.handleDragCancel}
        >
          <SortableContext items={sortableIds} strategy={rectSortingStrategy}>{allContent}</SortableContext>
          <ProjectDropLine ignorePrefix="grid-cat-" placement={dnd.placementRef} activeIds={dnd.activeIds} />
          <DragOverlay
            dropAnimation={dnd.dropAnimation}
          >
            {activeProject ? (
              <ProjectDragOverlay
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
                  onToggleSelect={selecting || selectedIds.size > 0 ? () => {} : undefined}
                  onShowGitSidebar={onShowGitSidebar ? () => {} : undefined}
                  activeTag={activeTag}
                  onTogglePin={() => {}}
                  onVersionChange={() => {}}
                  onRemove={() => {}}
                />
              </ProjectDragOverlay>
            ) : null}
          </DragOverlay>
        </DndContext>
      </div>
    )
  }

  return <div className="pb-4">{allContent}</div>
}
