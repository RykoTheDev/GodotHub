import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { AnimatePresence, motion } from 'framer-motion'
import { useSettings } from '../hooks/useSettings'
import { useGodotVersionsContext } from '../hooks/godotVersionsContext'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { Checkbox } from '../components/ui/Checkbox'
import { Tooltip } from '../components/reusables/Tooltip'
import { ModalShell } from '../components/modals/ModalShell'
import { api } from '../lib/api'
import { formatBytes } from '../lib/formatBytes'
import { pushToast, reportError } from '../lib/toast'
import {
  IconCloudArrowDown,
  IconFolder,
  IconHardDrive,
  IconRefresh,
  IconRocket,
  IconSpinner,
  IconTrash,
} from '../lib/icons'
import type { ReclaimItem, StorageReport } from '../types'

type ReclaimGroup = 'versions' | 'partials' | 'exports'

interface ReclaimEntry {
  key: string
  group: ReclaimGroup
  label: string
  detail: string
  path: string
  size: number
  defaultOn: boolean
  item: ReclaimItem
}

function reclaimEntries(
  report: StorageReport,
  tc: (key: string, opts?: Record<string, unknown>) => string,
): ReclaimEntry[] {
  const entries: ReclaimEntry[] = []
  for (const v of report.versions) {
    if (!v.unused) continue
    entries.push({
      key: `version:${v.tag}`,
      group: 'versions',
      label: v.name,
      detail: v.external ? tc('cleanup_external_hint') : v.tag,
      path: v.path,
      size: v.size_bytes,
      defaultOn: !v.external,
      item: { kind: 'version', tag: v.tag },
    })
  }
  for (const p of report.partials) {
    entries.push({
      key: `partial:${p.path}`,
      group: 'partials',
      label: p.name,
      detail: tc(`cleanup_kind_${p.kind}`),
      path: p.path,
      size: p.size_bytes,
      defaultOn: true,
      item: { kind: 'partial', path: p.path },
    })
  }
  for (const e of report.export_templates) {
    if (!e.orphan) continue
    entries.push({
      key: `export:${e.root}:${e.folder}`,
      group: 'exports',
      label: e.folder,
      detail: e.root,
      path: e.path,
      size: e.size_bytes,
      defaultOn: false,
      item: { kind: 'export_templates', folder: e.folder, root: e.root },
    })
  }
  return entries
}

function sum(values: number[]): number {
  return values.reduce((a, b) => a + b, 0)
}

function Badge({ tone, children }: { tone: 'accent' | 'mint' | 'amber' | 'muted' | 'danger'; children: ReactNode }) {
  const tones = {
    accent: 'bg-accent/10 text-accent-bright border-accent-dim/30',
    mint: 'bg-mint/10 text-mint border-mint/30',
    amber: 'bg-amber/10 text-amber border-amber/30',
    muted: 'bg-raised text-muted border-outline/50',
    danger: 'bg-danger/10 text-danger border-danger/30',
  }
  return (
    <span className={`shrink-0 text-[10px] font-semibold px-1.5 py-0.5 rounded-tag border ${tones[tone]}`}>
      {children}
    </span>
  )
}

function OpenFolderButton({ path }: { path: string }) {
  const { t: tc } = useTranslation('common')
  return (
    <Tooltip content={tc('open_folder')} side="left">
      <button
        type="button"
        aria-label={tc('open_folder')}
        onClick={() => void api.openProjectFolder(path).catch(reportError)}
        className="focus-ring cursor-pointer shrink-0 p-1.5 rounded-btn text-muted/60 hover:text-ink hover:bg-raised transition-colors"
      >
        <IconFolder className="w-3.5 h-3.5" />
      </button>
    </Tooltip>
  )
}

