import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion, type Transition } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Category, GitStatus, InstalledGodotVersion, Project, ProjectViewMode } from '../../types'
import { getCardViewSettings } from '../../lib/cardViewSettings'
import { api, getCachedProjectIcon, getCachedProjectName } from '../../lib/api'
import {
  formatLastOpened,
} from '../../lib/lastOpened'
import { formatDuration } from '../../lib/duration'
import { effectiveTotalMs } from '../../lib/projectSort'
import { tagColor } from '../../lib/colors'
import { isReducedMotion } from '../../lib/appearance'
import { useSettings } from '../../hooks/useSettings'
import { useProjectResolutionEpoch } from '../../hooks/useProjectResolutionEpoch'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { TagManagerModal } from '../modals/TagManagerModal'
import { LaunchArgsModal } from '../modals/LaunchArgsModal'
import { Dropdown } from '../ui/Dropdown'

import { TimeTrackerModal } from '../modals/TimeTrackerModal'
import { SaveAsTemplateModal } from '../modals/SaveAsTemplateModal'
import { ProjectSizeModal } from '../modals/ProjectSizeModal'
import { OpenButton } from '../reusables/OpenButton'
import { Tooltip } from '../reusables/Tooltip'
import {
  IconCheckCircle,
  IconChevronDown,
  IconClock,
  IconCode,
  IconCopy,
  IconExternalLink,
  IconGitBranch,
  IconHardDrive,
  IconNode,
  IconPencil,
  IconPin,
  IconPlay,
  IconStopwatch,
  IconTags,
  IconTerminal,
  IconRocket,
  IconTrash,
  IconX,
} from '../../lib/icons'

interface ProjectCardProps {
  project: Project
  installedVersions: InstalledGodotVersion[]
  categories?: Category[]
  gitStatus?: GitStatus | null
  launchWithConsole?: boolean
  onTogglePin: () => void
  onVersionChange: (tag: string) => void
  onRemove: () => void
  onDelete: () => void
  onCategoryChange?: (category: string) => void
  onDuplicate?: () => void
  onTagsSaved?: (project: Project) => void
  onTagClick?: (tag: string) => void
  onLaunchArgsChange?: (args: string) => void
  onShowGitSidebar?: () => void
  activeTag?: string | null
  selected?: boolean
  onToggleSelect?: (e: React.MouseEvent) => void
  viewMode?: ProjectViewMode
}

function getInitials(name: string): string {
  const words = name
    .trim()
    .split(/[\s_-]+/)
    .filter(Boolean)
  if (words.length === 0) return ''
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase()
  return (words[0][0] + words[1][0]).toUpperCase()
}

