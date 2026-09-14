import { useMemo } from 'react'
import Masonry from 'react-masonry-css'
import { useTranslation } from 'react-i18next'
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core'
import { SortableContext } from '@dnd-kit/sortable'
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
import { AUTO_SCROLL_CONFIG, DRAG_FEEL } from '../../lib/dragFeel'
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

const BREAKPOINTS = {
  default: 4,
  1280: 3,
  960: 2,
  640: 1,
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
    collisionDetection: closestCenter,
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
      <div className="mb-3">
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
          onShowGitSidebar={() =>
            onShowGitSidebar?.(p, gitStatusMap[p.path] ?? null)
          }
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
          static
          gripClassName="left-1"
        >
          {card}
        </SortableProjectItem>
      )
    }

    return <div key={p.id}>{card}</div>
  }

  const masonry = (list: Project[]) => (
    <Masonry
      breakpointCols={BREAKPOINTS}
      className={`masonry ${isDndEnabled ? 'px-2' : ''}`}
      columnClassName="masonry-column"
    >
      {list.map(renderCard)}
    </Masonry>
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
            {masonry(catProjects)}
          </ProjectCategorySection>
        )
      })}
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
            {masonry(uncategorizedProjects)}
          </ProjectCategorySection>
        )
      })()}
    </>
  )

  const allContent = (
    <>
      {grouped ? categoryContent : masonry(projects)}
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
          <SortableContext items={sortableIds}>{allContent}</SortableContext>
          <ProjectDropLine ignorePrefix="grid-cat-" />
          <DragOverlay
            dropAnimation={{
              duration: DRAG_FEEL.drop.duration,
              easing: DRAG_FEEL.drop.easing,
            }}
          >
            {activeProject ? (
              <ProjectDragOverlay
                innerRef={dnd.overlayRef}
                count={dnd.activeIds.length}
                className="max-w-xs"
              >
                <ProjectCardGridItem
                  project={activeProject}
                  installedVersions={installedVersions}
                  gitStatus={gitStatusMap[activeProject.path] ?? null}
                  launchWithConsole={launchWithConsole}
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
