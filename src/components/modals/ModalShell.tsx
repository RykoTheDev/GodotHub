import { useEffect, useId } from 'react'
import { createPortal } from 'react-dom'
import { motion, type Variants } from 'framer-motion'
import { isReducedMotion } from '../../lib/appearance'
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
}: Props) {
  const reduced = isReducedMotion()
  const titleId = useId()

  useEffect(() => {
    window.dispatchEvent(new CustomEvent('app:dialog-open'))
    return () => {
      window.dispatchEvent(new CustomEvent('app:dialog-close'))
    }
  }, [])

  const cardVariants: Variants = reduced
    ? {
        hidden: { opacity: 0 },
        show: { opacity: 1, transition: { duration: 0.15 } },
        exit: { opacity: 0, transition: { duration: 0.12 } },
      }
    : {
        hidden: { opacity: 0, scale: 0.96 },
        show: {
          opacity: 1,
          scale: 1,
          transition: {
            type: 'spring',
            stiffness: 380,
            damping: 30,
            staggerChildren: 0.07,
            delayChildren: 0.05,
          },
        },
        exit: {
          opacity: 0,
          scale: 0.96,
          transition: { duration: 0.12 },
        },
      }

  const sectionVariants: Variants = reduced
    ? {
        hidden: { opacity: 0 },
        show: { opacity: 1, transition: { duration: 0.15 } },
      }
    : {
        hidden: { opacity: 0, y: 10 },
        show: {
          opacity: 1,
          y: 0,
          transition: { type: 'spring', stiffness: 400, damping: 32 },
        },
      }

  return createPortal(
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial="hidden"
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
          variants={sectionVariants}
          titleId={titleId}
        />

        <motion.div variants={sectionVariants} className="flex-1 min-h-0 overflow-y-auto">
          {children}
        </motion.div>

        {footer && (
          <motion.div
            variants={sectionVariants}
            className="flex items-center gap-2.5 p-6 pt-4 border-t border-line shrink-0"
          >
            {footer}
          </motion.div>
        )}
      </motion.div>
    </motion.div>,
    document.body,
  )
}
