export type LastOpenedTimeFormat = '12h' | '24h'
export type LastOpenedDateFormat = 'DD-MM-YYYY' | 'MM-DD-YYYY' | 'YYYY-MM-DD'

function pad2(n: number): string {
  return n < 10 ? `0${n}` : `${n}`
}

function formatTime(date: Date, timeFormat: LastOpenedTimeFormat): string {
  let hours = date.getHours()
  const minutes = pad2(date.getMinutes())

  if (timeFormat === '24h') {
    return `${pad2(hours)}:${minutes}`
  }

  const suffix = hours >= 12 ? 'PM' : 'AM'
  hours = hours % 12
  if (hours === 0) hours = 12
  return `${hours}:${minutes} ${suffix}`
}

function formatDate(date: Date, dateFormat: LastOpenedDateFormat): string {
  const day = pad2(date.getDate())
  const month = pad2(date.getMonth() + 1)
  const year = date.getFullYear()

  switch (dateFormat) {
    case 'MM-DD-YYYY':
      return `${month}-${day}-${year}`
    case 'YYYY-MM-DD':
      return `${year}-${month}-${day}`
    case 'DD-MM-YYYY':
    default:
      return `${day}-${month}-${year}`
  }
}

function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

export function formatLastOpened(
  lastOpened: string | null | undefined,
  timeFormat: LastOpenedTimeFormat = '12h',
  dateFormat: LastOpenedDateFormat = 'DD-MM-YYYY',
): string | null {
  if (!lastOpened) return null

  const date = new Date(lastOpened)
  if (isNaN(date.getTime())) return null

  const now = new Date()
  return isSameDay(date, now)
    ? formatTime(date, timeFormat)
    : formatDate(date, dateFormat)
}
