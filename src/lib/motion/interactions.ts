import {
  canTransform,
  claim,
  ease,
  GHOST_SELECTOR,
  gsap,
  hold,
  prefersReducedMotion,
  setPointerHeld,
  settle,
} from './core'

const PRESSABLE = [
  'button',
  'a[href]',
  'summary',
  '[role="button"]',
  '[role="menuitem"]',
  '[role="tab"]',
  '[role="option"]',
  '[role="switch"]',
  '[role="checkbox"]',
  '[role="radio"]',
].join(',')

const CARD = [
  'article',
  '[data-card]',
  '[class*="rounded-card"]:is(button, a)',
  ':is(div, li)[class*="rounded-item"][class*="bg-overlay"][class*="border"]',
].join(',')

let pressed: HTMLElement | null = null
let hovered: HTMLElement | null = null

function disabled(el: HTMLElement) {
  return el.matches(':disabled, [aria-disabled="true"]') || !!el.closest(GHOST_SELECTOR)
}

function ripple(el: HTMLElement, e: PointerEvent) {
  if (el.closest('[data-no-ripple]')) return
  const rect = el.getBoundingClientRect()
  if (rect.width < 18 || rect.height < 14 || getComputedStyle(el).display === 'inline') return
  const host = document.createElement('span')
  host.setAttribute('data-motion-ghost', '')
  host.setAttribute('aria-hidden', 'true')
  host.className = 'motion-ripple'
  const dot = document.createElement('span')
  const size = Math.hypot(rect.width, rect.height) * 2
  const scaleX = el.offsetWidth ? rect.width / el.offsetWidth : 1
  const scaleY = el.offsetHeight ? rect.height / el.offsetHeight : 1
  dot.style.width = `${size}px`
  dot.style.height = `${size}px`
  dot.style.left = `${(e.clientX - rect.left) / scaleX - size / 2}px`
  dot.style.top = `${(e.clientY - rect.top) / scaleY - size / 2}px`
  host.appendChild(dot)
  el.appendChild(host)
  gsap.fromTo(dot, { scale: 0, opacity: 1 }, { scale: 1, opacity: 0, duration: 0.6, ease: 'power2.out', onComplete: () => host.remove() })
}

function press(el: HTMLElement) {
  if (!canTransform(el)) return
  claim(el)
  pressed = el
  const width = el.getBoundingClientRect().width
  gsap.set(el, { scale: gsap.getProperty(el, 'scale') })
  gsap.to(el, { scale: width > 260 ? 0.985 : width > 90 ? 0.955 : 0.88, duration: 0.14, ease: 'power2.out', overwrite: 'auto' })
}

function release() {
  setPointerHeld(false)
  const el = pressed
  pressed = null
  if (!el) return
  const tween: gsap.core.Tween = gsap.to(el, {
    scale: 1,
    duration: 0.8,
    ease: 'elastic.out(1.15, 0.32)',
    overwrite: 'auto',
    onComplete: () => settle(el, tween),
  })
}

function pulse(el: HTMLElement) {
  if (!canTransform(el)) return
  claim(el)
  const tween: gsap.core.Tween = gsap.fromTo(el, { scale: 0.92 }, { scale: 1, duration: 0.7, ease: ease.elastic, overwrite: 'auto', onComplete: () => settle(el, tween) })
}

function tiltStrength(card: HTMLElement) {
  const r = card.getBoundingClientRect()
  if (r.width < 120 || r.height < 64 || r.width > 1400 || r.height > 640) return 0
  return Math.min(7, 2400 / r.width)
}

function enterCard(card: HTMLElement) {
  hovered = card
  hold(card, true)
}

function leaveCard() {
  const card = hovered
  if (!card) return
  hovered = null
  hold(card, false)
  if (!canTransform(card)) return
  const tween: gsap.core.Tween = gsap.to(card, {
    rotationX: 0,
    rotationY: 0,
    y: 0,
    duration: 1,
    ease: 'elastic.out(1, 0.5)',
    overwrite: 'auto',
    onComplete: () => settle(card, tween),
  })
}

function tilt(card: HTMLElement, e: PointerEvent) {
  const r = card.getBoundingClientRect()
  const px = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width))
  const py = Math.min(1, Math.max(0, (e.clientY - r.top) / r.height))
  const strength = tiltStrength(card)
  if (!strength || !canTransform(card)) return
  claim(card)
  gsap.to(card, {
    rotationY: (px - 0.5) * strength,
    rotationX: (0.5 - py) * strength,
    y: -4,
    transformPerspective: 900,
    duration: 0.5,
    ease: ease.soft,
    overwrite: 'auto',
  })
}

function onPointerDown(e: PointerEvent) {
  setPointerHeld(true)
  if (e.button !== 0) return
  const target = e.target as Element
  const el = target.closest<HTMLElement>(PRESSABLE) ?? target.closest<HTMLElement>(CARD)
  if (!el || disabled(el)) return
  press(el)
  ripple(el, e)
}

function onPointerMove(e: PointerEvent) {
  if (e.pointerType !== 'mouse' || e.buttons) return
  const target = e.target as Element
  const card = target.closest<HTMLElement>(CARD)
  if (card !== hovered) {
    leaveCard()
    if (card && !card.closest(GHOST_SELECTOR)) enterCard(card)
  }
  if (hovered) tilt(hovered, e)
}

function onKeyDown(e: KeyboardEvent) {
  if (e.key !== 'Enter' && e.key !== ' ') return
  const el = document.activeElement
  if (el instanceof HTMLElement && el.matches(PRESSABLE) && !disabled(el)) pulse(el)
}

export function installInteractions() {
  if (prefersReducedMotion()) return
  document.addEventListener('pointerdown', onPointerDown, { passive: true })
  document.addEventListener('pointerup', release, { passive: true })
  document.addEventListener('pointercancel', release, { passive: true })
  document.addEventListener('pointermove', onPointerMove, { passive: true })
  document.documentElement.addEventListener('pointerleave', leaveCard)
  document.addEventListener('keydown', onKeyDown)
}

export function spin(el: Element | null) {
  if (!(el instanceof SVGElement) || prefersReducedMotion()) return
  el.setAttribute('data-motion-busy', '')
  const release = () => el.removeAttribute('data-motion-busy')
  gsap.fromTo(
    el,
    { rotation: 0, scale: 0.6 },
    { rotation: 180, scale: 1, duration: 0.9, ease: ease.elastic, overwrite: 'auto', clearProps: 'transform', onComplete: release, onInterrupt: release },
  )
}
