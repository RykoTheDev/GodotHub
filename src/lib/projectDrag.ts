import type { Category, Project } from '../types'

export const UNCATEGORIZED_KEY = '__uncategorized__'

export interface DroppablePrefixes {
  category: string
}

export type DropPlacement = 'before' | 'after'

export type ProjectDropResolution =
  | { type: 'none' }
  | { type: 'reorder'; orderedIds: string[] }
  | {
      type: 'move'
      activeIds: string[]
      categoryName: string
      destOrderedIds: string[]
    }

export function categoryKeyOf(project: Pick<Project, 'category'>): string {
  return project.category || UNCATEGORIZED_KEY
}

// Pinning never changes a category's saved visibility or its project membership.
export function hasOnlyPinnedProjects(projects: Project[], categoryKey: string): boolean {
  const members = projects.filter((p) => categoryKeyOf(p) === categoryKey)
  return members.length > 0 && members.every((p) => p.pinned)
}

export interface ProjectDropInput {
  activeId: string
  activeIds?: string[]
  overId: string
  projects: Project[]
  categories: Category[]
  grouped: boolean
  prefixes: DroppablePrefixes
  placement?: DropPlacement
}

export function resolveProjectDrop(input: ProjectDropInput): ProjectDropResolution {
  const { activeId, overId, projects, categories, grouped, prefixes } = input
  const travelling = new Set(input.activeIds?.length ? input.activeIds : [activeId])
  // Preserve visible selection order, regardless of which card was grabbed.
  const moving = projects.filter((p) => travelling.has(p.id))
  const dragged = projects.find((p) => p.id === activeId)
  if (!dragged || moving.length === 0 || travelling.has(overId)) return { type: 'none' }

  const onZone = overId.startsWith(prefixes.category)
  const overProject = projects.find((p) => p.id === overId)
  if ((!grouped || !onZone) && !overProject) return { type: 'none' }

  const suffix = overId.slice(prefixes.category.length)
  const targetKey = onZone
    ? suffix === 'uncategorized'
      ? UNCATEGORIZED_KEY
      : categories.find((c) => c.id === suffix)?.name ?? suffix
    : categoryKeyOf(overProject!)
  const destination = grouped
    ? projects.filter((p) => categoryKeyOf(p) === targetKey)
    : projects
  const rest = destination.filter((p) => !travelling.has(p.id))
  const overIndex = rest.findIndex((p) => p.id === overId)
  const sameCategory = moving.every((p) => categoryKeyOf(p) === targetKey)
  const placement = input.placement ?? (
    moving.length === 1 && (!grouped || sameCategory) &&
    destination.indexOf(dragged) < destination.findIndex((p) => p.id === overId)
      ? 'after'
      : 'before'
  )
  const insertAt = onZone ? rest.length : overIndex + (placement === 'after' ? 1 : 0)
  const next = [...rest]
  next.splice(insertAt, 0, ...moving)
  const orderedIds = next.map((p) => p.id)

  if (!grouped || sameCategory) {
    if (destination.length === next.length && destination.every((p, i) => p.id === orderedIds[i])) {
      return { type: 'none' }
    }
    return { type: 'reorder', orderedIds }
  }
  return {
    type: 'move',
    activeIds: moving.map((p) => p.id),
    categoryName: targetKey === UNCATEGORIZED_KEY ? '' : targetKey,
    destOrderedIds: orderedIds,
  }
}
