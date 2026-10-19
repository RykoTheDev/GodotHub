import { useEffect, useId } from 'react'
import { createPortal } from 'react-dom'
import { motion, type Variants } from 'framer-motion'
import { useUiMotion } from '../../hooks/useUiMotion'
import { ModalHeader } from './ModalHeader'

interface Props {
  icon: React.ReactNode
  title: string
  description?: React.ReactNode
  maxWidth?: string
  onClose?: () => void
  showClose?: boolean
  onKeyDown?: (e: React.KeyboardEvent) => void
  children: React.ReactNode
  footer?: React.ReactNode
  bodyClassName?: string
}

export function ModalShell({
  icon,
  title,
  description,
  maxWidth = 'max-w-2xl',
  onClose,
  showClose = true,
  onKeyDown,
  children,
  footer,
  bodyClassName,
}: Props) {
  const { reduced, instant, transition } = useUiMotion()
  const titleId = useId()

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dialog-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dialog-close'))
    }
  }, [])

  const closedTransform = reduced || instant ? 'none' : 'scale(0.96)'
  const cardVariants: Variants = {
    hidden: { opacity: 0, transform: closedTransform },
    show: { opacity: 1, transform: reduced || instant ? 'none' : 'scale(1)', transition: transition('modal') },
    exit: { opacity: 0, transform: closedTransform, transition: transition('modal', true) },
  }

  return createPortal(
    <motion.div
      initial={instant ? false : { opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: transition('modal', true) }}
      transition={transition('modal')}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={(e) => {
        e.stopPropagation()
        onClose?.()
      }}
    >
      <motion.div
        initial={instant ? false : 'hidden'}
        animate="show"
        exit="exit"
        variants={cardVariants}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className={`bg-surface rounded-modal w-full ${maxWidth} max-h-[88vh] flex flex-col shadow-2xl overflow-clip`}
        onClick={(e) => e.stopPropagation()}
        onKeyDown={onKeyDown}
      >
        <ModalHeader
          icon={icon}
          title={title}
          description={description}
          onClose={showClose ? onClose : undefined}
          titleId={titleId}
        />

        <div className={`min-h-0 overflow-y-auto ${bodyClassName ?? 'flex-1'}`}>
          {children}
        </div>

        {footer && (
          <div
            className="flex items-center gap-2.5 p-6 pt-4 border-t border-line shrink-0"
          >
            {footer}
          </div>
        )}
      </motion.div>
    </motion.div>,
    document.body,
  )
}
