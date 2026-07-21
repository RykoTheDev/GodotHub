import { useEffect, useRef, useState, memo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import type { Category, GitStatus, InstalledGodotVersion, Project } from '../../types'
import { api, getCachedProjectIcon, getCachedProjectName } from '../../lib/api'
import { Dropdown } from './Dropdown'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { LaunchArgsModal } from '../modals/LaunchArgsModal'
import {
  ContextMenu,
  type ContextMenuSection,
} from './ContextMenu'
import { Tooltip } from './Tooltip'
import { IconGrip, IconMore, IconPin, IconPlay, IconTrash, IconClock, IconExternalLink, IconCode, IconGitBranch, IconX, IconTags, IconCopy, IconHardDrive, IconAlertTriangle, IconCheckCircle } from '../Icons'
import {
  formatLastOpened,
  type LastOpenedTimeFormat,
  type LastOpenedDateFormat,
} from '../../lib/lastOpened'

interface Props {
  project: Project
  installedVersions: InstalledGodotVersion[]
  categories: Category[]
  categoriesEnabled?: boolean
  onRemove: () => void
  onDelete: () => void
  onVersionChange: (tag: string) => void
  onCategoryChange: (category: string) => void
  onTogglePin: () => void
  onLaunchArgsChange?: (args: string) => void
  onOpenProperties?: () => void
  onGitAction?: (action: 'terminal' | 'pull' | 'push' | 'fetch' | 'log') => void
  onShowGitSidebar?: () => void
  onOpened?: () => void
  draggable?: boolean
  isDragging?: boolean
  selected?: boolean
  onToggleSelect?: () => void
  versionWarning?: 'not_found' | 'major_mismatch' | null
  gitStatus?: GitStatus | null
  lastOpenedTimeFormat?: LastOpenedTimeFormat
  lastOpenedDateFormat?: LastOpenedDateFormat
  setNodeRef?: (node: HTMLElement | null) => void
  style?: React.CSSProperties
  dragHandleProps?: Record<string, unknown>
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

export const ProjectCard = memo(function ProjectCard({
  project,
  installedVersions,
  onRemove,
  onDelete,
  onVersionChange,
  onCategoryChange,
  categories,
  onTogglePin,
  onLaunchArgsChange,
  onOpenProperties,
  onGitAction: _onGitAction,
  onShowGitSidebar,
  gitStatus,
  onOpened,
  draggable,
  isDragging,
  selected,
  onToggleSelect,
  versionWarning,
  setNodeRef,
  style,
  dragHandleProps,
  lastOpenedTimeFormat = '12h',
  lastOpenedDateFormat = 'DD-MM-YYYY',
  categoriesEnabled = true,
}: Props) {
  const [icon, setIcon] = useState<string | null>(() => getCachedProjectIcon(project.path))
  const [settingsName, setSettingsName] = useState<string | null>(() => getCachedProjectName(project.path))
  const displayName = settingsName ?? project.name
  const versionInstalled = installedVersions.some(
    (v) => v.tag === project.godot_version,
  )
  const [confirmAction, setConfirmAction] = useState<
    'remove' | 'delete' | null
  >(null)
  const [templateSaveOpen, setTemplateSaveOpen] = useState(false)
  const [templateName, setTemplateName] = useState('')
  const [templateDesc, setTemplateDesc] = useState('')
  const [templateBusy, setTemplateBusy] = useState(false)
  const [contextMenu, setContextMenu] = useState<{
    x: number
    y: number
  } | null>(null)
  const [showLaunchArgs, setShowLaunchArgs] = useState(false)
  const [cardMoreOpen, setCardMoreOpen] = useState(false)
  const [cardMoreUp, setCardMoreUp] = useState(false)
  const cardMoreRef = useRef<HTMLDivElement>(null)

  const lastOpenedLabel = formatLastOpened(
    project.last_opened,
    lastOpenedTimeFormat,
    lastOpenedDateFormat,
  )

  useEffect(() => {
    let cancelled = false
    api.getProjectIcon(project.path).then((data) => {
      if (!cancelled) setIcon(data)
    })
    return () => {
      cancelled = true
    }
  }, [project.path])

  useEffect(() => {
    let cancelled = false
    api.getProjectName(project.path).then((data) => {
      if (!cancelled) setSettingsName(data)
    })
    return () => {
      cancelled = true
    }
  }, [project.path])

  const openFolder = () =>
    api.openProjectFolder(project.path).catch((e) => alert(e))

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (cardMoreRef.current && !cardMoreRef.current.contains(e.target as Node)) {
        setCardMoreOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const handleSaveTemplate = async () => {
    if (!templateName.trim()) return
    setTemplateBusy(true)
    try {
      await api.saveProjectAsTemplate(
        project.id,
        templateName.trim(),
        templateDesc.trim(),
      )
      setTemplateSaveOpen(false)
      setTemplateName('')
      setTemplateDesc('')
    } catch (e) {
      alert(e)
    } finally {
      setTemplateBusy(false)
    }
  }

  const dialogs = (
    <>
      {confirmAction === 'remove' && (
        <ConfirmDialog
          title="Remove from library?"
          description={`"${displayName}" will be removed from GodotHub's list. Its files stay on disk untouched, you can import it again anytime.`}
          confirmLabel="Remove"
          onConfirm={() => {
            onRemove()
            setConfirmAction(null)
          }}
          onCancel={() => setConfirmAction(null)}
        />
      )}

      {confirmAction === 'delete' && (
        <ConfirmDialog
          title="Delete project files?"
          description={`This permanently deletes "${displayName}" and everything inside it from disk. This can't be undone.`}
          confirmLabel="Delete permanently"
          variant="danger"
          onConfirm={() => {
            onDelete()
            setConfirmAction(null)
          }}
          onCancel={() => setConfirmAction(null)}
        />
      )}

      <AnimatePresence>
        {templateSaveOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={() => setTemplateSaveOpen(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: 12, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ type: 'spring', stiffness: 380, damping: 30 }}
              className="bg-surface border border-line rounded-2xl p-6 w-full max-w-sm flex flex-col gap-5 shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            >
              <div>
                <h4 className="font-display font-semibold text-base">
                  Save as Template
                </h4>
                <p className="text-xs text-muted mt-1">
                  Copy "{displayName}" to your templates library so you can
                  reuse its structure in new projects.
                </p>
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-medium text-muted">
                  Template Name
                </label>
                <input
                  value={templateName}
                  onChange={(e) => setTemplateName(e.target.value)}
                  className="focus-ring bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors"
                  placeholder={displayName}
                  autoFocus
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-xs font-medium text-muted">
                  Description{' '}
                  <span className="text-muted/60 font-normal">(optional)</span>
                </label>
                <textarea
                  value={templateDesc}
                  onChange={(e) => setTemplateDesc(e.target.value)}
                  className="focus-ring bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors resize-none"
                  placeholder="What's in this template?"
                  rows={2}
                />
              </div>

              <div className="flex justify-end gap-2.5 mt-1">
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={() => setTemplateSaveOpen(false)}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  Cancel
                </motion.button>
                <motion.button
                  whileHover={templateBusy ? undefined : { y: -1 }}
                  whileTap={templateBusy ? undefined : { scale: 0.96 }}
                  onClick={handleSaveTemplate}
                  disabled={templateBusy || !templateName.trim()}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors"
                >
                  {templateBusy ? 'Saving…' : 'Save Template'}
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
  return (
    <>
      <div
        ref={setNodeRef}
        style={style}
        onContextMenu={(e) => {
          e.preventDefault()
          setContextMenu({ x: e.clientX, y: e.clientY })
        }}
        className={`group relative border p-3 rounded-xl bg-surface transition-all duration-200 ${
          isDragging
            ? 'opacity-40 border-line scale-[1.02] shadow-lg shadow-black/30'
            : selected
              ? 'border-accent ring-1 ring-accent/30 bg-accent/5'
              : draggable
                ? 'border-line hover:border-accent-dim hover:shadow-sm hover:shadow-black/10'
                : 'border-line hover:border-accent-dim'
        }`}
      >
            {/* Selection checkbox */}
            {onToggleSelect && (
              <div className="absolute top-2.5 left-2.5 z-10">
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    onToggleSelect()
                  }}
                  className={`focus-ring cursor-pointer w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all duration-150 ${
                    selected
                      ? 'bg-accent border-accent text-white scale-100 opacity-100'
                      : 'border-muted/40 bg-black/20 opacity-0 group-hover:opacity-100 group-hover:scale-100 scale-75 hover:border-accent/60'
                  }`}
                  aria-label={selected ? 'Deselect project' : 'Select project'}
                >
                  {selected && <IconCheckCircle className="w-3.5 h-3.5" fill="currentColor" />}
                </button>
              </div>
            )}

            {/* Version warning indicator */}
            {versionWarning && (
              <Tooltip
                content={
                  versionWarning === 'not_found'
                    ? `Godot ${project.godot_version} is not installed. Select a version from the dropdown before opening.`
                    : `Godot ${project.godot_version} may have compatibility issues. No matching installed version found.`
                }
                side="top"
              >
                <div className="absolute top-2.5 right-2.5 z-10">
                  <IconAlertTriangle className="w-4 h-4 text-amber" />
                </div>
              </Tooltip>
            )}

            <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-xl">
              {icon ? (
                <img
                  src={icon}
                  alt=""
                  aria-hidden="true"
                  className="select-none absolute -left-6 top-1/2 -translate-y-1/2 -rotate-6 group-hover:rotate-0 h-35 w-35 object-contain opacity-[0.14] grayscale group-hover:grayscale-0 contrast-125 transition-all duration-300 ease-out will-change-transform"
                  style={{
                    maskImage:
                      'linear-gradient(to right, black 35%, transparent 90%)',
                    WebkitMaskImage:
                      'linear-gradient(to right, black 35%, transparent 90%)',
                  }}
                />
              ) : (
                <span
                  aria-hidden="true"
                  className="select-none absolute -left-3 top-1/2 -translate-y-1/2 -rotate-6 group-hover:rotate-0 font-display font-black text-muted group-hover:text-accent-bright transition-all duration-300 ease-out will-change-transform"
                  style={{
                    fontSize: '72px',
                    lineHeight: 1,
                    opacity: 0.14,
                    maskImage:
                      'linear-gradient(to right, black 35%, transparent 90%)',
                    WebkitMaskImage:
                      'linear-gradient(to right, black 35%, transparent 90%)',
                  }}
                >
                  {getInitials(displayName)}
                </span>
              )}
            </div>
            <div className="flex items-center gap-3.5 min-w-0">
              {draggable && (
                <IconGrip
                  {...dragHandleProps}
                  className="w-4 h-4 text-muted/30 group-hover:text-muted/70 shrink-0 opacity-0 group-hover:opacity-100 scale-50 group-hover:scale-100 transition-all duration-200 ease-out touch-none cursor-grab active:cursor-grabbing"
                />
              )}
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-1.5">
                  <h3 className="font-display font-medium text-lg truncate">
                    {displayName}
                  </h3>
                  <button
                    onClick={onTogglePin}
                    aria-label={project.pinned ? 'Unpin project' : 'Pin project'}
                    className={`icon-wiggle focus-ring cursor-pointer shrink-0 p-1 rounded-md transition-colors ${
                      project.pinned
                        ? 'text-accent-bright opacity-100'
                        : 'text-muted/40 opacity-0 group-hover:opacity-100 hover:text-muted hover:bg-raised'
                    }`}
                  >
                    <IconPin
                      className="w-3.5 h-3.5"
                      fill={project.pinned ? 'currentColor' : 'none'}
                    />
                  </button>
                </div>
                  <button
                    type="button"
                    onClick={openFolder}
                    className="text-[11px] px-3 py-1.5 mb-1 bg-base rounded-md text-muted font-mono truncate block w-fit text-left hover:text-accent-bright cursor-pointer transition-colors"
                  >
                    {project.path}
                  </button>
              </div>
            </div>
            <div className="flex items-center gap-2.5 flex-wrap justify-between">
              <div className="flex items-center gap-2.5 flex-wrap min-w-0">
                {lastOpenedLabel && (
                  <Tooltip content={`Last opened ${lastOpenedLabel}`}>
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-raised border border-line font-mono text-[11px] text-muted shrink-0">
                      <IconClock className="w-3 h-3" />
                      {lastOpenedLabel}
                    </span>
                  </Tooltip>
                )}
                {gitStatus?.is_repo && (
                  <Tooltip
                    content={
                      gitStatus.has_uncommitted
                        ? `${gitStatus.branch ?? 'HEAD'} has uncommitted changes (click for details)`
                        : `${gitStatus.branch ?? 'HEAD'} > clean (click for details)`
                    }
                  >
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation()
                        onShowGitSidebar?.()
                      }}
                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg font-mono text-[11px] border shrink-0 transition-colors hover:border-accent-dim ${
                        gitStatus.has_uncommitted
                          ? 'bg-amber/10 border-amber/30 text-amber'
                          : 'bg-raised border-line text-muted'
                      }`}
                    >
                      <IconGitBranch className="w-3 h-3" />
                      {gitStatus.branch ?? 'HEAD'}
                      {gitStatus.has_uncommitted && <span className="w-1.5 h-1.5 rounded-full bg-amber ml-0.5" />}
                    </button>
                  </Tooltip>
                )}
                {project.pinned && categoriesEnabled && (() => {
                  const cat = categories.find((c) => c.name === project.category)
                  const catColor = cat?.color ?? '#949ba4'
                  return (
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-raised border border-line font-mono text-[11px] text-muted shrink-0">
                      <span
                        className="w-1.5 h-1.5 rounded-full shrink-0 ring-1 ring-black/10"
                        style={{ backgroundColor: catColor }}
                      />
                      {project.category ?? 'Uncategorized'}
                    </span>
                  )
                })()}

                <Dropdown
                  className="w-40 shrink-0"
                  value={project.godot_version}
                  onChange={onVersionChange}
                  options={installedVersions.map((v) => ({
                    value: v.tag,
                    label: v.custom_name || v.tag,
                    dotClassName: 'bg-mint',
                  }))}
                />
              </div>

              <div className="flex items-center gap-2.5 shrink-0 ml-auto">
                <motion.button
                  whileHover={versionInstalled ? { y: -1 } : undefined}
                  whileTap={versionInstalled ? { scale: 0.96 } : undefined}
                  disabled={!versionInstalled}
                  onClick={() =>
                    api
                      .openProject(project.id, true)
                      .then(() => onOpened?.())
                      .catch((e) => alert(e))
                  }
                  className="focus-ring cursor-pointer shrink-0 flex items-center justify-center gap-1.5 px-8 py-3 rounded-lg bg-accent hover:bg-accent-bright disabled:bg-raised disabled:text-muted disabled:cursor-not-allowed text-sm font-medium text-white transition-colors"
                >
                  <IconPlay className="w-3 h-3" />
                  Open Project
                </motion.button>
                <div ref={cardMoreRef} className="relative">
                  <button
                    onClick={() => {
                      const btnRect = cardMoreRef.current?.getBoundingClientRect()
                      if (btnRect) {
                        setCardMoreUp(window.innerHeight - btnRect.bottom < 210)
                      }
                      setCardMoreOpen((prev) => !prev)
                    }}
                    className="focus-ring cursor-pointer p-2.5 rounded-lg border border-line text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
                    aria-label="More actions"
                  >
                    <IconMore className="w-4 h-4" />
                  </button>
                  <AnimatePresence>
                    {cardMoreOpen && (
                      <motion.div
                        initial={{ opacity: 0, y: cardMoreUp ? 4 : -4, scale: 0.96 }}
                        animate={{ opacity: 1, y: 0, scale: 1 }}
                        exit={{ opacity: 0, y: cardMoreUp ? 4 : -4, scale: 0.96 }}
                        transition={{ duration: 0.12, ease: 'easeOut' }}
                        className={`absolute right-0 z-30 ${cardMoreUp ? 'bottom-full mb-1 origin-bottom' : 'mt-1 origin-top'} min-w-50 rounded-xl border border-line bg-surface shadow-2xl shadow-black/40 p-1.5`}
                      >
                        <button
                          type="button"
                          onClick={() => { setCardMoreOpen(false); onOpenProperties?.() }}
                          className="w-full flex items-center cursor-pointer gap-2.5 px-3 py-2 rounded-lg text-xs font-medium text-ink hover:bg-raised transition-colors"
                        >
                          <IconHardDrive className="w-3.5 h-3.5 text-muted" />
                          Project Size
                        </button>
                        <div className="h-px bg-line my-1" />
                        <button
                          type="button"
                          onClick={() => { setCardMoreOpen(false); setTemplateSaveOpen(true) }}
                          className="w-full flex items-center cursor-pointer gap-2.5 px-3 py-2 rounded-lg text-xs font-medium text-ink hover:bg-raised transition-colors"
                        >
                          <IconCopy className="w-3.5 h-3.5 text-muted" />
                          Save as Template
                        </button>
                        <div className="h-px bg-line my-1" />
                        <button
                          type="button"
                          onClick={() => { setCardMoreOpen(false); setConfirmAction('remove') }}
                          className="w-full flex items-center cursor-pointer gap-2.5 px-3 py-2 rounded-lg text-xs font-medium text-ink hover:bg-raised transition-colors"
                        >
                          <IconX className="w-3.5 h-3.5 text-muted" />
                          Remove from Library
                        </button>
                        <button
                          type="button"
                          onClick={() => { setCardMoreOpen(false); setConfirmAction('delete') }}
                          className="w-full flex items-center cursor-pointer gap-2.5 px-3 py-2 rounded-lg text-xs font-medium text-danger hover:bg-danger/10 transition-colors"
                        >
                          <IconTrash className="w-3.5 h-3.5" />
                          Delete Files
                        </button>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </div>
            </div>
      </div>

      {dialogs}

      <AnimatePresence>
        {contextMenu && (
          <ContextMenu
            position={contextMenu}
            onClose={() => setContextMenu(null)}
            items={buildContextMenuItems()}
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
    </>
  )

  function buildContextMenuItems(): ContextMenuSection[] {
    return [
      {
        label: 'Open Project',
        icon: IconPlay,
        onClick: () =>
          api
            .openProject(project.id, true)
            .then(() => onOpened?.())
            .catch((e) => alert(e)),
        disabled: !versionInstalled,
      },
      {
        label: 'Open Folder',
        icon: IconExternalLink,
        onClick: openFolder,
      },
      {
        label: 'Open in IDE',
        icon: IconCode,
        onClick: () => api.openInEditor(project.path).catch((e) => alert(e)),
      },
      { type: 'separator' },
      {
        label: 'Pinning',
        icon: IconPin,
        children: [
          {
            label: project.pinned ? 'Unpin from Library' : 'Pin to Library',
            icon: IconPin,
            onClick: onTogglePin,
          },
        ],
      },
      {
        label: 'Category',
        icon: IconTags,
        children: [
          {
            label: 'None',
            onClick: () => onCategoryChange(''),
            icon: IconX,
          },
          ...(categories.length > 0
            ? [
                { type: 'separator' as const },
                ...categories.map((cat) => ({
                  label: cat.name,
                  onClick: () => onCategoryChange(cat.name),
                  icon: IconTags,
                })),
              ]
            : []),
        ],
      },
      {
        label: 'Project Size',
        icon: IconHardDrive,
        onClick: () => onOpenProperties?.(),
      },
      {
        label: 'Launch Arguments…',
        icon: IconCode,
        onClick: () => setShowLaunchArgs(true),
      },
      {
        label: 'Save as Template',
        icon: IconCopy,
        onClick: () => setTemplateSaveOpen(true),
      },
      ...(gitStatus?.is_repo
        ? [
            { type: 'separator' as const },
            {
              label: 'Git',
              icon: IconGitBranch,
              onClick: () => onShowGitSidebar?.(),
            },
          ]
        : []),
      { type: 'separator' },
      {
        label: 'Remove from Library',
        icon: IconX,
        onClick: () => setConfirmAction('remove'),
      },
      {
        label: 'Delete Files',
        icon: IconTrash,
        variant: 'danger',
        onClick: () => setConfirmAction('delete'),
      },
    ]
  }
})
