import { useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { ModalShell } from './ModalShell'
import { IconPlus, IconTags, IconX } from '../../lib/icons'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import type { Project } from '../../types'

interface Props {
  projects: Project[]
  onClose: () => void
  onApplied: () => void
}

export function BulkTagModal({ projects, onClose, onApplied }: Props) {
  const { t } = useTranslation('common')
  const [tagInput, setTagInput] = useState('')

  const allTags = useMemo(() => {
    const map = new Map<string, number>()
    for (const p of projects) {
      for (const tag of p.tags) {
        map.set(tag, (map.get(tag) ?? 0) + 1)
      }
    }
    return [...map.entries()].sort((a, b) => b[1] - a[1])
  }, [projects])

  const apply = async (fn: (tags: string[]) => string[]) => {
    for (const p of projects) {
      try {
        await api.saveProjectTags(p.id, p.path, fn(p.tags))
      } catch {
        // Keep going even if a single project fails.
      }
    }
    onApplied()
  }

  const addTag = async () => {
    const tag = tagInput.trim()
    if (!tag) return
    setTagInput('')
    await apply((tags) => (tags.includes(tag) ? tags : [...tags, tag]))
    pushToast('success', t('tags_added_to_selection', { count: projects.length }))
  }

  const removeTag = async (tag: string) => {
    await apply((tags) => tags.filter((x) => x !== tag))
    pushToast('success', t('tags_removed_from_selection', { count: projects.length }))
  }

  return (
    <ModalShell
      icon={<IconTags className="w-5 h-5" />}
      title={t('bulk_tags_title')}
      description={t('bulk_tags_desc')}
      maxWidth="max-w-md"
      onClose={onClose}
    >
      <div className="flex flex-col gap-4 p-6 pt-0">
        <div className="flex gap-2">
          <input
            type="text"
            value={tagInput}
            onChange={(e) => setTagInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') void addTag()
            }}
            placeholder={t('tag_input_placeholder')}
            className="focus-ring flex-1 min-w-0 bg-base border border-outline/50 rounded-item px-3 py-2 text-xs text-ink placeholder:text-muted focus:border-accent-dim outline-none transition-colors"
          />
          <button
            type="button"
            onClick={() => void addTag()}
            disabled={!tagInput.trim()}
            className="focus-ring cursor-pointer shrink-0 inline-flex items-center gap-1.5 px-3 rounded-item bg-accent/15 border border-accent/40 text-accent-bright hover:bg-accent/25 text-xs font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <IconPlus className="w-3 h-3" />
            {t('add_tag')}
          </button>
        </div>

        {allTags.length === 0 ? (
          <p className="text-[11px] text-muted/50">{t('no_common_tags')}</p>
        ) : (
          <div className="flex flex-col gap-1">
            {allTags.map(([tag, count]) => (
              <div
                key={tag}
                className="flex items-center gap-2 px-2.5 py-1.5 rounded-item bg-raised border border-outline/50"
              >
                <span className="flex-1 min-w-0 text-xs font-mono text-ink truncate">
                  {tag}
                </span>
                <span className="text-[10px] font-mono text-muted/50 tabular-nums shrink-0">
                  {count}/{projects.length}
                </span>
                <button
                  type="button"
                  onClick={() => void removeTag(tag)}
                  aria-label={t('remove_tag')}
                  className="focus-ring cursor-pointer shrink-0 p-1 rounded text-muted/60 hover:text-danger hover:bg-danger/10 transition-colors"
                >
                  <IconX className="w-3 h-3" />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </ModalShell>
  )
}