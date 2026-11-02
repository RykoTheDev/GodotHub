import { useTranslation } from 'react-i18next'
import type { VaultItem } from '../../types'
import { ModalShell } from '../modals/ModalShell'
import { formatBytes } from '../../lib/formatBytes'
import { VaultFileTree } from './VaultFileTree'
import { IconBriefcase, IconInfo } from '../../lib/icons'

interface Props {
  item: VaultItem
  onClose: () => void
}

export function VaultItemPreviewModal({ item, onClose }: Props) {
  const { t } = useTranslation('common')
  const files = item.files ?? []
  const fileCount = files.filter((e) => !e.is_dir).length
  const dirCount = files.filter((e) => e.is_dir).length
  const totalSize = files.reduce((acc, e) => acc + e.size, 0)

  return (
    <ModalShell
      icon={<IconBriefcase className="w-5 h-5 text-accent-bright" />}
      title={item.name}
      description={item.description || undefined}
      maxWidth="max-w-lg"
      onClose={onClose}
    >
      <div className="p-6">
        {item.tags.length > 0 && (
          <div className="flex flex-wrap gap-1.5 pb-3">
            {item.tags.map((tag) => (
              <span
                key={tag}
                className="inline-flex items-center px-2 py-0.5 rounded-tag bg-raised border border-outline/50 text-2xs font-mono text-muted"
              >
                {tag}
              </span>
            ))}
          </div>
        )}

        {files.length === 0 ? (
          <div className="flex items-center justify-center py-12 text-sm text-muted">
            {t('vault_item_empty')}
          </div>
        ) : (
          <>
            <div className="flex items-center gap-2 px-1 pb-2 text-3xs text-muted/50 font-mono">
              <IconInfo className="w-3 h-3" />
              {t('file_count', { count: fileCount })}
              {dirCount > 0 && ` · ${t('folder_count', { count: dirCount })}`}
              {totalSize > 0 && ` · ${formatBytes(totalSize)}`}
            </div>
            <VaultFileTree entries={files} />
          </>
        )}
      </div>
    </ModalShell>
  )
}
