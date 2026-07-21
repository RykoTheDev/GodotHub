import { createContext, useContext, type ReactNode } from 'react'
import { useGodotVersions } from './useGodotVersions'

type GodotVersionsApi = ReturnType<typeof useGodotVersions>

const GodotVersionsContext = createContext<GodotVersionsApi | null>(null)

export function GodotVersionsProvider({ children }: { children: ReactNode }) {
  const value = useGodotVersions()
  return (
    <GodotVersionsContext.Provider value={value}>
      {children}
    </GodotVersionsContext.Provider>
  )
}

export function useGodotVersionsContext() {
  const ctx = useContext(GodotVersionsContext)
  if (!ctx)
    throw new Error(
      'useGodotVersionsContext must be used within a GodotVersionsProvider',
    )
  return ctx
}
