import type { Project } from '../types'

export type ProjectSearchField =
  | 'name'
  | 'tag'
  | 'category'
  | 'version'
  | 'path'
  | 'pinned'

export const PROJECT_SEARCH_FIELDS: ProjectSearchField[] = [
  'name',
  'tag',
  'category',
  'version',
  'path',
  'pinned',
]

const FIELD_ALIASES: Record<string, ProjectSearchField> = {
  name: 'name',
  tag: 'tag',
  tags: 'tag',
  category: 'category',
  cat: 'category',
  version: 'version',
  engine: 'version',
  path: 'path',
  folder: 'path',
  dir: 'path',
  pinned: 'pinned',
  pin: 'pinned',
}

const PINNED_TRUE = ['true', 'yes', 'on', '1', 'y', 't']
const PINNED_FALSE = ['false', 'no', 'off', '0', 'n', 'f']

export interface ProjectSearchToken {
  raw: string
  start: number
  end: number
  field: ProjectSearchField | null
  value: string
}

export interface ParsedProjectQuery {
  text: string[]
  filters: { field: ProjectSearchField; value: string }[]
  activeToken: ProjectSearchToken | null
  active: boolean
}

function tokenize(input: string): ProjectSearchToken[] {
  const tokens: ProjectSearchToken[] = []
  const re = /\S+/g
  let match: RegExpExecArray | null
  while ((match = re.exec(input)) !== null) {
    const raw = match[0]
    const start = match.index
    const end = start + raw.length
    const sep = raw.toLowerCase().indexOf(':')
    let field: ProjectSearchField | null = null
    let value = ''
    if (sep > 0) {
      const resolved = FIELD_ALIASES[raw.slice(0, sep).toLowerCase()]
      if (resolved) {
        field = resolved
        value = raw.slice(sep + 1)
      }
    }
    tokens.push({ raw, start, end, field, value })
  }
  return tokens
}

function findActiveToken(
  tokens: ProjectSearchToken[],
  caret: number,
): ProjectSearchToken | null {
  for (const token of tokens) {
    if (caret >= token.start && caret <= token.end) return token
  }
  return null
}

export function parseProjectQuery(
  input: string,
  caret: number = input.length,
): ParsedProjectQuery {
  const tokens = tokenize(input)
  const activeToken = findActiveToken(tokens, caret)
  const text: string[] = []
  const filters: { field: ProjectSearchField; value: string }[] = []

  for (const token of tokens) {
    if (token.field) {
      const value = token.value.trim().toLowerCase()
      if (value) {
        filters.push({ field: token.field, value })
      } else if (token.field === 'pinned') {
        filters.push({ field: 'pinned', value: '' })
      }
      continue
    }
    if (token === activeToken && token.raw.startsWith('/')) continue
    text.push(token.raw.toLowerCase())
  }

  return {
    text,
    filters,
    activeToken,
    active: text.length > 0 || filters.length > 0,
  }
}

function includesLower(haystack: string | null | undefined, needle: string) {
  return (haystack ?? '').toLowerCase().includes(needle)
}

function matchesVersion(version: string | null | undefined, term: string): boolean {
  const value = (version ?? '').toLowerCase()
  if (!value || !term) return false
  if (value.startsWith(term)) return true
  return value
    .split(/[.\s_-]+/)
    .some((segment) => segment.length > 0 && segment.startsWith(term))
}

function matchesPinned(project: Project, value: string): boolean {
  if (!value) return project.pinned
  if (PINNED_FALSE.includes(value)) return !project.pinned
  if (PINNED_TRUE.includes(value)) return project.pinned
  return project.pinned
}

function matchesFilter(
  project: Project,
  field: ProjectSearchField,
  value: string,
): boolean {
  switch (field) {
    case 'name':
      return includesLower(project.name, value)
    case 'tag':
      return project.tags.some((tag) => tag.toLowerCase().includes(value))
    case 'category':
      return includesLower(project.category, value)
    case 'version':
      return matchesVersion(project.godot_version, value)
    case 'path':
      return includesLower(project.path, value)
    case 'pinned':
      return matchesPinned(project, value)
    default:
      return true
  }
}

function termScore(project: Project, term: string): number {
  const name = project.name.toLowerCase()
  if (name === term) return 120
  if (name.startsWith(term)) return 90
  if (name.split(/[\s._-]+/).some((word) => word.startsWith(term))) return 70
  if (name.includes(term)) return 50
  if (project.tags.some((tag) => tag.toLowerCase().includes(term))) return 30
  if (includesLower(project.category, term)) return 24
  if (matchesVersion(project.godot_version, term)) return 20
  if (includesLower(project.path, term)) return 12
  return 0
}

export function matchProject(
  project: Project,
  query: ParsedProjectQuery,
): number | null {
  if (!query.active) return 0
  for (const filter of query.filters) {
    if (!matchesFilter(project, filter.field, filter.value)) return null
  }
  let total = 0
  for (const term of query.text) {
    const score = termScore(project, term)
    if (score === 0) return null
    total += score
  }
  return total
}

export function replaceToken(
  input: string,
  token: { start: number; end: number },
  replacement: string,
): { value: string; caret: number } {
  const value = input.slice(0, token.start) + replacement + input.slice(token.end)
  return { value, caret: token.start + replacement.length }
}

export function collectTags(projects: Project[]): string[] {
  const seen = new Set<string>()
  for (const project of projects) {
    for (const tag of project.tags) {
      const trimmed = tag.trim()
      if (trimmed) seen.add(trimmed)
    }
  }
  return [...seen].sort((a, b) => a.localeCompare(b))
}

export function collectVersions(projects: Project[]): string[] {
  const seen = new Set<string>()
  for (const project of projects) {
    const version = project.godot_version?.trim()
    if (version) seen.add(version)
  }
  return [...seen].sort((a, b) => b.localeCompare(a))
}
