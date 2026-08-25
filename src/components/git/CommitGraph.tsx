import { useMemo } from 'react'
import { openUrl } from '@tauri-apps/plugin-opener'
import { useTranslation } from 'react-i18next'
import {
  LANE_W,
  ROW_H,
  DOT_R,
  colorFor,
  shortHash,
  buildGraphRows,
  type GraphRow,
} from '../../lib/gitGraph'
import type { GitLogEntry } from '../../types'


interface Props {
  commits: GitLogEntry[]
  remoteUrl?: string | null
  onOpenDetails?: (hash: string) => void
}

function RowGraph({ row }: { row: GraphRow }) {
  const cols = Math.max(1, row.cells.length)
  return (
    <svg width={cols * LANE_W} height={ROW_H} className="shrink-0">
      {row.cells.map((cell, i) => {
        if (cell.type === 'empty') return null
        const x = i * LANE_W + LANE_W / 2
        const color = colorFor(cell.lane)
        const isDot = cell.type === 'dot'
        return (
          <g key={i}>
            <line
              x1={x}
              y1={0}
              x2={x}
              y2={ROW_H}
              stroke={color}
              strokeWidth={1.6}
              opacity={isDot ? 0.9 : 0.45}
            />
            {isDot && (
              <circle
                cx={x}
                cy={ROW_H / 2}
                r={DOT_R}
                fill={color}
                stroke="var(--color-surface)"
                strokeWidth={2}
              />
            )}
          </g>
        )
      })}
      {row.joins.length > 0 && (
        <g>
          {row.joins.map((j) => {
            const x1 = row.lane * LANE_W + LANE_W / 2
            const x2 = j * LANE_W + LANE_W / 2
            return (
              <line
                key={`join-${j}`}
                x1={x1}
                y1={ROW_H / 2}
                x2={x2}
                y2={ROW_H / 2}
                stroke={colorFor(j)}
                strokeWidth={1.6}
                opacity={0.45}
              />
            )
          })}
        </g>
      )}
    </svg>
  )
}

export function CommitGraph({ commits, remoteUrl, onOpenDetails }: Props) {
  const { t } = useTranslation('git')
  const rows = useMemo(() => buildGraphRows(commits), [commits])

  if (commits.length === 0) {
    return (
      <div className="px-3 py-2.5">
        <span className="text-[11px] text-muted/50">
          {t('no_commits_found')}
        </span>
      </div>
    )
  }

  const baseUrl = remoteUrl ? remoteUrl.replace(/\/+$/, '') : null

  return (
    <div className="w-full overflow-x-auto new-ui-scroll-viewport">
      <div className="flex flex-col min-w-max">
        {rows.map((row) => {
          const c = row.commit
          const url = baseUrl ? `${baseUrl}/commit/${c.hash}` : null
          return (
            <div key={c.hash} className="flex items-center gap-1.5">
              <RowGraph row={row} />
                <div
                  onClick={() => {
                    if (onOpenDetails) {
                      onOpenDetails(c.hash)
                    } else if (url) {
                      void openUrl(url).catch(() => {})
                    }
                  }}
                  className={`flex items-center gap-2 pr-2 rounded-md transition-colors ${
                    onOpenDetails || url
                      ? 'cursor-pointer hover:bg-raised/60'
                      : 'cursor-default'
                  }`}
                  style={{ height: ROW_H }}
                >
                  <span className="font-mono text-[10px] font-semibold text-accent-bright shrink-0">
                    {shortHash(c.hash)}
                  </span>
                  <div className="min-w-0 flex-1 max-w-[180px]">
                    <p className="text-xs text-ink truncate leading-snug">
                      {c.message}
                    </p>
                    {(c.author || c.date) && (
                      <p className="text-[10px] text-muted truncate mt-0.5">
                        {[c.author, c.date].filter(Boolean).join(' · ')}
                      </p>
                    )}
                  </div>
                </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
