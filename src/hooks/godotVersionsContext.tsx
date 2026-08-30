import { createContextProvider } from '../lib/createContextProvider'
import { useGodotVersions } from './useGodotVersions'

export type GodotVersionsApi = ReturnType<typeof useGodotVersions>

export const { Provider: GodotVersionsProvider, useCtx: useGodotVersionsContext } =
  createContextProvider(useGodotVersions, 'GodotVersionsProvider')
