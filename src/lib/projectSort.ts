import type { Project } from '../types'

export type ProjectSortOption =
  | 'categories'
  | 'recent'
  | 'name_asc'
  | 'name_desc'
  | 'created_desc'
  | 'created_asc'

export const SORT_OPTIONS: { value: ProjectSortOption; labelKey: string }[] = [
  { value: 'categories', labelKey: 'sort_categories' },
  { value: 'recent', labelKey: 'sort_recent' },
  { value: 'name_asc', labelKey: 'sort_name_asc' },
  { value: 'name_desc', labelKey: 'sort_name_desc' },
  { value: 'created_desc', labelKey: 'sort_created_desc' },
  { value: 'created_asc', labelKey: 'sort_created_asc' },
]

function timeOf(iso: string | null | undefined): number {
  if (!iso) return -Infinity
  const t = new Date(iso).getTime()
  return isNaN(t) ? -Infinity : t
}

export function comparatorFor(
  sort: ProjectSortOption,
): ((a: Project, b: Project) => number) | null {
  switch (sort) {
    case 'categories':
      return null
    case 'recent':
      return (a, b) => timeOf(b.last_opened) - timeOf(a.last_opened)
    case 'name_asc':
      return (a, b) => a.name.localeCompare(b.name)
    case 'name_desc':
      return (a, b) => b.name.localeCompare(a.name)
    case 'created_desc':
      return (a, b) => timeOf(b.created_at) - timeOf(a.created_at)
    case 'created_asc':
      return (a, b) => timeOf(a.created_at) - timeOf(b.created_at)
    default:
      return null
  }
}
