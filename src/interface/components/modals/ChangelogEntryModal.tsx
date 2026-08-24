import { useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { ModalShell } from './ModalShell'
import {
  IconAlertTriangle,
  IconPencil,
  IconPlus,
  IconX,
} from '../../lib/icons'

import type { ChangelogEntry, ChangelogNote } from '../../../types'

interface Props {
  entry?: ChangelogEntry
  initial?: {
    version?: string
    date?: string
    notes?: ChangelogNote[]
  }
  onClose: () => void
  onSave: (
    version: string,
    date: string,
    notes: ChangelogNote[],
    knownIssues: string[],
  ) => Promise<void>
}

const CATEGORIES: {
  value: ChangelogNote['category']
  label: string
  activeClass: string
  dotClass: string
}[] = [
  { value: 'add', label: 'add', activeClass: 'bg-mint/15 text-mint', dotClass: 'bg-mint' },
  { value: 'fix', label: 'fix', activeClass: 'bg-danger/15 text-danger', dotClass: 'bg-danger' },
  {
    value: 'improve',
    label: 'improve',
    activeClass: 'bg-accent/15 text-accent-bright',
    dotClass: 'bg-accent-bright',
  },
]

const todayIso = () => new Date().toISOString().slice(0, 10)

export function ChangelogEntryModal({ entry, initial, onClose, onSave }: Props) {
  const { t } = useTranslation('common')
  const [version, setVersion] = useState(entry?.version ?? initial?.version ?? '')
  const [date, setDate] = useState(entry?.date ?? initial?.date ?? todayIso())
  const [notes, setNotes] = useState<ChangelogNote[]>(() => {
    if (entry?.notes.length) return entry.notes
    if (initial?.notes?.length) return initial.notes
    return [{ category: 'add', text: '' }]
  })
  const [knownIssues, setKnownIssues] = useState<string[]>(
    entry?.known_issues?.length ? entry.known_issues : [],
  )
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  const setNote = (i: number, patch: Partial<ChangelogNote>) =>
    setNotes((prev) =>
      prev.map((n, idx) => (idx === i ? { ...n, ...patch } : n)),
    )
  const addNote = () =>
    setNotes((prev) => [...prev, { category: 'add', text: '' }])
  const removeNote = (i: number) =>
    setNotes((prev) =>
      prev.length === 1 ? prev : prev.filter((_, idx) => idx !== i),
    )

  const setIssue = (i: number, text: string) =>
    setKnownIssues((prev) =>
      prev.map((issue, idx) => (idx === i ? text : issue)),
    )
  const addIssue = () => setKnownIssues((prev) => [...prev, ''])
  const removeIssue = (i: number) =>
    setKnownIssues((prev) => prev.filter((_, idx) => idx !== i))

  const submit = async () => {
    if (!version.trim()) {
      setError(t('changelog_error_no_version'))
      return
    }
    setBusy(true)
    setError(null)
    try {
      await onSave(version, date, notes, knownIssues)
      onClose()
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <ModalShell
      icon={<IconPencil className="w-5 h-5 text-accent-bright" />}
      title={entry ? t('edit_entry') : t('new_entry')}
      description={t('changelog_entry_desc')}
      maxWidth="max-w-lg"
      onClose={onClose}
      showClose={false}
      footer={
        <>
          {error && <p className="text-xs text-danger">{error}</p>}
          <div className="ml-auto flex justify-end gap-2.5">
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={onClose}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
            >
              {t('cancel')}
            </motion.button>
            <motion.button
              whileHover={busy ? undefined : { y: -1 }}
              whileTap={busy ? undefined : { scale: 0.96 }}
              onClick={submit}
              disabled={busy}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors"
            >
              {busy ? t('saving') : entry ? t('save_changes') : t('add_entry')}
            </motion.button>
          </div>
        </>
      }
    >
        <div className="flex flex-col gap-2.5 p-6">
          <div className="flex gap-4">
            <div className="flex flex-col gap-2 flex-1">
              <label className="text-xs font-medium text-muted">
                {t('changelog_version_label')}
              </label>
              <input
                autoFocus
                value={version}
                onChange={(e) => setVersion(e.target.value)}
                className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm text-ink focus:border-accent-dim transition-colors"
                placeholder={t('changelog_version_placeholder')}
              />
            </div>
            <div className="flex flex-col gap-2 flex-1">
              <label className="text-xs font-medium text-muted">
                {t('changelog_date_label')}
              </label>
              <input
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="focus-ring bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm text-ink focus:border-accent-dim transition-colors"
                placeholder={t('changelog_date_placeholder')}
              />
            </div>
          </div>

          <span className="text-xs font-medium text-muted mt-3">
            {t('changelog_what_changed')}
          </span>
          <div className="flex flex-col gap-2">
            {notes.map((note, i) => (
              <div key={i} className="flex items-center gap-2">
                <div className="flex rounded-btn border border-outline/50 overflow-hidden shrink-0">
                  {CATEGORIES.map((c) => (
                      <button
                        key={c.value}
                        type="button"
                        onClick={() => setNote(i, { category: c.value })}
                        title={t(c.label)}
                        className={`focus-ring cursor-pointer px-2 py-1.5 text-[10px] font-medium transition-colors ${
                          note.category === c.value
                            ? c.activeClass
                            : 'text-muted hover:bg-raised/50'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full inline-block mr-1 align-middle ${c.dotClass}`}
                        />
                        {t(c.label)}
                      </button>
                  ))}
                </div>
                <input
                  value={note.text}
                  onChange={(e) => setNote(i, { text: e.target.value })}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      addNote()
                    }
                  }}
                  className="focus-ring flex-1 bg-base border border-outline/50 rounded-btn px-3.5 py-2 text-sm text-ink focus:border-accent-dim transition-colors"
                  placeholder={t('changelog_placeholder_note')}
                />
                {notes.length > 1 && (
                  <button
                    type="button"
                    onClick={() => removeNote(i)}
                    aria-label={t('changelog_remove_line_aria')}
                    className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                  >
                    <IconX className="w-3 h-3" />
                  </button>
                )}
              </div>
            ))}
          </div>
          <motion.button
            type="button"
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={addNote}
            className="focus-ring cursor-pointer self-start flex items-center gap-1.5 px-3 py-1.5 rounded-btn text-xs text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            <IconPlus className="w-3 h-3" />
            {t('changelog_add_line')}
          </motion.button>

          <div className="flex items-center gap-1.5 mt-4">
            <IconAlertTriangle className="w-3.5 h-3.5 text-amber" />
            <span className="text-xs font-medium text-muted">
              {t('changelog_known_issues')}
            </span>
          </div>
          <div className="flex flex-col gap-2">
            {knownIssues.length === 0 ? (
              <p className="text-[11px] text-muted/60 italic">
                {t('changelog_known_issues_none')}
              </p>
            ) : (
              knownIssues.map((issue, i) => (
                <div key={i} className="flex items-center gap-2">
                  <IconAlertTriangle className="w-3.5 h-3.5 text-amber shrink-0" />
                  <input
                    value={issue}
                    onChange={(e) => setIssue(i, e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        addIssue()
                      }
                    }}
                    className="focus-ring flex-1 bg-base border border-outline/50 rounded-btn px-3.5 py-2 text-sm text-ink focus:border-amber/60 transition-colors"
                    placeholder={t('changelog_known_issue_placeholder')}
                  />
                  <button
                    type="button"
                    onClick={() => removeIssue(i)}
                    aria-label={t('changelog_remove_known_issue_aria')}
                    className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                  >
                    <IconX className="w-3 h-3" />
                  </button>
                </div>
              ))
            )}
          </div>
          <motion.button
            type="button"
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={addIssue}
            className="focus-ring cursor-pointer self-start flex items-center gap-1.5 px-3 py-1.5 rounded-btn text-xs text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            <IconPlus className="w-3 h-3" />
            {t('changelog_add_known_issue')}
          </motion.button>
        </div>
    </ModalShell>
  )
}
