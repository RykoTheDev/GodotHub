import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { AnimatePresence, motion } from 'framer-motion'
import { IconCheck } from '../../lib/icons'

interface Props {
  value: string
  onChange: (key: string) => void
  onReset?: () => void
}

export function KeyRecorder({ value, onChange, onReset }: Props) {
  const { t } = useTranslation('settings')
  const [listening, setListening] = useState(false)
  const [confirmMsg, setConfirmMsg] = useState<string | null>(null)
  const confirmTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange
  const mod = navigator.platform.includes('Mac') ? '⌘' : 'Ctrl+'

  useEffect(() => {
    if (!listening) return

    const handler = (e: KeyboardEvent) => {
      e.preventDefault()
      e.stopPropagation()

      if (e.key === 'Escape') {
        setListening(false)
        return
      }

      if (e.key.length !== 1) return

      const captured = e.key === ' ' ? ' ' : e.key.toLowerCase()
      onChangeRef.current(captured)
      setListening(false)

      const label = captured === ' ' ? t('key_space') : captured.toUpperCase()
      setConfirmMsg(`✓ ${mod}${label}`)
      if (confirmTimer.current) clearTimeout(confirmTimer.current)
      confirmTimer.current = setTimeout(() => setConfirmMsg(null), 1500)
    }

    window.addEventListener('keydown', handler, true)
    return () => window.removeEventListener('keydown', handler, true)
  }, [listening, t, mod])

  useEffect(() => {
    return () => {
      if (confirmTimer.current) clearTimeout(confirmTimer.current)
    }
  }, [])

  const displayKey =
    value === ' ' ? t('key_space') : value ? value.toUpperCase() : t('none')

  return (
    <div className="flex flex-col gap-2.5">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-muted block">
          {t('palette_shortcut')}
        </span>
        {value !== 'p' && onReset && (
          <button
            type="button"
            onClick={() => {
              onReset()
              setConfirmMsg(`✓ ${mod}P`)
              if (confirmTimer.current) clearTimeout(confirmTimer.current)
              confirmTimer.current = setTimeout(() => setConfirmMsg(null), 1500)
            }}
            className="focus-ring cursor-pointer text-[10px] font-medium text-muted/60 hover:text-accent transition-colors"
          >
            {t('reset_to_default')}
          </button>
        )}
      </div>
      <p className="text-[11px] text-muted mt-0.5 leading-relaxed">
        {t('keybind_instruction')} {t('press')}{' '}
        <kbd className="font-mono text-[10px] px-1 py-0.5 rounded bg-base border border-line">
          Esc
        </kbd>{' '}
        {t('to_cancel')}.
      </p>
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => setListening((l) => !l)}
          className={`focus-ring cursor-pointer relative flex items-center justify-center gap-2 px-5 py-3 rounded-item border text-sm font-mono font-semibold transition-all ${
            listening
              ? 'border-accent bg-accent/10 text-accent-bright'
              : 'border-outline/50 bg-overlay text-ink hover:border-accent-dim hover:bg-raised'
          }`}
        >
          {listening ? (
            <>
              <span className="inline-block w-2 h-2 rounded-full bg-accent animate-pulse" />
              <span>{t('press_key')}</span>
            </>
          ) : (
            <>
              <kbd className="text-xs px-2 py-0.5 rounded bg-base border border-line/60">
                {mod}
                {displayKey}
              </kbd>
              <span className="text-xs font-normal text-muted">
                {t('click_to_rebind')}
              </span>
            </>
          )}
        </button>

        <AnimatePresence mode="wait">
          {confirmMsg && (
            <motion.span
              key={confirmMsg}
              initial={{ opacity: 0, x: -4 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 4 }}
              transition={{ duration: 0.2, ease: 'easeOut' }}
              className="flex items-center gap-1 text-xs text-accent font-medium shrink-0"
            >
              <IconCheck className="w-3 h-3" />
              {confirmMsg}
            </motion.span>
          )}
        </AnimatePresence>
      </div>
    </div>
  )
}
