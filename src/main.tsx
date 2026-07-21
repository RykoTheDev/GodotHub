import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { ErrorBoundary } from './ErrorBoundary'
import { SettingsProvider } from './hooks/useSettings'
import { WorkspacesProvider } from './hooks/useWorkspaces'
import { ProjectsProvider } from './hooks/projectsContext'
import { CategoriesProvider } from './hooks/categoriesContext'

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <ErrorBoundary>
      <WorkspacesProvider>
        <SettingsProvider>
          <ProjectsProvider>
            <CategoriesProvider>
              <App />
            </CategoriesProvider>
          </ProjectsProvider>
        </SettingsProvider>
      </WorkspacesProvider>
    </ErrorBoundary>
  </React.StrictMode>,
)
