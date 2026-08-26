import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import type { Category, GitAuthState, UserRepoInfo } from '../../types'
import { api } from '../../lib/api'
import { useSettings } from '../../hooks/useSettings'
import { useTaskTray } from '../../hooks/useTaskTray'
import { Checkbox } from '../ui/Checkbox'
import {
  IconGitBranch,
  IconAlertTriangle,
  IconSpinner,
  IconCheck,
  IconSearch,
  IconPlug,
} from '../../lib/icons'
import { ModalHeader } from './ModalHeader'

function repoBaseName(url: string): string {
  let cleaned = url.trim().replace(/\/+$/, '')
  while (cleaned.endsWith('.git')) {
    cleaned = cleaned.slice(0, -4)
  }
  const parts = cleaned.split('/')
  return parts[parts.length - 1] || 'repo'
}

type Tab = 'browse' | 'url'

interface Props {
  defaultLocation?: string | null
  categories?: Category[]
  categoriesEnabled?: boolean
  onClose: () => void
  onCloned: (projectPath: string) => void
}

export function CloneRepoModal({
  defaultLocation,
  categories = [],
  categoriesEnabled = false,
  onClose,
  onCloned,
}: Props) {
  const { t } = useTranslation('common')
  const { settings, update: updateSettings } = useSettings()
  const { registerTask, updateTask, unregisterTask } = useTaskTray()
  const [url, setUrl] = useState('')
  const [location, setLocation] = useState(defaultLocation ?? '')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [attempted, setAttempted] = useState(false)
  const [openAfterImport, setOpenAfterImport] = useState(
    settings.open_after_import,
  )
  const [category, setCategory] = useState<string | null>(null)

  const [gitAuth, setGitAuth] = useState<GitAuthState | null>(null)
  const [activeTab, setActiveTab] = useState<Tab>('browse')
  const [repos, setRepos] = useState<UserRepoInfo[]>([])
  const [reposLoading, setReposLoading] = useState(false)
  const [reposLoadingMore, setReposLoadingMore] = useState(false)
  const [reposError, setReposError] = useState<string | null>(null)
  const [hasMoreRepos, setHasMoreRepos] = useState(false)
  const [repoPage, setRepoPage] = useState(1)
  const [repoSearch, setRepoSearch] = useState('')
  const [selectedRepo, setSelectedRepo] = useState<UserRepoInfo | null>(null)

  const connectedProvider = gitAuth?.github ? 'github' : gitAuth?.gitlab ? 'gitlab' : null
  const connectedUsername = gitAuth?.github?.username ?? gitAuth?.gitlab?.username ?? null

  const handleOpenAfterImportChange = (checked: boolean) => {
    setOpenAfterImport(checked)
    updateSettings({ ...settings, open_after_import: checked }).catch(
      () => {},
    )
  }
  const urlInputRef = useRef<HTMLInputElement>(null)
  const searchInputRef = useRef<HTMLInputElement>(null)
  const repoListRef = useRef<HTMLDivElement>(null)

  const repoName = useMemo(() => repoBaseName(url), [url])

  useEffect(() => {
    if (connectedProvider && activeTab === 'browse') {
    } else if (!connectedProvider) {
      setActiveTab('url')
    }
  }, [connectedProvider])

  useEffect(() => {
    if (activeTab === 'url') {
      urlInputRef.current?.focus()
    } else if (activeTab === 'browse') {
      searchInputRef.current?.focus()
    }
  }, [activeTab])

  useEffect(() => {
    api.gitAuthGetState().then(setGitAuth).catch(() => {})
  }, [])

  const fetchRepos = useCallback(async (pageNum: number, append: boolean) => {
    if (!connectedProvider) return
    if (append) {
      setReposLoadingMore(true)
    } else {
      setReposLoading(true)
    }
    setReposError(null)
    try {
      const result = await api.gitAuthListUserRepos(connectedProvider, pageNum)
      setRepos((prev) => append ? [...prev, ...result.repos] : result.repos)
      setHasMoreRepos(result.has_more)
      setRepoPage(pageNum)
    } catch (e) {
      setReposError(String(e))
    } finally {
      setReposLoading(false)
      setReposLoadingMore(false)
    }
  }, [connectedProvider])

  useEffect(() => {
    if (activeTab === 'browse' && connectedProvider && repos.length === 0 && !reposLoading) {
      fetchRepos(1, false)
    }
  }, [activeTab, connectedProvider, repos.length, reposLoading, fetchRepos])

  const loadMoreRepos = useCallback(() => {
    fetchRepos(repoPage + 1, true)
  }, [fetchRepos, repoPage])

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dialog-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dialog-close'))
    }
  }, [])

  const pickLocation = async () => {
    const folder = await api.pickFolder()
    if (folder) {
      setLocation(folder)
      setError(null)
    }
  }

  const selectRepo = (repo: UserRepoInfo) => {
    setSelectedRepo(repo)
    setUrl(repo.clone_url)
    setError(null)
  }

  const filteredRepos = useMemo(() => {
    if (!repoSearch.trim()) return repos
    const q = repoSearch.toLowerCase()
    return repos.filter(
      (r) =>
        r.name.toLowerCase().includes(q) ||
        r.full_name.toLowerCase().includes(q) ||
        (r.description ?? '').toLowerCase().includes(q) ||
        (r.language ?? '').toLowerCase().includes(q),
    )
  }, [repos, repoSearch])

  const urlInvalid = attempted && !url.trim()
  const locationInvalid = attempted && !location

  const submit = async () => {
    if (busy) return
    if (!url.trim() || !location) {
      setAttempted(true)
      setError(
        !url.trim()
          ? t('clone_repo_error_url')
          : t('clone_repo_error_location'),
      )
      return
    }

    setBusy(true)
    setError(null)

    const taskId = `clone-${Date.now()}`

    registerTask({
      id: taskId,
      type: 'clone-repo',
      label: `${t('cloning')} ${repoName}`,
      description: t('loading'),
      progress: null,
      status: 'running',
    })

    try {
      const clonedPath = await api.cloneRepo(url.trim(), location)
      updateTask(taskId, {
        description: t('importing_project'),
        status: 'running',
      })
      const project = await api.importProject(clonedPath, '', category)
      updateTask(taskId, { status: 'completed', description: 'Done' })
      setTimeout(() => unregisterTask(taskId), 3000)
      onCloned(project.id)
      if (openAfterImport) {
        api.openProject(project.id, true).catch((e) => alert(String(e)))
      }
    } catch (e) {
      setError(String(e))
      updateTask(taskId, {
        status: 'error',
        errorMessage: String(e),
      })
      setTimeout(() => unregisterTask(taskId), 6000)
    } finally {
      setBusy(false)
    }
  }

  const inputClass = (invalid: boolean) =>
    `focus-ring bg-overlay border rounded-item px-3.5 py-2.5 text-sm font-mono transition-colors ${
      invalid ? 'border-danger/70 focus:border-danger' : 'border-outline/50 focus:border-accent-dim'
    }`

  const tabClass = (active: boolean) =>
    `px-3 py-1.5 rounded-btn text-xs font-medium transition-colors ${
      active
        ? 'bg-accent/15 text-accent-bright border border-accent/30'
        : 'text-muted hover:text-ink hover:bg-raised border border-transparent'
    }`

  return createPortal(
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.96 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface rounded-modal w-full max-w-2xl max-h-[88vh] flex flex-col shadow-2xl overflow-clip"
        onClick={(e) => e.stopPropagation()}
      >
        <ModalHeader
          icon={<IconGitBranch className="w-5 h-5 text-accent-bright" />}
          title={t('clone_repo_title')}
          description={t('clone_repo_desc')}
          autoFocusBanner={false}
        />

        {connectedProvider && (
          <div className="flex items-center gap-2 px-6 pt-1">
            <button
              type="button"
              onClick={() => setActiveTab('browse')}
              className={tabClass(activeTab === 'browse')}
            >
              {t('clone_repo_browse_repos')}
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('url')}
              className={tabClass(activeTab === 'url')}
            >
              {t('clone_repo_url_manual')}
            </button>
          </div>
        )}

        <div className="gap-6 p-6 flex-1 overflow-y-auto">
          <div className="md:col-span-3 flex flex-col gap-4">
            {activeTab === 'browse' && connectedProvider && (
              <div className="flex flex-col gap-3">
                <div className="flex items-center gap-2 px-1">
                  <span className="text-xs text-muted">
                    {t('clone_repo_connected_as', { username: connectedUsername })}
                  </span>
                  <span className="text-xs text-muted opacity-50">•</span>
                  <span className="text-xs font-medium text-accent-bright capitalize">
                    {connectedProvider}
                  </span>
                  <button
                    type="button"
                    onClick={() => {
                      setRepos([])
                      setSelectedRepo(null)
                      fetchRepos(1, false)
                    }}
                    disabled={reposLoading}
                    className="ml-auto text-xs text-muted hover:text-accent-bright transition-colors"
                  >
                    {t('refresh')}
                  </button>
                </div>

                <div className="relative">
                  <IconSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted pointer-events-none" />
                  <input
                    ref={searchInputRef}
                    value={repoSearch}
                    onChange={(e) => setRepoSearch(e.target.value)}
                    placeholder={t('clone_repo_search_repos')}
                    className={`${inputClass(false)} w-full pl-9`}
                  />
                </div>

                <div
                  ref={repoListRef}
                  className="max-h-[300px] overflow-y-auto rounded-item border border-outline/30 divide-y divide-line"
                >
                  {reposLoading && repos.length === 0 ? (
                    <div className="flex items-center justify-center gap-2 py-8 text-sm text-muted">
                      <IconSpinner className="w-4 h-4 animate-spin" />
                      {t('clone_repo_loading_repos')}
                    </div>
                  ) : reposError ? (
                    <div className="flex items-center gap-2 py-8 px-4 text-sm text-danger">
                      <IconAlertTriangle className="w-4 h-4 shrink-0" />
                      <div className="flex flex-col gap-1">
                        <span>{t('clone_repo_load_error')}</span>
                        <span className="text-xs text-danger/70 font-mono">{reposError}</span>
                      </div>
                    </div>
                  ) : filteredRepos.length === 0 ? (
                    <div className="flex flex-col items-center justify-center gap-1 py-8 text-sm text-muted">
                      <IconSearch className="w-5 h-5 opacity-40" />
                      <span>{t('clone_repo_no_repos_found')}</span>
                    </div>
                  ) : (
                    filteredRepos.map((repo) => {
                      const isSelected = selectedRepo?.clone_url === repo.clone_url
                      return (
                        <motion.button
                          key={repo.clone_url}
                          type="button"
                          whileHover={{ backgroundColor: 'var(--color-raised)' }}
                          onClick={() => selectRepo(repo)}
                          className={`w-full text-left px-4 py-3 flex items-start gap-3 transition-colors cursor-pointer ${
                            isSelected ? 'bg-accent/10' : ''
                          }`}
                        >
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-medium text-ink truncate">
                                {repo.full_name}
                              </span>
                              <span
                                className={`text-[10px] px-1.5 py-0.5 rounded font-medium ${
                                  repo.private
                                    ? 'bg-warning/15 text-warning'
                                    : 'bg-success/15 text-success'
                                }`}
                              >
                                {repo.private
                                  ? t('clone_repo_private')
                                  : t('clone_repo_public')}
                              </span>
                              {repo.language && (
                                <span className="text-[10px] text-muted bg-overlay px-1.5 py-0.5 rounded">
                                  {repo.language}
                                </span>
                              )}
                            </div>
                            {repo.description && (
                              <p className="text-xs text-muted mt-0.5 line-clamp-1">
                                {repo.description}
                              </p>
                            )}
                          </div>
                          {isSelected ? (
                            <IconCheck className="w-4 h-4 text-accent-bright shrink-0 mt-0.5" />
                          ) : (
                            <span className="text-xs text-accent opacity-0 group-hover:opacity-100 shrink-0 mt-0.5 transition-opacity">
                              {t('clone_repo_select')}
                            </span>
                          )}
                        </motion.button>
                      )
                    })
                  )}

                  {!reposLoading && repos.length > 0 && filteredRepos.length > 0 && (
                    <div className="border-t border-line">
                      {reposLoadingMore ? (
                        <div className="flex items-center justify-center gap-2 py-3 text-xs text-muted">
                          <IconSpinner className="w-3 h-3 animate-spin" />
                          {t('loading')}
                        </div>
                      ) : hasMoreRepos ? (
                        <button
                          type="button"
                          onClick={loadMoreRepos}
                          className="w-full py-3 text-xs font-medium text-accent-bright hover:bg-raised transition-colors cursor-pointer"
                        >
                          {t('load_more')}
                        </button>
                      ) : (
                        <div className="py-3 text-center text-xs text-muted">
                          {repos.length} {t('clone_repo_repos_loaded')}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>
            )}

            {(activeTab === 'url' || !connectedProvider) && (
              <>
                {!connectedProvider && (
                  <div className="flex items-center gap-2 px-3 py-2.5 rounded-item bg-overlay border border-outline/30 text-xs text-muted">
                    <IconPlug className="w-3.5 h-3.5 shrink-0 opacity-60" />
                    <span>{t('clone_repo_no_account')}</span>
                  </div>
                )}
                <div className="flex flex-col gap-0.5">
                  <label className="pl-3 text-xs font-medium text-muted">
                    {t('clone_repo_url_label')}
                  </label>
                  <input
                    ref={urlInputRef}
                    value={url}
                    onChange={(e) => {
                      setUrl(e.target.value)
                      setSelectedRepo(null)
                      if (error) setError(null)
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') submit()
                    }}
                    placeholder={t('clone_repo_url_placeholder')}
                    className={`${inputClass(urlInvalid)} w-full`}
                  />
                  {selectedRepo && (
                    <span className="pl-3 text-xs text-accent-bright mt-0.5">
                      {selectedRepo.full_name}
                    </span>
                  )}
                </div>
              </>
            )}

            <div className="flex flex-col gap-0.5">
              <label className="pl-3 text-xs font-medium text-muted">
                {t('clone_repo_dest_label')}
              </label>
              <div className="flex gap-2.5">
                <input
                  value={location}
                  readOnly
                  onClick={pickLocation}
                  className={`${inputClass(locationInvalid)} flex-1 text-muted truncate`}
                  placeholder={t('clone_repo_dest_placeholder')}
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

            {categoriesEnabled && (
              <div className="flex flex-col gap-2">
                <label className="text-xs font-medium text-muted">
                  {t('category_optional')}
                </label>
                <div className="flex flex-wrap gap-1.5">
                  <button
                    type="button"
                    onClick={() => setCategory(null)}
                    className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-1.5 rounded-btn border text-xs font-medium transition-colors ${
                      category === null
                        ? 'border-accent bg-accent/10 text-accent-bright'
                        : 'border-outline/50 text-muted hover:border-accent-dim hover:text-ink hover:bg-raised'
                    }`}
                  >
                    {category === null && (
                      <IconCheck className="w-3 h-3 inline mr-1 -mt-0.5" />
                    )}
                    {t('no_category_label')}
                  </button>
                  {categories.map((cat) => (
                    <button
                      key={cat.id}
                      type="button"
                      onClick={() => setCategory(cat.name)}
                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-3 py-1.5 rounded-btn border text-xs font-medium transition-colors ${
                        category === cat.name
                          ? 'border-accent bg-accent/10 text-accent-bright'
                          : 'border-outline/50 text-muted hover:border-accent-dim hover:text-ink hover:bg-raised'
                      }`}
                    >
                      {category === cat.name && (
                        <IconCheck className="w-3 h-3 inline mr-1 -mt-0.5" />
                      )}
                      <span
                        className="w-1.5 h-1.5 rounded-full shrink-0"
                        style={{ backgroundColor: cat.color }}
                      />
                      {cat.name}
                    </button>
                  ))}
                </div>
              </div>
            )}

            <label className="flex items-center gap-2.5 cursor-pointer select-none">
              <Checkbox
                checked={openAfterImport}
                onChange={handleOpenAfterImportChange}
                label={t('clone_repo_open_after')}
              />
              <span className="text-xs font-medium text-ink">
                {t('clone_repo_open_after')}
              </span>
            </label>
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

        <div className="flex justify-end gap-2.5 p-6 pt-4 border-t border-line">
          <motion.button
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            disabled={busy}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-50"
          >
            {t('clone_repo_cancel')}
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
                {t('cloning')}
              </>
            ) : (
              t('clone_import')
            )}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>,
    document.body,
  )
}