function Section({
  icon,
  title,
  total,
  description,
  children,
}: {
  icon: ReactNode
  title: string
  total?: number
  description?: string
  children: ReactNode
}) {
  return (
    <section className="flex flex-col gap-3 rounded-item border border-outline/50 bg-overlay p-4">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <h3 className="flex items-center gap-2 text-sm font-medium text-ink">
            {icon}
            {title}
          </h3>
          {description && (
            <p className="text-[11px] text-muted mt-1 leading-relaxed">{description}</p>
          )}
        </div>
        {total !== undefined && (
          <span className="shrink-0 text-xs font-mono text-muted tabular-nums">
            {formatBytes(total)}
          </span>
        )}
      </div>
      {children}
    </section>
  )
}

function SizeBar({ size, max }: { size: number; max: number }) {
  const pct = max > 0 ? Math.max(2, Math.round((size / max) * 100)) : 0
  return (
    <div className="h-1 w-full rounded-full bg-raised overflow-hidden">
      <div className="ui-grow-x h-full rounded-full bg-accent/60" style={{ width: `${pct}%` }} />
    </div>
  )
}

export function StorageView({
  connected = false,
  active = true,
}: {
  connected?: boolean
  active?: boolean
}) {
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const { refreshInstalled } = useGodotVersionsContext()
  const [report, setReport] = useState<StorageReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [confirming, setConfirming] = useState(false)
  const [reclaiming, setReclaiming] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const next = await api.getStorageReport()
      setReport(next)
      setSelected(
        new Set(reclaimEntries(next, tc).filter((e) => e.defaultOn).map((e) => e.key)),
      )
    } catch (e) {
      setError(String(e))
    } finally {
      setLoading(false)
    }
  }, [tc])

  useEffect(() => {
    if (active) void load()
  }, [active, load])

  const entries = useMemo(() => (report ? reclaimEntries(report, tc) : []), [report, tc])
  const chosen = entries.filter((e) => selected.has(e.key))
  const chosenSize = sum(chosen.map((e) => e.size))

  const totals = useMemo(() => {
    if (!report) return { versions: 0, templates: 0, exports: 0, partials: 0, all: 0 }
    const versions = sum(report.versions.map((v) => v.size_bytes))
    const templates = sum(report.templates.map((t) => t.size_bytes))
    const exports = sum(report.export_templates.map((e) => e.size_bytes))
    const partials = sum(report.partials.map((p) => p.size_bytes))
    return { versions, templates, exports, partials, all: versions + templates + exports + partials }
  }, [report])

  const toggle = (key: string, on: boolean) =>
    setSelected((prev) => {
      const next = new Set(prev)
      if (on) next.add(key)
      else next.delete(key)
      return next
    })

  const reclaim = async () => {
    setConfirming(false)
    setReclaiming(true)
    try {
      const result = await api.reclaimStorage(chosen.map((e) => e.item))
      if (result.removed > 0) {
        pushToast('success', tc('cleanup_done', { size: formatBytes(result.freed_bytes) }))
      }
      for (const f of result.failed) {
        pushToast('error', tc('cleanup_failed', { label: f.label, error: f.error }), 8000)
      }
      if (chosen.some((e) => e.group === 'versions')) await refreshInstalled()
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setReclaiming(false)
      await load()
    }
  }

  const groups: { id: ReclaimGroup; title: string; hint?: string }[] = [
    { id: 'versions', title: tc('cleanup_group_unused_versions') },
    { id: 'partials', title: tc('cleanup_group_partials') },
    { id: 'exports', title: tc('cleanup_group_orphan_exports'), hint: tc('cleanup_orphan_exports_hint') },
  ]

  const maxVersion = Math.max(0, ...(report?.versions.map((v) => v.size_bytes) ?? []))

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <ViewHeader
        connected={connected}
        className="mb-4"
        title={tc('cleanup_title')}
        leadingAction={
          <span className="inline-flex items-center px-2 py-0.5 rounded-tag bg-amber/15 text-amber text-[10px] font-semibold uppercase tracking-wider">
            {tc('unlocalized_badge')}
          </span>
        }
        metric={
          <>
            <h2 className="text-4xl font-bold text-muted tabular-nums">
              {report ? formatBytes(totals.all) : '…'}
            </h2>
            <p className="text-lg font-medium uppercase text-muted">{tc('cleanup_total_label')}</p>
          </>
        }
        actions={
          <motion.button
            type="button"
            data-press-feedback
            onClick={() => void load()}
            disabled={loading || reclaiming}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-overlay border border-outline/50 text-xs font-medium text-muted hover:text-ink hover:bg-raised hover:border-accent-dim transition-colors disabled:opacity-40 disabled:cursor-default"
          >
            <IconRefresh className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
            {tc('refresh')}
          </motion.button>
        }
      >
        <p className="text-xs text-muted">{tc('cleanup_subtitle')}</p>
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-me-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        topButtonBottom={'bottom-16'}
      >
        <div className={`ui-stagger ${connected ? 'ps-3' : ''} pe-5 pb-4 flex flex-col gap-3`}>
          {error && !report ? (
            <div className="border border-dashed border-danger/30 rounded-item py-16 flex flex-col items-center gap-4 text-center">
              <p className="text-sm text-muted max-w-sm leading-relaxed">
                {tc('cleanup_load_error', { error })}
              </p>
              <button
                type="button"
                onClick={() => void load()}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2 rounded-item border border-outline/50 hover:bg-raised text-xs font-medium text-ink transition-colors"
              >
                <IconRefresh className="w-3.5 h-3.5" />
                {tc('try_again')}
              </button>
            </div>
          ) : !report ? (
            <div className="py-24 flex flex-col items-center gap-3 text-center">
              <IconSpinner className="w-5 h-5 animate-spin text-muted" />
              <p className="text-xs text-muted">{tc('cleanup_scanning')}</p>
            </div>
          ) : (
            <>
              <div className="ui-stagger grid grid-cols-2 lg:grid-cols-4 gap-3">
                {[
                  { label: tc('installed_versions_section'), value: totals.versions },
                  { label: tc('cleanup_templates_title'), value: totals.templates },
                  { label: tc('cleanup_export_templates_title'), value: totals.exports },
                  { label: tc('cleanup_reclaimable_title'), value: sum(entries.map((e) => e.size)) },
                ].map((card) => (
                  <div
                    key={card.label}
                    className="flex flex-col gap-1 px-4 py-3 rounded-item border border-outline/50 bg-overlay"
                  >
                    <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">
                      {card.label}
                    </span>
                    <span className="text-lg font-semibold text-ink tabular-nums">
                      {formatBytes(card.value)}
                    </span>
                  </div>
                ))}
              </div>

              <Section
                icon={<IconTrash className="w-3.5 h-3.5 text-muted" />}
                title={tc('cleanup_reclaimable_title')}
                description={tc('cleanup_reclaimable_desc')}
              >
                {entries.length === 0 ? (
                  <p className="text-xs text-muted/70 py-2">{tc('cleanup_nothing_to_reclaim')}</p>
                ) : (
                  <>
                    {groups.map((group) => {
                      const rows = entries.filter((e) => e.group === group.id)
                      if (rows.length === 0) return null
                      const allOn = rows.every((r) => selected.has(r.key))
                      const someOn = rows.some((r) => selected.has(r.key))
                      return (
                        <div key={group.id} className="flex flex-col gap-1.5">
                          <div className="flex items-center justify-between gap-3 pt-1">
                            <Checkbox
                              checked={allOn}
                              indeterminate={!allOn && someOn}
                              onChange={(on) => rows.forEach((r) => toggle(r.key, on))}
                              label={group.title}
                            >
                              <span className="text-xs font-medium text-ink">{group.title}</span>
                            </Checkbox>
                            <span className="text-[11px] font-mono text-muted tabular-nums">
                              {formatBytes(sum(rows.map((r) => r.size)))}
                            </span>
                          </div>
                          {group.hint && (
                            <p className="text-[11px] text-amber/90 leading-relaxed">{group.hint}</p>
                          )}
                          {rows.map((row) => (
                            <div
                              key={row.key}
                              className="flex items-center gap-3 rounded-btn bg-base/40 border border-outline/40 px-3 py-2"
                            >
                              <Checkbox
                                checked={selected.has(row.key)}
                                onChange={(on) => toggle(row.key, on)}
                                label={row.label}
                              />
                              <div className="min-w-0 flex-1">
                                <p className="text-xs font-medium text-ink truncate">{row.label}</p>
                                <p className="text-[11px] text-muted truncate">{row.detail}</p>
                              </div>
                              <span className="shrink-0 text-xs font-mono text-ink tabular-nums">
                                {formatBytes(row.size)}
                              </span>
                              <OpenFolderButton path={row.path} />
                            </div>
                          ))}
                        </div>
                      )
                    })}
                    <div className="flex items-center justify-end gap-3 pt-2 border-t border-line">
                      <motion.button
                        type="button"
                        data-press-feedback
                        disabled={chosen.length === 0 || reclaiming || loading}
                        onClick={() => setConfirming(true)}
                        className="focus-ring cursor-pointer inline-flex items-center gap-2 h-9 px-5 rounded-item bg-danger text-white text-sm font-medium hover:brightness-110 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                      >
                        {reclaiming ? (
                          <IconSpinner className="w-4 h-4 animate-spin" />
                        ) : (
                          <IconTrash className="w-4 h-4" />
                        )}
                        {tc('cleanup_reclaim_btn', { size: formatBytes(chosenSize) })}
                      </motion.button>
                    </div>
                  </>
                )}
              </Section>

              <Section
                icon={<IconCloudArrowDown className="w-3.5 h-3.5 text-muted" />}
                title={tc('installed_versions_section')}
                total={totals.versions}
                description={tc('cleanup_versions_desc')}
              >
                {report.versions.length === 0 ? (
                  <p className="text-xs text-muted/70 py-2">{tc('cleanup_empty')}</p>
                ) : (
                  <div className="flex flex-col gap-1.5">
                    {report.versions.map((v) => (
                      <div
                        key={v.tag}
                        className="flex flex-col gap-1.5 rounded-btn bg-base/40 border border-outline/40 px-3 py-2"
                      >
                        <div className="flex items-center gap-2">
                          <div className="min-w-0 flex-1 flex items-center gap-1.5 flex-wrap">
                            <span className="text-xs font-medium text-ink truncate">{v.name}</span>
                            {v.name !== v.tag && (
                              <span className="text-[11px] text-muted font-mono">{v.tag}</span>
                            )}
                            {v.is_current && <Badge tone="accent">{tc('cleanup_current_badge')}</Badge>}
                            {v.aliases.length > 0 && (
                              <Badge tone="accent">{tc('cleanup_alias_badge')}</Badge>
                            )}
                            {v.projects.length > 0 && (
                              <Tooltip content={v.projects.join(', ')}>
                                <span>
                                  <Badge tone="mint">
                                    {tc('n_projects', { count: v.projects.length })}
                                  </Badge>
                                </span>
                              </Tooltip>
                            )}
                            {v.templates.length > 0 && (
                              <Tooltip content={v.templates.join(', ')}>
                                <span>
                                  <Badge tone="mint">
                                    {tc('cleanup_used_by_templates', { count: v.templates.length })}
                                  </Badge>
                                </span>
                              </Tooltip>
                            )}
                            {v.unused && <Badge tone="amber">{tc('cleanup_unused_badge')}</Badge>}
                            {v.managed_by && <Badge tone="muted">{tc('cleanup_mise_badge')}</Badge>}
                            {v.external && !v.managed_by && (
                              <Badge tone="muted">{tc('cleanup_external_badge')}</Badge>
                            )}
                          </div>
                          <span className="shrink-0 text-xs font-mono text-ink tabular-nums">
                            {v.managed_by ? '-' : formatBytes(v.size_bytes)}
                          </span>
                          <OpenFolderButton path={v.path} />
                        </div>
                        {!v.managed_by && <SizeBar size={v.size_bytes} max={maxVersion} />}
                      </div>
                    ))}
                  </div>
                )}
              </Section>

              <Section
                icon={<IconRocket className="w-3.5 h-3.5 text-muted" />}
                title={tc('cleanup_templates_title')}
                total={totals.templates}
              >
                {report.templates.length === 0 ? (
                  <p className="text-xs text-muted/70 py-2">{tc('cleanup_empty')}</p>
                ) : (
                  <div className="flex flex-col gap-1.5">
                    {report.templates.map((t) => (
                      <div
                        key={t.path}
                        className="flex items-center gap-3 rounded-btn bg-base/40 border border-outline/40 px-3 py-2"
                      >
                        <div className="min-w-0 flex-1">
                          <p className="text-xs font-medium text-ink truncate">{t.name}</p>
                          <p className="text-[11px] text-muted truncate">{t.workspace}</p>
                        </div>
                        <span className="shrink-0 text-xs font-mono text-ink tabular-nums">
                          {formatBytes(t.size_bytes)}
                        </span>
                        <OpenFolderButton path={t.path} />
                      </div>
                    ))}
                  </div>
                )}
              </Section>

              <Section
                icon={<IconHardDrive className="w-3.5 h-3.5 text-muted" />}
                title={tc('cleanup_export_templates_title')}
                total={totals.exports}
              >
                {report.export_templates_error ? (
                  <p className="text-xs text-muted/70 py-2">{report.export_templates_error}</p>
                ) : report.export_templates.length === 0 ? (
                  <p className="text-xs text-muted/70 py-2">{tc('cleanup_empty')}</p>
                ) : (
                  <div className="flex flex-col gap-1.5">
                    {report.export_templates.map((e) => (
                      <div
                        key={`${e.root}:${e.folder}`}
                        className="flex items-center gap-3 rounded-btn bg-base/40 border border-outline/40 px-3 py-2"
                      >
                        <div className="min-w-0 flex-1 flex items-center gap-1.5">
                          <span className="text-xs font-medium text-ink truncate">
                            {e.tag ?? e.folder}
                          </span>
                          {e.orphan && <Badge tone="amber">{tc('cleanup_orphan_badge')}</Badge>}
                        </div>
                        <span className="shrink-0 text-xs font-mono text-ink tabular-nums">
                          {formatBytes(e.size_bytes)}
                        </span>
                        <OpenFolderButton path={e.path} />
                      </div>
                    ))}
                  </div>
                )}
              </Section>
            </>
          )}
          <div className="shrink-0 h-4" aria-hidden="true" />
        </div>
      </OverlayScrollArea>

      <AnimatePresence>
        {confirming && (
          <ModalShell
            icon={<IconTrash className="w-5 h-5 text-danger" />}
            title={tc('cleanup_confirm_title', { size: formatBytes(chosenSize) })}
            description={tc('cleanup_confirm_desc')}
            maxWidth="max-w-md"
            onClose={() => setConfirming(false)}
            showClose={false}
            footer={
              <div className="ms-auto flex items-center gap-2.5">
                <motion.button
                  data-press-feedback
                  onClick={() => setConfirming(false)}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  {tc('cancel')}
                </motion.button>
                <motion.button
                  data-press-feedback
                  onClick={() => void reclaim()}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm font-medium bg-danger hover:brightness-110 text-white transition-colors"
                >
                  {tc('cleanup_confirm_btn', { count: chosen.length })}
                </motion.button>
              </div>
            }
          >
            <div className="flex flex-col gap-3">
              <ul className="flex flex-col gap-1 max-h-64 overflow-y-auto">
                {chosen.map((e) => (
                  <li
                    key={e.key}
                    className="flex items-center justify-between gap-3 rounded-btn bg-base/50 border border-outline/40 px-3 py-2"
                  >
                    <div className="min-w-0">
                      <p className="text-xs font-medium text-ink truncate">{e.label}</p>
                      <p className="text-[11px] text-muted truncate" title={e.path}>
                        {e.path}
                      </p>
                    </div>
                    <span className="shrink-0 text-xs font-mono text-ink tabular-nums">
                      {formatBytes(e.size)}
                    </span>
                  </li>
                ))}
              </ul>
              <p className="text-[11px] text-muted leading-relaxed">
                {tc('cleanup_confirm_trash_note')}
              </p>
            </div>
          </ModalShell>
        )}
      </AnimatePresence>
    </div>
  )
}
