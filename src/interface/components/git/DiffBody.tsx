import type { GitDiffResult } from '../../../types'

export function DiffBody({ diff }: { diff: GitDiffResult }) {
  return (
    <div className="py-2 text-[12px] font-mono leading-5">
      {diff.hunks.map((h, hi) => (
        <div key={hi}>
          <div className="px-4 py-1 text-[11px] font-medium text-accent-bright bg-accent/5 border-y border-accent/10">
            @@ -{h.old_start},{h.old_lines} +{h.new_start},{h.new_lines} @@
          </div>
          {(() => {
            let oldLn = h.old_start
            let newLn = h.new_start
            return h.lines.map((l, li) => {
              const isAdd = l.kind === 'add'
              const isDel = l.kind === 'delete'
              const oldNum = !isAdd ? oldLn : null
              const newNum = !isDel ? newLn : null
              if (isDel) oldLn += 1
              else if (isAdd) newLn += 1
              else {
                oldLn += 1
                newLn += 1
              }
              return (
                <div
                  key={li}
                  className={`flex items-stretch px-4 ${
                    isAdd ? 'bg-mint/5' : isDel ? 'bg-danger/5' : ''
                  }`}
                >
                  <span className="w-10 shrink-0 text-right pr-3 text-muted/40 select-none">
                    {oldNum ?? ''}
                  </span>
                  <span className="w-10 shrink-0 text-right pr-3 text-muted/40 select-none">
                    {newNum ?? ''}
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
                    {l.content}
                  </span>
                </div>
              )
            })
          })()}
        </div>
      ))}
    </div>
  )
}
