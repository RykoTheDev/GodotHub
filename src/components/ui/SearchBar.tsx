import { useRef } from 'react'
import { useTranslation } from 'react-i18next'
import type { KeyboardEvent, ReactNode, RefObject, SyntheticEvent } from 'react'
import { IconSearch, IconX } from '../../lib/icons'
import { Tooltip } from '../reusables/Tooltip'

interface SearchBarProps {
  value: string
  onChange: (value: string) => void
  placeholderKey?: string
  placeholder?: string
  inputRef?: RefObject<HTMLInputElement | null>
  className?: string
  onKeyDown?: (e: KeyboardEvent<HTMLInputElement>) => void
  onCaretChange?: (caret: number) => void
  onBlur?: () => void
  /** Rendered below the bar, e.g. a slash-command suggestion menu. */
  children?: ReactNode
}

export function SearchBar({
  value,
  onChange,
  placeholderKey = 'search_projects_placeholder',
  placeholder,
  inputRef,
  className = '',
  onKeyDown,
  onCaretChange,
  onBlur,
  children,
}: SearchBarProps) {
  const { t } = useTranslation('common')
  const ownRef = useRef<HTMLInputElement>(null)

  const inputRef_ = (node: HTMLInputElement | null) => {
    ownRef.current = node
    if (inputRef) inputRef.current = node
  }

  const reportCaret = (e: SyntheticEvent<HTMLInputElement>) => {
    onCaretChange?.(e.currentTarget.selectionStart ?? 0)
  }

  return (
    <div className="relative">
      <div
        className={`shrink-0 flex items-center gap-2 px-3.5 h-12 rounded-item bg-overlay border border-outline/50 focus-within:border-accent-dim focus-within:bg-raised transition-colors ${className}`}
      >
        <IconSearch className="w-4 h-4 text-muted shrink-0" />
        <input
          type="text"
          ref={inputRef_}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onKeyDown={onKeyDown}
          onBlur={onBlur}
          onClick={reportCaret}
          onSelect={onCaretChange ? reportCaret : undefined}
          aria-label={t('search')}
          placeholder={placeholder ?? t(placeholderKey)}
          className="flex-1 min-w-0 bg-transparent outline-none text-sm font-medium text-ink placeholder:text-muted/70"
        />
        {value && (
          <Tooltip content={t('clear_search')} side="top">
            <button
              type="button"
              aria-label={t('clear_search')}
              onClick={() => {
                onChange('')
                requestAnimationFrame(() => ownRef.current?.focus())
              }}
              className="cursor-pointer flex items-center justify-center w-6 h-6 rounded-btn text-muted hover:text-ink hover:bg-raised transition-colors"
            >
              <IconX className="w-3.5 h-3.5" />
            </button>
          </Tooltip>
        )}
      </div>
      {children}
    </div>
  )
}
