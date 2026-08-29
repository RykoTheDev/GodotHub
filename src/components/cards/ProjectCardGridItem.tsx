import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion, type Transition } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Category, GitStatus, InstalledGodotVersion, Project } from '../../types'
import { api, getCachedProjectIcon, getCachedProjectName } from '../../lib/api'
import { formatDuration } from '../../lib/duration'
import { effectiveTotalMs } from '../../lib/projectSort'
import { tagColor } from '../../lib/colors'
import { isReducedMotion } from '../../lib/appearance'
import { useProjectResolutionEpoch } from '../../hooks/useProjectResolutionEpoch'
import { Dropdown } from '../ui/Dropdown'
import { OpenButton } from '../reusables/OpenButton'
import { Tooltip } from '../reusables/Tooltip'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { TagManagerModal } from '../modals/TagManagerModal'
import { LaunchArgsModal } from '../modals/LaunchArgsModal'
import { SaveAsTemplateModal } from '../modals/SaveAsTemplateModal'
import {
  IconCheckCircle,
  IconClock,
  IconCode,
  IconCopy,
  IconExternalLink,
  IconGitBranch,
  IconNode,
  IconPencil,
  IconPin,
  IconTags,
  IconTerminal,
  IconTrash,
  IconX,
} from '../../lib/icons'

interface ProjectCardGridItemProps {
  project: Project
  installedVersions: InstalledGodotVersion[]
  categories?: Category[]
  gitStatus?: GitStatus | null
  launchWithConsole?: boolean
  onTogglePin: () => void
  onVersionChange: (tag: string) => void
  onRemove: () => void
  onDelete?: () => void
  onCategoryChange?: (category: string) => void
  onTagsSaved?: (project: Project) => void
  onTagClick?: (tag: string) => void
  onLaunchArgsChange?: (args: string) => void
  onShowGitSidebar?: () => void
  activeTag?: string | null
  selected?: boolean
  onToggleSelect?: (e: React.MouseEvent) => void
}

function getInitials(name: string): string {
  const words = name.trim().split(/[\s_-]+/).filter(Boolean)
  if (words.length === 0) return ''
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase()
  return (words[0][0] + words[1][0]).toUpperCase()
}

