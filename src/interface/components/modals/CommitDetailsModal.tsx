import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { GitCommitDetails, Project } from '../../../types'
import { api } from '../../../lib/api'
import { shortHash } from '../../../lib/gitGraph'
import { ModalShell } from './ModalShell'
import { DiffBody } from '../git/DiffBody'
import { IconGitBranch, IconUser } from '../../lib/icons'

interface Props {
  project: Project
  hash: string
  onClose: () => void
}

function statusMeta(status: string) {
  const s = status.charAt(0)
  const isAdded = s === 'A'
  const isDeleted = s === 'D'
  const isModified = s === 'M' || s === 'T'
  const isRenamed = s === 'R'
  return {
    badge: isAdded ? 'A' : isDeleted ? 'D' : isModified ? 'M' : isRenamed ? 'R' : s,
    color: isAdded
      ? 'text-mint'
      : isDeleted
        ? 'text-danger'
        : isModified
          ? 'text-amber'
          : 'text-muted/50',
  }
}

export function CommitDetailsModal({ project, hash, onClose }: Props) {
  const { t } = useTranslation('git')
  const [details, setDetails] = useState<GitCommitDetails | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    api
      .gitShowCommit(project.path, hash)
      .then((d) => {
        if (cancelled) return
        setDetails(d)
        setLoading(false)
      })
      .catch(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [project.path, hash])

  return (
    <ModalShell
      icon={<IconGitBranch className="w-5 h-5 text-accent-bright" />}
      title={details ? details.message || shortHash(hash) : shortHash(hash)}
      description={details ? `${shortHash(hash)} · ${details.author}` : project.name}
      maxWidth="max-w-3xl"
      onClose={onClose}
    >
      <div className="flex flex-col">
        {details && (
          <div className="flex items-center gap-3 px-5 pt-3 pb-2.5 border-b border-line/60">
            <span className="font-mono text-[11px] text-accent-bright shrink-0">
              {shortHash(details.hash)}
            </span>
            <span className="flex items-center gap-1 text-[11px] text-muted">
              <IconUser className="w-3 h-3" />
              {details.author}
            </span>
            <span className="text-[11px] text-muted/60">{details.date}</span>
          </div>
        )}

        <div className="max-h-[60vh] overflow-auto new-ui-scroll-viewport">
          {loading || !details ? (
            <div className="flex flex-col gap-1.5 p-5 animate-pulse">
              {Array.from({ length: 14 }).map((_, i) => (
                <div
                  key={i}
                  className="h-4 rounded bg-raised"
                  style={{ width: `${40 + ((i * 37) % 55)}%` }}
                />
              ))}
            </div>
          ) : (
            <>
              {details.files.length > 0 && (
                <div className="px-3 py-2 border-b border-line/40 flex flex-col gap-0.5">
                  {details.files.map((f) => {
                    const meta = statusMeta(f.status)
                    return (
                      <div
                        key={f.path}
                        className="flex items-center gap-2 px-1.5 py-1 rounded"
                      >
                        <span
                          className={`w-3 shrink-0 text-[9px] font-mono font-bold ${meta.color}`}
                        >
                          {meta.badge}
                        </span>
                        <span className="flex-1 min-w-0 text-[11px] font-mono text-muted truncate">
                          {f.path}
                        </span>
                      </div>
                    )
                  })}
                </div>
              )}
              {details.diff.hunks.length > 0 ? (
                <DiffBody diff={details.diff} />
              ) : (
                <div className="px-5 py-8 text-center text-[12px] text-muted/60">
                  {t('diff_no_diff')}
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </ModalShell>
  )
}
