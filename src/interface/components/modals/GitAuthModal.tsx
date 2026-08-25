import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { api } from '../../../lib/api'
import { ModalShell } from './ModalShell'
import type { DeviceFlowStart } from '../../../types'
import {
  IconCheck,
  IconCopy,
  IconExternalLink,
  IconGitBranch,
  IconSpinner,
  IconX,
} from '../../lib/icons'

type Provider = 'github' | 'gitlab'

interface Props {
  provider: Provider
  baseUrl?: string | null
  clientId?: string | null
  onClose: () => void
  onConnected: (username: string) => void
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
  const [flow, setFlow] = useState<DeviceFlowStart | null>(null)
  const [status, setStatus] = useState<'starting' | 'waiting' | 'success' | 'error'>(
    'starting',
  )
  const [message, setMessage] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)
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

  const providerLabel =
    provider === 'github' ? 'GitHub' : 'GitLab'

  useEffect(() => {
    stopRef.current = false
    let cancelled = false

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
          }, 1200)
          return
        }
        if (result.status === 'error') {
          setStatus('error')
          setMessage(result.message)
          return
        }
        setStatus('waiting')
        timerRef.current = setTimeout(
          () => poll(flowInfo),
          flowInfo.interval * 1000,
        )
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
  }, [provider])

  const copyCode = async () => {
    if (!flow) return
    try {
      await navigator.clipboard.writeText(flow.user_code)
      setCopied(true)
      setTimeout(() => setCopied(false), 1600)
    } catch {}
  }

  const reopenBrowser = () => {
    if (!flow) return
    const url =
      flow.verification_uri_complete || flow.verification_uri
    if (url) openUrl(url).catch(() => {})
  }

  return (
    <ModalShell
      icon={<IconGitBranch className="w-5 h-5 text-accent-bright" />}
      title={ts('git_auth_title', { provider: providerLabel })}
      description={
        provider === 'gitlab' && baseUrl
          ? baseUrl.replace(/^https?:\/\//, '')
          : providerLabel
      }
      maxWidth="max-w-md"
      onClose={onClose}
      showClose={false}
      footer={
        status === 'waiting' ? (
          <div className="w-full">
            <button
              type="button"
              onClick={onClose}
              className="focus-ring cursor-pointer w-full px-4 py-2.5 rounded-item border border-outline/50 text-muted hover:text-ink hover:bg-raised text-sm font-medium transition-colors"
            >
              {tc('cancel')}
            </button>
          </div>
        ) : undefined
      }
    >
        <div className="p-6 flex flex-col gap-4">
          {status === 'starting' && (
            <div className="flex items-center gap-2 py-6 justify-center">
              <IconSpinner className="w-4 h-4 animate-spin text-muted" />
              <span className="text-sm text-muted">{ts('git_auth_starting')}</span>
            </div>
          )}

          {status === 'error' && (
            <div className="flex flex-col items-center gap-3 py-6 text-center">
              <div className="w-11 h-11 rounded-tile bg-danger/10 border border-danger/30 flex items-center justify-center">
                <IconX className="w-5 h-5 text-danger" />
              </div>
              <p className="text-sm text-danger max-w-xs break-all leading-relaxed">
                {message}
              </p>
              <button
                type="button"
                onClick={onClose}
                className="focus-ring cursor-pointer px-4 py-2 rounded-item border border-outline/50 hover:border-accent-dim hover:bg-raised text-sm font-medium transition-colors"
              >
                {tc('close')}
              </button>
            </div>
          )}

          {status === 'success' && (
            <div className="flex flex-col items-center gap-3 py-6 text-center">
              <div className="w-11 h-11 rounded-tile bg-mint/10 border border-mint/30 flex items-center justify-center">
                <IconCheck className="w-5 h-5 text-mint" />
              </div>
              <p className="text-sm text-ink">
                {ts('git_auth_connected_as', { username: message })}
              </p>
            </div>
          )}

          {(status === 'waiting' || status === 'success') && flow && status === 'waiting' && (
            <div className="flex flex-col gap-4">
              <p className="text-sm text-muted leading-relaxed text-center">
                {ts('git_auth_instructions')}
              </p>

              <div className="flex flex-col items-center gap-2">
                <span className="text-[10px] font-semibold uppercase tracking-wider text-muted">
                  {ts('git_auth_enter_code')}
                </span>
                <div className="flex items-center gap-2">
                  <code className="font-mono text-2xl font-semibold tracking-[0.3em] text-ink bg-base border border-outline/50 rounded-btn px-5 py-3">
                    {flow.user_code}
                  </code>
                    <button
                      type="button"
                      onClick={copyCode}
                      aria-label={ts('git_auth_copy_code')}
                      className="focus-ring cursor-pointer p-2.5 rounded-btn border border-outline/50 text-muted hover:text-ink hover:border-accent-dim transition-colors shrink-0"
                      >
                      {copied ? (
                        <IconCheck className="w-4 h-4 text-mint" />
                      ) : (
                        <IconCopy className="w-4 h-4" />
                      )}
                    </button>
                </div>
              </div>

              <div className="flex items-center justify-center gap-2">
                <button
                  type="button"
                  onClick={reopenBrowser}
                  className="focus-ring cursor-pointer inline-flex items-center gap-1.5 px-4 py-2 rounded-item bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
                >
                  <IconExternalLink className="w-3.5 h-3.5" />
                  {ts('git_auth_open_browser')}
                </button>
              </div>

              <div className="flex items-center justify-center gap-2 py-1">
                <IconSpinner className="w-3.5 h-3.5 animate-spin text-muted" />
                <span className="text-xs text-muted">
                  {ts('git_auth_waiting')}
                </span>
              </div>
            </div>
          )}
        </div>
    </ModalShell>
  )
}
