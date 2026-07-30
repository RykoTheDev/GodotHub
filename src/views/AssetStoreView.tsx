import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { IconStore } from '../components/Icons'

export function AssetStoreView() {
  const { t } = useTranslation('common')
  return (
    <div className="p-10 pt-6 max-w-8xl mx-auto flex flex-col gap-6">
      <div className="flex items-center gap-4">
        <div>
          <h2 className="font-body font-semibold text-3xl tracking-tight">
            {t('asset_store_title')}
          </h2>
          <p className="text-xs text-muted">
            {t('asset_subtitle')}
          </p>
        </div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.3, ease: 'easeOut' }}
        className="flex flex-col items-center justify-center gap-6 py-24 rounded-2xl border border-dashed border-line/60 bg-surface/30"
      >
        <div className="w-20 h-20 rounded-full bg-accent/5 flex items-center justify-center">
          <IconStore className="w-10 h-10 text-muted/30" />
        </div>
        <div className="text-center max-w-xs">
          <h3 className="font-display font-semibold text-lg text-ink">
            {t('asset_coming_soon')}
          </h3>
          <p className="text-sm text-muted mt-1.5 leading-relaxed">
            {t('asset_description')}
          </p>
        </div>
      </motion.div>
    </div>
  )
}
