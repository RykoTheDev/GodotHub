import i18n from '../../i18n'
import { useTranslation } from 'react-i18next'
import {
  LANGUAGES,
  resolveLanguage,
  type LanguageStatus,
} from '../../i18n/languages'
import { IconCheck } from '../../lib/icons'
import { useSettings } from '../../hooks/useSettings'
import { LanguageFlag } from './LanguageFlag'
import { Dropdown } from '../ui/Dropdown'

function statusLabel(status: LanguageStatus, t: (key: string) => string): string {
  switch (status) {
    case 'complete':
      return '✓'
    case 'beta':
      return t('language_beta')
    case 'incomplete':
      return t('language_incomplete')
  }
}

function isActive(value: string): boolean {
  return (
    i18n.language === value ||
    i18n.language.startsWith(value.split('-')[0])
  )
}

export interface LanguagePickerProps {
  variant?: 'dropdown' | 'inline'
  className?: string
}

export function LanguagePicker({
  variant = 'dropdown',
  className,
}: LanguagePickerProps) {
  const { t: ts } = useTranslation('settings')
  const { settings, update } = useSettings()

  const current =
    LANGUAGES.find((l) => isActive(l.value)) ?? LANGUAGES[0]

  const handleChange = (value: string) => {
    i18n.changeLanguage(resolveLanguage(value))
    update({ ...settings, language: value })
  }

  if (variant === 'inline') {
    return (
      <div className={`flex flex-col gap-1 ${className ?? ''}`}>
        {LANGUAGES.map((lang) => {
          const active = isActive(lang.value)
          return (
            <button
              key={lang.value}
              type="button"
              onClick={() => handleChange(lang.value)}
              className={`focus-ring cursor-pointer w-full flex items-center justify-between gap-2 text-left px-3 py-2 rounded-item text-xs transition-colors ${
                active
                  ? 'bg-accent/15 text-accent-bright'
                  : 'text-muted hover:bg-raised hover:text-ink'
              }`}
            >
              <span className="flex items-center gap-2 min-w-0">
                <LanguageFlag country={lang.country} className="w-5 h-3.5" />
                <span className="truncate">{lang.labelKey ? ts(lang.labelKey) : lang.label}</span>
                {lang.status !== 'complete' && (
                  <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-tag border bg-black/15 text-muted border-outline/40">
                    {statusLabel(lang.status, ts)}
                  </span>
                )}
              </span>
              {active && <IconCheck className="w-3.5 h-3.5" />}
            </button>
          )
        })}
      </div>
    )
  }

  return (
    <Dropdown
      align="left"
      trigger={({ open, toggle }) => (
        <button
          type="button"
          onClick={toggle}
          aria-expanded={open}
          className={`focus-ring cursor-pointer inline-flex items-center gap-2 px-3.5 py-2 rounded-btn bg-overlay border border-outline/50 text-xs font-medium text-ink hover:border-accent-dim transition-colors self-start ${className ?? ''}`}
        >
          <LanguageFlag country={current.country} />
          {current.labelKey ? ts(current.labelKey) : current.label}
          <svg
            className={`w-3 h-3 text-muted transition-transform duration-200 ${open ? 'rotate-180' : ''}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>
      )}
      items={LANGUAGES.map((lang) => ({
        key: lang.value,
        label: lang.labelKey ? ts(lang.labelKey) : lang.label,
        active: isActive(lang.value),
        leading: <LanguageFlag country={lang.country} className="w-5 h-3.5" />,
        badge: lang.status !== 'complete' ? statusLabel(lang.status, ts) : undefined,
        onClick: () => handleChange(lang.value),
      }))}
    />
  )
}
