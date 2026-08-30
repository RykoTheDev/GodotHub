import type { AssetLibraryAsset } from '../types'

export type AssetSortKey =
  | 'relevance'
  | 'updated_new'
  | 'updated_old'
  | 'name_az'
  | 'name_za'
  | 'rating_high'
  | 'rating_low'
  | 'license_az'
  | 'license_za'

export const ASSET_SORT_KEYS: AssetSortKey[] = [
  'relevance',
  'updated_new',
  'updated_old',
  'name_az',
  'name_za',
  'rating_high',
  'rating_low',
  'license_az',
  'license_za',
]

export function assetSortParams(key: AssetSortKey): {
  sort: string | null
  reverse: boolean
} {
  switch (key) {
    case 'updated_new':
      return { sort: 'updated', reverse: false }
    case 'updated_old':
      return { sort: 'updated', reverse: true }
    case 'name_az':
      return { sort: 'name', reverse: false }
    case 'name_za':
      return { sort: 'name', reverse: true }
    case 'rating_high':
      return { sort: 'rating', reverse: true }
    case 'rating_low':
      return { sort: 'rating', reverse: false }
    case 'license_az':
      return { sort: 'cost', reverse: false }
    case 'license_za':
      return { sort: 'cost', reverse: true }
    default:
      return { sort: null, reverse: false }
  }
}

function relevanceScore(asset: AssetLibraryAsset, query: string): number {
  const title = asset.title.toLowerCase()
  const author = asset.author.toLowerCase()
  const category = asset.category.toLowerCase()
  const description = (asset.description ?? '').toLowerCase()
  let score = 0
  if (title === query) score += 100
  else if (title.startsWith(query)) score += 80
  else if (title.includes(query)) score += 60
  if (author.includes(query)) score += 25
  if (category.includes(query)) score += 15
  if (description.includes(query)) score += 10
  return score
}

function tieBreak(a: AssetLibraryAsset, b: AssetLibraryAsset): number {
  const byTitle = a.title.localeCompare(b.title)
  if (byTitle !== 0) return byTitle
  return a.asset_id.localeCompare(b.asset_id)
}

export function rankByRelevance(
  assets: AssetLibraryAsset[],
  query: string,
): AssetLibraryAsset[] {
  const q = query.trim().toLowerCase()
  if (!q) return [...assets].sort(tieBreak)
  return [...assets].sort((a, b) => {
    const byScore = relevanceScore(b, q) - relevanceScore(a, q)
    return byScore !== 0 ? byScore : tieBreak(a, b)
  })
}

export type AssetSource = 'all' | 'library' | 'store'

export function storeServerSort(key: AssetSortKey): string {
  switch (key) {
    case 'updated_new':
      return 'updated_desc'
    case 'updated_old':
      return 'updated_asc'
    case 'rating_high':
      return 'reviews_desc'
    case 'rating_low':
      return 'reviews_asc'
    default:
      return 'relevance'
  }
}

export function sortKeysForSource(source: AssetSource): AssetSortKey[] {
  const base: AssetSortKey[] = [
    'relevance',
    'name_az',
    'name_za',
    'license_az',
    'license_za',
    'rating_high',
    'rating_low',
  ]
  return source === 'all' ? base : [...base, 'updated_new', 'updated_old']
}

export function shouldClientSort(
  source: AssetSource,
  sort: AssetSortKey,
  query: string,
): boolean {
  if (source === 'all') return true
  if (source === 'store') {
    if (!query.trim()) return true
    return (
      sort === 'relevance' ||
      sort === 'name_az' ||
      sort === 'name_za' ||
      sort === 'license_az' ||
      sort === 'license_za' ||
      sort === 'rating_high' ||
      sort === 'rating_low'
    )
  }
  return false
}

function parseRating(asset: AssetLibraryAsset): number {
  const n = parseFloat(asset.rating ?? '')
  return Number.isFinite(n) ? n : 0
}

export function sortAssets(
  assets: AssetLibraryAsset[],
  sort: AssetSortKey,
  query: string,
): AssetLibraryAsset[] {
  switch (sort) {
    case 'relevance':
      return rankByRelevance(assets, query)
    case 'name_az':
      return [...assets].sort((a, b) => tieBreak(a, b))
    case 'name_za':
      return [...assets].sort((a, b) => tieBreak(b, a))
    case 'license_az':
      return [...assets].sort((a, b) =>
        (a.cost ?? '').localeCompare(b.cost ?? '') || tieBreak(a, b),
      )
    case 'license_za':
      return [...assets].sort((a, b) =>
        (b.cost ?? '').localeCompare(a.cost ?? '') || tieBreak(a, b),
      )
    case 'rating_high':
      return [...assets].sort((a, b) =>
        parseRating(b) - parseRating(a) || tieBreak(a, b),
      )
    case 'rating_low':
      return [...assets].sort((a, b) =>
        parseRating(a) - parseRating(b) || tieBreak(a, b),
      )
    default:
      return assets
  }
}
