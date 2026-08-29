import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ACCENT_PRESETS_DARK,
  ACCENT_PRESETS_LIGHT,
  BG_PRESETS_DARK,
  BG_PRESETS_LIGHT,
  LIGHT_THEME_PRESETS,
  DARK_THEME_PRESETS,
  resolveThemeMode,
  getThemePreset,
} from '../lib/colors'
import {
  LANGUAGES,
  SYSTEM_LANGUAGE,
  getSystemLanguage,
} from '../i18n/languages'
import { defaultCornerRadius } from '../lib/platform'
import {
  useOnboarding,
  STARTER_CATEGORIES,
} from '../hooks/useOnboarding'
import { api } from '../lib/api'
import { Titlebar } from '../components/titlebar/Titlebar'
import { useDiscordRpc } from '../hooks/useDiscordRpc'
import { DirList } from '../components/reusables/DirList'
import { ColorSwatchPicker } from '../components/ui/ColorSwatchPicker'
import { Slider } from '../components/ui/Slider'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { LanguageFlag } from '../components/reusables/LanguageFlag'
import { Dropdown } from '../components/ui/Dropdown'
import { Toggle } from '../components/ui/Toggle'
import { ThemePresetsModal } from '../components/modals/ThemePresetsModal'
import { RestoreProgressModal } from '../components/modals/RestoreProgressModal'
import { GitAuthModal } from '../components/modals/GitAuthModal'
import {
  IconCheck,
  IconCopy,
  IconCloudArrowDown,
  IconDownload,
  IconFolderPlus,
  IconLayoutGrid,
  IconMonitor,
  IconMoon,
  IconNews,
  IconPalette,
  IconPlus,
  IconRefresh,
  IconSun,
  IconChevronDown,
  IconChevronLeft,
  IconChevronRight,
  IconHouse,
  IconTags,
  IconTrash,
} from '../lib/icons'
import type { AppSettings } from '../types'

interface Props {
  settings: AppSettings
  onComplete: (settings: AppSettings) => Promise<AppSettings> | void
}

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
    <div className="flex flex-col gap-6 w-full max-w-xl">
      <div className="flex items-start gap-4">
        <div className="w-11 h-11 shrink-0 rounded-tile bg-accent/10 border border-accent-dim/30 flex items-center justify-center text-accent-bright">
          {icon}
        </div>
        <div className="min-w-0">
          <h2 className="font-display font-semibold text-2xl tracking-tight text-ink">
            {title}
          </h2>
          <p className="text-sm text-muted mt-1.5 leading-relaxed">
            {description}
          </p>
        </div>
      </div>
      {children}
    </div>
  )
}

function ProgressRow({
  label,
  progress,
  running,
}: {
  label: string
  progress: { current: number; total: number } | null
  running: boolean
}) {
  const { t } = useTranslation('common')
  const hasProgress = !!progress && progress.total > 0
  const pct = hasProgress
    ? Math.min((progress.current / progress.total) * 100, 100)
    : 0

  return (
    <div className="flex flex-col gap-2 px-4 py-3 rounded-item bg-overlay border border-outline/50">
      <div className="flex items-center justify-between gap-3">
        <span className="text-xs text-muted">{label}</span>
        {hasProgress ? (
          <span className="font-mono text-[11px] text-muted shrink-0">
            {progress.current} / {progress.total}
          </span>
        ) : running ? (
          <span className="flex items-center gap-1.5 text-xs text-accent-bright shrink-0">
            <IconRefresh className="w-3 h-3 animate-spin" />
            <span className="font-mono">…</span>
          </span>
        ) : (
          <span className="font-mono text-[11px] text-muted shrink-0">
            {t('none')}
          </span>
        )}
      </div>
      <div className="h-1.5 w-full rounded-full bg-line/40 overflow-hidden">
        {hasProgress ? (
          <motion.div
            className="h-full rounded-full bg-accent"
            initial={{ width: 0 }}
            animate={{ width: `${pct}%` }}
            transition={{ duration: 0.3, ease: 'easeOut' }}
          />
        ) : running ? (
          <motion.div
            className="h-full rounded-full bg-accent/60"
            animate={{ x: ['-100%', '400%'] }}
            transition={{ repeat: Infinity, duration: 1.4, ease: 'easeInOut' }}
            style={{ width: '30%' }}
          />
        ) : (
          <div className="h-full w-0" />
        )}
      </div>
    </div>
  )
}

