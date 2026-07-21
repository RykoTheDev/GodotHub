import { useEffect, useRef, useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import type { Project, ProjectSizeInfo } from '../../types'
import { api } from '../../lib/api'
import { IconX, IconHardDrive } from '../Icons'

interface Props {
  project: Project
  onClose: () => void
}

const PIE_COLORS = [
  '#457ff2', '#f28b45', '#45c97f', '#e74c8a', '#a855f7',
  '#22d3ee', '#f59e0b', '#ef4444', '#10b981', '#6366f1',
  '#ec4899', '#14b8a6', '#f97316', '#8b5cf6', '#06b6d4',
  '#84cc16', '#d946ef', '#0ea5e9', '#eab308', '#94a3b8',
]

function formatSize(bytes: number): string {
  if (bytes === 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  const val = bytes / Math.pow(1024, i)
  return `${val.toFixed(i === 0 ? 0 : 1)} ${units[i]}`
}

function DonutChart({
  categories,
  totalSize,
  hoveredIndex,
  onHover,
}: {
  categories: { label: string; size: number; color: string; count: number }[]
  totalSize: number
  hoveredIndex: number | null
  onHover: (index: number | null) => void
}) {
  const innerRadius = 65
  const [animated, setAnimated] = useState(false)

  useEffect(() => {
    const t = setTimeout(() => setAnimated(true), 50)
    return () => clearTimeout(t)
  }, [])

  if (totalSize === 0) {
    return (
      <div className="flex items-center justify-center h-56 text-muted text-sm">
        No files found
      </div>
    )
  }

  let cumulative = 0
  const arcs = categories.map((cat) => {
    const startAngle = (cumulative / totalSize) * 360
    cumulative += cat.size
    const endAngle = (cumulative / totalSize) * 360
    return { ...cat, startAngle, endAngle }
  })

  const maxSlices = 8
  const displayArcs = arcs.slice(0, maxSlices - 1)
  const remaining = arcs.slice(maxSlices - 1)
  const otherSize = remaining.reduce((sum, c) => sum + c.size, 0)
  if (otherSize > 0) {
    const startAngle = displayArcs.length > 0
      ? displayArcs[displayArcs.length - 1].endAngle
      : 0
    displayArcs.push({
      ...remaining.reduce((merged, c) => ({
        label: 'Other',
        size: merged.size + c.size,
        color: '#94a3b8',
        count: merged.count + c.count,
        startAngle: 0,
        endAngle: 0,
      }), { label: 'Other', size: 0, color: '#94a3b8', count: 0, startAngle: 0, endAngle: 0 }),
      startAngle,
      endAngle: 360,
    })
  }

  const toRad = (deg: number) => (deg - 90) * (Math.PI / 180)

  return (
    <svg viewBox="0 0 200 200" className="w-full h-full drop-shadow-sm overflow-visible">
      {/* Background ring */}
      <circle cx="100" cy="100" r={innerRadius} fill="none" stroke="var(--color-line)" strokeWidth="18" opacity={0.3} />

      {displayArcs.map((arc, i) => {
        const start = toRad(arc.startAngle * (animated ? 1 : 0))
        const end = toRad(arc.endAngle * (animated ? 1 : 0))
        const x1 = 100 + innerRadius * Math.cos(start)
        const y1 = 100 + innerRadius * Math.sin(start)
        const x2 = 100 + innerRadius * Math.cos(end)
        const y2 = 100 + innerRadius * Math.sin(end)
        const largeArc = arc.endAngle - (animated ? arc.startAngle : 0) > 180 ? 1 : 0
        const isHovered = hoveredIndex === i

        return (
          <motion.path
            key={i}
            d={`M ${x1} ${y1} A ${innerRadius} ${innerRadius} 0 ${largeArc} 1 ${x2} ${y2} L 100 100 Z`}
            fill={arc.color}
            stroke={isHovered ? 'var(--color-ink)' : 'none'}
            strokeWidth={isHovered ? 1.5 : 0}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{
              opacity: isHovered ? 1 : 0.85,
              scale: isHovered ? 1.04 : 1,
            }}
            transition={{ duration: 0.4, delay: i * 0.06, ease: 'easeOut' }}
            className="cursor-pointer"
            onMouseEnter={() => onHover(i)}
            onMouseLeave={() => onHover(null)}
            style={{ transformOrigin: '100px 100px' }}
          />
        )
      })}

      {/* Center hole with total */}
      <circle cx="100" cy="100" r={42} fill="var(--color-surface)" stroke="var(--color-line)" strokeWidth="1" />
      <text
        x="100"
        y="93"
        textAnchor="middle"
        className="fill-ink font-display font-semibold text-base"
      >
        {formatSize(totalSize)}
      </text>
      <text
        x="100"
        y="110"
        textAnchor="middle"
        className="fill-muted text-[10px] uppercase tracking-wider"
      >
        Total
      </text>
    </svg>
  )
}

function ChartTooltip({
  content,
  children,
}: {
  content: string | null
  children: React.ReactNode
}) {
  const [show, setShow] = useState(false)
  const [pos, setPos] = useState({ x: 0, y: 0 })
  const triggerRef = useRef<HTMLDivElement>(null)
  const tooltipRef = useRef<HTMLDivElement>(null)
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const reposition = useCallback(() => {
    if (!triggerRef.current || !tooltipRef.current) return
    const rect = triggerRef.current.getBoundingClientRect()
    const tw = tooltipRef.current.offsetWidth
    const th = tooltipRef.current.offsetHeight
    let x = rect.left + rect.width / 2 - tw / 2
    let y = rect.top - th - 8
    x = Math.max(12, Math.min(x, window.innerWidth - tw - 12))
    if (y < 12) y = rect.bottom + 8
    setPos({ x, y })
  }, [])

  useEffect(() => {
    if (show && content) reposition()
  }, [show, content, reposition])

  return (
    <div
      ref={triggerRef}
      onMouseEnter={() => {
        if (timeoutRef.current) clearTimeout(timeoutRef.current)
        timeoutRef.current = setTimeout(() => setShow(true), 300)
      }}
      onMouseLeave={() => {
        if (timeoutRef.current) clearTimeout(timeoutRef.current)
        setShow(false)
      }}
      className="contents"
    >
      {children}
      <AnimatePresence>
        {show && content && (
          <motion.div
            ref={tooltipRef}
            initial={{ opacity: 0, y: 4, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.96 }}
            transition={{ duration: 0.12, ease: 'easeOut' }}
            className="fixed z-999 px-3 py-1.5 rounded-lg border border-line bg-surface text-xs text-ink font-medium shadow-2xl shadow-black/50 pointer-events-none"
            style={{
              left: pos.x,
              top: pos.y,
              backdropFilter: 'blur(8px)',
              WebkitBackdropFilter: 'blur(8px)',
              maxWidth: 260,
              wordBreak: 'break-word',
            }}
          >
            {content}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export function ProjectPropertiesModal({ project, onClose }: Props) {
  const [sizeInfo, setSizeInfo] = useState<ProjectSizeInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    api.getProjectSize(project.path)
      .then((info) => {
        if (!cancelled) {
          setSizeInfo(info)
          setLoading(false)
        }
      })
      .catch((e) => {
        if (!cancelled) {
          setError(String(e))
          setLoading(false)
        }
      })
    return () => { cancelled = true }
  }, [project.path])

  const chartCategories = sizeInfo?.categories.map((c, i) => ({
    ...c,
    color: PIE_COLORS[i % PIE_COLORS.length],
  })) ?? []

  const hoveredCat = hoveredIndex !== null ? chartCategories[hoveredIndex] ?? null : null

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 16, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 16, scale: 0.95 }}
        transition={{ type: 'spring', stiffness: 360, damping: 28 }}
        className="bg-surface border border-line rounded-2xl p-8 w-full max-w-xl flex flex-col gap-7 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-accent/10 border border-accent/20 flex items-center justify-center">
              <IconHardDrive className="w-5 h-5 text-accent-bright" />
            </div>
            <div>
              <h3 className="font-display font-semibold text-lg">Project Size</h3>
              <p className="text-xs text-muted font-mono truncate max-w-sm">
                {project.name}
              </p>
            </div>
          </div>
          <motion.button
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={onClose}
            className="focus-ring cursor-pointer p-1.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors"
            aria-label="Close"
          >
            <IconX className="w-4 h-4" />
          </motion.button>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-16 gap-3">
            <div className="w-8 h-8 rounded-full border-2 border-accent/30 border-t-accent animate-spin" />
            <p className="text-sm text-muted">Scanning project files…</p>
          </div>
        ) : error ? (
          <div className="flex items-center justify-center py-16 text-danger text-sm">
            {error}
          </div>
        ) : sizeInfo ? (
          <div className="flex items-start">
            <div className="w-64 h-64 shrink-0 mt-10">
              <ChartTooltip
                content={
                  hoveredCat
                    ? `${hoveredCat.label}: ${formatSize(hoveredCat.size)} (${hoveredCat.count} files)`
                    : null
                }
              >
                <DonutChart
                  categories={chartCategories}
                  totalSize={sizeInfo.total_size}
                  hoveredIndex={hoveredIndex}
                  onHover={setHoveredIndex}
                />
              </ChartTooltip>
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-6 mb-5 pb-4 border-b border-line">
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Total Size</p>
                  <p className="text-lg font-display font-semibold text-ink mt-0.5">{formatSize(sizeInfo.total_size)}</p>
                </div>
                <div className="w-px h-8 bg-line" />
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-muted/60">Files</p>
                  <p className="text-lg font-display font-semibold text-ink mt-0.5">{sizeInfo.file_count.toLocaleString()}</p>
                </div>
              </div>

              <div className="space-y-1.5 max-h-64 overflow-y-auto pr-1">
                {chartCategories.map((cat, i) => {
                  const pct = sizeInfo.total_size > 0 ? (cat.size / sizeInfo.total_size) * 100 : 0
                  const isHovered = hoveredIndex === i
                  return (
                    <div
                      key={cat.label}
                      onMouseEnter={() => setHoveredIndex(i)}
                      onMouseLeave={() => setHoveredIndex(null)}
                      className={`group flex items-center justify-between py-1.5 px-2 mx-2 my-1 rounded-lg cursor-pointer transition-colors ${
                        isHovered ? 'bg-raised/80 ring-1 ring-accent/20' : 'hover:bg-raised/60'
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0 flex-1">
                        <span
                          className={`w-3 h-3 rounded-full shrink-0 ring-1 ring-black/10 transition-all ${
                            isHovered ? 'ring-2 ring-accent scale-125' : ''
                          }`}
                          style={{ backgroundColor: cat.color }}
                        />
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center gap-2">
                            <span className={`text-sm truncate transition-colors ${isHovered ? 'text-ink font-medium' : 'text-muted'}`}>
                              {cat.label}
                            </span>
                            <span className="text-[11px] text-muted/50 font-mono shrink-0">({cat.count})</span>
                          </div>
                          <div className="h-1 rounded-full bg-line/50 mt-1 overflow-hidden max-w-40">
                            <div
                              className="h-full rounded-full transition-all duration-500 ease-out"
                              style={{ width: `${pct}%`, backgroundColor: cat.color }}
                            />
                          </div>
                        </div>
                      </div>
                      <div className="text-right shrink-0 ml-3">
                        <p className="text-sm font-mono font-medium text-ink">{formatSize(cat.size)}</p>
                        <p className="text-[10px] text-muted/50 font-mono">{pct.toFixed(1)}%</p>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        ) : null}
      </motion.div>
    </motion.div>
  )
}
