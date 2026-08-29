import { useState, useEffect, useCallback, useRef } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { check } from '@tauri-apps/plugin-updater'
import { getVersion } from '@tauri-apps/api/app'
import { ModalShell } from './ModalShell'
import {
  IconAlertTriangle,
  IconRefresh,
  IconDownload,
  IconCheck,
  IconExternalLink,
  IconX,
} from '../../lib/icons'
import { api } from '../../lib/api'
import { useSettings } from '../../hooks/useSettings'

type UpdateState =
  | { type: 'checking' }
  | { type: 'available'; version: string; notes: string | null; downloadAndInstall: () => Promise<void> }
  | { type: 'downloading'; progress: number }
  | { type: 'done' }
  | { type: 'uptodate' }
  | { type: 'portable'; version: string; notes: string | null }
  | { type: 'error'; message: string }

interface Props {
  onClose: () => void
  onOpenTokenSettings?: () => void
  mode?: 'manual' | 'preview'
}

const PREVIEW_VERSION = '1.0.0'

const PREVIEW_NOTES = `## What's new in v1.0.0 - The Preview Update

## 🚀 New

- Revamped the Check for Updates modal with structured release notes
- Added screen reader announcements with an Accessibility settings tab

## 🐛 Fixes

- Fixed a crash when switching workspaces with pinned projects
- Fixed update checks failing silently when GitHub rate limits are hit

## ✨ Improvements

- Faster startup times across all platforms
- Reworked workspace modals with compact style pickers

## ⚠️ Known Issues

- Linux OS: AppImage won't work on some distros, use the .rpm or .deb package instead
- Windows: the taskbar may briefly show a duplicate icon until the app restarts`

const PREVIEW_STATES = [
  'checking',
  'available',
  'downloading',
  'done',
  'uptodate',
  'portable',
  'error',
] as const

type TokenHint = 'rate-limited' | 'token-rejected'

function githubTokenHint(message: string, hasToken: boolean): TokenHint | null {
  if (/\b401\b/.test(message)) return 'token-rejected'
  if (/\b403\b/.test(message) || /rate limit/i.test(message)) {
    return hasToken ? 'token-rejected' : 'rate-limited'
  }
  return null
}

function downloadsFromGithubApi(rawJson: Record<string, unknown> | undefined) {
  const platforms = rawJson?.platforms as
    | Record<string, { url?: unknown }>
    | undefined
  if (!platforms) return false
  const urls = Object.values(platforms)
    .map((p) => p?.url)
    .filter((u): u is string => typeof u === 'string')
  if (urls.length === 0) return false
  return urls.every((u) => {
    try {
      return new URL(u).host === 'api.github.com'
    } catch {
      return false
    }
  })
}

interface ReleaseSection {
  title: string
  items: string[]
}

interface ParsedReleaseNotes {
  intro: string[]
  sections: ReleaseSection[]
}

