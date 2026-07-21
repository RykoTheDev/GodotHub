import { useState } from 'react'
import { motion } from 'framer-motion'
import { IconX, IconCheckCircle, IconAlertTriangle, IconTerminal, IconChevronDown, IconCopy } from '../Icons'

interface GitResultDialogProps {
  type: 'success' | 'error'
  title: string
  instructions: string
  rawError?: string
  onClose: () => void
  onOpenTerminal?: () => void
}

export function parseGitError(message: string): {
  title: string
  instructions: string
  rawError?: string
} {
  const trimmed = message.trim()

  const rawMarker = '\nRaw error:\n'
  const rawIdx = trimmed.indexOf(rawMarker)

  if (rawIdx !== -1) {
    const beforeRaw = trimmed.slice(0, rawIdx).trim()
    const rawError = trimmed.slice(rawIdx + rawMarker.length).trim()

    const firstNewline = beforeRaw.indexOf('\n')
    if (firstNewline !== -1) {
      return {
        title: beforeRaw.slice(0, firstNewline).trim(),
        instructions: beforeRaw.slice(firstNewline).trim(),
        rawError,
      }
    }
    return { title: beforeRaw, instructions: '', rawError }
  }
  const firstNewline = trimmed.indexOf('\n')
  if (firstNewline !== -1) {
    return {
      title: trimmed.slice(0, firstNewline).trim(),
      instructions: trimmed.slice(firstNewline).trim(),
    }
  }
  return { title: trimmed, instructions: '' }
}

export function GitResultDialog({
  type,
  title,
  instructions,
  rawError,
  onClose,
  onOpenTerminal,
}: GitResultDialogProps) {
  const [showRaw, setShowRaw] = useState(false)

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 1, y: 8, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-6 w-full max-w-md flex flex-col gap-4 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Icon + Title */}
        <div className="flex items-start gap-3.5">
          <div
            className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
              type === 'success'
                ? 'bg-mint/10'
                : 'bg-danger/10'
            }`}
          >
            {type === 'success' ? (
              <IconCheckCircle className="w-5 h-5 text-mint" />
            ) : (
              <IconAlertTriangle className="w-5 h-5 text-danger" />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-display font-semibold text-ink break-words">
              {title}
            </h3>
            {instructions && (
              <p className="text-sm text-muted mt-1.5 leading-relaxed whitespace-pre-wrap">
                {instructions}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
          >
            <IconX className="w-4 h-4" />
          </button>
        </div>

        {/* Raw error (collapsible) */}
        {rawError && (
          <div className="bg-base rounded-xl border border-line overflow-hidden">
            <button
              onClick={() => setShowRaw((v) => !v)}
              className="flex items-center gap-2 w-full px-3.5 py-2.5 text-[11px] font-medium text-muted hover:text-ink transition-colors cursor-pointer"
            >
              <IconChevronDown
                className={`w-3 h-3 transition-transform duration-150 ${showRaw ? 'rotate-0' : '-rotate-90'}`}
              />
              <span>Technical details</span>
              <div className="flex-1" />
              {showRaw && (
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    navigator.clipboard.writeText(rawError)
                  }}
                  className="focus-ring p-1 rounded text-muted hover:text-ink hover:bg-raised transition-colors cursor-pointer"
                  title="Copy to clipboard"
                >
                  <IconCopy className="w-3 h-3" />
                </button>
              )}
            </button>
            {showRaw && (
              <pre className="px-3.5 pb-3 text-[10px] font-mono text-muted leading-relaxed whitespace-pre-wrap max-h-40 overflow-y-auto border-t border-line pt-2.5 mx-0">
                {rawError}
              </pre>
            )}
          </div>
        )}

        {/* Actions */}
        <div className="flex items-center justify-end gap-2.5 mt-1">
          {type === 'error' && onOpenTerminal && (
            <button
              onClick={() => {
                onOpenTerminal()
                onClose()
              }}
              className="focus-ring cursor-pointer flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs text-muted hover:text-ink hover:bg-raised border border-line transition-colors"
            >
              <IconTerminal className="w-3.5 h-3.5" />
              Open Terminal
            </button>
          )}
          <button
            onClick={onClose}
            className={`focus-ring cursor-pointer px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              type === 'success'
                ? 'bg-accent hover:bg-accent-bright text-white'
                : 'bg-accent hover:bg-accent-bright text-white'
            }`}
          >
            {type === 'success' ? 'Done' : 'Got it'}
          </button>
        </div>
      </motion.div>
    </motion.div>
  )
}
