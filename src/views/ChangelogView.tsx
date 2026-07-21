import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useChangelog } from '../hooks/useChangelog'
import { ChangelogEntryModal } from '../components/modals/ChangelogEntryModal'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import {
  IconBookOpen,
  IconPencil,
  IconPlus,
  IconTrash,
} from '../components/Icons'
import type { ChangelogEntry, ChangelogNote } from '../types'

const IS_DEV = import.meta.env.DEV

function formatDate(raw: string): string {
  if (!raw) return ''
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  return d.toLocaleDateString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

const GROUPS: {
  key: ChangelogNote['category']
  label: string
  color: string
}[] = [
  { key: 'add', label: 'Added', color: 'text-mint' },
  { key: 'fix', label: 'Fixed', color: 'text-danger' },
  { key: 'improve', label: 'Improved', color: 'text-accent-bright' },
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
  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 8 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-40px' }}
      exit={{ opacity: 0 }}
      className="group relative flex gap-5"
    >
      <div className="flex flex-col items-center pt-1.5 shrink-0">
        <span className="w-2.5 h-2.5 rounded-full bg-accent shrink-0" />
        {!isLast && <span className="w-px flex-1 bg-line mt-1.5" />}
      </div>

      <div className="flex-1 min-w-0 pb-9 -mt-1">
        <div className="rounded-xl border border-line bg-surface p-5 hover:border-accent-dim transition-colors">
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              <h3 className="font-display font-semibold truncate">
                {entry.version}
              </h3>
              {entry.date && (
                <p className="text-[11px] text-muted mt-0.5">
                  {formatDate(entry.date)}
                </p>
              )}
            </div>
            {IS_DEV && (
              <div className="flex items-center gap-1 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={onEdit}
                  aria-label={`Edit ${entry.version}`}
                  className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  <IconPencil className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={onDelete}
                  aria-label={`Delete ${entry.version}`}
                  className="focus-ring cursor-pointer p-2 rounded-lg text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                >
                  <IconTrash className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
          {entry.notes.length > 0 && (
            <div className="mt-3.5 flex flex-col gap-3">
              {GROUPS.map((g) => {
                const items = entry.notes.filter((n) => n.category === g.key)
                if (!items.length) return null
                return (
                  <div key={g.key}>
                    <p
                      className={`text-[10px] font-semibold uppercase tracking-wide mb-1 ${g.color}`}
                    >
                      {g.label}
                    </p>
                    <ul className="flex flex-col gap-1.5">
                      {items.map((n, i) => (
                        <li
                          key={i}
                          className="text-xs text-muted leading-relaxed flex gap-2"
                        >
                          <span className={`shrink-0 ${g.color}`}>•</span>
                          {n.text}
                        </li>
                      ))}
                    </ul>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </motion.div>
  )
}

export function ChangelogView() {
  const { entries, loading, addEntry, updateEntry, removeEntry } =
    useChangelog()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingEntry, setEditingEntry] = useState<ChangelogEntry | null>(null)
  const [confirmingDeleteId, setConfirmingDeleteId] = useState<string | null>(
    null,
  )

  const openCreate = () => {
    setEditingEntry(null)
    setModalOpen(true)
  }
  const openEdit = (entry: ChangelogEntry) => {
    setEditingEntry(entry)
    setModalOpen(true)
  }

  return (
    <div className="p-10 pt-15 max-w-8xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="font-body font-semibold text-3xl tracking-tight">
            CHANGELOG
          </h2>
          <p className="text-xs text-muted">A history of GodotHub updates.</p>
        </div>
        {IS_DEV && (
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={openCreate}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
          >
            <span className="icon-wiggle inline-flex">
              <IconPlus className="w-4 h-4" />
            </span>
            Add Entry
          </motion.button>
        )}
      </div>

      {loading && entries.length === 0 ? (
        <div className="flex flex-col gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div
              key={i}
              className="h-28 rounded-xl border border-line bg-surface animate-pulse"
            />
          ))}
        </div>
      ) : entries.length === 0 ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
            <IconBookOpen className="w-5 h-5 text-muted" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            No changelog entries yet
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

      <AnimatePresence>
        {modalOpen && (
          <ChangelogEntryModal
            entry={editingEntry ?? undefined}
            onClose={() => setModalOpen(false)}
            onSave={async (version, date, notes) => {
              if (editingEntry)
                await updateEntry(editingEntry.id, version, date, notes)
              else await addEntry(version, date, notes)
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmingDeleteId && (
          <ConfirmDialog
            title="Delete changelog entry?"
            description="This removes the entry permanently. This can't be undone."
            confirmLabel="Delete"
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
