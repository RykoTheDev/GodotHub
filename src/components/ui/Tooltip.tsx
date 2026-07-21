import { useRef, useState, useCallback, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useSettings } from '../../hooks/useSettings'

interface TooltipProps {
  content: string
  children: React.ReactNode
  side?: 'top' | 'bottom' | 'right'
  className?: string
  maxWidth?: number
  delay?: number
}

const MAX_TOOLTIP_WIDTH = 320
const VIEWPORT_PADDING = 14
const CURSOR_GAP = 12
const FOLLOW_SMOOTHING = 0.18
const DEFAULT_DELAY = 350

export function Tooltip({ content, children, side: sideProp, className, maxWidth = MAX_TOOLTIP_WIDTH, delay: delayProp }: TooltipProps) {
  const { settings } = useSettings()
  const delay = delayProp ?? settings.tooltip_delay ?? DEFAULT_DELAY
  const [show, setShow] = useState(false)
  const [shimmerDone, setShimmerDone] = useState(false)
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const mousePosRef = useRef({ x: 0, y: 0 })
  const tooltipRef = useRef<HTMLDivElement>(null)
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const animationFrameRef = useRef<number>(0)
  const currentPosRef = useRef({ x: 0, y: 0 })
  const targetPosRef = useRef({ x: 0, y: 0 })
  const sideRef = useRef<'top' | 'bottom' | 'right'>('bottom')

  const pickSide = useCallback((mx: number, my: number, tw: number, th: number) => {
    if (sideProp) return sideProp

    const spaceRight = window.innerWidth - mx - VIEWPORT_PADDING - CURSOR_GAP
    const spaceBelow = window.innerHeight - my - VIEWPORT_PADDING - CURSOR_GAP
    const spaceAbove = my - VIEWPORT_PADDING - CURSOR_GAP

    if (spaceRight >= tw + CURSOR_GAP && spaceRight > spaceBelow && spaceRight > spaceAbove) {
      return 'right' as const
    }
    if (spaceBelow >= th + CURSOR_GAP || spaceBelow >= spaceAbove) {
      return 'bottom' as const
    }
    return 'top' as const
  }, [sideProp])

  const calcTarget = useCallback((mx: number, my: number) => {
    if (!tooltipRef.current) return { x: mx, y: my }
    const th = tooltipRef.current.offsetHeight
    const tw = tooltipRef.current.offsetWidth
    const side = pickSide(mx, my, tw, th)
    sideRef.current = side

    let x: number
    let y: number

    if (side === 'right') {
      x = mx + CURSOR_GAP
      y = my - th / 2
    } else if (side === 'top') {
      x = mx - tw / 2
      y = my - th - CURSOR_GAP
    } else {
      x = mx - tw / 2
      y = my + CURSOR_GAP
    }

    const maxX = window.innerWidth - tw - VIEWPORT_PADDING
    const maxY = window.innerHeight - th - VIEWPORT_PADDING
    x = Math.max(VIEWPORT_PADDING, Math.min(x, maxX))
    y = Math.max(VIEWPORT_PADDING, Math.min(y, maxY))

    return { x, y }
  }, [pickSide])

  const startLerp = useCallback(() => {
    if (animationFrameRef.current) cancelAnimationFrame(animationFrameRef.current)

    const tick = () => {
      const cp = currentPosRef.current
      const tp = targetPosRef.current

      const dx = tp.x - cp.x
      const dy = tp.y - cp.y
      const dist = Math.sqrt(dx * dx + dy * dy)

      if (dist < 0.5) {
        currentPosRef.current = { ...tp }
        setPosition({ ...tp })
        animationFrameRef.current = 0
        return
      }

      const ease = Math.min(FOLLOW_SMOOTHING * (dist / 30 + 0.6), 0.45)
      currentPosRef.current = {
        x: cp.x + dx * ease,
        y: cp.y + dy * ease,
      }
      setPosition({ ...currentPosRef.current })
      animationFrameRef.current = requestAnimationFrame(tick)
    }

    animationFrameRef.current = requestAnimationFrame(tick)
  }, [])

  const updateTarget = useCallback(() => {
    const target = calcTarget(mousePosRef.current.x, mousePosRef.current.y)
    targetPosRef.current = target
    if (!animationFrameRef.current) startLerp()
  }, [calcTarget, startLerp])

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    const dx = e.clientX - mousePosRef.current.x
    const dy = e.clientY - mousePosRef.current.y
    if (Math.abs(dx) < 2 && Math.abs(dy) < 2) return
    mousePosRef.current = { x: e.clientX, y: e.clientY }
    if (!show) return
    updateTarget()
  }, [show, updateTarget])

  const handleMouseEnter = useCallback(() => {
    timeoutRef.current = setTimeout(() => {
      mousePosRef.current = { ...mousePosRef.current }
      currentPosRef.current = { x: mousePosRef.current.x, y: mousePosRef.current.y }
      setPosition({ x: mousePosRef.current.x, y: mousePosRef.current.y })
      setShow(true)
      requestAnimationFrame(() => {
        updateTarget()
      })
    }, delay)
  }, [updateTarget, delay])

  const handleMouseLeave = useCallback(() => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current)
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current)
      animationFrameRef.current = 0
    }
    setShimmerDone(false)
    setShow(false)
  }, [])

  useEffect(() => {
    if (!show) return
    const handler = () => updateTarget()
    window.addEventListener('scroll', handler, true)
    window.addEventListener('resize', handler)
    return () => {
      window.removeEventListener('scroll', handler, true)
      window.removeEventListener('resize', handler)
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
        animationFrameRef.current = 0
      }
    }
  }, [show, updateTarget])

  const effectiveMaxWidth = Math.min(maxWidth, window.innerWidth - VIEWPORT_PADDING * 2)
  const arrowSide = sideRef.current

  return (
    <div
      onMouseEnter={handleMouseEnter}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className={className}
    >
      {children}

      <AnimatePresence>
        {show && (
          <motion.div
            ref={tooltipRef}
            initial={{
              opacity: 0,
              scale: 0.85,
              [arrowSide === 'top' ? 'y' : arrowSide === 'bottom' ? 'y' : 'x']:
                arrowSide === 'top' ? 10 : arrowSide === 'bottom' ? -10 : -8,
            }}
            animate={{ opacity: 1, scale: 1, y: 0, x: 0 }}
            exit={{
              opacity: 0,
              scale: 0.85,
              [arrowSide === 'top' ? 'y' : arrowSide === 'bottom' ? 'y' : 'x']:
                arrowSide === 'top' ? 8 : arrowSide === 'bottom' ? -8 : -6,
            }}
            transition={{ type: 'spring', stiffness: 500, damping: 28, mass: 0.8 }}
            className="fixed z-999 pointer-events-none"
            style={{
              left: position.x,
              top: position.y,
            }}
          >
            {/* Arrow pointer — seamless bg-surface diamond, no border so it blends into the tooltip body */}
            <div
              className="absolute z-[-1] w-2.5 h-2.5 rotate-45 bg-surface"
              style={{
                [arrowSide === 'top' ? 'bottom' : arrowSide === 'bottom' ? 'top' : 'left']: -5,
                [arrowSide === 'top' || arrowSide === 'bottom' ? 'left' : 'top']: '50%',
                marginLeft: arrowSide !== 'right' ? -5 : undefined,
                marginTop: arrowSide === 'right' ? -5 : undefined,
              }}
            />
            {/* Tooltip body */}
            <div
              className="relative overflow-hidden px-3.5 py-2 rounded-xl border border-line/80 bg-surface/96 text-xs text-ink font-medium shadow-2xl shadow-black/60 backdrop-blur-[12px]"
              style={{
                maxWidth: effectiveMaxWidth,
                wordBreak: 'break-word',
                overflowWrap: 'break-word',
              }}
            >
              {/* Shimmer sweep on spawn */}
              {!shimmerDone && (
                <motion.div
                  initial={{ x: '-100%' }}
                  animate={{ x: '200%' }}
                  onAnimationComplete={() => setShimmerDone(true)}
                  transition={{
                    duration: 0.7,
                    ease: [0.22, 1, 0.36, 1],
                    delay: 0.04,
                  }}
                  className="absolute inset-0 pointer-events-none"
                  style={{
                    background:
                      'linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.08) 50%, transparent 100%)',
                  }}
                />
              )}
              <span className="relative z-[1]">{content}</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
