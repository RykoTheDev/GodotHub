import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  IconSearch,
  IconDownload,
  IconX,
} from './Icons'

interface Tip {
  title: string
  description: string
  icon: typeof IconSearch
}

const TIPS: Tip[] = [
  {
    title: 'Search Settings',
    description:
      'Use the search bar at the top of the Settings page to instantly find any option across all tabs.',
    icon: IconSearch,
  },
  {
    title: 'Command Palette',
    description:
      'Press Ctrl+K to open the command palette. Quickly navigate projects, versions, and settings from anywhere.',
    icon: IconSearch,
  },
  {
    title: 'Drag & Drop Import',
    description:
      'Drop Godot project folders or .zip version files anywhere on the window to instantly import them into your library.',
    icon: IconDownload,
  },
]

export function OnboardingTips({ onDismiss }: { onDismiss: () => void }) {
  const [step, setStep] = useState(0)
  const current = TIPS[step]
  const isLast = step === TIPS.length - 1

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.2 }}
      className="fixed inset-0 z-200 flex items-center justify-center p-4"
      onClick={onDismiss}
    >
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />

      <motion.div
        key={step}
        initial={{ opacity: 0, y: 16, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: -16, scale: 0.95 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="relative z-10 bg-surface border border-line rounded-2xl p-8 w-full max-w-sm flex flex-col items-center gap-5 text-center shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Step indicator dots */}
        <div className="flex items-center gap-2">
          {TIPS.map((_, i) => (
            <button
              key={i}
              onClick={() => setStep(i)}
              className={`focus-ring cursor-pointer w-2 h-2 rounded-full transition-all duration-300 ${
                i === step
                  ? 'bg-accent w-5'
                  : 'bg-line hover:bg-muted/50'
              }`}
              aria-label={`Tip ${i + 1}`}
            />
          ))}
        </div>

        {/* Icon */}
        <div className="w-14 h-14 rounded-2xl bg-accent/10 flex items-center justify-center">
          <current.icon className="w-6 h-6 text-accent-bright" />
        </div>

        {/* Content */}
        <div>
          <h3 className="font-display font-semibold text-lg text-ink">
            {current.title}
          </h3>
          <p className="text-sm text-muted mt-2 leading-relaxed">
            {current.description}
          </p>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3 w-full">
          {!isLast ? (
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => setStep((s) => Math.min(s + 1, TIPS.length - 1))}
              className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-white text-sm font-medium transition-colors"
            >
              Next Tip
            </motion.button>
          ) : (
            <motion.button
              whileHover={{ y: -1 }}
              whileTap={{ scale: 0.96 }}
              onClick={onDismiss}
              className="focus-ring cursor-pointer flex-1 px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-white text-sm font-medium transition-colors"
            >
              Got It!
            </motion.button>
          )}
          <button
            onClick={onDismiss}
            className="focus-ring cursor-pointer p-2.5 rounded-lg text-muted hover:text-ink hover:bg-raised transition-colors"
            aria-label="Close"
          >
            <IconX className="w-4 h-4" />
          </button>
        </div>
      </motion.div>
    </motion.div>
  )
}
