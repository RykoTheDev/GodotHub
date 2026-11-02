import { syncReducedMotion } from './core'
import { installInteractions } from './interactions'
import { installPresence } from './presence'

export { busy, ease, gsap, prefersReducedMotion } from './core'
export { enableLiveReveal, revealView } from './reveal'
export { introShell } from './intro'
export { spin } from './interactions'

export function installMotion() {
  syncReducedMotion()
  installPresence()
  installInteractions()
}
