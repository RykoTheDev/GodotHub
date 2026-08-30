import { createContextProvider } from '../lib/createContextProvider'
import { useCategories } from './useCategories'

export type CategoriesApi = ReturnType<typeof useCategories>

export const { Provider: CategoriesProvider, useCtx: useCategoriesContext } =
  createContextProvider(useCategories, 'CategoriesProvider')
