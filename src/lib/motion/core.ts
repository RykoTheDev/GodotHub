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

export type MotionIntensity = 'full' | 'subtle' | 'none'
export type ViewEntrance = 'fade' | 'slide' | 'scale' | 'none'

export interface MotionPrefs {
  intensity: MotionIntensity
  speed: number
  entrance: ViewEntrance
  threshold: number
  scrollReveal: boolean
  tilt: boolean
  ripple: boolean
  press: boolean
}

let prefs: MotionPrefs = {
  intensity: 'full',
  speed: 1.5,
  entrance: 'slide',
  threshold: 20,
  scrollReveal: true,
  tilt: true,
  ripple: true,
  press: true,
}

const reduceQuery = window.matchMedia('(prefers-reduced-motion: reduce)')

export function motionPrefs() {
  return prefs
}

export function motionOff() {
  return reduceQuery.matches || prefs.intensity === 'none'
}

export function flourishesOn() {
  return !motionOff() && prefs.intensity === 'full'
}

function applyTiming() {
  const root = document.documentElement
  const speed = (prefs.intensity === 'subtle' ? 1.8 : 1) * prefs.speed
  gsap.globalTimeline.timeScale(motionOff() ? 40 : speed)
  root.style.setProperty('--motion-speed', String(speed))
  root.classList.toggle('motion-off', prefs.intensity === 'none')
}

export function setMotionPrefs(next: Partial<MotionPrefs>) {
  prefs = { ...prefs, ...next }
  applyTiming()
}

export function syncReducedMotion() {
  applyTiming()
  reduceQuery.addEventListener('change', applyTiming)
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
