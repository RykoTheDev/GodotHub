import { useEffect, useState } from 'react'
import {
  getCurrentWindow,
  type Window as TauriWindow,
} from '@tauri-apps/api/window'
import { openUrl } from '@tauri-apps/plugin-opener'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { isMac } from '../../lib/platform'
import { useSettings } from '../../hooks/useSettings'
import { RunningProjectsChip } from '../titlebar/RunningProjectsChip'
import { TaskTray } from '../titlebar/TaskTray'
import { LanguageMenu } from '../titlebar/LanguageMenu'
import {
  IconHeart,
  IconStar,
  IconBug,
  IconMinus,
  IconX,
  IconWindowMaximize,
  IconWindowRestore,
} from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'

export function Titlebar({ minimal = false }: { minimal?: boolean }) {
  const { t } = useTranslation('common')
  const { settings } = useSettings()
  const [appWindow, setAppWindow] = useState<TauriWindow | null>(null)
  const [isMaximized, setIsMaximized] = useState(false)

  const useOsDec = settings.use_os_decorations
  const showWindowControls = !isMac && !useOsDec

  useEffect(() => {
    let unlisten: (() => void) | undefined
    try {
      const w = getCurrentWindow()
      setAppWindow(w)
      w.isMaximized()
        .then(setIsMaximized)
        .catch(() => {})
      w.onResized(() => {
        w.isMaximized()
          .then(setIsMaximized)
          .catch(() => {})
      })
        .then((f) => {
          unlisten = f
        })
        .catch(() => {})
    } catch {}
    return () => unlisten?.()
  }, [])

  useEffect(() => {
    if (isMac) return
    getCurrentWindow()
      .setDecorations(useOsDec)
      .catch((e) => console.error('Failed to set window decorations:', e))
  }, [useOsDec])

  const safe = (fn: (w: TauriWindow) => void) => {
    if (appWindow) {
      try {
        fn(appWindow)
      } catch {}
    }
  }

  const handleDoubleClick = (e: React.MouseEvent) => {
    if (!showWindowControls) return
    if (e.target !== e.currentTarget) return
    safe((w) => w.toggleMaximize())
  }

  const noDrag = (e: React.MouseEvent) => e.stopPropagation()

  const hasAnyTitlebarButton =
    settings.show_support_button ||
    settings.show_star_button ||
    settings.show_bug_button ||
    settings.show_language_button ||
    settings.show_tray_button

  if (useOsDec && !hasAnyTitlebarButton) return null

  const windowDot =
    'w-4.5 h-4.5 rounded-xl transition-[filter] duration-150 group-hover/win:brightness-125'

  return (
    <header
      data-tauri-drag-region
      onDoubleClick={handleDoubleClick}
      className={`shrink-0 flex items-center gap-3 select-none ${
        showWindowControls ? 'h-8' : 'h-11'
      } ${
        settings.card_layout ? 'bg-raised/80' : 'bg-raised border-b border-line'
      } ${isMac ? 'pl-20' : 'pl-4'} ${showWindowControls ? '' : 'pr-4'}`}
    >
      {!minimal && <RunningProjectsChip />}

      <div className="ml-auto flex items-center gap-1.5 self-stretch ">
        {!minimal && settings.show_support_button && (
            <Tooltip content={t('support_dev')}>
            <motion.button
              type="button"
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.94 }}
              transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              onMouseDown={noDrag}
              onClick={() =>
                openUrl('https://www.patreon.com/cw/TheRyko/membership')
              }
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-6.5 px-3 rounded-item bg-danger/10 text-danger hover:bg-danger/20 transition-colors text-xs font-semibold"
            >
              <IconHeart className="w-3.5 h-3.5" />
              {t('support')}
            </motion.button>
            </Tooltip>
        )}

        {!minimal && settings.show_star_button && (
            <Tooltip content={t('star_on_github')}>
            <motion.button
              type="button"
              whileHover={{ scale: 1.08 }}
              whileTap={{ scale: 0.9 }}
              transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              onMouseDown={noDrag}
              onClick={() => openUrl('https://github.com/RykoTheDev/GodotHub')}
              className="focus-ring cursor-pointer w-8 h-8 flex items-center justify-center rounded-item text-muted hover:text-amber hover:bg-amber/10 transition-colors"
            >
              <IconStar className="w-3.5 h-3.5" />
            </motion.button>
            </Tooltip>
        )}

        {!minimal && settings.show_bug_button && (
            <Tooltip content={t('report_a_bug')}>
            <motion.button
              type="button"
              whileHover={{ scale: 1.08 }}
              whileTap={{ scale: 0.9 }}
              transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              onMouseDown={noDrag}
              onClick={() =>
                window.dispatchEvent(new Event('app:report-bug'))
              }
              className="focus-ring cursor-pointer w-6 h-6 flex items-center justify-center rounded-item text-muted hover:text-danger hover:bg-danger/10 transition-colors"
            >
              <IconBug className="w-3.5 h-3.5" />
            </motion.button>
            </Tooltip>
        )}

        {(settings.show_language_button || (!minimal && settings.show_tray_button)) && (
          <>
            <div className="w-px h-5 bg-line/40 mx-1 shrink-0" />
            {settings.show_language_button && <LanguageMenu />}
            {!minimal && settings.show_tray_button && <TaskTray />}
          </>
        )}

        {showWindowControls && (
          <>
            {(settings.show_language_button || (!minimal && settings.show_tray_button)) && (
              <div className="w-px h-5 bg-line/40 mx-1 shrink-0" />
            )}
            {settings.colored_titlebar_buttons ? (
              <div className="flex self-stretch">
                <Tooltip content={t('minimize')}>
                <button
                  type="button"
                  onMouseDown={noDrag}
                  onClick={() => safe((w) => w.minimize())}
                  className="focus-ring cursor-pointer group/win w-9 h-full flex items-center justify-center"
                >
                  <motion.span
                    whileHover={{ scale: 1.12 }}
                    whileTap={{ scale: 0.9 }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                    className={`${windowDot} -mr-3 bg-mint`}
                  />
                </button>
                </Tooltip>

                <Tooltip content={isMaximized ? t('restore') : t('maximize')}>
                <button
                  type="button"
                  onMouseDown={noDrag}
                  onClick={() => safe((w) => w.toggleMaximize())}
                  className="focus-ring cursor-pointer group/win w-9 h-full flex items-center justify-center"
                >
                  <motion.span
                    whileHover={{ scale: 1.12 }}
                    whileTap={{ scale: 0.9 }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                    className={`${windowDot} bg-amber`}
                  />
                </button>
                </Tooltip>

                <Tooltip content={t('close')}>
                <button
                  type="button"
                  onMouseDown={noDrag}
                  onClick={() => safe((w) => w.close())}
                  className="focus-ring cursor-pointer group/win w-9 h-full flex items-center justify-center"
                >
                  <motion.span
                    whileHover={{ scale: 1.12 }}
                    whileTap={{ scale: 0.9 }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                    className={`${windowDot} mr-3 bg-danger`}
                  />
                </button>
                </Tooltip>
              </div>
            ) : (
              <div className="flex self-stretch">
                <Tooltip content={t('minimize')}>
                <button
                  type="button"
                  aria-label={t('minimize')}
                  onMouseDown={noDrag}
                  onClick={() => safe((w) => w.minimize())}
                  className="focus-ring cursor-pointer group/win w-11 h-full flex items-center justify-center text-ink/55 hover:bg-ink/10 hover:text-ink transition-colors"
                >
                  <IconMinus className="w-2.5 h-2.5" />
                </button>
                </Tooltip>

                <Tooltip content={isMaximized ? t('restore') : t('maximize')}>
                <button
                  type="button"
                  aria-label={isMaximized ? t('restore') : t('maximize')}
                  onMouseDown={noDrag}
                  onClick={() => safe((w) => w.toggleMaximize())}
                  className="focus-ring cursor-pointer group/win w-11 h-full flex items-center justify-center text-ink/55 hover:bg-ink/10 hover:text-ink transition-colors"
                >
                  {isMaximized ? (
                    <IconWindowRestore className="w-2.5 h-2.5" />
                  ) : (
                    <IconWindowMaximize className="w-2.5 h-2.5" />
                  )}
                </button>
                </Tooltip>

                <Tooltip content={t('close')}>
                <button
                  type="button"
                  aria-label={t('close')}
                  onMouseDown={noDrag}
                  onClick={() => safe((w) => w.close())}
                  className="focus-ring cursor-pointer group/win w-11 h-full flex items-center justify-center text-ink/55 hover:bg-danger hover:text-white transition-colors"
                >
                  <IconX className="w-3 h-3" />
                </button>
                </Tooltip>
              </div>
            )}
          </>
        )}
      </div>
    </header>
  )
}
