import { invoke } from '@tauri-apps/api/core'
import type { NewsResponse } from '../types'

export const newsApi = {
  fetch: () => invoke<NewsResponse>('fetch_godot_news'),
}
