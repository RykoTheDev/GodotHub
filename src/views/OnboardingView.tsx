import { useEffect, useLayoutEffect, useRef, useState, type Dispatch, type SetStateAction } from 'react'
import { useTranslation } from 'react-i18next'
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
  STARTER_CATEGORY_COLORS,
} from '../hooks/useOnboarding'
import { CATEGORY_COLORS } from '../lib/categoryColors'
import { api } from '../lib/api'
import { pushToast } from '../lib/toast'
import type { DiscoveredInstall, DiscoveredProject, Project } from '../types'
import { Titlebar } from '../components/titlebar/Titlebar'
import { useDiscordRpc } from '../hooks/useDiscordRpc'
import { DirList } from '../components/reusables/DirList'
import { SortableCategoryList } from '../components/reusables/SortableCategoryList'
import { ColorSwatchPicker } from '../components/ui/ColorSwatchPicker'
import { Slider } from '../components/ui/Slider'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { LanguageFlag } from '../components/reusables/LanguageFlag'
import { Dropdown } from '../components/ui/Dropdown'
import { Toggle } from '../components/ui/Toggle'
import { ThemePresetsModal } from '../components/modals/ThemePresetsModal'
import { RestoreProgressModal } from '../components/modals/RestoreProgressModal'
import { GitAuthModal } from '../components/modals/GitAuthModal'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { CreateWorkspaceModal } from '../components/modals/CreateWorkspaceModal'
import { WorkspaceEditModal } from '../components/modals/WorkspaceEditModal'
import { useWorkspaces } from '../hooks/useWorkspaces'
import { getWorkspaceIcon } from '../lib/workspaceIcons'
import { WorkspaceForm, workspaceNameError, type WorkspaceDraft } from '../components/ui/WorkspaceForm'
import { WelcomeIntro } from '../components/onboarding/WelcomeIntro'
import { MiniAppPreview } from '../components/onboarding/MiniAppPreview'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { useProjectsContext } from '../hooks/projectsContext'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { ease, gsap, motionOff } from '../lib/motion'
import { handOffShellIntro } from '../lib/uiTransition'
import {
  FeatureSetupPicker,
  featureLabel,
} from '../components/ui/FeatureSetupPicker'
import { CORE_FEATURES, FEATURES, isFeatureEnabled } from '../lib/features'
import {
  IconCheck,
  IconCopy,
  IconCloudArrowDown,
  IconDownload,
  IconFolderPlus,
  IconLayoutGrid,
  IconMonitor,
  IconMoon,
  IconPalette,
  IconPencil,
  IconPlus,
  IconRefresh,
  IconSun,
  IconChevronDown,
  IconChevronLeft,
  IconChevronRight,
  IconHouse,
  IconBriefcase,
  IconTags,
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
  wide = false,
  children,
}: {
  icon: React.ReactNode
  title: string
  description: string
  wide?: boolean
  children: React.ReactNode
}) {
  return (
    <div className={`flex flex-col gap-6 w-full ${wide ? 'max-w-3xl' : 'max-w-xl'}`}>
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
          <span className="font-mono text-2xs text-muted shrink-0">
            {progress.current} / {progress.total}
          </span>
        ) : running ? (
          <span className="flex items-center gap-1.5 text-xs text-accent-bright shrink-0">
            <IconRefresh className="w-3 h-3 animate-spin" />
            <span className="font-mono">…</span>
          </span>
        ) : (
          <span className="font-mono text-2xs text-muted shrink-0">
            {t('none')}
          </span>
        )}
      </div>
      <div className="h-1.5 w-full rounded-full bg-line/40 overflow-hidden">
        {hasProgress ? (
          <div
            className="h-full origin-left rtl:origin-right rounded-full bg-accent"
            style={{ width: `${pct}%` }}
          />
        ) : running ? (
          <div
            className="h-full rounded-full bg-accent/60"


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
      <span className="font-mono text-xs text-ink text-end min-w-0 truncate">
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
      <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70 px-1">
        {title}
      </span>
      <div className="flex flex-col gap-1.5">{children}</div>
    </div>
  )
}

interface DiscoveryRow {
  key: string
  primary: string
  secondary?: string
  badges?: string[]
}

