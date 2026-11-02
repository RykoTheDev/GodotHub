import { useLayoutEffect, useRef, useState, type ReactNode } from 'react'
import { IconChevronRight } from '../../lib/icons'
import { isRtl } from '../../lib/locale'
import { busy, ease, gsap } from '../../lib/motion'

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
      const items = innerRef.current ? (Array.from(innerRef.current.children) as HTMLElement[]).slice(0, 16) : []
      const release = busy(el)
      gsap.fromTo(
        el,
        { height: start, opacity: start ? gsap.getProperty(el, 'opacity') : 0 },
        { height: 'auto', opacity: 1, duration: 0.4, ease: ease.out, lazy: false, clearProps: 'height,opacity', onComplete: release, onInterrupt: release },
      )
      if (items.length && !start) {
        const releaseItems = busy(...items)
        gsap.fromTo(
          items,
          { y: -6, opacity: 0 },
          {
            y: 0,
            opacity: 1,
            duration: 0.32,
            stagger: { amount: Math.min(0.1, items.length * 0.012) },
            ease: ease.out,
            lazy: false,
            clearProps: 'opacity,transform',
            onComplete: releaseItems,
            onInterrupt: releaseItems,
          },
        )
      }
    } else {
      closing.current = true
      const release = busy(el)
      gsap.to(el, {
        height: 0,
        opacity: 0,
        duration: 0.26,
        ease: 'power3.out',
        onInterrupt: release,
        onComplete: () => {
          closing.current = false
          el.hidden = true
          setShown(false)
          gsap.set(el, { clearProps: 'height,opacity' })
          release()
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
