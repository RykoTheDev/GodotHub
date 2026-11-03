import { busy, canTransform, ease, GHOST_SELECTOR, gsap, isPointerHeld, motionOff, motionPrefs } from './core'

const REVEAL = [
  'section',
  'header',
  'article',
  'li',
  'tr',
  'h1',
  'h2',
  'h3',
  '[role="row"]',
  '[role="option"]',
  '[role="listitem"]',
  '[data-card]',
  '[class*="rounded-card"]',
  '[class*="rounded-tile"]',
  ':is(div, a)[class*="rounded-item"][class*="bg-overlay"]',
  ':is(div, a)[class*="rounded-item"][class*="bg-raised"]',
  ':is(div, a)[class*="rounded-btn"][class*="bg-overlay"][class*="border"]',
].join(',')

const SKIP = `${GHOST_SELECTOR}, [data-motion-skip]`
const MAX_BATCH = 120

let live = false
const pending = new Set<HTMLElement>()

const watcher = new IntersectionObserver((entries) => {
  let index = 0
  for (const entry of entries) {
    const el = entry.target as HTMLElement
    if (!entry.isIntersecting) continue
    watcher.unobserve(el)
    pending.delete(el)
    gsap.set(el, { clearProps: 'opacity' })
    play(el, Math.min(index * 0.06, 0.5), true)
    index += 1
  }
})

export function enableLiveReveal() {
  live = true
}

function collect(root: HTMLElement) {
  const list: HTMLElement[] = root.matches(REVEAL) ? [root] : []
  root.querySelectorAll<HTMLElement>(REVEAL).forEach((el) => list.push(el))
  return list.filter((el) => !el.closest(SKIP))
}

function play(el: HTMLElement, delay: number, fromScroll = false) {
  const release = busy(el)
  const ownOpacity = el.style.opacity !== ''
  const move = canTransform(el)
  const cleared = ['clipPath', 'filter']
  const vars: gsap.TweenVars = {
    duration: 0.75,
    delay,
    ease: ease.out,
    onComplete: release,
    onInterrupt: release,
  }
  if (!ownOpacity) {
    vars.opacity = 0
    cleared.push('opacity')
  }
  const entrance = motionPrefs().entrance
  if (move && entrance !== 'fade') {
    cleared.push('transform')
    if (el.matches('[class*="rounded-tile"]')) {
      Object.assign(vars, { scale: 0.3, rotation: '-=16', ease: ease.pop, duration: 0.85 })
    } else if (el.matches('h1, h2, h3')) {
      Object.assign(vars, entrance === 'slide' ? { y: 20, clipPath: 'inset(0% 0% 100% 0%)' } : { scale: 0.96 })
    } else if (entrance === 'scale') {
      Object.assign(vars, { scale: 0.92, ease: ease.spring })
    } else {
      Object.assign(vars, { y: fromScroll ? 40 : 26, scale: 0.96, filter: 'blur(4px)' })
    }
  }
  vars.clearProps = cleared.join(',')
  gsap.from(el, vars)
}

function defer(el: HTMLElement) {
  if (el.style.opacity !== '') return
  gsap.set(el, { opacity: 0 })
  pending.add(el)
  watcher.observe(el)
}

export function flushPending() {
  for (const el of pending) {
    watcher.unobserve(el)
    gsap.set(el, { clearProps: 'opacity' })
  }
  pending.clear()
}

function prune() {
  for (const el of pending) {
    if (el.isConnected) continue
    watcher.unobserve(el)
    pending.delete(el)
  }
}

export function animateIn(elements: HTMLElement[], baseDelay = 0) {
  const { entrance, threshold, scrollReveal } = motionPrefs()
  if (motionOff() || entrance === 'none') return
  const projects = new Set(elements.map((el) => el.closest('[data-sortable-id]')).filter(Boolean))
  if (projects.size > threshold) elements = elements.filter((el) => !el.closest('[data-sortable-id]'))
  prune()
  const vh = window.innerHeight
  const vw = window.innerWidth
  let index = 0
  for (const el of elements.slice(0, MAX_BATCH)) {
    if (pending.has(el) || gsap.isTweening(el)) continue
    const r = el.getBoundingClientRect()
    if (r.width === 0 || r.height === 0) continue
    if (r.top > vh || r.bottom < 0 || r.left > vw || r.right < 0) {
      if (scrollReveal) defer(el)
      continue
    }
    play(el, baseDelay + Math.min(index * 0.035, 0.8))
    index += 1
  }
}

export function revealView(pane: HTMLElement) {
  if (motionOff() || motionPrefs().entrance === 'none' || gsap.isTweening(pane)) return
  if (getComputedStyle(pane).display !== 'contents') {
    gsap.from(pane, { opacity: 0, duration: 0.4, ease: ease.soft, clearProps: 'opacity' })
  }
  animateIn(collect(pane), 0.05)
}

export function revealLive(roots: HTMLElement[], exclude: HTMLElement[]) {
  if (!live || isPointerHeld()) return
  const found = new Set<HTMLElement>()
  for (const root of roots) {
    if (root.closest(SKIP)) continue
    const parent = root.parentElement
    if (parent?.hasAttribute('data-view-pane')) {
      revealView(parent)
      continue
    }
    for (const el of collect(root)) {
      if (!exclude.some((o) => o.contains(el))) found.add(el)
    }
  }
  if (found.size) animateIn([...found])
}
