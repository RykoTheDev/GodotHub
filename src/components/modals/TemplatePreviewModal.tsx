import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { api } from '../../lib/api'
import type { ProjectTemplate, TemplateFileEntry } from '../../types'
import { IconCopy, IconInfo, IconX, IconChevronDown, IconChevronRight } from '../Icons'

function formatSize(bytes: number): string {
  if (bytes === 0) return ''
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function FileTree({ entries }: { entries: TemplateFileEntry[] }) {
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set())

  const toggle = (path: string) => {
    setCollapsed((prev) => {
      const next = new Set(prev)
      if (next.has(path)) next.delete(path)
      else next.add(path)
      return next
    })
  }

  interface TreeNode {
    name: string
    path: string
    is_dir: boolean
    size: number
    children: TreeNode[]
  }

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

  const renderNode = (node: TreeNode, depth: number) => {
    const isCollapsed = collapsed.has(node.path)
    const hasChildren = node.children.length > 0

    return (
      <div key={node.path}>
        <div
          className={`flex items-center gap-2 px-2 py-1 rounded-md text-xs hover:bg-raised/60 transition-colors cursor-default ${
            depth === 0 ? 'font-medium text-ink' : 'text-muted'
          }`}
          style={{ paddingLeft: `${depth * 16 + 8}px` }}
        >
          {hasChildren ? (
            <button
              onClick={() => toggle(node.path)}
              className="focus-ring cursor-pointer p-0.5 text-muted hover:text-ink transition-colors"
              aria-label={isCollapsed ? 'Expand' : 'Collapse'}
            >
              {isCollapsed ? (
                <IconChevronRight className="w-3 h-3" />
              ) : (
                <IconChevronDown className="w-3 h-3" />
              )}
            </button>
          ) : (
            <span className="w-4" />
          )}

          {node.is_dir ? (
            <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5 text-accent-bright/70 shrink-0">
              <path d="M2 4.5A2.5 2.5 0 0 1 4.5 2h2.879a1.5 1.5 0 0 1 1.06.44l1.122 1.12A1.5 1.5 0 0 0 10.62 4H15.5A2.5 2.5 0 0 1 18 6.5v.5H2v-2.5Z" />
              <path d="M2 8.5V15a2.5 2.5 0 0 0 2.5 2.5h11A2.5 2.5 0 0 0 18 15V8.5H2Z" />
            </svg>
          ) : (
            <svg viewBox="0 0 20 20" fill="currentColor" className="w-3.5 h-3.5 text-muted/60 shrink-0">
              <path d="M4.5 2A1.5 1.5 0 0 0 3 3.5v13A1.5 1.5 0 0 0 4.5 18h11a1.5 1.5 0 0 0 1.5-1.5V6.621a1.5 1.5 0 0 0-.44-1.06l-3.12-3.122A1.5 1.5 0 0 0 12.378 2H4.5Z" />
            </svg>
          )}

          <span className="truncate">{node.name}</span>

          {!node.is_dir && node.size > 0 && (
            <span className="ml-auto text-[10px] text-muted/50 font-mono shrink-0">
              {formatSize(node.size)}
            </span>
          )}
        </div>

        {hasChildren && !isCollapsed && (
          <div>
            {node.children.map((child) => renderNode(child, depth + 1))}
          </div>
        )}
      </div>
    )
  }

  return <div className="flex flex-col">{root.map((n) => renderNode(n, 0))}</div>
}

interface Props {
  template: ProjectTemplate
  onClose: () => void
}

export function TemplatePreviewModal({ template, onClose }: Props) {
  const [entries, setEntries] = useState<TemplateFileEntry[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    setError(null)
    api
      .getTemplatePreview(template.id)
      .then(setEntries)
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false))
  }, [template.id])

  const fileCount = entries.filter((e) => !e.is_dir).length
  const dirCount = entries.filter((e) => e.is_dir).length
  const totalSize = entries.reduce((acc, e) => acc + e.size, 0)

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
        className="bg-surface border border-line rounded-2xl w-full max-w-lg max-h-[80vh] flex flex-col shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-start justify-between gap-4 p-6 pb-4 border-b border-line">
          <div className="flex items-start gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-accent/10 flex items-center justify-center shrink-0">
              <IconCopy className="w-4 h-4 text-accent-bright" />
            </div>
            <div className="min-w-0">
              <h3 className="font-display font-semibold text-lg truncate">
                {template.name}
              </h3>
              {template.description && (
                <p className="text-xs text-muted mt-0.5 leading-relaxed">
                  {template.description}
                </p>
              )}
              <div className="flex items-center gap-2 mt-1.5 text-[10px] text-muted/50 font-mono">
                <IconInfo className="w-3 h-3" />
                {fileCount} file{fileCount !== 1 ? 's' : ''}
                {dirCount > 0 && ` · ${dirCount} folder${dirCount !== 1 ? 's' : ''}`}
                {totalSize > 0 && ` · ${formatSize(totalSize)}`}

              </div>
            </div>
          </div>
          <button
            onClick={onClose}
            className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors shrink-0"
            aria-label="Close"
          >
            <IconX className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-4">
          {loading ? (
            <div className="flex items-center justify-center py-12 text-sm text-muted">
              Loading…
            </div>
          ) : error ? (
            <div className="flex items-center justify-center py-12 text-sm text-danger">
              {error}
            </div>
          ) : entries.length === 0 ? (
            <div className="flex items-center justify-center py-12 text-sm text-muted">
              This template is empty.
            </div>
          ) : (
            <FileTree entries={entries} />
          )}
        </div>
      </motion.div>
    </motion.div>
  )
}
