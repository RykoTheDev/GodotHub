import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type PointerEvent,
  type ReactNode,
  type RefObject,
} from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { IconChevronUp } from '../../lib/icons'
import { isReducedMotion } from '../../../lib/appearance'

interface OverlayScrollAreaProps {
  children: ReactNode
  className?: string
  hideThumb?: boolean
  hideTopButton?: boolean
  scrollToTopOn?: unknown
  scrollRef?: RefObject<HTMLDivElement | null>
  topButtonBottom?: string
}

interface Metrics {
  thumbHeight: number
  offset: number
  visible: boolean
}

const SHOW_AFTER = 200

export function OverlayScrollArea({
  children,
  className = '',
  hideThumb = false,
  hideTopButton = false,
  scrollToTopOn,
  scrollRef,
  topButtonBottom = 'bottom-4',
}: OverlayScrollAreaProps) {
  const { t } = useTranslation('common')
  const viewportRef = useRef<HTMLDivElement>(null)
  const trackRef = useRef<HTMLDivElement>(null)
  const rafRef = useRef(0)
  const [metrics, setMetrics] = useState<Metrics>({
    thumbHeight: 0,
    offset: 0,
    visible: false,
  })
  const [showTopBtn, setShowTopBtn] = useState(false)
  const [overlayOpen, setOverlayOpen] = useState(false)
  const overlayCountRef = useRef(0)
  const [dragging, setDragging] = useState(false)
  const draggingRef = useRef(false)
  const dragRef = useRef({ startY: 0, startScrollTop: 0 })

  const prevScrollToTopOn = useRef(scrollToTopOn)
  useEffect(() => {
    if (prevScrollToTopOn.current === scrollToTopOn) return
    prevScrollToTopOn.current = scrollToTopOn
    viewportRef.current?.scrollTo({
      top: 0,
      behavior: isReducedMotion() ? 'auto' : 'smooth',
    })
  }, [scrollToTopOn])

  const setViewport = (node: HTMLDivElement | null) => {
    viewportRef.current = node
    if (scrollRef) scrollRef.current = node
  }

  const update = useCallback(() => {
    const el = viewportRef.current
    if (!el) return
    const { scrollTop, clientHeight, scrollHeight } = el
    const maxScroll = scrollHeight - clientHeight
    setShowTopBtn(scrollTop > SHOW_AFTER)
    if (maxScroll <= 0) {
      setMetrics((m) =>
        m.visible ? { thumbHeight: 0, offset: 0, visible: false } : m,
      )
      return
    }
    const thumbHeight = Math.min(
      clientHeight,
      Math.max(32, (clientHeight / scrollHeight) * clientHeight),
    )
    const offset = (scrollTop / maxScroll) * (clientHeight - thumbHeight)
    setMetrics({ thumbHeight, offset, visible: true })
  }, [])

  useLayoutEffect(() => {
    update()
    const el = viewportRef.current
    if (!el) return
    const ro = new ResizeObserver(update)
    ro.observe(el)
    const mo = new MutationObserver(update)
    mo.observe(el, { childList: true, subtree: true })
    return () => {
      ro.disconnect()
      mo.disconnect()
    }
  }, [update])

  useEffect(() => () => cancelAnimationFrame(rafRef.current), [])

  useEffect(() => {
    const open = () => {
      overlayCountRef.current += 1
      setOverlayOpen(true)
    }
    const close = () => {
      overlayCountRef.current = Math.max(0, overlayCountRef.current - 1)
      if (overlayCountRef.current === 0) setOverlayOpen(false)
    }
    window.addEventListener('app:dropdown-open', open)
    window.addEventListener('app:dropdown-close', close)
    window.addEventListener('app:dialog-open', open)
    window.addEventListener('app:dialog-close', close)
    return () => {
      window.removeEventListener('app:dropdown-open', open)
      window.removeEventListener('app:dropdown-close', close)
      window.removeEventListener('app:dialog-open', open)
      window.removeEventListener('app:dialog-close', close)
    }
  }, [])

  const handleScroll = () => {
    if (rafRef.current) return
    rafRef.current = requestAnimationFrame(() => {
      rafRef.current = 0
      update()
    })
  }

  const handleTrackDown = (e: PointerEvent<HTMLDivElement>) => {
    const el = viewportRef.current
    const track = trackRef.current
    if (!el || !track || !metrics.visible) return
    e.preventDefault()
    const { clientHeight, scrollHeight } = el
    const maxScroll = scrollHeight - clientHeight
    const travel = clientHeight - metrics.thumbHeight
    if (maxScroll <= 0 || travel <= 0) return
    const rect = track.getBoundingClientRect()
    const y = e.clientY - rect.top
    const target =
      ((y - metrics.thumbHeight / 2) / travel) * maxScroll
    el.scrollTop = Math.min(maxScroll, Math.max(0, target))
    e.currentTarget.setPointerCapture(e.pointerId)
    dragRef.current = { startY: e.clientY, startScrollTop: el.scrollTop }
    draggingRef.current = true
    setDragging(true)
  }

  const moveDrag = (e: PointerEvent<HTMLDivElement>) => {
    if (!draggingRef.current) return
    if (e.buttons === 0) {
      endDrag(e)
      return
    }
    const el = viewportRef.current
    if (!el) return
    const { clientHeight, scrollHeight } = el
    const maxScroll = scrollHeight - clientHeight
    const travel = clientHeight - metrics.thumbHeight
    if (maxScroll <= 0 || travel <= 0) return
    const dy = e.clientY - dragRef.current.startY
    el.scrollTop = dragRef.current.startScrollTop + (dy / travel) * maxScroll
  }

  const endDrag = (e: PointerEvent<HTMLDivElement>) => {
    if (!draggingRef.current) return
    draggingRef.current = false
    setDragging(false)
    try {
      e.currentTarget.releasePointerCapture(e.pointerId)
    } catch {
    }
  }

  const scrollToTop = () => {
    viewportRef.current?.scrollTo({
      top: 0,
      behavior: isReducedMotion() ? 'auto' : 'smooth',
    })
  }

  const showThumb = metrics.visible && !hideThumb

  return (
    <div className={`relative overflow-hidden ${className}`}>
      <div
        ref={setViewport}
        onScroll={handleScroll}
        className="new-ui-scroll-viewport h-full overflow-y-scroll overflow-x-hidden"
      >
        {children}
      </div>
      <div
        ref={trackRef}
        onPointerDown={handleTrackDown}
        onPointerMove={moveDrag}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
        className={`absolute inset-y-0 right-0 w-3.5 flex justify-center group ${
          showThumb
            ? dragging
              ? 'cursor-grabbing'
              : 'cursor-pointer'
            : 'pointer-events-none'
        }`}
      >
        <div
          style={{
            height: metrics.thumbHeight || undefined,
            transform: `translateY(${metrics.offset}px)`,
            opacity: showThumb ? 1 : 0,
          }}
          className={`w-[5px] rounded-full pointer-events-none transition-[opacity,background-color] duration-200 ease-out ${
            dragging
              ? 'bg-accent shadow-md shadow-accent/40'
              : 'bg-line group-hover:bg-accent-dim'
          }`}
        />
      </div>

      <AnimatePresence>
        {!hideTopButton && showTopBtn && !overlayOpen && (
          <motion.button
            key="scroll-to-top"
            type="button"
            aria-label={t('scroll_to_top')}
            onClick={scrollToTop}
            initial={{ opacity: 0, y: 12, scale: 0.85 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 12, scale: 0.85 }}
            transition={{ type: 'spring', stiffness: 420, damping: 28 }}
            className={`focus-ring cursor-pointer absolute left-1/2 -translate-x-1/2 z-30 inline-flex items-center gap-1.5 h-9 px-4 rounded-full bg-raised border border-outline/50 text-muted shadow-lg shadow-black/40 transition-colors duration-150 hover:text-ink hover:border-accent-dim/70 hover:bg-overlay ${topButtonBottom}`}
          >
            <IconChevronUp className="w-3.5 h-3.5" />
            <span className="text-xs font-medium">{t('scroll_to_top')}</span>
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  )
}
