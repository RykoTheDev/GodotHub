import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { createPortal } from 'react-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { openUrl } from '@tauri-apps/plugin-opener'
import { formatLocaleDate } from '../lib/locale'

interface PR {
  number: number
  title: string
  state: 'open' | 'closed' | 'merged'
  html_url: string
  created_at: string
  merged_at: string | null
}

interface Props {
  login: string
  avatarUrl: string
  onClose: () => void
}

function stateBadge(pr: PR, t: (key: string) => string) {
  if (pr.merged_at) {
    return (
      <span className="text-[9px] font-semibold px-1.5 py-0.5 rounded bg-accent/15 text-accent">
        {t('contributor_pr_merged')}
      </span>
    )
  }
  if (pr.state === 'open') {
    return (
      <span className="text-[9px] font-semibold px-1.5 py-0.5 rounded bg-mint/15 text-mint">
        {t('contributor_pr_open')}
      </span>
    )
  }
  return (
    <span className="text-[9px] font-semibold px-1.5 py-0.5 rounded bg-danger/15 text-danger">
      {t('contributor_pr_closed')}
    </span>
  )
}

function formatDate(iso: string) {
  return formatLocaleDate(new Date(iso), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

export function ContributorPRsModal({ login, avatarUrl, onClose }: Props) {
  const { t } = useTranslation('common')
  const [prs, setPrs] = useState<PR[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  useEffect(() => {
    let cancelled = false
    fetch(
      `https://api.github.com/search/issues?q=repo:RykoTheDev/GodotHub+is:pr+author:${login}&per_page=50&sort=created&order=desc`,
    )
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`)
        return r.json()
      })
      .then((data) => {
        if (cancelled) return
        setPrs(
          (data.items ?? []).map((item: Record<string, unknown>) => ({
            number: item.number as number,
            title: item.title as string,
            state: (item.pull_request as Record<string, unknown>)?.merged_at
              ? ('merged' as const)
              : (item.state as 'open' | 'closed'),
            html_url: item.html_url as string,
            created_at: item.created_at as string,
            merged_at: ((item.pull_request as Record<string, unknown>)?.merged_at as string) ?? null,
          })),
        )
        setLoading(false)
      })
      .catch(() => {
        if (!cancelled) {
          setError(true)
          setLoading(false)
        }
      })
    return () => {
      cancelled = true
    }
  }, [login])

  return createPortal(
    <AnimatePresence>
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
          exit={{ opacity: 0, scale: 0.96 }}
          transition={{ type: 'spring', stiffness: 380, damping: 30 }}
          role="dialog"
          aria-modal="true"
          className="bg-surface rounded-modal w-full max-w-lg max-h-[80vh] flex flex-col shadow-2xl overflow-clip"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="flex items-center gap-3 px-5 py-4 border-b border-line shrink-0">
            <img
              src={avatarUrl}
              alt={login}
              className="w-9 h-9 rounded-full"
              onError={(e) => {
                e.currentTarget.style.display = 'none'
              }}
            />
            <div className="min-w-0 flex-1">
              <button
                type="button"
                onClick={() => openUrl(`https://github.com/${login}`)}
                className="focus-ring cursor-pointer text-sm font-semibold text-ink hover:text-accent transition-colors"
              >
                {login}
              </button>
              <p className="text-[11px] text-muted">
                {loading
                  ? t('contributor_pr_loading')
                  : t(prs.length === 1 ? 'contributor_pr_count_one' : 'contributor_pr_count_other', { count: prs.length })}
              </p>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="focus-ring cursor-pointer p-1.5 rounded-md text-muted hover:text-ink hover:bg-raised transition-colors"
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round">
                <path d="M18 6L6 18M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div className="flex-1 min-h-0 overflow-y-auto">
            {loading ? (
              <div className="flex items-center justify-center py-12">
                <motion.svg
                  width={20}
                  height={20}
                  viewBox="0 0 24 24"
                  fill="none"
                  animate={{ rotate: 360 }}
                  transition={{ repeat: Infinity, duration: 0.8, ease: 'linear' }}
                >
                  <path
                    d="M21 12a9 9 0 11-6.219-8.56"
                    stroke="currentColor"
                    strokeWidth={2}
                    strokeLinecap="round"
                  />
                </motion.svg>
              </div>
            ) : error ? (
              <div className="flex flex-col items-center justify-center gap-2 py-12 text-muted text-sm">
                <p>{t('contributor_pr_load_failed')}</p>
                <p className="text-xs text-muted/50">{t('contributor_pr_network_hint')}</p>
              </div>
            ) : prs.length === 0 ? (
              <div className="flex flex-col items-center justify-center gap-2 py-12 text-muted text-sm">
                <p>{t('contributor_pr_empty')}</p>
              </div>
            ) : (
              <div className="flex flex-col">
                {prs.map((pr) => (
                  <button
                    key={pr.number}
                    type="button"
                    onClick={() => openUrl(pr.html_url)}
                    className="focus-ring cursor-pointer flex items-start gap-3 px-5 py-3 text-left hover:bg-raised/60 transition-colors border-b border-line/50 last:border-b-0"
                  >
                    <span className="text-[11px] font-mono text-muted/50 shrink-0 mt-0.5">
                      #{pr.number}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium text-ink truncate">{pr.title}</p>
                      <p className="text-[10px] text-muted mt-0.5">{formatDate(pr.created_at)}</p>
                    </div>
                    {stateBadge(pr, t)}
                  </button>
                ))}
              </div>
            )}
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>,
    document.body,
  )
}
