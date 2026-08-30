import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { Category } from '../../types'
import { IconTags, IconX } from '../../lib/icons'

interface Props {
  categories: Category[]
  activeCategory: string | null
  onSelect: (category: string | null) => void
  uncategorizedLabel: string
  counts?: Record<string, number>
  uncategorizedCount?: number
}

export function CategoryFilterBar({
  categories,
  activeCategory,
  onSelect,
  uncategorizedLabel,
  counts,
  uncategorizedCount = 0,
}: Props) {
  const { t } = useTranslation('common')

  if (categories.length === 0) return null

  const allCount =
    categories.reduce((sum, cat) => sum + (counts?.[cat.name] ?? 0), 0) +
    uncategorizedCount

  return (
    <div className="flex items-center gap-1.5 flex-wrap">
      <motion.button
        type="button"
        onClick={() => onSelect(null)}
        whileHover={{ scale: 1.04 }}
        whileTap={{ scale: 0.94 }}
        className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-item transition-colors ${
          activeCategory === null
            ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
            : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
        }`}
      >
        <IconTags className="w-3 h-3" />
        <span className="text-[16px] font-medium">{t('all')}</span>
        <span className="text-[12px] tabular-nums text-muted/80">{allCount}</span>
      </motion.button>

      <motion.button
        type="button"
        onClick={() => onSelect(activeCategory === '' ? null : '')}
        whileHover={{ scale: 1.04 }}
        whileTap={{ scale: 0.94 }}
        className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-item transition-colors ${
          activeCategory === ''
            ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
            : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
        }`}
      >
        <span className="w-2 h-2 rounded-full shrink-0 ring-1 ring-black/10 bg-[#949ba4]" />
        <span className="text-[16px] font-medium">{uncategorizedLabel}</span>
        <span className="text-[12px] tabular-nums text-muted/80">{uncategorizedCount}</span>
        {activeCategory === '' && <IconX className="w-3 h-3 ml-0.5" />}
      </motion.button>

      {categories.map((cat) => {
        const isActive = activeCategory === cat.name
        return (
          <motion.button
            key={cat.id}
            type="button"
            onClick={() => onSelect(isActive ? null : cat.name)}
            whileHover={{ scale: 1.04 }}
            whileTap={{ scale: 0.94 }}
            className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 h-8 px-3 rounded-item transition-colors ${
              isActive
                ? 'bg-accent/15 text-accent-bright ring-1 ring-accent-dim/70'
                : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
            }`}
          >
            <span
              className="w-2 h-2 rounded-full shrink-0 ring-1 ring-black/10"
              style={{ backgroundColor: cat.color }}
            />
            <span className="text-[16px] font-medium">{cat.name}</span>
            <span className="text-[12px] tabular-nums text-muted/80">
              {counts?.[cat.name] ?? 0}
            </span>
            {isActive && <IconX className="w-3 h-3 ml-0.5" />}
          </motion.button>
        )
      })}
    </div>
  )
}
