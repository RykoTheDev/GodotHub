import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react'
import { createPortal } from 'react-dom'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'
import {
  LANGUAGES,
  SYSTEM_LANGUAGE,
  getSystemLanguage,
  languageStatusLabelKey,
  type LanguageStatus,
} from '../../i18n/languages'
import { IconLanguage, IconCheck, IconTextDirection } from '../../lib/icons'
import { useSettings } from '../../hooks/useSettings'
import { LanguageFlag } from '../reusables/LanguageFlag'
import { Tooltip } from '../reusables/Tooltip'

const STATUS_BADGE_CLASS: Record<LanguageStatus, string> = {
  complete: 'bg-mint/10 text-mint border-mint/30',
  beta: 'bg-amber/10 text-amber border-amber/30',
  incomplete: 'bg-black/15 text-muted border-outline/40',
}

const GAP = 8
const EDGE_PADDING = 8
const MENU_WIDTH = 240
const OPEN_UP_THRESHOLD = 220

export function LanguageMenu() {
  const { t: ts } = useTranslation('settings')
  const { settings, update } = useSettings()

  const badge = (status: LanguageStatus) => (
    <span
      className={`text-3xs font-semibold px-1.5 py-0.5 rounded-tag border shrink-0 ${STATUS_BADGE_CLASS[status]}`}
    >
      {ts(languageStatusLabelKey(status))}
    </span>
  )

  const [open, setOpen] = useState(false)
  const [dir, setDir] = useState(false)
  const [pos, setPos] = useState<{
    left: number
    top: number
  } | null>(null)

  const ref = useRef<HTMLDivElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (
        ref.current &&
        !ref.current.contains(e.target as Node)
      ) {
        if (
          listRef.current?.contains(e.target as Node)
        ) {
          return
        }

        setOpen(false)
      }
    }

    const keyHandler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setOpen(false)
      }
    }

    document.addEventListener('mousedown', handler)
    document.addEventListener('keydown', keyHandler)

    return () => {
      document.removeEventListener('mousedown', handler)
      document.removeEventListener('keydown', keyHandler)
    }
  }, [])

  const measure = useCallback(() => {
    const el = ref.current

    if (!el || !listRef.current) {
      return
    }

    const r = el.getBoundingClientRect()
    const spaceBelow = window.innerHeight - r.bottom
    const d = spaceBelow < OPEN_UP_THRESHOLD
    const h = listRef.current.offsetHeight

    setDir(d)

    setPos({
      left: Math.max(
        EDGE_PADDING,
        r.right - MENU_WIDTH,
      ),
      top: Math.max(
        EDGE_PADDING,
        d
          ? r.top - h - GAP
          : r.bottom + GAP,
      ),
    })
  }, [])

  useLayoutEffect(() => {
    if (open) {
      measure()
    }
  }, [open, measure])

  useEffect(() => {
    if (!open) {
      return
    }

    const reposition = () => measure()

    window.addEventListener(
      'scroll',
      reposition,
      true,
    )

    window.addEventListener(
      'resize',
      reposition,
    )

    return () => {
      window.removeEventListener(
        'scroll',
        reposition,
        true,
      )

      window.removeEventListener(
        'resize',
        reposition,
      )
    }
  }, [open, measure])

  const isActive = (value: string) => {
    if (value === SYSTEM_LANGUAGE) {
      return settings.language === SYSTEM_LANGUAGE
    }

    if (settings.language === SYSTEM_LANGUAGE) {
      return false
    }

    return (
      i18n.language === value ||
      i18n.language.startsWith(
        value.split('-')[0],
      )
    )
  }

  const select = (value: string) => {
    const language =
      value === SYSTEM_LANGUAGE
        ? getSystemLanguage()
        : value

    i18n.changeLanguage(language)

    update({
      ...settings,
      language: value,
    })

    setOpen(false)
  }

  const noDrag = (e: React.MouseEvent) =>
    e.stopPropagation()

  return (
    <>
      <div
        ref={ref}
        className="flex items-stretch shrink-0"
      >
        <Tooltip content={ts('language_label')}>
          <button
            type="button"
            onClick={() => setOpen((o) => !o)}
            onMouseDown={noDrag}
            aria-label={ts('language_label')}
            aria-expanded={open}
            aria-haspopup="menu"



            className="focus-ring cursor-pointer relative w-9 h-8 flex items-center justify-center rounded-item text-muted hover:text-ink hover:bg-raised shrink-0"
          >
            <IconLanguage className="w-4 h-4" />
          </button>
        </Tooltip>
      </div>

      {createPortal(

          open && (
            <div key="div-220"
              ref={listRef}

              role="menu"
              className={`fixed z-50 ${
                dir
                  ? 'origin-bottom'
                  : 'origin-top'
              } rounded-menu border border-outline/50 bg-overlay shadow-md shadow-black/10 p-1.5`}
              style={{
                left: pos?.left,
                top: pos?.top,
                width: MENU_WIDTH,
                transformOrigin: `${dir ? 'bottom' : 'top'} right`,
              }}
            >
              <div className="px-2.5 pt-1.5 pb-1 text-3xs font-semibold uppercase tracking-wider text-muted/50">
                {ts('language_label')}
              </div>

              {LANGUAGES.map((lang) => {
                const active = isActive(lang.value)
                const isSystem =
                  lang.value === SYSTEM_LANGUAGE

                const showLayoutToggle =
                  active && i18n.dir(i18n.language) === 'rtl'

                const item = (
                  <button
                    key={lang.value}
                    type="button"
                    role="menuitem"
                    onClick={() =>
                      select(lang.value)
                    }
                    className={`focus-ring cursor-pointer flex items-center justify-between gap-2 text-start px-2.5 py-2 text-xs  ${
                      showLayoutToggle
                        ? 'flex-1 min-w-0 rounded-s-item rounded-e-sm'
                        : 'w-full rounded-item'
                    } ${
                      active
                        ? 'bg-accent/15 text-accent-bright'
                        : 'text-muted hover:bg-raised hover:text-ink'
                    }`}
                  >
                    <span className="flex items-center gap-1.5 min-w-0">
                      <LanguageFlag
                        country={lang.country}
                      />

                      <span className="truncate">
                      {lang.labelKey ? ts(lang.labelKey): lang.label}
                      </span>

                      {!isSystem &&
                        badge(lang.status)}
                    </span>

                    {active && (
                      <IconCheck className="w-3.5 h-3.5" />
                    )}
                  </button>
                )

                if (!showLayoutToggle) return item

                const mirrored = settings.rtl_layout ?? false
                const layoutLabel = mirrored
                  ? 'التبديل إلى التخطيط من اليسار إلى اليمين'
                  : 'التبديل إلى التخطيط من اليمين إلى اليسار'

                return (
                  <div
                    key={lang.value}
                    className="flex items-stretch gap-0.5"
                  >
                    {item}
                    <Tooltip content={layoutLabel}>
                      <button
                        type="button"
                        role="menuitemcheckbox"
                        aria-checked={mirrored}
                        aria-label={layoutLabel}
                        onClick={() =>
                          update({
                            ...settings,
                            rtl_layout: !mirrored,
                          })
                        }
                        className={`focus-ring cursor-pointer w-9 shrink-0 flex items-center justify-center rounded-s-sm rounded-e-item  ${
                          mirrored
                            ? 'bg-accent/25 text-accent-bright hover:bg-accent/35'
                            : 'bg-accent/15 text-accent-bright/70 hover:bg-accent/25 hover:text-accent-bright'
                        }`}
                      >
                        <IconTextDirection className="w-3.5 h-3.5" />
                      </button>
                    </Tooltip>
                  </div>
                )
              })}
            </div>
          )
        ,
        document.body,
      )}
    </>
  )
}
