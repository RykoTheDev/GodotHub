import { useEffect, useState } from 'react'
import {
  getCurrentWindow,
  type Window as TauriWindow,
} from '@tauri-apps/api/window'
import { motion } from 'framer-motion'
import { version } from '../../package.json'
import { Tooltip } from './ui/Tooltip'

export function TitleBar() {
  const [appWindow, setAppWindow] = useState<TauriWindow | null>(null)
  const [isMaximized, setIsMaximized] = useState(false)
  const [isHovered, setIsHovered] = useState(false)

  useEffect(() => {
    let unlisten: (() => void) | undefined
    try {
      const w = getCurrentWindow()
      setAppWindow(w)
      w.isMaximized()
        .then(setIsMaximized)
        .catch(() => {})
      w.onResized(() => {
        w.isMaximized()
          .then(setIsMaximized)
          .catch(() => {})
      })
        .then((f) => {
          unlisten = f
        })
        .catch(() => {})
    } catch {}
    return () => unlisten?.()
  }, [])

  const safe = (fn: (w: TauriWindow) => void) => {
    if (appWindow) {
      try {
        fn(appWindow)
      } catch {}
    }
  }

  return (
    <div className="relative h-10 flex items-stretch bg-surface border-line border-b select-none shrink-0">
      <div
        data-tauri-drag-region
        onDoubleClick={() => safe((w) => w.toggleMaximize())}
        className="flex-1 flex items-center px-4 min-w-0"
      ></div>

      <div
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-auto select-none"
      >
        <motion.h1
          layoutId="brand-title"
          layout
          transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          animate={{
            opacity: isHovered ? 0 : 1,
            y: isHovered ? -10 : 0,
            transition: { duration: 0.22, ease: 'easeInOut' },
          }}
          className="font-black italic tracking-tight text-xl text-muted flex items-center gap-2"
        >
          GodotHub
          <Tooltip content="See what's new and upcoming →" side="bottom">
            <button
              onClick={() => window.dispatchEvent(new CustomEvent('app:switch-tab', { detail: 4 }))}
              className="text-[9px] mb-2 font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-md bg-amber/15 text-amber border border-amber/30 hover:bg-amber/25 hover:border-amber/50 cursor-pointer shrink-0 transition-colors"
            >
              Beta
            </button>
          </Tooltip>
        </motion.h1>
        <motion.p
          initial={false}
          animate={{
            opacity: isHovered ? 1 : 0,
            y: isHovered ? 0 : 10,
          }}
          transition={{ duration: 0.22, ease: 'easeInOut' }}
          className="absolute inset-0 flex items-center justify-center font-mono text-xs text-muted/70"
        >
          v{version}
        </motion.p>
      </div>

      <div className="flex items-stretch gap-1 px-3">
        <motion.button
          onClick={() => safe((w) => w.minimize())}
          aria-label="Minimize"
          className="w-6 cursor-pointer flex items-center justify-center text-muted hover:text-ink transition-colors shrink-0"
          whileHover={{
            y: -2,
            scale: 1.1,
          }}
          transition={{
            type: 'spring',
            stiffness: 500,
            damping: 30,
          }}
        >
          <div className="w-4 h-4 bg-green-400 rounded-full" />
        </motion.button>

        <motion.button
          onClick={() => safe((w) => w.toggleMaximize())}
          aria-label={isMaximized ? 'Restore' : 'Maximize'}
          className="w-6 cursor-pointer flex items-center justify-center text-muted hover:text-ink transition-colors shrink-0"
          whileHover={{
            y: -2,
            scale: 1.1,
          }}
          transition={{
            type: 'spring',
            stiffness: 500,
            damping: 30,
          }}
        >
          <div className="w-4 h-4 bg-amber rounded-full" />
        </motion.button>

        <motion.button
          onClick={() => safe((w) => w.close())}
          aria-label="Close"
          className="w-6 cursor-pointer flex items-center justify-center text-muted hover:text-white transition-colors shrink-0"
          whileHover={{
            y: -2,
            scale: 1.1,
          }}
          transition={{
            type: 'spring',
            stiffness: 500,
            damping: 30,
          }}
        >
          <div className="w-4 h-4 bg-red-400 rounded-full" />
        </motion.button>
      </div>
    </div>
  )
}
