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
import { AUTO_SCROLL_CONFIG } from '../../lib/dragFeel'
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
      const key = grouped ? (project.category || UNCATEGORIZED) : UNCATEGORIZED
      const list = map.get(key)
      if (list) list.push(project)
      else map.set(key, [project])
    }
    return map
  }, [projects, grouped])

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
          onShowGitSidebar={onShowGitSidebar ? () => onShowGitSidebar(p, gitStatusMap[p.path] ?? null) : undefined}
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
            fillHeight={false}
            id={p.id}
            static={dnd.activeIds.length > 1}
            carried={dnd.activeIds.includes(p.id)}
            className="mb-3"
            gripClassName="start-1"
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
      dnd.activeIds,
    ],
  )

  const columns = [
    ...categories.map(category => ({
      key: category.id, title: category.name, color: category.color,
      projects: groupedProjects.get(category.name) ?? [], category,
    })),
    ...[...groupedProjects.entries()]
      .filter(([key]) => key !== UNCATEGORIZED && !categories.some(category => category.name === key))
      .map(([key, list]) => ({ key, title: key, color: '#949ba4', projects: list, category: undefined })),
    { key: 'uncategorized', title: tc('uncategorized'), color: '#949ba4', projects: groupedProjects.get(UNCATEGORIZED) ?? [], category: undefined },
  ]

  const columnContent = columns.map(column => (
    <KanbanColumn
      key={column.key}
      title={column.title}
      color={column.color}
      count={column.projects.length}
      compact={compact}
      droppableId={`kanban-cat-${column.key}`}
      onContextMenu={column.category && onCategoryContextMenu
        ? event => onCategoryContextMenu(event, column.category!)
        : undefined}
    >
      {isDndEnabled ? (
        <SortableContext items={column.projects.map(project => project.id)} strategy={verticalListSortingStrategy}>
          {column.projects.map(renderItem)}
        </SortableContext>
      ) : column.projects.map(renderItem)}
    </KanbanColumn>
  ))

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
          <ProjectDropLine ignorePrefix="kanban-cat-" placement={dnd.placementRef} activeIds={dnd.activeIds} />
          <DragOverlay
            dropAnimation={dnd.dropAnimation}
          >
            {activeProject ? (
              <ProjectDragOverlay
                innerRef={dnd.overlayRef}
                count={dnd.activeIds.length}
                className="h-full"
              >
                <ProjectCardKanbanItem
                  preview
                  project={activeProject}
                  installedVersions={installedVersions}
                  gitStatus={gitStatusMap[activeProject.path] ?? null}
                  launchWithConsole={launchWithConsole}
                  selected={selectedIds.has(activeProject.id)}
                  onToggleSelect={selecting || selectedIds.size > 0 ? () => {} : undefined}
                  onShowGitSidebar={onShowGitSidebar ? () => {} : undefined}
                  activeTag={activeTag}
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
      className={`flex flex-col shrink-0 min-h-0 ${
        compact ? 'w-[260px]' : 'w-[300px]'
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
        <span className="min-w-0 flex-1 text-sm font-medium text-ink truncate">{title}</span>
        <span className="shrink-0 text-xs text-muted tabular-nums">{count}</span>
      </div>
      <div
        ref={setNodeRef}
        className={`flex-1 min-h-0 overflow-y-auto overflow-x-hidden rounded-item border transition-colors duration-150 ${
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
