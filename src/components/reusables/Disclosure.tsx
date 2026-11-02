import { useLayoutEffect, useRef, useState, type ReactNode } from 'react'
import { IconChevronRight } from '../../lib/icons'
import { isRtl } from '../../lib/locale'
import { ease, gsap } from '../../lib/motion'

interface Props {
  id: string
  open: boolean
  className?: string
  children: ReactNode
}

export function Disclosure({ id, open, className, children }: Props) {
  const ref = useRef<HTMLDivElement>(null)
  const innerRef = useRef<HTMLDivElement>(null)
  const prevOpen = useRef(open)
  const closing = useRef(false)
  const [shown, setShown] = useState(open)
  if (open && !shown) setShown(true)

  useLayoutEffect(() => {
    const el = ref.current
    if (!el || prevOpen.current === open) return
    prevOpen.current = open
    gsap.killTweensOf(el)
    if (open) {
      const start = closing.current ? el.offsetHeight : 0
      closing.current = false
      gsap.fromTo(
        el,
        { height: start, opacity: start ? gsap.getProperty(el, 'opacity') : 0 },
        { height: 'auto', opacity: 1, duration: 0.5, ease: ease.out, clearProps: 'height,opacity' },
      )
      const items = innerRef.current ? Array.from(innerRef.current.children).slice(0, 16) : []
      if (items.length && !start) {
        gsap.from(items, { y: -8, opacity: 0, duration: 0.45, stagger: 0.03, ease: ease.out, clearProps: 'opacity,transform' })
      }
    } else {
      closing.current = true
      gsap.to(el, {
        height: 0,
        opacity: 0,
        duration: 0.32,
        ease: 'power3.inOut',
        onComplete: () => {
          closing.current = false
          setShown(false)
          gsap.set(el, { clearProps: 'height,opacity' })
        },
      })
    }
  }, [open])

  return (
    <div ref={ref} id={id} hidden={!shown} className="overflow-hidden">
      <div ref={innerRef} className={className}>{children}</div>
    </div>
  )
}

export function DisclosureChevron({ open }: Pick<Props, 'open'>) {
  return (
    <span
      aria-hidden="true"
      className="inline-flex shrink-0 text-muted transition-transform duration-500 ease-spring"
      style={{ transform: open ? (isRtl() ? 'rotate(-90deg)' : 'rotate(90deg)') : 'rotate(0deg)' }}
    >
      <IconChevronRight className="w-3 h-3 rtl:rotate-180" />
    </span>
  )
}
