import { useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'

interface Props {
  projectName: string
  currentArgs: string
  onSave: (args: string) => void
  onClose: () => void
}

const SUGGESTIONS = [
  { labelKey: 'args_debug', descKey: 'args_debug_desc' },
  { labelKey: 'args_single_window', descKey: 'args_single_window_desc' },
  { labelKey: 'args_opengl3', descKey: 'args_opengl3_desc' },
  { labelKey: 'args_vulkan', descKey: 'args_vulkan_desc' },
  { labelKey: 'args_headless', descKey: 'args_headless_desc' },
  { labelKey: 'args_verbose', descKey: 'args_verbose_desc' },
  { labelKey: 'args_editor', descKey: 'args_editor_desc' },
  { labelKey: 'args_build_solutions', descKey: 'args_build_solutions_desc' },
  { labelKey: 'args_gpu_index', descKey: 'args_gpu_index_desc' },
]

export function LaunchArgsModal({
  projectName,
  currentArgs,
  onSave,
  onClose,
}: Props) {
  const { t } = useTranslation('common')
  const [args, setArgs] = useState(currentArgs)

  const append = (flag: string) => {
    setArgs((prev) => {
      const trimmed = prev.trim()
      return trimmed ? `${trimmed} ${flag}` : flag
    })
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-7 w-full max-w-lg flex flex-col gap-5 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div>
          <h3 className="font-display font-semibold text-lg">
            {t('args_heading')}
          </h3>
          <p className="text-xs text-muted mt-1.5">
            {t('args_desc_custom_flags_before')}{' '}
            <span className="font-medium text-ink">{projectName}</span>
            {t('args_desc_custom_flags_after')}
          </p>
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">{t('args_label')}</label>
          <input
            value={args}
            onChange={(e) => setArgs(e.target.value)}
            placeholder={t('args_placeholder')}
            className="focus-ring bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm font-mono text-ink focus:border-accent-dim transition-colors"
          />
          <p className="text-[11px] text-muted/60">
            {t('args_desc_separate_prefix')}{' '}
            <code className="text-muted">--rendering-driver opengl3</code>{' '}
            {t('args_desc_separate_suffix')}
          </p>
        </div>

        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">{t('args_suggestions')}</span>
          <div className="flex flex-wrap gap-1.5">
            {SUGGESTIONS.map((s) => (
              <button
                key={s.labelKey}
                type="button"
                onClick={() => append(t(s.labelKey))}
                title={t(s.descKey)}
                className="focus-ring cursor-pointer px-2.5 py-1 rounded-md bg-raised border border-line text-[11px] font-mono text-muted hover:text-ink hover:border-accent-dim transition-colors"
              >
                {t(s.labelKey)}
              </button>
            ))}
          </div>
        </div>

        <div className="flex justify-end gap-2.5 mt-1">
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            {t('cancel')}
          </motion.button>
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={() => onSave(args.trim())}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
          >
            {t('save')}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  )
}
