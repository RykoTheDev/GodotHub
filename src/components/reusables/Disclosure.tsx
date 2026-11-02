import type { ReactNode } from 'react'
import { IconChevronRight } from '../../lib/icons'
import { isRtl } from '../../lib/locale'

interface Props {
  id: string
  open: boolean
  className?: string
  children: ReactNode
}

export function Disclosure({ id, open, className, children }: Props) {
  return (
    <div id={id} hidden={!open} className="overflow-hidden">
      <div className={className}>{children}</div>
    </div>
  )
}

export function DisclosureChevron({ open }: Pick<Props, 'open'>) {
  return (
    <span
      aria-hidden="true"
      className="inline-flex shrink-0 text-muted"
      style={{ transform: open ? (isRtl() ? 'rotate(-90deg)' : 'rotate(90deg)') : 'rotate(0deg)' }}
    >
      <IconChevronRight className="w-3 h-3 rtl:rotate-180" />
    </span>
  )
}
