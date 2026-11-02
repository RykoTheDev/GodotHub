import { useEffect, useId, useRef, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { api } from '../../lib/api'
import type { DeviceFlowStart } from '../../types'
import {
  IconAlertTriangle,
  IconCheck,
  IconCopy,
  IconExternalLink,
  IconGithub,
  IconGitlab,
  IconRefresh,
  IconSpinner,
  IconX,
} from '../../lib/icons'
import { reportError } from '../../lib/toast'

type Provider = 'github' | 'gitlab'
type Status = 'starting' | 'waiting' | 'success' | 'error' | 'expired'

interface Props {
  provider: Provider
  baseUrl?: string | null
  clientId?: string | null
  onClose: () => void
  onConnected: (username: string) => void
}

const FOCUSABLE = 'button:not(:disabled), a[href], [tabindex]:not([tabindex="-1"])'

function formatRemaining(seconds: number) {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return `${m}:${String(s).padStart(2, '0')}`
}

function Step({
  index,
  title,
  done,
  active,
  last = false,
  children,
}: {
  index: number
  title: string
  done: boolean
  active: boolean
  last?: boolean
  children?: ReactNode
}) {
  return (
    <li className={`relative flex gap-3.5 ${last ? '' : 'pb-5'}`}>
      {!last && (
        <span aria-hidden="true" className="absolute start-3.5 top-8 bottom-1 w-px bg-outline/40" />
      )}
      <span
        className={`relative z-10 w-7 h-7 shrink-0 rounded-full flex items-center justify-center text-xs font-semibold  ${
          done
            ? 'bg-mint/15 text-mint'
            : active
              ? 'bg-accent text-white'
              : 'bg-raised text-muted border border-outline/50'
        }`}
      >
        {done ? <IconCheck className="w-3 h-3" /> : index}
      </span>
      <div className="flex-1 min-w-0 pt-1 flex flex-col gap-2.5">
        <p className={`text-sm font-medium ${active || done ? 'text-ink' : 'text-muted'}`}>{title}</p>
        {children}
      </div>
    </li>
  )
}

export function GitAuthModal({
  provider,
  baseUrl,
  clientId,
  onClose,
  onConnected,
}: Props) {
  const { t: tc } = useTranslation('common')
  const { t: ts } = useTranslation('settings')
  const titleId = useId()
  const dialogRef = useRef<HTMLDivElement>(null)
  const [returnFocus] = useState(() => document.activeElement as HTMLElement | null)
  const [attempt, setAttempt] = useState(0)
  const [flow, setFlow] = useState<DeviceFlowStart | null>(null)
  const [status, setStatus] = useState<Status>('starting')
  const [message, setMessage] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)
  const [linkCopied, setLinkCopied] = useState(false)
  const [opened, setOpened] = useState(false)
  const [remaining, setRemaining] = useState<number | null>(null)
  const stopRef = useRef(false)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const onConnectedRef = useRef(onConnected)
  onConnectedRef.current = onConnected
  const onCloseRef = useRef(onClose)
  onCloseRef.current = onClose
  const baseUrlRef = useRef(baseUrl)
  baseUrlRef.current = baseUrl
  const clientIdRef = useRef(clientId)
  clientIdRef.current = clientId

  const providerLabel = provider === 'github' ? 'GitHub' : 'GitLab'
  const ProviderIcon = provider === 'github' ? IconGithub : IconGitlab
  const host = provider === 'gitlab' && baseUrl ? baseUrl.replace(/^https?:\/\//, '') : null

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dialog-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dialog-close'))
    }
  }, [])

  useEffect(() => {
    dialogRef.current?.focus({ preventScroll: true })
    return () => {
      if (returnFocus?.isConnected) returnFocus.focus({ preventScroll: true })
    }
  }, [returnFocus])

  useEffect(() => {
    stopRef.current = false
    let cancelled = false
    setFlow(null)
    setStatus('starting')
    setMessage(null)
    setOpened(false)
    setRemaining(null)

    const poll = async (flowInfo: DeviceFlowStart) => {
      if (stopRef.current) return
      try {
        const result = await api.gitAuthPollDeviceFlow(
          provider,
          flowInfo.device_code,
          baseUrlRef.current,
          clientIdRef.current,
        )
        if (cancelled || stopRef.current) return
        if (result.status === 'success') {
          setStatus('success')
          setMessage(result.username)
          onConnectedRef.current(result.username)
          setTimeout(() => {
            if (!stopRef.current) onCloseRef.current()
          }, 1600)
          return
        }
        if (result.status === 'error') {
          setStatus('error')
          setMessage(result.message)
          return
        }
        timerRef.current = setTimeout(() => poll(flowInfo), flowInfo.interval * 1000)
      } catch (e) {
        if (cancelled || stopRef.current) return
        setStatus('error')
        setMessage(String(e))
      }
    }

    api
      .gitAuthStartDeviceFlow(provider, baseUrlRef.current, clientIdRef.current)
      .then((info) => {
        if (cancelled || stopRef.current) return
        setFlow(info)
        setStatus('waiting')
        setRemaining(info.expires_in)
        timerRef.current = setTimeout(() => poll(info), info.interval * 1000)
      })
      .catch((e) => {
        if (cancelled || stopRef.current) return
        setStatus('error')
        setMessage(String(e))
      })

    return () => {
      cancelled = true
      stopRef.current = true
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [provider, attempt])

  useEffect(() => {
    if (status !== 'waiting' || remaining === null) return
    if (remaining <= 0) {
      stopRef.current = true
      if (timerRef.current) clearTimeout(timerRef.current)
      setStatus('expired')
      return
    }
    const tick = setTimeout(() => setRemaining((r) => (r === null ? r : r - 1)), 1000)
    return () => clearTimeout(tick)
  }, [status, remaining])

  const verificationUrl = flow?.verification_uri_complete || flow?.verification_uri

  const copyCode = async () => {
    if (!flow) return false
    try {
      await navigator.clipboard.writeText(flow.user_code)
      setCopied(true)
      setTimeout(() => setCopied(false), 1600)
      return true
    } catch {
      return false
    }
  }

  const copyAndOpen = async () => {
    await copyCode()
    if (!verificationUrl) return
    openUrl(verificationUrl).catch(reportError)
    setOpened(true)
  }

  const copyLink = async () => {
    if (!verificationUrl) return
    try {
      await navigator.clipboard.writeText(verificationUrl)
      setLinkCopied(true)
      setTimeout(() => setLinkCopied(false), 1600)
    } catch {}
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.stopPropagation()
      return
    }
    if (e.key !== 'Tab') return
    const dialog = dialogRef.current
    if (!dialog) return
    const focusable = [...dialog.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
      (el) => el.getClientRects().length > 0,
    )
    if (focusable.length === 0) {
      e.preventDefault()
      return
    }
    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    const active = document.activeElement
    if (e.shiftKey && (active === first || active === dialog)) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && active === last) {
      e.preventDefault()
      first.focus()
    }
  }

  const codeGroups = flow?.user_code.split('-') ?? []
  const expiringSoon = remaining !== null && remaining <= 60

  return createPortal(
    <div


      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm"
      onClick={(e) => e.stopPropagation()}
    >
      <div

        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        onKeyDown={handleKeyDown}
        className="relative w-full max-w-md rounded-[28px] bg-surface border border-outline/40 shadow-2xl overflow-hidden outline-none"
      >
        <button
          type="button"
          onClick={onClose}
          aria-label={tc('close')}
          className="focus-ring cursor-pointer absolute top-4 end-4 z-10 w-8 h-8 flex items-center justify-center rounded-full text-muted hover:text-ink hover:bg-ink/10 "
        >
          <IconX className="w-3.5 h-3.5" />
        </button>

        <div className="relative px-7 pt-9 pb-6 flex flex-col items-center text-center gap-3">
          <div className="relative">
            <span className="w-16 h-16 rounded-full bg-raised border border-outline/50 flex items-center justify-center">
              <ProviderIcon className="w-8 h-8 text-ink" />
            </span>
            {status === 'success' && (
              <span className="absolute -bottom-1 -end-1 w-6 h-6 rounded-full bg-mint text-white flex items-center justify-center ring-4 ring-surface">
                <IconCheck className="w-3 h-3" />
              </span>
            )}
          </div>
          <div className="flex flex-col gap-1">
            <h2 id={titleId} className="font-display text-xl font-black tracking-tight text-ink">
              {ts('git_auth_title', { provider: providerLabel })}
            </h2>
            {host && <p dir="ltr" className="text-xs text-muted">{host}</p>}
          </div>
        </div>

        <div className="relative px-7 pb-9">
          {status === 'starting' && (
            <div className="flex flex-col items-center gap-3 py-8">
              <IconSpinner className="w-5 h-5 animate-spin text-accent-bright" />
              <p className="text-sm text-muted">{tc('starting')}</p>
            </div>
          )}

          {status === 'success' && (
            <div className="flex flex-col items-center gap-1.5 py-6 text-center">
              <p className="text-base font-semibold text-ink">
                {ts('git_connected_as', { username: message })}
              </p>
              <p className="text-xs text-muted">{ts('git_auth_success_hint')}</p>
            </div>
          )}

          {(status === 'error' || status === 'expired') && (
            <div className="flex flex-col items-center gap-4 py-2 text-center">
              <span className="w-11 h-11 rounded-full bg-danger/10 text-danger flex items-center justify-center">
                <IconAlertTriangle className="w-5 h-5" />
              </span>
              <div className="flex flex-col gap-1">
                <p className="text-sm font-semibold text-ink">
                  {status === 'expired' ? ts('git_auth_expired') : ts('git_auth_failed')}
                </p>
                {status === 'error' && message && (
                  <p className="text-xs text-muted break-all leading-relaxed max-w-xs">{message}</p>
                )}
              </div>
              <button
                type="button"

                onClick={() => setAttempt((a) => a + 1)}
                className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright text-sm font-medium text-white "
              >
                <IconRefresh className="w-4 h-4" />
                {ts('git_auth_try_again')}
              </button>
            </div>
          )}

          {status === 'waiting' && flow && (
            <ol className="flex flex-col">
              <Step index={1} title={ts('git_auth_step_copy')} done={copied || opened} active={!copied && !opened}>
                <button
                  type="button"
                  onClick={copyCode}
                  aria-label={`${ts('git_auth_copy_code')}: ${flow.user_code}`}
                  className="group focus-ring cursor-pointer w-full flex items-center justify-between gap-3 ps-4 pe-3 py-3 rounded-2xl bg-base border border-outline/50 hover:border-accent-dim "
                >
                  <span dir="ltr" className="flex items-center gap-2 font-mono text-2xl font-semibold tracking-[0.2em] text-ink">
                    {codeGroups.map((group, i) => (
                      <span key={i} className="flex items-center gap-2">
                        {i > 0 && <span className="text-muted/50">–</span>}
                        {group}
                      </span>
                    ))}
                  </span>
                  <span
                    className={`shrink-0 inline-flex items-center gap-1 h-7 px-2.5 rounded-full text-2xs font-semibold  ${
                      copied ? 'bg-mint/15 text-mint' : 'bg-raised text-muted group-hover:text-ink'
                    }`}
                  >
                    {copied ? <IconCheck className="w-3 h-3" /> : <IconCopy className="w-3 h-3" />}
                    {copied ? ts('git_auth_copied') : ts('git_auth_copy_code')}
                  </span>
                </button>
              </Step>

              <Step
                index={2}
                title={ts('git_auth_step_paste', { provider: providerLabel })}
                done={opened}
                active={!opened}
              >
                <div className="flex flex-col gap-2">
                  <button
                    type="button"

                    onClick={copyAndOpen}
                    className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-btn bg-accent hover:bg-accent-bright text-sm font-medium text-white "
                  >
                    <IconExternalLink className="w-4 h-4" />
                    {ts('git_auth_copy_and_open', { provider: providerLabel })}
                  </button>
                  {verificationUrl && (
                    <button
                      type="button"
                      onClick={copyLink}
                      className="focus-ring cursor-pointer w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised "
                    >
                      {linkCopied ? <IconCheck className="w-4 h-4 text-mint shrink-0" /> : <IconCopy className="w-4 h-4 shrink-0" />}
                      <span dir="ltr" className="truncate">{verificationUrl.replace(/^https?:\/\//, '')}</span>
                      <span className="sr-only">{ts('git_auth_copy_link')}</span>
                    </button>
                  )}
                </div>
              </Step>

              <Step index={3} title={ts('git_auth_step_approve')} done={false} active={opened} last>
                <div className="flex items-center justify-between gap-3 text-xs" role="status">
                  <span className="inline-flex items-center gap-2 text-muted">
                    <IconSpinner className="w-3.5 h-3.5 animate-spin" />
                    {ts('git_auth_waiting')}
                  </span>
                  {remaining !== null && (
                    <span className={`tabular-nums ${expiringSoon ? 'text-danger' : 'text-muted/70'}`}>
                      {ts('git_auth_expires_in', { time: formatRemaining(remaining) })}
                    </span>
                  )}
                </div>
              </Step>
            </ol>
          )}
        </div>
      </div>
    </div>,
    document.body,
  )
}
