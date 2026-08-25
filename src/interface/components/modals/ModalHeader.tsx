import { useEffect, useId, useRef } from 'react'
import { motion, type Variants } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { IconX } from '../../lib/icons'

interface Props {
  icon: React.ReactNode
  title: string
  description?: React.ReactNode
  onClose?: () => void
  variants?: Variants
  titleId?: string
  autoFocusBanner?: boolean
}

export function ModalHeader({
  icon,
  title,
  description,
  onClose,
  variants,
  titleId,
  autoFocusBanner = true,
}: Props) {
  const { t } = useTranslation('common')
  const fallbackId = useId()
  const id = titleId ?? fallbackId
  const bannerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!autoFocusBanner) return
    const banner = bannerRef.current
    if (!banner) return
    const dialog = banner.closest('[role="dialog"]')
    if (dialog && dialog.contains(document.activeElement)) return
    banner.focus()
  }, [autoFocusBanner])

  return (
    <motion.div
      variants={variants}
      className="flex items-start justify-between gap-4 p-5 pb-2 shrink-0"
    >
      <div
        ref={bannerRef}
        tabIndex={-1}
        className="flex items-start gap-1 min-w-0 flex-1 bg-black/15 px-3 py-4 rounded-btn outline-none"
      >
        <div className="w-10 h-10 rounded-tile flex items-center justify-center shrink-0">
          {icon}
        </div>
        <div className="min-w-0">
          <h3 id={id} className="uppercase font-semibold text-xl text-ink truncate">
            {title}
          </h3>
          {description && (
            <p className="text-xs text-muted mt-0.5 leading-relaxed">{description}</p>
          )}
        </div>
      </div>
      {onClose && (
        <button
          type="button"
          onClick={onClose}
          aria-label={t('close')}
          className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/50 hover:text-ink hover:bg-raised transition-colors shrink-0"
        >
          <IconX className="w-4 h-4" />
        </button>
      )}
    </motion.div>
  )
}
