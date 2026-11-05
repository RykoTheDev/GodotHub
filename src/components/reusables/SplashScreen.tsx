import { useLayoutEffect, useRef } from 'react'
import { ease, gsap, motionOff } from '../../lib/motion'

export function SplashScreen() {
  const rootRef = useRef<HTMLDivElement>(null)

  useLayoutEffect(() => {
    const root = rootRef.current
    if (!root) return
    const ctx = gsap.context(() => {
      const tl = gsap.timeline()
      tl.from('[data-splash-letter]', {
        yPercent: 120,
        rotationX: -90,
        opacity: 0,
        transformOrigin: '50% 100%',
        duration: 0.9,
        stagger: 0.045,
        ease: ease.out,
      })
      tl.from('[data-splash-track]', { scaleX: 0, opacity: 0, duration: 0.6, ease: ease.out }, 0.25)
      if (!motionOff()) {
        gsap.fromTo('[data-splash-bar]', { xPercent: -120 }, { xPercent: 220, duration: 1.1, ease: 'power2.inOut', repeat: -1 })
      }
    }, root)
    return () => ctx.revert()
  }, [])

  return (
    <div ref={rootRef} data-motion="splash" className="fixed inset-0 z-50 flex items-center justify-center bg-base overflow-hidden">
      <div className="relative flex flex-col items-center gap-6 select-none">
        <div className="flex flex-col items-center gap-3">
          <h1
            aria-label="GodotHub"
            className="flex font-black italic tracking-tight leading-none text-ink text-[3.5rem] perspective-[600px]"
          >
            {'GodotHub'.split('').map((letter, i) => (
              <span key={i} data-splash-letter aria-hidden="true" className="inline-block">
                {letter}
              </span>
            ))}
          </h1>

          <div data-splash-track className="relative h-[3px] w-40 rounded-full bg-raised overflow-hidden">
            <div data-splash-bar className="absolute inset-y-0 w-1/2 rounded-full bg-linear-to-r from-transparent via-accent to-transparent" />
          </div>
        </div>
      </div>
    </div>
  )
}
