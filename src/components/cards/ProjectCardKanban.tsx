import { useCallback, useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import {
  DndContext,
  DragOverlay,
  closestCorners,
  useDroppable,
} from '@dnd-kit/core'
import {
  SortableContext,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable'
import type {
  Category,
  GitStatus,
  InstalledGodotVersion,
  Project,
} from '../../types'
import { ProjectCardKanbanItem } from './ProjectCardKanbanItem'
import {
  HiddenCategoriesSection,
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

interface ProjectCardKanbanProps {
  projects: Project[]
  categories: Category[]
  installedVersions: InstalledGodotVersion[]
  gitStatusMap: Record<string, GitStatus | null>
  launchWithConsole: boolean
  compact?: boolean
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

export function ProjectCardKanban({
  projects,
  categories,
  installedVersions,
  gitStatusMap,
  launchWithConsole,
  compact = false,
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
}: ProjectCardKanbanProps) {
  const { t: tc } = useTranslation('common')

  const grouped = categories.length > 0
  const isDndEnabled = Boolean(onReorder)

  const groupedProjects = useMemo(() => {
    const map = new Map<string, Project[]>()
    for (const project of projects) {
      const key = project.category || UNCATEGORIZED
      const list = map.get(key)
      if (list) list.push(project)
      else map.set(key, [project])
    }
    return map
  }, [projects])

  const sortableProjects = useMemo(() => {
    if (!grouped) return projects
    const ordered: Project[] = []
    for (const cat of categories) {
      ordered.push(...(groupedProjects.get(cat.name) ?? []))
    }
    ordered.push(...(groupedProjects.get(UNCATEGORIZED) ?? []))
    for (const [key, list] of groupedProjects) {
      if (
        key === UNCATEGORIZED ||
        categories.some((c) => c.name === key)
      ) {
        continue
      }
      ordered.push(...list)
    }
    return ordered
  }, [grouped, projects, categories, groupedProjects])

  const dnd = useProjectDnd({
    projects: sortableProjects,
    categories,
    grouped,
    prefixes: { category: 'kanban-cat-' },
    collisionDetection: closestCorners,
    selectedIds,
    onReorder,
    onMoveProjects,
  })

  const renderItem = useCallback(
    (p: Project) => {
      const card = (
        <ProjectCardKanbanItem
          project={p}
          installedVersions={installedVersions}
          categories={categories}
          gitStatus={gitStatusMap[p.path] ?? null}
          launchWithConsole={launchWithConsole}
          compact={compact}
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
      )

      if (isDndEnabled) {
        return (
          <SortableProjectItem
            key={p.id}
            id={p.id}
            className="mb-3"
            gripClassName="left-1"
          >
            {card}
          </SortableProjectItem>
        )
      }

      return (
        <div key={p.id} className="mb-3">
          {card}
        </div>
      )
    },
    [
      installedVersions,
      categories,
      gitStatusMap,
      launchWithConsole,
      compact,
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
      isDndEnabled,
    ],
  )

  const columnContent = (
    <>
      {categories.map((cat) => {
        const catProjects = groupedProjects.get(cat.name) ?? []
        return (
          <KanbanColumn
            key={cat.id}
            title={cat.name}
            color={cat.color}
            count={catProjects.length}
            compact={compact}
            droppableId={`kanban-cat-${cat.id}`}
            onContextMenu={
              onCategoryContextMenu
                ? (e) => onCategoryContextMenu(e, cat)
                : undefined
            }
          >
            {isDndEnabled ? (
              <SortableContext
                items={catProjects.map((p) => p.id)}
                strategy={verticalListSortingStrategy}
              >
                {catProjects.map(renderItem)}
              </SortableContext>
            ) : (
              catProjects.map(renderItem)
            )}
          </KanbanColumn>
        )
      })}

      {(() => {
        const uncategorizedProjects = groupedProjects.get(UNCATEGORIZED) ?? []
        return (
          <KanbanColumn
            title={tc('uncategorized')}
            color="#949ba4"
            count={uncategorizedProjects.length}
            compact={compact}
            droppableId="kanban-cat-uncategorized"
          >
            {isDndEnabled ? (
              <SortableContext
                items={uncategorizedProjects.map((p) => p.id)}
                strategy={verticalListSortingStrategy}
              >
                {uncategorizedProjects.map(renderItem)}
              </SortableContext>
            ) : (
              uncategorizedProjects.map(renderItem)
            )}
          </KanbanColumn>
        )
      })()}
    </>
  )

  const hiddenSection =
    hiddenCategories.length > 0 ? (
      <HiddenCategoriesSection
        entries={hiddenCategories}
        onUnhide={(id) => onUnhideCategory?.(id)}
        className="shrink-0 pt-1"
      />
    ) : null

  if (isDndEnabled) {
    const activeProject = dnd.activeProject
    return (
      <div className="flex flex-col h-full">
      <div className="flex gap-4 flex-1 min-h-0 overflow-x-auto pb-4">
        <DndContext
          sensors={dnd.sensors}
          collisionDetection={dnd.collisionDetection ?? closestCorners}
          autoScroll={AUTO_SCROLL_CONFIG}
          onDragStart={dnd.handleDragStart}
          onDragMove={dnd.handleDragMove}
          onDragEnd={dnd.handleDragEnd}
          onDragCancel={dnd.handleDragCancel}
        >
          {columnContent}
          <ProjectDropLine ignorePrefix="kanban-cat-" />
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
                <ProjectCardKanbanItem
                  project={activeProject}
                  installedVersions={installedVersions}
                  gitStatus={gitStatusMap[activeProject.path] ?? null}
                  launchWithConsole={launchWithConsole}
                  compact={compact}
                  onTogglePin={() => {}}
                  onVersionChange={() => {}}
                  onRemove={() => {}}
                />
              </ProjectDragOverlay>
            ) : null}
          </DragOverlay>
        </DndContext>
      </div>
      {hiddenSection}
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex gap-4 flex-1 min-h-0 overflow-x-auto pb-4">
        {columnContent}
      </div>
      {hiddenSection}
    </div>
  )
}

interface KanbanColumnProps {
  title: string
  color: string
  count: number
  compact?: boolean
  droppableId?: string
  onContextMenu?: (e: React.MouseEvent<HTMLElement>) => void
  children: React.ReactNode
}

function KanbanColumn({
  title,
  color,
  count,
  compact,
  droppableId,
  onContextMenu,
  children,
}: KanbanColumnProps) {
  const { t } = useTranslation('common')
  const isEmpty = count === 0
  const { isOver, setNodeRef } = useDroppable({
    id: droppableId ?? `kanban-col-${title}`,
  })

  return (
    <div
      className={`flex flex-col flex-1 ${
        compact ? 'min-w-[260px] max-w-xs' : 'min-w-xs max-w-[380px]'
      }`}
    >
      <div
        className="flex items-center gap-2 mb-2 px-1 rounded-item"
        onContextMenu={
          onContextMenu
            ? (e) => {
                e.preventDefault()
                onContextMenu(e)
              }
            : undefined
        }
      >
        <span
          className="w-2.5 h-2.5 rounded-full shrink-0 ring-1 ring-black/20"
          style={{ backgroundColor: color }}
        />
        <span className="text-sm font-medium text-ink truncate">{title}</span>
        <span className="text-xs text-muted tabular-nums">{count}</span>
      </div>
      <div
        ref={setNodeRef}
        className={`flex-1 overflow-y-auto rounded-item border transition-colors duration-150 ${
          isOver
            ? 'bg-accent/10 border-accent/50'
            : 'bg-overlay/50 border-outline/30'
        } ${compact ? 'p-2.5 min-h-[200px]' : 'p-3 min-h-[250px]'}`}
      >
        {children}
        {isEmpty && !isOver && (
          <div className="flex items-center justify-center h-full min-h-[120px]">
            <span className="text-xs text-muted/40 select-none">
              {t('empty_category')}
            </span>
          </div>
        )}
        {isEmpty && isOver && (
          <div className="flex items-center justify-center h-full min-h-[120px]">
            <span className="text-xs text-accent-bright font-medium select-none">
              {t('release_to_drop')}
            </span>
          </div>
        )}
      </div>
    </div>
  )
}
