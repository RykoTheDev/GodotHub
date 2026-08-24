import { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Project } from '../../../types'
import { api } from '../../../lib/api'
import { ModalShell } from './ModalShell'

import { IconX, IconPlus, IconCheck, IconPencil, IconTags } from '../../lib/icons'

interface Props {
  project: Project
  onClose: () => void
  onSaved: (project: Project) => void
}

const TAG_COLORS = [
  '#457ff2', '#f28b45', '#45c97f', '#e74c8a', '#a855f7',
  '#22d3ee', '#f59e0b', '#ef4444', '#10b981', '#6366f1',
  '#ec4899', '#14b8a6', '#f97316', '#8b5cf6', '#06b6d4',
  '#84cc16', '#d946ef', '#0ea5e9', '#eab308', '#3b82f6',
]

function tagColor(tag: string): string {
  let hash = 0
  for (let i = 0; i < tag.length; i++) {
    hash = tag.charCodeAt(i) + ((hash << 5) - hash)
  }
  return TAG_COLORS[Math.abs(hash) % TAG_COLORS.length]
}

export function TagManagerModal({ project, onClose, onSaved }: Props) {
  const { t } = useTranslation('common')
  const [tags, setTags] = useState<string[]>(project.tags)
  const [newTag, setNewTag] = useState('')
  const [editingIndex, setEditingIndex] = useState<number | null>(null)
  const [editValue, setEditValue] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const editInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    setTimeout(() => inputRef.current?.focus(), 100)
  }, [])

  useEffect(() => {
    if (editingIndex !== null) {
      setTimeout(() => editInputRef.current?.focus(), 50)
    }
  }, [editingIndex])

  const addTag = () => {
    const trimmed = newTag.trim()
    if (!trimmed) return
    if (tags.some((t) => t.toLowerCase() === trimmed.toLowerCase())) {
      setError(t('tag_already_exists'))
      return
    }
    setTags([...tags, trimmed])
    setNewTag('')
    setError(null)
    setTimeout(() => inputRef.current?.focus(), 10)
  }

  const removeTag = (index: number) => {
    setTags(tags.filter((_, i) => i !== index))
    if (editingIndex === index) {
      setEditingIndex(null)
      setEditValue('')
    }
  }

  const startEdit = (index: number) => {
    setEditingIndex(index)
    setEditValue(tags[index])
  }

  const saveEdit = () => {
    if (editingIndex === null) return
    const trimmed = editValue.trim()
    if (!trimmed) {
      removeTag(editingIndex)
      return
    }
    if (tags.some((t, i) => i !== editingIndex && t.toLowerCase() === trimmed.toLowerCase())) {
      setError(t('tag_already_exists'))
      return
    }
    setTags(tags.map((t, i) => (i === editingIndex ? trimmed : t)))
    setEditingIndex(null)
    setEditValue('')
    setError(null)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      if (editingIndex !== null) {
        saveEdit()
      } else {
        addTag()
      }
    }
    if (e.key === 'Escape') {
      if (editingIndex !== null) {
        setEditingIndex(null)
        setEditValue('')
      } else {
        onClose()
      }
    }
  }

  const handleSave = async () => {
    setSaving(true)
    setError(null)
    try {
      const updated = await api.saveProjectTags(project.id, project.path, tags)
      onSaved(updated)
      onClose()
    } catch (e) {
      setError(String(e))
    } finally {
      setSaving(false)
    }
  }

  return (
    <ModalShell
      icon={<IconTags className="w-5 h-5 text-accent-bright" />}
      title={t('manage_tags')}
      description={project.name}
      maxWidth="max-w-lg"
      onClose={onClose}
      showClose={false}
      onKeyDown={handleKeyDown}
      footer={
        <>
          <span className="text-xs text-muted/60">
            {tags.length === 0
              ? t('no_tags')
              : t('tag_count', { count: tags.length })}
          </span>
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
              whileHover={saving ? undefined : { y: -1 }}
              whileTap={saving ? undefined : { scale: 0.96 }}
              onClick={handleSave}
              disabled={saving}
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-5 py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors"
            >
              {saving ? (
                <>
                  <div className="w-3.5 h-3.5 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                  {t('saving')}
                </>
              ) : (
                <>
                  <IconCheck className="w-3.5 h-3.5" />
                  {t('save')}
                </>
              )}
            </motion.button>
          </div>
        </>
      }
    >
      <div className="p-6 pt-0 flex flex-col gap-4">
        <AnimatePresence>
          {error && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="px-3 py-2 rounded-lg bg-danger/10 border border-danger/20 text-danger text-xs"
            >
              {error}
            </motion.div>
          )}
        </AnimatePresence>

        <div className="flex items-center gap-2">
          <input
            ref={inputRef}
            type="text"
            value={newTag}
            onChange={(e) => setNewTag(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                addTag()
              }
              if (e.key === 'Escape') {
                onClose()
              }
            }}
            placeholder={t('tag_input_placeholder')}
            className="focus-ring flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors outline-none"
          />
          <motion.button
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.96 }}
            onClick={addTag}
            disabled={!newTag.trim()}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-40 text-sm font-medium text-white transition-colors shrink-0"
          >
            <IconPlus className="w-3.5 h-3.5" />
            {t('add')}
          </motion.button>
        </div>

        <div className="flex flex-col gap-2 max-h-64 overflow-y-auto min-h-0">
          {tags.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 gap-2 text-muted/60">
              <IconTags className="w-8 h-8 opacity-40" />
              <p className="text-sm">{t('no_tags')}</p>
            </div>
          ) : (
            tags.map((tag, index) => {
              const color = tagColor(tag)
              const isEditing = editingIndex === index
              return (
                <motion.div
                  key={`${tag}-${index}`}
                  initial={{ opacity: 0, x: -8 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 8, height: 0 }}
                  transition={{ duration: 0.15 }}
                  className="group flex items-center gap-2 px-3 py-2 rounded-xl bg-raised border border-line/60 hover:border-accent-dim/40 transition-colors"
                >

                  <span
                    className="w-2.5 h-2.5 rounded-full shrink-0 ring-1 ring-black/10"
                    style={{ backgroundColor: color }}
                  />

                  {isEditing ? (
                    <input
                      ref={editInputRef}
                      type="text"
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault()
                          saveEdit()
                        }
                        if (e.key === 'Escape') {
                          setEditingIndex(null)
                          setEditValue('')
                        }
                      }}
                      onBlur={saveEdit}
                      className="focus-ring flex-1 bg-base border border-accent/40 rounded-md px-2 py-1 text-sm font-medium font-mono outline-none transition-colors"
                      style={{ color }}
                      autoFocus
                    />
                  ) : (
                    <span
                        title={t('tag_rename_hint')}
                        className="block text-sm font-medium font-mono cursor-pointer py-1 truncate flex-1 min-w-0"
                        style={{ color }}
                        onClick={() => startEdit(index)}
                      >
                        {tag}
                      </span>
                  )}

                  <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    {!isEditing && (
                      <button
                        onClick={() => startEdit(index)}
                        className="focus-ring cursor-pointer p-1.5 rounded-md text-muted/50 hover:text-ink hover:bg-base transition-colors"
                        aria-label={t('tag_rename_aria')}
                      >
                        <IconPencil className="w-3 h-3" />
                      </button>
                    )}
                    <button
                      onClick={() => removeTag(index)}
                      className="focus-ring cursor-pointer p-1.5 rounded-md text-muted/50 hover:text-danger hover:bg-danger/10 transition-colors"
                      aria-label={t('tag_remove_aria', { tag })}
                    >
                      <IconX className="w-3 h-3" />
                    </button>
                  </div>
                </motion.div>
              )
            })
          )}
        </div>
      </div>
    </ModalShell>
  )
}
