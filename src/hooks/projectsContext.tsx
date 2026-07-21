import { createContext, useContext, type ReactNode } from 'react'
import { useProjects } from './useProjects'

export type ProjectsApi = ReturnType<typeof useProjects>

const ProjectsContext = createContext<ProjectsApi | null>(null)

export function ProjectsProvider({ children }: { children: ReactNode }) {
  const value = useProjects()
  return (
    <ProjectsContext.Provider value={value}>
      {children}
    </ProjectsContext.Provider>
  )
}

export function useProjectsContext() {
  const ctx = useContext(ProjectsContext)
  if (!ctx)
    throw new Error(
      'useProjectsContext must be used within a ProjectsProvider',
    )
  return ctx
}
