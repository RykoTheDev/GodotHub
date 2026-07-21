interface Props {
  tag: string
  state?: 'installed' | 'available' | 'downloading' | 'unbound'
  customName?: string | null
}

const dotColor = {
  installed: 'bg-mint',
  available: 'bg-muted',
  downloading: 'bg-amber',
  unbound: 'bg-line',
} as const

export function VersionBadge({ tag, state = 'available', customName }: Props) {
  return (
    <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-raised border border-line font-mono text-xs text-ink">
      <span
        className={`w-1.5 h-1.5 rounded-full ${dotColor[state]} ${state === 'downloading' ? 'animate-pulse' : ''}`}
      />
      {customName ? (
        <>
          {customName}
          <span className="text-muted">({tag || 'unbound'})</span>
        </>
      ) : (
        tag || 'unbound'
      )}
    </span>
  )
}
