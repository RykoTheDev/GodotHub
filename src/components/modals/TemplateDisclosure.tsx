import { useLayoutEffect, useRef, type ReactNode } from 'react'
import { isReducedMotion } from '../../lib/appearance'
import { disclosureMotion } from '../../lib/motion'
import { IconChevronRight } from '../../lib/icons'

interface Props {
  id: string
  open: boolean
  animate: boolean
  className?: string
  children: ReactNode
}

/** Measure explicit heights so transitions can reverse from their current
 * position. Open panels return to natural height for nested disclosures. */
export function TemplateDisclosure({ id, open, animate, className, children }: Props) {
  const panel = useRef<HTMLDivElement>(null)
  const content = useRef<HTMLDivElement>(null)
  const initialOpen = useRef(open)
  const mounted = useRef(false)
  const animateRef = useRef(animate)
  animateRef.current = animate

  useLayoutEffect(() => {
    const element = panel.current
    const inner = content.current
    if (!element || !inner) return
    const finish = () => {
      element.style.height = open ? 'auto' : '0px'
      element.style.opacity = open ? '1' : '0'
    }
    if (!mounted.current || !animateRef.current || isReducedMotion()) {
      mounted.current = true
      element.style.transition = 'none'
      finish()
      return
    }
    const height = element.getBoundingClientRect().height
    const opacity = getComputedStyle(element).opacity
    element.style.transition = 'none'
    element.style.height = `${height}px`
    element.style.opacity = opacity
    // Commit the current frame before retargeting, including interrupted exits.
    void element.offsetHeight
    const { durationMs, easing } = disclosureMotion
    element.style.transition = `height ${durationMs}ms ${easing}, opacity ${durationMs}ms ${easing}`
    element.style.height = open ? `${inner.getBoundingClientRect().height}px` : '0px'
    element.style.opacity = open ? '1' : '0'
    const completed = (event: TransitionEvent) => {
      if (event.target === element && event.propertyName === 'height') finish()
    }
    element.addEventListener('transitionend', completed)
    const timer = window.setTimeout(finish, durationMs)
    return () => {
      element.removeEventListener('transitionend', completed)
      window.clearTimeout(timer)
    }
  }, [open])

  return (
    <div ref={panel} id={id} inert={!open} aria-hidden={!open}
      className="overflow-hidden"
      style={{ height: initialOpen.current ? 'auto' : 0, opacity: initialOpen.current ? 1 : 0 }}>
      <div ref={content} className={className}>{children}</div>
    </div>
  )
}

export function TemplateDisclosureChevron({ open, animate }: Pick<Props, 'open' | 'animate'>) {
  const { durationMs, easing } = disclosureMotion
  return (
    <span aria-hidden="true" className="inline-flex shrink-0 text-muted"
      style={{ transform: open ? 'rotate(90deg)' : 'rotate(0deg)',
        transition: animate && !isReducedMotion() ? `transform ${durationMs}ms ${easing}` : 'none' }}>
      <IconChevronRight className="w-3 h-3" />
    </span>
  )
}
