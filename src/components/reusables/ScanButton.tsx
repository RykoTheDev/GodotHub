import { motion, AnimatePresence } from 'framer-motion'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { IconRefresh } from '../../lib/icons'
import { isReducedMotion } from '../../lib/appearance'
import { ConfirmDialog } from '../modals/ConfirmDialog'
import { Tooltip } from './Tooltip'

type Phase = 'idle' | 'scanning' | 'done' | 'error'
const MIN_SCAN_TIME = 800

function Spinner({ reduced, size = 20 }: { reduced: boolean; size?: number }) {
  return (
    <motion.svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      className="block"
      animate={reduced ? undefined : { rotate: 360 }}
      transition={
        reduced
          ? { duration: 0 }
          : { repeat: Infinity, duration: 0.8, ease: 'linear' }
      }
    >
      <path
        d="M21 12a9 9 0 1 1-6.219-8.56"
        stroke="currentColor"
        strokeWidth={2}
        strokeLinecap="round"
      />
    </motion.svg>
  )
}

function DrawGlyph({
  paths,
  reduced,
  size = 20,
  strokeWidth = 2,
}: {
  paths: string[]
  reduced: boolean
  size?: number
  strokeWidth?: number
}) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className="block">
      {paths.map((p, i) => (
        <motion.path
          key={p}
          d={p}
          initial={{ pathLength: 0, opacity: 0 }}
          animate={{ pathLength: 1, opacity: 1 }}
          transition={
            reduced
              ? { duration: 0 }
              : {
                  duration: 0.25,
                  delay: i * 0.08,
                  ease: [0.4, 0, 0.2, 1],
                }
          }
          stroke="currentColor"
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      ))}
    </svg>
  )
}

interface ScanButtonProps {
  onOpenSettings?: () => void
  scanDirs: string[]
  scan: () => Promise<unknown>
  onComplete?: () => void
  onReadd?: (paths: string[]) => Promise<void> | void
  onScanStart?: () => void
  onScanEnd?: () => void
  disabled?: boolean
  requiresDirs?: boolean
}

