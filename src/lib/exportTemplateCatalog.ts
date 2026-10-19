import { api } from './api'
import type { ExportTemplateOption } from '../types'

const catalogs = new Map<string, ExportTemplateOption[]>()
const requests = new Map<string, Promise<ExportTemplateOption[]>>()

export const getCachedTemplateOptions = (tag: string) => catalogs.get(tag)

export function cacheTemplateOptions(tag: string, options: ExportTemplateOption[]) {
  catalogs.set(tag, options)
}

export function setTemplateFilesInstalled(tag: string, names: string[] | undefined, installed: boolean) {
  const options = catalogs.get(tag)
  if (!options) return
  const changed = names ? new Set(names) : undefined
  cacheTemplateOptions(tag, options.map((option) => {
    const files = option.files.map((file) => !changed || changed.has(file.name) ? { ...file, installed } : file)
    return { ...option, files, installed: files.every((file) => file.installed) }
  }))
}

export function loadTemplateOptions(tag: string, refresh = false) {
  const key = `${tag}:${refresh}`
  const existing = requests.get(key)
  if (existing) return existing
  const request = api.getExportTemplateOptions(tag, refresh).then((options) => {
    cacheTemplateOptions(tag, options)
    return options
  }).finally(() => requests.delete(key))
  requests.set(key, request)
  return request
}
