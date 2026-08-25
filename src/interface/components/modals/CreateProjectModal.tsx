import { useEffect, useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type {
  GitAuthState,
  InstalledGodotVersion,
  ProjectTemplate,
} from '../../../types'
import { api } from '../../../lib/api'
import { applyNamingConvention } from '../../../lib/namingConvention'
import { useSettings } from '../../../hooks/useSettings'
import { TemplatePreviewModal } from './TemplatePreviewModal'
import { Toggle } from '../ui/Toggle'
import { Checkbox } from '../ui/Checkbox'
import {
  IconFolderPlus,
  IconCheck,
  IconBookOpen,
  IconAlertTriangle,
  IconSpinner,
} from '../../lib/icons'

interface Props {
  installedVersions: InstalledGodotVersion[]
  defaultLocation?: string | null
  initialTemplateId?: string | null
  onClose: () => void
  onCreated: () => void
}

const ICON_PRESET_SVG = (
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={1.5}
    className="w-6 h-6 text-muted"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Zm16.5-13.5h.008v.008h-.008V7.5Z"
    />
  </svg>
)

export function CreateProjectModal({
  installedVersions,
  defaultLocation,
  initialTemplateId = null,
  onClose,
  onCreated,
}: Props) {
  const { t } = useTranslation('common')
  const { settings } = useSettings()
  const [name, setName] = useState('')
  const [location, setLocation] = useState(defaultLocation ?? '')
  const [version, setVersion] = useState(installedVersions[0]?.tag ?? '')
  const [iconPath, setIconPath] = useState<string | null>(null)
  const [iconPreview, setIconPreview] = useState<string | null>(null)
  const [templateId, setTemplateId] = useState<string | null>(initialTemplateId)
  const [previewTemplate, setPreviewTemplate] = useState<ProjectTemplate | null>(null)
  const [templates, setTemplates] = useState<ProjectTemplate[]>([])
  const [error, setError] = useState<string | null>(null)
  const [initGit, setInitGit] = useState(settings.git_init_new_projects)
  const [gitGitignore, setGitGitignore] = useState(true)
  const [gitGitattributes, setGitGitattributes] = useState(true)
  const [gitReadme, setGitReadme] = useState(false)
  const [gitLicense, setGitLicense] = useState('')
  const [gitAvailable, setGitAvailable] = useState(true)
  const [gitWarning, setGitWarning] = useState<string | null>(null)
  const [remoteSuccess, setRemoteSuccess] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [initializingGit, setInitializingGit] = useState(false)
  const [creatingRemote, setCreatingRemote] = useState(false)
  const [attempted, setAttempted] = useState(false)
  const [gitAuth, setGitAuth] = useState<GitAuthState | null>(null)
  const [remoteEnabled, setRemoteEnabled] = useState(false)
  const [remoteProvider, setRemoteProvider] = useState<'github' | 'gitlab'>(
    'github',
  )
  const [remotePrivate, setRemotePrivate] = useState(true)
  const nameInputRef = useRef<HTMLInputElement>(null)

  const folderName = useMemo(
    () => applyNamingConvention(name, settings.directory_naming_convention),
    [name, settings.directory_naming_convention],
  )

  const projectNamePlaceholder = useMemo(() => {
    const names = [
      'My Awesome Game',
      'Untitled Masterpiece',
      'Project Nebula',
      'Game of the Year',
      'Probably Nothing',
      'Friday Night Project',
      'Yet Another Platformer',
      'The Next Big Thing',
      'workspace_simulator',
      'Definitely Not Flappy Bird',
      'Super Secret Project',
      'Roguelike #4',
      'Ctrl+S Adventure',
      'Pixels & Dreams',
      'v0.0.1 - The Beginning',
      'Procrastination.exe',
      'Rapid Unplanned Disassembly',
      'Another One Bites the Dust',
      'Jam Entry 2026',
      'Open World Survival Thing',
    ]
    return names[Math.floor(Math.random() * names.length)]
  }, [])

  useEffect(() => {
    api.listTemplates().then(setTemplates).catch(() => {})
  }, [])

  useEffect(() => {
    api
      .gitIsAvailable()
      .then((available) => {
        setGitAvailable(available)
        if (!available) setInitGit(false)
      })
      .catch(() => {})
  }, [])

  useEffect(() => {
    api
      .gitAuthGetState()
      .then((state) => {
        setGitAuth(state)
        if (state.github && !state.gitlab) setRemoteProvider('github')
        else if (state.gitlab && !state.github) setRemoteProvider('gitlab')
      })
      .catch(() => {})
  }, [])

  useEffect(() => {
    nameInputRef.current?.focus()
  }, [])

  useEffect(() => {
    if (!iconPath) {
      setIconPreview(null)
      return
    }
    let cancelled = false
    api
      .readImageFile(iconPath)
      .then((data) => {
        if (!cancelled) setIconPreview(data)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [iconPath])

  const dismiss = () => {
    if (gitWarning || remoteSuccess) onCreated()
    else onClose()
  }

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (gitWarning || remoteSuccess) onCreated()
        else onClose()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [gitWarning, remoteSuccess, onClose, onCreated])

  const pickLocation = async () => {
    const folder = await api.pickFolder()
    if (folder) {
      setLocation(folder)
      setError(null)
    }
  }

  const pickIcon = async () => {
    const file = await api.pickFile()
    if (file) setIconPath(file)
  }

  const clearIcon = () => {
    setIconPath(null)
    setIconPreview(null)
  }

  const nameInvalid = attempted && !name.trim()
  const locationInvalid = attempted && !location

  const submit = async () => {
    if (busy || gitWarning || remoteSuccess) return
    if (!name.trim() || !location) {
      setAttempted(true)
      setError(t('create_project_error'))
      return
    }
    setBusy(true)
    setError(null)
    try {
      const project = await api.createProject(
        name.trim(),
        location,
        version,
        iconPath,
        templateId,
        null,
      )
      if (initGit) {
        setInitializingGit(true)
        try {
          const outcome = await api.gitInitProject(project.path, {
            gitignore: gitGitignore,
            gitattributes: gitGitattributes,
            readme: gitReadme,
            license: gitLicense || null,
          })
          if (outcome.warning) {
            setGitWarning(outcome.warning)
            return
          }
        } catch (e) {
          setGitWarning(String(e))
          return
        } finally {
          setInitializingGit(false)
        }
      }
      if (remoteEnabled && (gitAuth?.github || gitAuth?.gitlab)) {
        setCreatingRemote(true)
        try {
          const result = await api.gitAuthCreateRemoteRepo(
            remoteProvider,
            name.trim(),
            remotePrivate,
            project.path,
          )
          setRemoteSuccess(result.url)
          return
        } catch (e) {
          setGitWarning(String(e))
          return
        } finally {
          setCreatingRemote(false)
        }
      }
      onCreated()
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const inputClass = (invalid: boolean) =>
    `focus-ring bg-overlay border rounded-item px-3.5 py-2.5 text-sm font-mono text-ink placeholder:text-muted/70 transition-colors ${
      invalid ? 'border-danger/70 focus:border-danger' : 'border-outline/50 focus:border-accent-dim'
    }`

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dialog-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dialog-close'))
    }
  }, [])

  const chipClass = (active: boolean) =>
    active
      ? 'focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-1.5 rounded-btn border text-xs font-medium transition-colors'
      : 'focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-1.5 rounded-btn border border-outline/50 text-muted hover:border-accent-dim hover:text-ink hover:bg-raised text-xs font-medium transition-colors'

  return createPortal(
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={dismiss}
    >
      <motion.div
        initial={{ opacity: 0, y: 14, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface rounded-modal w-full max-w-2xl max-h-[88vh] flex flex-col shadow-2xl overflow-clip"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-4 p-5 pb-2">
          <div className="flex items-start gap-1 w-full bg-black/15 px-3 py-4 rounded-btn shrink-0">
            <div className="w-10 h-10 rounded-tile flex items-center justify-center shrink-0">
              <IconFolderPlus className="w-5 h-5 text-accent-bright" />
            </div>
            <div className="min-w-0">
              <h3 className="uppercase font-semibold text-xl text-ink">
                {t('create_project_title')}
              </h3>
              <p className="text-xs text-muted mt-0.5">
                {t('create_project_desc')}
              </p>
            </div>
          </div>
        </div>

        <div className="gap-6 p-6 flex-1 overflow-y-auto">
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-0.5">
              <label className="pl-3 text-xs font-medium text-muted">
                {t('project_name_label')}
              </label>
              <input
                ref={nameInputRef}
                value={name}
                onChange={(e) => {
                  setName(e.target.value)
                  if (error) setError(null)
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') submit()
                }}
                className={`${inputClass(nameInvalid)} w-full`}
                placeholder={projectNamePlaceholder}
              />
              <div className="flex items-center ml-2 mt-1 gap-1.5 text-[10px] font-mono text-muted/60">
                <IconFolderPlus className="w-3 h-3 text-accent-bright/70 shrink-0" />
                <span className="truncate">
                  {name.trim()
                    ? t('folder_name_preview', { name: folderName })
                    : t('folder_name_hint')}
                </span>
              </div>
            </div>

            <div className="flex flex-col gap-0.5">
              <label className="pl-3 text-xs font-medium text-muted">
                {t('project_location_label')}
              </label>
              <div className="flex gap-2.5">
                <input
                  value={location}
                  readOnly
                  onClick={pickLocation}
                  className={`${inputClass(locationInvalid)} flex-1 font-mono text-muted truncate`}
                  placeholder={t('choose_folder_placeholder')}
                />
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={pickLocation}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm transition-colors shrink-0"
                >
                  {t('browse')}
                </motion.button>
              </div>
            </div>

            {templates.length > 0 && (
              <div className="flex flex-col gap-2">
                <label className="text-xs font-medium text-muted">
                  {t('template_optional')}
                </label>
                <div className="flex flex-wrap gap-1.5">
                  <button
                    type="button"
                    onClick={() => setTemplateId(null)}
                    className={`${chipClass(templateId === null)} ${
                      templateId === null
                        ? 'border-accent bg-accent/10 text-accent-bright'
                        : ''
                    }`}
                  >
                    {templateId === null && (
                      <IconCheck className="w-3 h-3 inline mr-1 -mt-0.5" />
                    )}
                    {t('blank_template')}
                  </button>
                  {templates.map((tpl) => (
                    <span key={tpl.id} className="relative inline-flex group">
                      <button
                        type="button"
                        onClick={() => setTemplateId(tpl.id)}
                        className={`${chipClass(templateId === tpl.id)} ${
                          templateId === tpl.id
                            ? 'border-accent bg-accent/10 text-accent-bright'
                            : ''
                        }`}
                      >
                        {templateId === tpl.id && (
                          <IconCheck className="w-3 h-3 inline mr-1 -mt-0.5" />
                        )}
                        {tpl.name}
                      </button>
                      <button
                        type="button"
                        onClick={() => setPreviewTemplate(tpl)}
                        aria-label={t('template_preview_aria', { name: tpl.name })}
                        className="focus-ring cursor-pointer absolute -top-2 -right-2 w-5 h-5 rounded-full bg-surface border border-line text-muted hover:text-accent-bright hover:border-accent-dim shadow-md flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all"
                      >
                        <IconBookOpen className="w-3 h-3" />
                      </button>
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div className="flex flex-col gap-5">
              <div className="flex flex-col gap-2">
                <label className="text-xs font-medium text-muted">
                  {t('godot_version_label')}
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {installedVersions.map((v) => {
                    const active = version === v.tag
                    return (
                      <button
                        key={v.tag}
                        type="button"
                        onClick={() => setVersion(v.tag)}
                        className={`${chipClass(active)} ${
                          active
                            ? 'border-mint bg-mint/10 text-mint'
                            : ''
                        }`}
                      >
                        {active && <IconCheck className="w-3 h-3 inline -mt-0.5" />}
                        <span className="w-1.5 h-1.5 rounded-full bg-mint shrink-0" />
                        {v.custom_name || v.tag}
                        {v.is_mono && (
                          <span className="text-[9px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-tag bg-mint/15 text-mint border border-mint/25 shrink-0">
                            Mono
                          </span>
                        )}
                      </button>
                    )
                  })}
                </div>
                {installedVersions.length === 0 && (
                  <p className="text-xs text-amber">
                    {t('no_engine_warning')}
                  </p>
                )}
              </div>

            </div>

            <div className="flex items-center gap-3.5">
              <div className="w-14 h-14 rounded-tile border border-outline/50 bg-overlay flex items-center justify-center overflow-hidden shrink-0">
                {iconPreview ? (
                  <img
                    src={iconPreview}
                    alt=""
                    className="w-full h-full object-contain"
                  />
                ) : (
                  ICON_PRESET_SVG
                )}
              </div>
              <div className="flex flex-col gap-1.5 flex-1 min-w-0">
                <div className="flex gap-2">
                  <motion.button
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    onClick={pickIcon}
                    className="focus-ring cursor-pointer px-3 py-2 rounded-btn border border-outline/50 hover:border-accent-dim hover:bg-raised text-xs transition-colors"
                  >
                    {iconPath ? t('change_icon') : t('choose_icon')}
                  </motion.button>
                  {iconPath && (
                    <motion.button
                      initial={{ opacity: 0, scale: 0.9 }}
                      animate={{ opacity: 1, scale: 1 }}
                      whileHover={{ y: -1 }}
                      whileTap={{ scale: 0.96 }}
                      onClick={clearIcon}
                      className="focus-ring cursor-pointer px-3 py-2 rounded-btn border border-outline/50 text-muted hover:text-danger hover:border-danger/30 hover:bg-danger/10 text-xs transition-colors"
                    >
                      {t('reset_icon')}
                    </motion.button>
                  )}
                </div>
                {iconPath && (
                  <p className="text-[10px] text-muted/60 font-mono truncate">
                    {iconPath}
                  </p>
                )}
                <p className="text-[10px] text-muted/40">
                  {t('icon_format_desc')}
                </p>
              </div>
            </div>

            <div className="flex flex-col gap-3 pt-5 border-t border-line">
              <label className="text-xs font-medium text-muted">
                {t('other_settings_label')}
              </label>
              <label className="flex items-center justify-between gap-4">
                <div className="min-w-0">
                  <span className="text-xs font-medium text-ink block">
                    {t('init_git_label')}
                  </span>
                  <p className="text-[11px] text-muted mt-1 leading-relaxed">
                    {gitAvailable ? t('init_git_desc') : t('init_git_unavailable')}
                  </p>
                </div>
                <Toggle
                  checked={initGit}
                  onChange={setInitGit}
                  disabled={busy || !gitAvailable || gitWarning !== null || remoteSuccess !== null}
                  label={t('init_git_label')}
                />
              </label>

              {initGit && gitAvailable && (
                <div className="flex flex-col gap-2.5 rounded-item border border-outline/50 bg-overlay p-3.5">
                  <div className="flex flex-wrap gap-x-5 gap-y-2">
                    <Checkbox
                      checked={gitGitignore}
                      onChange={setGitGitignore}
                      disabled={busy}
                    >
                      {t('git_option_gitignore')}
                    </Checkbox>
                    <Checkbox
                      checked={gitGitattributes}
                      onChange={setGitGitattributes}
                      disabled={busy}
                    >
                      {t('git_option_gitattributes')}
                    </Checkbox>
                    <Checkbox
                      checked={gitReadme}
                      onChange={setGitReadme}
                      disabled={busy}
                    >
                      {t('git_option_readme')}
                    </Checkbox>
                  </div>
                  <div className="flex items-center gap-3">
                    <label className="text-xs font-medium text-muted shrink-0">
                      {t('git_option_license')}
                    </label>
                    <div className="flex flex-wrap gap-1.5">
                      <button
                        type="button"
                        onClick={() => setGitLicense('')}
                        className={`${chipClass(gitLicense === '')} ${
                          gitLicense === ''
                            ? 'border-outline/60 text-muted'
                            : ''
                        }`}
                      >
                        {t('git_option_no_license')}
                      </button>
                      {['MIT', 'Apache-2.0', 'GPL-3.0', 'Unlicense'].map((lic) => (
                        <button
                          key={lic}
                          type="button"
                          onClick={() => setGitLicense(lic)}
                          className={`${chipClass(gitLicense === lic)} ${
                            gitLicense === lic
                              ? 'border-accent bg-accent/10 text-accent-bright'
                              : ''
                          }`}
                        >
                          {gitLicense === lic && (
                            <IconCheck className="w-3 h-3 inline -mt-0.5" />
                          )}
                          {lic}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {(gitAuth?.github || gitAuth?.gitlab) && (
                <div className="flex flex-col gap-2.5 pt-1">
                  <label className="flex items-center justify-between gap-4">
                    <div className="min-w-0">
                      <span className="text-xs font-medium text-ink block">
                        {t('create_remote_label')}
                      </span>
                      <p className="text-[11px] text-muted mt-1 leading-relaxed">
                        {t('create_remote_desc')}
                      </p>
                    </div>
                    <Toggle
                      checked={remoteEnabled}
                      onChange={(v) => {
                        setRemoteEnabled(v)
                        if (v && !initGit) setInitGit(true)
                      }}
                      disabled={busy || !initGit || !gitAvailable || gitWarning !== null || remoteSuccess !== null}
                      label={t('create_remote_label')}
                    />
                  </label>

                  {remoteEnabled && (
                    <div className="flex flex-col gap-2.5 rounded-item border border-outline/50 bg-overlay p-3">
                      <div className="flex flex-wrap gap-1.5">
                        {gitAuth?.github && (
                          <button
                            type="button"
                            onClick={() => setRemoteProvider('github')}
                            className={`${chipClass(remoteProvider === 'github')} ${
                              remoteProvider === 'github'
                                ? 'border-accent bg-accent/10 text-accent-bright'
                                : ''
                            }`}
                          >
                            {remoteProvider === 'github' && (
                              <IconCheck className="w-3 h-3 inline -mt-0.5" />
                            )}
                            GitHub
                          </button>
                        )}
                        {gitAuth?.gitlab && (
                          <button
                            type="button"
                            onClick={() => setRemoteProvider('gitlab')}
                            className={`${chipClass(remoteProvider === 'gitlab')} ${
                              remoteProvider === 'gitlab'
                                ? 'border-accent bg-accent/10 text-accent-bright'
                                : ''
                            }`}
                          >
                            {remoteProvider === 'gitlab' && (
                              <IconCheck className="w-3 h-3 inline -mt-0.5" />
                            )}
                            GitLab
                          </button>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => setRemotePrivate(true)}
                          className={`flex-1 px-3 py-1.5 rounded-btn border text-xs font-medium transition-colors ${
                            remotePrivate
                              ? 'border-mint bg-mint/10 text-mint'
                              : 'border-outline/50 text-muted hover:border-accent-dim hover:text-ink'
                          }`}
                        >
                          {t('remote_private')}
                        </button>
                        <button
                          type="button"
                          onClick={() => setRemotePrivate(false)}
                          className={`flex-1 px-3 py-1.5 rounded-btn border text-xs font-medium transition-colors ${
                            !remotePrivate
                              ? 'border-mint bg-mint/10 text-mint'
                              : 'border-outline/50 text-muted hover:border-accent-dim hover:text-ink'
                          }`}
                        >
                          {t('remote_public')}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>

        </div>

        <AnimatePresence>
          {error && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              className="px-6 overflow-hidden"
            >
              <div className="flex items-start gap-2.5 rounded-item border border-danger/25 bg-danger/10 px-4 py-3">
                <IconAlertTriangle className="w-4 h-4 text-danger shrink-0 mt-0.5" />
                <p className="text-xs text-danger leading-relaxed">{error}</p>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <AnimatePresence>
          {gitWarning && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              className="px-6 overflow-hidden"
            >
              <div className="flex items-start gap-2.5 rounded-item border border-amber/25 bg-amber/10 px-4 py-3">
                <IconAlertTriangle className="w-4 h-4 text-amber shrink-0 mt-0.5" />
                <div className="min-w-0">
                  <p className="text-xs font-semibold text-amber">
                    {t('git_init_warning_title')}
                  </p>
                  <p className="text-xs text-muted leading-relaxed mt-1 whitespace-pre-wrap wrap-break-word">
                    {gitWarning}
                  </p>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <AnimatePresence>
          {remoteSuccess && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              className="px-6 overflow-hidden"
            >
              <div className="flex items-start gap-2.5 rounded-item border border-mint/25 bg-mint/10 px-4 py-3">
                <IconCheck className="w-4 h-4 text-mint shrink-0 mt-0.5" />
                <div className="min-w-0">
                  <p className="text-xs font-semibold text-mint">
                    {t('remote_repo_created_title')}
                  </p>
                  <p className="text-xs text-muted leading-relaxed mt-1 whitespace-pre-wrap wrap-break-word">
                    {remoteSuccess}
                  </p>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="flex justify-end gap-2.5 p-6 pt-4 border-t border-line">
          {gitWarning || remoteSuccess ? (
            <motion.button
              whileTap={{ scale: 0.96 }}
              onClick={onCreated}
              className="focus-ring px-5 cursor-pointer py-2.5 rounded-btn bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
            >
              {t('create_project_done')}
            </motion.button>
          ) : (
            <>
              <motion.button
                whileTap={{ scale: 0.96 }}
                onClick={onClose}
                disabled={busy}
                className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-50"
              >
                {t('cancel')}
              </motion.button>
              <motion.button
                whileTap={busy ? undefined : { scale: 0.96 }}
                onClick={submit}
                disabled={busy}
                className="focus-ring px-5 cursor-pointer py-2.5 rounded-btn bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors flex items-center gap-2"
              >
                {busy ? (
                  <>
                    <IconSpinner className="w-3.5 h-3.5 animate-spin" />
                    {creatingRemote
                      ? t('creating_remote_repo')
                      : initializingGit
                        ? t('initializing_git')
                        : t('creating')}
                  </>
                ) : (
                  t('create_project_btn')
                )}
              </motion.button>
            </>
          )}
        </div>
      </motion.div>

      <AnimatePresence>
        {previewTemplate && (
          <div onClick={(e) => e.stopPropagation()} className="fixed inset-0 z-60">
            <TemplatePreviewModal
              template={previewTemplate}
              onClose={() => setPreviewTemplate(null)}
            />
          </div>
        )}
      </AnimatePresence>
    </motion.div>,
    document.body,
  )
}
