import { useLayoutEffect, useRef, type ReactNode } from 'react'
import { useUiMotion } from '../../hooks/useUiMotion'
import { disclosureMotion } from '../../lib/motion'
import { IconChevronRight } from '../../lib/icons'
import { isRtl } from '../../lib/locale'

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
  const { instant, reduced } = useUiMotion()
  const panel = useRef<HTMLDivElement>(null)
  const content = useRef<HTMLDivElement>(null)
  const initialOpen = useRef(open)
  const mounted = useRef(false)
  const previousOpen = useRef(open)
  const animateRef = useRef(animate)
  animateRef.current = animate

  useLayoutEffect(() => {
    const element = panel.current
    const inner = content.current
    if (!element || !inner) return
    const changed = previousOpen.current !== open
    previousOpen.current = open
    let observer: ResizeObserver | undefined
    let timer: ReturnType<typeof setTimeout> | undefined
    let finished = false
    const finish = () => {
      finished = true
      observer?.disconnect()
      window.clearTimeout(timer)
      element.style.height = open ? 'auto' : '0px'
      element.style.opacity = open ? '1' : '0'
    }
    if (!mounted.current || !changed || !animateRef.current || instant || reduced) {
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
    const fallback = () => {
      window.clearTimeout(timer)
      // Actual completion comes from transitionend; this only covers cancelled
      // transitions and hidden windows, rather than cutting the last frame off.
      timer = window.setTimeout(finish, durationMs * 2)
    }
    if (open) {
      observer = new ResizeObserver(() => {
        if (finished) return
        const height = `${inner.getBoundingClientRect().height}px`
        if (element.style.height !== height) { element.style.height = height; fallback() }
      })
      observer.observe(inner)
    }
    const completed = (event: TransitionEvent) => {
      if (event.target === element && event.propertyName === 'height') finish()
    }
    element.addEventListener('transitionend', completed)
    fallback()
    return () => {
      element.removeEventListener('transitionend', completed)
      window.clearTimeout(timer)
      observer?.disconnect()
    }
  }, [open, instant, reduced])

  return (
    <div ref={panel} id={id} inert={!open} aria-hidden={!open}
      className="overflow-hidden"
      style={{ height: initialOpen.current ? 'auto' : 0, opacity: initialOpen.current ? 1 : 0 }}>
      <div ref={content} className={className}>{children}</div>
    </div>
  )
}

export function TemplateDisclosureChevron({ open, animate }: Pick<Props, 'open' | 'animate'>) {
  const { instant, reduced } = useUiMotion()
  const { durationMs, easing } = disclosureMotion
  return (
    <span aria-hidden="true" className="inline-flex shrink-0 text-muted"
      style={{ transform: open ? (isRtl() ? 'rotate(-90deg)' : 'rotate(90deg)') : 'rotate(0deg)',
        transition: animate && !instant && !reduced ? `transform ${durationMs}ms ${easing}` : 'none' }}>
      <IconChevronRight className="w-3 h-3 rtl:rotate-180" />
    </span>
  )
}
