import type { TargetAndTransition, Transition } from 'framer-motion'

export type AnimationIntensity = 'full' | 'subtle' | 'none'

export type ViewEntrance = 'fade' | 'slide' | 'scale' | 'none'

export const easeOut = [0.23, 1, 0.32, 1] as const
export const easeOutCss = 'cubic-bezier(0.23, 1, 0.32, 1)'
export const motionDuration = { press: 0.16, tooltip: 0.125, popover: 0.2, modal: 0.2, exit: 0.125 } as const
export const overlayTransition: Transition = { type: 'tween', duration: motionDuration.exit, ease: easeOut }

export const disclosureMotion = {
  durationMs: 200,
  easing: easeOutCss,
} as const

export function entranceDuration(intensity: AnimationIntensity): number {
  if (intensity === 'none') return 0
  return intensity === 'subtle' ? 0.08 : 0.15
}

interface ViewTransitionProps {
  initial: TargetAndTransition | boolean
  animate: TargetAndTransition
  transition: Transition
}

export function viewTransition(
  entrance: ViewEntrance,
  intensity: AnimationIntensity,
): ViewTransitionProps {
  const duration = entranceDuration(intensity)
  if (entrance === 'none' || intensity === 'none') {
    return {
      initial: false,
      animate: { opacity: 1 },
      transition: { duration: 0 },
    }
  }
  const ease = [0.23, 1, 0.32, 1] as const
  if (entrance === 'scale') {
    return {
      initial: { opacity: 0, transform: 'scale(0.97)' },
      animate: { opacity: 1, transform: 'scale(1)' },
      transition: { duration, ease },
    }
  }
  if (entrance === 'slide') {
    return {
      initial: { opacity: 0, transform: 'translateY(10px)' },
      animate: { opacity: 1, transform: 'translateY(0px)' },
      transition: { duration, ease },
    }
  }
  return {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    transition: { duration, ease },
  }
}
