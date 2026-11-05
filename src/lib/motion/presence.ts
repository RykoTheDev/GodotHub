import {
  busy,
  canTransform,
  ease,
  GHOST_ATTR,
  gsap,
  isRtlDocument,
  motionOff,
} from './core'
import { revealLive } from './reveal'

type Kind = 'modal' | 'popover' | 'tooltip' | 'panel' | 'backdrop' | 'toast' | 'splash' | 'none'

const PRESENCE = '[data-motion], .fixed.inset-0, [role="menu"], [role="listbox"], .rounded-menu'
const MENU = '[role="menu"], [role="listbox"], .rounded-menu'

const entered = new WeakSet<Element>()
const sharedRects = new Map<string, DOMRect>()
const sharedLive = new Map<string, HTMLElement>()

function declared(el: HTMLElement): Kind | null {
  const kind = el.dataset.motion as Kind | undefined
  if (kind) return kind
  if (el.classList.contains('fixed') && el.classList.contains('inset-0')) return 'modal'
  return null
}

function kindOf(el: HTMLElement): Kind | null {
  const kind = declared(el)
  if (kind) return kind
  if (!el.matches(MENU)) return null
  const position = getComputedStyle(el).position
  return position === 'fixed' || position === 'absolute' ? 'popover' : null
}

function detachedKindOf(el: HTMLElement): Kind | null {
  const kind = declared(el)
  if (kind) return kind
  return el.matches(MENU) && el.classList.contains('fixed') ? 'popover' : null
}

function panelOf(el: HTMLElement) {
  return (el.querySelector<HTMLElement>('[role="dialog"]') ?? el.firstElementChild) as HTMLElement | null
}

function cascade(root: HTMLElement, limit = 18) {
  const out: HTMLElement[] = []
  for (const child of Array.from(root.children) as HTMLElement[]) {
    const kids = Array.from(child.children) as HTMLElement[]
    if (kids.length > 1 && kids.length <= 12 && !child.matches('button, a, input, textarea')) out.push(...kids)
    else out.push(child)
    if (out.length >= limit) break
  }
  return out.filter((el) => canTransform(el) && el.getClientRects().length > 0).slice(0, limit)
}

function enterModal(el: HTMLElement) {
  const panel = panelOf(el)
  const release = busy(el)
  const tl = gsap.timeline({ onComplete: release, onInterrupt: release })
  tl.from(el, { opacity: 0, duration: 0.2, ease: ease.soft, lazy: false, clearProps: 'opacity' }, 0)
  if (!panel || !canTransform(panel)) return
  const releasePanel = busy(panel)
  tl.from(
    panel,
    {
      opacity: 0,
      y: 18,
      scale: 0.96,
      duration: 0.36,
      ease: ease.out,
      lazy: false,
      clearProps: 'opacity,transform',
      onComplete: releasePanel,
      onInterrupt: releasePanel,
    },
    0,
  )
  const parts = cascade(panel)
  if (parts.length) {
    const releaseParts = busy(...parts)
    tl.from(
      parts,
      {
        opacity: 0,
        y: 8,
        duration: 0.3,
        stagger: { amount: Math.min(0.12, parts.length * 0.02) },
        ease: ease.out,
        lazy: false,
        clearProps: 'opacity,transform',
        onComplete: releaseParts,
        onInterrupt: releaseParts,
      },
      0.05,
    )
  }
}

function enterPopover(el: HTMLElement) {
  const up = el.classList.contains('origin-bottom') || el.style.transformOrigin.startsWith('bottom')
  const items = Array.from(el.querySelectorAll<HTMLElement>('[role="menuitem"], [role="option"]')).slice(0, 16)
  const release = busy(el, ...items)
  const tl = gsap.timeline({ onComplete: release, onInterrupt: release })
  tl.from(el, {
    opacity: 0,
    scale: 0.95,
    y: up ? 6 : -6,
    duration: 0.28,
    ease: ease.out,
    clearProps: 'opacity,transform',
  })
  if (items.length) {
    tl.from(
      items,
      { opacity: 0, x: isRtlDocument() ? 6 : -6, duration: 0.24, stagger: { amount: Math.min(0.12, items.length * 0.015) }, ease: ease.soft, clearProps: 'opacity,transform' },
      0.02,
    )
  }
}