function SummaryRow({
  label,
  value,
}: {
  label: string
  value: React.ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-4 px-4 py-3 rounded-item bg-overlay border border-outline/50">
      <span className="text-xs text-muted shrink-0">{label}</span>
      <span className="font-mono text-xs text-ink text-right min-w-0 truncate">
        {value}
      </span>
    </div>
  )
}

function SummarySection({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-[10px] font-semibold uppercase tracking-wide text-muted/70 px-1">
        {title}
      </span>
      <div className="flex flex-col gap-1.5">{children}</div>
    </div>
  )
}

export function OnboardingView({
  settings,
  onComplete,
}: Props) {
  const { t } = useTranslation('onboarding')
  const { t: tc, i18n } = useTranslation('common')
  const { t: ts } = useTranslation('settings')
  const [presetModal, setPresetModal] = useState<'light' | 'dark' | null>(null)

  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent('app:view-changed', { detail: 'onboarding' }),
    )
  }, [])

  const {
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
  } = useOnboarding({ settings, onComplete })

  useDiscordRpc(draft, [])

  return (
    <div className="new-ui h-screen w-screen flex flex-col bg-base text-ink font-body select-none">
      <Titlebar minimal />

      <div className="flex-1 min-h-0 flex gap-4 p-4 pt-2">
        <aside className="shrink-0 w-60 flex flex-col rounded-card bg-raised overflow-hidden">
          <div className="p-5 pb-4 border-b border-line">
            <div className="flex items-center gap-2.5">
              <span className="font-display font-black text-xl tracking-tight text-ink">
                GodotHub
              </span>
            </div>
            <p className="text-[11px] text-muted/70 mt-2 leading-relaxed">
              {t('welcome_desc')}
            </p>
          </div>

          <OverlayScrollArea
            className="flex-1 min-h-0"
            hideThumb={!settings.show_scrollbars}
            hideTopButton
          >
            <div className="p-3 flex flex-col gap-1">
            {STEPS.map((s, i) => {
              const active = i === stepIndex
              const done = i < stepIndex
              return (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => jumpTo(i)}
                  className={`focus-ring cursor-pointer relative flex items-center gap-2.5 px-3 py-2.5 rounded-item text-sm font-medium transition-colors ${
                    active
                      ? 'text-ink'
                      : done
                        ? 'text-accent-bright'
                        : 'text-muted hover:text-ink hover:bg-overlay/60'
                  }`}
                >
                  {active && (
                    <motion.span
                      layoutId="new-ui-onboarding-pill"
                      transition={{ type: 'spring', stiffness: 650, damping: 38 }}
                      className="absolute inset-0 rounded-item bg-overlay border border-outline/50 shadow-md shadow-black/10 pointer-events-none"
                    />
                  )}
                  <span
                    className={`relative w-6 h-6 shrink-0 flex items-center justify-center rounded-tag text-[10px] font-bold border transition-colors ${
                      done
                        ? 'bg-accent/15 text-accent-bright border-accent-dim/40'
                        : active
                          ? 'bg-accent/15 text-accent-bright border-accent-dim/40'
                          : 'bg-overlay text-muted border-outline/50'
                    }`}
                  >
                    {done ? <IconCheck className="w-3 h-3" /> : i + 1}
                  </span>
                  <span className="relative min-w-0 truncate">
                    {stepLabel(s.id)}
                  </span>
                </button>
              )
            })}
            </div>
          </OverlayScrollArea>

          <div className="shrink-0 p-4 border-t border-line flex flex-col gap-2">
            <div className="h-1.5 w-full rounded-full bg-line/40 overflow-hidden">
              <motion.div
                className="h-full rounded-full bg-accent"
                animate={{
                  width: `${((stepIndex + 1) / STEPS.length) * 100}%`,
                }}
                transition={{ duration: 0.3, ease: 'easeOut' }}
              />
            </div>
            <span className="text-[10px] font-medium text-muted/70 text-center tabular-nums">
              {stepIndex + 1} / {STEPS.length}
            </span>
          </div>
        </aside>

        <main className="flex-1 min-w-0 flex flex-col rounded-card bg-raised overflow-hidden">
          <div className="flex-1 min-h-0 flex flex-col">
            <OverlayScrollArea
              className="flex-1 min-w-0"
              hideThumb={!settings.show_scrollbars}
              hideTopButton
            >
              <div className="min-h-full px-6 py-6 sm:px-10 sm:py-8">
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
                        icon={<IconHouse className="w-5 h-5" />}
                        title={t('welcome_title')}
                        description={t('welcome_desc')}
                      >
                        <div className="flex flex-col gap-6">
                          <div className="flex flex-col gap-2.5">
                            <span className="text-xs font-semibold uppercase tracking-wide text-muted">
                              {t('language_heading')}
                            </span>
                            <Dropdown
                              align="left"
                              trigger={({ open, toggle }) => {
                                const current = LANGUAGES.find(
                                  (l) => l.value === draft.language,
                                )
                                return (
                                  <button
                                    type="button"
                                    aria-expanded={open}
                                    onClick={toggle}
                                    className="focus-ring cursor-pointer inline-flex items-center gap-2 px-3.5 py-2 rounded-btn border border-outline/50 bg-overlay text-sm font-medium text-ink hover:border-accent-dim transition-colors"
                                  >
                                    {current && <LanguageFlag country={current.country} />}
                                    {current
                                      ? current.labelKey
                                        ? i18n.t(`settings:${current.labelKey}`)
                                        : current.label
                                      : i18n.language}
                                    <IconChevronDown className={`w-3 h-3 text-muted transition-transform duration-200 ${open ? 'rotate-180' : ''}`} />
                                  </button>
                                )
                              }}
                              items={LANGUAGES.map(({ value, label, labelKey, country }) => ({
                                key: value,
                                label: labelKey ? i18n.t(`settings:${labelKey}`) : label,
                                leading: <LanguageFlag country={country} className="w-5 h-3.5" />,
                                active: draft.language === value,
                                onClick: () => {
                                  const language =
                                    value === SYSTEM_LANGUAGE
                                      ? getSystemLanguage()
                                      : value

                                  i18n.changeLanguage(language)

                                setDraft((prev) => ({
                                  ...prev,
                                  language: value,
                                }))
                              },
                              }))}
                            />
                          </div>

                          <OnboardingCloudBackup />

                          <div className="flex items-center justify-between gap-4 px-4 py-3 rounded-item bg-overlay border border-outline/50">
                            <div className="min-w-0">
                              <p className="text-xs font-medium text-ink">
                                {tc('onboarding_discord_rpc')}
                              </p>
                              <p className="text-[11px] text-muted mt-0.5 leading-relaxed">
                                {tc('onboarding_discord_rpc_desc')}
                              </p>
                            </div>
                            <Toggle
                              checked={draft.discord_rpc_enabled}
                              onChange={(checked) =>
                                setDraft((prev) => ({ ...prev, discord_rpc_enabled: checked }))
                              }
                              label={tc('onboarding_discord_rpc')}
                            />
                          </div>

                          <div className="grid grid-cols-3 gap-3">
                            <div className="flex flex-col gap-2 p-4 rounded-item bg-overlay border border-outline/50">
                              <IconLayoutGrid className="w-4 h-4 text-accent-bright" />
                              <span className="text-xs font-medium text-ink">
                                {tc('section_projects')}
                              </span>
                              <p className="text-[11px] text-muted leading-relaxed">
                                {t('onboarding_keep_organized', { ns: 'common' })}
                              </p>
                            </div>
                            <div className="flex flex-col gap-2 p-4 rounded-item bg-overlay border border-outline/50">
                              <IconCloudArrowDown className="w-4 h-4 text-accent-bright" />
                              <span className="text-xs font-medium text-ink">
                                {tc('section_versions')}
                              </span>
                              <p className="text-[11px] text-muted leading-relaxed">
                                {t('onboarding_download_manage', { ns: 'common' })}
                              </p>
                            </div>
                            <div className="flex flex-col gap-2 p-4 rounded-item bg-overlay border border-outline/50">
                              <IconNews className="w-4 h-4 text-accent-bright" />
                              <span className="text-xs font-medium text-ink">
                                {tc('section_news')}
                              </span>
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
                        <div className="flex flex-col gap-4 w-full">
                          <DirList
                            dirs={draft.project_scan_dirs}
                            onChange={(dirs) =>
                              setField('project_scan_dirs', dirs)
                            }
                            emptyHint={t('onboard_empty_projects')}
                            defaultDir={draft.default_project_location}
                            onSetDefault={(dir) =>
                              setField('default_project_location', dir)
                            }
                            defaultLabel={ts('new_project_default')}
                          />
                          {projectSuggestions.length > 0 && (
                            <div className="flex flex-col gap-1.5">
                              <span className="text-[10px] font-semibold uppercase tracking-wide text-muted/70">
                                {tc('suggested_from_workspaces')}
                              </span>
                              <div className="flex flex-wrap gap-1.5">
                                {projectSuggestions.map((s) => {
                                  const added = draft.project_scan_dirs.includes(
                                    s.path,
                                  )
                                  return (
                                    <button
                                      key={s.path}
                                      type="button"
                                      onClick={() => {
                                        if (added) return
                                        setField('project_scan_dirs', [
                                          ...draft.project_scan_dirs,
                                          s.path,
                                        ])
                                      }}
                                      disabled={added}
                                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-tag border text-[11px] font-mono transition-colors disabled:cursor-default ${
                                        added
                                          ? 'border-accent-dim/40 bg-accent/10 text-accent-bright'
                                          : 'border-dashed border-outline/60 text-muted hover:text-accent-bright hover:border-accent-dim'
                                      }`}
                                    >
                                      {added ? (
                                        <IconCheck className="w-3 h-3 shrink-0" />
                                      ) : (
                                        <IconPlus className="w-3 h-3 shrink-0" />
                                      )}
                                      <span className="max-w-48 truncate">
                                        {s.path}
                                      </span>
                                      <span className="shrink-0 text-[10px] text-muted">
                                        {tc('from_workspace', { name: s.source })}
                                      </span>
                                    </button>
                                  )
                                })}
                              </div>
                            </div>
                          )}
                        </div>
                      </StepShell>
                    )}

                    {step.id === 'versions' && (
                      <StepShell
                        icon={<IconDownload className="w-5 h-5" />}
                        title={t('onboarding_versions_title', { ns: 'common' })}
                        description={t('onboarding_versions_desc', { ns: 'common' })}
                      >
                        <div className="flex flex-col gap-4 w-full">
                          <DirList
                            dirs={draft.version_scan_dirs}
                            onChange={(dirs) =>
                              setField('version_scan_dirs', dirs)
                            }
                            emptyHint={t('onboard_empty_versions')}
                            defaultDir={draft.download_dir}
                            onSetDefault={(dir) =>
                              setField('download_dir', dir)
                            }
                            defaultLabel={ts('download_folder')}
                          />
                          {versionSuggestions.length > 0 && (
                            <div className="flex flex-col gap-1.5">
                              <span className="text-[10px] font-semibold uppercase tracking-wide text-muted/70">
                                {tc('suggested_from_workspaces')}
                              </span>
                              <div className="flex flex-wrap gap-1.5">
                                {versionSuggestions.map((s) => {
                                  const added = draft.version_scan_dirs.includes(
                                    s.path,
                                  )
                                  return (
                                    <button
                                      key={s.path}
                                      type="button"
                                      onClick={() => {
                                        if (added) return
                                        setField('version_scan_dirs', [
                                          ...draft.version_scan_dirs,
                                          s.path,
                                        ])
                                      }}
                                      disabled={added}
                                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-tag border text-[11px] font-mono transition-colors disabled:cursor-default ${
                                        added
                                          ? 'border-accent-dim/40 bg-accent/10 text-accent-bright'
                                          : 'border-dashed border-outline/60 text-muted hover:text-accent-bright hover:border-accent-dim'
                                      }`}
                                    >
                                      {added ? (
                                        <IconCheck className="w-3 h-3 shrink-0" />
                                      ) : (
                                        <IconPlus className="w-3 h-3 shrink-0" />
                                      )}
                                      <span className="max-w-48 truncate">
                                        {s.path}
                                      </span>
                                      <span className="shrink-0 text-[10px] text-muted">
                                        {tc('from_workspace', { name: s.source })}
                                      </span>
                                    </button>
                                  )
                                })}
                              </div>
                            </div>
                          )}
                        </div>
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
                                className="flex-1 bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-xs font-mono text-ink"
                              />
                            ) : (
                              <span className="text-xs text-muted">
                                {t('onboard_no_template_folder')}
                              </span>
                            )}
                            <button
                              type="button"
                              onClick={async () => {
                                const folder = await api.pickFolder()
                                if (folder)
                                  setField('template_scan_dir', folder)
                              }}
                              className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn border border-outline/50 text-sm hover:border-accent-dim hover:bg-overlay transition-colors"
                            >
                              {tc('browse')}
                            </button>
                            {draft.template_scan_dir && (
                              <button
                                type="button"
                                onClick={() => setField('template_scan_dir', null)}
                                className="focus-ring cursor-pointer px-3 py-2.5 rounded-btn border border-outline/50 text-xs text-muted hover:text-danger hover:border-danger/30 hover:bg-danger/10 transition-colors"
                              >
                                {tc('clear')}
                              </button>
                            )}
                          </div>

                          {pendingTemplateSuggestions.length > 0 && (
                            <div className="flex flex-col gap-1.5">
                              <span className="text-[10px] font-semibold uppercase tracking-wide text-muted/70">
                                {tc('suggested_from_workspaces')}
                              </span>
                              {pendingTemplateSuggestions.map((s) => (
                                <button
                                  key={s.path}
                                  type="button"
                                  onClick={() =>
                                    setField('template_scan_dir', s.path)
                                  }
                                  className="focus-ring cursor-pointer flex items-center gap-2 px-3 py-2 rounded-item border border-dashed border-outline/60 text-left hover:border-accent-dim hover:bg-overlay/60 transition-colors"
                                >
                                  <span className="shrink-0 flex items-center justify-center w-4 h-4 rounded-tag bg-accent/15 text-accent-bright">
                                    <IconCopy className="w-3 h-3" />
                                  </span>
                                  <span className="text-[11px] font-mono text-ink truncate">
                                    {s.path}
                                  </span>
                                  <span className="shrink-0 text-[10px] text-muted truncate max-w-32">
                                    {tc('from_workspace', { name: s.source })}
                                  </span>
                                </button>
                              ))}
                            </div>
                          )}
                        </div>                      </StepShell>
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
                                  className={`focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-btn border text-xs font-medium transition-colors disabled:cursor-default ${
                                    added
                                      ? 'border-accent-dim/50 bg-accent/10 text-accent-bright'
                                      : 'border-dashed border-outline/50 text-muted hover:text-accent-bright hover:border-accent-dim'
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
                              className="focus-ring flex-1 bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm focus:border-accent-dim outline-none transition-colors"
                            />
                            <motion.button
                              whileHover={categoryBusy ? undefined : { y: -1 }}
                              whileTap={categoryBusy ? undefined : { scale: 0.96 }}
                              onClick={addCustomCategory}
                              disabled={categoryBusy || !categoryDraft.trim()}
                              className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white transition-colors"
                            >
                              <IconPlus className="w-3.5 h-3.5" />
                              {tc('add')}
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
                                    className="group flex items-center justify-between gap-2 px-3.5 py-2 rounded-btn bg-raised border border-outline/50"
                                  >
                                    <span className="text-xs text-ink">{c.name}</span>
                                    <button
                                      onClick={() => removeCategory(c.id)}
                                      aria-label={tc('remove_category_aria', { name: c.name })}
                                      className="focus-ring cursor-pointer text-muted opacity-0 group-hover:opacity-100 hover:text-danger transition-colors"
                                    >
                                      <IconTrash className="w-3.5 h-3.5" />
                                    </button>
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      </StepShell>
                    )}

                    {step.id === 'customize' && (
                      <StepShell
                        icon={<IconPalette className="w-5 h-5" />}
                        title={t('onboarding_customize_title', { ns: 'common' })}
                        description={t('onboarding_customize_desc', { ns: 'common' })}
                      >
                        <div className="flex flex-col gap-7 w-full">
                          <div className="flex flex-col gap-2.5">
                            <span className="text-xs font-medium text-muted">
                              {ts('theme_preset_label')}
                            </span>
                            <div className="flex flex-col gap-2">
                              {([
                                {
                                  mode: 'light' as const,
                                  label: ts('preset_light_group'),
                                  Icon: IconSun,
                                  presets: LIGHT_THEME_PRESETS,
                                },
                                {
                                  mode: 'dark' as const,
                                  label: ts('preset_dark_group'),
                                  Icon: IconMoon,
                                  presets: DARK_THEME_PRESETS,
                                },
                              ]).map(({ mode, label, Icon, presets }) => (
                                <button
                                  key={mode}
                                  type="button"
                                  onClick={() => setPresetModal(mode)}
                                  className="focus-ring cursor-pointer flex items-center gap-3 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-overlay px-4 py-3.5 transition-colors"
                                >
                                  <Icon className="w-4 h-4 text-muted shrink-0" />
                                  <span className="text-xs font-medium text-ink">
                                    {label}
                                  </span>
                                  <span className="text-[10px] font-medium text-muted/60">
                                    {presets.length}
                                  </span>
                                  <IconChevronRight className="w-3.5 h-3.5 text-muted ml-auto" />
                                </button>
                              ))}

                              <button
                                type="button"
                                onClick={() => selectPreset('custom')}
                                className={`focus-ring cursor-pointer flex items-center gap-3 rounded-btn border px-4 py-3.5 transition-colors ${
                                  !presetActive
                                    ? 'border-accent bg-accent/10'
                                    : 'border-outline/50 hover:border-accent-dim hover:bg-overlay'
                                }`}
                              >
                                <IconPalette className="w-4 h-4 text-muted shrink-0" />
                                <span className="text-xs font-medium text-ink">
                                  {ts('theme_preset_custom')}
                                </span>
                                {!presetActive && (
                                  <IconCheck className="w-3.5 h-3.5 text-accent-bright ml-auto" />
                                )}
                              </button>
                            </div>
                            <p className="text-[11px] text-muted leading-relaxed">
                              {ts('theme_preset_desc')}
                            </p>
                          </div>

                          {!presetActive && (
                            <>
                              <div className="flex flex-wrap gap-8">
                                <ColorSwatchPicker
                                  label={t('onboarding_accent_color', { ns: 'common' })}
                                  value={draft.accent_color}
                                  presets={
                                    resolveThemeMode(draft.theme_mode) === 'light'
                                      ? ACCENT_PRESETS_LIGHT
                                      : ACCENT_PRESETS_DARK
                                  }
                                  onChange={(hex) => {
                                    setAccentColor(hex)
                                  }}
                                />
                                <ColorSwatchPicker
                                  label={t('onboarding_bg_color', { ns: 'common' })}
                                  value={draft.background_color}
                                  presets={
                                    resolveThemeMode(draft.theme_mode) === 'light'
                                      ? BG_PRESETS_LIGHT
                                      : BG_PRESETS_DARK
                                  }
                                  onChange={(hex) => {
                                    setBackgroundColor(hex)
                                  }}
                                />
                              </div>

                              <div className="inline-flex self-start rounded-btn border border-outline/50 bg-overlay p-1 gap-1">
                                {([
                                  { mode: 'dark' as const, label: ts('dark'), Icon: IconMoon },
                                  { mode: 'light' as const, label: ts('light'), Icon: IconSun },
                                  { mode: 'system' as const, label: ts('system'), Icon: IconMonitor },
                                ]).map(({ mode, label, Icon }) => {
                                  const active = draft.theme_mode === mode
                                  return (
                                    <button
                                      key={mode}
                                      type="button"
                                      onClick={() => setThemeMode(mode)}
                                      className={`focus-ring cursor-pointer flex items-center gap-2 px-3.5 py-1.5 rounded-btn text-sm font-medium transition-colors ${
                                        active
                                          ? 'bg-accent text-white'
                                          : 'text-muted hover:text-ink hover:bg-raised'
                                      }`}
                                    >
                                      <Icon className="w-3.5 h-3.5" />
                                      {label}
                                    </button>
                                  )
                                })}
                              </div>
                            </>
                          )}

                          <div className="flex flex-col gap-2.5">
                            <Slider
                              label={t('onboarding_corner_radius', { ns: 'common' })}
                              display={
                                <span className="text-xs font-mono text-ink tabular-nums">
                                  {draft.corner_radius}px
                                </span>
                              }
                              value={draft.corner_radius}
                              min={0}
                              max={20}
                              step={1}
                              defaultValue={defaultCornerRadius}
                              onChange={(v) => {
                                setCornerRadius(v)
                              }}
                            />
                          </div>
                        </div>
                      </StepShell>
                    )}

                    {step.id === 'finish' && (
                      <StepShell
                        icon={<IconCheck className="w-5 h-5" />}
                        title={t(
                          finishing
                            ? 'onboarding_setting_up_title'
                            : 'onboarding_finish_title',
                          { ns: 'common' },
                        )}
                        description={
                          finishing
                            ? t('onboarding_setting_up_desc', { ns: 'common' })
                            : t('onboarding_finish_desc', { ns: 'common' })
                        }
                      >
                        {finishing ? (
                          <div className="flex flex-col gap-3 w-full">
                            <ProgressRow
                              label={
                                draft.project_scan_dirs.length > 0
                                  ? tc('scanning_projects')
                                  : tc('skipped')
                              }
                              progress={
                                draft.project_scan_dirs.length > 0
                                  ? scanProgress.projects
                                  : null
                              }
                              running={draft.project_scan_dirs.length > 0}
                            />
                            <ProgressRow
                              label={
                                draft.version_scan_dirs.length > 0
                                  ? tc('scanning_versions')
                                  : tc('skipped')
                              }
                              progress={
                                draft.version_scan_dirs.length > 0
                                  ? scanProgress.versions
                                  : null
                              }
                              running={draft.version_scan_dirs.length > 0}
                            />
                            {draft.template_scan_dir && (
                              <ProgressRow
                                label={tc('syncing')}
                                progress={null}
                                running
                              />
                            )}

                          </div>
                        ) : (
                          <div className="flex flex-col gap-4 w-full">
                            <SummarySection
                              title={ts('interface_label')}
                            >
                              <SummaryRow
                                label={ts('language_label')}
                                value={
                                  (() => {
                                    const lang = LANGUAGES.find(
                                      (l) => l.value === draft.language,
                                    )

                                    return lang ? (
                                      <span className="inline-flex items-center gap-1.5">
                                        <LanguageFlag country={lang.country} />
                                        {lang.labelKey
                                          ? i18n.t(`settings:${lang.labelKey}`)
                                          : lang.label}
                                      </span>
                                    ) : (
                                      draft.language
                                    )
                                  })()
                                }
                              />
                            </SummarySection>

                            <SummarySection title={ts('appearance')}>
                              <SummaryRow
                                label={ts('theme')}
                                value={`${ts(
                                  draft.theme_mode === 'system'
                                    ? 'system'
                                    : draft.theme_mode,
                                )} · ${
                                  getThemePreset(draft.theme_preset)?.name ??
                                  ts('theme_preset_custom')
                                }`}
                              />
                              <SummaryRow
                                label={ts('corner_radius_label')}
                                value={`${draft.corner_radius}px`}
                              />
                            </SummarySection>

                            <SummarySection title={ts('storage')}>
                              <SummaryRow
                                label={t('project_folders')}
                                value={
                                  draft.project_scan_dirs.length || tc('none')
                                }
                              />
                              <SummaryRow
                                label={t('version_folders')}
                                value={
                                  draft.version_scan_dirs.length || tc('none')
                                }
                              />
                              <SummaryRow
                                label={tc('section_templates')}
                                value={
                                  draft.template_scan_dir || tc('none')
                                }
                              />
                            </SummarySection>


                          </div>
                        )}
                      </StepShell>
                    )}
                  </motion.div>
                </AnimatePresence>
              </div>
            </OverlayScrollArea>
          </div>

          <div className="shrink-0 px-6 py-4 border-t border-line flex items-center justify-between gap-4">
            <button
              type="button"
              onClick={() => (stepIndex === 0 ? finish(true) : goBack())}
              disabled={finishing}
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-4 py-2.5 rounded-item text-sm text-muted hover:text-ink hover:bg-overlay transition-colors disabled:opacity-50"
            >
              {stepIndex === 0 ? (
                tc('skip_setup')
              ) : (
                <>
                  <IconChevronLeft className="w-3.5 h-3.5" />
                  {tc('back')}
                </>
              )}
            </button>

            {step.id === 'finish' ? (
              <button
                type="button"
                onClick={() => finish(false)}
                disabled={finishing}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-6 py-2.5 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-60 text-sm font-medium text-white transition-colors"
              >
                {finishing ? tc('finishing') : tc('get_started')}
              </button>
            ) : (
              <button
                type="button"
                onClick={goNext}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-6 py-2.5 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
              >
                {t('onboarding_continue', { ns: 'common' })}
                <IconChevronRight className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </main>
      </div>

      <AnimatePresence>
        {presetModal && (
          <ThemePresetsModal
            mode={presetModal}
            currentId={draft.theme_preset}
            onSelect={(id) => {
              selectPreset(id)
              setPresetModal(null)
            }}
            onClose={() => setPresetModal(null)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

function OnboardingCloudBackup() {
  const { t } = useTranslation('onboarding')
  const { t: ts } = useTranslation('settings')
  const [gitUser, setGitUser] = useState<string | null>(null)
  const [gistUrl, setGistUrl] = useState('')
  const [busy, setBusy] = useState(false)
  const [msg, setMsg] = useState<string | null>(null)
  const [showRestoreModal, setShowRestoreModal] = useState(false)
  const [showGitAuth, setShowGitAuth] = useState(false)
  const [savedGistUrl, setSavedGistUrl] = useState<string | null>(null)

  useEffect(() => {
    api.gitAuthGetState().then((s) => {
      if (s.github) setGitUser(s.github.username)
    })
    api.gistSyncGetInfo().then((info) => {
      if (info) setSavedGistUrl(info.gist_url)
    })
  }, [])

  const handleConnected = (username: string) => {
    setGitUser(username)
    setShowGitAuth(false)
  }

  const handlePull = async () => {
    if (!gistUrl.trim()) return
    setBusy(true)
    setMsg(null)
    try {
      await api.gistSyncSaveGistUrl(gistUrl.trim())
      setShowRestoreModal(true)
    } catch (e) {
      setMsg(String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="flex flex-col gap-2.5">
      <span className="text-xs font-semibold uppercase tracking-wide text-muted">
        {t('onboard_cloud_heading')}
      </span>
      <div className="rounded-item bg-overlay border border-outline/50 p-4 flex flex-col gap-3">
        <p className="text-[11px] text-muted leading-relaxed">
          {t('onboard_cloud_desc')}
        </p>
        {!gitUser ? (
          <button
            type="button"
            onClick={() => setShowGitAuth(true)}
            className="focus-ring cursor-pointer self-start inline-flex items-center gap-2 px-4 py-2 rounded-btn bg-overlay border border-outline/50 hover:border-accent-dim hover:bg-raised text-xs font-medium transition-colors"
          >
            {t('onboard_cloud_sign_in')}
          </button>
        ) : (
          <div className="flex flex-col gap-2.5">
            <p className="text-xs text-green flex items-center gap-1.5">
              <IconCheck className="w-3.5 h-3.5" />
              {t('onboard_cloud_connected', { username: gitUser })}
            </p>
            {savedGistUrl && (
              <button
                type="button"
                onClick={() => setShowRestoreModal(true)}
                disabled={busy}
                className="focus-ring cursor-pointer self-start inline-flex items-center gap-2 px-4 py-2 rounded-btn bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors disabled:opacity-50"
              >
                {ts('sync_pull_btn')}
              </button>
            )}
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={gistUrl}
                onChange={(e) => setGistUrl(e.target.value)}
                placeholder={ts('sync_manual_placeholder')}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handlePull()
                }}
                className="focus-ring flex-1 bg-base border border-outline/50 rounded-btn px-3 py-2 text-xs focus:border-accent-dim transition-colors"
              />
              <button
                type="button"
                onClick={handlePull}
                disabled={busy || !gistUrl.trim()}
                className="focus-ring cursor-pointer px-4 py-2 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-raised text-xs font-medium transition-colors disabled:opacity-50"
              >
                {busy ? ts('saving') : ts('sync_manual_pull_btn')}
              </button>
            </div>
          </div>
        )}
        {msg && (
          <p className="text-[11px] text-muted">{msg}</p>
        )}
      </div>

      <AnimatePresence>
        {showRestoreModal && (
          <RestoreProgressModal onClose={() => setShowRestoreModal(false)} />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showGitAuth && (
          <GitAuthModal
            provider="github"
            onClose={() => setShowGitAuth(false)}
            onConnected={handleConnected}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
