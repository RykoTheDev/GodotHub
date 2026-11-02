import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { IconMore, IconTerminal } from '../../lib/icons'
import { Dropdown, type NewDropdownItem, type NewDropdownHeaderItem } from '../ui/Dropdown'
import { Tooltip } from './Tooltip'

interface OpenButtonProps {
  label: string
  onOpen: (console?: boolean) => void
  items: NewDropdownItem[]
  headerItems?: NewDropdownHeaderItem[]
  consoleSupported?: boolean
  consoleInitiallyOn?: boolean
  showConsole?: boolean
  disabled?: boolean
  moreAriaLabel: string
  className?: string
  size?: 'default' | 'compact'
  disabledReason?: string
}

export function OpenButton({
  label,
  onOpen,
  items,
  headerItems,
  consoleSupported = false,
  consoleInitiallyOn = false,
  showConsole = true,
  disabled = false,
  moreAriaLabel,
  className = 'px-10',
  size = 'default',
  disabledReason,
}: OpenButtonProps) {
  const { t } = useTranslation('common')
  const [consoleEnabled, setConsoleEnabled] = useState(
    consoleSupported && consoleInitiallyOn,
  )
  const compact = size === 'compact'

  useEffect(() => {
    setConsoleEnabled(consoleSupported && consoleInitiallyOn)
  }, [consoleSupported, consoleInitiallyOn])

  return (
    <div className={`flex items-stretch gap-1 ${compact ? 'min-w-0 w-full' : 'shrink-0 justify-end'}`}>
      <button



        type="button"
        disabled={disabled}
        onClick={() => onOpen((consoleSupported && consoleEnabled) || undefined)}
        title={disabled ? disabledReason : consoleEnabled ? t('open_with_console') : label}
        className={`focus-ring flex items-center justify-center ${compact ? 'min-w-0 flex-1 px-3 h-9 text-xs' : `${className} h-12 text-[17px]`} rounded-s-dropdown-btn rounded-e-[4px] font-semibold shadow-md shadow-black/10 border border-outline/50  ${
          disabled
            ? 'bg-raised text-muted/40 cursor-not-allowed'
            : 'bg-accent text-white hover:bg-accent-bright cursor-pointer'
        }`}
      >
        <span className={compact ? 'truncate' : undefined}>{label}</span>
      </button>

      {consoleSupported && showConsole && (
        <Tooltip content={t('open_with_console')} side="top">
          <button


              type="button"
              onClick={() => setConsoleEnabled((v) => !v)}
              aria-pressed={consoleEnabled}
              aria-label={t('open_with_console')}
              disabled={disabled}
              className={`focus-ring cursor-pointer flex items-center justify-center shrink-0 ${compact ? 'w-9 h-9' : 'p-2 h-12 text-[17px]'} rounded-[4px] font-semibold shadow-md shadow-black/10 border disabled:opacity-40 disabled:cursor-not-allowed ${
                consoleEnabled
                  ? 'bg-raised text-ink border-mint'
                  : 'bg-overlay text-muted border-outline/50 hover:text-mint hover:border-mint/50'
              }`}
            >
              <IconTerminal
                className={`w-4 h-4 ${consoleEnabled ? 'text-mint' : ''}`}
              />
            </button>
        </Tooltip>
      )}

      <Dropdown
        align="right"
        side={compact ? 'bottom' : 'left'}
        compact
        trigger={({ open, toggle }) => (
          <button



            type="button"
            aria-label={moreAriaLabel}
            aria-expanded={open}
            onClick={toggle}
            className={`focus-ring cursor-pointer flex items-center justify-center shrink-0 ${compact ? 'w-8 h-9' : 'px-[5px] h-12 text-[17px]'} rounded-e-dropdown rounded-s-[4px] font-semibold shadow-md shadow-black/10 border border-outline/50  ${
              open
                ? 'bg-raised text-ink border-accent-dim/60'
                : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
            }`}
          >
            <IconMore className="w-4 h-4" />
          </button>
        )}
        header={headerItems}
        items={items}
      />
    </div>
  )
}
