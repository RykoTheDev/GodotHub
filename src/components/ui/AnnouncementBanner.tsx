import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { IconHeart, IconX } from '../../lib/icons'
import { uiPrefs } from '../../lib/uiPrefs'

const DISMISS_KEY = 'godothub_announcement_dismissed'
const USAGE_KEY = 'godothub_announcement_usage_seconds'
const USAGE_THRESHOLD = 30 * 60
const TICK_SECONDS = 15
const SUPPORT_URL = 'https://www.patreon.com/cw/TheRyko/membership'

export function AnnouncementBanner() {
  const { t } = useTranslation('common')
  const [visible, setVisible] = useState(false)
  const dismissedRef = useRef(false)

  useEffect(() => {
    try {
      dismissedRef.current = uiPrefs.getItem(DISMISS_KEY) === '1'
    } catch {}
    let usage = 0
    try {
      usage = Number(uiPrefs.getItem(USAGE_KEY)) || 0
    } catch {}

    if (!dismissedRef.current && usage >= USAGE_THRESHOLD) setVisible(true)

    const id = window.setInterval(() => {
      if (document.hidden || dismissedRef.current) return
      usage += TICK_SECONDS
      try {
        uiPrefs.setItem(USAGE_KEY, String(usage))
      } catch {}
      if (usage >= USAGE_THRESHOLD) setVisible(true)
    }, TICK_SECONDS * 1000)

    const onShow = () => setVisible(true)
    window.addEventListener('app:show-announcement', onShow)

    return () => {
      window.clearInterval(id)
      window.removeEventListener('app:show-announcement', onShow)
    }
  }, [])

  if (!visible) return null

  const dismiss = () => {
    dismissedRef.current = true
    setVisible(false)
    try {
      uiPrefs.setItem(DISMISS_KEY, '1')
    } catch {}
  }

  return (
    <div className="pointer-events-none absolute inset-x-0 bottom-0 z-40 px-4 pb-4">
      <div
        style={{ animation: 'dash-rise 0.45s var(--ease-out-expo) backwards' }}
        className="pointer-events-auto w-full flex items-center gap-3.5 rounded-item bg-raised border border-outline/60 shadow-lg shadow-black/40 ps-5 pe-3 py-3"
      >
        <span className="grid place-items-center w-9 h-9 shrink-0 rounded-tile bg-danger/10 border border-danger/30 text-danger">
          <IconHeart className="w-4 h-4" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-ink">{t('announcement_support_title')}</p>
          <p className="text-2xs text-muted mt-0.5 leading-relaxed">
            {t('announcement_support_body')}
          </p>
        </div>
        <button
          type="button"
          onClick={() => openUrl(SUPPORT_URL)}
          className="focus-ring cursor-pointer shrink-0 inline-flex items-center gap-1.5 h-9 px-4 rounded-btn bg-danger/15 text-danger hover:bg-danger/25 text-xs font-semibold"
        >
          <IconHeart className="w-3.5 h-3.5" />
          {t('support')}
        </button>
        <button
          type="button"
          onClick={dismiss}
          aria-label={t('dismiss')}
          className="focus-ring cursor-pointer shrink-0 w-8 h-8 inline-flex items-center justify-center rounded-btn text-muted/60 hover:text-ink hover:bg-overlay"
        >
          <IconX className="w-4 h-4" />
        </button>
      </div>
    </div>
  )
}
