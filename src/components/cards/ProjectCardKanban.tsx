import { useCallback, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
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
import type { Category, GitStatus, InstalledGodotVersion, Project } from '../../types'
import { ProjectCardKanbanItem } from './ProjectCardKanbanItem'
import { DragHandle } from '../reusables/DragHandle'

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
  onMoveProject?: (id: string, category: string, destOrderedIds: string[]) => Promise<void>
}

const UNCATEGORIZED = '__uncategorized__'

function SortableKanbanCard({
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

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
    zIndex: isDragging ? 50 : undefined,
  }

  return (
    <div ref={setNodeRef} style={style} className="mb-3 relative group/drag">
      <DragHandle
        ref={setActivatorNodeRef}
        attributes={attributes}
        listeners={listeners}
        isDragging={isDragging}
        disabled={disabled}
        className="absolute top-1/2 -translate-y-1/2 -left-1.5"
      />
      {children}
    </div>
  )
}

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
  onMoveProject,
}: ProjectCardKanbanProps) {
  const { t: tc } = useTranslation('common')
  const [activeDragId, setActiveDragId] = useState<string | null>(null)

  const dndSensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 8 },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    }),
  )

  const grouped = useMemo(() => {
    const map = new Map<string, Project[]>()
    for (const cat of categories) {
      map.set(cat.name, [])
    }
    map.set(UNCATEGORIZED, [])
    for (const project of projects) {
      const cat = project.category || UNCATEGORIZED
      const list = map.get(cat)
      if (list) {
        list.push(project)
      } else {
        map.set(cat, [project])
      }
    }
    return map
  }, [projects, categories])

  const projectsById = useMemo(() => {
    const map = new Map<string, Project>()
    for (const p of projects) {
      map.set(p.id, p)
    }
    return map
  }, [projects])

  const isDndEnabled = Boolean(onReorder)

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
      const catDropMatch = targetId.match(/^kanban-cat-(.+)$/) 
      if (catDropMatch && onMoveProject) {
        const catId = catDropMatch[1]
        const targetCat = catId === 'uncategorized' 
          ? UNCATEGORIZED 
          : categories.find((c) => c.id === catId)?.name ?? catId
        const draggedCat = draggedProject.category || UNCATEGORIZED
        if (draggedCat === targetCat) return
        const destProjects = projects.filter(
          (p) => (p.category || UNCATEGORIZED) === targetCat && !p.pinned,
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
        // Cross-column move
        const destProjects = projects.filter(
          (p) => (p.category || UNCATEGORIZED) === targetCat && !p.pinned,
        )
        const destTargetIdx = destProjects.findIndex((p) => p.id === targetId)
        const insertIdx = destTargetIdx >= 0 ? destTargetIdx : destProjects.length
        const newDest = [...destProjects]
        newDest.splice(insertIdx, 0, draggedProject)
        await onMoveProject(draggedId, targetCat === UNCATEGORIZED ? '' : targetCat, newDest.map((p) => p.id))
      } else if (draggedCat === targetCat) {
        // Same-column reorder
        const catProjects = projects.filter(
          (p) => (p.category || UNCATEGORIZED) === draggedCat && !p.pinned,
        )
        const oldIdx = catProjects.findIndex((p) => p.id === draggedId)
        const newIdx = catProjects.findIndex((p) => p.id === targetId)
        if (oldIdx !== -1 && newIdx !== -1) {
          const reordered = arrayMove(catProjects, oldIdx, newIdx)
          await onReorder(reordered.map((p) => p.id))
        }
      }
    },
    [projectsById, projects, categories, onReorder, onMoveProject],
  )

  const draggedProject = activeDragId ? projectsById.get(activeDragId) ?? null : null

  const renderItems = (list: Project[]) =>
    list.map((p) => {
      const card = (
        <ProjectCardKanbanItem
          key={p.id}
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
          onCategoryChange={onCategoryChange ? (cat) => onCategoryChange(p.id, cat) : undefined}
          onDuplicate={onDuplicate ? () => onDuplicate(p) : undefined}
          onLaunchArgsChange={onLaunchArgsChange ? (args) => onLaunchArgsChange(p.id, args) : undefined}
          onTagsSaved={onTagsSaved}
          onTagClick={onTagClick}
          onShowGitSidebar={() => onShowGitSidebar?.(p, gitStatusMap[p.path] ?? null)}
          activeTag={activeTag}
          selected={selectedIds.has(p.id)}
          onToggleSelect={(selecting || selectedIds.size > 0) ? (e) => onToggleSelect?.(p.id, e) : undefined}
        />
      )

      if (isDndEnabled) {
        return (
          <SortableKanbanCard key={p.id} id={p.id}>
            {card}
          </SortableKanbanCard>
        )
      }

      return <div key={p.id} className="mb-3">{card}</div>
    })

  const columnContent = (
    <>
      {categories.map((cat) => {
        const catProjects = grouped.get(cat.name) ?? []
        return (
          <KanbanColumn
            key={cat.id}
            title={cat.name}
            color={cat.color}
            count={catProjects.length}
            compact={compact}
            droppableId={`kanban-cat-${cat.id}`}
          >
            {isDndEnabled ? (
              <SortableContext
                items={catProjects.map((p) => p.id)}
                strategy={verticalListSortingStrategy}
              >
                {renderItems(catProjects)}
              </SortableContext>
            ) : (
              renderItems(catProjects)
            )}
          </KanbanColumn>
        )
      })}

      {(() => {
        const uncategorizedProjects = grouped.get(UNCATEGORIZED) ?? []
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
                {renderItems(uncategorizedProjects)}
              </SortableContext>
            ) : (
              renderItems(uncategorizedProjects)
            )}
          </KanbanColumn>
        )
      })()}
    </>
  )

  if (isDndEnabled) {
    return (
      <div className="flex gap-4 h-full overflow-x-auto pb-4">
        <DndContext
          sensors={dndSensors}
          collisionDetection={closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          {columnContent}
          <DragOverlay
            dropAnimation={{
              duration: 280,
              easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
          >
            {draggedProject ? (
              <div className="rounded-item shadow-2xl shadow-black/30 scale-[1.015] ring-1 ring-accent/20 bg-overlay/95 backdrop-blur-sm max-w-xs">
                <ProjectCardKanbanItem
                  project={draggedProject}
                  installedVersions={installedVersions}
                  gitStatus={gitStatusMap[draggedProject.path] ?? null}
                  launchWithConsole={launchWithConsole}
                  compact={compact}
                  onTogglePin={() => {}}
                  onVersionChange={() => {}}
                  onRemove={() => {}}
                />
              </div>
            ) : null}
          </DragOverlay>
        </DndContext>
      </div>
    )
  }

  return (
    <div className="flex gap-4 h-full overflow-x-auto pb-4">
      {columnContent}
    </div>
  )
}

interface KanbanColumnProps {
  title: string
  color: string
  count: number
  compact?: boolean
  droppableId?: string
  children: React.ReactNode
}

function KanbanColumn({ title, color, count, compact, droppableId, children }: KanbanColumnProps) {
  const { t } = useTranslation('common')
  const isEmpty = count === 0
  const { isOver, setNodeRef } = useDroppable({
    id: droppableId ?? `kanban-col-${title}`,
    disabled: !isEmpty,
  })

  return (
    <div className={`flex flex-col flex-1 ${compact ? 'min-w-[260px] max-w-xs' : 'min-w-xs max-w-[380px]'}`}>
      <div className="flex items-center gap-2 mb-2 px-1">
        <span
          className="w-2.5 h-2.5 rounded-full shrink-0 ring-1 ring-black/20"
          style={{ backgroundColor: color }}
        />
        <span className="text-sm font-medium text-ink truncate">
          {title}
        </span>
        <span className="text-xs text-muted tabular-nums">
          {count}
        </span>
      </div>
      <div
        ref={isEmpty ? setNodeRef : undefined}
        className={`flex-1 overflow-y-auto rounded-item transition-colors duration-150 ${
          isOver
            ? 'bg-accent/10 border-2 border-dashed border-accent/50'
            : 'bg-overlay/50 border border-outline/30'
        } ${compact ? 'p-2.5 min-h-[200px]' : 'p-3 min-h-[250px]'}`}
      >
        {children}
        {isEmpty && !isOver && (
          <div className="flex items-center justify-center h-full min-h-[120px]">
            <span className="text-xs text-muted/40 select-none">{t('empty_category')}</span>
          </div>
        )}
        {isEmpty && isOver && (
          <div className="flex items-center justify-center h-full min-h-[120px]">
            <span className="text-xs text-accent-bright font-medium select-none">{t('release_to_drop')}</span>
          </div>
        )}
      </div>
    </div>
  )
}
