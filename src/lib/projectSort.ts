import type { Project } from '../types'

export type ProjectSortOption =
  | 'custom'
  | 'name_asc'
  | 'name_desc'
  | 'last_opened'
  | 'created_desc'
  | 'created_asc'
  | 'size_desc'
  | 'size_asc'

export const SORT_OPTIONS: { value: ProjectSortOption; label: string }[] = [
  { value: 'name_asc', label: 'Name (A–Z)' },
  { value: 'name_desc', label: 'Name (Z–A)' },
  { value: 'size_desc', label: 'Project size (largest)' },
  { value: 'size_asc', label: 'Project size (smallest)' },
  { value: 'last_opened', label: 'Recently opened' },
  { value: 'created_desc', label: 'Date added (newest)' },
  { value: 'created_asc', label: 'Date added (oldest)' },
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
    case 'name_asc':
      return (a, b) => a.name.localeCompare(b.name)
    case 'name_desc':
      return (a, b) => b.name.localeCompare(a.name)
    case 'last_opened':
      return (a, b) => timeOf(b.last_opened) - timeOf(a.last_opened)
    case 'created_desc':
      return (a, b) => timeOf(b.created_at) - timeOf(a.created_at)
    case 'created_asc':
      return (a, b) => timeOf(a.created_at) - timeOf(b.created_at)
    case 'size_desc':
      return (a, b) => ((b as any).__cached_size ?? 0) - ((a as any).__cached_size ?? 0)
    case 'size_asc':
      return (a, b) => ((a as any).__cached_size ?? 0) - ((b as any).__cached_size ?? 0)
    case 'custom':
    default:
      return null
  }
}
