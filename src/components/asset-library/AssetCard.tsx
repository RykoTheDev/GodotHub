import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import type { AssetLibraryAsset } from '../../types'
import {
  IconExternalLink,
  IconStar,
  IconStore,
} from '../../lib/icons'

const SUPPORT_BADGE: Record<string, string> = {
  official: 'bg-mint/10 text-mint border-mint/20',
  featured: 'bg-accent/10 text-accent-bright border-accent-dim/40',
  community: 'bg-raised text-muted border-line',
  testing: 'bg-amber/10 text-amber border-amber/20',
  testers: 'bg-amber/10 text-amber border-amber/20',
}

export function AssetCard({
  asset,
  onOpenPage,
  actions,
  showSource = false,
}: {
  asset: AssetLibraryAsset
  onOpenPage?: () => void
  actions?: React.ReactNode
  showSource?: boolean
}) {
  const { t } = useTranslation('common')

  const metaParts = [
    asset.godot_version ? `Godot ${asset.godot_version}` : null,
    asset.category || null,
    asset.cost || null,
  ].filter(Boolean) as string[]

  const rating = Number.parseFloat(asset.rating ?? '')
  const hasRating = Number.isFinite(rating) && rating > 0

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ type: 'spring', stiffness: 380, damping: 30 }}
      className="group relative flex flex-col rounded-item bg-overlay border border-outline/50 hover:bg-raised hover:border-accent-dim/60 transition-colors"
    >
      <div className="relative h-24 shrink-0 bg-raised flex items-center justify-center overflow-hidden rounded-t-item">
        {asset.icon_url && (
          <img
            src={asset.icon_url}
            alt=""
            loading="lazy"
            decoding="async"
            className="absolute inset-0 w-full h-full object-cover opacity-15 group-hover:opacity-0 transition-opacity duration-300"
            onError={(e) => {
              e.currentTarget.style.display = 'none'
            }}
          />
        )}
        <div className="absolute inset-x-0 bottom-0 h-10 bg-linear-to-t from-overlay to-transparent transition-opacity duration-300 group-hover:opacity-0" />
        <div className="relative w-14 h-14 rounded-tile bg-surface/90 border border-outline/60 flex items-center justify-center overflow-hidden opacity-0 scale-75 group-hover:opacity-100 group-hover:scale-100 transition-all duration-300 ease-out">
          <IconStore className="w-5 h-5 text-muted/50" />
          {asset.icon_url && (
            <img
              src={asset.icon_url}
              alt=""
              loading="lazy"
              decoding="async"
              className="absolute inset-0 w-full h-full object-cover"
              onError={(e) => {
                e.currentTarget.style.display = 'none'
              }}
            />
          )}
        </div>
      </div>

      <div className="flex flex-col gap-1.5 p-4 flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2">
          <h3 className="font-display font-medium text-lg text-ink leading-snug line-clamp-2 min-w-0">
            {asset.title}
          </h3>
          {onOpenPage && (
            <button
              onClick={onOpenPage}
              className="focus-ring cursor-pointer p-1 rounded-btn text-muted/40 opacity-0 group-hover:opacity-100 hover:text-ink hover:bg-raised transition-all shrink-0"
              aria-label={t('asset_open_page')}
            >
              <IconExternalLink className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        <div className="flex items-center gap-1.5 flex-wrap min-w-0">
          <p className="text-[11px] text-muted/70 truncate min-w-0">
            {t('asset_by_author', { author: asset.author })}
          </p>
          {showSource && asset.source && (
            <span className="shrink-0 inline-flex items-center px-2 py-0.5 rounded-tag text-[10px] font-semibold border border-accent-dim/30 bg-accent/10 text-accent-bright">
              {t(`asset_source_${asset.source}`)}
            </span>
          )}
          {hasRating && (
            <span className="shrink-0 inline-flex items-center gap-1 px-2 py-0.5 rounded-tag text-[10px] font-semibold border border-amber/25 bg-amber/10 text-amber">
              <IconStar className="w-2.5 h-2.5" />
              {rating.toFixed(1)}
            </span>
          )}
          {asset.support_level && (
            <span
              className={`shrink-0 inline-flex items-center px-2 py-0.5 rounded-tag text-[10px] font-semibold border ${
                SUPPORT_BADGE[asset.support_level] ??
                'bg-raised text-muted border-outline/50'
              }`}
            >
              {asset.support_level}
            </span>
          )}
        </div>

        {asset.description && (
          <p className="text-xs text-muted/60 leading-relaxed line-clamp-2">
            {asset.description.replace(/\r?\n/g, ' ')}
          </p>
        )}

        {metaParts.length > 0 && (
          <div className="flex items-center gap-1.5 flex-wrap mt-auto pt-2">
            {metaParts.map((part, i) => (
              <span
                key={i}
                className="inline-flex items-center px-2.5 py-1 rounded-tag bg-black/15 border border-outline/50 font-mono text-[10px] text-muted"
              >
                {part}
              </span>
            ))}
          </div>
        )}
      </div>

      {actions && (
        <div className="shrink-0 w-full flex items-center px-4 pb-4 pt-1">
          {actions}
        </div>
      )}
    </motion.div>
  )
}
