import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import { ModalShell } from './ModalShell'
import {
  IconHardDrive,
  IconStopwatch,
  IconEyeSlash,
  IconFolder,
  IconTags,
  IconClock,
  IconPlay,
  IconTerminal,
  IconKanban,
  IconLayoutGrid,
  IconLayoutList,
  IconPencil,
  IconPlus,
  IconX,
} from '../../lib/icons'
import { useSettings } from '../../hooks/useSettings'
import { Toggle } from '../ui/Toggle'
import {
  getCardViewSettings,
  setCardViewOverride,
} from '../../lib/cardViewSettings'
import type { ProjectViewMode } from '../../types'

interface Props {
  savedViews: ProjectViewMode[]
  viewNames: Record<string, string>
  onAdd: (mode: ProjectViewMode) => void
  onRemove: (mode: ProjectViewMode) => void
  onRename: (mode: ProjectViewMode, name: string) => void
  onClose: () => void
}

const VIEW_OPTIONS: {
  value: ProjectViewMode
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

const CARD_TOGGLE_OPTIONS: {
  key: keyof ReturnType<typeof getCardViewSettings>
  icon: typeof IconHardDrive
  labelKey: string
}[] = [
  { key: 'show_size', icon: IconHardDrive, labelKey: 'customize_card_show_size' },
  { key: 'show_time', icon: IconStopwatch, labelKey: 'customize_card_show_time' },
  { key: 'blur_path', icon: IconEyeSlash, labelKey: 'customize_card_blur_path' },
  { key: 'show_path', icon: IconFolder, labelKey: 'customize_card_show_path' },
  { key: 'show_tags', icon: IconTags, labelKey: 'customize_card_show_tags' },
  { key: 'show_last_opened', icon: IconClock, labelKey: 'customize_card_show_last_opened' },
  { key: 'show_play', icon: IconPlay, labelKey: 'customize_card_show_play' },
  { key: 'show_console', icon: IconTerminal, labelKey: 'customize_card_show_console' },
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
  const { settings, update } = useSettings()
  const [editingMode, setEditingMode] = useState<ProjectViewMode | null>(null)
  const [editValue, setEditValue] = useState('')
  const [activeTab, setActiveTab] = useState<ProjectViewMode>('list')

  const available = VIEW_OPTIONS.filter((v) => !savedViews.includes(v.value))
  const active = VIEW_OPTIONS.filter((v) => savedViews.includes(v.value))
  const tabViews = VIEW_OPTIONS.filter((v) => savedViews.includes(v.value))

  const startRename = (mode: ProjectViewMode) => {
    setEditingMode(mode)
    setEditValue(viewNames[mode] ?? t(VIEW_OPTIONS.find((o) => o.value === mode)!.labelKey))
  }

  const commitRename = () => {
    if (editingMode && editValue.trim()) {
      onRename(editingMode, editValue.trim())
    }
    setEditingMode(null)
  }

  const toggleCardSetting = (key: string, value: boolean) => {
    const next = setCardViewOverride(settings, activeTab, key as any, value)
    update(next)
  }

  const currentCardSettings = getCardViewSettings(settings, activeTab)

  return (
    <ModalShell
      icon={<IconPlus className="w-5 h-5 text-accent-bright" />}
      title={t('manage_views')}
      description={t('manage_views_desc')}
      onClose={onClose}
      maxWidth="max-w-3xl"
    >
      <div className="p-6">
        <div className="flex gap-6 min-h-0">
          {/* Left: Project Card Toggles */}
          <div className="flex flex-col gap-2 min-w-0 flex-1">
            {/* View Tabs */}
            <div className="flex items-center gap-1 bg-overlay rounded-tag p-0.5">
              {tabViews.map((v) => {
                const Icon = v.icon
                const isActive = activeTab === v.value
                const customName = viewNames[v.value]
                return (
                  <button
                    key={v.value}
                    type="button"
                    onClick={() => setActiveTab(v.value)}
                    className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-tag text-xs font-medium transition-colors cursor-pointer ${
                      isActive
                        ? 'bg-accent/15 text-accent-bright'
                        : 'text-muted hover:text-ink hover:bg-raised/50'
                    }`}
                  >
                    <Icon className="w-3 h-3" />
                    {customName ?? t(v.labelKey)}
                  </button>
                )
              })}
            </div>

            <span className="text-[10px] font-semibold uppercase tracking-wider text-muted/50 px-1">
              {t('customize_card_section')}
            </span>
            <div className="rounded-item border border-outline/50 bg-raised/40 divide-y divide-outline/30">
              {CARD_TOGGLE_OPTIONS.filter((opt) =>
                opt.key !== 'blur_path' || currentCardSettings.show_path
              ).map((opt) => {
                const Icon = opt.icon
                const checked = currentCardSettings[opt.key]
                return (
                  <div
                    key={opt.key}
                    className="flex items-center gap-2.5 px-3 py-2"
                  >
                    <Icon className="w-3.5 h-3.5 text-muted/60 shrink-0" />
                    <span className="text-sm font-medium text-ink flex-1 min-w-0">
                      {t(opt.labelKey as any)}
                    </span>
                    <Toggle
                      checked={checked}
                      onChange={(v) => toggleCardSetting(opt.key, v)}
                      aria-label={t(opt.labelKey as any)}
                    />
                  </div>
                )
              })}
            </div>
          </div>

          {/* Divider */}
          <div className="w-px bg-outline/30 shrink-0" />

          {/* Right: View Management */}
          <div className="flex flex-col gap-2 min-w-0 flex-1">
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
                      className="flex items-center gap-2.5 p-2.5 rounded-item border border-outline/50 bg-raised/40"
                    >
                      <div className="w-7 h-7 rounded-item bg-accent/10 flex items-center justify-center shrink-0">
                        <Icon className="w-3.5 h-3.5 text-accent-bright" />
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
                          <span className="block text-sm font-medium text-ink truncate">
                            {customName ?? t(opt.labelKey)}
                          </span>
                          {customName && customName !== t(opt.labelKey) && (
                            <span className="block text-[10px] text-muted/50 mt-0.5 truncate">
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
                      className="focus-ring cursor-pointer flex items-center gap-2.5 p-2.5 rounded-item border border-dashed border-outline/50 bg-overlay hover:bg-raised hover:border-accent-dim/50 transition-colors text-left"
                    >
                      <div className="w-7 h-7 rounded-item bg-accent/10 flex items-center justify-center shrink-0">
                        <Icon className="w-3.5 h-3.5 text-accent-bright" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <span className="block text-sm font-medium text-ink truncate">
                          {t(opt.labelKey)}
                        </span>
                        <span className="block text-[11px] text-muted/60 mt-0.5 truncate">
                          {opt.description}
                        </span>
                      </div>
                      <IconPlus className="w-3.5 h-3.5 text-muted/40 shrink-0" />
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
        </div>
      </div>
    </ModalShell>
  )
}
