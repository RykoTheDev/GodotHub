import { useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { IconMore, IconTerminal } from '../../lib/icons'
import { Dropdown, type NewDropdownItem } from '../ui/Dropdown'

const SPRING = { type: 'spring', stiffness: 500, damping: 30 } as const

interface OpenButtonProps {
  label: string
  onOpen: (console?: boolean) => void
  items: NewDropdownItem[]
  consoleSupported?: boolean
  consoleInitiallyOn?: boolean
  disabled?: boolean
  moreAriaLabel: string
  className?: string
}

export function OpenButton({
  label,
  onOpen,
  items,
  consoleSupported = false,
  consoleInitiallyOn = false,
  disabled = false,
  moreAriaLabel,
  className = 'px-10',
}: OpenButtonProps) {
  const { t } = useTranslation('common')
  const [consoleEnabled, setConsoleEnabled] = useState(
    consoleSupported && consoleInitiallyOn,
  )

  return (
    <div className="flex items-stretch gap-1 shrink-0 justify-end">
      <motion.button
        whileHover={disabled ? undefined : { scale: 1.04 }}
        whileTap={disabled ? undefined : { scale: 0.94 }}
        transition={SPRING}
        type="button"
        disabled={disabled}
        onClick={() => onOpen(consoleEnabled || undefined)}
        className={`focus-ring flex items-center ${className} h-12 rounded-l-dropdown-btn rounded-r-[4px] font-semibold text-[17px] shadow-md shadow-black/10 border border-outline/50 transition-colors ${
          disabled
            ? 'bg-raised text-muted/40 cursor-not-allowed'
            : 'bg-accent text-ink hover:bg-accent-bright cursor-pointer'
        }`}
      >
        {label}
      </motion.button>

      {consoleSupported && (
        <motion.button
            key={consoleEnabled ? 'console-on' : 'console-off'}
            initial={{ scale: 0.9, opacity: 0.6 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ type: 'spring', stiffness: 500, damping: 24 }}
            whileHover={{ scale: 1.04 }}
            whileTap={{ scale: 0.9 }}
            type="button"
            onClick={() => setConsoleEnabled((v) => !v)}
            aria-label={t('open_with_console')}
            aria-pressed={consoleEnabled}
            className={`focus-ring cursor-pointer p-2 h-12 rounded-[4px] font-semibold text-[17px] shadow-md shadow-black/10 border transition-colors duration-200 ${
              consoleEnabled
                ? 'bg-raised text-ink border-mint'
                : 'bg-overlay text-muted border-outline/50 hover:text-mint hover:border-mint/50'
            }`}
          >
            <IconTerminal
              className={`w-4 h-4 ${consoleEnabled ? 'text-mint' : ''}`}
            />
          </motion.button>
      )}

      <Dropdown
        align="right"
        compact
        trigger={({ open, toggle }) => (
          <motion.button
            whileHover={{ scale: 1.04 }}
            whileTap={{ scale: 0.94 }}
            transition={SPRING}
            type="button"
            aria-label={moreAriaLabel}
            aria-expanded={open}
            onClick={toggle}
            className={`focus-ring cursor-pointer px-[5px] h-12 rounded-r-dropdown rounded-l-[4px] font-semibold text-[17px] shadow-md shadow-black/10 border border-outline/50 transition-colors ${
              open
                ? 'bg-raised text-ink border-accent-dim/60'
                : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
            }`}
          >
            <IconMore className="w-4 h-4" />
          </motion.button>
        )}
        items={items}
      />
    </div>
  )
}
