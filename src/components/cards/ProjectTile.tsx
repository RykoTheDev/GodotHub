import { useState, type MouseEvent } from 'react'
import { AnimatePresence } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Category, GitStatus, InstalledGodotVersion, Project, ProjectViewMode } from '../../types'
import { api } from '../../lib/api'
import { tagColor } from '../../lib/colors'
import { formatDuration } from '../../lib/duration'
import { formatLastOpened } from '../../lib/lastOpened'
import { effectiveTotalMs } from '../../lib/projectSort'
import { getCardViewSettings } from '../../lib/cardViewSettings'
import { pushToast } from '../../lib/toast'
import { useSettings } from '../../hooks/useSettings'
import { useProjectTileData } from '../../hooks/useProjectTileData'
import { Dropdown, type NewDropdownItem } from '../ui/Dropdown'
import { OpenButton } from '../reusables/OpenButton'
import { Tooltip } from '../reusables/Tooltip'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { LaunchArgsModal } from '../modals/LaunchArgsModal'
import { TagManagerModal } from '../modals/TagManagerModal'
import { SaveAsTemplateModal } from '../modals/SaveAsTemplateModal'
import { ProjectSizeModal } from '../modals/ProjectSizeModal'
import { ProjectDoctorModal } from '../modals/ProjectDoctorModal'
import {
  IconCheck, IconChevronDown, IconClock, IconCode, IconCopy, IconExternalLink,
  IconGitBranch, IconHardDrive, IconHistory, IconNode, IconPin, IconPlay,
  IconPlus, IconRocket, IconTags, IconTerminal, IconTrash, IconX,
  IconBug,
} from '../../lib/icons'

export interface ProjectTileProps {
  project: Project
  installedVersions: InstalledGodotVersion[]
  categories?: Category[]
  gitStatus?: GitStatus | null
  launchWithConsole?: boolean
  compact?: boolean
  onTogglePin: () => void
  onVersionChange: (tag: string) => void
  onRemove: () => void
  onDelete?: () => void
  onCategoryChange?: (category: string) => void
  onDuplicate?: () => void
  onTagsSaved?: (project: Project) => void
  onTagClick?: (tag: string) => void
  onLaunchArgsChange?: (args: string) => void
  onShowGitSidebar?: () => void
  activeTag?: string | null
  selected?: boolean
  onToggleSelect?: (event: MouseEvent) => void
  viewMode?: ProjectViewMode
  preview?: boolean
}

function initials(name: string): string {
  const words = name.trim().split(/[\s_-]+/).filter(Boolean)
  return words.length > 1 ? `${words[0][0]}${words[1][0]}`.toUpperCase() : name.slice(0, 2).toUpperCase()
}

