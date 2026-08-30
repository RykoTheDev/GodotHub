import { motion } from 'framer-motion'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { IconChevronDown } from '../../lib/icons'
import { api } from '../../lib/api'
import { Dropdown, type NewDropdownItem } from '../ui/Dropdown'

const TOOL_BUTTON_CLASS =
  'text-muted hover:text-ink font-semibold text-[17px] bg-overlay shadow-md shadow-black/10 border border-outline/50 hover:bg-raised cursor-pointer h-10 flex items-center transition-colors'

const TOOL_BUTTON_SPRING = { type: 'spring', stiffness: 500, damping: 30 } as const

const TOOL_BUTTON_ANIMATION = {
  whileHover: { scale: 1.04 },
  whileTap: { scale: 0.94 },
  transition: TOOL_BUTTON_SPRING,
} as const

interface ImportButtonProps {
  onImport: (folder: string) => Promise<void>
  options?: NewDropdownItem[]
  disabled?: boolean
  importEvent?: string
}

export function ImportButton({
  onImport,
  options = [],
  disabled = false,
  importEvent,
}: ImportButtonProps) {
  const { t } = useTranslation('common')
  const [importing, setImporting] = useState(false)
  const [picking, setPicking] = useState(false)

  const handleImport = async () => {
    if (importing || picking || disabled) return
    setPicking(true)
    setImporting(true)
    try {
      const folder = await api.pickFolder()
      if (!folder) return
      try {
        await onImport(folder)
      } catch (e) {
        console.error('[new-ui] import failed:', e)
        alert(String(e))
      }
    } finally {
      setPicking(false)
      setImporting(false)
    }
  }

  const handleImportRef = useRef(handleImport)
  handleImportRef.current = handleImport

  useEffect(() => {
    if (!importEvent) return
    const handler = () => handleImportRef.current()
    window.addEventListener(importEvent, handler)
    return () => window.removeEventListener(importEvent, handler)
  }, [importEvent])

  const hasOptions = options.length > 0
  const busy = importing || picking

  return (
    <div className="flex items-stretch gap-1">
      <motion.button
        type="button"
        {...(!busy ? TOOL_BUTTON_ANIMATION : {})}
        onClick={handleImport}
        disabled={busy || disabled}
        className={`${TOOL_BUTTON_CLASS} px-6 ${
          hasOptions ? 'rounded-l-dropdown-btn rounded-r-[4px]' : 'rounded-item'
        } disabled:opacity-40 disabled:cursor-not-allowed`}
      >
        {t('import')}
      </motion.button>
      {hasOptions && (
        <Dropdown
          align="right"
          trigger={({ open, toggle }) => (
            <motion.button
              type="button"
              aria-label={t('more_import_options')}
              aria-expanded={open}
              {...TOOL_BUTTON_ANIMATION}
              onClick={toggle}
              className={`${TOOL_BUTTON_CLASS} px-[5px] rounded-r-dropdown rounded-l-[4px]`}
            >
              <IconChevronDown
                className={`w-3 h-3 transition-transform duration-200 ${
                  open ? 'rotate-180 text-ink' : ''
                }`}
              />
            </motion.button>
          )}
          items={options}
        />
      )}
    </div>
  )
}
