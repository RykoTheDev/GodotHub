import { useState } from 'react'
import { motion } from 'framer-motion'

interface Props {
  projectName: string
  currentArgs: string
  onSave: (args: string) => void
  onClose: () => void
}

const SUGGESTIONS = [
  { label: '--debug', description: 'Run with debugger attached' },
  { label: '--single-window', description: 'Force single window mode' },
  {
    label: '--rendering-driver opengl3',
    description: 'Use OpenGL 3 rendering driver',
  },
  {
    label: '--rendering-driver vulkan',
    description: 'Use Vulkan rendering driver',
  },
  { label: '--headless', description: 'Run without a window' },
  { label: '--verbose', description: 'Log detailed debug output' },
  { label: '--editor', description: 'Open the editor (same as -e)' },
  { label: '--build-solutions', description: 'Build C# solutions on open' },
  { label: '--gpu-index 1', description: 'Use GPU index 1 (dedicated GPU)' },
]

export function LaunchArgsModal({
  projectName,
  currentArgs,
  onSave,
  onClose,
}: Props) {
  const [args, setArgs] = useState(currentArgs)

  const append = (flag: string) => {
    setArgs((prev) => {
      const trimmed = prev.trim()
      return trimmed ? `${trimmed} ${flag}` : flag
    })
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-7 w-full max-w-lg flex flex-col gap-5 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div>
          <h3 className="font-display font-semibold text-lg">
            Launch Arguments
          </h3>
          <p className="text-xs text-muted mt-1.5">
            Custom CLI flags passed to Godot when opening{' '}
            <span className="font-medium text-ink">{projectName}</span>.
          </p>
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-xs font-medium text-muted">Arguments</label>
          <input
            value={args}
            onChange={(e) => setArgs(e.target.value)}
            placeholder="e.g. --debug --single-window"
            className="focus-ring bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm font-mono text-ink focus:border-accent-dim transition-colors"
          />
          <p className="text-[11px] text-muted/60">
            Separate arguments with spaces. Flags with values like{' '}
            <code className="text-muted">--rendering-driver opengl3</code> use
            two tokens.
          </p>
        </div>

        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">Suggestions</span>
          <div className="flex flex-wrap gap-1.5">
            {SUGGESTIONS.map((s) => (
              <button
                key={s.label}
                type="button"
                onClick={() => append(s.label)}
                title={s.description}
                className="focus-ring cursor-pointer px-2.5 py-1 rounded-md bg-raised border border-line text-[11px] font-mono text-muted hover:text-ink hover:border-accent-dim transition-colors"
              >
                {s.label}
              </button>
            ))}
          </div>
        </div>

        <div className="flex justify-end gap-2.5 mt-1">
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            Cancel
          </motion.button>
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={() => onSave(args.trim())}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg bg-accent hover:bg-accent-bright text-sm font-medium text-white transition-colors"
          >
            Save
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  )
}
