import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useWorkspaces } from '../../hooks/useWorkspaces'
import { getWorkspaceIcon } from '../../lib/workspaceIcons'
import { ease, gsap, motionOff } from '../../lib/motion'
import type { Workspace } from '../../types'

const HOLD_SECONDS = 1.1

export function WorkspaceSwitchNotice() {
  const { t } = useTranslation('common')
  const { workspaces, activeId } = useWorkspaces()
  const previousId = useRef<string | null>(null)
  const cardRef = useRef<HTMLDivElement>(null)
  const [notice, setNotice] = useState<{ workspace: Workspace; key: number } | null>(null)

  useEffect(() => {
    if (!activeId) return
    const previous = previousId.current
    previousId.current = activeId
    if (!previous || previous === activeId) return
    const workspace = workspaces.find((w) => w.id === activeId)
    if (workspace) setNotice((current) => ({ workspace, key: (current?.key ?? 0) + 1 }))
  }, [activeId, workspaces])

  useLayoutEffect(() => {
    const card = cardRef.current
    if (!notice || !card) return
    const hide = () => setNotice(null)
    if (motionOff()) {
      const id = window.setTimeout(hide, (HOLD_SECONDS + 0.4) * 1000)
      return () => window.clearTimeout(id)
    }
    const tl = gsap.timeline({ onComplete: hide })
    tl.fromTo(card, { opacity: 0, scale: 0.9, y: 12 }, { opacity: 1, scale: 1, y: 0, duration: 0.4, ease: ease.spring })
    tl.to(card, { opacity: 0, scale: 0.96, y: -8, duration: 0.3, ease: ease.in }, `+=${HOLD_SECONDS}`)
    return () => {
      tl.kill()
    }
  }, [notice])

  if (!notice) return null
  const Icon = getWorkspaceIcon(notice.workspace.icon)

  return (
    <div
      data-motion="none"
      role="status"
      aria-live="polite"
      className="pointer-events-none fixed inset-0 z-[90] flex items-center justify-center"
    >
      <div
        key={notice.key}
        ref={cardRef}
        className="flex flex-col items-center gap-3 px-10 py-7 rounded-card bg-raised border border-outline/50 shadow-2xl shadow-black/40"
      >
        <span className="w-12 h-12 rounded-full bg-overlay border border-outline/50 flex items-center justify-center text-ink">
          <Icon className="w-5 h-5" />
        </span>
        <span className="text-3xs font-semibold uppercase tracking-[0.25em] text-muted">
          {t('workspace_switched_to')}
        </span>
        <span className="max-w-[60vw] truncate font-display font-bold text-3xl tracking-tight text-ink">
          {notice.workspace.name}
        </span>
      </div>
    </div>
  )
}
