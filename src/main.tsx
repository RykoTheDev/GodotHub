import React from 'react'
import ReactDOM from 'react-dom/client'
import { App } from './App'
import { ErrorBoundary } from './ErrorBoundary'
import { SettingsProvider } from './hooks/useSettings'
import { WorkspacesProvider } from './hooks/useWorkspaces'
import { ProjectsProvider } from './hooks/projectsContext'
import { CategoriesProvider } from './hooks/categoriesContext'
import { UpdatesBadgeProvider } from './hooks/useUpdatesBadge'
import { UpdateAvailableProvider } from './hooks/useUpdateAvailable'
import { GodotVersionsProvider } from './hooks/godotVersionsContext'
import { TaskTrayProvider } from './hooks/useTaskTray'
import '@fontsource-variable/inter'
import '@fontsource/google-sans-code/400.css'
import '@fontsource/google-sans-code/500.css'
import './i18n'
import './index.css'
import { initReducedMotionDetection } from './lib/appearance'

initReducedMotionDetection()

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <ErrorBoundary>
      <WorkspacesProvider>
        <SettingsProvider>
          <ProjectsProvider>
            <CategoriesProvider>
              <UpdatesBadgeProvider>
                <UpdateAvailableProvider>
                  <GodotVersionsProvider>
                    <TaskTrayProvider>
                      <App />
                    </TaskTrayProvider>
                  </GodotVersionsProvider>
                </UpdateAvailableProvider>
              </UpdatesBadgeProvider>
            </CategoriesProvider>
          </ProjectsProvider>
        </SettingsProvider>
      </WorkspacesProvider>
    </ErrorBoundary>
  </React.StrictMode>,
)