export function ScanButton({
  onOpenSettings,
  scanDirs,
  scan,
  onComplete,
  onReadd,
  onScanStart,
  onScanEnd,
  disabled = false,
  requiresDirs = true,
}: ScanButtonProps) {
  const { t } = useTranslation('common')
  const [phase, setPhase] = useState<Phase>('idle')
  const phaseTimerRef = useRef<number | null>(null)
  const [foundDismissed, setFoundDismissed] = useState<string[] | null>(null)
  const reduced = isReducedMotion()

  useEffect(
    () => () => {
      if (phaseTimerRef.current != null) {
        window.clearTimeout(phaseTimerRef.current)
      }
    },
    [],
  )

  useEffect(() => {
    if (phase !== 'done' && phase !== 'error') return
    const timer = window.setTimeout(
      () => setPhase('idle'),
      reduced ? 600 : 1500,
    )
    return () => window.clearTimeout(timer)
  }, [phase, reduced])

  const handleScan = async () => {
    if (phase !== 'idle') return
    if (scanDirs.length === 0 && requiresDirs) {
      onOpenSettings?.()
      return
    }
    setPhase('scanning')
    onScanStart?.()
    const start = performance.now()
    const hold = (next: Phase) => {
      const remaining = MIN_SCAN_TIME - (performance.now() - start)
      const go = () => setPhase(next)
      if (!reduced && remaining > 0) {
        phaseTimerRef.current = window.setTimeout(go, remaining)
      } else {
        go()
      }
    }
    try {
      const result = await scan()
      const dismissed =
        typeof result === 'object' && result !== null
          ? (result as { found_dismissed?: string[] }).found_dismissed
          : undefined
      if (dismissed?.length && onReadd) {
        setFoundDismissed(dismissed)
      }
      onComplete?.()
      hold('done')
    } catch (e) {
      console.error('[new-ui] scan failed:', e)
      hold('error')
    } finally {
      onScanEnd?.()
    }
  }

  const handleReaddDismissed = async () => {
    if (!foundDismissed || !onReadd) return
    const paths = foundDismissed
    setFoundDismissed(null)
    try {
      await onReadd(paths)
    } catch (e) {
      console.error('[new-ui] re-adding dismissed projects failed:', e)
    }
  }

  const glyph = {
    idle: <IconRefresh className="w-5 h-5" />,
    scanning: <Spinner reduced={reduced} />,
    done: <DrawGlyph reduced={reduced} paths={['M20 6 9 17l-5-5']} />,
    error: <DrawGlyph reduced={reduced} paths={['M18 6 6 18', 'M6 6l12 12']} />,
  } as const

  return (
    <>
      <Tooltip
        content={
          phase === 'idle'
            ? t('scan_for_projects')
            : phase === 'done'
              ? t('scan_complete')
              : phase === 'error'
                ? t('scan_failed')
                : t('scanning')
        }
        side="bottom"
      >
      <motion.button
        type="button"
        onClick={handleScan}
        disabled={phase !== 'idle' || disabled}
        aria-label={
          phase === 'idle'
            ? t('scan_for_projects')
            : phase === 'done'
              ? t('scan_complete')
              : phase === 'error'
                ? t('scan_failed')
                : t('scanning')
        }
        className={[
          'relative inline-flex items-center justify-center shadow-md shadow-black/10 border border-outline/50 w-10 h-10 shrink-0 grow-0 overflow-hidden rounded-item',
          'select-none focus-ring transition-colors duration-300',
          phase === 'idle'
            ? 'bg-overlay text-muted hover:text-ink hover:bg-raised cursor-pointer'
            : phase === 'done'
              ? 'bg-mint text-overlay'
              : phase === 'error'
                ? 'bg-danger text-overlay'
                : 'bg-accent text-overlay',
        ].join(' ')}
      >
        <span role="status" aria-live="polite" className="sr-only">
          {phase === 'idle'
            ? t('scan_for_projects')
            : phase === 'done'
              ? t('scan_complete')
              : phase === 'error'
                ? t('scan_failed')
                : t('scanning')}
        </span>
        <AnimatePresence mode="popLayout">
          <motion.span
            key={phase}
            className="inline-flex"
            initial={{ opacity: 0, scale: 0.6, filter: 'blur(4px)' }}
            animate={{ opacity: 1, scale: 1, filter: 'blur(0px)' }}
            exit={{
              opacity: 0,
              scale: 0.6,
              filter: 'blur(4px)',
              transition: {
                duration: reduced ? 0 : 0.2,
                ease: [0.4, 0, 1, 1],
              },
            }}
            transition={{
              duration: reduced ? 0 : 0.3,
              ease: [0.34, 1.56, 0.64, 1],
            }}
          >
            {glyph[phase]}
          </motion.span>
        </AnimatePresence>
      </motion.button>
      </Tooltip>

      <AnimatePresence>
        {foundDismissed && (
          <ConfirmDialog
            title={t('found_dismissed_title', { count: foundDismissed.length })}
            description={
              <div className="flex flex-col gap-2">
                <p>
                  {t('found_dismissed_desc', { count: foundDismissed.length })}
                </p>
                <ul className="flex flex-wrap gap-1.5 mt-1">
                  {foundDismissed.map((p) => (
                    <li
                      key={p}
                      className="text-xs px-2 py-1 rounded-md bg-raised border border-line/50 text-muted truncate max-w-48"
                    >
                      {p.split(/[\\/]/).pop()}
                    </li>
                  ))}
                </ul>
              </div>
            }
            confirmLabel={t('readd_all')}
            cancelLabel={t('skip_all')}
            onConfirm={handleReaddDismissed}
            onCancel={() => setFoundDismissed(null)}
          />
        )}
      </AnimatePresence>
    </>
  )
}
