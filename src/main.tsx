import '@fontsource-variable/inter'
import '@fontsource/google-sans-code/400.css'
import '@fontsource/google-sans-code/500.css'
import './index.css'
import { installDevMocks } from './lib/devMock'
import { loadUiPrefs } from './lib/uiPrefs'

installDevMocks()

void loadUiPrefs().then(() => import('./bootstrap'))
