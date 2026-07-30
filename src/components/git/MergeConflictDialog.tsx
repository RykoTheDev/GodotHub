import { useState, useEffect, useCallback } from 'react'
import { useTranslation } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '../../lib/api'
import {
  IconX,
  IconCheck,
  IconRefresh,
  IconAlertTriangle,
  IconCheckCircle,
  IconTerminal,
  IconCode,
  IconCircleX,
} from '../Icons'
import { ConfirmDialog } from '../modals/ConfirmDialog'

interface ConflictFile {
  path: string
  resolved?: 'ours' | 'theirs' | 'manual' | null
}

interface MergeConflictDialogProps {
  projectPath: string
  onClose: () => void
  onAllResolved: () => void
  onOpenTerminal: () => void
  onAbortMerge: () => void
}

export function MergeConflictDialog({
  projectPath,
  onClose,
  onAllResolved,
  onOpenTerminal,
  onAbortMerge,
}: MergeConflictDialogProps) {
  const { t } = useTranslation('git')
  const [conflictFiles, setConflictFiles] = useState<ConflictFile[]>([])
  const [loading, setLoading] = useState(true)
  const [resolving, setResolving] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [showAbortConfirm, setShowAbortConfirm] = useState(false)

  const loadConflicts = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const files = await api.gitMergeConflictFiles(projectPath)
      setConflictFiles(
        files.map((f) => ({ path: f, resolved: null })),
      )
    } catch (e) {
      setError(String(e))
    } finally {
      setLoading(false)
    }
  }, [projectPath])

  useEffect(() => {
    loadConflicts()
  }, [loadConflicts])

  const handleResolve = async (
    filePath: string,
    strategy: 'ours' | 'theirs',
  ) => {
    setResolving(filePath)
    setError(null)
    try {
      if (strategy === 'ours') {
        await api.gitResolveConflictOurs(projectPath, filePath)
      } else {
        await api.gitResolveConflictTheirs(projectPath, filePath)
      }
      setConflictFiles((prev) =>
        prev.map((f) =>
          f.path === filePath ? { ...f, resolved: strategy } : f,
        ),
      )
    } catch (e) {
      setError(String(e))
    } finally {
      setResolving(null)
    }
  }

  const handleMarkManual = async (filePath: string) => {
    setResolving(filePath)
    setError(null)
    try {
      await api.gitResolveConflictManual(projectPath, filePath)
      setConflictFiles((prev) =>
        prev.map((f) =>
          f.path === filePath ? { ...f, resolved: 'manual' } : f,
        ),
      )
    } catch (e) {
      setError(String(e))
    } finally {
      setResolving(null)
    }
  }

  const unresolvedCount = conflictFiles.filter(
    (f) => !f.resolved,
  ).length
  const resolvedCount = conflictFiles.length - unresolvedCount

  const allResolved = unresolvedCount === 0 && conflictFiles.length > 0

  return (
    <>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 bg-black/70 flex items-center justify-center z-150 p-4"
        onClick={onClose}
      >
        <motion.div
          initial={{ opacity: 1, y: 8, scale: 0.97 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ type: 'spring', stiffness: 380, damping: 30 }}
          className="bg-surface border border-line rounded-2xl w-full max-w-xl flex flex-col shadow-2xl"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="flex items-start gap-3.5 p-6 pb-4 border-b border-line">
            <div className="w-10 h-10 rounded-xl bg-danger/10 flex items-center justify-center shrink-0">
              <IconAlertTriangle className="w-5 h-5 text-danger" />
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="font-display font-semibold text-ink text-lg">
                {t('merge_conflicts')}
              </h3>
              <p className="text-sm text-muted mt-1">
                {t('merge_desc')}
              </p>
            </div>
            <button
              onClick={onClose}
              className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
            >
              <IconX className="w-4 h-4" />
            </button>
          </div>

          {/* Progress bar */}
          {conflictFiles.length > 0 && (
            <div className="px-6 pt-4 pb-2">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs text-muted">
                  {t('merge_resolved_count', { resolved: resolvedCount, total: conflictFiles.length })}
                </span>
                {allResolved && (
                  <span className="text-xs text-mint font-medium flex items-center gap-1">
                    <IconCheckCircle className="w-3.5 h-3.5" />
                    {t('merge_all_resolved')}
                  </span>
                )}
              </div>
              <div className="w-full h-1.5 bg-base rounded-full overflow-hidden">
                <motion.div
                  className="h-full bg-mint rounded-full"
                  initial={{ width: 0 }}
                  animate={{
                    width: `${(resolvedCount / conflictFiles.length) * 100}%`,
                  }}
                  transition={{ duration: 0.3 }}
                />
              </div>
            </div>
          )}

          {/* Content */}
          <div className="flex-1 overflow-y-auto max-h-[400px] px-6 py-3">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <IconRefresh className="w-5 h-5 animate-spin text-muted" />
                <span className="ml-2.5 text-sm text-muted">
                  {t('merge_checking')}
                </span>
              </div>
            ) : error ? (
              <div className="flex flex-col items-center justify-center py-8 gap-3">
                <IconAlertTriangle className="w-8 h-8 text-danger/60" />
                <p className="text-sm text-danger max-w-xs text-center">
                  {error}
                </p>
                <button
                  onClick={loadConflicts}
                  className="focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
                >
                  <IconRefresh className="w-3 h-3" />
                  {t('retry')}
                </button>
              </div>
            ) : conflictFiles.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-8 gap-2">
                <IconCheckCircle className="w-8 h-8 text-mint/60" />
                <p className="text-sm text-muted">{t('merge_no_conflicts')}</p>
              </div>
            ) : (
              <div className="flex flex-col gap-2">
                {conflictFiles.map((file) => (
                  <div
                    key={file.path}
                    className={`rounded-xl border transition-all ${
                      file.resolved
                        ? 'border-mint/30 bg-mint/5'
                        : 'border-danger/20 bg-danger/5'
                    }`}
                  >
                    <div className="flex items-center gap-3 px-4 py-3">
                      {/* Status icon */}
                      <div
                        className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${
                          file.resolved
                            ? 'bg-mint/15 text-mint'
                            : 'bg-danger/10 text-danger'
                        }`}
                      >
                        {file.resolved ? (
                          <IconCheckCircle className="w-4 h-4" />
                        ) : (
                          <IconAlertTriangle className="w-4 h-4" />
                        )}
                      </div>

                      {/* File path */}
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-mono text-ink truncate">
                          {file.path}
                        </p>
                        <p className="text-[10px] text-muted mt-0.5">
                          {file.resolved
                            ? t('resolved_count', { count: file.resolved })
                            : t('needs_resolution')}
                        </p>
                      </div>

                      {/* Actions */}
                      {!file.resolved && (
                        <div className="flex items-center gap-1 shrink-0">
                          <button
                            onClick={() => handleResolve(file.path, 'ours')}
                            disabled={resolving === file.path}
                            className="focus-ring cursor-pointer px-2 py-1.5 rounded-lg bg-accent/10 hover:bg-accent/20 border border-accent/20 text-accent-bright disabled:opacity-40 disabled:cursor-not-allowed text-[10px] font-medium transition-colors"
                            title={t('merge_use_ours_tooltip')}
                          >
                            {t('merge_use_ours')}
                          </button>
                          <button
                            onClick={() =>
                              handleResolve(file.path, 'theirs')
                            }
                            disabled={resolving === file.path}
                            className="focus-ring cursor-pointer px-2 py-1.5 rounded-lg bg-mint/10 hover:bg-mint/20 border border-mint/20 text-mint disabled:opacity-40 disabled:cursor-not-allowed text-[10px] font-medium transition-colors"
                            title={t('merge_use_theirs_tooltip')}
                          >
                            {t('merge_use_theirs')}
                          </button>
                          <button
                            onClick={() => onOpenTerminal()}
                            className="focus-ring cursor-pointer p-1.5 rounded-lg border border-line text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
                            title={t('merge_edit_terminal_tooltip')}
                          >
                            <IconTerminal className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => handleMarkManual(file.path)}
                            disabled={resolving === file.path}
                            className="focus-ring cursor-pointer px-2 py-1.5 rounded-lg bg-base hover:bg-raised border border-line text-muted hover:text-ink disabled:opacity-40 disabled:cursor-not-allowed text-[10px] font-medium transition-colors"
                            title={t('merge_mark_fixed_tooltip')}
                          >
                            {t('merge_mark_fixed')}
                          </button>
                        </div>
                      )}

                      {file.resolved && (
                        <button
                          onClick={() =>
                            setConflictFiles((prev) =>
                              prev.map((f) =>
                                f.path === file.path
                                  ? { ...f, resolved: null }
                                  : f,
                              ),
                            )
                          }
                          className="focus-ring cursor-pointer text-[10px] text-muted hover:text-ink underline transition-colors shrink-0"
                        >
                          {t('undo')}
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-between gap-3 px-6 py-4 border-t border-line">
            <div className="flex items-center gap-2">
              <button
                onClick={() => setShowAbortConfirm(true)}
                className="focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-lg border border-danger/40 text-danger hover:bg-danger/10 text-xs transition-colors"
              >
                <IconCircleX className="w-3.5 h-3.5" />
                {t('abort_merge')}
              </button>
              <button
                onClick={() => {
                  onOpenTerminal()
                  onClose()
                }}
                className="focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-lg border border-line text-muted hover:text-ink hover:bg-raised text-xs transition-colors"
              >
                <IconCode className="w-3.5 h-3.5" />
                {t('terminal')}
              </button>
            </div>

            <div className="flex items-center gap-2.5">
              <button
                onClick={onClose}
                className="focus-ring cursor-pointer px-4 py-2 rounded-lg border border-line text-muted hover:text-ink hover:bg-raised text-xs transition-colors"
              >
                {t('close')}
              </button>
              {allResolved && (
                <button
                  onClick={() => {
                    onAllResolved()
                    onClose()
                  }}
                  className="focus-ring cursor-pointer flex items-center gap-1.5 px-4 py-2 rounded-lg bg-mint hover:bg-mint-bright text-white text-xs font-medium transition-colors"
                >
                  <IconCheck className="w-3.5 h-3.5" />
                  {t('finish_merge')}
                </button>
              )}
            </div>
          </div>
        </motion.div>
      </motion.div>

      {/* Abort merge confirmation */}
      <AnimatePresence>
        {showAbortConfirm && (
          <ConfirmDialog
            title={t('merge_abort_title')}
            description={t('merge_abort_desc')}
            confirmLabel={t('merge_abort_confirm')}
            variant="danger"
            onConfirm={() => {
              setShowAbortConfirm(false)
              onAbortMerge()
              onClose()
            }}
            onCancel={() => setShowAbortConfirm(false)}
          />
        )}
      </AnimatePresence>
    </>
  )
}