export function ProjectCardGridItem({
  project,
  installedVersions,
  categories = [],
  gitStatus,
  launchWithConsole,
  onTogglePin,
  onVersionChange,
  onRemove,
  onDelete,
  onCategoryChange,
  onTagsSaved,
  onTagClick,
  onLaunchArgsChange,
  onShowGitSidebar,
  activeTag,
  selected = false,
  onToggleSelect,
}: ProjectCardGridItemProps) {
  const { t } = useTranslation('common')
  const resolutionEpoch = useProjectResolutionEpoch()
  const [icon, setIcon] = useState<string | null>(() =>
    getCachedProjectIcon(project.path),
  )
  const [settingsName, setSettingsName] = useState<string | null>(() =>
    getCachedProjectName(project.path),
  )
  const [cardHovered, setCardHovered] = useState(false)
  const [addingTag, setAddingTag] = useState(false)
  const [newTagValue, setNewTagValue] = useState('')
  const [editingTagIndex, setEditingTagIndex] = useState<number | null>(null)
  const [editTagValue, setEditTagValue] = useState('')
  const [tagError, setTagError] = useState<string | null>(null)
  const [savingTags, setSavingTags] = useState(false)
  const [confirmAction, setConfirmAction] = useState<'remove' | 'delete' | null>(null)
  const [showLaunchArgs, setShowLaunchArgs] = useState(false)
  const [tagManagerOpen, setTagManagerOpen] = useState(false)
  const [templateSaveOpen, setTemplateSaveOpen] = useState(false)
  const addInputRef = useRef<HTMLInputElement>(null)
  const editInputRef = useRef<HTMLInputElement>(null)

  const displayName = settingsName ?? project.name

  const springTransition: Transition = isReducedMotion()
    ? { duration: 0 }
    : { type: 'spring', stiffness: 460, damping: 34 }

  const boundVersion = installedVersions.find(
    (v) => v.tag === project.godot_version,
  )

  useEffect(() => {
    let cancelled = false
    api.getProjectIcon(project.path).then((data) => {
      if (!cancelled) setIcon(data)
    })
    return () => { cancelled = true }
  }, [project.path, resolutionEpoch])

  useEffect(() => {
    let cancelled = false
    api.getProjectName(project.path).then((data) => {
      if (!cancelled) setSettingsName(data)
    })
    return () => { cancelled = true }
  }, [project.path, resolutionEpoch])

  useEffect(() => {
    if (tagError) editInputRef.current?.focus()
  }, [tagError])

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

  const launchProject = (withConsole?: boolean) =>
    window.dispatchEvent(
      new CustomEvent('app:open-project', {
        detail: { id: project.id, console: withConsole },
      }),
    )

  const openFolder = () =>
    api.openProjectFolder(project.path).catch((e) => alert(e))

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
    setAddingTag(false)
    setNewTagValue('')
    setTagError(null)
    saveTags([...project.tags, trimmed])
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
      className={`group relative flex flex-col rounded-item border transition-colors ${
        selected
          ? 'bg-accent/5 border-accent ring-1 ring-accent/30'
          : 'bg-overlay border-outline/50 hover:bg-raised hover:border-accent-dim/60'
      }`}
    >
      {/* Selection checkbox */}
      {onToggleSelect && (
        <div className="absolute top-2 left-7 z-20">
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation()
              onToggleSelect(e)
            }}
            className={`focus-ring cursor-pointer w-4 h-4 rounded-full border-2 flex items-center justify-center transition-all duration-150 ${
              selected
                ? 'bg-accent border-accent text-white'
                : 'border-muted/40 bg-black/20 opacity-0 group-hover:opacity-100 hover:border-accent/60'
            }`}
          >
            {selected && (
              <IconCheckCircle className="w-3 h-3" fill="currentColor" />
            )}
          </button>
        </div>
      )}

      {/* Pin button (top-left) */}
      {cardHovered && !project.pinned && (
        <Tooltip content={t('project_pin_aria')} side="right">
          <motion.button
            type="button"
            onClick={(e) => {
              e.stopPropagation()
              onTogglePin()
            }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={springTransition}
            className="focus-ring cursor-pointer absolute top-2 left-2 z-20 w-4 h-4 flex items-center justify-center text-muted/40 hover:text-ink"
          >
            <IconPin className="w-3 h-3" />
          </motion.button>
        </Tooltip>
      )}

      {/* Icon header (matches AssetCard style) */}
      <div className="relative h-24 shrink-0 bg-raised flex items-center justify-center overflow-hidden rounded-t-item">
        {icon && (
          <img
            src={icon}
            alt=""
            loading="lazy"
            decoding="async"
            className="absolute inset-0 w-full h-full object-cover opacity-15 group-hover:opacity-0 transition-opacity duration-300"
          />
        )}
        {!icon && (
          <span
            aria-hidden="true"
            className="select-none absolute inset-0 flex items-center justify-center font-display font-black text-muted text-5xl opacity-15 group-hover:opacity-0 transition-opacity duration-300"
          >
            {getInitials(displayName)}
          </span>
        )}
        <div className="absolute inset-x-0 bottom-0 h-10 bg-gradient-to-t from-overlay to-transparent transition-opacity duration-300 group-hover:opacity-0" />
        <div className="relative w-14 h-14 rounded-tile bg-surface/90 border border-outline/60 flex items-center justify-center overflow-hidden opacity-0 scale-75 group-hover:opacity-100 group-hover:scale-100 transition-all duration-300 ease-out">
          {icon ? (
            <img src={icon} alt="" className="absolute inset-0 w-full h-full object-cover" />
          ) : (
            <span className="text-xs font-bold text-muted">
              {getInitials(displayName)}
            </span>
          )}
        </div>
        {/* Time pill (top-right) */}
        {(sessionMs > 0 || (allMs > 0 && sessionMs === 0)) && (
          <span className="absolute top-2 right-2 z-10 inline-flex items-center gap-1 px-2 py-0.5 rounded-tag bg-surface/90 border border-outline/50 font-mono text-[10px] font-medium text-muted backdrop-blur-sm">
            {sessionMs > 0 ? (
              <>
                <span className="w-1.5 h-1.5 rounded-full bg-accent-bright animate-pulse shrink-0" />
                <span className="text-accent-bright">{formatDuration(sessionMs)}</span>
              </>
            ) : (
              <>
                <IconClock className="w-2.5 h-2.5 text-muted/60" />
                <span>{formatDuration(allMs)}</span>
              </>
            )}
          </span>
        )}
      </div>

      {/* Content */}
      <div className="flex flex-col items-center gap-1.5 p-4 flex-1 min-w-0">
        {/* Project name + Git button (centered) */}
        <div className="flex items-center gap-1.5 justify-center min-w-0">
          <h3 className="font-display font-medium text-lg text-ink leading-snug line-clamp-2 text-center min-w-0">
            {displayName}
          </h3>
          {gitStatus?.is_repo && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation()
                onShowGitSidebar?.()
              }}
              className={`focus-ring cursor-pointer shrink-0 w-5 h-5 rounded-item flex items-center justify-center transition-colors ${
                gitStatus.has_uncommitted
                  ? 'bg-amber/10 text-amber hover:bg-amber/20'
                  : 'text-muted/50 hover:text-ink hover:bg-raised'
              }`}
              title={gitStatus.branch ?? (gitStatus.has_uncommitted ? t('git_uncommitted') : t('git_clean'))}
            >
              <IconGitBranch className="w-3 h-3" />
            </button>
          )}
        </div>

        {/* Path (pill) */}
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation()
            api.openProjectFolder(project.path).catch((err) => alert(err))
          }}
          className="block bg-black/15 px-3 py-1 rounded-tag text-[11px] font-mono text-muted truncate hover:text-accent-bright cursor-pointer transition-colors w-fit max-w-full text-center mx-auto"
        >
          {project.path}
        </button>

        {/* Tags */}
        <div className="relative flex items-center gap-1 flex-wrap min-h-[22px] justify-center overflow-hidden" style={{ maxHeight: '44px' }}>
        {project.tags.slice(0, 3).map((tag, i) => {
          const color = tagColor(tag)
          const isActive = activeTag === tag
          const isEditing = editingTagIndex === i
          return (
            <span
              key={`${tag}-${i}`}
              className={`group/tag inline-flex items-center gap-0.5 pl-2 pr-1 py-0.5 rounded-tag font-mono text-[10px] font-medium tracking-tight shrink-0 transition-[filter] duration-100 ${
                isActive ? 'ring-1 ring-accent-dim/70 brightness-110' : ''
              }`}
              style={{ backgroundColor: `${color}18`, color }}
            >
              <span
                className="w-1.5 h-1.5 rounded-full shrink-0 ring-1 ring-black/20"
                style={{ backgroundColor: color }}
              />
              {isEditing ? (
                <input
                  ref={editInputRef}
                  type="text"
                  value={editTagValue}
                  title={tagError ?? undefined}
                  onChange={(e) => {
                    setEditTagValue(e.target.value)
                    if (tagError) setTagError(null)
                  }}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      handleRenameTag(i)
                    }
                    if (e.key === 'Escape') {
                      setEditingTagIndex(null)
                      setEditTagValue('')
                      setTagError(null)
                    }
                  }}
                  onBlur={() => handleRenameTag(i)}
                  className={`w-14 bg-transparent outline-none text-[9px] font-mono font-medium ${
                    tagError ? 'text-danger' : ''
                  }`}
                  style={tagError ? undefined : { color }}
                  autoFocus
                />
              ) : (
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation()
                    onTagClick?.(tag)
                  }}
                  className="cursor-pointer hover:brightness-125 transition-[filter] duration-100"
                >
                  {tag}
                </button>
              )}
              {!isEditing && (
                <>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      setEditingTagIndex(i)
                      setEditTagValue(tag)
                      setTagError(null)
                    }}
                    className="focus-ring cursor-pointer opacity-0 group-hover/tag:opacity-100 w-0 group-hover/tag:w-3 h-3 overflow-hidden rounded-full flex items-center justify-center transition-all duration-150 hover:text-ink shrink-0"
                  >
                    <IconPencil className="w-2 h-2" />
                  </button>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      handleRemoveTag(i)
                    }}
                    className="focus-ring cursor-pointer opacity-0 group-hover/tag:opacity-100 w-0 group-hover/tag:w-3 h-3 overflow-hidden rounded-full flex items-center justify-center transition-all duration-150 hover:text-danger shrink-0"
                  >
                    <IconX className="w-2 h-2" />
                  </button>
                </>
              )}
            </span>
          )
        })}
        {!addingTag ? (
          <motion.button
            type="button"
            initial={false}
            animate={{
              opacity: cardHovered ? 1 : 0,
              scale: cardHovered ? 1 : 0.8,
            }}
            transition={springTransition}
            onClick={(e) => {
              e.stopPropagation()
              setAddingTag(true)
              setNewTagValue('')
              setTagError(null)
            }}
            className="focus-ring cursor-pointer absolute -right-0.5 -top-0.5 z-10 inline-flex items-center justify-center w-4 h-4 rounded-full text-[9px] font-mono font-medium text-muted hover:text-accent-bright hover:bg-raised transition-colors border border-dashed border-outline/50 bg-overlay"
          >
            +
          </motion.button>
        ) : (
          <span
            className={`inline-flex items-center px-1 py-0.5 rounded-tag font-mono text-[9px] font-medium tracking-tight shrink-0 border ${
              tagError
                ? 'bg-danger/10 border-danger/50'
                : 'bg-accent/10 border-accent/30'
            }`}
          >
            <input
              ref={addInputRef}
              type="text"
              value={newTagValue}
              title={tagError ?? undefined}
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
              className={`w-14 bg-transparent outline-none text-[9px] font-mono font-medium ${
                tagError
                  ? 'text-danger placeholder:text-danger/40'
                  : 'text-accent-bright placeholder:text-accent/40'
              }`}
              placeholder="..."
              autoFocus
            />
          </span>
        )}
        {savingTags && (
          <span className="w-3 h-3 rounded-full border-2 border-accent-dim/30 border-t-accent-bright animate-spin shrink-0" />
        )}
        {project.tags.length > 3 && (
          <span className="text-[9px] text-muted">+{project.tags.length - 3}</span>
        )}
      </div>

        {/* Footer: Version + Open button */}
        <div className="flex flex-wrap items-center gap-2 mt-auto pt-2">
          <Dropdown
            align="left"
            trigger={({ open, toggle }) => (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation()
                  toggle()
                }}
                aria-expanded={open}
                className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-3 rounded-btn bg-raised border border-outline/50 font-mono text-[10px] text-muted hover:text-ink hover:border-accent-dim cursor-pointer transition-colors shrink-0"
              >
                <IconNode className="w-2.5 h-2.5" />
                {boundVersion ? (boundVersion.custom_name || boundVersion.tag) : t('no_version_selected')}
              </button>
            )}
            items={installedVersions.map((v) => ({
              key: v.tag,
              label: v.custom_name || v.tag,
              active: v.tag === project.godot_version,
              onClick: () => onVersionChange(v.tag),
            }))}
          />
          <div className="flex-1 min-w-0 hidden sm:block" />
          <div className="w-full sm:w-auto order-last sm:order-none">
          <OpenButton
            label={boundVersion ? t('open_project') : t('no_version_selected')}
            disabled={!boundVersion}
            onOpen={(console) => launchProject(console)}
            consoleSupported={boundVersion?.supports_console ?? false}
            consoleInitiallyOn={launchWithConsole && (boundVersion?.supports_console ?? false)}
            moreAriaLabel={t('project_more_aria')}
            className="px-6 text-xs h-8"
            headerItems={[
              {
                key: 'open-folder',
                label: t('open_folder'),
                icon: IconExternalLink,
                onClick: openFolder,
              },
              {
                key: 'open-ide',
                label: t('open_in_ide'),
                icon: IconCode,
                onClick: () => api.openInEditor(project.path).catch((e) => alert(e)),
              },
            ]}
            items={[
              {
                key: 'launch-arguments',
                label: t('launch_arguments'),
                icon: IconTerminal,
                onClick: () => setShowLaunchArgs(true),
              },
              {
                key: 'manage-tags',
                label: t('manage_tags'),
                icon: IconTags,
                onClick: () => setTagManagerOpen(true),
                dividerAfter: !!onCategoryChange,
              },
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
              onDelete?.()
            }}
            onCancel={() => setConfirmAction(null)}
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
        {tagManagerOpen && (
          <TagManagerModal
            project={project}
            onClose={() => setTagManagerOpen(false)}
            onSaved={(updated) => onTagsSaved?.(updated)}
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
    </div>
  )
}
