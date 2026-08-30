import React, { createContext, createElement, useCallback, useContext, useEffect, useState, type ReactNode } from 'react'
import { check } from '@tauri-apps/plugin-updater'

interface UpdateAvailableContextValue {
  updateAvailable: boolean
  dismissUpdate: () => void
  previewUpdate: boolean
  setPreviewUpdate: React.Dispatch<React.SetStateAction<boolean>>
}

const UpdateAvailableContext = createContext<UpdateAvailableContextValue | null>(null)

export function UpdateAvailableProvider({ children }: { children: ReactNode }) {
  const [updateAvailable, setUpdateAvailable] = useState(false)
  const [previewUpdate, setPreviewUpdate] = useState(false)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const update = await check()
        if (!cancelled && update) {
          setUpdateAvailable(true)
        }
      } catch {}
    })()
    return () => { cancelled = true }
  }, [])

  const dismissUpdate = useCallback(() => setUpdateAvailable(false), [])

  return createElement(
    UpdateAvailableContext.Provider,
    { value: { updateAvailable, dismissUpdate, previewUpdate, setPreviewUpdate } },
    children,
  )
}

export function useUpdateAvailable() {
  const ctx = useContext(UpdateAvailableContext)
  if (!ctx) {
    throw new Error('useUpdateAvailable() must be used within an <UpdateAvailableProvider>')
  }
  return ctx
}
