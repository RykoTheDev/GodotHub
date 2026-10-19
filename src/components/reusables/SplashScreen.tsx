import { motion } from 'framer-motion'
import { useUiMotion } from '../../hooks/useUiMotion'

export type SplashPhase = 'enter' | 'fly' | 'fade'

interface SplashScreenProps {
  phase: SplashPhase
}

export function SplashScreen({ phase }: SplashScreenProps) {
  const exiting = phase !== 'enter'
  const {transition, reduced, instant} = useUiMotion()

  return (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center bg-base"
      animate={{ opacity: exiting ? 0 : 1 }}
      transition={transition('modal')}
      style={{ pointerEvents: exiting ? 'none' : 'auto' }}
    >
      <div
        className="flex flex-col items-center gap-6 select-none"
      >
        <div className="flex flex-col items-center gap-3">
          <h1
            className="font-black italic tracking-tight leading-none text-ink text-[56px]"
          >
            GodotHub
          </h1>

          <div
            className="relative h-[3px] w-40 rounded-full bg-raised overflow-hidden"
          >
            <motion.div
              initial={reduced || instant ? false : { transform: 'translateX(-100%)' }}
              animate={{ transform: reduced || instant ? 'none' : 'translateX(100%)' }}
              transition={{
                duration: reduced || instant ? 0 : 1.1,
                repeat: reduced || instant ? 0 : Infinity,
                ease: 'linear',
              }}
              className="absolute inset-y-0 w-1/2 rounded-full bg-linear-to-r from-transparent via-accent to-transparent"
            />
          </div>
        </div>
      </div>
    </motion.div>
  )
}
