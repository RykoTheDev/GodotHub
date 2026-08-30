import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useCategoriesContext } from './categoriesContext'
import { useWorkspaces } from './useWorkspaces'
import { useTauriEvent } from '../lib/useTauriEvent'
import { api } from '../lib/api'
import { applyRadius } from '../lib/appearance'
import {
  DEFAULT_BG,
  DEFAULT_BG_LIGHT,
  applyTheme,
  applyThemePreset,
  customThemeDefaults,
  getThemePreset,
  isDarkColor,
  resolveThemeMode,
  type ThemeModeSetting,
} from '../lib/colors'
import type { AppSettings, WorkspaceScanDirs } from '../types'

export type OnboardingStepId =
  | 'welcome'
  | 'projects'
  | 'versions'
  | 'templates'
  | 'categories'
  | 'customize'
  | 'finish'

export const STARTER_CATEGORIES = [
  'In Progress',
  'Prototypes',
  'Finished',
  'Game Jams',
]

export const ALL_STEPS: { id: OnboardingStepId }[] = [
  { id: 'welcome' },
  { id: 'projects' },
  { id: 'versions' },
  { id: 'templates' },
  { id: 'categories' },
  { id: 'customize' },
  { id: 'finish' },
]

interface UseOnboardingOptions {
  settings: AppSettings
  onComplete: (settings: AppSettings) => Promise<AppSettings> | void
}

const dedupePaths = (
  items: { path: string; source: string }[],
): { path: string; source: string }[] => {
  const seen = new Set<string>()
  return items.filter((item) => {
    if (seen.has(item.path)) return false
    seen.add(item.path)
    return true
  })
}

