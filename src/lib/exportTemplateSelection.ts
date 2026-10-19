import type { ExportTemplateOption } from '../types'

export type ExportTemplateFile = ExportTemplateOption['files'][number]

interface TemplateFileGroup {
  label: string | null
  labelKey?: 'export_templates_web_standard' | 'export_templates_web_extensions' | 'export_templates_web_single_threaded' | 'export_templates_web_extensions_single_threaded'
  files: ExportTemplateFile[]
}

const webGroups: Record<string, Pick<TemplateFileGroup, 'label' | 'labelKey'>> = {
  web_standard: { label: 'Web', labelKey: 'export_templates_web_standard' },
  web_extensions: { label: 'Web with Extensions', labelKey: 'export_templates_web_extensions' },
  web_single_threaded: { label: 'Web Single-Threaded', labelKey: 'export_templates_web_single_threaded' },
  web_extensions_single_threaded: { label: 'Web with Extensions Single-Threaded', labelKey: 'export_templates_web_extensions_single_threaded' },
}

export function groupTemplateFiles(files: ExportTemplateFile[]) {
  const groups = new Map<string, TemplateFileGroup>()
  for (const file of files) {
    const name = file.name.toLowerCase()
    if (/^(web|javascript|html5)[_.\/-]/.test(name)) {
      const extensions = /(?:^|_)(dlink|extensions)(?:_|\.)/.test(name)
      const singleThreaded = name.includes('nothreads')
      const id = `web_${extensions ? 'extensions' : 'standard'}${singleThreaded ? '_single_threaded' : ''}`.replace('standard_single_threaded', 'single_threaded')
      const group = groups.get(id) ?? { ...webGroups[id], files: [] }
      group.files.push(file)
      groups.set(id, group)
      continue
    }
    const architecture = name.match(/(?:^|[_.\/-])(x86_64|x86_32|arm64|arm32|aarch64|armv7|amd64|x64|x32)(?=[_.\/-]|$)/)?.[1]
      ?? name.match(/(?:windows|win|x11)[_.-]?(32|64)(?=[_.\/-]|$)/)?.[1]
    const labels: Record<string, string> = {
      x86_32: 'x86 (32-bit)', x32: 'x86 (32-bit)', '32': 'x86 (32-bit)',
      x86_64: 'x86_64 (64-bit)', amd64: 'x86_64 (64-bit)', x64: 'x86_64 (64-bit)', '64': 'x86_64 (64-bit)',
      arm32: 'ARM32', armv7: 'ARM32', arm64: 'ARM64', aarch64: 'ARM64',
    }
    const label = architecture ? labels[architecture] : null
    const id = label ?? 'files'
    const group = groups.get(id) ?? { label, files: [] }
    group.files.push(file)
    groups.set(id, group)
  }
  const order = ['x86 (32-bit)', 'x86_64 (64-bit)', 'ARM32', 'ARM64', 'web_standard', 'web_extensions', 'web_single_threaded', 'web_extensions_single_threaded', 'files']
  return [...groups.entries()].map(([id, group]) => ({ id, ...group }))
    .sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id))
}

export function groupTemplateOptions(options: ExportTemplateOption[]) {
  const definitions = [
    { id: 'desktop', labelKey: 'export_templates_category_desktop', platforms: ['windows', 'linux', 'macos', 'uwp', 'server'] },
    { id: 'mobile', labelKey: 'export_templates_category_mobile', platforms: ['android', 'ios', 'visionos', 'tvos'] },
    { id: 'web', labelKey: 'export_templates_category_web', platforms: ['web'] },
    { id: 'common', labelKey: 'export_templates_category_common', platforms: ['icu'] },
  ] as const
  const known = new Set<string>(definitions.flatMap((category) => [...category.platforms]))
  const categories = definitions.map((category) => ({
    id: category.id as string,
    labelKey: category.labelKey as string,
    options: category.platforms.flatMap((id) => options.filter((option) => option.id === id)),
  }))
  const other = options.filter((option) => !known.has(option.id))
  if (other.length) categories.push({ id: 'other', labelKey: 'export_templates_category_other', options: other })
  return categories.filter((category) => category.options.length > 0)
}

export function toggleTemplateFiles(selected: string[], files: ExportTemplateFile[], checked: boolean) {
  const names = new Set(files.filter((file) => !file.installed).map((file) => file.name))
  return checked
    ? [...new Set([...selected, ...names])]
    : selected.filter((name) => !names.has(name))
}
