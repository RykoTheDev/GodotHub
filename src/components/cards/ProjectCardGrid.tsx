import { useCallback, useMemo, useState } from 'react'
import Masonry from 'react-masonry-css'
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
  useSortable,
  arrayMove,
  sortableKeyboardCoordinates,
} from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import type { Category, GitStatus, InstalledGodotVersion, Project } from '../../types'
import { ProjectCardGridItem } from './ProjectCardGridItem'
import { DragHandle } from '../reusables/DragHandle'

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
  onMoveProject?: (id: string, category: string, destOrderedIds: string[]) => Promise<void>
}

function GridCategoryDropZone({
  droppableId,
  isEmpty,
  children,
}: {
  droppableId: string
  isEmpty: boolean
  children: React.ReactNode
}) {
  const { t } = useTranslation('common')
  const { isOver, setNodeRef } = useDroppable({
    id: droppableId,
    disabled: !isEmpty,
  })

  if (!isEmpty) return <>{children}</>

  return (
    <div
      ref={setNodeRef}
      className={`rounded-item transition-colors duration-150 min-h-[100px] flex items-center justify-center ${
        isOver
          ? 'bg-accent/10 border-2 border-dashed border-accent/50'
          : 'bg-overlay/30 border border-dashed border-outline/30'
      }`}
    >
      <span className={`text-xs select-none ${isOver ? 'text-accent-bright font-medium' : 'text-muted/40'}`}>
        {isOver ? t('release_to_drop') : t('empty_category')}
      </span>
    </div>
  )
}

function SortableGridCard({
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
    <div ref={setNodeRef} style={style} className="relative group/drag overflow-visible">
      <DragHandle
        ref={setActivatorNodeRef}
        attributes={attributes}
        listeners={listeners}
        isDragging={isDragging}
        disabled={disabled}
        className="absolute top-1/2 -translate-y-1/2 ml-[-8px] left-0"
      />
      {children}
    </div>
  )
}

const BREAKPOINTS = {
  default: 4,
  1280: 3,
  960: 2,
  640: 1,
}

const UNCATEGORIZED = '__uncategorized__'

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
  onMoveProject,
}: ProjectCardGridProps) {
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
      const catDropMatch = targetId.match(/^grid-cat-(.+)$/) 
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
        const destProjects = projects.filter(
          (p) => (p.category || UNCATEGORIZED) === targetCat && !p.pinned,
        )
        const destTargetIdx = destProjects.findIndex((p) => p.id === targetId)
        const insertIdx = destTargetIdx >= 0 ? destTargetIdx : destProjects.length
        const newDest = [...destProjects]
        newDest.splice(insertIdx, 0, draggedProject)
        await onMoveProject(draggedId, targetCat === UNCATEGORIZED ? '' : targetCat, newDest.map((p) => p.id))
      } else if (draggedCat === targetCat) {
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

  const grouped = useMemo(() => {
    if (!categoriesEnabled) return null
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
  }, [projects, categories, categoriesEnabled])

  const renderCard = (p: Project) => {
    const card = (
      <div key={p.id} className="mb-3">
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
      </div>
    )

    if (isDndEnabled) {
      return (
        <SortableGridCard key={p.id} id={p.id}>
          {card}
        </SortableGridCard>
      )
    }

    return card
  }

  const categoryContent = (
    <>
      {categories.map((cat) => {
        const catProjects = grouped?.get(cat.name) ?? []
        return (
          <div key={cat.id} className="mb-6">
            <div className="flex items-center gap-2 mb-3 px-1">
              <span
                className="w-2.5 h-2.5 rounded-full shrink-0 ring-1 ring-black/20"
                style={{ backgroundColor: cat.color }}
              />
              <span className="text-sm font-medium text-ink">
                {cat.name}
              </span>
              <span className="text-xs text-muted tabular-nums">
                {catProjects.length}
              </span>
            </div>
            <GridCategoryDropZone droppableId={`grid-cat-${cat.id}`} isEmpty={catProjects.length === 0}>
              <Masonry
                breakpointCols={BREAKPOINTS}
                className={`masonry ${isDndEnabled ? 'px-2' : ''}`}
                columnClassName="masonry-column"
              >
                {catProjects.map(renderCard)}
              </Masonry>
            </GridCategoryDropZone>
          </div>
        )
      })}
      {(() => {
        const uncategorizedProjects = grouped?.get(UNCATEGORIZED) ?? []
        return (
          <div className="mb-6">
            <div className="flex items-center gap-2 mb-3 px-1">
              <span
                className="w-2.5 h-2.5 rounded-full shrink-0 ring-1 ring-black/20"
                style={{ backgroundColor: '#949ba4' }}
              />
              <span className="text-sm font-medium text-ink">
                {tc('uncategorized')}
              </span>
              <span className="text-xs text-muted tabular-nums">
                {uncategorizedProjects.length}
              </span>
            </div>
            <GridCategoryDropZone droppableId="grid-cat-uncategorized" isEmpty={uncategorizedProjects.length === 0}>
              <Masonry
                breakpointCols={BREAKPOINTS}
                className={`masonry ${isDndEnabled ? 'px-2' : ''}`}
                columnClassName="masonry-column"
              >
                {uncategorizedProjects.map(renderCard)}
              </Masonry>
            </GridCategoryDropZone>
          </div>
        )
      })()}
    </>
  )

  const allContent = grouped ? (
    categoryContent
  ) : (
    <Masonry
      breakpointCols={BREAKPOINTS}
      className={`masonry ${isDndEnabled ? 'px-2' : ''}`}
      columnClassName="masonry-column"
    >
      {projects.map(renderCard)}
    </Masonry>
  )

  if (isDndEnabled) {
    return (
      <div className="pb-4">
        <DndContext
          sensors={dndSensors}
          collisionDetection={closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          {allContent}
          <DragOverlay
            dropAnimation={{
              duration: 280,
              easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
          >
            {draggedProject ? (
              <div className="rounded-item shadow-2xl shadow-black/30 scale-[1.015] ring-1 ring-accent/20 bg-overlay/95 backdrop-blur-sm max-w-xs">
                <ProjectCardGridItem
                  project={draggedProject}
                  installedVersions={installedVersions}
                  gitStatus={gitStatusMap[draggedProject.path] ?? null}
                  launchWithConsole={launchWithConsole}
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
    <div className="pb-4">
      {allContent}
    </div>
  )
}
