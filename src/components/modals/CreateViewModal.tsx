import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { ModalShell } from './ModalShell'
import {
  IconKanban,
  IconLayoutGrid,
  IconLayoutList,
  IconPencil,
  IconPlus,
  IconX,
} from '../../lib/icons'

type ViewMode = 'list' | 'grid' | 'kanban'

interface Props {
  savedViews: ViewMode[]
  viewNames: Record<string, string>
  onAdd: (mode: ViewMode) => void
  onRemove: (mode: ViewMode) => void
  onRename: (mode: ViewMode, name: string) => void
  onClose: () => void
}

const VIEW_OPTIONS: {
  value: ViewMode
  labelKey: string
  icon: typeof IconLayoutList
  description: string
}[] = [
  {
    value: 'list',
    labelKey: 'view_list',
    icon: IconLayoutList,
    description: 'Compact rows with key details',
  },
  {
    value: 'grid',
    labelKey: 'view_grid',
    icon: IconLayoutGrid,
    description: 'Card-based grid layout',
  },
  {
    value: 'kanban',
    labelKey: 'view_kanban',
    icon: IconKanban,
    description: 'Columns grouped by category',
  },
]

export function CreateViewModal({
  savedViews,
  viewNames,
  onAdd,
  onRemove,
  onRename,
  onClose,
}: Props) {
  const { t } = useTranslation('common')
  const [editingMode, setEditingMode] = useState<ViewMode | null>(null)
  const [editValue, setEditValue] = useState('')

  const available = VIEW_OPTIONS.filter((v) => !savedViews.includes(v.value))
  const active = VIEW_OPTIONS.filter((v) => savedViews.includes(v.value))

  const startRename = (mode: ViewMode) => {
    setEditingMode(mode)
    setEditValue(viewNames[mode] ?? t(VIEW_OPTIONS.find((o) => o.value === mode)!.labelKey))
  }

  const commitRename = () => {
    if (editingMode && editValue.trim()) {
      onRename(editingMode, editValue.trim())
    }
    setEditingMode(null)
  }

  return (
    <ModalShell
      icon={<IconPlus className="w-5 h-5 text-accent-bright" />}
      title={t('manage_views')}
      description={t('manage_views_desc')}
      onClose={onClose}
      maxWidth="max-w-sm"
    >
      <div className="p-6 flex flex-col gap-4">
        {active.length > 0 && (
          <div className="flex flex-col gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/50 px-1">
              {t('active_views')}
            </span>
            {active.map((opt) => {
              const Icon = opt.icon
              const isOnly = savedViews.length === 1
              const customName = viewNames[opt.value]
              const isEditing = editingMode === opt.value

              return (
                <div
                  key={opt.value}
                  className="flex items-center gap-3 p-3 rounded-item border border-outline/50 bg-raised/40"
                >
                  <div className="w-8 h-8 rounded-item bg-accent/10 flex items-center justify-center shrink-0">
                    <Icon className="w-4 h-4 text-accent-bright" />
                  </div>
                  {isEditing ? (
                    <input
                      autoFocus
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') commitRename()
                        if (e.key === 'Escape') setEditingMode(null)
                      }}
                      onBlur={commitRename}
                      className="flex-1 min-w-0 bg-overlay border border-accent-dim rounded-item px-2 py-1 text-sm text-ink outline-none"
                    />
                  ) : (
                    <div className="flex-1 min-w-0">
                      <span className="block text-sm font-medium text-ink">
                        {customName ?? t(opt.labelKey)}
                      </span>
                      {customName && customName !== t(opt.labelKey) && (
                        <span className="block text-[10px] text-muted/50 mt-0.5">
                          {t(opt.labelKey)}
                        </span>
                      )}
                    </div>
                  )}
                  <div className="flex items-center gap-0.5 shrink-0">
                    {!isEditing && (
                      <button
                        type="button"
                        onClick={() => startRename(opt.value)}
                        className="focus-ring cursor-pointer p-1.5 rounded-item text-muted hover:text-accent hover:bg-accent/10 transition-colors"
                        aria-label={t('rename_view')}
                      >
                        <IconPencil className="w-3.5 h-3.5" />
                      </button>
                    )}
                    {!isOnly && (
                      <button
                        type="button"
                        onClick={() => onRemove(opt.value)}
                        className="focus-ring cursor-pointer p-1.5 rounded-item text-muted hover:text-danger hover:bg-danger/10 transition-colors"
                        aria-label={t('remove_view')}
                      >
                        <IconX className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {available.length > 0 && (
          <div className="flex flex-col gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/50 px-1">
              {t('available_views')}
            </span>
            {available.map((opt) => {
              const Icon = opt.icon
              return (
                <motion.button
                  key={opt.value}
                  type="button"
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => onAdd(opt.value)}
                  className="focus-ring cursor-pointer flex items-center gap-3 p-3 rounded-item border border-dashed border-outline/50 bg-overlay hover:bg-raised hover:border-accent-dim/50 transition-colors text-left"
                >
                  <div className="w-8 h-8 rounded-item bg-accent/10 flex items-center justify-center shrink-0">
                    <Icon className="w-4 h-4 text-accent-bright" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="block text-sm font-medium text-ink">
                      {t(opt.labelKey)}
                    </span>
                    <span className="block text-[11px] text-muted/60 mt-0.5">
                      {opt.description}
                    </span>
                  </div>
                  <IconPlus className="w-4 h-4 text-muted/40 shrink-0" />
                </motion.button>
              )
            })}
          </div>
        )}

        {available.length === 0 && active.length > 0 && (
          <p className="text-sm text-muted text-center py-2">
            {t('all_views_created')}
          </p>
        )}
      </div>
    </ModalShell>
  )
}
