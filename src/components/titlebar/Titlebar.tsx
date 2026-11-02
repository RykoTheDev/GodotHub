import { useEffect, useState } from 'react'
import {
  getCurrentWindow,
  type Window as TauriWindow,
} from '@tauri-apps/api/window'
import { openUrl } from '@tauri-apps/plugin-opener'
import { useTranslation } from 'react-i18next'
import { isMac } from '../../lib/platform'
import { useSettings } from '../../hooks/useSettings'
import { useChangelogBadge } from '../../hooks/useChangelogBadge'
import { RunningProjectsChip } from '../titlebar/RunningProjectsChip'
import { TaskTray } from '../titlebar/TaskTray'
import { LanguageMenu } from '../titlebar/LanguageMenu'
import {
  IconBookOpen,
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
  const { t: tn } = useTranslation('nav')
  const { settings } = useSettings()
  const { hasNewEntry: hasNewChangelogEntry } = useChangelogBadge()
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
    settings.show_tray_button ||
    (!minimal && hasNewChangelogEntry)

  if (useOsDec && !hasAnyTitlebarButton) return null

  const windowDot =
    'w-4.5 h-4.5 rounded-xl group-hover/win:brightness-125'

  return (
    <header
      data-tauri-drag-region
      onDoubleClick={handleDoubleClick}
      className={`shrink-0 flex items-center gap-3 select-none ${
        showWindowControls ? 'h-8' : 'h-11'
      } ${
        settings.card_layout ? 'bg-raised/80' : 'bg-raised border-b border-line'
      } ${isMac ? 'ps-20' : 'ps-4'} ${showWindowControls ? '' : 'pe-4'}`}
    >
      {!minimal && <RunningProjectsChip />}

      <div className="ms-auto flex items-center gap-1.5 self-stretch ">
        {!minimal && (
          <Tooltip content={tn('changelog')}>
            <button
              type="button"

              onMouseDown={noDrag}
              onClick={() => window.dispatchEvent(new CustomEvent('app:set-tab', { detail: 'changelog' }))}
              aria-label={hasNewChangelogEntry ? `${tn('changelog')} (${t('new_badge')})` : tn('changelog')}
              className={`focus-ring cursor-pointer inline-flex items-center justify-center rounded-item  ${
                hasNewChangelogEntry
                  ? ' gap-1.5 h-6.5 px-3 bg-accent/10 border border-accent/30 text-accent-bright hover:bg-accent/20 text-xs font-semibold'
                  : 'w-8 h-8 text-muted hover:text-ink hover:bg-ink/10'
              }`}
            >
              {hasNewChangelogEntry && (
                <span className="relative flex w-2 h-2" aria-hidden="true">
                  <span className="relative inline-flex rounded-full w-2 h-2 bg-accent-bright" />
                </span>
              )}
              <IconBookOpen className="w-3.5 h-3.5" />
              {hasNewChangelogEntry && tn('changelog')}
            </button>
          </Tooltip>
        )}

        {!minimal && settings.show_support_button && (
            <Tooltip content={t('support_dev')}>
            <button
              type="button"



              onMouseDown={noDrag}
              onClick={() =>
                openUrl('https://www.patreon.com/cw/TheRyko/membership')
              }
              className="focus-ring cursor-pointer inline-flex items-center gap-1.5 h-6.5 px-3 rounded-item bg-danger/10 text-danger hover:bg-danger/20 text-xs font-semibold"
            >
              <IconHeart className="w-3.5 h-3.5" />
              {t('support')}
            </button>
            </Tooltip>
        )}

        {!minimal && settings.show_star_button && (
            <Tooltip content={t('star_on_github')}>
            <button
              type="button"



              onMouseDown={noDrag}
              onClick={() => openUrl('https://github.com/RykoTheDev/GodotHub')}
              aria-label={t('star_on_github')}
              className="focus-ring cursor-pointer w-8 h-8 flex items-center justify-center rounded-item text-muted hover:text-amber hover:bg-amber/10 "
            >
              <IconStar className="w-3.5 h-3.5" />
            </button>
            </Tooltip>
        )}

        {!minimal && settings.show_bug_button && (
            <Tooltip content={t('report_a_bug')}>
            <button
              type="button"



              onMouseDown={noDrag}
              onClick={() =>
                window.dispatchEvent(new Event('app:report-bug'))
              }
              aria-label={t('report_a_bug')}
              className="focus-ring cursor-pointer w-6 h-6 flex items-center justify-center rounded-item text-muted hover:text-danger hover:bg-danger/10 "
            >
              <IconBug className="w-3.5 h-3.5" />
            </button>
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
                  <span



                    className={`${windowDot} -me-3 bg-mint`}
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
                  <span



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
                  <span



                    className={`${windowDot} me-3 bg-danger`}
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
                  className="focus-ring cursor-pointer group/win w-11 h-full flex items-center justify-center text-ink/55 hover:bg-ink/10 hover:text-ink "
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
                  className="focus-ring cursor-pointer group/win w-11 h-full flex items-center justify-center text-ink/55 hover:bg-ink/10 hover:text-ink "
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
                  className="focus-ring cursor-pointer group/win w-11 h-full flex items-center justify-center text-ink/55 hover:bg-danger hover:text-white "
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
