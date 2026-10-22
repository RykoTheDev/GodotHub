import { useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { version } from '../../../package.json'
import { ModalShell } from './ModalShell'
import type { DownloadErrorInfo } from '../../hooks/useGodotVersions'
import {
  IconAlertTriangle,
  IconCheck,
  IconCopy,
  IconExternalLink,
  IconRefresh,
} from '../../lib/icons'

interface Props {
  error: DownloadErrorInfo
  onRetry: () => void
  onClose: () => void
}

const NEW_ISSUE_URL = 'https://github.com/RykoTheDev/GodotHub/issues/new'

const SOURCE_LABELS: Record<string, string> = {
  github: 'GitHub',
  archive: 'Godot Archive',
  mise: 'mise',
}

function detectOs(): string {
  const ua = navigator.userAgent
  if (ua.includes('Windows')) return 'Windows'
  if (ua.includes('Mac OS X') || ua.includes('macOS')) return 'macOS'
  if (ua.includes('Linux')) return 'Linux'
  return ua
}

// Plain-text, locale-independent report the user can paste into an issue/chat.
function buildReport(error: DownloadErrorInfo): string {
  const sourceLabel = SOURCE_LABELS[error.source] ?? error.source
  return [
    'GodotHub - download failed',
    `Version:  ${error.tag}`,
    `Source:   ${sourceLabel}`,
    error.assetName ? `File:     ${error.assetName}` : null,
    error.url ? `URL:      ${error.url}` : null,
    `App:      ${version}`,
    `OS:       ${detectOs()}`,
    `Platform: ${navigator.platform}`,
    '',
    'Error:',
    error.message,
  ]
    .filter((line): line is string => line !== null)
    .join('\n')
}

export function DownloadErrorModal({ error, onRetry, onClose }: Props) {
  const { t: tv } = useTranslation('versions')
  const { t: tc } = useTranslation('common')
  const [copied, setCopied] = useState(false)

  const report = useMemo(() => buildReport(error), [error])
  const sourceLabel = SOURCE_LABELS[error.source] ?? error.source

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(report)
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    } catch {
      /* clipboard unavailable - the block is select-all as a fallback */
    }
  }

  const openIssue = () => {
    const title = `Download failed: ${error.tag}`
    const body = [
      '**What happened?**',
      '',
      `Installing \`${error.tag}\` failed.`,
      '',
      '**Details**',
      '',
      '```',
      report,
      '```',
    ].join('\n')
    const params = new URLSearchParams({ title, body })
    void openUrl(`${NEW_ISSUE_URL}?${params.toString()}`)
  }

  return (
    <ModalShell
      icon={<IconAlertTriangle className="w-5 h-5 text-danger" />}
      title={tv('download_failed_title')}
      description={tv('download_failed_desc', { tag: error.tag })}
      maxWidth="max-w-lg"
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={handleCopy}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
          >
            {copied ? (
              <IconCheck className="w-4 h-4 text-mint" />
            ) : (
              <IconCopy className="w-4 h-4" />
            )}
            {copied ? tc('bug_report_copied') : tv('download_failed_copy')}
          </button>
          <div className="ms-auto flex items-center gap-2.5">
            <motion.button
              data-press-feedback
              onClick={onRetry}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
            >
              <IconRefresh className="w-4 h-4" />
              {tc('retry')}
            </motion.button>
            <motion.button
              data-press-feedback
              onClick={openIssue}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item bg-danger hover:bg-danger/90 text-sm font-medium text-white transition-colors"
            >
              <IconExternalLink className="w-4 h-4" />
              {tc('bug_report_open_github')}
            </motion.button>
          </div>
        </>
      }
    >
      <div className="p-6 pt-2 flex flex-col gap-4">
        <div className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
          <span className="text-muted">{tv('source')}</span>
          <span className="text-ink">{sourceLabel}</span>
          {error.assetName ? (
            <>
              <span className="text-muted">
                {tv('download_failed_asset_label')}
              </span>
              <span className="text-ink break-all">{error.assetName}</span>
            </>
          ) : null}
        </div>

        <div className="flex flex-col gap-1.5">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-muted">
            {tv('download_failed_error_label')}
          </span>
          <div className="rounded-item bg-base border border-line p-3.5 font-mono text-[11px] text-muted whitespace-pre-wrap break-all leading-relaxed max-h-[200px] overflow-y-auto select-all">
            {error.message}
          </div>
        </div>

        <p className="text-xs text-muted/80 leading-relaxed">
          {tv('download_failed_hint')}
        </p>
      </div>
    </ModalShell>
  )
}
