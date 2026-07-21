import { motion } from 'framer-motion'

export type SplashPhase = 'enter' | 'fly' | 'fade'

interface SplashScreenProps {
  phase: SplashPhase
}

export function SplashScreen({ phase }: SplashScreenProps) {
  const splashOpacity = phase === 'enter' ? 1 : 0

  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center bg-base"
      animate={{ opacity: splashOpacity }}
      transition={{ duration: 0.5, ease: 'easeInOut' }}
      style={{ pointerEvents: splashOpacity === 0 ? 'none' : 'auto' }}
    >
      {phase === 'enter' && (
        <motion.h1
          layoutId="brand-title"
          layout
          initial={{ opacity: 0, scale: 0.6 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          className="font-black italic tracking-tight leading-none text-ink text-[64px] select-none"
        >
          GodotHub
        </motion.h1>
      )}
    </motion.div>
  )
}
