import { useEffect, useState, useRef } from 'react'
import { useTranslation, Trans } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '../lib/api'
import { useSettings } from '../hooks/useSettings'
import { useWorkspaces } from '../hooks/useWorkspaces'
import type { ProjectTemplate, TemplateSyncResult } from '../types'
import { IconCopy, IconTrash, IconAlertTriangle, IconRefresh, IconExternalLink, IconSearch, IconX } from '../components/Icons'
import { Tooltip } from '../components/ui/Tooltip'
import { TemplatePreviewModal } from '../components/modals/TemplatePreviewModal'
import { useTaskTray } from '../hooks/useTaskTray'

export function TemplatesView() {
  const { settings } = useSettings()
  const { activeId } = useWorkspaces()
  const [templates, setTemplates] = useState<ProjectTemplate[]>([])
  const [loaded, setLoaded] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [dialogMinimized, setDialogMinimized] = useState(false)
  const [syncMessage, setSyncMessage] = useState<string | null>(null)
  const [syncResult, setSyncResult] = useState<TemplateSyncResult | null>(null)
  const [previewTemplate, setPreviewTemplate] = useState<ProjectTemplate | null>(null)
  const [query, setQuery] = useState('')
  const { registerTask, updateTask, unregisterTask } = useTaskTray()
  const { t } = useTranslation('common')

  const load = async () => {
    try {
      setTemplates(await api.listTemplates())
    } catch {}
    setLoaded(true)
  }

  useEffect(() => {
    load()
  }, [activeId])

  const handleSync = async () => {
    setDialogMinimized(false)
    setSyncing(true)
    setSyncMessage(null)
    setSyncResult(null)
    registerTask({
      id: 'sync-templates',
      type: 'sync-templates',
      label: t('syncing'),
      description: t('loading'),
      progress: null,
      status: 'running',
    })
    try {
      const result = await api.syncTemplatesWithScanDir()
      setSyncResult(result)
      const parts: string[] = []
      if (result.imported.length > 0)
        parts.push(t('template_imported_count', { count: result.imported.length }))
      if (result.updated.length > 0)
        parts.push(t('template_updated_count', { count: result.updated.length }))
      if (result.removed.length > 0)
        parts.push(t('template_removed_count', { count: result.removed.length }))
      setSyncMessage(
        parts.length > 0
          ? parts.join(' · ')
          : t('templates_up_to_date'),
      )
      updateTask('sync-templates', {
        status: 'completed',
        description: parts.length > 0 ? parts.join(' · ') : t('up_to_date'),
      })
      setTimeout(() => unregisterTask('sync-templates'), 3000)
      await load()
    } catch (e) {
      setSyncMessage(String(e))
      updateTask('sync-templates', {
        status: 'error',
        errorMessage: String(e),
      })
      setTimeout(() => unregisterTask('sync-templates'), 6000)
    } finally {
      setSyncing(false)
    }
  }

  const syncRef = useRef(handleSync)
  syncRef.current = handleSync
  const loadRef = useRef(load)
  loadRef.current = load
  useEffect(() => {
    const handler = () => syncRef.current()
    const refreshHandler = () => loadRef.current()
    window.addEventListener('app:sync-templates', handler)
    window.addEventListener('app:refresh-templates', refreshHandler)
    return () => {
      window.removeEventListener('app:sync-templates', handler)
      window.removeEventListener('app:refresh-templates', refreshHandler)
    }
  }, [])

  const handleDelete = async (id: string) => {
    setDeleting(true)
    try {
      await api.deleteTemplate(id)
      setTemplates((prev) => prev.filter((t) => t.id !== id))
      setConfirmDelete(null)
    } catch (e) {
      alert(e)
    } finally {
      setDeleting(false)
    }
  }

  const isSearching = query.trim().length > 0
  const filteredTemplates = isSearching
    ? templates.filter(
        (t) =>
          t.name.toLowerCase().includes(query.toLowerCase()) ||
          (t.description &&
            t.description.toLowerCase().includes(query.toLowerCase())),
      )
    : templates

  const user = filteredTemplates

  return (
    <div className="p-10 pt-6 max-w-8xl mx-auto">
      <div className="mb-8">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="font-body font-semibold text-3xl tracking-tight">
              {t('templates_title')}
            </h2>
            <p className="text-xs text-muted mt-1">
              {templates.length > 0
                ? t('template_count', { count: templates.length }) + (isSearching ? ' · ' + t('showing_count', { count: filteredTemplates.length }) : '')
                : t('no_templates_saved')}
            </p>
          </div>
          {/* Search bar */}
          <div className="relative w-64 shrink-0">
            <IconSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted/50 pointer-events-none" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={t('template_search_placeholder')}
              className="w-full pl-9 pr-9 py-2 rounded-lg border border-line bg-surface text-sm text-ink placeholder:text-muted/50 outline-none transition-all focus:border-accent focus:ring-1 focus:ring-accent/30"
            />
            {query && (
              <button
                onClick={() => setQuery('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted/50 hover:text-ink transition-colors cursor-pointer"
              >
                <IconX className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>
        <div className="flex items-center gap-3 mt-4">
          <Tooltip
            content={!settings.template_scan_dir ? t('template_scan_dir_hint') : t('template_sync_from_dir')}
            side="bottom"
          >
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={handleSync}
              disabled={syncing || !settings.template_scan_dir}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <span className={`icon-wiggle inline-flex ${syncing ? 'animate-spin' : ''}`}>
                <IconRefresh className="w-4 h-4" />
              </span>
              {syncing ? t('syncing') : t('sync_now')}
            </motion.button>
          </Tooltip>
          {settings.template_scan_dir && (
            <Tooltip content={t('template_open_folder')} side="bottom">
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => api.openProjectFolder(settings.template_scan_dir!)}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                <IconExternalLink className="w-4 h-4" />
                {t('template_open_folder_btn')}
              </motion.button>
            </Tooltip>
          )}
          {syncMessage && (
            <span className={`text-xs ${syncResult && (syncResult.imported.length > 0 || syncResult.updated.length > 0 || syncResult.removed.length > 0) ? 'text-mint' : 'text-muted'}`}>
              {syncMessage}
            </span>
          )}
        </div>
      </div>

      {!loaded ? (
        <div className="text-sm text-muted">{t('loading')}</div>
      ) : templates.length === 0 ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
            <IconCopy className="w-5 h-5 text-muted" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            <Trans i18nKey="no_templates_yet" ns="common">
              No templates yet. Right-click a project or open its "More" menu and
              select <strong>Save as Template</strong> to create one.
            </Trans>
          </p>
        </div>
      ) : filteredTemplates.length === 0 ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <IconSearch className="w-5 h-5 text-muted" />
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            {t('no_templates_match')} <strong>"{query}"</strong>.
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-8">
          {/* User templates section */}
          {user.length > 0 && (
            <section>
              <div className="flex items-center gap-2 mb-4">
                <IconCopy className="w-3.5 h-3.5 text-muted" />
                <h3 className="text-xs font-semibold uppercase tracking-wide text-muted">
                  {t('template_your_templates')}
                </h3>
                <span className="text-[10px] text-muted/50">· {user.length}</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <AnimatePresence>
                  {user.map((tmpl) => (
                    <motion.div
                      key={tmpl.id}
                      layout
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      className="relative border border-line rounded-xl bg-surface p-5 flex flex-col gap-3 group cursor-pointer"
                      onClick={() => setPreviewTemplate(tmpl)}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="w-9 h-9 rounded-lg bg-raised border border-line flex items-center justify-center shrink-0">
                          <IconCopy className="w-3.5 h-3.5 text-muted" />
                        </div>
                        <button
                          onClick={(e) => { e.stopPropagation(); setConfirmDelete(tmpl.id) }}
                          className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted/40 opacity-0 group-hover:opacity-100 hover:text-danger hover:bg-danger/10 transition-all"
                          aria-label={t('delete_template', { name: tmpl.name })}
                        >
                          <IconTrash className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-display font-semibold text-sm truncate">
                          {tmpl.name}
                        </h4>
                        {tmpl.description && (
                          <p className="text-xs text-muted mt-1 leading-relaxed">
                            {tmpl.description}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-1.5 text-[10px] text-muted/50 font-mono">
                        {tmpl.godot_version && (
                          <span>{t('godot')} {tmpl.godot_version}</span>
                        )}
                        {tmpl.created_at && (
                          <>
                            <span>·</span>
                            <span>
                              {new Date(tmpl.created_at).toLocaleDateString()}
                            </span>
                          </>
                        )}
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>
            </section>
          )}
        </div>
      )}

      {/* Preview modal */}
      <AnimatePresence>
        {previewTemplate && (
          <TemplatePreviewModal
            template={previewTemplate}
            onClose={() => setPreviewTemplate(null)}
          />
        )}
      </AnimatePresence>

      {/* Delete confirmation dialog */}
      <AnimatePresence>
        {confirmDelete && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={() => !deleting && setConfirmDelete(null)}
          >
            <motion.div
              initial={{ opacity: 0, y: 12, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ type: 'spring', stiffness: 380, damping: 30 }}
              className="bg-surface border border-line rounded-2xl p-6 w-full max-w-sm flex flex-col gap-5 shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-danger/10 flex items-center justify-center shrink-0">
                  <IconAlertTriangle className="w-5 h-5 text-danger" />
                </div>
                <div>
                  <h4 className="font-display font-semibold text-muted">
                    {t('template_delete_title')}
                  </h4>
                  <p className="text-xs text-muted mt-0.5">
                    {templates.find((t) => t.id === confirmDelete)?.name
                      ? t('template_delete_desc', { name: templates.find((t) => t.id === confirmDelete)?.name })
                      : t('cannot_undo')}
                  </p>
                </div>
              </div>
              <div className="flex justify-end gap-2.5">
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={() => setConfirmDelete(null)}
                  disabled={deleting}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
                >
                  {t('cancel')}
                </motion.button>
                <motion.button
                  whileHover={deleting ? undefined : { y: -1 }}
                  whileTap={deleting ? undefined : { scale: 0.96 }}
                  onClick={() => handleDelete(confirmDelete)}
                  disabled={deleting}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg bg-danger hover:bg-danger/80 disabled:opacity-50 text-sm font-medium text-white transition-colors"
                >
                  {deleting ? t('deleting') : t('delete')}
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Sync overlay */}
      {syncing && !dialogMinimized && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-surface border border-line rounded-2xl px-8 py-6 flex flex-col items-center gap-3 min-w-64">
            <IconRefresh className="w-6 h-6 animate-spin text-accent" />
            <p className="text-sm font-medium text-ink">
              {t('template_syncing_from_dir')}
            </p>
            <button
              onClick={() => setDialogMinimized(true)}
              className="focus-ring cursor-pointer text-xs text-muted hover:text-ink transition-colors mt-1"
            >
              {t('resume_background')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
