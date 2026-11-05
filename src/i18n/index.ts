import i18n, { type BackendModule } from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import { SYSTEM_LANGUAGE, getSystemLanguage } from './languages'

import enUSNav from './locales/en-US/nav.json'
import enUSCommon from './locales/en-US/common.json'
import enUSSettings from './locales/en-US/settings.json'
import enUSGit from './locales/en-US/git.json'
import enUSChangelog from './locales/en-US/changelog.json'
import enUSOnboarding from './locales/en-US/onboarding.json'
import enUSVersions from './locales/en-US/versions.json'
import enUSDashboard from './locales/en-US/dashboard.json'
import enUSTodos from './locales/en-US/todos.json'

const enUS = {
  nav: enUSNav,
  common: enUSCommon,
  settings: enUSSettings,
  git: enUSGit,
  changelog: enUSChangelog,
  onboarding: enUSOnboarding,
  versions: enUSVersions,
  dashboard: enUSDashboard,
  todos: enUSTodos,
}

const localeLoaders = import.meta.glob<{ default: Record<string, string> }>([
  './locales/*/*.json',
  '!./locales/en-US/*.json',
])

const localeBackend: BackendModule = {
  type: 'backend',
  init() {},
  read(language, namespace, callback) {
    const load = localeLoaders[`./locales/${language}/${namespace}.json`]
    if (!load) {
      callback(null, {})
      return
    }
    load().then(
      (module) => callback(null, module.default),
      (error: Error) => callback(error, false),
    )
  },
}

try {
  if (localStorage.getItem('i18nextLng') === SYSTEM_LANGUAGE) {
    localStorage.setItem('i18nextLng', getSystemLanguage())
  }
} catch {}

export const i18nReady = i18n
  .use(localeBackend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: { 'en-US': enUS },
    partialBundledLanguages: true,
    ns: Object.keys(enUS),
    fallbackLng: 'en-US',
    fallbackNS: ['common'],
    defaultNS: 'common',
    interpolation: {
      escapeValue: false,
    },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
    },
  })

const RTL_LAYOUT_KEY = 'godothub_rtl_layout'

let rtlLayout = (() => {
  try {
    return localStorage.getItem(RTL_LAYOUT_KEY) === '1'
  } catch {
    return false
  }
})()

function syncDocumentLanguage(lng: string): void {
  const textDir = i18n.dir(lng)
  document.documentElement.lang = lng
  document.documentElement.dir = textDir === 'rtl' && rtlLayout ? 'rtl' : 'ltr'
  document.documentElement.dataset.textDir = textDir
}

export function setRtlLayout(enabled: boolean): void {
  if (enabled === rtlLayout) return
  rtlLayout = enabled
  try {
    localStorage.setItem(RTL_LAYOUT_KEY, enabled ? '1' : '0')
  } catch {}
  syncDocumentLanguage(i18n.resolvedLanguage || i18n.language || 'en-US')
}

i18n.on('languageChanged', syncDocumentLanguage)
syncDocumentLanguage(i18n.resolvedLanguage || i18n.language || 'en-US')

export default i18n