function formatSize(bytes: number): string {
  if (bytes >= 1024 ** 3) return `${(bytes / 1024 ** 3).toFixed(1)} GB`
  if (bytes >= 1024 ** 2) return `${(bytes / 1024 ** 2).toFixed(1)} MB`
  if (bytes >= 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${bytes} B`
}

export function ProjectTile({
  project, installedVersions, categories = [], gitStatus, launchWithConsole = false,
  compact = false, onTogglePin, onVersionChange, onRemove, onDelete, onCategoryChange,
  onDuplicate, onTagsSaved, onTagClick, onLaunchArgsChange, onShowGitSidebar,
  activeTag, selected = false, onToggleSelect, viewMode = 'grid', preview = false,
}: ProjectTileProps) {
  const { t } = useTranslation('common')
  const { settings } = useSettings()
  const options = getCardViewSettings(settings, viewMode)
  const { cardRef, icon, displayName, size, now } = useProjectTileData(project, options.show_size, preview)
  const [dialog, setDialog] = useState<'remove' | 'delete' | 'tags' | 'args' | 'template' | 'size' | 'doctor' | null>(null)
  const [brokenIcon, setBrokenIcon] = useState<string | null>(null)
  const grid = viewMode === 'grid'
  const version = installedVersions.find(entry => entry.tag === project.godot_version)
  const versionLabel = version?.custom_name || version?.tag || project.godot_version || t('no_version_selected')
  const unavailable = !!project.godot_version && !version
  const unavailableHint = installedVersions.length === 0
    ? t('no_engine_warning')
    : unavailable ? t('project_card_version_unavailable', { version: project.godot_version }) : t('no_version_selected')
  const running = !!project.session_started_at_ms
  const sessionMs = Math.max(0, now - (project.session_started_at_ms ?? now))
  const timeLabel = formatDuration(running ? sessionMs : effectiveTotalMs(project, now))
  const lastOpened = formatLastOpened(project.last_opened, settings.last_opened_time_format, settings.last_opened_date_format)
  const iconButton = 'focus-ring cursor-pointer flex shrink-0 h-7 w-7 items-center justify-center rounded-btn transition-colors disabled:cursor-not-allowed disabled:opacity-40'
  const launch = (console?: boolean) => window.dispatchEvent(new CustomEvent('app:open-project', { detail: { id: project.id, console } }))
  const runAction = (action: () => Promise<unknown>) => { void action().catch(error => pushToast('error', String(error))) }
  const openFolder = () => runAction(() => api.openProjectFolder(project.path))

  const menuItems: NewDropdownItem[] = [
    { key: 'project-doctor', label: t('title', {ns:'doctor'}), icon: IconBug, onClick: () => setDialog('doctor') },
    { key: 'pin', label: t(project.pinned ? 'project_unpin_aria' : 'project_pin_aria'), icon: IconPin, onClick: onTogglePin },
    ...(onLaunchArgsChange ? [{ key: 'launch-arguments', label: t('launch_arguments'), icon: IconRocket, onClick: () => setDialog('args') }] : []),
    { key: 'manage-tags', label: t('manage_tags'), icon: IconTags, onClick: () => setDialog('tags') },
    ...(onDuplicate ? [{ key: 'duplicate', label: t('duplicate_project'), icon: IconCopy, onClick: onDuplicate }] : []),
    ...(onCategoryChange ? [{ key: 'set-category', label: t('set_category'), icon: IconTags, children: [
      { key: 'uncategorized', label: t('uncategorized'), dotColor: '#949ba4', active: !project.category, onClick: () => onCategoryChange('') },
      ...categories.map(category => ({ key: category.id, label: category.name, dotColor: category.color, active: project.category === category.name, onClick: () => onCategoryChange(category.name) })),
    ] }] : []),
    { key: 'save-as-template', label: t('save_as_template'), icon: IconCopy, onClick: () => setDialog('template'), dividerAfter: true },
    { key: 'remove', label: t('project_card_remove_library'), icon: IconX, onClick: () => setDialog('remove') },
    ...(onDelete ? [{ key: 'delete', label: t('project_card_delete_files'), icon: IconTrash, danger: true, onClick: () => setDialog('delete') }] : []),
  ]

  return (
    <article ref={cardRef} aria-label={displayName} data-card-view={viewMode} data-card-id={project.id}
      className={`group/tile relative flex min-w-0 flex-col gap-3 rounded-item border transition-colors duration-150 ${grid ? 'h-full min-h-[260px] p-4' : compact ? 'p-3' : 'p-3.5'} ${selected ? 'border-accent bg-accent/5 ring-1 ring-accent/25' : 'border-outline/50 bg-overlay hover:border-accent-dim/50'}`}>
      <div className="flex items-start gap-3 min-w-0">
        <div aria-hidden="true" className={`flex shrink-0 items-center justify-center overflow-hidden rounded-tile border border-outline/40 bg-raised ${grid ? 'h-12 w-12' : compact ? 'h-9 w-9' : 'h-10 w-10'}`}>
          {icon && icon !== brokenIcon ? <img src={icon} onError={() => setBrokenIcon(icon)} alt="" draggable={false} decoding="async" className="h-full w-full object-contain p-1" />
            : <span className="select-none font-display text-sm font-semibold text-accent-bright/80">{initials(displayName)}</span>}
        </div>
        <h3 title={displayName} className={`min-w-0 flex-1 line-clamp-2 wrap-break-word font-display font-semibold leading-snug text-ink ${grid ? 'text-base' : compact ? 'text-[13px]' : 'text-[15px]'}`}>{displayName}</h3>
        <div className="flex shrink-0 flex-col items-center gap-1">
          <button type="button" onClick={onTogglePin} disabled={preview} aria-label={t(project.pinned ? 'project_unpin_aria' : 'project_pin_aria')} aria-pressed={project.pinned}
            title={t(project.pinned ? 'project_unpin_aria' : 'project_pin_aria')}
            className={`${iconButton} ${project.pinned ? 'bg-accent/10 text-accent-bright hover:bg-accent/20' : 'text-muted/70 hover:bg-raised hover:text-ink'}`}>
            <IconPin className="h-3.5 w-3.5" />
          </button>
          {onToggleSelect && <button type="button" disabled={preview} onClick={onToggleSelect} aria-label={t(selected ? 'project_deselect_aria' : 'project_select_aria')} aria-pressed={selected}
            className={`${iconButton} ${selected ? 'bg-accent text-white' : 'border border-line bg-raised text-muted/60 hover:border-accent-dim hover:text-ink'}`}>
            <IconCheck className={`h-3.5 w-3.5 ${selected ? '' : 'opacity-30'}`} />
          </button>}
        </div>
      </div>

      {options.show_path && <Tooltip content={project.path} className="w-full min-w-0">
        <button type="button" dir="ltr" onClick={openFolder} disabled={preview} aria-label={t('open_folder')}
          className={`focus-ring min-w-0 w-full cursor-pointer truncate rounded-btn px-1 py-0.5 text-left font-mono text-[11px] text-muted/70 transition-colors hover:text-accent-bright ${options.blur_path ? 'blur-sm hover:blur-none focus-visible:blur-none' : ''}`}>
          {project.path}
        </button>
      </Tooltip>}

      {gitStatus?.is_repo && onShowGitSidebar && <button type="button" onClick={onShowGitSidebar} disabled={preview} aria-label={t('git_sidebar')}
        title={`${gitStatus.branch ?? ''} · ${t(gitStatus.has_uncommitted ? 'git_uncommitted' : 'git_clean')}`}
        className={`focus-ring flex w-fit max-w-full min-w-0 cursor-pointer items-center gap-1.5 rounded-tag px-2 py-1 text-[11px] transition-colors ${gitStatus.has_uncommitted ? 'bg-amber/10 text-amber hover:bg-amber/15' : 'bg-raised text-muted hover:text-ink'}`}>
        <IconGitBranch className="h-3 w-3 shrink-0" /><span className="min-w-0 truncate">{gitStatus.branch || t('git_sidebar')}</span>
        {gitStatus.has_uncommitted && <span aria-hidden="true" className="h-1.5 w-1.5 shrink-0 rounded-full bg-amber" />}
      </button>}

      {(options.show_time || options.show_size || (options.show_last_opened && lastOpened)) && <div className="flex min-h-5 flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-muted/70">
        {options.show_time && (running || effectiveTotalMs(project, now) > 0) && <span title={running ? t('running') : t('project_card_total_time', { time: timeLabel })} className={`inline-flex items-center gap-1.5 font-mono ${running ? 'text-accent-bright' : ''}`}>
          {running ? <span aria-hidden="true" className="h-1.5 w-1.5 shrink-0 rounded-full bg-accent-bright animate-pulse" /> : <IconClock className="h-3 w-3" />}{timeLabel}
        </span>}
        {options.show_size && <button type="button" onClick={() => setDialog('size')} disabled={preview} aria-label={t('project_size')} title={t('project_size')}
          className="focus-ring cursor-pointer inline-flex items-center gap-1.5 rounded-btn px-1 py-0.5 hover:text-ink transition-colors">
          <IconHardDrive className="h-3 w-3 shrink-0" />
          {size === undefined ? <span aria-hidden="true" className="inline-block h-2.5 w-10 rounded bg-raised" /> : size === null ? ':' : formatSize(size)}
        </button>}
        {options.show_last_opened && lastOpened && <span title={t('project_card_last_opened', { date: new Date(project.last_opened!).toLocaleString() })} className="inline-flex items-center gap-1.5">
          <IconHistory className="h-3 w-3 shrink-0" />{lastOpened}
        </span>}
      </div>}

      {options.show_tags && <div className="flex items-start gap-1.5 min-w-0">
        <div className="flex min-w-0 flex-1 flex-wrap gap-1.5">
          {project.tags.slice(0, grid ? 3 : 2).map(tag => <button key={tag} type="button" disabled={preview} onClick={() => onTagClick ? onTagClick(tag) : setDialog('tags')}
            aria-pressed={activeTag === tag} title={tag}
            className={`focus-ring cursor-pointer flex h-6 max-w-28 min-w-0 items-center gap-1.5 rounded-tag px-2 text-[10px] font-medium transition-[filter] hover:brightness-125 ${activeTag === tag ? 'ring-1 ring-accent-dim' : ''}`}
            style={{ backgroundColor: `${tagColor(tag)}18`, color: tagColor(tag) }}>
            <span className="h-1 w-1 shrink-0 rounded-full" style={{ backgroundColor: tagColor(tag) }} /><span className="min-w-0 truncate">{tag}</span>
          </button>)}
          {project.tags.length > (grid ? 3 : 2) && <button type="button" disabled={preview} onClick={() => setDialog('tags')}
            aria-label={t('project_card_more_tags', { count: project.tags.length - (grid ? 3 : 2) })}
            className="focus-ring cursor-pointer h-6 rounded-tag bg-raised px-2 text-[10px] text-muted hover:text-ink">+{project.tags.length - (grid ? 3 : 2)}</button>}
          {project.tags.length === 0 && <button type="button" disabled={preview} onClick={() => setDialog('tags')}
            className="focus-ring cursor-pointer inline-flex h-7 items-center gap-1 rounded-btn border border-dashed border-outline/50 px-2 text-[11px] text-muted/70 hover:text-ink hover:bg-raised transition-colors">
            <IconPlus className="h-2.5 w-2.5" />{t('add_tag')}
          </button>}
        </div>
        {project.tags.length > 0 && <button type="button" disabled={preview} onClick={() => setDialog('tags')} aria-label={t('manage_tags')} title={t('manage_tags')}
          className={`${iconButton} text-muted/60 hover:bg-raised hover:text-ink`}><IconTags className="h-3 w-3" /></button>}
      </div>}

      <div className="mt-auto flex min-w-0 flex-col gap-2 border-t border-outline/30 pt-3">
        <Dropdown align="left" className="w-full min-w-0" trigger={({ open, toggle }) => <button type="button" onClick={toggle} disabled={preview || installedVersions.length === 0} aria-label={t('godot_version_label')} aria-expanded={open}
          title={!version ? unavailableHint : t('godot_version_label')}
          className={`focus-ring flex w-full min-w-0 cursor-pointer items-center gap-2 rounded-btn border border-outline/50 bg-raised px-2.5 py-2 text-[11px] transition-colors hover:border-accent-dim disabled:cursor-not-allowed disabled:opacity-60 ${unavailable ? 'text-amber' : 'text-muted'}`}>
          <IconNode className="h-3 w-3 shrink-0" /><span className="min-w-0 flex-1 truncate text-left">{versionLabel}</span><IconChevronDown className="h-2.5 w-2.5 shrink-0" />
        </button>} items={installedVersions.map(entry => ({ key: entry.tag, label: entry.custom_name || entry.tag, badge: entry.custom_name && entry.custom_name !== entry.tag ? entry.tag : undefined, active: entry.tag === project.godot_version, onClick: () => onVersionChange(entry.tag) }))} />
        {!version && <p className="px-1 text-[10px] leading-relaxed text-muted/70">{unavailableHint}</p>}
        <div className="flex min-w-0 items-stretch gap-1.5">
          {options.show_play && <button type="button" onClick={() => runAction(() => api.openProject(project.id, false))} disabled={!version || preview}
            aria-label={t('play_project_tooltip')} title={!version ? unavailableHint : t('play_project_tooltip')}
            className="focus-ring flex h-9 w-9 shrink-0 cursor-pointer items-center justify-center rounded-btn border border-outline/50 bg-raised text-muted hover:text-mint hover:border-mint/40 transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
            <IconPlay className="h-3 w-3" />
          </button>}
          <OpenButton label={t('open_project')} disabled={!version || preview} disabledReason={unavailableHint} size="compact" onOpen={launch}
            consoleSupported={version?.supports_console ?? false} consoleInitiallyOn={launchWithConsole} showConsole={options.show_console}
            moreAriaLabel={t('project_more_aria')} items={menuItems}
            headerItems={[
              { key: 'folder', label: t('open_folder'), icon: IconExternalLink, tooltip: t('open_folder'), onClick: openFolder },
              { key: 'ide', label: t('open_in_ide'), icon: IconCode, tooltip: t('open_in_ide'), onClick: () => runAction(() => api.openInEditor(project.path)) },
              { key: 'terminal', label: t('open_terminal'), icon: IconTerminal, tooltip: t('open_terminal'), onClick: () => runAction(() => api.openTerminal(project.path)) },
            ]} />
        </div>
      </div>

      <AnimatePresence>
        {dialog === 'remove' && <ConfirmDialog title={t('project_remove_title')} description={t('project_remove_desc', { name: displayName })} confirmLabel={t('project_remove_confirm')}
          onConfirm={() => { setDialog(null); onRemove() }} onCancel={() => setDialog(null)} />}
        {dialog === 'delete' && onDelete && <ConfirmDialog title={t('project_delete_title')} description={t('project_delete_desc', { name: displayName })} confirmLabel={t('project_delete_confirm')} variant="danger"
          onConfirm={() => { setDialog(null); onDelete() }} onCancel={() => setDialog(null)} />}
        {dialog === 'tags' && <TagManagerModal project={project} onClose={() => setDialog(null)} onSaved={updated => onTagsSaved?.(updated)} />}
        {dialog === 'args' && <LaunchArgsModal projectName={displayName} currentArgs={project.launch_arguments} onSave={args => { onLaunchArgsChange?.(args); setDialog(null) }} onClose={() => setDialog(null)} />}
        {dialog === 'template' && <SaveAsTemplateModal project={project} onClose={() => setDialog(null)} />}
        {dialog === 'size' && <ProjectSizeModal projectPath={project.path} projectName={displayName} onClose={() => setDialog(null)} />}
        {dialog === 'doctor' && <ProjectDoctorModal project={project} installedVersions={installedVersions} onClose={() => setDialog(null)} />}
      </AnimatePresence>
    </article>
  )
}
