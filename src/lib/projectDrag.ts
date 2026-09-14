import { arrayMove } from '@dnd-kit/sortable'
import type { Category, Project } from '../types'

export const UNCATEGORIZED_KEY = '__uncategorized__'

export interface DroppablePrefixes {
  category: string
}

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

function categoryKeyFromSuffix(suffix: string, categories: Category[]): string {
  if (suffix === 'uncategorized') return UNCATEGORIZED_KEY
  return categories.find((c) => c.id === suffix)?.name ?? suffix
}

function idsOf(projects: Project[]): string[] {
  return projects.map((p) => p.id)
}

function sameOrder(a: string[], b: string[]): boolean {
  return a.length === b.length && a.every((id, i) => id === b[i])
}

function zoneKeyOf(
  overId: string,
  categories: Category[],
  prefixes: DroppablePrefixes,
): string | null {
  if (!overId.startsWith(prefixes.category)) return null
  return categoryKeyFromSuffix(overId.slice(prefixes.category.length), categories)
}

export interface ProjectDropInput {
  activeId: string
  activeIds?: string[]
  overId: string
  projects: Project[]
  categories: Category[]
  grouped: boolean
  prefixes: DroppablePrefixes
}

export function resolveProjectDrop(input: ProjectDropInput): ProjectDropResolution {
  const { activeId, overId, projects, categories, grouped, prefixes } = input

  const group = (input.activeIds?.length ? input.activeIds : [activeId]).filter(
    (id) => projects.some((p) => p.id === id),
  )
  if (group.length === 0) return { type: 'none' }
  if (group.includes(overId)) return { type: 'none' }

  if (group.length > 1) {
    return resolveGroupDrop({ group, overId, projects, categories, grouped, prefixes })
  }

  if (!grouped) {
    const ids = idsOf(projects)
    const from = ids.indexOf(activeId)
    const to = ids.indexOf(overId)
    if (from === -1 || to === -1 || from === to) return { type: 'none' }
    return { type: 'reorder', orderedIds: arrayMove(ids, from, to) }
  }

  const dragged = projects.find((p) => p.id === activeId)
  if (!dragged) return { type: 'none' }
  const draggedKey = categoryKeyOf(dragged)

  const zoneSuffix = overId.startsWith(prefixes.category)
    ? overId.slice(prefixes.category.length)
    : null

  let targetKey: string
  let insertIndex: number | null = null
  let droppedOnZone = false

  if (zoneSuffix !== null) {
    droppedOnZone = true
    targetKey = categoryKeyFromSuffix(zoneSuffix, categories)
  } else {
    const overProject = projects.find((p) => p.id === overId)
    if (!overProject) return { type: 'none' }
    targetKey = categoryKeyOf(overProject)
    if (targetKey !== draggedKey) {
      const dest = projects.filter((p) => categoryKeyOf(p) === targetKey)
      const overIdx = dest.findIndex((p) => p.id === overId)
      insertIndex = overIdx >= 0 ? overIdx : dest.length
    }
  }

  if (targetKey === draggedKey) {
    const ids = idsOf(projects.filter((p) => categoryKeyOf(p) === draggedKey))
    const from = ids.indexOf(activeId)
    if (from === -1) return { type: 'none' }
    const to = droppedOnZone ? ids.length - 1 : ids.indexOf(overId)
    if (to === -1 || from === to) return { type: 'none' }
    return { type: 'reorder', orderedIds: arrayMove(ids, from, to) }
  }

  const dest = projects.filter((p) => categoryKeyOf(p) === targetKey)
  const next = [...dest]
  next.splice(insertIndex ?? dest.length, 0, dragged)
  return {
    type: 'move',
    activeIds: [activeId],
    categoryName: targetKey === UNCATEGORIZED_KEY ? '' : targetKey,
    destOrderedIds: idsOf(next),
  }
}

function resolveGroupDrop({
  group,
  overId,
  projects,
  categories,
  grouped,
  prefixes,
}: {
  group: string[]
  overId: string
  projects: Project[]
  categories: Category[]
  grouped: boolean
  prefixes: DroppablePrefixes
}): ProjectDropResolution {
  const travelling = new Set(group)
  const groupProjects = group
    .map((id) => projects.find((p) => p.id === id))
    .filter((p): p is Project => Boolean(p))

  if (!grouped) {
    const rest = idsOf(projects).filter((id) => !travelling.has(id))
    const overIdx = rest.indexOf(overId)
    const insertAt = overIdx >= 0 ? overIdx : rest.length
    rest.splice(insertAt, 0, ...group)
    const before = idsOf(projects)
    if (sameOrder(before, rest)) return { type: 'none' }
    return { type: 'reorder', orderedIds: rest }
  }

  const lead = groupProjects[0]
  if (!lead) return { type: 'none' }
  const draggedKey = categoryKeyOf(lead)

  const zoneKey = zoneKeyOf(overId, categories, prefixes)
  let targetKey: string
  if (zoneKey !== null) {
    targetKey = zoneKey
  } else {
    const overProject = projects.find((p) => p.id === overId)
    if (!overProject) return { type: 'none' }
    targetKey = categoryKeyOf(overProject)
  }

  const destAll = projects.filter((p) => categoryKeyOf(p) === targetKey)
  const dest = destAll.filter((p) => !travelling.has(p.id))
  const overIdx = dest.findIndex((p) => p.id === overId)
  const insertAt = zoneKey !== null ? dest.length : overIdx >= 0 ? overIdx : dest.length

  const next = [...dest]
  next.splice(insertAt, 0, ...groupProjects)
  const orderedIds = idsOf(next)

  if (targetKey === draggedKey) {
    if (sameOrder(idsOf(destAll), orderedIds)) return { type: 'none' }
    return { type: 'reorder', orderedIds }
  }

  return {
    type: 'move',
    activeIds: group,
    categoryName: targetKey === UNCATEGORIZED_KEY ? '' : targetKey,
    destOrderedIds: orderedIds,
  }
}
