import { useSyncExternalStore, type ReactNode } from 'react'
import { MotionConfig, type Transition } from 'framer-motion'
import { getMotionSnapshot, subscribeMotionPreferences } from '../lib/appearance'
import { easeOut, motionDuration } from '../lib/motion'

// motion-dom supports per-transition reduction (including live changes), while
// framer-motion's public Transition alias does not yet expose that field.
type UiTransition = Transition & { reduceMotion: boolean }

export function useUiMotion() {
  const snapshot = useSyncExternalStore(subscribeMotionPreferences, getMotionSnapshot, () => 'none|true|true')
  return resolveUiMotion(snapshot)
}

export function resolveUiMotion(snapshot: string) {
  const [intensity, systemReduced, keyboard] = snapshot.split('|')
  const instant = intensity === 'none' || keyboard === 'true'
  const reduced = intensity !== 'full' || systemReduced === 'true'
  const transition = (kind: keyof typeof motionDuration, exit = false): UiTransition => ({
    type: 'tween', ease: easeOut,
    duration: instant ? 0 : reduced || exit ? motionDuration.exit : motionDuration[kind],
    reduceMotion: reduced,
  })
  const surface = (kind: keyof typeof motionDuration, from = 'scale(0.96)', skip = false) => {
    // Motion interpolates complex transform strings to "none" by zeroing their
    // numbers, including scale. Keep matching functions with explicit identity
    // values so a finished entrance cannot leave a surface at scale(0).
    const rest = from
      .replace(/scale\([^)]+\)/g, 'scale(1)')
      .replace(/translate([XY])\([^)]+\)/g, 'translate$1(0px)')
    const closed = reduced || instant || skip ? rest : from
    return {
      initial: instant || skip ? false as const : {opacity:0, transform:closed},
      animate: {opacity:1, transform:rest},
      exit: {opacity:0, transform:closed, transition:skip ? {duration:0} : transition(kind, true)},
      transition:skip ? {duration:0} : transition(kind),
    }
  }
  return { instant, reduced, transition, surface }
}

/** Covers legacy Motion components as well as the shared UI primitives. */
export function UiMotionProvider({ children }: { children: ReactNode }) {
  const {instant, reduced} = useUiMotion()
  const defaultTransition: UiTransition = {type:'tween', duration:instant ? 0 : reduced ? motionDuration.exit : motionDuration.popover, ease:easeOut, reduceMotion:reduced,
    ...(reduced ? {transform:{type:false as const}} : {})}
  return <MotionConfig reducedMotion={reduced ? 'always' : 'never'} skipAnimations={instant}
    transition={defaultTransition}>
    {children}
  </MotionConfig>
}
