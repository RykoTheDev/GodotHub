import { motion } from 'framer-motion'
import { IconTrash } from '../Icons'

interface Props {
  title: string
  description: string
  confirmLabel: string
  variant?: 'default' | 'danger'
  onConfirm: () => void
  onCancel: () => void
}

export function ConfirmDialog({
  title,
  description,
  confirmLabel,
  variant = 'default',
  onConfirm,
  onCancel,
}: Props) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onCancel}
    >
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-7 w-full max-w-sm flex flex-col gap-5 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start gap-4">
          {variant === 'danger' && (
            <div className="w-10 h-10 rounded-lg bg-danger/10 border border-danger/30 flex items-center justify-center shrink-0">
              <IconTrash className="w-4 h-4 text-danger" />
            </div>
          )}
          <div>
            <h3 className="font-display font-semibold ">{title}</h3>
            <p className="text-sm text-muted mt-2 leading-relaxed">
              {description}
            </p>
          </div>
        </div>

        <div className="flex justify-end gap-2.5 mt-1">
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onCancel}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            Cancel
          </motion.button>
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onConfirm}
            className={`focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm font-medium transition-colors ${
              variant === 'danger'
                ? 'bg-danger hover:brightness-110 text-white'
                : 'bg-accent hover:bg-accent-bright text-white'
            }`}
          >
            {confirmLabel}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  )
}
