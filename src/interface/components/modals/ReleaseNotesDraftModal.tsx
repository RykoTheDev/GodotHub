import { useCallback, useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { ModalShell } from './ModalShell'
import { Dropdown } from '../ui/Dropdown'

import { api } from '../../../lib/api'
import {
  IconCheck,
  IconGitBranch,
  IconRefresh,
  IconRocket,
} from '../../lib/icons'
import type { ChangelogDraft, ChangelogNote } from '../../../types'

const HEAD = 'HEAD'

interface Row {
  key: string
  category: ChangelogNote['category']
  text: string
  hash?: string
  author?: string
}

const CATEGORIES: {
  value: ChangelogNote['category']
  activeClass: string
  dotClass: string
}[] = [
  { value: 'add', activeClass: 'bg-mint/15 text-mint', dotClass: 'bg-mint' },
  {
    value: 'fix',
    activeClass: 'bg-danger/15 text-danger',
    dotClass: 'bg-danger',
  },
  {
    value: 'improve',
    activeClass: 'bg-accent/15 text-accent-bright',
    dotClass: 'bg-accent-bright',
  },
]

const todayIso = () => new Date().toISOString().slice(0, 10)

interface Props {
  onClose: () => void
  onUseDraft: (
    notes: ChangelogNote[],
    version: string,
    date: string,
  ) => void
}

export function ReleaseNotesDraftModal({ onClose, onUseDraft }: Props) {
  const { t } = useTranslation('common')
  const [tags, setTags] = useState<string[]>([])
  const [from, setFrom] = useState('')
  const [to, setTo] = useState(HEAD)
  const [draft, setDraft] = useState<ChangelogDraft | null>(null)
  const [rows, setRows] = useState<Row[]>([])
  const [skippedChecked, setSkippedChecked] = useState<Record<number, boolean>>(
    {},
  )
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [version, setVersion] = useState('')
  const [date, setDate] = useState(todayIso())

  useEffect(() => {
    let cancelled = false
    api
      .listGitTags()
      .then((list) => {
        if (cancelled) return
        setTags(list)
        setFrom(list[0] ?? '')
      })
      .catch((e) => {
        if (!cancelled) setError(String(e))
      })
    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (!draft) return
    setRows(
      draft.notes.map((n) => ({
        key: `n-${n.hash}`,
        category: n.category,
        text: n.text,
        hash: n.hash,
        author: n.author,
      })),
    )
    setSkippedChecked({})
    setVersion((v) => (v ? v : draft.next_version))
  }, [draft])

  const generate = useCallback(async () => {
    if (!from || !to) return
    setLoading(true)
    setError(null)
    setDraft(null)
    try {
      const d = await api.generateChangelogDraft(from, to)
      setDraft(d)
    } catch (e) {
      setError(String(e))
    } finally {
      setLoading(false)
    }
  }, [from, to])

  const setRow = (i: number, patch: Partial<Row>) =>
    setRows((prev) => prev.map((r, idx) => (idx === i ? { ...r, ...patch } : r)))

  const toggleSkipped = (i: number) => {
    if (!draft) return
    const item = draft.skipped[i]
    const key = `s-${i}`
    setSkippedChecked((prev) => ({ ...prev, [i]: !prev[i] }))
    setRows((prev) => {
      const exists = prev.some((r) => r.key === key)
      if (exists) return prev.filter((r) => r.key !== key)
      return [
        ...prev,
        {
          key,
          category: 'improve' as const,
          text: item.subject,
          hash: item.hash,
        },
      ]
    })
  }

  const useDraft = () => {
    const notes = rows
      .map((r) => ({ category: r.category, text: r.text.trim() }))
      .filter((n) => n.text.length > 0)
    onUseDraft(notes, version, date)
  }

  return (
    <ModalShell
      icon={<IconRocket className="w-5 h-5 text-accent-bright" />}
      title={t('changelog_draft_title')}
      description={t('changelog_draft_desc')}
      maxWidth="max-w-lg"
      onClose={onClose}
      showClose={false}
      footer={
        <>
          {error && (
            <p className="text-xs text-danger self-start max-w-64">{error}</p>
          )}
          <div className="ml-auto flex items-center gap-2.5">
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={onClose}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
            >
              {t('cancel')}
            </motion.button>
            <motion.button
              whileHover={rows.length === 0 ? undefined : { y: -1 }}
              whileTap={rows.length === 0 ? undefined : { scale: 0.96 }}
              onClick={useDraft}
              disabled={rows.length === 0}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-40 text-sm font-medium text-white transition-colors"
            >
              {t('changelog_draft_use')}
            </motion.button>
          </div>
        </>
      }
    >
      <div className="flex flex-col gap-2.5 p-6">
        <div className="flex items-end gap-3">
          <div className="flex flex-col gap-1.5 flex-1">
            <span className="text-[11px] font-medium text-muted">
              {t('changelog_draft_from')}
            </span>
            <Dropdown
              align="left"
              trigger={({ open, toggle }) => (
                <button
                  type="button"
                  aria-expanded={open}
                  onClick={toggle}
                  className="focus-ring cursor-pointer w-full inline-flex items-center justify-between gap-2 h-9 px-3 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:border-accent-dim transition-colors"
                >
                  <span className="font-mono text-[11px] truncate">
                    {from || '…'}
                  </span>
                  <IconGitBranch className="w-3 h-3 shrink-0 opacity-60" />
                </button>
              )}
              items={tags.map((tag) => ({
                key: tag,
                label: tag,
                active: from === tag,
                onClick: () => setFrom(tag),
              }))}
            />
          </div>
          <span className="text-xs text-muted pb-2.5">→</span>
          <div className="flex flex-col gap-1.5 flex-1">
            <span className="text-[11px] font-medium text-muted">
              {t('changelog_draft_to')}
            </span>
            <Dropdown
              align="left"
              trigger={({ open, toggle }) => (
                <button
                  type="button"
                  aria-expanded={open}
                  onClick={toggle}
                  className="focus-ring cursor-pointer w-full inline-flex items-center justify-between gap-2 h-9 px-3 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:border-accent-dim transition-colors"
                >
                  <span className="font-mono text-[11px] truncate">{to}</span>
                  <IconGitBranch className="w-3 h-3 shrink-0 opacity-60" />
                </button>
              )}
              items={[
                {
                  key: HEAD,
                  label: HEAD,
                  active: to === HEAD,
                  onClick: () => setTo(HEAD),
                },
                ...tags.map((tag) => ({
                  key: tag,
                  label: tag,
                  active: to === tag,
                  onClick: () => setTo(tag),
                })),
              ]}
            />
          </div>
            <motion.button
              type="button"
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.94 }}
              onClick={generate}
              disabled={loading || !from || !to}
              title={t('changelog_draft_generate')}
              className="focus-ring cursor-pointer h-9 w-9 rounded-item bg-accent hover:bg-accent-bright disabled:opacity-40 text-white flex items-center justify-center transition-colors"
            >
              <IconRefresh
                className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`}
              />
            </motion.button>
        </div>

        {draft && (
          <>
            <div className="flex items-center gap-1.5 mt-2">
              <IconRocket className="w-3.5 h-3.5 text-accent-bright" />
              <span className="text-xs font-medium text-ink">
                {t('changelog_draft_commits', { count: draft.count })}
              </span>
              <span className="text-[11px] font-mono text-muted/60">
                {draft.from} → {draft.to}
              </span>
            </div>

            <div className="flex flex-col gap-1.5 max-h-64 overflow-y-auto pr-1">
              {rows.length === 0 && draft.skipped.length === 0 && (
                <p className="text-xs text-muted/70 italic py-3 text-center">
                  {t('changelog_draft_none')}
                </p>
              )}
              {rows.map((row, i) => (
                <div key={row.key} className="flex items-center gap-2">
                  <div className="flex rounded-btn border border-outline/50 overflow-hidden shrink-0">
                    {CATEGORIES.map((c) => (
                      <button
                        key={c.value}
                        type="button"
                        onClick={() => setRow(i, { category: c.value })}
                        className={`focus-ring cursor-pointer px-2 py-1.5 transition-colors ${
                          row.category === c.value
                            ? c.activeClass
                            : 'text-muted hover:bg-raised/50'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full inline-block mr-1 align-middle ${c.dotClass}`}
                        />
                        {t(c.value)}
                      </button>
                    ))}
                  </div>
                  <input
                    value={row.text}
                    onChange={(e) => setRow(i, { text: e.target.value })}
                    className="focus-ring flex-1 min-w-0 bg-base border border-outline/50 rounded-btn px-3 py-1.5 text-xs text-ink focus:border-accent-dim transition-colors"
                  />
                  {row.hash && (
                    <span className="font-mono text-[10px] text-muted/50 shrink-0">
                      {row.hash}
                    </span>
                  )}
                </div>
              ))}
            </div>

            {draft.skipped.length > 0 && (
              <div className="mt-2 pt-3 border-t border-outline/40">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-muted/60">
                  {t('changelog_draft_skipped')}
                </span>
                <div className="flex flex-col gap-1 mt-1.5">
                  {draft.skipped.map((s, i) => (
                    <div
                      key={s.hash}
                      className="flex items-center gap-2 text-[11px] text-muted/70"
                    >
                      <button
                        type="button"
                        role="checkbox"
                        aria-checked={Boolean(skippedChecked[i])}
                        onClick={() => toggleSkipped(i)}
                        aria-label={t('changelog_draft_include')}
                        className={`focus-ring cursor-pointer w-4 h-4 rounded-item border flex items-center justify-center transition-colors shrink-0 ${
                          skippedChecked[i]
                            ? 'bg-accent border-accent text-white'
                            : 'border-muted/40 hover:border-accent/60'
                        }`}
                      >
                        {skippedChecked[i] && <IconCheck className="w-2.5 h-2.5" />}
                      </button>
                      <span className="font-mono text-[10px] shrink-0">{s.hash}</span>
                      <span className="truncate">{s.subject}</span>
                      <span className="ml-auto shrink-0 text-[10px] uppercase tracking-wide text-muted/40">
                        {s.reason}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}

        <div className="flex gap-4 mt-3">
          <div className="flex flex-col gap-2 flex-1">
            <label className="text-xs font-medium text-muted">
              {t('changelog_version_label')}
            </label>
            <input
              value={version}
              onChange={(e) => setVersion(e.target.value)}
              className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2 text-sm text-ink focus:border-accent-dim transition-colors"
              placeholder={draft?.next_version || t('changelog_version_placeholder')}
            />
          </div>
          <div className="flex flex-col gap-2 flex-1">
            <label className="text-xs font-medium text-muted">
              {t('changelog_date_label')}
            </label>
            <input
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2 text-sm text-ink focus:border-accent-dim transition-colors"
            />
          </div>
        </div>
      </div>
    </ModalShell>
  )
}
