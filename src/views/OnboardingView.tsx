import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { applyTheme } from '../lib/colors'
import { applyRadius } from '../lib/appearance'
import { useCategoriesContext } from '../hooks/categoriesContext'
import { DirList } from '../components/ui/DirList'
import { ColorSwatchPicker } from '../components/ui/ColorSwatchPicker'
import { Slider } from '../components/ui/Slider'
import { api } from '../lib/api'
import {
  IconLayoutGrid,
  IconLayoutList,
  IconNews,
  IconTags,
  IconPlus,
  IconTrash,
  IconCheck,
  IconFolderPlus,
  IconDownload,
  IconArrowUpDown,
  IconCopy,
} from '../components/Icons'
import type { AppSettings } from '../types'

const ACCENT_PRESETS_DARK = [
  '#457ff2',
  '#5865f2',
  '#7983f5',
  '#23a55a',
  '#f0b132',
  '#eb459e',
  '#00a8fc',
  '#2dd4bf',
  '#a78bfa',
  '#f97316',
  '#84cc16',
  '#e11d48',
  '#0ea5e9',
  '#facc15',
  '#8b5cf6',
]

const ACCENT_PRESETS_LIGHT = [
  '#457ff2',
  '#5b75e6',
  '#7480e8',
  '#36a05b',
  '#e0a832',
  '#d9458e',
  '#00a1e8',
  '#2dc4b4',
  '#9d7ae0',
  '#ec7031',
  '#78b820',
  '#d1263f',
  '#1b9ce0',
  '#e8c420',
  '#8470e8',
  '#e04244',
  '#28b45a',
  '#4285d4',
  '#d94562',
]

const BG_PRESETS_DARK = [
  '#15171c',
  '#10131a',
  '#1e1f22',
  '#111214',
  '#13151a',
  '#0f1115',
  '#20232a',
  '#171a21',
  '#1c1e24',
  '#1a1c23',
  '#0d0e11',
  '#232630',
  '#1b1d24',
  '#101114',
  '#191b20',
]

const BG_PRESETS_LIGHT = [
  '#f8f9fa',
  '#ffffff',
  '#f0f2f5',
  '#f5f5f5',
  '#fafafa',
  '#eceff1',
  '#f3f4f6',
  '#f9fafb',
  '#eef1f5',
  '#f8f6f3',
  '#f2f6fc',
  '#faf5ef',
  '#edf2f7',
  '#f6f8fa',
  '#f1f3f5',
  '#e8ecf1',
  '#faf6f0',
]

const STARTER_CATEGORIES = [
  'In Progress',
  'Prototypes',
  'Finished',
  'Game Jams',
]

interface Props {
  settings: AppSettings
  onComplete: (settings: AppSettings) => Promise<AppSettings> | void
}

type StepId =
  'welcome' | 'projects' | 'versions' | 'templates' | 'categories' | 'customize' | 'finish'

const ALL_STEPS: { id: StepId }[] = [
  { id: 'welcome' },
  { id: 'projects' },
  { id: 'versions' },
  { id: 'templates' },
  { id: 'categories' },
  { id: 'customize' },
  { id: 'finish' },
]

function StepShell({
  icon,
  title,
  description,
  children,
}: {
  icon: React.ReactNode
  title: string
  description: string
  children: React.ReactNode
}) {
  return (
    <div className="flex flex-col gap-8 w-full max-w-xl">
      <div className="flex flex-col gap-3">
        <div className="w-11 h-11 rounded-xl bg-accent/15 border border-accent-dim/40 flex items-center justify-center text-accent-bright">
          {icon}
        </div>
        <div>
          <h2 className="font-display font-semibold text-2xl tracking-tight">
            {title}
          </h2>
          <p className="text-sm text-muted mt-2 leading-relaxed">
            {description}
          </p>
        </div>
      </div>
      {children}
    </div>
  )
}

