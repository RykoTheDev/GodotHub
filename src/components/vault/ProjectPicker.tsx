import { useTranslation } from 'react-i18next'
import { motion } from 'framer-motion'
import type { Project } from '../../types'
import { Dropdown } from '../ui/Dropdown'
import { IconChevronDown, IconFolder } from '../../lib/icons'

interface Props {
  projects: Project[]
  selectedId: string | null
  onSelect: (id: string) => void
}

export function ProjectPicker({ projects, selectedId, onSelect }: Props) {
  const { t } = useTranslation('common')
  const selected = projects.find((p) => p.id === selectedId)

  return (
    <Dropdown
      align="left"
      className="w-full"
      menuClassName="max-h-72 overflow-y-auto"
      trigger={({ open, toggle }) => (
        <motion.button
          type="button"
          aria-expanded={open}
          data-press-feedback
          onClick={toggle}
          className="focus-ring cursor-pointer w-full flex items-center gap-2 h-10 px-3 rounded-item bg-base border border-outline/50 hover:border-accent-dim text-sm transition-colors"
        >
          <IconFolder className="w-3.5 h-3.5 text-muted shrink-0" />
          <span className={`flex-1 min-w-0 truncate text-start ${selected ? 'text-ink' : 'text-muted'}`}>
            {selected ? selected.name : t('vault_select_project')}
          </span>
          <IconChevronDown className="w-3.5 h-3.5 text-muted shrink-0" />
        </motion.button>
      )}
      items={projects.map((p) => ({
        key: p.id,
        label: p.name,
        active: p.id === selectedId,
        onClick: () => onSelect(p.id),
      }))}
    />
  )
}