function enter(kind: Kind, el: HTMLElement) {
  if (motionOff()) return
  switch (kind) {
    case 'modal':
      enterModal(el)
      break
    case 'popover':
      enterPopover(el)
      break
    case 'tooltip':
      gsap.from(el, { opacity: 0, scale: 0.78, duration: 0.32, ease: ease.pop, clearProps: 'opacity,transform' })
      break
    case 'panel':
      gsap.from(el, { xPercent: isRtlDocument() ? -110 : 110, opacity: 0, duration: 0.7, ease: ease.out, clearProps: 'opacity,transform' })
      break
    case 'backdrop':
      gsap.from(el, { opacity: 0, duration: 0.4, ease: ease.soft, clearProps: 'opacity' })
      break
    case 'toast':
      gsap.from(el, {
        opacity: 0,
        x: isRtlDocument() ? -110 : 110,
        scale: 0.8,
        rotation: isRtlDocument() ? -8 : 8,
        duration: 0.8,
        ease: 'back.out(1.5)',
        clearProps: 'opacity,transform',
      })
      break
  }
}

function ghostOf(el: HTMLElement, parent: Node, next: Node | null) {
  const ghost = el.cloneNode(true) as HTMLElement
  const sources = el.querySelectorAll<HTMLInputElement | HTMLTextAreaElement>('input, textarea')
  ghost.querySelectorAll<HTMLInputElement | HTMLTextAreaElement>('input, textarea').forEach((field, i) => {
    field.value = sources[i]?.value ?? ''
  })
  ghost.removeAttribute('id')
  ghost.querySelectorAll('[id]').forEach((node) => node.removeAttribute('id'))
  ghost.setAttribute(GHOST_ATTR, '')
  ghost.setAttribute('aria-hidden', 'true')
  ghost.inert = true
  ghost.style.pointerEvents = 'none'
  const host = parent.isConnected ? parent : document.body
  host.insertBefore(ghost, next && next.parentNode === host ? next : null)
  return ghost
}

function exit(kind: Kind, ghost: HTMLElement) {
  const done = () => ghost.remove()
  switch (kind) {
    case 'modal': {
      const panel = panelOf(ghost)
      const tl = gsap.timeline({ onComplete: done })
      tl.to(ghost, { opacity: 0, duration: 0.22, ease: 'power2.out' }, 0.02)
      if (panel) {
        tl.to(panel, { opacity: 0, y: 12, scale: 0.96, duration: 0.2, ease: ease.in }, 0)
      }
      break
    }
    case 'popover':
      gsap.to(ghost, { opacity: 0, scale: 0.96, y: -4, duration: 0.15, ease: ease.in, onComplete: done })
      break
    case 'tooltip':
      gsap.to(ghost, { opacity: 0, scale: 0.88, duration: 0.14, ease: ease.in, onComplete: done })
      break
    case 'panel':
      gsap.to(ghost, { xPercent: isRtlDocument() ? -110 : 110, opacity: 0.3, duration: 0.42, ease: 'power3.in', onComplete: done })
      break
    case 'backdrop':
      gsap.to(ghost, { opacity: 0, duration: 0.35, onComplete: done })
      break
    case 'splash':
      gsap.to(ghost, { opacity: 0, scale: 1.08, filter: 'blur(12px)', duration: 0.75, ease: 'power2.inOut', onComplete: done })
      break
    default:
      done()
  }
}

function exitTree(el: HTMLElement, parent: Node, next: Node | null) {
  if (motionOff()) return
  const kind = detachedKindOf(el)
  if (kind) {
    if (kind !== 'none' && kind !== 'toast') exit(kind, ghostOf(el, parent, next))
    return
  }
  el.querySelectorAll<HTMLElement>('.fixed.inset-0, [data-motion="modal"]').forEach((child) => {
    if (child.parentElement?.closest('.fixed.inset-0')) return
    exit('modal', ghostOf(child, document.body, null))
  })
}