export function OnboardingView({ settings, onComplete }: Props) {
  const { t } = useTranslation('onboarding')
  const { t: tc, i18n } = useTranslation('common')
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

  const goNext = () => setStepIndex((i) => Math.min(i + 1, STEPS.length - 1))
  const goBack = () => setStepIndex((i) => Math.max(i - 1, 0))

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

  return (
    <div className="h-screen w-screen flex flex-col bg-base text-ink font-body select-none">
      {/* Draggable region so the window can be moved during setup (no TitleBar is shown) */}
      <div data-tauri-drag-region className="h-10 shrink-0" />
      <div className="flex-1 flex flex-col items-center justify-center px-8 py-12 overflow-y-auto">
        <div className="flex items-center gap-2 mb-12">
          {STEPS.map((s, i) => (
            <div
              key={s.id}
              title={t(s.id)}
              className={`h-1.5 rounded-full transition-all duration-300 ${
                i === stepIndex
                  ? 'w-8 bg-accent'
                  : i < stepIndex
                    ? 'w-4 bg-accent-dim'
                    : 'w-4 bg-line'
              }`}
            />
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={step.id}
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -16 }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="w-full flex flex-col items-center"
          >
            {step.id === 'welcome' && (
              <StepShell
                icon={<span className="font-black italic text-lg">GH</span>}
                title={t('welcome_title')}
                description={t('welcome_desc')}
              >
                <div className="flex flex-col gap-5">
                  <div className="flex flex-col gap-2">
                    <span className="text-xs font-semibold uppercase tracking-wide text-muted">
                      {t('language_heading')}
                    </span>
                    <div className="inline-flex self-start rounded-lg border border-line bg-raised p-1 gap-1">
                      {[
                        { value: 'en-US', label: 'English' },
                        { value: 'zh-CN', label: '简体中文' },
                      ].map(({ value, label }) => {
                        const active = i18n.language === value || i18n.language.startsWith(value.split('-')[0])
                        return (
                          <motion.button
                            key={value}
                            whileTap={{ scale: 0.96 }}
                            onClick={() => {
                              i18n.changeLanguage(value)
                              setDraft((prev) => ({ ...prev, language: value }))
                            }}
                            className={
                              'focus-ring cursor-pointer px-4 py-2 rounded-md text-sm font-medium transition-colors ' +
                              (active
                                ? 'bg-accent text-white'
                                : 'text-muted hover:text-ink hover:bg-overlay/60')
                            }
                          >
                            {label}
                          </motion.button>
                        )
                      })}
                    </div>
                  </div>
                  <div className="grid grid-cols-3 gap-3">
                    <div className="flex flex-col gap-2 p-4 rounded-xl border border-line bg-surface/60">
                      <IconLayoutGrid className="w-4 h-4 text-accent-bright" />
                      <span className="text-xs font-medium">{tc('section_projects')}</span>
                      <p className="text-[11px] text-muted leading-relaxed">
                        {t('onboarding_keep_organized', { ns: 'common' })}
                      </p>
                    </div>
                    <div className="flex flex-col gap-2 p-4 rounded-xl border border-line bg-surface/60">
                      <IconLayoutList className="w-4 h-4 text-accent-bright" />
                      <span className="text-xs font-medium">{tc('section_versions')}</span>
                      <p className="text-[11px] text-muted leading-relaxed">
                        {t('onboarding_download_manage', { ns: 'common' })}
                      </p>
                    </div>
                    <div className="flex flex-col gap-2 p-4 rounded-xl border border-line bg-surface/60">
                      <IconNews className="w-4 h-4 text-accent-bright" />
                      <span className="text-xs font-medium">{tc('section_news')}</span>
                      <p className="text-[11px] text-muted leading-relaxed">
                        {t('onboarding_stay_current', { ns: 'common' })}
                      </p>
                    </div>
                  </div>
                </div>
              </StepShell>
            )}

            {step.id === 'projects' && (
              <StepShell
                icon={<IconFolderPlus className="w-5 h-5" />}
                title={t('onboarding_projects_title', { ns: 'common' })}
                description={t('onboarding_projects_desc', { ns: 'common' })}
              >
                <DirList
                  dirs={draft.project_scan_dirs}
                  onChange={(dirs) => setField('project_scan_dirs', dirs)}
                  emptyHint={t('onboard_empty_projects')}
                  defaultDir={draft.default_project_location}
                  onSetDefault={(dir) =>
                    setField('default_project_location', dir)
                  }
                  defaultLabel={t('new_project_default', { ns: 'settings' })}
                />
              </StepShell>
            )}

            {step.id === 'versions' && (
              <StepShell
                icon={<IconDownload className="w-5 h-5" />}
                title={t('onboarding_versions_title', { ns: 'common' })}
                description={t('onboarding_versions_desc', { ns: 'common' })}
              >
                <DirList
                  dirs={draft.version_scan_dirs}
                  onChange={(dirs) => setField('version_scan_dirs', dirs)}
                  emptyHint={t('onboard_empty_versions')}
                  defaultDir={draft.download_dir}
                  onSetDefault={(dir) => setField('download_dir', dir)}
                  defaultLabel={t('download_folder', { ns: 'settings' })}
                />
              </StepShell>
            )}

            {step.id === 'templates' && (
              <StepShell
                icon={<IconCopy className="w-5 h-5" />}
                title={t('onboarding_templates_title', { ns: 'common' })}
                description={t('onboarding_templates_desc', { ns: 'common' })}
              >
                <div className="flex flex-col gap-3 w-full">
                  <div className="flex items-center gap-2.5">
                    {draft.template_scan_dir ? (
                      <input
                        readOnly
                        value={draft.template_scan_dir}
                        className="flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-xs font-mono text-muted"
                      />
                    ) : (
                      <span className="text-xs text-muted">
                        {t('onboard_no_template_folder')}
                      </span>
                    )}
                    <motion.button
                      whileHover={{ y: -1 }}
                      whileTap={{ scale: 0.96 }}
                      onClick={async () => {
                        const folder = await api.pickFolder()
                        if (folder) setField('template_scan_dir', folder)
                      }}
                      className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm transition-colors"
                    >
                      {t('browse', { ns: 'common' })}
                    </motion.button>
                    {draft.template_scan_dir && (
                      <motion.button
                        whileHover={{ y: -1 }}
                        whileTap={{ scale: 0.96 }}
                        onClick={() => setField('template_scan_dir', null)}
                        className="focus-ring cursor-pointer px-3 py-2.5 rounded-lg border border-line text-xs text-muted hover:text-danger hover:border-danger/30 hover:bg-danger/10 transition-colors"
                      >
                        {t('clear', { ns: 'common' })}
                      </motion.button>
                    )}
                  </div>
                </div>
              </StepShell>
            )}

            {step.id === 'categories' && (
              <StepShell
                icon={<IconTags className="w-5 h-5" />}
                title={t('onboarding_categories_title', { ns: 'common' })}
                description={t('onboarding_categories_desc_full', { ns: 'common' })}
              >
                <div className="flex flex-col gap-4 w-full">
                  <div className="flex flex-wrap gap-2">
                    {STARTER_CATEGORIES.map((name) => {
                      const added = categories.some(
                        (c) => c.name.toLowerCase() === name.toLowerCase(),
                      )
                      return (
                        <motion.button
                          key={name}
                          whileHover={added ? undefined : { y: -1 }}
                          whileTap={added ? undefined : { scale: 0.96 }}
                          disabled={added || categoryBusy}
                          onClick={() => addStarterCategory(name)}
                          className={`focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-lg border text-xs font-medium transition-colors disabled:cursor-default ${
                            added
                              ? 'border-accent-dim/50 bg-accent/10 text-accent-bright'
                              : 'border-dashed border-line text-muted hover:text-accent-bright hover:border-accent-dim'
                          }`}
                        >
                          {added ? (
                            <IconCheck className="w-3 h-3" />
                          ) : (
                            <IconPlus className="w-3 h-3" />
                          )}
                          {categoryLabels[name] || name}
                        </motion.button>
                      )
                    })}
                  </div>

                  <div className="flex gap-2.5">
                    <input
                      value={categoryDraft}
                      onChange={(e) => setCategoryDraft(e.target.value)}
                      onKeyDown={(e) =>
                        e.key === 'Enter' && addCustomCategory()
                      }
                      placeholder={t('onboarding_custom_category_placeholder', { ns: 'common' })}
                      className="focus-ring flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors"
                    />
                    <motion.button
                      whileHover={categoryBusy ? undefined : { y: -1 }}
                      whileTap={categoryBusy ? undefined : { scale: 0.96 }}
                      onClick={addCustomCategory}
                      disabled={categoryBusy || !categoryDraft.trim()}
                      className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white transition-colors"
                    >
                      <IconPlus className="w-3.5 h-3.5" />
                      {t('add', { ns: 'common' })}
                    </motion.button>
                  </div>

                  {categories.length > 0 && (
                    <div className="flex flex-col gap-2">
                      <span className="text-[11px] font-medium text-muted uppercase tracking-wide">
                        {t('onboarding_your_categories', { ns: 'common' })}
                      </span>
                      <div className="flex flex-col gap-1.5 max-h-40 overflow-y-auto">
                        {categories.map((c) => (
                          <div
                            key={c.id}
                            className="group flex items-center justify-between gap-2 px-3.5 py-2 rounded-lg bg-raised border border-line"
                          >
                            <span className="text-xs">{c.name}</span>
                            <button
                              onClick={() => removeCategory(c.id)}
                              aria-label={t('remove_category_aria', { ns: 'common', name: c.name })}
                              className="icon-wiggle cursor-pointer text-muted opacity-0 group-hover:opacity-100 hover:text-danger transition-colors"
                            >
                              <IconTrash className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  <p className="text-[11px] text-muted leading-relaxed">
                    {t('onboard_categories_desc')}
                  </p>
                </div>
              </StepShell>
            )}

            {step.id === 'customize' && (
              <StepShell
                icon={<IconArrowUpDown className="w-5 h-5" />}
                title={t('onboarding_customize_title', { ns: 'common' })}
                description={t('onboarding_customize_desc', { ns: 'common' })}
              >
                <div className="flex flex-col gap-7 w-full">
                  <div className="flex gap-8">
                    <ColorSwatchPicker
                      label={t('onboarding_accent_color', { ns: 'common' })}
                      value={draft.accent_color}
                      presets={
                      draft.theme_mode === 'light'
                        ? ACCENT_PRESETS_LIGHT
                        : ACCENT_PRESETS_DARK
                    }
                      onChange={(hex) => {
                        setField('accent_color', hex)
                        applyTheme(
                          hex,
                          draft.background_color,
                          draft.theme_mode as 'dark' | 'light',
                        )
                      }}
                    />
                    <ColorSwatchPicker
                      label={t('onboarding_bg_color', { ns: 'common' })}
                      value={draft.background_color}
                      presets={
                      draft.theme_mode === 'light'
                        ? BG_PRESETS_LIGHT
                        : BG_PRESETS_DARK
                    }
                      onChange={(hex) => {
                        setField('background_color', hex)
                        applyTheme(
                          draft.accent_color,
                          hex,
                          draft.theme_mode as 'dark' | 'light',
                        )
                      }}
                    />
                  </div>

                  <label className="flex flex-col gap-2.5">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-medium text-muted">
                        {t('onboarding_corner_radius', { ns: 'common' })}
                      </span>
                      <span className="text-xs font-mono text-ink bg-raised px-2 py-0.5 rounded-md">
                        {draft.corner_radius}px
                      </span>
                    </div>
                    <Slider
                      min={0}
                      max={20}
                      step={1}
                      value={draft.corner_radius}
                      label={t('onboarding_corner_radius', { ns: 'common' })}
                      onChange={(v) => {
                        setField('corner_radius', v)
                        applyRadius(v)
                      }}
                    />
                  </label>
                </div>
              </StepShell>
            )}

            {step.id === 'finish' && (
              <StepShell
                icon={<IconCheck className="w-5 h-5" />}
                title={t('onboarding_finish_title', { ns: 'common' })}
                description={t('onboarding_finish_desc', { ns: 'common' })}
              >
                <div className="flex flex-col gap-2.5 w-full text-sm">
                  <div className="flex items-center justify-between px-4 py-3 rounded-lg bg-surface/60 border border-line">
                    <span className="text-muted">{t('project_folders')}</span>
                    <span className="font-mono text-xs">
                      {draft.project_scan_dirs.length || tc('none')}
                    </span>
                  </div>
                  <div className="flex items-center justify-between px-4 py-3 rounded-lg bg-surface/60 border border-line">
                    <span className="text-muted">{t('version_folders')}</span>
                    <span className="font-mono text-xs">
                      {draft.version_scan_dirs.length || tc('none')}
                    </span>
                  </div>
                  {settings.categories_enabled && (
                    <div className="flex items-center justify-between px-4 py-3 rounded-lg bg-surface/60 border border-line">
                      <span className="text-muted">{t('categories')}</span>
                      <span className="font-mono text-xs">
                        {categories.length || tc('none')}
                      </span>
                    </div>
                  )}
                </div>
              </StepShell>
            )}
          </motion.div>
        </AnimatePresence>

        <div className="w-full max-w-xl flex items-center justify-between mt-10">
          <button
            onClick={() => (stepIndex === 0 ? finish(true) : goBack())}
            disabled={finishing}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-50"
          >
            {stepIndex === 0 ? tc('skip_setup') : tc('back')}
          </button>

          {step.id === 'finish' ? (
            <motion.button
              whileHover={finishing ? undefined : { y: -1 }}
              whileTap={finishing ? undefined : { scale: 0.96 }}
              onClick={() => finish(false)}
              disabled={finishing}
              className="focus-ring cursor-pointer px-6 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-60 text-sm font-medium text-white transition-colors"
            >
              {finishing ? tc('finishing') : tc('get_started')}
            </motion.button>
          ) : (
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={goNext}
              className="focus-ring cursor-pointer px-6 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
            >
              {t('onboarding_continue', { ns: 'common' })}
            </motion.button>
          )}
        </div>
      </div>
    </div>
  )
}