function parseReleaseNotes(md: string | null): ParsedReleaseNotes {
  const result: ParsedReleaseNotes = { intro: [], sections: [] }
  if (!md) return result
  let current: ReleaseSection | null = null
  for (const rawLine of md.split('\n')) {
    const line = rawLine.trimEnd()
    if (/^#{2,4}\s+/.test(line)) {
      current = { title: line.replace(/^#{2,4}\s+/, '').trim(), items: [] }
      result.sections.push(current)
    } else if (current) {
      const trimmed = line.trim()
      if (!trimmed) continue
      current.items.push(trimmed.replace(/^[-*]\s+/, ''))
    } else if (line.trim()) {
      result.intro.push(line.trim())
    }
  }
  result.sections = result.sections.filter((s) => s.items.length > 0)
  return result
}

function isKnownIssueSection(s: ReleaseSection): boolean {
  return /known issue/i.test(s.title)
}

export function CheckForUpdatesModal({
  onClose,
  onOpenTokenSettings,
  mode = 'manual',
}: Props) {
  const { t } = useTranslation('common')
  const { settings } = useSettings()
  const isPreview = mode === 'preview'
  const simulateRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const [state, setState] = useState<UpdateState>(() =>
    isPreview
      ? {
          type: 'available',
          version: PREVIEW_VERSION,
          notes: PREVIEW_NOTES,
          downloadAndInstall: () => Promise.resolve(),
        }
      : { type: 'checking' },
  )
  const [currentVersion, setCurrentVersion] = useState<string | null>(null)
  const onCloseRef = useRef(onClose)
  onCloseRef.current = onClose

  const githubToken = settings.github_token?.trim() || null

  const notes =
    state.type === 'available' ? parseReleaseNotes(state.notes) : null
  const knownIssues =
    notes?.sections.filter(isKnownIssueSection).flatMap((s) => s.items) ?? []
  const hasReleaseNotesContent =
    (notes?.sections.some((s) => !isKnownIssueSection(s)) ?? false) ||
    (notes?.intro.length ?? 0) > 0

  const clearSimulation = () => {
    if (simulateRef.current) {
      clearInterval(simulateRef.current)
      simulateRef.current = null
    }
  }

  const simulateDownload = useCallback(() => {
    clearSimulation()
    return new Promise<void>((resolve) => {
      setState({ type: 'downloading', progress: 0 })
      let progress = 0
      simulateRef.current = setInterval(() => {
        progress = Math.min(progress + 0.045 + Math.random() * 0.06, 1)
        setState({ type: 'downloading', progress })
        if (progress >= 1) {
          clearSimulation()
          setTimeout(() => {
            setState({ type: 'done' })
            resolve()
          }, 350)
        }
      }, 200)
    })
  }, [])

  const doCheck = useCallback(async () => {
    if (mode === 'preview') {
      setState({
        type: 'available',
        version: PREVIEW_VERSION,
        notes: PREVIEW_NOTES,
        downloadAndInstall: simulateDownload,
      })
      return
    }
    setState({ type: 'checking' })
    try {
      const [update, portable] = await Promise.all([
        check(),
        api.isPortableInstall().catch(() => false),
      ])
      if (update) {
        if (portable) {
          setState({
            type: 'portable',
            version: update.version,
            notes: update.body ?? null,
          })
          return
        }
        setState({
          type: 'available',
          version: update.version,
          notes: update.body ?? null,
          downloadAndInstall: async () => {
            setState({ type: 'downloading', progress: 0 })
            let downloaded = 0
            let total: number | null = null
            try {
              const sendToken =
                githubToken && downloadsFromGithubApi(update.rawJson)
              await update.downloadAndInstall(
                (progressEvent) => {
                  if (progressEvent.event === 'Started') {
                    downloaded = 0
                    total = progressEvent.data.contentLength ?? null
                  } else if (progressEvent.event === 'Progress') {
                    downloaded += progressEvent.data.chunkLength
                    if (total) {
                      setState({
                        type: 'downloading',
                        progress: Math.min(downloaded / total, 1),
                      })
                    }
                  } else if (progressEvent.event === 'Finished') {
                    setState({ type: 'downloading', progress: 1 })
                  }
                },
                sendToken
                  ? { headers: { Authorization: `Bearer ${githubToken}` } }
                  : undefined,
              )
              setState({ type: 'done' })
            } catch (e) {
              setState({ type: 'error', message: String(e) })
            }
          },
        })
      } else {
        setState({ type: 'uptodate' })
      }
    } catch (e) {
      setState({ type: 'error', message: String(e) })
    }
  }, [mode, githubToken, simulateDownload])

  useEffect(() => {
    getVersion().then(setCurrentVersion).catch(() => setCurrentVersion(null))
  }, [])

  useEffect(() => {
    doCheck()
  }, [doCheck])

  useEffect(() => () => clearSimulation(), [])

  const switchPreviewState = (to: (typeof PREVIEW_STATES)[number]) => {
    clearSimulation()
    switch (to) {
      case 'checking':
        setState({ type: 'checking' })
        break
      case 'available':
        setState({
          type: 'available',
          version: PREVIEW_VERSION,
          notes: PREVIEW_NOTES,
          downloadAndInstall: simulateDownload,
        })
        break
      case 'downloading':
        setState({ type: 'downloading', progress: 0 })
        let progress = 0
        simulateRef.current = setInterval(() => {
          progress = Math.min(progress + 0.05 + Math.random() * 0.07, 1)
          setState({ type: 'downloading', progress })
          if (progress >= 1) clearSimulation()
        }, 160)
        break
      case 'done':
        setState({ type: 'done' })
        break
      case 'uptodate':
        setState({ type: 'uptodate' })
        break
      case 'portable':
        setState({
          type: 'portable',
          version: PREVIEW_VERSION,
          notes: PREVIEW_NOTES,
        })
        break
      case 'error':
        setState({
          type: 'error',
          message:
            'Preview error: GitHub API rate limit reached (HTTP 403). Add a token in Settings to keep checking.',
        })
        break
    }
  }

  const handleInstall = async () => {
    if (state.type === 'available') {
      await state.downloadAndInstall()
    }
  }

  const openTokenSettings = () => {
    onClose()
    onOpenTokenSettings?.()
  }

  return (
    <ModalShell
      icon={<IconDownload className="w-5 h-5 text-accent-bright" />}
      title={t('check_updates_title_modal')}
      maxWidth="max-w-2xl"
      onClose={onClose}
      showClose={false}
      footer={
        <div className="w-full flex items-center justify-end">
          <motion.button
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-4 py-2 rounded-item border border-outline/50 text-xs font-medium text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
          >
            {t('check_updates_close_btn')}
          </motion.button>
        </div>
      }
    >
        <div className="flex flex-col items-center gap-5 p-6">
          {isPreview && (
            <div className="w-full flex flex-col items-center gap-2.5">
              <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-tag bg-amber/15 text-amber text-[10px] font-semibold uppercase tracking-wider">
                {t('check_updates_preview_badge')}
              </span>
              <div className="flex flex-wrap items-center justify-center gap-1.5">
                {PREVIEW_STATES.map((s) => (
                  <button
                    key={s}
                    type="button"
                    onClick={() => switchPreviewState(s)}
                    className={`focus-ring cursor-pointer px-2.5 py-1 rounded-item text-[10px] font-medium border transition-colors ${
                      state.type === s
                        ? 'bg-accent/15 border-accent-dim/40 text-ink'
                        : 'bg-raised border-line text-muted hover:text-ink hover:border-accent-dim'
                    }`}
                  >
                    {t(`preview_state_${s}`)}
                  </button>
                ))}
              </div>
            </div>
          )}

          <AnimatePresence mode="wait" initial={false}>
            <motion.div
              key={state.type}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.16, ease: 'easeOut' }}
              className="w-full flex flex-col items-center gap-5"
            >
              {state.type === 'checking' && (
            <div className="flex flex-col items-center gap-4">
              <div className="w-14 h-14 rounded-full bg-accent/10 flex items-center justify-center">
                <IconRefresh className="w-6 h-6 text-accent animate-spin" />
              </div>
              <p className="text-sm text-muted">{t('checking_updates')}</p>
            </div>
          )}

          {state.type === 'uptodate' && (
            <div className="flex flex-col items-center gap-4">
              <div className="w-14 h-14 rounded-full bg-mint/10 flex items-center justify-center">
                <IconCheck className="w-6 h-6 text-mint" />
              </div>
              <div className="text-center">
                <p className="text-sm font-medium text-ink">{t('up_to_date')}</p>
                <p className="text-xs text-muted mt-1">
                  {t('is_latest', { version: currentVersion ?? '?' })}
                </p>
              </div>
            </div>
          )}

          {state.type === 'portable' && (
            <div className="flex flex-col items-center gap-5 w-full">
              <div className="w-14 h-14 rounded-full bg-amber/10 flex items-center justify-center">
                <IconAlertTriangle className="w-6 h-6 text-amber" />
              </div>
              <div className="text-center">
                <p className="text-sm font-medium text-ink">
                  {t('check_updates_portable_title')}
                </p>
                <p className="text-xs text-muted mt-1 max-w-xs leading-relaxed">
                  {t('check_updates_portable_desc')}
                </p>
              </div>
              <div className="w-full max-w-sm rounded-item border border-amber/30 bg-amber/10 p-4">
                <div className="flex flex-col gap-3">
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-xs font-semibold text-ink">
                      v{state.version}
                    </span>
                    <span className="text-xs text-muted">—</span>
                    <span className="text-xs text-muted">
                      {t('check_updates_version_available', { version: state.version })}
                    </span>
                  </div>
                  <motion.a
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    href="https://github.com/RykoTheDev/GodotHub/releases/latest"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="focus-ring cursor-pointer flex items-center justify-center gap-2 px-5 py-2.5 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors no-underline"
                  >
                    <IconExternalLink className="w-4 h-4" />
                    {t('check_updates_download_from_github')}
                  </motion.a>
                </div>
              </div>
            </div>
          )}

          {state.type === 'available' && (
            <div className="flex flex-col items-center gap-5 w-full">
              <div className="w-full grid grid-cols-1 sm:grid-cols-[minmax(0,15rem)_minmax(0,1fr)] gap-6 items-start">
                <div className="flex flex-col gap-5 min-w-0 w-full">
                  <div className="flex items-center gap-3.5">
                    <div className="w-12 h-12 shrink-0 rounded-tile bg-accent/10 flex items-center justify-center">
                      <IconDownload className="w-5 h-5 text-accent-bright" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-ink leading-snug">
                        {t('check_updates_version_available', {
                          version: state.version,
                        })}
                      </p>
                      <p className="text-xs text-muted mt-0.5">
                        {t('check_updates_ask_download')}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-item bg-raised border border-line">
                      <span className="w-1.5 h-1.5 rounded-full bg-mint" />
                      <span className="font-mono text-xs text-ink">
                        v{currentVersion ?? '?'}
                      </span>
                    </span>
                    <IconRefresh className="w-3 h-3 text-muted/40 rotate-180 shrink-0" />
                    <span className="flex items-center gap-1.5 px-3 py-1.5 rounded-item bg-accent/15 border border-accent/30">
                      <span className="w-1.5 h-1.5 rounded-full bg-accent-bright animate-pulse" />
                      <span className="font-mono text-xs font-semibold text-accent-bright">
                        v{state.version}
                      </span>
                    </span>
                  </div>

                  {knownIssues.length > 0 && (
                    <div className="w-full rounded-item border border-amber/30 bg-amber/10 p-4">
                      <p className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-amber mb-2">
                        <IconAlertTriangle className="w-3.5 h-3.5 shrink-0" />
                        {t('check_updates_known_issues')}
                      </p>
                      <ul className="flex flex-col gap-1.5">
                        {knownIssues.map((issue, i) => (
                          <li
                            key={i}
                            className="text-xs text-muted leading-relaxed flex gap-2"
                          >
                            <span className="shrink-0 text-amber">•</span>
                            <span className="whitespace-pre-wrap wrap-break-word">
                              {issue}
                            </span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>

                <div className="min-w-0 w-full">
                  {notes && hasReleaseNotesContent && (
                    <div className="w-full bg-raised rounded-item border border-line overflow-hidden">
                      <div className="px-4 py-2.5 border-b border-line/70 bg-raised">
                        <p className="text-[11px] font-semibold uppercase tracking-wider text-muted">
                          {t('check_updates_release_notes')}
                        </p>
                      </div>
                      <div className="max-h-64 overflow-y-auto">
                        {notes.intro.length > 0 && (
                          <p className="px-4 pt-3 text-xs text-muted leading-relaxed">
                            {notes.intro.join(' ')}
                          </p>
                        )}
                        {notes.sections
                          .filter((s) => !isKnownIssueSection(s))
                          .map((section, i) => (
                            <div
                              key={i}
                              className="px-4 py-3 border-b border-line/50 last:border-b-0"
                            >
                              <p className="text-[10px] font-semibold uppercase tracking-wide mb-1.5 text-muted">
                                {section.title}
                              </p>
                              <ul className="flex flex-col gap-1.5">
                                {section.items.map((item, j) => (
                                  <li
                                    key={j}
                                    className="text-xs text-ink/90 leading-relaxed flex gap-2"
                                  >
                                    <span className="shrink-0 text-muted">
                                      •
                                    </span>
                                    <span className="whitespace-pre-wrap wrap-break-word">
                                      {item}
                                    </span>
                                  </li>
                                ))}
                              </ul>
                            </div>
                          ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={handleInstall}
                className="focus-ring cursor-pointer flex items-center gap-2 px-6 py-2.5 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
              >
                <IconDownload className="w-4 h-4" />
                {t('install_update')}
              </motion.button>
            </div>
          )}

          {state.type === 'downloading' && (
            <div className="flex flex-col items-center gap-4 w-full">
              <div className="w-14 h-14 rounded-full bg-accent/10 flex items-center justify-center">
                <IconDownload className="w-6 h-6 text-accent animate-pulse" />
              </div>
              <div className="text-center w-full">
                <p className="text-sm font-medium text-ink">{t('downloading_update')}</p>
                <p className="text-xs text-muted mt-1">
                  {t('percent_complete', { percent: Math.round(state.progress * 100) })}
                </p>
              </div>
              <div className="w-full h-2 rounded-full bg-line overflow-hidden">
                <motion.div
                  className="h-full bg-accent rounded-full"
                  initial={{ width: '0%' }}
                  animate={{ width: `${Math.round(state.progress * 100)}%` }}
                  transition={{ duration: 0.3 }}
                />
              </div>
            </div>
          )}

          {state.type === 'done' && (
            <div className="flex flex-col items-center gap-4">
              <div className="w-14 h-14 rounded-full bg-mint/10 flex items-center justify-center">
                <IconCheck className="w-6 h-6 text-mint" />
              </div>
              <div className="text-center">
                <p className="text-sm font-medium text-ink">{t('update_downloaded')}</p>
                <p className="text-xs text-muted mt-1">{t('restart_to_apply')}</p>
              </div>
              <p className="text-[11px] text-muted/70 text-center max-w-xs">
                {t('update_applied_desc')}
              </p>
            </div>
          )}

          {state.type === 'error' &&
            (() => {
              const hint = githubTokenHint(state.message, !!githubToken)
              return (
                <div className="flex flex-col items-center gap-4 w-full">
                  <div className="w-14 h-14 rounded-full bg-danger/10 flex items-center justify-center">
                    <IconX className="w-6 h-6 text-danger" />
                  </div>
                  <div className="text-center">
                    <p className="text-sm font-medium text-ink">
                      {hint === 'rate-limited'
                        ? t('check_updates_rate_limited')
                        : hint === 'token-rejected'
                          ? t('check_updates_token_rejected')
                          : t('check_updates_failed')}
                    </p>
                    <p className="text-xs text-muted mt-1 max-w-xs">
                      {state.message}
                    </p>
                  </div>
                  {hint && (
                    <div className="w-full bg-raised rounded-xl border border-line p-4 flex flex-col gap-3">
                      <p className="text-[11px] text-muted leading-relaxed">
                        {hint === 'token-rejected'
                          ? t('check_updates_rate_limited_token_hint')
                          : t('check_updates_rate_limited_hint')}
                      </p>
                      <motion.button
                        whileHover={{ y: -1 }}
                        whileTap={{ scale: 0.96 }}
                        onClick={openTokenSettings}
                        className="focus-ring cursor-pointer self-start px-4 py-2 rounded-item bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
                      >
                        {hint === 'token-rejected'
                          ? t('check_updates_open_token_settings')
                          : t('check_updates_add_token')}
                      </motion.button>
                    </div>
                  )}
                  <motion.button
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    onClick={doCheck}
                    className="focus-ring cursor-pointer flex items-center gap-2 px-5 py-2.5 rounded-item border border-line hover:border-accent-dim hover:bg-raised text-sm font-medium text-ink transition-colors"
                  >
                    <IconRefresh className="w-4 h-4" />
                    {t('check_updates_try_again')}
                  </motion.button>
                </div>
              )
            })()}
            </motion.div>
          </AnimatePresence>
        </div>
    </ModalShell>
  )
}
