import type { TargetAndTransition, Transition } from 'framer-motion'

export type AnimationIntensity = 'full' | 'subtle' | 'none'

export type ViewEntrance = 'fade' | 'slide' | 'scale' | 'none'

export function entranceDuration(intensity: AnimationIntensity): number {
  if (intensity === 'none') return 0
  return intensity === 'subtle' ? 0.08 : 0.18
}

interface ViewTransitionProps {
  initial: TargetAndTransition | boolean
  animate: TargetAndTransition
  exit?: TargetAndTransition
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
  if (entrance === 'scale') {
    return {
      initial: { opacity: 0, scale: 0.97 },
      animate: { opacity: 1, scale: 1 },
      exit: { opacity: 0, scale: 0.97 },
      transition: { duration, ease: 'easeOut' },
    }
  }
  if (entrance === 'slide') {
    return {
      initial: { opacity: 0, y: 12 },
      animate: { opacity: 1, y: 0 },
      exit: { opacity: 0, y: -8 },
      transition: { duration, ease: 'easeOut' },
    }
  }
  return {
    initial: { opacity: 0 },
    animate: { opacity: 1 },
    exit: { opacity: 0 },
    transition: { duration, ease: 'easeOut' },
  }
}
