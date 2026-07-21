import { createContext, useContext, type ReactNode } from 'react'
import { useCategories } from './useCategories'

export type CategoriesApi = ReturnType<typeof useCategories>

const CategoriesContext = createContext<CategoriesApi | null>(null)

export function CategoriesProvider({ children }: { children: ReactNode }) {
  const value = useCategories()
  return (
    <CategoriesContext.Provider value={value}>
      {children}
    </CategoriesContext.Provider>
  )
}

export function useCategoriesContext() {
  const ctx = useContext(CategoriesContext)
  if (!ctx)
    throw new Error(
      'useCategoriesContext must be used within a CategoriesProvider',
    )
  return ctx
}
