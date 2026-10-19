import type { TargetAndTransition, Transition } from 'framer-motion'

export type AnimationIntensity = 'full' | 'subtle' | 'none'

export type ViewEntrance = 'fade' | 'slide' | 'scale' | 'none'

export const overlayTransition: Transition = { duration: 0.12, ease: 'easeOut' }

export const disclosureMotion = {
  durationMs: 200,
  easing: 'cubic-bezier(0.23, 1, 0.32, 1)',
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
      initial: { opacity: 0, scale: 0.98 },
      animate: { opacity: 1, scale: 1 },
      transition: { duration, ease },
    }
  }
  if (entrance === 'slide') {
    return {
      initial: { opacity: 0, y: 10 },
      animate: { opacity: 1, y: 0 },
      transition: { duration, ease },
    }
  }
  return {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    transition: { duration, ease },
  }
}
