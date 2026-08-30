import { createContextProvider } from '../lib/createContextProvider'
import { useProjects } from './useProjects'

export type ProjectsApi = ReturnType<typeof useProjects>

export const { Provider: ProjectsProvider, useCtx: useProjectsContext } =
  createContextProvider(useProjects, 'ProjectsProvider')
