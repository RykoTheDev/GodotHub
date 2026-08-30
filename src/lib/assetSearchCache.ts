import type { AssetLibraryResponse } from '../types'

const RESPONSE_CACHE_TTL = 120_000
const responseCache = new Map<
  string,
  { at: number; promise: Promise<AssetLibraryResponse> }
>()

export function cachedAssetSearch(
  key: string,
  fn: () => Promise<AssetLibraryResponse>,
): Promise<AssetLibraryResponse> {
  const hit = responseCache.get(key)
  if (hit && Date.now() - hit.at < RESPONSE_CACHE_TTL) {
    return hit.promise
  }
  const promise = fn()
  promise.catch(() => responseCache.delete(key))
  responseCache.set(key, { at: Date.now(), promise })
  return promise
}
