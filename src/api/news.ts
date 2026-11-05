import { invoke } from '@tauri-apps/api/core'
import type { NewsResponse } from '../types'

const NEWS_TTL_MS = 15 * 60 * 1000

let cached: { at: number; request: Promise<NewsResponse> } | null = null

export const newsApi = {
  fetch: (force = false) => {
    if (!force && cached && Date.now() - cached.at < NEWS_TTL_MS) return cached.request
    const request = invoke<NewsResponse>('fetch_godot_news')
    const entry = { at: Date.now(), request }
    cached = entry
    request.catch(() => {
      if (cached === entry) cached = null
    })
    return request
  },
}
