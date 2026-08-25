import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { IconAlertTriangle, IconTrash } from '../../lib/icons'
import { ModalShell } from './ModalShell'

interface Props {
  title: string
  description: string | React.ReactNode
  confirmLabel: string
  cancelLabel?: string
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
  cancelLabel,
}: Props) {
  const { t } = useTranslation('common')

  return (
    <ModalShell
      icon={
        variant === 'danger' ? (
          <IconTrash className="w-5 h-5 text-danger" />
        ) : (
          <IconAlertTriangle className="w-5 h-5 text-amber" />
        )
      }
      title={title}
      description={description}
      maxWidth="max-w-sm"
      onClose={onCancel}
      showClose={false}
      footer={
        <div className="ml-auto flex items-center gap-2.5">
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onCancel}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            {cancelLabel || t('cancel')}
          </motion.button>
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onConfirm}
            className={`focus-ring cursor-pointer px-4 py-2.5 rounded-btn text-sm font-medium transition-colors ${
              variant === 'danger'
                ? 'bg-danger hover:brightness-110 text-white'
                : 'bg-accent hover:bg-accent-bright text-white'
            }`}
          >
            {confirmLabel}
          </motion.button>
        </div>
      }
    >
      <div className="p-6 pt-0" />
    </ModalShell>
  )
}
