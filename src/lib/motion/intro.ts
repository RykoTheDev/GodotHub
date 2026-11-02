import { ease, gsap, isRtlDocument, motionOff } from './core'
import { enableLiveReveal } from './reveal'

export function introShell(titlebar: HTMLElement | null, sidebar: HTMLElement | null) {
  if (motionOff()) {
    enableLiveReveal()
    return
  }
  const tl = gsap.timeline({ delay: 0.15, onComplete: enableLiveReveal, onInterrupt: enableLiveReveal })
  if (titlebar) {
    tl.from(titlebar, { y: -40, opacity: 0, duration: 0.8, ease: ease.out, clearProps: 'opacity,transform' }, 0)
    const parts = Array.from(titlebar.querySelectorAll<HTMLElement>(':scope > *'))
    if (parts.length) tl.from(parts, { y: -14, opacity: 0, duration: 0.6, stagger: 0.06, ease: ease.out, clearProps: 'opacity,transform' }, 0.15)
  }
  if (sidebar) {
    tl.from(sidebar, { x: isRtlDocument() ? 60 : -60, opacity: 0, duration: 0.9, ease: ease.out, clearProps: 'opacity,transform' }, 0.05)
    const items = Array.from(sidebar.querySelectorAll<HTMLElement>('button')).slice(0, 30)
    if (items.length) {
      tl.from(items, { x: isRtlDocument() ? 20 : -20, opacity: 0, duration: 0.6, stagger: 0.03, ease: ease.out, clearProps: 'opacity,transform' }, 0.2)
    }
  }
}
