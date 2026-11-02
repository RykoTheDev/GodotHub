import React from 'react'
import ReactDOM from 'react-dom/client'
import { App } from './App'
import { ErrorBoundary } from './ErrorBoundary'
import { SettingsProvider } from './hooks/useSettings'
import { WorkspacesProvider } from './hooks/useWorkspaces'
import { ProjectsProvider } from './hooks/projectsContext'
import { CategoriesProvider } from './hooks/categoriesContext'
import { UpdateAvailableProvider } from './hooks/useUpdateAvailable'
import { GodotVersionsProvider } from './hooks/godotVersionsContext'
import { TaskTrayProvider } from './hooks/useTaskTray'
import { ChangelogBadgeProvider } from './hooks/useChangelogBadge'
import '@fontsource-variable/inter'
import '@fontsource/google-sans-code/400.css'
import '@fontsource/google-sans-code/500.css'
import './i18n'
import './index.css'
import { installDevMocks } from './lib/devMock'

installDevMocks()

ReactDOM.createRoot(document.getElementById('root') as HTMLElement).render(
  <React.StrictMode>
    <ErrorBoundary>
        <WorkspacesProvider>
          <SettingsProvider>
            <ProjectsProvider>
              <CategoriesProvider>
                <UpdateAvailableProvider>
                  <GodotVersionsProvider>
                    <TaskTrayProvider>
                      <ChangelogBadgeProvider>
                        <App />
                      </ChangelogBadgeProvider>
                    </TaskTrayProvider>
                  </GodotVersionsProvider>
                </UpdateAvailableProvider>
              </CategoriesProvider>
            </ProjectsProvider>
          </SettingsProvider>
        </WorkspacesProvider>
    </ErrorBoundary>
  </React.StrictMode>,
)