function formatBytes(bytes: number): string {
  if (bytes >= 1024 ** 3) return `${(bytes / 1024 ** 3).toFixed(1)} GB`
  if (bytes >= 1024 ** 2) return `${(bytes / 1024 ** 2).toFixed(1)} MB`
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${bytes} B`
}

export function ProjectCard({
  project,
  installedVersions,

  categories = [],
  gitStatus,
  launchWithConsole = false,
  onTogglePin,
  onVersionChange,
  onRemove,
  onDelete,
  onCategoryChange,
  onDuplicate,
  onTagsSaved,
  onTagClick,
  onLaunchArgsChange,
  onShowGitSidebar,
  activeTag,
  selected = false,
  onToggleSelect,
  viewMode = 'list',
}: ProjectCardProps) {
  const { t } = useTranslation('common')
  const { settings } = useSettings()
  const cardSettings = getCardViewSettings(settings, viewMode)
  const resolutionEpoch = useProjectResolutionEpoch()
  const [icon, setIcon] = useState<string | null>(() =>
    getCachedProjectIcon(project.path),
  )
  const [settingsName, setSettingsName] = useState<string | null>(() =>
    getCachedProjectName(project.path),
  )
  const [confirmAction, setConfirmAction] = useState<'remove' | 'delete' | null>(
    null,
  )
  const [tagsExpanded, setTagsExpanded] = useState(false)
  const [tagManagerOpen, setTagManagerOpen] = useState(false)
  const [timeTrackerOpen, setTimeTrackerOpen] = useState(false)
  const [templateSaveOpen, setTemplateSaveOpen] = useState(false)
  const [sizeModalOpen, setSizeModalOpen] = useState(false)
  const [showLaunchArgs, setShowLaunchArgs] = useState(false)
  const [editingTagIndex, setEditingTagIndex] = useState<number | null>(null)
  const [editTagValue, setEditTagValue] = useState('')
  const [addingTag, setAddingTag] = useState(false)
  const [newTagValue, setNewTagValue] = useState('')
  const [savingTags, setSavingTags] = useState(false)
  const [tagError, setTagError] = useState<string | null>(null)
  const [cardHovered, setCardHovered] = useState(false)
  const [pinFocused, setPinFocused] = useState(false)
  const editInputRef = useRef<HTMLInputElement>(null)
  const addInputRef = useRef<HTMLInputElement>(null)

  const displayName = settingsName ?? project.name
  const pinButtonVisible = project.pinned || cardHovered || pinFocused
  const springTransition: Transition = isReducedMotion()
    ? { duration: 0 }
    : { type: 'spring', stiffness: 460, damping: 34 }
  const boundVersion = installedVersions.find(
    (v) => v.tag === project.godot_version,
  )
  const versionInstalled = Boolean(boundVersion)
  const supportsConsole = boundVersion?.supports_console ?? false

  useEffect(() => {
    let cancelled = false
    api.getProjectIcon(project.path).then((data) => {
      if (!cancelled) setIcon(data)
    })
    return () => {
      cancelled = true
    }
  }, [project.path, resolutionEpoch])

  useEffect(() => {
    let cancelled = false
    api.getProjectName(project.path).then((data) => {
      if (!cancelled) setSettingsName(data)
    })
    return () => {
      cancelled = true
    }
  }, [project.path, resolutionEpoch])

  useEffect(() => {
    if (tagError) editInputRef.current?.focus()
  }, [tagError])

  const lastOpenedLabel = formatLastOpened(
    project.last_opened,
    settings.last_opened_time_format,
    settings.last_opened_date_format,
  )


  const sessionStart = project.session_started_at_ms
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (!sessionStart) return
    setNow(Date.now())
    const id = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [sessionStart])
  const allMs = effectiveTotalMs(project, now)
  const sessionMs = sessionStart ? Math.max(0, now - sessionStart) : 0

  const [projectSize, setProjectSize] = useState<number | null>(null)
  useEffect(() => {
    let cancelled = false
    api.getProjectSize(project.path).then((info) => {
      if (!cancelled) setProjectSize(info.total_size)
    }).catch(() => {})
    return () => { cancelled = true }
  }, [project.path])

  const openFolder = () =>
    api.openProjectFolder(project.path).catch((e) => alert(e))
  const openInIde = () => api.openInEditor(project.path).catch((e) => alert(e))
  const launchProject = (withConsole?: boolean) =>
    window.dispatchEvent(
      new CustomEvent('app:open-project', {
        detail: { id: project.id, console: withConsole },
      }),
    )
  const playProject = () =>
    api.openProject(project.id, false).catch((e) => alert(e))
  const saveTags = async (newTags: string[]) => {
    setSavingTags(true)
    try {
      await api.saveProjectTags(project.id, project.path, newTags)
      onTagsSaved?.({ ...project, tags: newTags })
    } catch (e) {
      console.error('Failed to save tags:', e)
    } finally {
      setSavingTags(false)
    }
  }

  const handleAddTag = () => {
    const trimmed = newTagValue.trim()
    if (!trimmed || savingTags) return
    if (project.tags.some((t) => t.toLowerCase() === trimmed.toLowerCase())) {
      setTagError(t('tag_already_exists'))
      return
    }
    const newTags = [...project.tags, trimmed]
    setAddingTag(false)
    setNewTagValue('')
    setTagError(null)
    saveTags(newTags)
  }

  const handleRemoveTag = (index: number) => {
    if (savingTags) return
    const newTags = project.tags.filter((_, i) => i !== index)
    if (editingTagIndex === index) {
      setEditingTagIndex(null)
      setEditTagValue('')
    }
    setTagError(null)
    saveTags(newTags)
  }

  const handleRenameTag = (index: number) => {
    if (editingTagIndex !== index) return
    const trimmed = editTagValue.trim()
    const current = project.tags[index]
    if (!trimmed || trimmed === current || savingTags) {
      setEditingTagIndex(null)
      setEditTagValue('')
      setTagError(null)
      return
    }
    if (
      project.tags.some(
        (t, i) => i !== index && t.toLowerCase() === trimmed.toLowerCase(),
      )
    ) {
      setTagError(t('tag_already_exists'))
      return
    }
    const newTags = project.tags.map((t, i) => (i === index ? trimmed : t))
    setEditingTagIndex(null)
    setEditTagValue('')
    setTagError(null)
    saveTags(newTags)
  }

  return (
    <div
      onMouseEnter={() => setCardHovered(true)}
      onMouseLeave={() => setCardHovered(false)}
      className={`group relative flex items-end gap-3.5 p-3.5 rounded-item border transition-all duration-150 ${
        selected
          ? 'bg-accent/5 border-accent ring-1 ring-accent/30'
          : 'bg-overlay border-outline/50 hover:bg-raised hover:border-accent-dim/60'
      }`}
    >
      {onToggleSelect && (
        <div className="absolute top-2.5 left-2.5 z-20">
          <Tooltip
            content={selected ? t('project_deselect_aria') : t('project_select_aria')}
            side="right"
          >
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation()
                onToggleSelect(e)
              }}
              aria-pressed={selected}
              className={`focus-ring cursor-pointer w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all duration-150 ${
                selected
                  ? 'bg-accent border-accent text-white scale-100 opacity-100'
                  : 'border-muted/40 bg-black/20 opacity-100 hover:border-accent/60 hover:scale-105'
              }`}
            >
              {selected && (
                <IconCheckCircle className="w-3.5 h-3.5" fill="currentColor" />
              )}
            </button>
          </Tooltip>
        </div>
      )}
      <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-item isolate">
        {icon ? (
          <img
            src={icon}
            alt=""
            aria-hidden="true"
            className="select-none absolute -left-6 top-1/2 -translate-y-1/2 -rotate-6 group-hover:rotate-0 h-35 w-35 object-contain grayscale group-hover:grayscale-0 contrast-125 transition-all duration-300 ease-out group-hover:will-change-transform"
            style={{
              opacity: 'var(--project-icon-opacity, 0.14)',
              maskImage: 'linear-gradient(to right, black 35%, transparent 90%)',
              WebkitMaskImage:
                'linear-gradient(to right, black 35%, transparent 90%)',
            }}
          />
        ) : (
          <span
            aria-hidden="true"
            className="select-none absolute -left-3 top-1/2 -translate-y-1/2 -rotate-6 group-hover:rotate-0 font-display font-black text-muted group-hover:text-accent-bright transition-all duration-300 ease-out group-hover:will-change-transform"
            style={{
              fontSize: '72px',
              lineHeight: 1,
              opacity: 'var(--project-icon-opacity, 0.14)',
              maskImage: 'linear-gradient(to right, black 35%, transparent 90%)',
              WebkitMaskImage:
                'linear-gradient(to right, black 35%, transparent 90%)',
            }}
          >
            {getInitials(displayName)}
          </span>
        )}
      </div>


      <div className={`min-w-0 flex-1 ${onToggleSelect ? 'pl-8' : ''}`}>
        <div className="flex items-center gap-1.5 flex-wrap min-w-0">
          <h3 className="font-display font-medium text-xl text-ink truncate">
            {displayName}
          </h3>
          {gitStatus?.is_repo && (
              <button
                type="button"
                onClick={onShowGitSidebar}
                aria-label={t('git_sidebar')}
                className={`shrink-0 inline-flex items-center gap-1.5 px-1.5 py-0.5 rounded-tag transition-colors cursor-pointer ${
                  gitStatus.has_uncommitted
                    ? 'bg-amber/10 text-amber'
                    : 'text-muted hover:text-ink hover:bg-raised'
                }`}
              >
                <IconGitBranch className="w-3 h-3 shrink-0" />
                {gitStatus.branch && (
                  <span className="text-[10px] font-mono font-medium truncate max-w-24">
                    {gitStatus.branch}
                  </span>
                )}
              </button>
          )}
          {lastOpenedLabel && cardSettings.show_last_opened && (
              <span className="inline-flex items-center gap-1 pl-1.5 pr-1 py-0.5 rounded-tag font-mono text-[10px] font-medium tracking-tight shrink-0 text-muted">
                <IconClock className="w-2.5 h-2.5 text-muted/60 shrink-0" />
                {lastOpenedLabel}
              </span>
          )}
          {addingTag ? (
            <span
              className={`inline-flex items-center px-1.5 py-0.5 rounded-tag font-mono text-[10px] font-medium tracking-tight shrink-0 border ${
                tagError
                  ? 'bg-danger/10 border-danger/50'
                  : 'bg-accent/10 border-accent/30'
              }`}
            >
              {tagError ? (
                  <input
                    ref={addInputRef}
                    type="text"
                    value={newTagValue}
                    title={tagError}
                            onChange={(e) => {
                      setNewTagValue(e.target.value)
                      if (tagError) setTagError(null)
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        handleAddTag()
                      }
                      if (e.key === 'Escape') {
                        setAddingTag(false)
                        setNewTagValue('')
                        setTagError(null)
                      }
                    }}
                    onBlur={() => {
                      if (newTagValue.trim()) {
                        handleAddTag()
                      } else {
                        setAddingTag(false)
                        setTagError(null)
                      }
                    }}
                    className={`w-16 bg-transparent outline-none text-[10px] font-mono font-medium ${
                      tagError
                        ? 'text-danger placeholder:text-danger/40'
                        : 'text-accent-bright placeholder:text-accent/40'
                    }`}
                    placeholder={t('tag_input_placeholder')}
                    aria-invalid={tagError ? true : undefined}
                    autoFocus
                  />
              ) : (
                <input
                  ref={addInputRef}
                  type="text"
                  value={newTagValue}
                        onChange={(e) => {
                    setNewTagValue(e.target.value)
                    if (tagError) setTagError(null)
                  }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      handleAddTag()
                    }
                    if (e.key === 'Escape') {
                      setAddingTag(false)
                      setNewTagValue('')
                      setTagError(null)
                    }
                  }}
                  onBlur={() => {
                    if (newTagValue.trim()) {
                      handleAddTag()
                    } else {
                      setAddingTag(false)
                      setTagError(null)
                    }
                  }}
                  className={`w-16 bg-transparent outline-none text-[10px] font-mono font-medium ${
                    tagError
                      ? 'text-danger placeholder:text-danger/40'
                      : 'text-accent-bright placeholder:text-accent/40'
                  }`}
                  placeholder={t('tag_input_placeholder')}
                  aria-invalid={tagError ? true : undefined}
                  autoFocus
                />
              )}
            </span>
          ) : (
            <motion.span
              initial={false}
              animate={{
                width: cardHovered ? 'auto' : 0,
                marginRight: cardHovered ? 6 : 0,
                opacity: cardHovered ? 1 : 0,
              }}
              transition={springTransition}
              className="overflow-hidden inline-flex items-center shrink-0"
            >
                <button
                  type="button"
                  onClick={() => {
                    setAddingTag(true)
                    setNewTagValue('')
                    setTagError(null)
                  }}
                        aria-label={t('add_tag_aria')}
                  className="focus-ring cursor-pointer inline-flex items-center px-2 py-0.5 rounded-tag text-[10px] font-mono font-medium tracking-tight whitespace-nowrap text-muted hover:text-accent-bright hover:bg-raised transition-colors shrink-0 border border-dashed border-outline/50"
                >
                  {t('add_tag_aria')}
                </button>
            </motion.span>
          )}
          {savingTags && (
            <span
              aria-label={t('saving_tags')}
              className="w-3 h-3 rounded-full border-2 border-accent-dim/30 border-t-accent-bright animate-spin shrink-0"
            />
          )}
        </div>

        {project.tags.length > 0 && cardSettings.show_tags && (
          <div className="flex items-center gap-1 flex-wrap min-w-0">
              {project.tags
                .slice(0, tagsExpanded ? project.tags.length : 2)
                .map((tag, index) => {
                  const color = tagColor(tag)
                  const isActive = activeTag === tag
                  const isEditing = editingTagIndex === index
                  return (
                    <span
                      key={`${tag}-${index}`}
                      className={`group/tag inline-flex items-center gap-1 pl-1.5 pr-1 py-0.5 rounded-tag font-mono text-[10px] font-medium tracking-tight shrink-0 transition-[filter,box-shadow] duration-100 ${
                        isActive ? 'ring-1 ring-accent-dim/70 brightness-110' : ''
                      }`}
                      style={{ backgroundColor: `${color}18`, color }}
                    >
                      <span
                        aria-hidden="true"
                        className="w-1.5 h-1.5 rounded-full shrink-0 ring-1 ring-black/20"
                        style={{ backgroundColor: color }}
                      />
                      {isEditing ? (
                        tagError ? (
                            <input
                              ref={editInputRef}
                              type="text"
                              value={editTagValue}
                              title={tagError}
                                                onChange={(e) => {
                                setEditTagValue(e.target.value)
                                if (tagError) setTagError(null)
                              }}
                              onKeyDown={(e) => {
                                if (e.key === 'Enter') {
                                  e.preventDefault()
                                  handleRenameTag(index)
                                }
                                if (e.key === 'Escape') {
                                  setEditingTagIndex(null)
                                  setEditTagValue('')
                                  setTagError(null)
                                }
                              }}
                              onBlur={() => handleRenameTag(index)}
                              className={`w-16 bg-transparent outline-none text-[10px] font-mono font-medium ${
                                tagError ? 'text-danger' : ''
                              }`}
                              style={tagError ? undefined : { color }}
                              aria-invalid={tagError ? true : undefined}
                              autoFocus
                            />
                        ) : (
                          <input
                            ref={editInputRef}
                            type="text"
                            value={editTagValue}
                                            onChange={(e) => {
                              setEditTagValue(e.target.value)
                              if (tagError) setTagError(null)
                            }}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') {
                                e.preventDefault()
                                handleRenameTag(index)
                              }
                              if (e.key === 'Escape') {
                                setEditingTagIndex(null)
                                setEditTagValue('')
                                setTagError(null)
                              }
                            }}
                            onBlur={() => handleRenameTag(index)}
                            className={`w-16 bg-transparent outline-none text-[10px] font-mono font-medium ${
                              tagError ? 'text-danger' : ''
                            }`}
                            style={tagError ? undefined : { color }}
                            aria-invalid={tagError ? true : undefined}
                            autoFocus
                          />
                        )
                      ) : (
                        <>
                          <button
                              type="button"
                              onClick={() => onTagClick?.(tag)}
                                                className="cursor-pointer hover:brightness-125 transition-[filter] duration-100"
                            >
                              {tag}
                            </button>
                          <button
                              type="button"
                              onClick={() => {
                                setEditingTagIndex(index)
                                setEditTagValue(tag)
                                setTagError(null)
                              }}
                                                aria-label={t('tag_rename_aria')}
                              className="focus-ring cursor-pointer opacity-0 group-hover/tag:opacity-100 scale-75 group-hover/tag:scale-100 w-0 group-hover/tag:w-3 h-3 overflow-hidden rounded-full flex items-center justify-center transition-all duration-150 hover:text-ink shrink-0"
                            >
                              <IconPencil className="w-2.5 h-2.5 shrink-0" />
                            </button>
                          <button
                              type="button"
                              onClick={() => handleRemoveTag(index)}
                                                aria-label={t('tag_remove_aria', { tag })}
                              className="focus-ring cursor-pointer opacity-0 group-hover/tag:opacity-100 scale-75 group-hover/tag:scale-100 w-0 group-hover/tag:w-3 h-3 overflow-hidden rounded-full flex items-center justify-center transition-all duration-150 hover:text-danger shrink-0"
                            >
                              <IconX className="w-2.5 h-2.5 shrink-0" />
                            </button>
                        </>
                      )}
                    </span>
                  )
                })}
              {!tagsExpanded && project.tags.length > 2 && (
                <button
                    type="button"
                    onClick={() => setTagsExpanded(true)}
                            aria-label={t('show_more_tags')}
                    className="focus-ring cursor-pointer inline-flex items-center px-2 py-0.5 rounded-tag text-[10px] font-mono font-medium tracking-tight text-muted hover:text-ink hover:bg-raised transition-colors shrink-0 border border-dashed border-outline/50"
                  >
                    +{project.tags.length - 2}
                  </button>
              )}
              {tagsExpanded && project.tags.length > 2 && (
                <button
                    type="button"
                    onClick={() => setTagsExpanded(false)}
                            aria-label={t('show_fewer_tags')}
                    className="focus-ring cursor-pointer inline-flex items-center px-2 py-0.5 rounded-tag text-[10px] font-mono font-medium tracking-tight text-muted hover:text-ink hover:bg-raised transition-colors shrink-0 border border-dashed border-outline/50"
                  >
                    -{project.tags.length - 2}
                  </button>
              )}
            </div>
          )}

          {cardSettings.show_path && (
            <button
              type="button"
              onClick={openFolder}
              className={`block bg-black/15 px-3 py-1 rounded-tag text-[11px] font-mono text-muted truncate hover:text-accent-bright cursor-pointer transition-colors w-fit max-w-full ${cardSettings.blur_path ? 'blur-sm hover:blur-none transition-[filter]' : ''}`}
            >
              {project.path}
            </button>
          )}

        <div className="flex items-center gap-1.5 flex-wrap mt-1.5">
          <Dropdown
            align="left"
            trigger={({ open, toggle }) => (
              <button
                type="button"
                aria-expanded={open}
                onClick={toggle}
                    className="inline-flex items-center gap-1.5 px-3 py-3 rounded-btn bg-raised border border-outline/50 font-mono text-[10px] text-muted hover:text-ink hover:border-accent-dim cursor-pointer transition-colors shrink-0"
              >
                <IconNode className="w-2.5 h-2.5" />
                {boundVersion ? (
                  <>
                    {boundVersion.custom_name || boundVersion.tag}
                    {boundVersion.is_mono && (
                      <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-tag bg-accent/10 text-accent-bright border border-accent-dim/40 shrink-0">
                        {t('version_mono_badge')}
                      </span>
                    )}
                  </>
                ) : (
                  t('no_version_selected')
                )}
                <IconChevronDown
                  className={`w-2.5 h-2.5 transition-transform duration-200 ${
                    open ? 'rotate-180 text-ink' : ''
                  }`}
                />
              </button>
            )}
            items={installedVersions.map((v) => ({
              key: v.tag,
              label: v.custom_name || v.tag,
              active: v.tag === project.godot_version,
              onClick: () => onVersionChange(v.tag),
              badge: v.is_mono ? t('version_mono_badge') : undefined,
            }))}
          />
          <motion.span
            initial={false}
            animate={{
              width: pinButtonVisible ? 'auto' : 0,
              marginRight: pinButtonVisible ? 6 : 0,
              opacity: pinButtonVisible ? 1 : 0,
            }}
            transition={springTransition}
            className="overflow-hidden inline-flex items-center shrink-0"
          >
              {project.pinned ? (
                <Tooltip content={t('project_unpin_aria')} side="top">
                  <button
                    type="button"
                    onClick={onTogglePin}
                    onFocus={() => setPinFocused(true)}
                    onBlur={() => setPinFocused(false)}
                    className="focus-ring cursor-pointer inline-flex items-center ml-1 px-2.5 py-2.5 rounded-btn border font-mono transition-colors shrink-0 bg-accent/10 border-accent-dim/40 text-accent-bright hover:bg-accent/20 hover:border-accent-dim"
                  >
                    <IconPin className="w-3 h-3" fill="currentColor" />
                  </button>
                </Tooltip>
              ) : (
                <button
                  type="button"
                  onClick={onTogglePin}
                  onFocus={() => setPinFocused(true)}
                  onBlur={() => setPinFocused(false)}
                  className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-3 rounded-btn border font-mono text-[10px] transition-colors shrink-0 bg-raised border-outline/50 text-muted hover:text-ink hover:border-accent-dim"
                >
                  <IconPin className="w-3 h-3" />
                  {t('project_pin_aria')}
                </button>
              )}
          </motion.span>
          {allMs > 0 && cardSettings.show_time && (
              <button
                type="button"
                onClick={() => setTimeTrackerOpen(true)}
                    aria-label={t('time_tracked_title')}
                className="focus-ring border border-outline/50 cursor-pointer inline-flex items-center gap-1.5 rounded-btn px-3 py-3 bg-black/10 font-mono text-[10px] text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
              >
                <IconStopwatch className="w-3 h-3 text-muted/60 shrink-0" />
                {formatDuration(allMs)}
              </button>
          )}
          {projectSize != null && projectSize > 0 && cardSettings.show_size && (
              <button
                type="button"
                onClick={() => setSizeModalOpen(true)}
                aria-label={t('project_card_project_size')}
                className="focus-ring cursor-pointer border border-outline/50 inline-flex items-center gap-1.5 rounded-btn px-3 py-3 bg-black/10 font-mono text-[10px] text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
              >
                <IconHardDrive className="w-3 h-3 text-muted/60 shrink-0" />
                {formatBytes(projectSize)}
              </button>
          )}
          {categories.length > 0 && onCategoryChange && (
            <Dropdown
              align="right"
              trigger={({ open, toggle }) => {
                const cat = categories.find((c) => c.name === project.category)
                const catColor = cat?.color ?? '#949ba4'
                return (
                  <button
                    type="button"
                    aria-expanded={open}
                    onClick={toggle}
                            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-3 rounded-btn bg-raised border border-outline/50 font-mono text-[10px] text-muted hover:text-ink hover:border-accent-dim transition-colors shrink-0"
                  >
                    <span
                      className="w-1.5 h-1.5 rounded-full shrink-0 ring-1 ring-black/20"
                      style={{ backgroundColor: catColor }}
                    />
                    {project.category ?? t('uncategorized')}
                    <IconChevronDown
                      className={`w-2.5 h-2.5 transition-transform duration-200 ${
                        open ? 'rotate-180 text-ink' : ''
                      }`}
                    />
                  </button>
                )
              }}
              items={[
                {
                  key: 'category-uncategorized',
                  label: t('uncategorized'),
                  dotColor: '#949ba4',
                  active: !project.category,
                  onClick: () => onCategoryChange(''),
                },
                ...categories.map((c) => ({
                  key: `category-${c.id}`,
                  label: c.name,
                  dotColor: c.color,
                  active: project.category === c.name,
                  onClick: () => onCategoryChange(c.name),
                })),
              ]}
            />
          )}
        </div>
      </div>
        {sessionMs > 0 && (
          <motion.div
            initial={{ x: 80, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: 80, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 350, damping: 25 }}
            className="flex items-center shrink-0 -mr-5 mb-1 overflow-hidden"
          >
            <div className="flex items-center gap-2 px-4 h-10 bg-base/50 border-r-0 rounded-l-dropdown-btn font-mono text-xs text-accent-bright whitespace-nowrap">
              <span className="w-1.5 h-1.5 rounded-full bg-accent-bright animate-pulse shrink-0" />
              {formatDuration(sessionMs)}
            </div>
          </motion.div>
        )}
      <div className="flex items-stretch shrink-0 relative -mr-2">

        <div className="flex flex-col justify-end gap-1.5">
          {cardSettings.show_play && (
            <div className="flex h-12 w-full">
              <AnimatePresence>
                {versionInstalled && cardHovered && (
                  <Tooltip
                    content={t('play_project_tooltip')}
                    side="left"
                    className="w-full"
                  >
                    <motion.button
                      key="button-787"
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 8 }}
                      transition={{
                        type: 'spring',
                        stiffness: 500,
                        damping: 30,
                      }}
                      type="button"
                      onClick={playProject}
                      aria-label={t('play_project')}
                      className="focus-ring inline-flex h-12 w-full shrink-0 cursor-pointer items-center justify-center gap-1.5 rounded-btn border border-outline/50 bg-overlay text-[18px] font-medium text-muted shadow-md shadow-black/10 transition-colors hover:bg-raised hover:text-ink"
                    >
                      <IconPlay className="h-4 w-4" />
                      {t('play_project')}
                    </motion.button>
                  </Tooltip>
                )}
              </AnimatePresence>
            </div>
          )}
        <OpenButton
          label={versionInstalled ? t('open_project') : t('no_version_selected')}
          disabled={!versionInstalled}
          onOpen={launchProject}
          consoleSupported={supportsConsole}
          consoleInitiallyOn={launchWithConsole && supportsConsole}
          showConsole={cardSettings.show_console}
          moreAriaLabel={t('project_more_aria')}
          className="px-10"
          headerItems={[
            {
              key: 'open-folder',
              label: t('open_folder'),
              icon: IconExternalLink,
              tooltip: t('open_folder'),
              onClick: openFolder,
            },
            {
              key: 'open-ide',
              label: t('open_in_ide'),
              icon: IconCode,
              tooltip: t('open_in_ide'),
              onClick: openInIde,
            },
            {
              key: 'open-terminal',
              label: t('open_terminal'),
              icon: IconTerminal,
              tooltip: t('open_terminal'),
              onClick: () => api.openTerminal(project.path).catch((e) => alert(e)),
            },
          ]}
          items={[
          {
            key: 'launch-arguments',
            label: t('launch_arguments'),
            icon: IconRocket,
            onClick: () => setShowLaunchArgs(true),
          },
          {
            key: 'manage-tags',
            label: t('manage_tags'),
            icon: IconTags,
            onClick: () => setTagManagerOpen(true),
            dividerAfter: !!onCategoryChange,
          },
          ...(onDuplicate
            ? [
                {
                  key: 'duplicate',
                  label: t('duplicate_project'),
                  icon: IconCopy,
                  onClick: onDuplicate,
                },
              ]
            : []),
          ...(onCategoryChange
            ? [
                {
                  key: 'set-category',
                  label: t('set_category'),
                  icon: IconTags,
                  children: [
                    {
                      key: 'category-uncategorized',
                      label: t('uncategorized'),
                      dotColor: '#949ba4',
                      active: !project.category,
                      onClick: () => onCategoryChange(''),
                    },
                    ...categories.map((c) => ({
                      key: `category-${c.id}`,
                      label: c.name,
                      dotColor: c.color,
                      active: project.category === c.name,
                      onClick: () => onCategoryChange(c.name),
                    })),
                  ],
                  dividerAfter: true,
                },
              ]
            : []),
          {
            key: 'save-as-template',
            label: t('save_as_template'),
            icon: IconCopy,
            onClick: () => setTemplateSaveOpen(true),
            dividerAfter: true,
          },
          {
            key: 'remove',
            label: t('project_card_remove_library'),
            icon: IconX,
            onClick: () => setConfirmAction('remove'),
          },
          {
            key: 'delete',
            label: t('project_card_delete_files'),
            icon: IconTrash,
            danger: true,
            onClick: () => setConfirmAction('delete'),
          },
        ]}
        />
      </div>
      </div>

      <AnimatePresence>
        {confirmAction === 'remove' && (
          <ConfirmDialog
            title={t('project_remove_title')}
            description={t('project_remove_desc', { name: displayName })}
            confirmLabel={t('project_remove_confirm')}
            onConfirm={() => {
              setConfirmAction(null)
              onRemove()
            }}
            onCancel={() => setConfirmAction(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmAction === 'delete' && (
          <ConfirmDialog
            title={t('project_delete_title')}
            description={t('project_delete_desc', { name: displayName })}
            confirmLabel={t('project_delete_confirm')}
            variant="danger"
            onConfirm={() => {
              setConfirmAction(null)
              onDelete()
            }}
            onCancel={() => setConfirmAction(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {tagManagerOpen && (
          <TagManagerModal
            project={project}
            onClose={() => setTagManagerOpen(false)}
            onSaved={(updated) => onTagsSaved?.(updated)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {timeTrackerOpen && (
          <TimeTrackerModal
            project={project}
            onClose={() => setTimeTrackerOpen(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {showLaunchArgs && (
          <LaunchArgsModal
            projectName={displayName}
            currentArgs={project.launch_arguments}
            onSave={(args) => {
              onLaunchArgsChange?.(args)
              setShowLaunchArgs(false)
            }}
            onClose={() => setShowLaunchArgs(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {templateSaveOpen && (
          <SaveAsTemplateModal
            project={project}
            onClose={() => setTemplateSaveOpen(false)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {sizeModalOpen && (
          <ProjectSizeModal
            projectPath={project.path}
            projectName={displayName}
            onClose={() => setSizeModalOpen(false)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}