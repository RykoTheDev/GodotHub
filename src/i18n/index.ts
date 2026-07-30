import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import enUSNav from './locales/en-US/nav.json'
import enUSCommon from './locales/en-US/common.json'
import enUSSettings from './locales/en-US/settings.json'
import enUSGit from './locales/en-US/git.json'
import enUSChangelog from './locales/en-US/changelog.json'
import enUSOnboarding from './locales/en-US/onboarding.json'
import enUSVersions from './locales/en-US/versions.json'
import zhCNNav from './locales/zh-CN/nav.json'
import zhCNCommon from './locales/zh-CN/common.json'
import zhCNSettings from './locales/zh-CN/settings.json'
import zhCNGit from './locales/zh-CN/git.json'
import zhCNChangelog from './locales/zh-CN/changelog.json'
import zhCNOnboarding from './locales/zh-CN/onboarding.json'
import zhCNVersions from './locales/zh-CN/versions.json'

const zhCNResources = {
  nav: zhCNNav,
  common: zhCNCommon,
  settings: zhCNSettings,
  git: zhCNGit,
  changelog: zhCNChangelog,
  onboarding: zhCNOnboarding,
  versions: zhCNVersions,
}

const resources = {
  'en-US': {
    nav: enUSNav,
    common: enUSCommon,
    settings: enUSSettings,
    git: enUSGit,
    changelog: enUSChangelog,
    onboarding: enUSOnboarding,
    versions: enUSVersions,
  },
  'zh-CN': zhCNResources,
  zh: zhCNResources,
}

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    fallbackLng: 'en-US',
    defaultNS: 'common',
    interpolation: {
      escapeValue: false,
    },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
    },
  })

export default i18n
