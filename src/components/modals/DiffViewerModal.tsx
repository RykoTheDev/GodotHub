import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { GitDiffResult } from '../../types'
import { ModalShell } from './ModalShell'
import { DiffBody } from '../git/DiffBody'
import { IconCode } from '../../lib/icons'

interface Props {
  title: string
  subtitle?: string
  fetchDiff: () => Promise<GitDiffResult>
  onClose: () => void
}

export function DiffViewerModal({ title, subtitle, fetchDiff, onClose }: Props) {
  const { t } = useTranslation('git')
  const [diff, setDiff] = useState<GitDiffResult | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setDiff(null)
    fetchDiff()
      .then((d) => {
        if (cancelled) return
        setDiff(d)
        setLoading(false)
      })
      .catch(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [])

  const adds =
    diff?.hunks.reduce(
      (acc, h) => acc + h.lines.filter((l) => l.kind === 'add').length,
      0,
    ) ?? 0
  const dels =
    diff?.hunks.reduce(
      (acc, h) => acc + h.lines.filter((l) => l.kind === 'delete').length,
      0,
    ) ?? 0

  const empty = !diff || diff.hunks.length === 0

  return (
    <ModalShell
      icon={<IconCode className="w-5 h-5 text-accent-bright" />}
      title={title}
      description={subtitle}
      maxWidth="max-w-3xl"
      onClose={onClose}
    >
      <div className="flex flex-col">
        <div className="flex items-center gap-2 px-5 pt-3 pb-2.5 border-b border-line/60">
          {!loading && !empty && (
            <>
              <span className="text-[11px] font-mono text-mint font-medium">
                +{adds}
              </span>
              <span className="text-[11px] font-mono text-danger font-medium">
                -{dels}
              </span>
            </>
          )}
        </div>

        <div className="max-h-[60vh] overflow-auto new-ui-scroll-viewport">
          {loading ? (
            <div className="flex flex-col gap-1.5 p-5 animate-pulse">
              {Array.from({ length: 14 }).map((_, i) => (
                <div
                  key={i}
                  className="h-4 rounded bg-raised"
                  style={{ width: `${40 + ((i * 37) % 55)}%` }}
                />
              ))}
            </div>
          ) : empty ? (
            <div className="px-5 py-10 flex flex-col items-center gap-2 text-muted/60">
              <IconCode className="w-6 h-6 opacity-40" />
              <p className="text-sm">{t('diff_no_diff')}</p>
            </div>
          ) : (
            <DiffBody diff={diff} />
          )}
        </div>
      </div>
    </ModalShell>
  )
}
