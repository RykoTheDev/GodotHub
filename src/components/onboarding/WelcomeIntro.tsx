import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { ease, gsap, motionOff } from '../../lib/motion'
import { api } from '../../lib/api'
import { IconChevronRight } from '../../lib/icons'

const RING_GROWTH = 14
const MAGNET_MARGIN = 28
const MAGNET_PULL = 0.3
const WORDMARK_TARGET = '[data-onboarding-wordmark]'

export function WelcomeIntro({ onLeave, onDone }: { onLeave: () => void; onDone: () => void }) {
  const { t } = useTranslation('onboarding')
  const rootRef = useRef<HTMLDivElement>(null)
  const wordmarkRef = useRef<HTMLHeadingElement>(null)
  const leavingRef = useRef(false)
  const [leaving, setLeaving] = useState(false)
  const [name, setName] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    api
      .getOsUsername()
      .then((n) => {
        if (!cancelled && n?.trim()) setName(n.trim())
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [])

  useLayoutEffect(() => {
    const root = rootRef.current
    if (!root || motionOff()) return
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: ease.out } })
      tl.from('[data-intro-grid]', { opacity: 0, duration: 1.4 }, 0)
      tl.from('[data-intro-eyebrow]', { opacity: 0, y: 14, duration: 0.7 }, 0.25)
      tl.from(
        '[data-intro-letter]',
        {
          yPercent: 120,
          rotationX: -90,
          opacity: 0,
          transformOrigin: '50% 100%',
          duration: 1,
          stagger: 0.05,
        },
        0.4,
      )
      tl.from('[data-intro-line]', { scaleX: 0, opacity: 0, duration: 0.9 }, 0.85)
      tl.from('[data-intro-desc]', { opacity: 0, y: 16, duration: 0.8 }, 1)
      tl.from('[data-intro-cta]', { opacity: 0, scale: 0.85, y: 12, duration: 0.7, ease: ease.spring }, 1.25)
      tl.call(() => {
        const button = root.querySelector<HTMLElement>('[data-intro-button]')
        const radius = button ? parseFloat(getComputedStyle(button).borderTopLeftRadius) || 0 : 0
        ctx.add(() => gsap.fromTo(
          '[data-intro-ring]',
          { inset: 0, borderRadius: radius, opacity: 0.75 },
          {
            inset: -RING_GROWTH,
            borderRadius: radius + RING_GROWTH,
            opacity: 0,
            duration: 2.4,
            ease: 'power2.out',
            stagger: { each: 1.2, repeat: -1 },
          },
        ))
      })
    }, root)

    const anchor = root.querySelector<HTMLElement>('[data-intro-cta]')
    const magnet = root.querySelector<HTMLElement>('[data-intro-magnet]')
    if (!anchor || !magnet) return () => ctx.revert()

    const magnetX = gsap.quickTo(magnet, 'x', { duration: 0.7, ease: 'power3.out' })
    const magnetY = gsap.quickTo(magnet, 'y', { duration: 0.7, ease: 'power3.out' })

    const release = () => {
      magnetX(0)
      magnetY(0)
    }

    const onMove = (e: PointerEvent) => {
      if (leavingRef.current) return
      const r = anchor.getBoundingClientRect()
      const dx = e.clientX - (r.left + r.width / 2)
      const dy = e.clientY - (r.top + r.height / 2)
      if (Math.abs(dx) > r.width / 2 + MAGNET_MARGIN || Math.abs(dy) > r.height / 2 + MAGNET_MARGIN) {
        release()
        return
      }
      magnetX(dx * MAGNET_PULL)
      magnetY(dy * MAGNET_PULL)
    }

    root.addEventListener('pointermove', onMove)
    root.addEventListener('pointerleave', release)
    return () => {
      root.removeEventListener('pointermove', onMove)
      root.removeEventListener('pointerleave', release)
      ctx.revert()
    }
  }, [])

  const diveIn = () => {
    if (leavingRef.current) return
    leavingRef.current = true
    setLeaving(true)
    const root = rootRef.current
    const wordmark = wordmarkRef.current
    const target = document.querySelector<HTMLElement>(WORDMARK_TARGET)
    if (!root || !wordmark || !target || motionOff()) {
      onLeave()
      onDone()
      return
    }

    const from = wordmark.getBoundingClientRect()
    const to = target.getBoundingClientRect()
    const scale =
      parseFloat(getComputedStyle(target).fontSize) / parseFloat(getComputedStyle(wordmark).fontSize)
    gsap.set(target, { opacity: 0 })
    onLeave()

    gsap.context(() => {
      const tl = gsap.timeline({
        onComplete: () => {
          gsap.set(target, { clearProps: 'opacity' })
          onDone()
        },
      })
      tl.to(['[data-intro-eyebrow]', '[data-intro-line]', '[data-intro-desc]', '[data-intro-cta]'], {
        opacity: 0,
        y: 12,
        duration: 0.3,
        stagger: 0.04,
        ease: ease.in,
      }, 0)
      tl.to(wordmark, {
        x: to.left + to.width / 2 - (from.left + from.width / 2),
        y: to.top + to.height / 2 - (from.top + from.height / 2),
        scale,
        duration: 0.95,
        ease: 'power3.inOut',
      }, 0.1)
      tl.to('[data-intro-bg]', { opacity: 0, duration: 0.55, ease: 'power2.out' }, 0.25)
    }, root)
  }

  return (
    <div
      ref={rootRef}
      data-motion="none"
      data-tauri-drag-region
      onKeyDown={(e) => {
        if (e.key === 'Enter') diveIn()
      }}
      className={`fixed inset-0 z-100 flex items-center justify-center overflow-hidden select-none ${
        leaving ? 'pointer-events-none' : ''
      }`}
    >
      <div data-intro-bg data-tauri-drag-region className="absolute inset-0 bg-base">
        <div
          data-intro-grid
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 opacity-[0.07]"
          style={{
            backgroundImage: 'radial-gradient(var(--color-ink) 1px, transparent 1px)',
            backgroundSize: '28px 28px',
            maskImage: 'radial-gradient(ellipse at center, black 30%, transparent 75%)',
            WebkitMaskImage: 'radial-gradient(ellipse at center, black 30%, transparent 75%)',
          }}
        />
      </div>

      <div className="pointer-events-none relative flex flex-col items-center gap-7 px-6 text-center">
        <div className="flex flex-col items-center gap-4">
          <span
            data-intro-eyebrow
            aria-hidden="true"
            className="text-sm font-semibold uppercase tracking-[0.3em] text-accent-bright"
          >
            {name ? t('welcome_to_name', { name }) : t('welcome_to')}
          </span>
          <h1
            ref={wordmarkRef}
            aria-label={t('welcome_title')}
            className="flex font-display font-black tracking-tight leading-none text-ink text-[5.5rem] perspective-[800px]"
          >
            {'GodotHub'.split('').map((letter, i) => (
              <span key={i} data-intro-letter aria-hidden="true" className="inline-block">
                {letter}
              </span>
            ))}
          </h1>
          <div data-intro-line className="h-[3px] w-24 rounded-full bg-accent-bright" />
        </div>

        <p data-intro-desc className="max-w-lg text-sm text-muted leading-relaxed">
          {t('welcome_desc')}
        </p>

        <div data-intro-cta className="pointer-events-auto relative mt-2">
          <div data-intro-magnet className="relative">
            {[0, 1].map((ring) => (
              <span
                key={ring}
                data-intro-ring
                aria-hidden="true"
                className="pointer-events-none absolute inset-0 rounded-btn border-2 border-accent-bright opacity-0"
              />
            ))}
            <button
              type="button"
              autoFocus
              data-intro-button
              onClick={diveIn}
              disabled={leaving}
              className="focus-ring group relative cursor-pointer inline-flex items-center h-12 px-8 rounded-btn bg-accent hover:bg-accent-bright text-white text-sm font-semibold"
            >
              <span className="inline-flex items-center gap-2.5">
                {t('dive_in')}
                <IconChevronRight className="w-3.5 h-3.5 rtl:rotate-180 group-hover:translate-x-0.5 rtl:group-hover:-translate-x-0.5" />
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
