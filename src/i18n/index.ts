import i18n, { type BackendModule } from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import { SYSTEM_LANGUAGE, getSystemLanguage } from './languages'
import { uiPrefs } from '../lib/uiPrefs'

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

const LANGUAGE_KEY = 'i18nextLng'

if (uiPrefs.getItem(LANGUAGE_KEY) === SYSTEM_LANGUAGE) {
  uiPrefs.setItem(LANGUAGE_KEY, getSystemLanguage())
}

const languageDetector = new LanguageDetector()
languageDetector.addDetector({
  name: 'uiPrefs',
  lookup: () => uiPrefs.getItem(LANGUAGE_KEY) ?? undefined,
  cacheUserLanguage: (lng) => uiPrefs.setItem(LANGUAGE_KEY, lng),
})

export const i18nReady = i18n
  .use(localeBackend)
  .use(languageDetector)
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
      order: ['uiPrefs', 'navigator'],
      caches: ['uiPrefs'],
    },
  })

const RTL_LAYOUT_KEY = 'godothub_rtl_layout'

let rtlLayout = uiPrefs.getItem(RTL_LAYOUT_KEY) === '1'

function syncDocumentLanguage(lng: string): void {
  const textDir = i18n.dir(lng)
  document.documentElement.lang = lng
  document.documentElement.dir = textDir === 'rtl' && rtlLayout ? 'rtl' : 'ltr'
  document.documentElement.dataset.textDir = textDir
}

export function setRtlLayout(enabled: boolean): void {
  if (enabled === rtlLayout) return
  rtlLayout = enabled
  uiPrefs.setItem(RTL_LAYOUT_KEY, enabled ? '1' : '0')
  syncDocumentLanguage(i18n.resolvedLanguage || i18n.language || 'en-US')
}

i18n.on('languageChanged', syncDocumentLanguage)
syncDocumentLanguage(i18n.resolvedLanguage || i18n.language || 'en-US')

export default i18n
