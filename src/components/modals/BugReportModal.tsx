import { useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { version } from '../../../package.json'
import { ModalShell } from './ModalShell'
import {
  IconBug,
  IconCheck,
  IconCopy,
  IconDownload,
  IconExternalLink,
  IconRefresh,
} from '../../lib/icons'

interface Props {
  onClose: () => void
}

const BUG_REPORT_URL = 'https://github.com/RykoTheDev/GodotHub/issues/new'

interface CapturedError {
  time: string
  source: 'console.error' | 'window.onerror' | 'unhandledrejection'
  message: string
}

const MAX_CAPTURED = 20
let capturedErrors: CapturedError[] = []
let captureInstalled = false
let origConsoleError: typeof console.error | null = null
let origWindowOnError: typeof window.onerror | null = null
let unhandledRejectionHandler: ((e: PromiseRejectionEvent) => void) | null = null

function installErrorCapture() {
  if (captureInstalled) return
  captureInstalled = true

  const push = (source: CapturedError['source'], message: string) => {
    capturedErrors = [
      { time: new Date().toLocaleTimeString(), source, message },
      ...capturedErrors,
    ].slice(0, MAX_CAPTURED)
  }

  origConsoleError = console.error
  console.error = (...args: unknown[]) => {
    push('console.error', args.map((a) => String(a)).join(' '))
    origConsoleError!.apply(console, args)
  }

  origWindowOnError = window.onerror
  window.onerror = (_event, _source, _lineno, _colno, error) => {
    push('window.onerror', error?.message ?? String(_event))
    return origWindowOnError
      ? origWindowOnError.call(window, _event, _source, _lineno, _colno, error)
      : false
  }

  unhandledRejectionHandler = (e: PromiseRejectionEvent) => {
    push('unhandledrejection', e.reason?.message ?? String(e.reason))
  }
  window.addEventListener('unhandledrejection', unhandledRejectionHandler)
}

installErrorCapture()

async function getGPUInfo(t: (key: string) => string): Promise<string> {
  try {
    const canvas = document.createElement('canvas')
    const gl =
      canvas.getContext('webgl') || canvas.getContext('experimental-webgl')
    if (!gl) return t('gpu_webgl_unavailable')
    const debugInfo = (
      gl as WebGLRenderingContext
    ).getExtension('WEBGL_debug_renderer_info')
    if (!debugInfo) return t('gpu_info_unavailable')
    const renderer = (gl as WebGLRenderingContext).getParameter(
      debugInfo.UNMASKED_RENDERER_WEBGL,
    )
    const vendor = (gl as WebGLRenderingContext).getParameter(
      debugInfo.UNMASKED_VENDOR_WEBGL,
    )
    canvas.remove()
    return `${vendor}, ${renderer}`
  } catch {
    return t('gpu_info_unavailable')
  }
}

async function buildSystemReport(t: (key: string) => string): Promise<{ specs: string; errors: string }> {
  const gpu = await getGPUInfo(t)

  const specs = [
    `## ${t('bug_report_system')}`,
    '',
    `- **${t('bug_report_version')}**: ${version}`,
    `- **${t('bug_report_date')}**: ${new Date().toISOString().slice(0, 10)}`,
    `- **${t('bug_report_os')}**: ${
      navigator.userAgent.includes('Windows')
        ? 'Windows'
        : navigator.userAgent.includes('Mac OS X') ||
            navigator.userAgent.includes('macOS')
          ? 'macOS'
          : navigator.userAgent.includes('Linux')
            ? 'Linux'
            : navigator.userAgent
    }`,
    `- **${t('bug_report_platform')}**: ${navigator.platform}`,
    `- **${t('bug_report_language')}**: ${navigator.language}`,
    `- **${t('bug_report_cpu_cores')}**: ${navigator.hardwareConcurrency ?? t('unknown')}`,
    `- **${t('bug_report_ram')}**: ${
      (
        navigator as Navigator & { deviceMemory?: number }
      ).deviceMemory
        ? `${(navigator as Navigator & { deviceMemory?: number }).deviceMemory} GB`
        : t('unknown')
    }`,
    `- **${t('bug_report_screen')}**: ${screen.width}x${screen.height} @${screen.colorDepth}bit`,
    `- **${t('bug_report_gpu')}**: ${gpu}`,
    `- **${t('bug_report_user_agent')}**: ${navigator.userAgent}`,
  ].join('\n')

  const errorLines: string[] = [`## ${t('bug_report_recent_errors')}`]
  if (capturedErrors.length > 0) {
    for (const err of capturedErrors) {
      errorLines.push(`- \`[${err.time}]\` (${err.source}) ${err.message}`)
    }
  } else {
    errorLines.push(`- _(${t('bug_report_none_captured')})_`)
  }

  return { specs, errors: errorLines.join('\n') }
}

function assembleReport(
  description: string,
  specs: string,
  errors: string,
  t: (key: string) => string,
): string {
  const desc = description.trim()
  return [
    `## ${t('bug_report_description')}`,
    '',
    desc || `_ ${t('bug_report_no_description')} _`,
    '',
    specs,
    '',
    errors,
  ].join('\n')
}

function downloadReport(report: string) {
  const blob = new Blob([report], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `godothub-bug-report-${new Date().toISOString().slice(0, 10)}.txt`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

export function BugReportModal({ onClose }: Props) {
  const { t } = useTranslation('common')
  const [description, setDescription] = useState('')
  const [system, setSystem] = useState<{
    specs: string
    errors: string
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    buildSystemReport(t).then((r) => {
      if (!cancelled) {
        setSystem(r)
        setLoading(false)
      }
    })
    return () => {
      cancelled = true
    }
  }, [t])

  const report = useMemo(
    () => (system ? assembleReport(description, system.specs, system.errors, t) : null),
    [description, system, t],
  )

  const handleCopy = async () => {
    if (!report) return
    try {
      await navigator.clipboard.writeText(report)
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    } catch {
    }
  }

  const openGithubIssue = () => {
    if (!system) return
    const firstLine = description.trim().split('\n')[0] || ''
    const title = (firstLine || t('bug_report_title')).slice(0, 72)
    const params = new URLSearchParams({
      template: 'bug_report.yaml',
      title,
      description: description.trim(),
      environment: system.specs,
      'actual-behavior': system.errors,
    })
    const url = `${BUG_REPORT_URL}?${params.toString()}`
    openUrl(url)
    onClose()
  }

  return (
    <ModalShell
      icon={<IconBug className="w-5 h-5 text-danger" />}
      title={t('bug_report_title')}
      description={t('bug_report_desc', { version })}
      maxWidth="max-w-lg"
      onClose={onClose}
      footer={
        <>
          <button
            type="button"
            onClick={handleCopy}
            disabled={!report}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {copied ? (
              <IconCheck className="w-4 h-4 text-mint" />
            ) : (
              <IconCopy className="w-4 h-4" />
            )}
            {copied ? t('bug_report_copied') : t('bug_report_copy_log')}
          </button>
          <div className="ml-auto flex items-center gap-2.5">
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => report && downloadReport(report)}
              disabled={!report}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <IconDownload className="w-4 h-4" />
              {t('bug_report_download_log')}
            </motion.button>
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={openGithubIssue}
              disabled={!report}
              className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item bg-danger hover:bg-danger/90 text-sm font-medium text-white transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <IconExternalLink className="w-4 h-4" />
              {t('bug_report_open_github')}
            </motion.button>
          </div>
        </>
      }
    >
      <div className="p-6 flex flex-col gap-4">
        <div className="flex flex-col gap-1.5">
          <label
            htmlFor="bug-report-description"
            className="text-[11px] font-semibold uppercase tracking-wider text-muted"
          >
            {t('bug_report_describe_label')}
          </label>
          <textarea
            id="bug-report-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t('bug_report_describe_placeholder')}
            rows={3}
            maxLength={2000}
            className="focus-ring w-full resize-none bg-base border border-outline/50 rounded-btn px-3.5 py-2.5 text-sm text-ink placeholder:text-muted/50 focus:border-accent-dim transition-colors"
          />
        </div>

        <div className="flex flex-col gap-1.5">
          <div className="flex items-center justify-between gap-3">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-muted">
              {t('bug_report_diagnostics_label')}
            </span>
            <span className="text-[10px] text-muted/50 shrink-0">
              {t('bug_report_diagnostics_hint')}
            </span>
          </div>
          {loading ? (
            <div className="flex items-center justify-center py-10 rounded-item bg-base border border-line">
              <IconRefresh className="w-5 h-5 animate-spin text-muted" />
            </div>
          ) : (
            <div className="rounded-item bg-base border border-line p-3.5 font-mono text-[11px] text-muted whitespace-pre-wrap break-all leading-relaxed max-h-[200px] overflow-y-auto select-all">
              {report}
            </div>
          )}
        </div>
      </div>
    </ModalShell>
  )
}
