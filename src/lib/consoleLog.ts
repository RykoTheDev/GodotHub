import type { ConsoleLine } from '../types'

export type ConsoleLevel = 'error' | 'warning' | 'info'

export const CONSOLE_LEVELS: ConsoleLevel[] = ['error', 'warning', 'info']

const WARNING_PATTERN = /\b(warn|warning|warnings|deprecated|inconsistent)\b/i
const ERROR_PATTERN =
  /\b(error|errors|failed|failure|fatal|exception|crash|crashed|broken|unable|cannot|can't|refused|denied)\b/i

const levelCache = new WeakMap<ConsoleLine, ConsoleLevel>()

function detectLevel(line: ConsoleLine): ConsoleLevel {
  if (WARNING_PATTERN.test(line.text)) return 'warning'
  if (ERROR_PATTERN.test(line.text)) return 'error'
  return line.stream === 'stderr' ? 'error' : 'info'
}

export function classifyConsoleLine(line: ConsoleLine): ConsoleLevel {
  const cached = levelCache.get(line)
  if (cached) return cached
  const level = detectLevel(line)
  levelCache.set(line, level)
  return level
}

export interface ConsoleEntry {
  line: ConsoleLine
  level: ConsoleLevel
}

const STACK_FRAME_PATTERN = /^\s*at:/

export function annotateConsoleLines(lines: ConsoleLine[]): ConsoleEntry[] {
  let carried: ConsoleLevel | null = null
  return lines.map((line) => {
    const level =
      carried && STACK_FRAME_PATTERN.test(line.text)
        ? carried
        : classifyConsoleLine(line)
    carried = level
    return { line, level }
  })
}

export function countConsoleLevels(
  entries: ConsoleEntry[],
): Record<ConsoleLevel, number> {
  const counts: Record<ConsoleLevel, number> = {
    error: 0,
    warning: 0,
    info: 0,
  }
  for (const entry of entries) counts[entry.level] += 1
  return counts
}
