import { useCallback, useEffect, useRef, useState } from 'react'
import { AnimatePresence } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { GitWorktree, Project } from '../../types'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import { useTauriEvent } from '../../lib/useTauriEvent'
import { isWithinWorktree, worktreeProjectPath } from '../../lib/worktreePaths'
import { IconCheck, IconChevronRight, IconClone, IconPlus, IconRefresh, IconSpinner, IconTrash } from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'
import { Checkbox } from '../ui/Checkbox'
import { ModalShell } from '../modals/ModalShell'
import { CreateWorktreeModal } from '../modals/CreateWorktreeModal'
import { GitSection } from './GitSection'

interface Props {
  project: Project
  onSwitchProject?: (project: Project) => void | Promise<void>
  onChanged: () => void
}

export function GitWorktrees({ project, onSwitchProject, onChanged }: Props) {
  const { t } = useTranslation('git')
  const { t: tc } = useTranslation('common')
  const [worktrees, setWorktrees] = useState<GitWorktree[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)
  const [busy, setBusy] = useState<{ action: 'switch' | 'remove'; path: string } | null>(null)
  const [removal, setRemoval] = useState<GitWorktree | null>(null)
  const [discardChanges, setDiscardChanges] = useState(false)
  const [removeError, setRemoveError] = useState<string | null>(null)
  const mounted = useRef(true)
  const request = useRef(0)
  const currentWorktree = worktrees.filter(wt => isWithinWorktree(project.path, wt.path))
    .sort((a, b) => b.path.length - a.path.length)[0]

  const refresh = useCallback(async () => {
    const version = ++request.current
    setLoading(true)
    setError(null)
    try {
      const entries = await api.gitWorktreeList(project.path)
      if (mounted.current && request.current === version) setWorktrees(entries)
    } catch (error) {
      if (mounted.current && request.current === version) setError(String(error))
    } finally {
      if (mounted.current && request.current === version) setLoading(false)
    }
  }, [project.path])

  useEffect(() => {
    mounted.current = true
    void refresh()
    return () => { mounted.current = false; request.current++ }
  }, [refresh])

  useTauriEvent('git:project-changed', () => { void refresh() }, [refresh])

  const switchTo = async (wt: GitWorktree) => {
    if (busy || !onSwitchProject || wt === currentWorktree) return
    setBusy({ action: 'switch', path: wt.path })
    try {
      const path = worktreeProjectPath(project.path, currentWorktree?.path ?? project.path, wt.path)
      await api.gitWorktreeSwitch(project.path, path)
      if (!mounted.current) return
      await onSwitchProject({ ...project, path })
      pushToast('success', t('switched_worktree_ok'))
    } catch (error) { if (mounted.current) pushToast('error', String(error)) }
    finally { if (mounted.current) setBusy(null) }
  }

  const remove = async () => {
    if (!removal || busy || removal.is_main || removal === currentWorktree) return
    setBusy({ action: 'remove', path: removal.path })
    setRemoveError(null)
    try {
      await api.gitWorktreeRemove(project.path, removal.path, discardChanges)
      if (!mounted.current) return
      setRemoval(null)
      await refresh()
      onChanged()
      pushToast('success', t('worktree_removed_ok'))
    } catch (error) { if (mounted.current) setRemoveError(String(error)) }
    finally { if (mounted.current) setBusy(null) }
  }

  const sectionActionClass = 'focus-ring cursor-pointer shrink-0 flex h-7 w-7 items-center justify-center rounded-btn text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed'

  return (
    <>
      <GitSection title={t('worktrees_title')} count={worktrees.length} storageKey="git-sidebar-worktrees" defaultOpen={false}>
        <div aria-busy={loading} className="flex flex-col gap-1.5">
          {loading && worktrees.length === 0 && !error ? (
            <div role="status" className="flex items-center gap-2 px-2.5 py-3 text-[11px] text-muted">
              <IconSpinner className="w-3.5 h-3.5 animate-spin" />{tc('loading')}
            </div>
          ) : !error && worktrees.length === 0 ? (
            <p className="px-2.5 py-3 text-[11px] text-muted/70">{t('no_worktrees')}</p>
          ) : worktrees.map(wt => {
            const current = wt === currentWorktree
            const switching = busy?.action === 'switch' && busy.path === wt.path
            return (
              <div key={wt.path} className={`group grid grid-cols-[auto_minmax(0,1fr)_auto] items-center gap-2 rounded-item border px-2.5 py-2 transition-colors ${current ? 'border-accent/30 bg-accent/5' : 'border-outline/50 bg-base/40 hover:bg-raised/60'}`}>
                <IconClone className={`w-3.5 h-3.5 shrink-0 ${current ? 'text-accent-bright' : 'text-muted/60'}`} />
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-x-1.5 gap-y-0.5">
                    <span className="min-w-0 truncate text-[11px] font-medium text-ink" title={wt.branch ?? wt.head}>
                      {wt.branch ?? t('worktree_detached', { hash: wt.head.slice(0, 7) })}
                    </span>
                    {wt.is_main && <span className="text-[9px] text-muted/70">{t('worktree_main')}</span>}
                    <Tooltip content={wt.has_uncommitted ? t('worktree_dirty') : t('git_clean')}>
                      <span role="img" aria-label={wt.has_uncommitted ? t('worktree_dirty') : t('git_clean')}
                        className={`block shrink-0 w-1.5 h-1.5 rounded-full ${wt.has_uncommitted ? 'bg-amber' : 'bg-mint/60'}`} />
                    </Tooltip>
                  </div>
                  <Tooltip content={wt.path} className="w-full min-w-0">
                    <p dir="ltr" className="min-w-0 flex-1 truncate text-[10px] font-mono text-muted/60">{wt.path}</p>
                  </Tooltip>
                </div>
                {current ? (
                  <span className="flex shrink-0 items-center gap-1 rounded-tag bg-accent/10 px-1.5 py-1 text-[9px] font-medium text-accent-bright">
                    <IconCheck className="w-2.5 h-2.5" />{t('worktree_current')}
                  </span>
                ) : <div className="flex shrink-0 items-center gap-0.5">
                  {onSwitchProject && <Tooltip content={t('switch_worktree')}>
                    <button type="button" aria-label={t('switch_worktree_named', { name: wt.branch ?? wt.path })}
                      onClick={() => void switchTo(wt)} disabled={!!busy || loading} className={`${sectionActionClass} hover:text-accent-bright`}>
                      {switching ? <IconSpinner className="w-3.5 h-3.5 animate-spin" /> : <IconChevronRight className="w-3.5 h-3.5 rtl:rotate-180" />}
                    </button>
                  </Tooltip>}
                  {!wt.is_main && <Tooltip content={t('remove_worktree')}>
                    <button type="button" aria-label={t('remove_category_aria', { name: wt.branch ?? wt.path })}
                      onClick={() => { setRemoval(wt); setDiscardChanges(false); setRemoveError(null) }} disabled={!!busy || loading}
                      className={`${sectionActionClass} hover:text-danger opacity-60 group-hover:opacity-100 group-focus-within:opacity-100`}>
                      <IconTrash className="w-3.5 h-3.5" />
                    </button>
                  </Tooltip>}
                </div>}
              </div>
            )
          })}
          {error && <div role="alert" className="rounded-item border border-danger/25 bg-danger/5 p-2.5">
            <p className="text-[11px] text-danger wrap-break-word">{t('worktrees_load_error')}</p>
            <p className="mt-1 text-[10px] text-muted wrap-break-word">{error}</p>
            <button type="button" onClick={() => void refresh()} disabled={loading}
              className="focus-ring cursor-pointer mt-2 inline-flex items-center gap-1.5 rounded-btn px-2 py-1 text-[11px] text-muted hover:bg-raised hover:text-ink disabled:opacity-40">
              <IconRefresh className={`w-3 h-3 ${loading ? 'animate-spin' : ''}`} />{tc('retry')}
            </button>
          </div>}
          <button type="button" onClick={() => setCreating(true)} disabled={!!busy}
            className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-item border border-dashed border-outline/60 bg-base/40 text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed text-[11px] font-medium">
            <IconPlus className="w-3.5 h-3.5 text-accent-bright" />{t('add_worktree')}
          </button>
        </div>
      </GitSection>
      <AnimatePresence>
        {creating && <CreateWorktreeModal repositoryPath={currentWorktree?.path ?? project.path}
          onClose={() => setCreating(false)} onCreated={() => {
            if (!mounted.current) return
            setCreating(false); void refresh(); onChanged(); pushToast('success', t('worktree_created_ok'))
          }} />}
        {removal && <ModalShell icon={<IconTrash className="w-5 h-5 text-danger" />} title={t('remove_worktree')}
          description={t('remove_worktree_confirm_desc', { path: removal.path })} maxWidth="max-w-sm"
          onClose={busy ? undefined : () => setRemoval(null)}
          onKeyDown={event => { if (event.key === 'Escape' && !busy) { event.stopPropagation(); setRemoval(null) } }}
          footer={<div className="ms-auto flex items-center gap-2.5">
            <button type="button" onClick={() => setRemoval(null)} disabled={!!busy}
              className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40">{tc('cancel')}</button>
            <button type="button" onClick={() => void remove()} disabled={!!busy || (removal.has_uncommitted && !discardChanges)}
              className="focus-ring cursor-pointer inline-flex items-center gap-2 px-4 py-2.5 rounded-btn text-sm font-medium bg-danger text-white hover:brightness-110 transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
              {busy && <IconSpinner className="w-3.5 h-3.5 animate-spin" />}{busy ? t('worktree_removing') : t('remove_worktree')}
            </button>
          </div>}>
          <div className="flex flex-col gap-3 p-6 pt-0">
            <div className="rounded-item bg-raised px-3 py-2.5">
              <p className="text-xs font-medium text-ink wrap-break-word">{removal.branch ?? t('worktree_detached', { hash: removal.head.slice(0, 7) })}</p>
              <p dir="ltr" className="mt-1 text-[11px] font-mono text-muted wrap-break-word">{removal.path}</p>
            </div>
            {removal.has_uncommitted && <div className="rounded-item border border-danger/25 bg-danger/5 p-3">
              <p className="mb-3 text-xs text-danger leading-relaxed">{t('worktree_discard_warning')}</p>
              <Checkbox checked={discardChanges} onChange={setDiscardChanges} disabled={!!busy} label={t('worktree_discard_changes')}>
                {t('worktree_discard_changes')}
              </Checkbox>
            </div>}
            {removeError && <p role="alert" className="text-xs text-danger wrap-break-word">{removeError}</p>}
          </div>
        </ModalShell>}
      </AnimatePresence>
    </>
  )
}
