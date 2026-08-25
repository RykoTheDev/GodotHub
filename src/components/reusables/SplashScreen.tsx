import { motion } from 'framer-motion'

export type SplashPhase = 'enter' | 'fly' | 'fade'

interface SplashScreenProps {
  phase: SplashPhase
}

export function SplashScreen({ phase }: SplashScreenProps) {
  const exiting = phase !== 'enter'

  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center bg-base"
      animate={{ opacity: exiting ? 0 : 1 }}
      transition={{ duration: 0.5, ease: 'easeInOut' }}
      style={{ pointerEvents: exiting ? 'none' : 'auto' }}
    >
      <motion.div
        layoutId="brand-splash"
        layout
        initial={{ y: 0, scale: 1 }}
        animate={{
          y: phase === 'fly' ? -40 : 0,
          scale: phase === 'fly' ? 1.06 : 1,
        }}
        transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
        className="flex flex-col items-center gap-6 select-none"
      >
        <div className="flex flex-col items-center gap-3">
          <motion.h1
            initial={{ opacity: 0, y: 18, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1], delay: 0.3 }}
            className="font-black italic tracking-tight leading-none text-ink text-[56px]"
          >
            GodotHub
          </motion.h1>

          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.55 }}
            className="relative h-[3px] w-40 rounded-full bg-raised overflow-hidden"
          >
            <motion.div
              initial={{ x: '-100%' }}
              animate={{ x: '100%' }}
              transition={{
                duration: 1.1,
                repeat: Infinity,
                ease: 'easeInOut',
                delay: 0.5,
              }}
              className="absolute inset-y-0 w-1/2 rounded-full bg-linear-to-r from-transparent via-accent to-transparent"
            />
          </motion.div>
        </div>
      </motion.div>
    </motion.div>
  )
}