export function useOnboarding({ settings, onComplete }: UseOnboardingOptions) {
  const { t } = useTranslation('onboarding')
  const { t: tc } = useTranslation('common')
  const { activeId } = useWorkspaces()
  const STEPS = useMemo(
    () =>
      ALL_STEPS.filter(
        (s) => s.id !== 'categories' || settings.categories_enabled,
      ),
    [settings.categories_enabled],
  )
  const [stepIndex, setStepIndex] = useState(0)
  const [draft, setDraft] = useState<AppSettings>(settings)
  const [finishing, setFinishing] = useState(false)
  const [workspaceSuggestions, setWorkspaceSuggestions] = useState<
    WorkspaceScanDirs[]
  >([])
  const [scanProgress, setScanProgress] = useState<{
    projects: { current: number; total: number } | null
    versions: { current: number; total: number } | null
  }>({ projects: null, versions: null })

  useEffect(() => {
    api.listWorkspaceScanDirs().then(setWorkspaceSuggestions).catch(() => {})
  }, [])

  const projectSuggestions = useMemo(
    () =>
      dedupePaths(
        workspaceSuggestions
          .filter((w) => w.workspace_id !== activeId)
          .flatMap((w) =>
            w.project_scan_dirs.map((path) => ({
              path,
              source: w.workspace_name,
            })),
          ),
      ),
    [workspaceSuggestions, activeId],
  )
  const versionSuggestions = useMemo(
    () =>
      dedupePaths(
        workspaceSuggestions
          .filter((w) => w.workspace_id !== activeId)
          .flatMap((w) =>
            w.version_scan_dirs.map((path) => ({
              path,
              source: w.workspace_name,
            })),
          ),
      ),
    [workspaceSuggestions, activeId],
  )
  const templateSuggestions = useMemo(
    () =>
      dedupePaths(
        workspaceSuggestions
          .filter((w) => w.workspace_id !== activeId)
          .flatMap((w) =>
            w.template_scan_dir
              ? [{ path: w.template_scan_dir, source: w.workspace_name }]
              : [],
          ),
      ),
    [workspaceSuggestions, activeId],
  )

  const pendingTemplateSuggestions = templateSuggestions.filter(
    (s) => s.path !== draft.template_scan_dir,
  )

  useTauriEvent<[number, number]>('project-scan-progress', ([current, total]) => {
    setScanProgress((prev) => ({ ...prev, projects: { current, total } }))
  })
  useTauriEvent<[number, number]>('version-scan-progress', ([current, total]) => {
    setScanProgress((prev) => ({ ...prev, versions: { current, total } }))
  })

  const {
    categories,
    create: createCategory,
    remove: removeCategory,
  } = useCategoriesContext()
  const [categoryDraft, setCategoryDraft] = useState('')
  const [categoryBusy, setCategoryBusy] = useState(false)

  const step = STEPS[stepIndex]

  const setField = <K extends keyof AppSettings>(
    key: K,
    value: AppSettings[K],
  ) => {
    setDraft((prev) => ({ ...prev, [key]: value }))
  }

  const presetActive = draft.theme_preset !== 'custom'

  const selectPreset = (id: string) => {
    if (id === draft.theme_preset) return
    if (id === 'custom') {
      const defaults = customThemeDefaults(resolveThemeMode(draft.theme_mode))
      setDraft((prev) => ({ ...prev, theme_preset: id, ...defaults }))
      applyTheme(
        defaults.accent_color,
        defaults.background_color,
        resolveThemeMode(draft.theme_mode),
        undefined,
        draft.raised_contrast,
      )
    } else {
      const preset = getThemePreset(id)
      if (preset) {
        setDraft((prev) => ({
          ...prev,
          theme_preset: id,
          theme_mode: preset.mode,
        }))
        applyThemePreset(preset)
      }
    }
  }

  const setThemeMode = (mode: ThemeModeSetting) => {
    const resolved = resolveThemeMode(mode)
    const targetDark = resolved === 'dark'
    const bg = isDarkColor(draft.background_color) === targetDark
      ? draft.background_color
      : targetDark ? DEFAULT_BG : DEFAULT_BG_LIGHT
    setDraft((prev) => ({ ...prev, theme_mode: mode, background_color: bg }))
    applyTheme(
      draft.accent_color,
      bg,
      resolved,
      undefined,
      draft.raised_contrast,
    )
  }

  const setAccentColor = (hex: string) => {
    setField('accent_color', hex)
    applyTheme(
      hex,
      draft.background_color,
      resolveThemeMode(draft.theme_mode),
      undefined,
      draft.raised_contrast,
    )
  }

  const setBackgroundColor = (hex: string) => {
    setField('background_color', hex)
    applyTheme(
      draft.accent_color,
      hex,
      resolveThemeMode(draft.theme_mode),
      undefined,
      draft.raised_contrast,
    )
  }

  const setCornerRadius = (value: number) => {
    setField('corner_radius', value)
    applyRadius(value)
  }

  const goNext = () => setStepIndex((i) => Math.min(i + 1, STEPS.length - 1))
  const goBack = () => setStepIndex((i) => Math.max(i - 1, 0))
  const jumpTo = (i: number) =>
    setStepIndex(Math.min(Math.max(i, 0), STEPS.length - 1))

  const categoryLabels: Record<string, string> = useMemo(() => ({
    'In Progress': t('in_progress'),
    'Prototypes': t('prototypes'),
    'Finished': t('finished'),
    'Game Jams': t('game_jams'),
  }), [t])

  const addStarterCategory = async (name: string) => {
    if (categories.some((c) => c.name.toLowerCase() === name.toLowerCase()))
      return
    setCategoryBusy(true)
    try {
      await createCategory(name)
    } finally {
      setCategoryBusy(false)
    }
  }

  const addCustomCategory = async () => {
    const name = categoryDraft.trim()
    if (!name) return
    setCategoryBusy(true)
    try {
      await createCategory(name)
      setCategoryDraft('')
    } finally {
      setCategoryBusy(false)
    }
  }

  const finish = async (skip: boolean) => {
    setFinishing(true)
    setScanProgress({ projects: null, versions: null })
    const final: AppSettings = skip
      ? { ...settings, setup_complete: true, language: draft.language }
      : { ...draft, setup_complete: true }
    await Promise.all([
      final.project_scan_dirs.length
        ? api.scanForProjects(final.project_scan_dirs, final.scan_depth)
        : Promise.resolve(),
      final.version_scan_dirs.length
        ? api.scanForVersions(final.version_scan_dirs, final.scan_depth)
        : Promise.resolve(),
      final.template_scan_dir
        ? api.syncTemplatesWithScanDir().catch(() => {})
        : Promise.resolve(),
    ])
    await onComplete(final)
    setFinishing(false)
  }

  const stepLabel = (id: OnboardingStepId) => {
    switch (id) {
      case 'welcome':
        return t('welcome')
      case 'projects':
        return tc('section_projects')
      case 'versions':
        return tc('section_versions')
      case 'templates':
        return tc('section_templates')
      case 'categories':
        return t('categories')
      case 'customize':
        return t('customize')
      case 'finish':
        return t('finish')
    }
  }

  return {
    STEPS,
    stepIndex,
    step,
    goNext,
    goBack,
    jumpTo,
    stepLabel,
    draft,
    setDraft,
    setField,
    finishing,
    finish,
    presetActive,
    selectPreset,
    setThemeMode,
    setAccentColor,
    setBackgroundColor,
    setCornerRadius,
    projectSuggestions,
    versionSuggestions,
    pendingTemplateSuggestions,
    scanProgress,
    categories,
    removeCategory,
    categoryDraft,
    setCategoryDraft,
    categoryBusy,
    addStarterCategory,
    addCustomCategory,
    categoryLabels,
  }
}
