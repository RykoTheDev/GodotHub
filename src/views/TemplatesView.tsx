import { useEffect, useState, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '../lib/api'
import { useSettings } from '../hooks/useSettings'
import type { ProjectTemplate, TemplateSyncResult } from '../types'
import { IconCopy, IconTrash, IconAlertTriangle, IconRefresh, IconExternalLink } from '../components/Icons'
import { Tooltip } from '../components/ui/Tooltip'
import { TemplatePreviewModal } from '../components/modals/TemplatePreviewModal'
import { useTaskTray } from '../hooks/useTaskTray'

export function TemplatesView() {
  const { settings } = useSettings()
  const [templates, setTemplates] = useState<ProjectTemplate[]>([])
  const [loaded, setLoaded] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [syncing, setSyncing] = useState(false)
  const [dialogMinimized, setDialogMinimized] = useState(false)
  const [syncMessage, setSyncMessage] = useState<string | null>(null)
  const [syncResult, setSyncResult] = useState<TemplateSyncResult | null>(null)
  const [previewTemplate, setPreviewTemplate] = useState<ProjectTemplate | null>(null)
  const { registerTask, updateTask, unregisterTask } = useTaskTray()

  const load = async () => {
    try {
      setTemplates(await api.listTemplates())
    } catch {}
    setLoaded(true)
  }

  useEffect(() => {
    load()
  }, [])

  const handleSync = async () => {
    setDialogMinimized(false)
    setSyncing(true)
    setSyncMessage(null)
    setSyncResult(null)
    registerTask({
      id: 'sync-templates',
      type: 'sync-templates',
      label: 'Syncing templates',
      description: 'Starting…',
      progress: null,
      status: 'running',
    })
    try {
      const result = await api.syncTemplatesWithScanDir()
      setSyncResult(result)
      const parts: string[] = []
      if (result.imported.length > 0)
        parts.push(`Imported ${result.imported.length}`)
      if (result.updated.length > 0)
        parts.push(`Updated ${result.updated.length}`)
      if (result.removed.length > 0)
        parts.push(`Removed ${result.removed.length}`)
      setSyncMessage(
        parts.length > 0
          ? parts.join(' · ')
          : 'Templates are up to date.',
      )
      updateTask('sync-templates', {
        status: 'completed',
        description: parts.length > 0 ? parts.join(' · ') : 'Up to date',
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

  const user = templates

  return (
    <div className="p-10 pt-15 max-w-8xl mx-auto">
      <div className="mb-8">
        <h2 className="font-body font-semibold text-3xl tracking-tight">
          TEMPLATES
        </h2>
        <p className="text-xs text-muted mt-1">
          {templates.length > 0
            ? `${templates.length} template${templates.length !== 1 ? 's' : ''} available`
            : 'No templates saved yet.'}
        </p>
        <div className="flex items-center gap-3 mt-4">
          <Tooltip
            content={!settings.template_scan_dir ? 'Set a template scan directory in Settings → Storage first' : 'Sync from directory'}
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
              {syncing ? 'Syncing…' : 'Sync Now'}
            </motion.button>
          </Tooltip>
          {settings.template_scan_dir && (
            <Tooltip content="Open templates folder in file manager" side="bottom">
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={() => api.openProjectFolder(settings.template_scan_dir!)}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                <IconExternalLink className="w-4 h-4" />
                Open Folder
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
        <div className="text-sm text-muted">Loading…</div>
      ) : templates.length === 0 ? (
        <div className="border border-dashed border-line rounded-2xl py-24 flex flex-col items-center gap-4 text-center">
          <div className="w-12 h-12 rounded-xl bg-raised border border-line flex items-center justify-center">
            <IconCopy className="w-5 h-5 text-muted" />
          </div>
          <p className="text-sm text-muted max-w-xs leading-relaxed">
            No templates yet. Right-click a project or open its "More" menu and
            select <strong>Save as Template</strong> to create one.
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
                  Your Templates
                </h3>
                <span className="text-[10px] text-muted/50">· {user.length}</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                <AnimatePresence>
                  {user.map((t) => (
                    <motion.div
                      key={t.id}
                      layout
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      className="relative border border-line rounded-xl bg-surface p-5 flex flex-col gap-3 group cursor-pointer"
                      onClick={() => setPreviewTemplate(t)}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="w-9 h-9 rounded-lg bg-raised border border-line flex items-center justify-center shrink-0">
                          <IconCopy className="w-4 h-4 text-muted" />
                        </div>
                        <button
                          onClick={(e) => { e.stopPropagation(); setConfirmDelete(t.id) }}
                          className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted/40 opacity-0 group-hover:opacity-100 hover:text-danger hover:bg-danger/10 transition-all"
                          aria-label={`Delete ${t.name} template`}
                        >
                          <IconTrash className="w-3.5 h-3.5" />
                        </button>
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-display font-semibold text-sm truncate">
                          {t.name}
                        </h4>
                        {t.description && (
                          <p className="text-xs text-muted mt-1 leading-relaxed">
                            {t.description}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-1.5 text-[10px] text-muted/50 font-mono">
                        {t.godot_version && (
                          <span>Godot {t.godot_version}</span>
                        )}
                        {t.created_at && (
                          <>
                            <span>·</span>
                            <span>
                              {new Date(t.created_at).toLocaleDateString()}
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
                  <h4 className="font-display font-semibold text-base">
                    Delete Template?
                  </h4>
                  <p className="text-xs text-muted mt-0.5">
                    {templates.find((t) => t.id === confirmDelete)?.name
                      ? `"${templates.find((t) => t.id === confirmDelete)?.name}" will be permanently removed.`
                      : 'This cannot be undone.'}
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
                  Cancel
                </motion.button>
                <motion.button
                  whileHover={deleting ? undefined : { y: -1 }}
                  whileTap={deleting ? undefined : { scale: 0.96 }}
                  onClick={() => handleDelete(confirmDelete)}
                  disabled={deleting}
                  className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg bg-danger hover:bg-danger/80 disabled:opacity-50 text-sm font-medium text-white transition-colors"
                >
                  {deleting ? 'Deleting…' : 'Delete'}
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
              Syncing templates from directory…
            </p>
            <button
              onClick={() => setDialogMinimized(true)}
              className="focus-ring cursor-pointer text-xs text-muted hover:text-ink transition-colors mt-1"
            >
              Resume in background
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
