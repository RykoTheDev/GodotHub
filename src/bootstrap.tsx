import React from 'react'
import ReactDOM from 'react-dom/client'
import { invoke } from '@tauri-apps/api/core'
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
import { i18nReady } from './i18n'
import { installMotion } from './lib/motion'

installMotion()

// Two frames: the first paints the shell, the second means the webview really
// draws with the rendering path WebKitGTK picked on this machine.
function signalRendererHealthy() {
  if (!('__TAURI_INTERNALS__' in window)) return
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      invoke('renderer_healthy').catch(() => {})
    })
  })
}

function render() {
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
  signalRendererHealthy()
}

i18nReady.then(render, render)
