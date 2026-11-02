import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { VaultFileEntry } from '../../types'
import { IconChevronDown, IconChevronRight, IconCheck } from '../../lib/icons'

function formatSize(bytes: number): string {
  if (bytes === 0) return ''
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

interface TreeNode {
  name: string
  path: string
  rel: string
  is_dir: boolean
  size: number
  children: TreeNode[]
}

function buildTree(entries: VaultFileEntry[]): TreeNode[] {
  const root: TreeNode[] = []
  const map = new Map<string, TreeNode>()

  for (const e of entries) {
    const parts = e.path.split('/').filter(Boolean)
    let current = root
    let accumulated = ''
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i]
      accumulated = accumulated ? `${accumulated}/${part}` : part
      const isLast = i === parts.length - 1
      let node = map.get(accumulated)
      if (!node) {
        node = {
          name: part,
          path: accumulated + (e.is_dir && isLast ? '/' : ''),
          rel: accumulated,
          is_dir: isLast ? e.is_dir : true,
          size: isLast ? e.size : 0,
          children: [],
        }
        map.set(accumulated, node)
        current.push(node)
      }
      current = node.children
    }
  }

  return root
}

function FolderIcon() {
  return (
    <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5 text-accent-bright/70 shrink-0">
      <path d="M2 4.5A2.5 2.5 0 0 1 4.5 2h2.879a1.5 1.5 0 0 1 1.06.44l1.122 1.12A1.5 1.5 0 0 0 10.62 4H15.5A2.5 2.5 0 0 1 18 6.5v.5H2v-2.5Z" />
      <path d="M2 8.5V15a2.5 2.5 0 0 0 2.5 2.5h11A2.5 2.5 0 0 0 18 15V8.5H2Z" />
    </svg>
  )
}

function FileIcon() {
  return (
    <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5 text-muted/60 shrink-0">
      <path d="M4.5 2A1.5 1.5 0 0 0 3 3.5v13A1.5 1.5 0 0 0 4.5 18h11a1.5 1.5 0 0 0 1.5-1.5V6.621a1.5 1.5 0 0 0-.44-1.06l-3.12-3.122A1.5 1.5 0 0 0 12.378 2H4.5Z" />
    </svg>
  )
}

export function VaultFileTree({ entries }: { entries: VaultFileEntry[] }) {
  const { t } = useTranslation('common')
  const [collapsed, setCollapsed] = useState<Set<string>>(
    () => new Set(entries.filter((e) => e.is_dir).map((e) => e.path)),
  )

  const toggle = (path: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev)
      if (next.has(path)) next.delete(path)
      else next.add(path)
      return next
    })
  }

  const renderNode = (node: TreeNode, depth: number) => {
    const isCollapsed = collapsed.has(node.path)
    const hasChildren = node.children.length > 0

    return (
      <div key={node.path}>
        <div
          className={`flex items-center gap-2 px-2 py-1 rounded-item text-xs hover:bg-raised/60 cursor-default ${
            depth === 0 ? 'font-medium text-ink' : 'text-muted'
          }`}
          style={{ paddingLeft: `${depth * 16 + 8}px` }}
        >
          {hasChildren ? (
            <button
              onClick={() => toggle(node.path)}
              className="focus-ring cursor-pointer p-0.5 text-muted hover:text-ink "
              aria-label={isCollapsed ? t('expand') : t('collapse')}
            >
              {isCollapsed ? (
                <IconChevronRight className="rtl:rotate-180 w-3 h-3" />
              ) : (
                <IconChevronDown className="w-3 h-3" />
              )}
            </button>
          ) : (
            <span className="w-4" />
          )}

          {node.is_dir ? <FolderIcon /> : <FileIcon />}

          <span className="truncate">{node.name}</span>

          {!node.is_dir && node.size > 0 && (
            <span className="ms-auto text-3xs text-muted/50 font-mono shrink-0">
              {formatSize(node.size)}
            </span>
          )}
        </div>

        {hasChildren && !isCollapsed && (
          <div>{node.children.map((child) => renderNode(child, depth + 1))}</div>
        )}
      </div>
    )
  }

  const root = buildTree(entries)
  return <div className="flex flex-col">{root.map((n) => renderNode(n, 0))}</div>
}

export function SelectableVaultFileTree({
  entries,
  selected,
  onToggle,
}: {
  entries: VaultFileEntry[]
  selected: Set<string>
  onToggle: (rel: string) => void
}) {
  const { t } = useTranslation('common')
  const [collapsed, setCollapsed] = useState<Set<string>>(
    () => new Set(entries.filter((e) => e.is_dir).map((e) => e.path)),
  )

  const toggleCollapse = (path: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev)
      if (next.has(path)) next.delete(path)
      else next.add(path)
      return next
    })
  }

  const isCovered = (rel: string) => {
    for (const sel of selected) {
      if (rel === sel) continue
      if (rel.startsWith(`${sel}/`)) return true
    }
    return false
  }

  const renderNode = (node: TreeNode, depth: number) => {
    const isCollapsed = collapsed.has(node.path)
    const hasChildren = node.children.length > 0
    const covered = isCovered(node.rel)
    const checked = covered || selected.has(node.rel)

    return (
      <div key={node.path}>
        <div
          className="flex items-center gap-2 px-2 py-1 rounded-item text-xs hover:bg-raised/60 "
          style={{ paddingLeft: `${depth * 16 + 8}px` }}
        >
          {hasChildren ? (
            <button
              type="button"
              onClick={() => toggleCollapse(node.path)}
              className="focus-ring cursor-pointer p-0.5 text-muted hover:text-ink "
              aria-label={isCollapsed ? t('expand') : t('collapse')}
            >
              {isCollapsed ? (
                <IconChevronRight className="rtl:rotate-180 w-3 h-3" />
              ) : (
                <IconChevronDown className="w-3 h-3" />
              )}
            </button>
          ) : (
            <span className="w-4" />
          )}

          <button
            type="button"
            disabled={covered}
            onClick={() => onToggle(node.rel)}
            aria-pressed={checked}
            className={`focus-ring shrink-0 w-4 h-4 rounded-[5px] border flex items-center justify-center  ${
              checked
                ? 'bg-accent border-accent text-white'
                : 'bg-base border-outline/60 hover:border-accent-dim'
            } ${covered ? 'opacity-60 cursor-not-allowed' : 'cursor-pointer'}`}
          >
            {checked && <IconCheck className="w-3 h-3" />}
          </button>

          {node.is_dir ? <FolderIcon /> : <FileIcon />}

          <span
            className={`truncate cursor-pointer ${
              checked ? 'text-ink' : 'text-muted'
            } ${covered ? 'opacity-60' : ''}`}
            onClick={() => {
              if (!covered) onToggle(node.rel)
            }}
          >
            {node.name}
          </span>

          {!node.is_dir && node.size > 0 && (
            <span className="ms-auto text-3xs text-muted/50 font-mono shrink-0">
              {formatSize(node.size)}
            </span>
          )}
        </div>

        {hasChildren && !isCollapsed && (
          <div>{node.children.map((child) => renderNode(child, depth + 1))}</div>
        )}
      </div>
    )
  }

  const root = buildTree(entries)
  return <div className="flex flex-col">{root.map((n) => renderNode(n, 0))}</div>
}
