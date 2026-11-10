import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useCategoriesContext } from './categoriesContext'
import { useWorkspaces } from './useWorkspaces'
import { useTauriEvent } from '../lib/useTauriEvent'
import { api } from '../lib/api'
import { applyRadius } from '../lib/appearance'
import { CATEGORY_COLORS } from '../lib/categoryColors'
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
import { isFeatureEnabled, type FeatureId } from '../lib/features'
import type { AppSettings, WorkspaceScanDirs } from '../types'

export type OnboardingStepId =
  | 'workspace'
  | 'welcome'
  | 'setup'
  | 'projects'
  | 'versions'
  | 'templates'
  | 'categories'
  | 'appearance'
  | 'finish'

export const STARTER_CATEGORIES = [
  'In Progress',
  'Prototypes',
  'Finished',
  'Game Jams',
]

export const STARTER_CATEGORY_COLORS: Record<string, string> = {
  'In Progress': CATEGORY_COLORS[0],
  'Prototypes': CATEGORY_COLORS[1],
  'Finished': CATEGORY_COLORS[2],
  'Game Jams': CATEGORY_COLORS[3],
}

export const ALL_STEPS: { id: OnboardingStepId; feature?: FeatureId; firstRunOnly?: boolean }[] = [
  { id: 'workspace', firstRunOnly: true },
  { id: 'welcome' },
  { id: 'setup' },
  { id: 'projects' },
  { id: 'versions' },
  { id: 'templates', feature: 'templates' },
  { id: 'categories', feature: 'categories' },
  { id: 'appearance' },
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
  const { t: ts } = useTranslation('settings')
  const { activeId, workspaces } = useWorkspaces()
  const [draft, setDraft] = useState<AppSettings>(settings)
  const isFirstRun = workspaces.length <= 1
  const STEPS = ALL_STEPS.filter(
    (s) => (!s.feature || isFeatureEnabled(draft, s.feature)) && (!s.firstRunOnly || isFirstRun),
  )
  const [stepId, setStepId] = useState<OnboardingStepId>('workspace')
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
    update: updateCategory,
    reorder: reorderCategories,
    assignFolder: assignCategoryFolder,
    unassignFolder: unassignCategoryFolder,
  } = useCategoriesContext()
  const [categoryDraft, setCategoryDraft] = useState('')
  const [categoryColor, setCategoryColor] = useState<string>(CATEGORY_COLORS[0])
  const [categoryBusy, setCategoryBusy] = useState(false)

  const stepIndex = Math.max(STEPS.findIndex((s) => s.id === stepId), 0)
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

  const jumpTo = (i: number) =>
    setStepId(STEPS[Math.min(Math.max(i, 0), STEPS.length - 1)].id)
  const goNext = () => jumpTo(stepIndex + 1)
  const goBack = () => jumpTo(stepIndex - 1)

  const categoryLabels: Record<string, string> = useMemo(() => ({
    'In Progress': t('in_progress'),
    'Prototypes': t('prototypes'),
    'Finished': t('finished'),
    'Game Jams': t('game_jams'),
  }), [t])

  const isStarterCategoryAdded = (name: string) => {
    const label = (categoryLabels[name] || name).toLowerCase()
    return categories.some((c) => {
      const existing = c.name.toLowerCase()
      return existing === name.toLowerCase() || existing === label
    })
  }

  const addStarterCategory = async (name: string) => {
    if (isStarterCategoryAdded(name)) return
    setCategoryBusy(true)
    try {
      await createCategory(
        categoryLabels[name] || name,
        STARTER_CATEGORY_COLORS[name] ?? categoryColor,
      )
    } finally {
      setCategoryBusy(false)
    }
  }

  const addCustomCategory = async () => {
    const name = categoryDraft.trim()
    if (!name) return
    setCategoryBusy(true)
    try {
      await createCategory(name, categoryColor)
      setCategoryDraft('')
      setCategoryColor(CATEGORY_COLORS[0])
    } finally {
      setCategoryBusy(false)
    }
  }

  const finish = async (
    skip: boolean,
    beforeComplete?: () => Promise<void>,
    afterComplete?: () => Promise<void>,
  ) => {
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
      final.template_scan_dir && isFeatureEnabled(final, 'templates')
        ? api.syncTemplatesWithScanDir().catch(() => {})
        : Promise.resolve(),
    ])
    if (!skip) await beforeComplete?.()
    await onComplete(final)
    if (!skip) void afterComplete?.()
    await api.restartWatchers().catch(() => {})
    setFinishing(false)
  }

  const stepLabel = (id: OnboardingStepId) => {
    switch (id) {
      case 'workspace':
        return t('workspace_step')
      case 'welcome':
        return t('basics')
      case 'setup':
        return t('setup')
      case 'projects':
        return tc('section_projects')
      case 'versions':
        return tc('section_versions')
      case 'templates':
        return tc('section_templates')
      case 'categories':
        return t('categories')
      case 'appearance':
        return ts('appearance')
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
    updateCategory,
    reorderCategories,
    assignCategoryFolder,
    unassignCategoryFolder,
    categoryDraft,
    setCategoryDraft,
    categoryColor,
    setCategoryColor,
    categoryBusy,
    addStarterCategory,
    isStarterCategoryAdded,
    addCustomCategory,
    categoryLabels,
  }
}
