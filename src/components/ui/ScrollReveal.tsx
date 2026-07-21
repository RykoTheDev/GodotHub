import { motion } from 'framer-motion'
import type { HTMLMotionProps } from 'framer-motion'

interface Props extends HTMLMotionProps<'div'> {
  children: React.ReactNode
  className?: string
  delay?: number
}

export function ScrollReveal({ children, className, delay = 0, ...rest }: Props) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 48, scale: 0.92 }}
      whileInView={{ opacity: 1, y: 0, scale: 1 }}
      viewport={{ once: true, margin: '-40px' }}
      transition={{
        duration: 0.5,
        ease: [0.22, 1, 0.36, 1],
        delay,
      }}
      className={className}
      {...rest}
    >
      {children}
    </motion.div>
  )
}