function enterTree(el: HTMLElement, overlays: HTMLElement[]) {
  const targets: HTMLElement[] = el.matches(PRESENCE) ? [el] : []
  el.querySelectorAll<HTMLElement>(PRESENCE).forEach((t) => targets.push(t))
  for (const target of targets) {
    if (entered.has(target) || overlays.some((o) => o.contains(target))) continue
    const kind = kindOf(target)
    if (!kind) continue
    entered.add(target)
    overlays.push(target)
    if (kind !== 'none' && kind !== 'splash') enter(kind, target)
  }
}

function measureShared() {
  for (const [key, el] of sharedLive) {
    if (el.isConnected) sharedRects.set(key, el.getBoundingClientRect())
    else sharedLive.delete(key)
  }
}

function enterShared(el: HTMLElement) {
  const key = el.dataset.motionShared
  if (!key) return
  const rect = el.getBoundingClientRect()
  const prev = sharedRects.get(key)
  sharedLive.set(key, el)
  sharedRects.set(key, rect)
  if (!prev || motionOff() || !rect.width || !rect.height || !prev.width || !prev.height) return
  const dx = prev.left - rect.left
  const dy = prev.top - rect.top
  if (Math.abs(dx) < 1 && Math.abs(dy) < 1) return
  gsap.fromTo(
    el,
    { x: dx, y: dy, scaleX: prev.width / rect.width, scaleY: prev.height / rect.height, transformOrigin: '0 0' },
    { x: 0, y: 0, scaleX: 1, scaleY: 1, duration: 0.6, ease: ease.out, clearProps: 'transform,transformOrigin' },
  )
  const icon = el.parentElement?.querySelector<SVGElement>('svg')
  if (icon) {
    icon.setAttribute('data-motion-busy', '')
    const release = () => icon.removeAttribute('data-motion-busy')
    gsap.fromTo(
      icon,
      { scale: 0.6, rotation: -20 },
      { scale: 1, rotation: 0, duration: 0.9, delay: 0.12, ease: ease.elastic, clearProps: 'transform', onComplete: release, onInterrupt: release },
    )
  }
}

function enterImages(el: HTMLElement) {
  const images: HTMLImageElement[] = el instanceof HTMLImageElement ? [el] : Array.from(el.querySelectorAll('img'))
  for (const img of images) {
    if (img.complete || img.style.opacity !== '' || motionOff()) continue
    gsap.set(img, { opacity: 0 })
    const show = () => {
      const release = busy(img)
      gsap.fromTo(img, { opacity: 0, scale: 1.06, filter: 'blur(8px)' }, { opacity: 1, scale: 1, filter: 'blur(0px)', duration: 0.7, ease: ease.out, clearProps: 'opacity,transform,filter', onComplete: release, onInterrupt: release })
    }
    img.addEventListener('load', show, { once: true })
    img.addEventListener('error', () => gsap.set(img, { clearProps: 'opacity' }), { once: true })
  }
}

function onMutations(records: MutationRecord[]) {
  const added = new Set<HTMLElement>()
  const removed: { el: HTMLElement; parent: Node; next: Node | null }[] = []
  for (const record of records) {
    record.addedNodes.forEach((node) => {
      if (node instanceof HTMLElement && !node.hasAttribute(GHOST_ATTR)) added.add(node)
    })
    record.removedNodes.forEach((node) => {
      if (node instanceof HTMLElement && !node.hasAttribute(GHOST_ATTR)) {
        removed.push({ el: node, parent: record.target, next: record.nextSibling })
      }
    })
  }
  for (const { el, parent, next } of removed) {
    if (!el.isConnected) exitTree(el, parent, next)
  }
  const roots = [...added].filter((el) => el.isConnected && !removed.some((r) => r.el === el))
  const overlays: HTMLElement[] = []
  for (const el of roots) {
    enterTree(el, overlays)
    enterImages(el)
    if (el.dataset.motionShared) enterShared(el)
    el.querySelectorAll<HTMLElement>('[data-motion-shared]').forEach(enterShared)
  }
  revealLive(roots, overlays)
}

export function installPresence() {
  new MutationObserver(onMutations).observe(document.body, { childList: true, subtree: true })
  document.addEventListener('pointerdown', measureShared, true)
  document.addEventListener('keydown', measureShared, true)
  window.addEventListener('resize', measureShared)
}
