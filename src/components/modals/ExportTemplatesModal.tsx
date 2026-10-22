import { useEffect, useId, useRef, useState, type MouseEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { api } from '../../lib/api'
import { formatBytes } from '../../lib/formatBytes'
import { groupTemplateFiles, groupTemplateOptions, toggleTemplateFiles, type ExportTemplateFile } from '../../lib/exportTemplateSelection'
import { cacheTemplateOptions, getCachedTemplateOptions, loadTemplateOptions } from '../../lib/exportTemplateCatalog'
import { IconCheck, IconDownload, IconRefresh, IconSpinner, IconTrash } from '../../lib/icons'
import { pushToast } from '../../lib/toast'
import type { ExportTemplateOption } from '../../types'
import { Checkbox } from '../ui/Checkbox'
import { ModalShell } from './ModalShell'
import { TemplateDisclosure, TemplateDisclosureChevron } from './TemplateDisclosure'

interface Props {
  tag: string
  onClose: () => void
  onDownload: (files: string[]) => void
  onChanged?: () => void | Promise<void>
}

function InstalledMark({ label }: { label: string }) {
  return (
    <span role="checkbox" aria-checked="true" aria-readonly="true" aria-label={label} title={label}
      className="shrink-0 inline-flex items-center justify-center w-[18px] h-[18px] rounded-sm border border-mint/40 bg-mint/15 text-mint">
      <IconCheck className="w-3 h-3" />
    </span>
  )
}

export function ExportTemplatesModal({ tag, onClose, onDownload, onChanged }: Props) {
  const { t } = useTranslation('versions')
  const { t: tc } = useTranslation('common')
  const [options, setOptions] = useState<ExportTemplateOption[]>(() => getCachedTemplateOptions(tag) ?? [])
  const [selected, setSelected] = useState<string[]>([])
  const [expanded, setExpanded] = useState<string[]>([])
  const [expandedArchitectures, setExpandedArchitectures] = useState<string[]>([])
  const [loading, setLoading] = useState(() => !getCachedTemplateOptions(tag))
  const [checking, setChecking] = useState(true)
  const [collapsedCategories, setCollapsedCategories] = useState<string[]>([])
  const [animateDisclosures, setAnimateDisclosures] = useState(false)
  const [error, setError] = useState('')
  const [attempt, setAttempt] = useState(0)
  const [removing, setRemoving] = useState<string[]>([])
  const mutationPending = useRef(false)
  const content = useRef<HTMLDivElement>(null)
  const id = useId()
  const previousTag = useRef(tag)

  useEffect(() => {
    let active = true
    if (previousTag.current !== tag) {
      previousTag.current = tag
      setSelected([]); setExpanded([]); setExpandedArchitectures([]); setCollapsedCategories([])
    }
    const cached = getCachedTemplateOptions(tag)
    setOptions(cached ?? [])
    setLoading(!cached)
    setChecking(true)
    setError('')
    loadTemplateOptions(tag, attempt > 0).then((result) => {
      if (!active) return
      setOptions(result)
      const available = new Set(result.flatMap(option => option.files.filter(file => !file.installed).map(file => file.name)))
      const platforms = new Set(result.map(option => option.id))
      const groups = new Set(result.flatMap(option => groupTemplateFiles(option.files).map(group => `${option.id}:${group.id}`)))
      setSelected(previous => previous.filter(name => available.has(name)))
      setExpanded(previous => previous.filter(key => platforms.has(key)))
      setExpandedArchitectures(previous => previous.filter(key => groups.has(key)))
    }).catch((reason) => {
      if (!active) return
      if (cached) pushToast('error', `${t('export_templates_options_failed')} ${String(reason)}`, 6000)
      else setError(String(reason))
    }).finally(() => {
      if (active) { setLoading(false); setChecking(false) }
    })
    return () => { active = false }
  }, [tag, attempt])

  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null
    const dialog = content.current?.closest<HTMLElement>('[role="dialog"]')
    dialog?.querySelector<HTMLElement>('button')?.focus()
    return () => { previous?.focus() }
  }, [])

  const allFiles = options.flatMap((option) => option.files)
  const availableFiles = allFiles.filter((file) => !file.installed)
  const selectedNames = new Set(selected)
  const chosen = availableFiles.filter((file) => selectedNames.has(file.name))
  const downloadBytes = chosen.reduce((sum, file) => sum + file.download_bytes, 0)
  const installedBytes = chosen.reduce((sum, file) => sum + file.size_bytes, 0)
  const allSelected = availableFiles.length > 0 && chosen.length === availableFiles.length
  const busy = removing.length > 0 || checking

  const prepareDisclosure = (event: MouseEvent<HTMLButtonElement>) => {
    setAnimateDisclosures(event.detail > 0)
  }

  const uninstall = async (files: ExportTemplateFile[], label: string) => {
    const names = files.filter((file) => file.installed).map((file) => file.name)
    if (mutationPending.current || names.length === 0) return
    mutationPending.current = true
    const trigger = document.activeElement
    setRemoving(names)
    try {
      await api.uninstallExportTemplateFiles(tag, names)
      const removed = new Set(names)
      const next = options.map((option) => {
        const files = option.files.map((file) => removed.has(file.name) ? { ...file, installed: false } : file)
        return { ...option, files, installed: files.every((file) => file.installed) }
      })
      setOptions(next)
      cacheTemplateOptions(tag, next)
      setSelected((previous) => previous.filter((name) => !removed.has(name)))
      await onChanged?.()
      pushToast('success', t('export_templates_removed_toast'))
    } catch (reason) {
      pushToast('error', t('export_templates_uninstall_failed', { error: String(reason) }), 6000)
    } finally {
      mutationPending.current = false
      setRemoving([])
      requestAnimationFrame(() => {
        if (document.activeElement !== document.body && document.activeElement !== trigger) return
        const checkbox = [...(content.current?.querySelectorAll<HTMLButtonElement>('button[role="checkbox"]') ?? [])]
          .find((element) => element.getAttribute('aria-label') === label)
        checkbox?.focus()
      })
    }
  }

  const uninstallButton = (files: ExportTemplateFile[], label: string) => files.some((file) => file.installed) && (
    <button type="button" disabled={busy} onClick={() => void uninstall(files, label)}
      aria-label={t('export_templates_uninstall_named', { name: label })}
      title={t('export_templates_uninstall_named', { name: label })}
      className="focus-ring cursor-pointer shrink-0 p-1.5 rounded-btn text-muted/60 hover:text-danger hover:bg-danger/10 transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
      {files.some((file) => removing.includes(file.name))
        ? <IconSpinner className="w-3 h-3 animate-spin" />
        : <IconTrash className="w-3 h-3" />}
    </button>
  )

  return (
    <ModalShell
      icon={<IconDownload className="w-5 h-5 text-accent-bright" />}
      title={t('export_templates_choose')}
      description={t('export_templates_choose_desc', { tag })}
      maxWidth="max-w-2xl"
      bodyClassName="h-[min(60vh,34rem)] shrink"
      onClose={onClose}
      onKeyDown={(event) => {
        if (event.key === 'Escape') { event.stopPropagation(); onClose() }
        if (event.key !== 'Tab') return
        const elements = [...event.currentTarget.querySelectorAll<HTMLElement>('button:not(:disabled), [tabindex="0"]')]
          .filter((element) => !element.closest('[inert]'))
        const first = elements[0]
        const last = elements[elements.length - 1]
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault(); last?.focus()
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault(); first?.focus()
        }
      }}
      footer={
        <>
          <div className="flex-1 min-w-0 min-h-9 text-xs text-muted" aria-live="polite">
            <p className="font-medium text-ink">{t('export_templates_selected', { count: chosen.length })}</p>
            {chosen.length > 0 && (
              <p className="mt-1 text-[11px]">{t('export_templates_size_summary', {
                download: formatBytes(downloadBytes), installed: formatBytes(installedBytes),
              })}</p>
            )}
          </div>
          <button type="button" onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors">
            {tc('cancel')}
          </button>
          <button type="button" disabled={loading || !!error || busy || chosen.length === 0}
            onClick={() => onDownload(chosen.map((file) => file.name))}
            className="focus-ring cursor-pointer disabled:cursor-not-allowed disabled:opacity-40 inline-flex items-center gap-2 px-4 py-2.5 rounded-item text-sm font-medium bg-accent hover:bg-accent/90 text-white transition-colors">
            <IconDownload className="w-3.5 h-3.5" />{t('export_templates_download_selected')}
          </button>
        </>
      }
    >
      <div ref={content} className="px-6 pb-6 flex flex-col gap-3">
        {loading ? (
          <div role="status" className="flex items-center justify-center gap-3 py-12 text-sm text-muted">
            <IconSpinner className="w-4 h-4 animate-spin" />{t('export_templates_loading_options')}
          </div>
        ) : error ? (
          <div role="alert" className="rounded-item border border-danger/30 bg-danger/5 p-4 text-sm">
            <p className="text-danger">{t('export_templates_options_failed')}</p>
            <p className="text-muted mt-2 break-words">{error}</p>
            <button type="button" onClick={() => setAttempt((value) => value + 1)}
              className="focus-ring cursor-pointer mt-4 px-4 py-2 rounded-item border border-line bg-raised text-ink hover:bg-overlay">
              {t('export_templates_retry')}
            </button>
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between gap-3 text-xs text-muted">
              <span>{t('export_templates_available', { count: options.length })}</span>
              <button type="button" disabled={busy} onClick={() => setAttempt((value) => value + 1)}
                aria-label={t('export_templates_refresh')} title={t('export_templates_refresh')}
                className="focus-ring cursor-pointer ms-auto p-1.5 rounded-btn text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                <IconRefresh className={`w-3 h-3 ${checking ? 'animate-spin' : ''}`} />
              </button>
              <button type="button" disabled={busy || availableFiles.length === 0}
                onClick={() => setSelected(allSelected ? [] : availableFiles.map((file) => file.name))}
                className="focus-ring cursor-pointer rounded-btn px-3 py-1.5 text-accent-bright hover:bg-accent/10 transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                {t(allSelected ? 'export_templates_select_none' : 'export_templates_select_all')}
              </button>
            </div>
            <div className="flex flex-col gap-2.5">
              {groupTemplateOptions(options).map((category) => {
                const files = category.options.flatMap((option) => option.files)
                const available = files.filter((file) => !file.installed)
                const selectedCount = available.filter((file) => selectedNames.has(file.name)).length
                const open = !collapsedCategories.includes(category.id)
                const categoryId = `${id}-category-${category.id}`
                const label = t(category.labelKey)
                return (
                  <section key={category.id} className="flex flex-col">
                    <div className="flex items-center gap-3 px-1 py-2">
                      {available.length === 0 ? <InstalledMark label={`${label} · ${t('export_templates_option_installed')}`} /> : <Checkbox
                        checked={selectedCount === available.length} disabled={busy}
                        indeterminate={selectedCount > 0 && selectedCount < available.length}
                        label={label} onChange={(checked) => setSelected((previous) => toggleTemplateFiles(previous, files, checked))} />}
                      <button type="button" aria-expanded={open} aria-controls={categoryId}
                        onClick={(event) => {
                          prepareDisclosure(event)
                          setCollapsedCategories((previous) => open ? [...previous, category.id] : previous.filter((key) => key !== category.id))
                        }}
                        className="focus-ring cursor-pointer flex flex-1 items-center gap-2 rounded-btn text-start text-sm font-medium text-muted hover:text-ink transition-colors">
                        <span className="flex-1">{label}</span>
                        <TemplateDisclosureChevron open={open} animate={animateDisclosures} />
                      </button>
                    </div>
                    <TemplateDisclosure id={categoryId} open={open} animate={animateDisclosures} className="flex flex-col gap-2.5 pt-2.5">{category.options.map((option) => {
                        const available = option.files.filter((file) => !file.installed)
                        const installedCount = option.files.length - available.length
                        const selectedCount = available.filter((file) => selectedNames.has(file.name)).length
                        const fullyInstalled = available.length === 0
                        const open = expanded.includes(option.id)
                        const panelId = `${id}-${option.id}`
                        return (
                          <div key={option.id} className="rounded-item border border-outline/50 bg-overlay p-3.5">
                            <div className="flex items-center gap-3">
                              {fullyInstalled ? <InstalledMark label={`${option.label} · ${t('export_templates_option_installed')}`} /> : <Checkbox
                                checked={selectedCount === available.length} disabled={busy}
                                indeterminate={selectedCount > 0 && selectedCount < available.length}
                                label={option.label}
                                onChange={(checked) => setSelected((previous) => toggleTemplateFiles(previous, option.files, checked))} />}
                              <button type="button" aria-expanded={open} aria-controls={panelId}
                                onClick={(event) => {
                                  prepareDisclosure(event)
                                  setExpanded((previous) => open ? previous.filter((key) => key !== option.id) : [...previous, option.id])
                                }}
                                className="focus-ring cursor-pointer flex flex-1 min-w-0 items-center gap-2 rounded-btn text-start">
                                <span className="flex-1 min-w-0">
                                  <span className="block text-sm font-medium text-ink">{option.label}</span>
                                  <span className="block text-[11px] text-muted mt-0.5">{t('export_templates_files', { count: option.files.length })}</span>
                                </span>
                                {installedCount > 0 && <span className="shrink-0 rounded-tag border border-mint/30 bg-mint/10 px-2 py-0.5 text-[10px] font-medium text-mint">{!fullyInstalled && `${installedCount}/${option.files.length} `}{t('export_templates_option_installed')}</span>}
                                {selectedCount > 0 && <span className="text-[10px] text-accent-bright tabular-nums">{selectedCount}/{available.length}</span>}
                                <span className="text-xs text-muted tabular-nums shrink-0">{formatBytes(fullyInstalled ? option.size_bytes : available.reduce((sum, file) => sum + file.download_bytes, 0))}</span>
                                <TemplateDisclosureChevron open={open} animate={animateDisclosures} />
                              </button>
                              {uninstallButton(option.files, option.label)}
                            </div>
                            <TemplateDisclosure id={panelId} open={open} animate={animateDisclosures} className="pt-3">
                              <div className="pt-3 border-t border-outline/50 flex flex-col gap-3">
                                {groupTemplateFiles(option.files).map((group, groupIndex) => {
                                  const groupLabel = group.labelKey ? t(group.labelKey) : group.label
                                  const groupName = groupLabel ? (option.id === 'web' ? groupLabel : `${option.label} ${groupLabel}`) : option.label
                                  const available = group.files.filter((file) => !file.installed)
                                  const installedCount = group.files.length - available.length
                                  const fullyInstalled = available.length === 0
                                  const count = available.filter((file) => selectedNames.has(file.name)).length
                                  const groupKey = `${option.id}:${group.id}`
                                  const groupOpen = !group.label || expandedArchitectures.includes(groupKey)
                                  const groupPanelId = `${panelId}-${groupIndex}`
                                  return (
                                    <div key={group.id} className="flex flex-col">
                                      {groupLabel && (
                                        <div className="flex items-center gap-3 px-1 py-1">
                                          {fullyInstalled ? <InstalledMark label={`${groupName} · ${t('export_templates_option_installed')}`} /> : <Checkbox
                                            checked={count === available.length} disabled={busy}
                                            indeterminate={count > 0 && count < available.length}
                                            label={groupName}
                                            onChange={(checked) => setSelected((previous) => toggleTemplateFiles(previous, group.files, checked))} />}
                                          <button type="button" aria-expanded={groupOpen} aria-controls={groupPanelId}
                                            onClick={(event) => {
                                              prepareDisclosure(event)
                                              setExpandedArchitectures((previous) => groupOpen ? previous.filter((key) => key !== groupKey) : [...previous, groupKey])
                                            }}
                                            className="focus-ring cursor-pointer flex flex-1 min-w-0 items-center gap-2 rounded-btn text-start py-1">
                                            <span className="flex-1 text-xs font-medium text-ink">{groupLabel}</span>
                                            {installedCount > 0 && <span className="text-[10px] text-mint">{!fullyInstalled && `${installedCount}/${group.files.length} `}{t('export_templates_option_installed')}</span>}
                                            {!fullyInstalled && <span className="text-[10px] text-muted tabular-nums">{count}/{available.length}</span>}
                                            <TemplateDisclosureChevron open={groupOpen} animate={animateDisclosures} />
                                          </button>
                                          {uninstallButton(group.files, groupName)}
                                        </div>
                                      )}
                                      <TemplateDisclosure id={groupPanelId} open={groupOpen} animate={animateDisclosures} className={`flex flex-col gap-1.5 ${group.label ? 'pt-1.5' : ''}`}>{group.files.map((file) => (
                                        <div key={file.name} className={`flex items-center gap-3 rounded-btn border px-3 py-2.5 ${group.label ? 'ms-5' : ''} ${selectedNames.has(file.name) ? 'border-accent-dim/40 bg-accent/5' : 'border-transparent bg-base/30 hover:bg-raised/70'} transition-colors`}>
                                          {file.installed ? <div className="flex flex-1 min-w-0 items-center gap-2.5">
                                            <InstalledMark label={`${file.name} · ${t('export_templates_option_installed')}`} />
                                            <span title={file.name} className="block min-w-0 truncate font-mono text-[11px] text-ink">{file.name}</span>
                                          </div> : <Checkbox checked={selectedNames.has(file.name)} disabled={busy} label={file.name} className="flex-1 min-w-0"
                                            onChange={(checked) => setSelected((previous) => toggleTemplateFiles(previous, [file], checked))}>
                                            <span title={file.name} className="block truncate font-mono text-[11px] font-normal">{file.name}</span>
                                          </Checkbox>}
                                          {file.installed && <span className="shrink-0 text-[10px] text-mint">{t('export_templates_option_installed')}</span>}
                                          <span className="text-[11px] text-muted tabular-nums shrink-0">{formatBytes(file.installed ? file.size_bytes : file.download_bytes)}</span>
                                          {uninstallButton([file], file.name)}
                                        </div>
                                      ))}</TemplateDisclosure>
                                    </div>
                                  )
                                })}
                              </div>
                            </TemplateDisclosure>
                          </div>
                        )
                    })}</TemplateDisclosure>
                  </section>
                )
              })}
            </div>
            <p className="text-[11px] text-muted/70 leading-relaxed">{t('export_templates_keep_existing')}</p>
          </>
        )}
      </div>
    </ModalShell>
  )
}
