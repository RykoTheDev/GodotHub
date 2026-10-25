import { useEffect, useMemo, useRef, useState } from 'react'
import type { GitDiffResult } from '../../types'

const LINE_HEIGHT = 20
const HEADER_HEIGHT = 28
const OVERSCAN_PX = 800
const WINDOW_THRESHOLD = 600

type DiffRow =
  | { type: 'header'; text: string }
  | { type: 'line'; kind: string; content: string; oldNum: number | null; newNum: number | null }

function buildRows(diff: GitDiffResult): DiffRow[] {
  const rows: DiffRow[] = []
  for (const h of diff.hunks) {
    rows.push({
      type: 'header',
      text: `@@ -${h.old_start},${h.old_lines} +${h.new_start},${h.new_lines} @@`,
    })
    let oldLn = h.old_start
    let newLn = h.new_start
    for (const l of h.lines) {
      const isAdd = l.kind === 'add'
      const isDel = l.kind === 'delete'
      rows.push({
        type: 'line',
        kind: l.kind,
        content: l.content,
        oldNum: !isAdd ? oldLn : null,
        newNum: !isDel ? newLn : null,
      })
      if (isDel) oldLn += 1
      else if (isAdd) newLn += 1
      else {
        oldLn += 1
        newLn += 1
      }
    }
  }
  return rows
}

function scrollParent(el: HTMLElement | null): HTMLElement | null {
  let node = el?.parentElement ?? null
  while (node) {
    const overflowY = getComputedStyle(node).overflowY
    if (overflowY === 'auto' || overflowY === 'scroll') return node
    node = node.parentElement
  }
  return null
}

function rowHeight(row: DiffRow): number {
  return row.type === 'header' ? HEADER_HEIGHT : LINE_HEIGHT
}

function DiffRowView({ row }: { row: DiffRow }) {
  if (row.type === 'header') {
    return (
      <div className="flex h-7 items-center px-4 text-[11px] font-medium text-accent-bright bg-accent/5 border-y border-accent/10">
        {row.text}
      </div>
    )
  }
  const isAdd = row.kind === 'add'
  const isDel = row.kind === 'delete'
  return (
    <div
      className={`flex h-5 items-stretch px-4 ${
        isAdd ? 'bg-mint/5' : isDel ? 'bg-danger/5' : ''
      }`}
    >
      <span className="w-10 shrink-0 text-end pe-3 text-muted/40 select-none">
        {row.oldNum ?? ''}
      </span>
      <span className="w-10 shrink-0 text-end pe-3 text-muted/40 select-none">
        {row.newNum ?? ''}
      </span>
      <span
        className={`w-4 shrink-0 select-none ${
          isAdd
            ? 'text-mint'
            : isDel
              ? 'text-danger'
              : 'text-muted/30'
        }`}
      >
        {isAdd ? '+' : isDel ? '-' : ' '}
      </span>
      <span className="flex-1 min-w-0 whitespace-pre text-ink/90">
        {row.content}
      </span>
    </div>
  )
}

export function DiffBody({ diff }: { diff: GitDiffResult }) {
  const rows = useMemo(() => buildRows(diff), [diff])
  const windowed = rows.length > WINDOW_THRESHOLD
  const offsets = useMemo(() => {
    const result = new Array<number>(rows.length + 1)
    result[0] = 0
    for (let i = 0; i < rows.length; i++) result[i + 1] = result[i] + rowHeight(rows[i])
    return result
  }, [rows])
  const containerRef = useRef<HTMLDivElement>(null)
  const [range, setRange] = useState<[number, number]>([0, Math.min(rows.length, 200)])

  useEffect(() => {
    if (!windowed) return
    const container = containerRef.current
    const scroller = scrollParent(container)
    if (!container || !scroller) {
      setRange([0, rows.length])
      return
    }
    const findIndex = (y: number) => {
      let lo = 0
      let hi = rows.length
      while (lo < hi) {
        const mid = (lo + hi) >> 1
        if (offsets[mid + 1] <= y) lo = mid + 1
        else hi = mid
      }
      return lo
    }
    let frame = 0
    const update = () => {
      frame = 0
      const top =
        scroller.getBoundingClientRect().top - container.getBoundingClientRect().top
      const start = findIndex(Math.max(0, top - OVERSCAN_PX))
      const end = Math.min(rows.length, findIndex(top + scroller.clientHeight + OVERSCAN_PX) + 1)
      setRange((prev) => (prev[0] === start && prev[1] === end ? prev : [start, end]))
    }
    const schedule = () => {
      if (!frame) frame = requestAnimationFrame(update)
    }
    update()
    scroller.addEventListener('scroll', schedule, { passive: true })
    const observer = new ResizeObserver(schedule)
    observer.observe(scroller)
    return () => {
      if (frame) cancelAnimationFrame(frame)
      scroller.removeEventListener('scroll', schedule)
      observer.disconnect()
    }
  }, [windowed, rows, offsets])

  if (!windowed) {
    return (
      <div className="py-2 text-[12px] font-mono leading-5">
        {rows.map((row, i) => (
          <DiffRowView key={i} row={row} />
        ))}
      </div>
    )
  }

  const [start, end] = range
  return (
    <div ref={containerRef} className="py-2 text-[12px] font-mono leading-5">
      <div style={{ height: offsets[start] }} />
      {rows.slice(start, end).map((row, i) => (
        <DiffRowView key={start + i} row={row} />
      ))}
      <div style={{ height: offsets[rows.length] - offsets[end] }} />
    </div>
  )
}
