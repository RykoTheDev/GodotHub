import type { GitLogEntry } from '../types'

export const LANE_COLORS = [
  '#5865f2',
  '#23a55a',
  '#f0b132',
  '#f23f42',
  '#eb459e',
  '#00b8d4',
  '#a855f7',
  '#10b981',
  '#f97316',
  '#e11d48',
]

export const LANE_W = 20
export const ROW_H = 44
export const DOT_R = 4.5

export function colorFor(lane: number): string {
  return LANE_COLORS[lane % LANE_COLORS.length]
}

export function shortHash(hash: string): string {
  return hash.length > 7 ? hash.slice(0, 7) : hash
}

export type LaneCell =
  | { type: 'empty' }
  | { type: 'line'; lane: number }
  | { type: 'dot'; lane: number }

export interface GraphRow {
  commit: GitLogEntry
  lane: number
  cells: LaneCell[]
  joins: number[]
}

export function buildGraphRows(commits: GitLogEntry[]): GraphRow[] {
  let tips: (string | null)[] = []
  const rows: GraphRow[] = []

  for (const commit of commits) {
    const firstParent = commit.parents[0]

    let lane = tips.findIndex((t) => t === commit.hash)
    if (lane === -1 && commit.parents.length > 1) {
      lane = tips.findIndex((t) => t === firstParent)
    }
    if (lane === -1) {
      lane = tips.length
      tips.push(commit.hash)
    }

    const closes: number[] = []
    for (let i = 0; i < tips.length; i++) {
      if (i !== lane && tips[i] === commit.hash) closes.push(i)
    }

    const cells: LaneCell[] = tips.map((tip, i) => {
      if (tip === null) return { type: 'empty' }
      if (i === lane) return { type: 'dot', lane: i }
      return { type: 'line', lane: i }
    })

    const joins: number[] = [...closes]
    for (const parent of commit.parents.slice(1)) {
      let pLane = tips.findIndex((t) => t === parent)
      if (pLane === -1) {
        pLane = tips.length
        tips.push(parent)
        cells.push({ type: 'line', lane: pLane })
      }
      joins.push(pLane)
    }

    rows.push({ commit, lane, cells, joins })

    tips[lane] = firstParent ?? null
    for (const i of closes) tips[i] = null
    while (tips.length > 0 && tips[tips.length - 1] === null) tips.pop()
  }

  return rows
}
