import gsap from 'gsap'

export { gsap }

export const ease = {
  out: 'expo.out',
  soft: 'power3.out',
  in: 'power2.in',
  spring: 'back.out(1.8)',
  pop: 'back.out(2.6)',
  elastic: 'elastic.out(1.1, 0.4)',
}

export const GHOST_ATTR = 'data-motion-ghost'
export const GHOST_SELECTOR = `[${GHOST_ATTR}]`

const reduceQuery = window.matchMedia('(prefers-reduced-motion: reduce)')

export function prefersReducedMotion() {
  return reduceQuery.matches
}

export function syncReducedMotion() {
  const apply = () => gsap.globalTimeline.timeScale(reduceQuery.matches ? 40 : 1)
  apply()
  reduceQuery.addEventListener('change', apply)
}

export function isRtlDocument() {
  return document.documentElement.dir === 'rtl'
}

let pointerHeld = false

export function setPointerHeld(held: boolean) {
  pointerHeld = held
}

export function isPointerHeld() {
  return pointerHeld
}

const owned = new WeakSet<Element>()
const holding = new WeakSet<Element>()

export function canTransform(el: HTMLElement) {
  return owned.has(el) || el.style.transform === ''
}

export function claim(el: HTMLElement) {
  owned.add(el)
}

export function hold(el: HTMLElement, held: boolean) {
  if (held) holding.add(el)
  else holding.delete(el)
}

export function settle(el: HTMLElement, done?: gsap.core.Animation) {
  if (holding.has(el)) return
  if (gsap.getTweensOf(el).some((t) => t !== done && t.isActive())) return
  gsap.set(el, { clearProps: 'transform' })
  owned.delete(el)
}

export function busy(...els: HTMLElement[]) {
  els.forEach((el) => el.setAttribute('data-motion-busy', ''))
  return () => els.forEach((el) => el.removeAttribute('data-motion-busy'))
}