function DiscoveryList({
  heading,
  rows,
  selected,
  imported,
  busy,
  onToggle,
  onAdd,
  addLabel,
  loading = false,
  loadingLabel,
  hint,
}: {
  heading: string
  rows: DiscoveryRow[]
  selected: Set<string>
  imported: Set<string>
  busy: boolean
  onToggle: (key: string) => void
  onAdd: () => void
  addLabel: (count: number) => string
  loading?: boolean
  loadingLabel?: string
  hint?: string
}) {
  if (loading && rows.length === 0) {
    return (
      <div className="flex flex-col gap-1.5">
        <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70">
          {heading}
        </span>
        <div className="flex items-center gap-2 px-2.5 py-2 rounded-item border border-dashed border-line/60 text-2xs text-muted">
          <IconRefresh className="w-3 h-3 animate-spin shrink-0" />
          {loadingLabel}
        </div>
      </div>
    )
  }
  if (rows.length === 0) return null
  const selectableCount = rows.filter(
    (r) => selected.has(r.key) && !imported.has(r.key),
  ).length
  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70">
        {heading}
      </span>
      <div className="flex flex-col gap-1 max-h-56 overflow-y-auto">
        {rows.map((r) => {
          const isImported = imported.has(r.key)
          return (
            <label
              key={r.key}
              className={`flex items-center gap-2.5 px-2.5 py-1.5 rounded-item border border-line/60 bg-base/40 ${
                isImported ? 'opacity-60' : 'hover:bg-raised/40 cursor-pointer'
              }`}
            >
              <input
                type="checkbox"
                disabled={isImported}
                checked={isImported || selected.has(r.key)}
                onChange={() => onToggle(r.key)}
                className="accent-accent shrink-0"
              />
              <div className="flex-1 min-w-0">
                <p className="text-xs text-ink truncate">{r.primary}</p>
                {r.secondary && (
                  <p className="text-3xs font-mono text-muted/60 truncate">
                    {r.secondary}
                  </p>
                )}
              </div>
              {r.badges?.map((badge) => (
                <span
                  key={badge}
                  className="shrink-0 text-4xs font-semibold px-1.5 py-0.5 rounded bg-overlay border border-outline/50 text-muted"
                >
                  {badge}
                </span>
              ))}
              {isImported && (
                <IconCheck className="w-3.5 h-3.5 text-accent shrink-0" />
              )}
            </label>
          )
        })}
      </div>
      <button
        type="button"
        onClick={onAdd}
        disabled={busy || selectableCount === 0}
        className="focus-ring cursor-pointer self-start inline-flex items-center gap-1.5 px-3 py-1.5 rounded-btn bg-accent hover:bg-accent-bright text-white text-2xs font-medium disabled:opacity-40 disabled:cursor-not-allowed"
      >
        {busy ? (
          <IconRefresh className="w-3 h-3 animate-spin" />
        ) : (
          <IconPlus className="w-3 h-3" />
        )}
        {addLabel(selectableCount)}
      </button>
      {hint && (
        <p className="text-3xs text-muted/70 leading-relaxed">{hint}</p>
      )}
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
  const [celebrating, setCelebrating] = useState(false)
  const shellRef = useRef<HTMLDivElement>(null)
  const previewRef = useRef<HTMLDivElement>(null)
  const liftedRef = useRef<LiftedPreview | null>(null)
  const { projects, refresh: refreshProjects } = useProjectsContext()
  const { installed, refreshInstalled } = useGodotVersionsContext()
  const { workspaces, activeId } = useWorkspaces()
  const currentWorkspace = workspaces.find((w) => w.id === activeId) ?? null
  const [intro, setIntro] = useState(() => workspaces.length <= 1)

  const celebrate = async () => {
    await Promise.all([refreshProjects(), refreshInstalled()]).catch(() => {})
    setCelebrating(true)
    if (motionOff()) return
    await new Promise((resolve) => window.setTimeout(resolve, CELEBRATION_HOLD_MS))
    liftedRef.current = await liftPreview(previewRef.current, shellRef.current)
    if (liftedRef.current) handOffShellIntro()
  }

  const morph = () => morphIntoApp(liftedRef.current)

  const revealShell = () => {
    const shell = shellRef.current
    if (!shell || motionOff()) return
    gsap.from(shell.children, {
      opacity: 0,
      y: 24,
      scale: 0.985,
      duration: 0.7,
      stagger: 0.08,
      ease: ease.out,
      clearProps: 'opacity,transform',
    })
  }

  // Discovery: recent projects from Godot's project manager + detected installs.
  const [recentProjects, setRecentProjects] = useState<DiscoveredProject[]>([])
  const [detectedInstalls, setDetectedInstalls] = useState<DiscoveredInstall[]>([])
  const [selectedProjects, setSelectedProjects] = useState<Set<string>>(new Set())
  const [selectedInstalls, setSelectedInstalls] = useState<Set<string>>(new Set())
  const [importedProjects, setImportedProjects] = useState<Set<string>>(new Set())
  const [importedInstalls, setImportedInstalls] = useState<Set<string>>(new Set())
  const [importingProjects, setImportingProjects] = useState(false)
  const [importingInstalls, setImportingInstalls] = useState(false)
  const [discoveringProjects, setDiscoveringProjects] = useState(true)
  const [discoveringInstalls, setDiscoveringInstalls] = useState(true)

  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent('app:view-changed', { detail: 'onboarding' }),
    )
  }, [])

  useEffect(() => {
    let cancelled = false
    api
      .scanGodotRecentProjects()
      .then((list) => {
        if (cancelled) return
        setRecentProjects(list)
        setSelectedProjects(new Set(list.map((p) => p.path)))
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setDiscoveringProjects(false)
      })
    api
      .detectGodotInstalls()
      .then((list) => {
        if (cancelled) return
        setDetectedInstalls(list)
        setSelectedInstalls(new Set(list.map((i) => i.path)))
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setDiscoveringInstalls(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  const toggleIn = (
    setter: Dispatch<SetStateAction<Set<string>>>,
    key: string,
  ) => {
    setter((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  const importSelectedProjects = async () => {
    const targets = recentProjects.filter(
      (p) => selectedProjects.has(p.path) && !importedProjects.has(p.path),
    )
    if (targets.length === 0) return
    setImportingProjects(true)
    let added = 0
    for (const p of targets) {
      try {
        await api.importProject(p.path, '', null)
        setImportedProjects((prev) => new Set(prev).add(p.path))
        added++
      } catch (e) {
        pushToast('error', `${p.name}: ${String(e)}`)
      }
    }
    setImportingProjects(false)
    void refreshProjects()
    if (added > 0) {
      pushToast('success', t('discovery_added_projects', { count: added }))
    }
  }

  const importSelectedInstalls = async () => {
    const targets = detectedInstalls.filter(
      (i) => selectedInstalls.has(i.path) && !importedInstalls.has(i.path),
    )
    if (targets.length === 0) return
    setImportingInstalls(true)
    let added = 0
    for (const inst of targets) {
      try {
        await api.importDetectedInstall(inst.path)
        setImportedInstalls((prev) => new Set(prev).add(inst.path))
        added++
      } catch (e) {
        pushToast('error', `${inst.name}: ${String(e)}`)
      }
    }
    setImportingInstalls(false)
    void refreshInstalled()
    if (added > 0) {
      pushToast('success', t('discovery_added_versions', { count: added }))
    }
  }

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
    addCustomCategory,
    categoryLabels,
  } = useOnboarding({ settings, onComplete })

  useDiscordRpc(draft, [])

  const sidebarPreview = [
    ...CORE_FEATURES,
    ...FEATURES.filter((f) => !f.flag && isFeatureEnabled(draft, f.id)),
  ]

  return (
    <div className="new-ui h-screen w-screen flex flex-col bg-base text-ink font-body select-none">
      <Titlebar minimal />

      {intro && <WelcomeIntro onLeave={revealShell} onDone={() => setIntro(false)} />}

      <div ref={shellRef} className="flex-1 min-h-0 flex gap-4 p-4 pt-2">
        <aside className="shrink-0 w-60 flex flex-col rounded-card bg-raised overflow-hidden">
          <div className="shrink-0 flex items-center gap-2 px-5 h-14">
            <span data-onboarding-wordmark className="font-display font-black text-xl tracking-tight text-ink">
              GodotHub
            </span>
            <span className="ms-auto text-4xs font-semibold uppercase tracking-wide px-2 py-0.5 rounded-tag bg-accent/15 text-accent-bright">
              {t('setup')}
            </span>
          </div>

          <OverlayScrollArea
            className="flex-1 min-h-0"
            hideThumb={!settings.show_scrollbars}
            hideTopButton
          >
            <nav className="p-3 pt-1 flex flex-col gap-0.5" aria-label={t('setup')}>
              {STEPS.map((s, i) => {
                const active = i === stepIndex
                const done = i < stepIndex
                return (
                  <button
                    key={s.id}
                    type="button"
                    onClick={() => jumpTo(i)}
                    disabled={finishing}
                    aria-current={active ? 'step' : undefined}
                    className={`focus-ring cursor-pointer flex items-center gap-2.5 px-3 py-2 rounded-item border text-sm font-medium disabled:cursor-default ${
                      active
                        ? 'bg-overlay border-outline/50 text-ink shadow-md shadow-black/10'
                        : done
                          ? 'border-transparent text-ink/80 hover:bg-overlay/60'
                          : 'border-transparent text-muted hover:text-ink hover:bg-overlay/60'
                    }`}
                  >
                    <span
                      className={`w-6 h-6 shrink-0 flex items-center justify-center rounded-tag text-3xs font-bold tabular-nums ${
                        done
                          ? 'bg-accent text-white'
                          : active
                            ? 'bg-accent/15 text-accent-bright'
                            : 'bg-overlay text-muted'
                      }`}
                    >
                      {done ? <IconCheck className="w-3 h-3" /> : i + 1}
                    </span>
                    <span className="min-w-0 truncate">{stepLabel(s.id)}</span>
                  </button>
                )
              })}
            </nav>
          </OverlayScrollArea>

          <MiniAppPreview
            ref={previewRef}
            settings={draft}
            workspace={currentWorkspace}
            projects={projects}
            versionCount={installed.length}
          />
        </aside>

        <div className="flex-1 min-w-0 flex flex-col gap-4">
          <ViewHeader
            title={stepLabel(step.id)}
            metric={
              <span className="text-xs font-medium text-muted tabular-nums">
                {t('step_of', { current: stepIndex + 1, total: STEPS.length })}
              </span>
            }
          >
            <div className="flex gap-1" aria-hidden="true">
              {STEPS.map((s, i) => (
                <span
                  key={s.id}
                  className={`h-1 flex-1 rounded-full ${
                    i < stepIndex
                      ? 'bg-accent'
                      : i === stepIndex
                        ? 'bg-accent-bright'
                        : 'bg-line/50'
                  }`}
                />
              ))}
            </div>
          </ViewHeader>

        <main className="flex-1 min-h-0 flex flex-col rounded-card bg-raised overflow-hidden">
          <div className="flex-1 min-h-0 flex flex-col">
            <OverlayScrollArea
              className="flex-1 min-w-0"
              hideThumb={!settings.show_scrollbars}
              hideTopButton
            >
              <div className="min-h-full px-6 py-6 sm:px-10 sm:py-8">
                  <div
                    key={step.id}
                    className="w-full flex flex-col items-center"
                  >
                    {step.id === 'workspace' && (
                      <StepShell
                        icon={<IconBriefcase className="w-5 h-5" />}
                        title={t('first_workspace_title')}
                        description={t('first_workspace_desc')}
                      >
                        <OnboardingFirstWorkspace />
                      </StepShell>
                    )}

                    {step.id === 'welcome' && (
                      <StepShell
                        icon={<IconHouse className="w-5 h-5" />}
                        title={t('basics_title')}
                        description={t('basics_desc')}
                      >
                        <div className="flex flex-col gap-6">
                          <div className="flex flex-col gap-2.5">
                            <span className="text-xs font-semibold uppercase tracking-wide text-muted">
                              {t('language_label')}
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
                                    className="focus-ring cursor-pointer inline-flex items-center gap-2 px-3.5 py-2 rounded-btn border border-outline/50 bg-overlay text-sm font-medium text-ink hover:border-accent-dim "
                                  >
                                    {current && <LanguageFlag country={current.country} />}
                                    {current
                                      ? current.labelKey
                                        ? i18n.t(`settings:${current.labelKey}`)
                                        : current.label
                                      : i18n.language}
                                    <IconChevronDown className={`w-3 h-3 text-muted  ${open ? 'rotate-180' : ''}`} />
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
                              <p className="text-2xs text-muted mt-0.5 leading-relaxed">
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

                        </div>
                      </StepShell>
                    )}

                    {step.id === 'setup' && (
                      <StepShell
                        wide
                        icon={<IconLayoutGrid className="w-5 h-5" />}
                        title={t('setup_title')}
                        description={t('setup_desc')}
                      >
                        <FeatureSetupPicker value={draft} onChange={setDraft} />
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
                          <DiscoveryList
                            heading={t('discovery_recent_heading')}
                            loading={discoveringProjects}
                            loadingLabel={t('discovery_scanning_projects')}
                            hint={t('discovery_link_hint')}
                            rows={recentProjects.map((p) => ({
                              key: p.path,
                              primary: p.name,
                              secondary: p.path,
                              badges: [
                                ...(p.engine ? [t('discovery_engine', { version: p.engine })] : []),
                                ...(p.favorite ? [t('discovery_favorite')] : []),
                              ],
                            }))}
                            selected={selectedProjects}
                            imported={importedProjects}
                            busy={importingProjects}
                            onToggle={(k) => toggleIn(setSelectedProjects, k)}
                            onAdd={importSelectedProjects}
                            addLabel={(n) =>
                              n > 0 ? t('discovery_add_selected_count', { count: n }) : t('discovery_add_selected')
                            }
                          />
                          {projectSuggestions.length > 0 && (
                            <div className="flex flex-col gap-1.5">
                              <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70">
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
                                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-tag border text-2xs font-mono disabled:cursor-default ${
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
                                      <span className="shrink-0 text-3xs text-muted">
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
                          <DiscoveryList
                            heading={t('discovery_installs_heading')}
                            loading={discoveringInstalls}
                            loadingLabel={t('discovery_scanning_installs')}
                            rows={detectedInstalls.map((i) => ({
                              key: i.path,
                              primary: i.version
                                ? t('discovery_engine', { version: i.version })
                                : i.name,
                              secondary: i.path,
                              badges: [i.source],
                            }))}
                            selected={selectedInstalls}
                            imported={importedInstalls}
                            busy={importingInstalls}
                            onToggle={(k) => toggleIn(setSelectedInstalls, k)}
                            onAdd={importSelectedInstalls}
                            addLabel={(n) =>
                              n > 0 ? t('discovery_add_selected_count', { count: n }) : t('discovery_add_selected')
                            }
                          />
                          {versionSuggestions.length > 0 && (
                            <div className="flex flex-col gap-1.5">
                              <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70">
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
                                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-tag border text-2xs font-mono disabled:cursor-default ${
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
                                      <span className="shrink-0 text-3xs text-muted">
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
                          <DirList
                            single
                            dirs={draft.template_scan_dir ? [draft.template_scan_dir] : []}
                            onChange={(dirs) =>
                              setField('template_scan_dir', dirs[0] ?? null)
                            }
                            emptyHint={t('onboard_no_template_folder')}
                          />

                          {pendingTemplateSuggestions.length > 0 && (
                            <div className="flex flex-col gap-1.5">
                              <span className="text-3xs font-semibold uppercase tracking-wide text-muted/70">
                                {tc('suggested_from_workspaces')}
                              </span>
                              {pendingTemplateSuggestions.map((s) => (
                                <button
                                  key={s.path}
                                  type="button"
                                  onClick={() =>
                                    setField('template_scan_dir', s.path)
                                  }
                                  className="focus-ring cursor-pointer flex items-center gap-2 px-3 py-2 rounded-item border border-dashed border-outline/60 text-start hover:border-accent-dim hover:bg-overlay/60 "
                                >
                                  <span className="shrink-0 flex items-center justify-center w-4 h-4 rounded-tag bg-accent/15 text-accent-bright">
                                    <IconCopy className="w-3 h-3" />
                                  </span>
                                  <span className="text-2xs font-mono text-ink truncate">
                                    {s.path}
                                  </span>
                                  <span className="shrink-0 text-3xs text-muted truncate max-w-32">
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
                              const color =
                                STARTER_CATEGORY_COLORS[name] ?? CATEGORY_COLORS[0]
                              return (
                                <button
                                  key={name}


                                  disabled={added || categoryBusy}
                                  onClick={() => addStarterCategory(name)}
                                  className={`focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-btn border text-xs font-medium disabled:cursor-default ${
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
                                  <span
                                    className="w-2 h-2 rounded-full shrink-0 border border-black/20"
                                    style={{ backgroundColor: color }}
                                  />
                                  {categoryLabels[name] || name}
                                </button>
                              )
                            })}
                          </div>

                          <div className="flex flex-col gap-3">
                            <div className="flex gap-2.5">
                              <input
                                value={categoryDraft}
                                onChange={(e) => setCategoryDraft(e.target.value)}
                                onKeyDown={(e) =>
                                  e.key === 'Enter' && addCustomCategory()
                                }
                                placeholder={t('onboarding_custom_category_placeholder', { ns: 'common' })}
                                className="focus-ring flex-1 bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm focus:border-accent-dim outline-none "
                              />
                              <button


                                onClick={addCustomCategory}
                                disabled={categoryBusy || !categoryDraft.trim()}
                                className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium text-white "
                              >
                                <IconPlus className="w-3.5 h-3.5" />
                                {tc('add')}
                              </button>
                            </div>
                            <ColorSwatchPicker
                              label={tc('color_label')}
                              value={categoryColor}
                              onChange={setCategoryColor}
                              presets={CATEGORY_COLORS}
                            />
                          </div>

                          {categories.length > 0 && (
                            <div className="flex flex-col gap-2">
                              <span className="text-2xs font-medium text-muted uppercase tracking-wide">
                                {t('onboarding_your_categories', { ns: 'common' })}
                              </span>
                              <SortableCategoryList
                                categories={categories}
                                onUpdate={updateCategory}
                                onDelete={removeCategory}
                                onReorder={reorderCategories}
                                onAssignFolder={assignCategoryFolder}
                                onUnassignFolder={unassignCategoryFolder}
                                onError={(message) => {
                                  if (message) pushToast('error', message)
                                }}
                              />
                            </div>
                          )}
                        </div>
                      </StepShell>
                    )}

                    {step.id === 'workspaces' && (
                      <StepShell
                        icon={<IconLayoutGrid className="w-5 h-5" />}
                        title={t('workspaces_title')}
                        description={t('workspaces_desc')}
                      >
                        <OnboardingWorkspaces />
                      </StepShell>
                    )}

                    {step.id === 'appearance' && (
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
                                  className="focus-ring cursor-pointer flex items-center gap-3 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-overlay px-4 py-3.5 "
                                >
                                  <Icon className="w-4 h-4 text-muted shrink-0" />
                                  <span className="text-xs font-medium text-ink">
                                    {label}
                                  </span>
                                  <span className="text-3xs font-medium text-muted/60">
                                    {presets.length}
                                  </span>
                                  <IconChevronRight className="rtl:rotate-180 w-3.5 h-3.5 text-muted ms-auto" />
                                </button>
                              ))}

                              <button
                                type="button"
                                onClick={() => selectPreset('custom')}
                                className={`focus-ring cursor-pointer flex items-center gap-3 rounded-btn border px-4 py-3.5  ${
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
                                  <IconCheck className="w-3.5 h-3.5 text-accent-bright ms-auto" />
                                )}
                              </button>
                            </div>
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
                                  { mode: 'dark' as const, label: ts('theme_dark'), Icon: IconMoon },
                                  { mode: 'light' as const, label: ts('theme_light'), Icon: IconSun },
                                  { mode: 'system' as const, label: ts('system'), Icon: IconMonitor },
                                ]).map(({ mode, label, Icon }) => {
                                  const active = draft.theme_mode === mode
                                  return (
                                    <button
                                      key={mode}
                                      type="button"
                                      onClick={() => setThemeMode(mode)}
                                      className={`focus-ring cursor-pointer flex items-center gap-2 px-3.5 py-1.5 rounded-btn text-sm font-medium  ${
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
                              max={15}
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

                    {step.id === 'finish' && celebrating && (
                      <StepShell
                        icon={<IconCheck className="w-5 h-5" />}
                        title={t('found_title')}
                        description={t('found_desc')}
                      >
                        <FinishCelebration projects={projects} versionCount={installed.length} />
                      </StepShell>
                    )}

                    {step.id === 'finish' && !celebrating && (
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
                            {draft.template_scan_dir && isFeatureEnabled(draft, 'templates') && (
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

                            <SummarySection title={t('setup')}>
                              <SummaryRow
                                label={t('preview_heading')}
                                value={sidebarPreview.map(({ id }) => featureLabel(ts, id)).join(', ')}
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
                                label={ts('onboarding_corner_radius')}
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
                              {isFeatureEnabled(draft, 'templates') && (
                                <SummaryRow
                                  label={tc('section_templates')}
                                  value={
                                    draft.template_scan_dir || tc('none')
                                  }
                                />
                              )}
                            </SummarySection>

                          </div>
                        )}
                      </StepShell>
                    )}
                  </div>

              </div>
            </OverlayScrollArea>
          </div>

          <div className="shrink-0 px-6 py-4 border-t border-line flex items-center justify-between gap-4">
            <button
              type="button"
              onClick={() => (stepIndex === 0 ? finish(true) : goBack())}
              disabled={finishing}
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-4 py-2.5 rounded-item text-sm text-muted hover:text-ink hover:bg-overlay disabled:opacity-50"
            >
              {stepIndex === 0 ? (
                tc('skip_setup')
              ) : (
                <>
                  <IconChevronLeft className="rtl:rotate-180 w-3.5 h-3.5" />
                  {tc('back')}
                </>
              )}
            </button>

            {step.id === 'finish' ? (
              <button
                type="button"
                onClick={() => finish(false, celebrate, morph)}
                disabled={finishing}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-6 py-2.5 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-60 text-sm font-medium text-white "
              >
                {finishing ? tc('finishing') : tc('get_started')}
              </button>
            ) : (
              <button
                type="button"
                onClick={goNext}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-6 py-2.5 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white "
              >
                {t('onboarding_continue', { ns: 'common' })}
                <IconChevronRight className="rtl:rotate-180 w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </main>
        </div>
      </div>


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

    </div>
  )
}

const CELEBRATION_HOLD_MS = 2400
const MAX_CELEBRATION_TILES = 12

interface LiftedPreview {
  clone: HTMLElement
  cover: HTMLElement
}

function liftPreview(preview: HTMLElement | null, shell: HTMLElement | null) {
  return new Promise<LiftedPreview | null>((resolve) => {
    if (!preview) {
      resolve(null)
      return
    }
    const r = preview.getBoundingClientRect()
    const clone = preview.cloneNode(true) as HTMLElement
    clone.querySelectorAll('.dash-rise').forEach((n) => n.classList.remove('dash-rise'))
    clone.setAttribute('data-motion-skip', '')
    Object.assign(clone.style, {
      position: 'fixed',
      left: `${r.left}px`,
      top: `${r.top}px`,
      width: `${r.width}px`,
      height: `${r.height}px`,
      margin: '0',
      zIndex: '200',
      pointerEvents: 'none',
    })
    const cover = document.createElement('div')
    cover.setAttribute('data-motion-skip', '')
    cover.className = 'bg-base'
    Object.assign(cover.style, { position: 'fixed', inset: '0', zIndex: '199', pointerEvents: 'none', opacity: '0' })
    document.body.append(cover, clone)
    preview.style.visibility = 'hidden'
    const tl = gsap.timeline({ onComplete: () => resolve({ clone, cover }) })
    tl.to(cover, { opacity: 1, duration: 0.4, ease: ease.in }, 0)
    if (shell) tl.to(shell, { opacity: 0, duration: 0.4, ease: ease.in }, 0)
    tl.to(clone, { scale: 1.06, duration: 0.4, ease: ease.soft }, 0)
  })
}

function restingRect(el: HTMLElement) {
  const moved: [HTMLElement, string][] = []
  for (let node: HTMLElement | null = el; node && node !== document.body; node = node.parentElement) {
    if (getComputedStyle(node).transform !== 'none') {
      moved.push([node, node.style.transform])
      node.style.transform = 'none'
    }
  }
  const rect = el.getBoundingClientRect()
  for (const [node, transform] of moved) node.style.transform = transform
  return rect
}

function waitForElements<T>(find: () => T | null, frames = 90) {
  return new Promise<T | null>((resolve) => {
    let left = frames
    const check = () => {
      const found = find()
      if (found || left-- <= 0) resolve(found)
      else window.setTimeout(check, 16)
    }
    check()
  })
}

async function morphIntoApp(lifted: LiftedPreview | null) {
  if (!lifted) return
  const { clone, cover } = lifted
  const cleanup = () => {
    clone.remove()
    cover.remove()
  }
  const target = await waitForElements(() => {
    const sidebar = document.querySelector<HTMLElement>('[data-app-sidebar]')
    const main = document.querySelector<HTMLElement>('[data-app-main]')
    return sidebar && main ? { sidebar, main } : null
  })
  const [miniSidebar, miniMain] = Array.from(clone.children) as HTMLElement[]
  if (!target || !miniSidebar || !miniMain) {
    gsap.to([clone, cover], { opacity: 0, duration: 0.4, ease: 'power2.out', onComplete: cleanup })
    return
  }

  gsap.set(clone, { scale: 1, borderWidth: 0 })
  const origin = clone.getBoundingClientRect()
  for (const piece of [miniSidebar, miniMain]) {
    const r = piece.getBoundingClientRect()
    Object.assign(piece.style, {
      position: 'absolute',
      left: `${r.left - origin.left}px`,
      top: `${r.top - origin.top}px`,
      width: `${r.width}px`,
      height: `${r.height}px`,
      margin: '0',
    })
  }

  const sidebarRect = restingRect(target.sidebar)
  const mainRect = restingRect(target.main)
  const sidebarRadius = getComputedStyle(target.sidebar).borderTopLeftRadius
  const box = (r: DOMRect) => ({ left: r.left, top: r.top, width: r.width, height: r.height })

  const tl = gsap.timeline({ onComplete: cleanup })
  tl.to([...Array.from(miniSidebar.children), ...Array.from(miniMain.children)], {
    opacity: 0,
    duration: 0.2,
    ease: 'power2.out',
  }, 0)
  tl.to(clone, {
    left: 0,
    top: 0,
    width: window.innerWidth,
    height: window.innerHeight,
    borderRadius: 0,
    padding: 0,
    duration: 0.85,
    ease: 'power3.inOut',
  }, 0)
  tl.to(miniSidebar, { ...box(sidebarRect), borderRadius: sidebarRadius, duration: 0.85, ease: 'power3.inOut' }, 0)
  tl.to(miniMain, { ...box(mainRect), duration: 0.85, ease: 'power3.inOut' }, 0)
  tl.to([clone, cover], { opacity: 0, duration: 0.4, ease: 'power2.out' }, 0.8)
}

function FinishCelebration({ projects, versionCount }: { projects: Project[]; versionCount: number }) {
  const { t: tc } = useTranslation('common')
  const gridRef = useRef<HTMLDivElement>(null)
  const [counts, setCounts] = useState({ projects: 0, versions: 0 })

  useEffect(() => {
    const id = window.setTimeout(() => setCounts({ projects: projects.length, versions: versionCount }), 120)
    return () => window.clearTimeout(id)
  }, [projects.length, versionCount])

  useLayoutEffect(() => {
    const grid = gridRef.current
    if (!grid || motionOff()) return
    const tween = gsap.from(grid.children, {
      y: -36,
      opacity: 0,
      rotation: () => gsap.utils.random(-12, 12),
      duration: 0.7,
      stagger: 0.06,
      delay: 0.25,
      ease: ease.spring,
      clearProps: 'all',
    })
    return () => {
      tween.revert()
    }
  }, [])

  const stats = [
    { key: 'projects', label: tc('section_projects'), value: counts.projects },
    { key: 'versions', label: tc('section_versions'), value: counts.versions },
  ]

  return (
    <div className="flex flex-col gap-5 w-full">
      <div className="grid grid-cols-2 gap-3">
        {stats.map((stat) => (
          <div key={stat.key} className="flex flex-col gap-1 px-5 py-4 rounded-item bg-base/40 border border-outline/50">
            <span className="font-display font-bold text-4xl tracking-tight text-ink tabular-nums">
              <AnimatedNumber value={stat.value} />
            </span>
            <span className="text-xs font-medium text-muted">{stat.label}</span>
          </div>
        ))}
      </div>
      {projects.length > 0 && (
        <div ref={gridRef} className="grid grid-cols-4 gap-2">
          {projects.slice(0, MAX_CELEBRATION_TILES).map((p) => (
            <div
              key={p.id}
              className="flex items-center gap-2 px-2.5 py-2 rounded-item bg-base/40 border border-outline/50 min-w-0"
            >
              <span className="w-6 h-6 shrink-0 rounded-tag bg-accent/15 text-accent-bright flex items-center justify-center text-3xs font-bold">
                {p.name.trim().charAt(0).toUpperCase() || '?'}
              </span>
              <span className="min-w-0 truncate text-2xs text-ink">{p.name}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function OnboardingFirstWorkspace() {
  const { t } = useTranslation('common')
  const { workspaces, activeId, renameWorkspace, updateWorkspaceStyle } = useWorkspaces()
  const current = workspaces.find((w) => w.id === activeId) ?? null
  const [draft, setDraft] = useState<WorkspaceDraft | null>(current)
  const [synced, setSynced] = useState(current?.id ?? null)
  if (current && synced !== current.id) {
    setSynced(current.id)
    setDraft(current)
  }

  if (!current || !draft) return null
  const takenNames = workspaces.filter((w) => w.id !== current.id).map((w) => w.name)

  const commitName = () => {
    const trimmed = draft.name.trim()
    if (workspaceNameError(trimmed, takenNames, t) || trimmed === current.name) return
    renameWorkspace(current.id, trimmed).catch((e) => pushToast('error', String(e)))
  }

  const change = (next: WorkspaceDraft) => {
    setDraft(next)
    if (next.icon !== current.icon || next.color !== current.color) {
      updateWorkspaceStyle(current.id, next.icon, next.color).catch((e) => pushToast('error', String(e)))
    }
  }

  return (
    <WorkspaceForm
      value={draft}
      onChange={change}
      takenNames={takenNames}
      showErrors
      onSubmit={commitName}
      onNameBlur={commitName}
    />
  )
}

function OnboardingWorkspaces() {
  const { t } = useTranslation('common')
  const {
    workspaces,
    activeId,
    addWorkspace,
    renameWorkspace,
    updateWorkspaceStyle,
    deleteWorkspace,
  } = useWorkspaces()
  const [added, setAdded] = useState<Set<string>>(new Set())
  const [creating, setCreating] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const editing = workspaces.find((w) => w.id === editingId) ?? null

  return (
    <div className="flex flex-col gap-1.5 w-full">
      {workspaces.map((ws) => {
        const Icon = getWorkspaceIcon(ws.icon)
        return (
          <button
            key={ws.id}
            type="button"
            onClick={() => setEditingId(ws.id)}
            aria-label={`${t('edit_workspace_title')}: ${ws.name}`}
            className="focus-ring cursor-pointer group flex items-center gap-3 px-3 py-2.5 rounded-item border border-outline/50 bg-base/40 text-start hover:border-accent-dim hover:bg-overlay/60"
          >
            <span
              className="w-9 h-9 shrink-0 rounded-full border-2 flex items-center justify-center"
              style={{ backgroundColor: `${ws.color}26`, borderColor: ws.color }}
            >
              <Icon className="w-4 h-4" style={{ color: ws.color }} />
            </span>
            <span className="flex-1 min-w-0 text-sm font-medium text-ink truncate">
              {ws.name}
            </span>
            {ws.id === activeId && (
              <span className="shrink-0 text-4xs font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-tag bg-accent/15 text-accent-bright">
                {t('current_workspace')}
              </span>
            )}
            <IconPencil className="w-3.5 h-3.5 shrink-0 text-muted opacity-0 group-hover:opacity-100" />
          </button>
        )
      })}

      <button
        type="button"
        onClick={() => setCreating(true)}
        className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 px-3.5 py-2.5 rounded-item border border-dashed border-outline/60 text-xs text-muted hover:text-accent-bright hover:border-accent-dim hover:bg-overlay/40"
      >
        <IconPlus className="w-3.5 h-3.5" />
        {t('create_workspace')}
      </button>

      {creating && (
        <CreateWorkspaceModal
          takenNames={workspaces.map((w) => w.name)}
          onClose={() => setCreating(false)}
          onCreate={async ({ name, icon, color }) => {
            const id = await addWorkspace(name, icon, color)
            if (id) setAdded((prev) => new Set(prev).add(id))
            setCreating(false)
          }}
        />
      )}

      {editing && (
        <WorkspaceEditModal
          workspace={editing}
          takenNames={workspaces.filter((w) => w.id !== editing.id).map((w) => w.name)}
          canDelete={added.has(editing.id) && editing.id !== activeId}
          onClose={() => setEditingId(null)}
          onSave={async (name, icon, color) => {
            await Promise.all([
              name.trim() !== editing.name ? renameWorkspace(editing.id, name) : null,
              icon !== editing.icon || color !== editing.color
                ? updateWorkspaceStyle(editing.id, icon, color)
                : null,
            ])
            setEditingId(null)
          }}
          onDelete={async () => {
            await deleteWorkspace(editing.id)
            setEditingId(null)
          }}
        />
      )}
    </div>
  )
}

function OnboardingCloudBackup() {
  const { t } = useTranslation('onboarding')
  const { t: ts } = useTranslation('settings')
  const [gitUser, setGitUser] = useState<string | null>(null)

  const [showRestoreModal, setShowRestoreModal] = useState(false)
  const [showGitAuth, setShowGitAuth] = useState(false)

  useEffect(() => {
    api.gitAuthGetState().then((s) => {
      if (s.github) setGitUser(s.github.username)
    })
  }, [])

  const handleConnected = (username: string) => {
    setGitUser(username)
    setShowGitAuth(false)
  }

  return (
    <div className="flex flex-col gap-2.5">
      <span className="text-xs font-semibold uppercase tracking-wide text-muted">
        {t('onboard_cloud_heading')}
      </span>
      <div className="rounded-item bg-overlay border border-outline/50 p-4 flex flex-col gap-3">
        <p className="text-2xs text-muted leading-relaxed">
          {t('onboard_cloud_desc')}
        </p>
        {!gitUser ? (
          <button
            type="button"
            onClick={() => setShowGitAuth(true)}
            className="focus-ring cursor-pointer self-start inline-flex items-center gap-2 px-4 py-2 rounded-btn bg-overlay border border-outline/50 hover:border-accent-dim hover:bg-raised text-xs font-medium "
          >
            {t('git_sign_in_github')}
          </button>
        ) : (
          <div className="flex flex-col gap-3">
            <p className="text-xs text-green flex items-center gap-1.5">
              <IconCheck className="w-3.5 h-3.5" />
              {t('git_connected_as', { username: gitUser })}
            </p>

            <button
              type="button"
              onClick={() => setShowRestoreModal(true)}
              className="focus-ring cursor-pointer self-start inline-flex items-center gap-2 px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright text-xs font-medium text-white "
            >
              <IconCloudArrowDown className="w-3.5 h-3.5" />
              {ts('sync_pull_btn')}
            </button>
            <p className="text-2xs text-muted leading-relaxed">
              {ts('sync_manual_hint')}
            </p>
          </div>
        )}

      </div>


        {showRestoreModal && (
          <RestoreProgressModal onClose={() => setShowRestoreModal(false)} />
        )}



        {showGitAuth && (
          <GitAuthModal
            provider="github"
            onClose={() => setShowGitAuth(false)}
            onConnected={handleConnected}
          />
        )}

    </div>
  )
}
