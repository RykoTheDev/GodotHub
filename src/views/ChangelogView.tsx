import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { AnimatePresence, motion } from 'framer-motion'
import { useChangelog } from '../hooks/useChangelog'
import { useSettings } from '../hooks/useSettings'
import { ChangelogEntryModal } from '../components/modals/ChangelogEntryModal'
import { ReleaseNotesDraftModal } from '../components/modals/ReleaseNotesDraftModal'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ViewHeader } from '../components/reusables/ViewHeader'
import {
  IconAlertTriangle,
  IconBookOpen,
  IconClock,
  IconPencil,
  IconPlus,
  IconRocket,
  IconTrash,
} from '../lib/icons'
import { formatLocaleDate } from '../lib/locale'
import type { ChangelogEntry, ChangelogNote } from '../types'

const IS_DEV = import.meta.env.DEV

function formatDate(raw: string): string {
  if (!raw) return ''
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return formatLocaleDate(d, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

const GROUPS: {
  key: ChangelogNote['category']
  dot: string
  label: string
  chip: string
}[] = [
  {
    key: 'add',
    dot: 'bg-mint',
    label: 'text-mint',
    chip: 'bg-mint/10 text-mint',
  },
  {
    key: 'fix',
    dot: 'bg-danger',
    label: 'text-danger',
    chip: 'bg-danger/10 text-danger ',
  },
  {
    key: 'improve',
    dot: 'bg-accent-bright',
    label: 'text-accent-bright',
    chip: 'bg-accent/15 text-accent-bright',
  },
]

function EntryCard({
  entry,
  isLast,
  onEdit,
  onDelete,
}: {
  entry: ChangelogEntry
  isLast: boolean
  onEdit: () => void
  onDelete: () => void
}) {
  const { t } = useTranslation('changelog')
  const noteCount = entry.notes.length
  const issueCount = entry.known_issues?.length ?? 0

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
      className="group relative flex gap-5"
    >
      <div className="flex flex-col items-center pt-2 shrink-0">
        <span className="w-3 h-3 rounded-full bg-accent shrink-0 ring-4 ring-accent/15" />
        {!isLast && <span className="w-px flex-1 bg-line mt-2" />}
      </div>

      <div className="flex-1 min-w-0 pb-9">
        <div className="rounded-item border border-outline/50 bg-overlay p-5 hover:border-accent-dim/70 hover:bg-raised transition-colors">
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              <h3 className="font-display font-semibold text-lg text-ink truncate">
                {entry.version}
              </h3>
              {entry.date && (
                <p className="text-[11px] text-muted mt-1 flex items-center gap-1">
                  <IconClock className="w-3 h-3" />
                  {formatDate(entry.date)}
                </p>
              )}
            </div>
            {IS_DEV && (
              <div className="flex items-center gap-1 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={onEdit}
                  aria-label={`Edit ${entry.version}`}
                  className="focus-ring cursor-pointer p-2 rounded-btn text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconPencil className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={onDelete}
                  aria-label={`Delete ${entry.version}`}
                  className="focus-ring cursor-pointer p-2 rounded-btn text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                >
                  <IconTrash className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>

          {(noteCount > 0 || issueCount > 0) && (
            <div className="mt-3 flex items-center gap-1.5 flex-wrap">
              {GROUPS.map((g) => {
                const count = entry.notes.filter(
                  (n) => n.category === g.key,
                ).length
                if (!count) return null
                return (
                  <span
                    key={g.key}
                    className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-tag text-[10px] font-semibold ${g.chip}`}
                  >
                    <span className={`w-1.5 h-1.5 rounded-full ${g.dot}`} />
                    {count} {t(g.key)}
                  </span>
                )
              })}
              {issueCount > 0 && (
                <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-tag text-[10px] font-semibold bg-amber/10 text-amber">
                  <IconAlertTriangle className="w-2.5 h-2.5" />
                  {issueCount} {t('known_issues')}
                </span>
              )}
            </div>
          )}

          {entry.notes.length > 0 && (
            <div className="mt-4 flex flex-col gap-3">
              {GROUPS.map((g) => {
                const items = entry.notes.filter(
                  (n) => n.category === g.key,
                )
                if (!items.length) return null
                return (
                  <div key={g.key}>
                    <p
                      className={`text-[10px] font-semibold uppercase tracking-wider mb-1.5 ${g.label}`}
                    >
                      {t(g.key)}
                    </p>
                    <ul className="flex flex-col gap-1.5">
                      {items.map((n, i) => (
                        <li
                          key={i}
                          className="text-xs text-muted leading-relaxed flex gap-2"
                        >
                          <span
                            className={`shrink-0 mt-[3px] w-1.5 h-1.5 rounded-full ${g.dot}`}
                          />
                          <span className="min-w-0">{n.text}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )
              })}
            </div>
          )}

          {entry.known_issues?.length > 0 && (
            <div className="mt-4 pt-4 border-t border-outline/40">
              <p className="text-[10px] font-semibold uppercase tracking-wider mb-1.5 text-amber">
                <IconAlertTriangle className="w-3 h-3 inline -mt-0.5 mr-1" />
                {t('known_issues')}
              </p>
              <ul className="flex flex-col gap-1.5">
                {entry.known_issues.map((issue, i) => (
                  <li
                    key={i}
                    className="text-xs text-muted leading-relaxed flex gap-2"
                  >
                    <span className="shrink-0 mt-[3px] w-1.5 h-1.5 rounded-full bg-amber" />
                    <span className="min-w-0">{issue}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </div>
    </motion.div>
  )
}

export function ChangelogView({
  connected = false,
}: {
  connected?: boolean
}) {
  const { t } = useTranslation('changelog')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const { entries, loading, addEntry, updateEntry, removeEntry } =
    useChangelog()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingEntry, setEditingEntry] = useState<ChangelogEntry | null>(null)
  const [confirmingDeleteId, setConfirmingDeleteId] = useState<string | null>(
    null,
  )
  const [draftOpen, setDraftOpen] = useState(false)
  const [prefill, setPrefill] = useState<{
    version?: string
    date?: string
    notes?: ChangelogNote[]
  } | null>(null)

  const openCreate = () => {
    setEditingEntry(null)
    setPrefill(null)
    setModalOpen(true)
  }
  const openFromDraft = (
    notes: ChangelogNote[],
    version: string,
    date: string,
  ) => {
    setDraftOpen(false)
    setEditingEntry(null)
    setPrefill({ version, date, notes })
    setModalOpen(true)
  }
  const openEdit = (entry: ChangelogEntry) => {
    setEditingEntry(entry)
    setModalOpen(true)
  }

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col">
      <ViewHeader
        connected={connected}
        className="mb-4"
        title={t('changelog_title')}
        actions={
          IS_DEV ? (
            <div className="flex items-center gap-2">
              <motion.button
                type="button"
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => setDraftOpen(true)}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-overlay border border-outline/50 text-muted hover:text-ink hover:border-accent-dim text-xs font-medium transition-colors"
              >
                <IconRocket className="w-3.5 h-3.5" />
                {tc('changelog_generate_from_git')}
              </motion.button>
              <motion.button
                type="button"
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={openCreate}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-4 rounded-item bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
              >
                <IconPlus className="w-3.5 h-3.5" />
                {tc('add_entry')}
              </motion.button>
            </div>
          ) : undefined
        }
      >
        <p className="text-xs text-muted">{t('changelog_subtitle')}</p>
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
      >
        <div className={`h-full ${connected ? 'pl-3' : ''} pr-5 pb-4`}>
          {loading && entries.length === 0 ? (
            <div className="flex flex-col gap-4">
              {Array.from({ length: 3 }).map((_, i) => (
                <div
                  key={i}
                  className="h-28 rounded-item border border-outline/50 bg-overlay animate-pulse"
                />
              ))}
            </div>
          ) : entries.length === 0 ? (
            <div className="border border-dashed border-outline/50 rounded-item py-24 flex flex-col items-center gap-4 text-center">
              <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
                <IconBookOpen className="w-5 h-5 text-muted" />
              </div>
              <p className="text-sm text-muted max-w-xs leading-relaxed">
                {t('no_entries')}
              </p>
            </div>
          ) : (
            <div className="flex flex-col">
              <AnimatePresence>
                {entries.map((entry, i) => (
                  <EntryCard
                    key={entry.id}
                    entry={entry}
                    isLast={i === entries.length - 1}
                    onEdit={() => openEdit(entry)}
                    onDelete={() => setConfirmingDeleteId(entry.id)}
                  />
                ))}
              </AnimatePresence>
            </div>
          )}
        </div>
      </OverlayScrollArea>

      <AnimatePresence>
        {modalOpen && (
          <ChangelogEntryModal
            entry={editingEntry ?? undefined}
            initial={prefill ?? undefined}
            onClose={() => {
              setModalOpen(false)
              setPrefill(null)
            }}
            onSave={async (version, date, notes, knownIssues) => {
              if (editingEntry)
                await updateEntry(
                  editingEntry.id,
                  version,
                  date,
                  notes,
                  knownIssues,
                )
              else await addEntry(version, date, notes, knownIssues)
              setPrefill(null)
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {draftOpen && (
          <ReleaseNotesDraftModal
            onClose={() => setDraftOpen(false)}
            onUseDraft={openFromDraft}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingDeleteId && (
          <ConfirmDialog
            title={t('delete_entry_title')}
            description={t('delete_entry_desc')}
            confirmLabel={t('delete')}
            variant="danger"
            onConfirm={async () => {
              await removeEntry(confirmingDeleteId)
              setConfirmingDeleteId(null)
            }}
            onCancel={() => setConfirmingDeleteId(null)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
