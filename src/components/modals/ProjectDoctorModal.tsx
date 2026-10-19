import { useCallback, useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { api } from '../../lib/api'
import { formatBytes } from '../../lib/formatBytes'
import { pushToast } from '../../lib/toast'
import { setTemplateFilesInstalled } from '../../lib/exportTemplateCatalog'
import { useTauriEvent } from '../../lib/useTauriEvent'
import type { InstalledGodotVersion, Project, ProjectHealthCheck, ProjectHealthReport } from '../../types'
import { IconBug, IconCheckCircle, IconChevronDown, IconInfo, IconRefresh, IconSpinner, IconAlertTriangle, IconX } from '../../lib/icons'
import { Dropdown } from '../ui/Dropdown'
import { ModalShell } from './ModalShell'
import { ConfirmDialog } from './ConfirmDialog'
import { ExportTemplatesModal } from './ExportTemplatesModal'
import { TemplateDisclosure, TemplateDisclosureChevron } from './TemplateDisclosure'

interface Props {
  project: Project
  installedVersions: InstalledGodotVersion[]
  onClose: () => void
}

const categories = ['engine', 'templates', 'cache', 'scenes', 'addons', 'git', 'exports', 'registrations']
const rank = { error: 0, warning: 1, info: 2, ok: 3 }
const actionButton = 'focus-ring cursor-pointer inline-flex shrink-0 items-center justify-center gap-2 rounded-btn border border-line bg-raised px-3 py-2 text-xs font-medium text-ink hover:border-accent-dim hover:bg-overlay transition-colors disabled:opacity-40 disabled:cursor-not-allowed'

export function ProjectDoctorModal({ project, installedVersions, onClose }: Props) {
  const { t } = useTranslation('doctor')
  const { t: tc } = useTranslation('common')
  const [report, setReport] = useState<ProjectHealthReport | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState<string | null>(null)
  const [confirm, setConfirm] = useState<ProjectHealthCheck | null>(null)
  const [templatesOpen, setTemplatesOpen] = useState(false)
  const [showPassed, setShowPassed] = useState(false)
  const [animatePassed, setAnimatePassed] = useState(false)
  const [queuedVersion, setQueuedVersion] = useState(false)
  const dialogContent = useRef<HTMLDivElement>(null)
  const refreshButton = useRef<HTMLButtonElement>(null)
  const confirmTrigger = useRef<HTMLButtonElement | null>(null)
  const scanSequence = useRef(0)
  const mutationPending = useRef(false)
  const mounted = useRef(true)

  const scan = useCallback(async () => {
    if (!mounted.current) return
    const sequence = ++scanSequence.current
    setLoading(true); setError('')
    try {
      const result = await api.diagnoseProject(project.id)
      if (mounted.current && sequence === scanSequence.current) setReport(result)
    } catch (reason) {
      if (mounted.current && sequence === scanSequence.current) setError(String(reason))
    } finally {
      if (mounted.current && sequence === scanSequence.current) setLoading(false)
    }
  }, [project.id])

  useEffect(() => {
    mounted.current = true
    void scan()
    return () => { mounted.current = false; scanSequence.current++ }
  }, [scan])

  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null
    dialogContent.current?.closest('[role="dialog"]')?.querySelector<HTMLElement>('button')?.focus()
    return () => previous?.focus()
  }, [templatesOpen])

  useEffect(() => {
    if (!confirm) return
    const underlying = dialogContent.current?.closest<HTMLElement>('[role="dialog"]')
    const trigger = confirmTrigger.current
    if (underlying) underlying.inert = true
    const dialogs = document.querySelectorAll<HTMLElement>('[role="dialog"]')
    const active = dialogs[dialogs.length - 1]
    active?.querySelector<HTMLElement>('button')?.focus()
    const keyboard = (event: KeyboardEvent) => {
      if (event.key === 'Escape') { event.preventDefault(); event.stopPropagation(); setConfirm(null) }
      if (event.key !== 'Tab') return
      const buttons = [...(active?.querySelectorAll<HTMLElement>('button:not(:disabled), [tabindex="0"]') ?? [])]
      const first = buttons[0], last = buttons[buttons.length - 1]
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
    }
    document.addEventListener('keydown', keyboard, true)
    return () => {
      if (underlying) underlying.inert = false
      document.removeEventListener('keydown', keyboard, true)
      requestAnimationFrame(() => { if (trigger?.isConnected) trigger.focus() })
    }
  }, [confirm])

  useTauriEvent<string>('godot-download-complete', tag => {
    if (tag === project.godot_version) { setQueuedVersion(false); void scan() }
  }, [project.godot_version, scan])
  useTauriEvent<string>('godot-download-canceled', tag => {
    if (tag === project.godot_version) setQueuedVersion(false)
  }, [project.godot_version])
  useTauriEvent<{tag: string; message: string}>('godot-download-error', payload => {
    if (payload.tag === project.godot_version) { setQueuedVersion(false); setError(payload.message) }
  }, [project.godot_version])

  const changed = () => window.dispatchEvent(new Event('app:project-health-changed'))
  const run = async (id: string, action: () => Promise<unknown>) => {
    if (mutationPending.current) return
    mutationPending.current = true; setBusy(id); setError('')
    try { await action() }
    catch (reason) { if (mounted.current) setError(String(reason)) }
    finally {
      mutationPending.current = false
      if (mounted.current) {
        setBusy(null)
        requestAnimationFrame(() => {
          if (document.activeElement === document.body) refreshButton.current?.focus()
        })
      }
    }
  }

  const apply = async (finding: ProjectHealthCheck) => {
    setConfirm(null)
    await run(finding.id, async () => {
      await api.fixProjectHealth(project.id, finding.id)
      changed()
      pushToast('success', t('fix_complete'))
      if (finding.action?.kind === 'remove_registration' && finding.action.target === project.id) onClose()
      else await scan()
    })
  }

  const bind = async (tag: string) => run('binding', async () => {
    await api.updateProject(project.id, { godot_version: tag })
    changed(); await scan()
  })

  const installBoundVersion = (finding: ProjectHealthCheck) => run(finding.id, async () => {
    const mono = project.godot_version.endsWith('-mono')
    const tag = project.godot_version.replace(/-mono$/, '')
    let releases = await api.fetchAvailableGodotVersions('github')
    let release = releases.find(r => r.tag.replace(/^v/, '') === tag.replace(/^v/, ''))
    if (!release) {
      releases = await api.fetchAvailableGodotVersions('archive')
      release = releases.find(r => r.tag.replace(/^v/, '') === tag.replace(/^v/, ''))
    }
    const asset = release?.assets.find(a => a.is_mono === mono)
    if (!release || !asset) throw new Error(t('version_asset_unavailable'))
    await api.downloadGodotVersion(release.tag, asset.name, asset.download_url)
    setQueuedVersion(true)
    pushToast('success', t('version_queued'))
  })

  const action = (finding: ProjectHealthCheck) => {
    const kind = finding.action?.kind
    if (!kind) return null
    if (kind === 'choose_version') return <Dropdown
      trigger={({toggle}) => <button type="button" disabled={!!busy || loading || installedVersions.length === 0} onClick={toggle} className={actionButton}>
        {t('action_choose_version')}<IconChevronDown className="h-3 w-3" />
      </button>}
      items={installedVersions.map(v => ({ key:v.tag, label:v.custom_name || v.tag, onClick:() => void bind(v.tag) }))}
    />
    return <button type="button" disabled={!!busy || loading || (kind === 'install_version' && queuedVersion)} className={actionButton}
      onClick={event => {
        if (finding.action?.confirm) { confirmTrigger.current = event.currentTarget; setConfirm(finding); return }
        if (kind === 'templates') { setTemplatesOpen(true); return }
        if (kind === 'install_version') { void installBoundVersion(finding); return }
        if (kind === 'manage_versions') {
          onClose(); window.dispatchEvent(new CustomEvent('app:set-tab', {detail:'versions'})); return
        }
        if (kind === 'open_editor') { void run(finding.id, () => api.openProject(project.id, true)); return }
        if (kind === 'open_presets' || kind === 'open_addons') { void run(finding.id, () => api.openInEditor(project.path)); return }
        void apply(finding)
      }}>
      {busy === finding.id && <IconSpinner className="h-3 w-3 animate-spin" />}
      {t(kind === 'install_version' && queuedVersion ? 'version_queued_short' : `action_${kind}`)}
    </button>
  }

  const passed = report?.checks.filter(c => c.severity === 'ok') ?? []
  const findings = report?.checks.filter(c => c.severity !== 'ok') ?? []
  const errors = findings.filter(c => c.severity === 'error').length
  const warnings = findings.filter(c => c.severity === 'warning').length

  const row = (finding: ProjectHealthCheck) => {
    const Icon = finding.severity === 'ok' ? IconCheckCircle : finding.severity === 'info' ? IconInfo : IconAlertTriangle
    const tone = finding.severity === 'error' ? 'text-danger' : finding.severity === 'warning' ? 'text-amber' : finding.severity === 'ok' ? 'text-mint' : 'text-muted'
    const values = {...finding.values, size: formatBytes(Number(finding.values.bytes ?? 0))}
    return <div key={finding.id} className="flex gap-3 py-4 border-b border-line/70 last:border-0">
      <Icon className={`h-4 w-4 mt-0.5 shrink-0 ${tone}`} />
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
          <h4 className="text-sm font-medium text-ink">{t(`${finding.code}_title`, values)}</h4>
          <span className={`text-[10px] font-medium ${tone}`}>{t(`severity_${finding.severity}`)}</span>
        </div>
        <p className="mt-1 text-xs leading-relaxed text-muted max-w-prose">{t(`${finding.code}_description`, values)}</p>
        {finding.details.length > 0 && <ul className="mt-2 space-y-1 text-[11px] text-muted/80">
          {finding.details.map((detail, index) => <li key={index} className="break-all font-mono">{detail}</li>)}
        </ul>}
        {finding.action && <div className="mt-3">{action(finding)}</div>}
        {finding.action?.kind === 'choose_version' && installedVersions.length === 0 && <button type="button" className={`${actionButton} mt-2`}
          onClick={() => { onClose(); window.dispatchEvent(new CustomEvent('app:set-tab',{detail:'versions'})) }}>{t('action_manage_versions')}</button>}
      </div>
    </div>
  }

  if (templatesOpen) return <ExportTemplatesModal tag={project.godot_version} onClose={() => setTemplatesOpen(false)} onChanged={scan}
    onDownload={files => {
      setTemplatesOpen(false)
      void run('templates', async () => {
        const result = await api.installExportTemplates(project.godot_version, files)
        if (result) { setTemplateFilesInstalled(project.godot_version, files, true); pushToast('success', t('fix_complete')); changed() }
        await scan()
      })
    }} />

  return <>
    <ModalShell title={t('title')} icon={<IconBug className="h-5 w-5 text-accent-bright" />}
      description={project.name} maxWidth="max-w-3xl" bodyClassName="h-[min(60vh,34rem)] shrink" onClose={confirm ? undefined : onClose}
      onKeyDown={event => {
        if (confirm) return
        if (event.key === 'Escape') { event.stopPropagation(); onClose() }
        if (event.key !== 'Tab') return
        const elements = [...event.currentTarget.querySelectorAll<HTMLElement>('button:not(:disabled), [tabindex="0"]')].filter(e => !e.closest('[inert]'))
        const first = elements[0], last = elements[elements.length-1]
        if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
        else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
      }}
      footer={<>
        <p className="flex-1 text-[11px] text-muted leading-relaxed">{t(busy === 'templates' ? 'templates_downloading' : 'local_checks')}</p>
        <button type="button" className={actionButton} onClick={() => { onClose(); window.dispatchEvent(new CustomEvent('app:set-tab', {detail:'versions'})) }}>{t('action_manage_versions')}</button>
        {busy === 'templates' && <button type="button" className={actionButton} title={tc('cancel')} aria-label={tc('cancel')} onClick={() => void api.cancelExportTemplates(project.godot_version).catch(e => setError(String(e)))}><IconX className="h-3 w-3" /></button>}
        <button type="button" onClick={onClose} className={actionButton}>{tc('close')}</button>
      </>}>
      <div ref={dialogContent} className="px-6 pb-6">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line pb-4">
          <div aria-live="polite">
            <p className="text-sm font-medium text-ink">{loading ? t('scanning') : errors ? t('summary_errors', {count:errors}) : warnings ? t('summary_warnings', {count:warnings}) : report ? t('summary_ready') : t('scan_failed')}</p>
            {report && <p className="mt-1 text-xs text-muted">{t('summary_counts', {passed:passed.length, findings:findings.length})}</p>}
          </div>
          <button ref={refreshButton} type="button" disabled={loading || !!busy} onClick={() => void scan()} className={actionButton}>
            <IconRefresh className={`h-3 w-3 ${loading ? 'animate-spin' : ''}`} />{t('run_again')}
          </button>
        </div>
        {error && <div role="alert" className="mt-4 rounded-item border border-danger/30 bg-danger/5 p-3 text-xs text-danger break-words">{error}</div>}
        {loading && !report && <div role="status" className="flex items-center justify-center gap-3 py-16 text-sm text-muted"><IconSpinner className="h-4 w-4 animate-spin" />{t('scanning')}</div>}
        {report && <div aria-busy={loading} className={loading ? 'opacity-60' : ''}>
          {categories.map(category => {
            const entries = findings.filter(c => c.category === category).sort((a,b) => rank[a.severity] - rank[b.severity])
            return entries.length > 0 && <section key={category} className="mt-5">
              <h3 className="text-xs font-semibold text-muted">{t(`category_${category}`)}</h3>
              {entries.map(row)}
            </section>
          })}
          {passed.length > 0 && <section className="mt-5 border-t border-line pt-4">
            <button type="button" aria-expanded={showPassed} aria-controls="doctor-passed-checks" onClick={event => { setAnimatePassed(event.detail > 0); setShowPassed(!showPassed) }}
              className="focus-ring cursor-pointer flex w-full items-center gap-2 rounded-btn text-xs text-muted hover:text-ink transition-colors">
              <IconCheckCircle className="h-3.5 w-3.5 text-mint" /><span className="flex-1 text-left">{t('passed_checks', {count:passed.length})}</span>
              <TemplateDisclosureChevron open={showPassed} animate={animatePassed} />
            </button>
            <TemplateDisclosure id="doctor-passed-checks" open={showPassed} animate={animatePassed}>{passed.map(row)}</TemplateDisclosure>
          </section>}
        </div>}
      </div>
    </ModalShell>
    {confirm && <ConfirmDialog title={t(`action_${confirm.action?.kind}`)}
      description={t(`confirm_${confirm.action?.kind}`)} confirmLabel={t(`action_${confirm.action?.kind}`)}
      variant={confirm.action?.kind === 'enable_addon' ? 'default' : 'danger'} onConfirm={() => void apply(confirm)} onCancel={() => setConfirm(null)} />}
  </>
}
