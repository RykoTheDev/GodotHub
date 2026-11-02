import { setMotionPrefs, syncReducedMotion, type MotionPrefs } from './core'
import { installInteractions } from './interactions'
import { installPresence } from './presence'
import { flushPending } from './reveal'

export { busy, ease, gsap, motionOff } from './core'
export type { MotionIntensity, MotionPrefs, ViewEntrance } from './core'
export { enableLiveReveal, revealView } from './reveal'
export { introShell } from './intro'
export { spin } from './interactions'

export function installMotion() {
  syncReducedMotion()
  installPresence()
  installInteractions()
}

export function configureMotion(next: Partial<MotionPrefs>) {
  setMotionPrefs(next)
  if (next.scrollReveal === false || next.entrance === 'none' || next.intensity === 'none') flushPending()
}
