import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import LanguageDetector from 'i18next-browser-languagedetector'

import arMANav from './locales/ar-MA/nav.json'
import arMACommon from './locales/ar-MA/common.json'
import arMASettings from './locales/ar-MA/settings.json'
import arMAGit from './locales/ar-MA/git.json'
import arMAChangelog from './locales/ar-MA/changelog.json'
import arMAOnboarding from './locales/ar-MA/onboarding.json'
import arMAVersions from './locales/ar-MA/versions.json'
import arMADashboard from './locales/ar-MA/dashboard.json'

import enUSNav from './locales/en-US/nav.json'
import enUSCommon from './locales/en-US/common.json'
import enUSSettings from './locales/en-US/settings.json'
import enUSGit from './locales/en-US/git.json'
import enUSChangelog from './locales/en-US/changelog.json'
import enUSOnboarding from './locales/en-US/onboarding.json'
import enUSVersions from './locales/en-US/versions.json'
import enUSDashboard from './locales/en-US/dashboard.json'

import ptBRNav from './locales/pt-BR/nav.json'
import ptBRCommon from './locales/pt-BR/common.json'
import ptBRSettings from './locales/pt-BR/settings.json'
import ptBRGit from './locales/pt-BR/git.json'
import ptBRChangelog from './locales/pt-BR/changelog.json'
import ptBROnboarding from './locales/pt-BR/onboarding.json'
import ptBRVersions from './locales/pt-BR/versions.json'
import ptBRDashboard from './locales/pt-BR/dashboard.json'

import esMXNav from "./locales/es-MX/nav.json"
import esMXCommon from './locales/es-MX/common.json'
import esMXSettings from './locales/es-MX/settings.json'
import esMXGit from './locales/es-MX/git.json'
import esMXChangelog from './locales/es-MX/changelog.json'
import esMXOnboarding from './locales/es-MX/onboarding.json'
import esMXVersions from './locales/es-MX/versions.json'
import esMXDashboard from './locales/es-MX/dashboard.json'

import frFRNav from './locales/fr-FR/nav.json'
import frFRCommon from './locales/fr-FR/common.json'
import frFRSettings from './locales/fr-FR/settings.json'
import frFRGit from './locales/fr-FR/git.json'
import frFRChangelog from './locales/fr-FR/changelog.json'
import frFROnboarding from './locales/fr-FR/onboarding.json'
import frFRVersions from './locales/fr-FR/versions.json'
import frFRDashboard from './locales/fr-FR/dashboard.json'

import jaJPNav from './locales/ja-JP/nav.json'
import jaJPCommon from './locales/ja-JP/common.json'
import jaJPSettings from './locales/ja-JP/settings.json'
import jaJPGit from './locales/ja-JP/git.json'
import jaJPChangelog from './locales/ja-JP/changelog.json'
import jaJPOnboarding from './locales/ja-JP/onboarding.json'
import jaJPVersions from './locales/ja-JP/versions.json'
import jaJPDashboard from './locales/ja-JP/dashboard.json'

import zhCNNav from './locales/zh-CN/nav.json'
import zhCNCommon from './locales/zh-CN/common.json'
import zhCNSettings from './locales/zh-CN/settings.json'
import zhCNGit from './locales/zh-CN/git.json'
import zhCNChangelog from './locales/zh-CN/changelog.json'
import zhCNOnboarding from './locales/zh-CN/onboarding.json'
import zhCNVersions from './locales/zh-CN/versions.json'
import zhCNDashboard from './locales/zh-CN/dashboard.json'

import ruRUNav from './locales/ru-RU/nav.json'
import ruRuCommon from './locales/ru-RU/common.json'
import ruRUSettings from './locales/ru-RU/settings.json'
import ruRUGit from './locales/ru-RU/git.json'
import ruRUChangelog from './locales/ru-RU/changelog.json'
import ruRUOnboarding from './locales/ru-RU/onboarding.json'
import ruRUVersions from './locales/ru-RU/versions.json'
import ruRUDashboard from './locales/ru-RU/dashboard.json'


import viVNChangelog from './locales/vi-VN/changelog.json'
import viVNCommon from './locales/vi-VN/common.json'
import viVNDashboard from './locales/vi-VN/dashboard.json'
import viVNGit from './locales/vi-VN/git.json'
import viVNNav from './locales/vi-VN/nav.json'
import viVNOnboarding from './locales/vi-VN/onboarding.json'
import viVNSettings from './locales/vi-VN/settings.json'
import viVNVersions from './locales/vi-VN/versions.json'


const arMAResources = {
  nav: arMANav,
  common: arMACommon,
  settings: arMASettings,
  git: arMAGit,
  changelog: arMAChangelog,
  onboarding: arMAOnboarding,
  versions: arMAVersions,
  dashboard: arMADashboard,
}

const ptBRResources = {
  nav: ptBRNav,
  common: ptBRCommon,
  settings: ptBRSettings,
  git: ptBRGit,
  changelog: ptBRChangelog,
  onboarding: ptBROnboarding,
  versions: ptBRVersions,
  dashboard: ptBRDashboard,
}

const esMXResources = {
  nav: esMXNav,
  common: esMXCommon,
  settings: esMXSettings,
  git: esMXGit,
  changelog: esMXChangelog,
  onboarding: esMXOnboarding,
  versions: esMXVersions,
  dashboard: esMXDashboard,
}

const jaJPResources = {
  nav: jaJPNav,
  common: jaJPCommon,
  settings: jaJPSettings,
  git: jaJPGit,
  changelog: jaJPChangelog,
  onboarding: jaJPOnboarding,
  versions: jaJPVersions,
  dashboard: jaJPDashboard,
}

const frFRResources = {
  nav: frFRNav,
  common: frFRCommon,
  settings: frFRSettings,
  git: frFRGit,
  changelog: frFRChangelog,
  onboarding: frFROnboarding,
  versions: frFRVersions,
  dashboard: frFRDashboard,
}

const zhCNResources = {
  nav: zhCNNav,
  common: zhCNCommon,
  settings: zhCNSettings,
  git: zhCNGit,
  changelog: zhCNChangelog,
  onboarding: zhCNOnboarding,
  versions: zhCNVersions,
  dashboard: zhCNDashboard,
}

const viVNResources = {
  changelog: viVNChangelog,
  common: viVNCommon,
  dashboard: viVNDashboard,
  git: viVNGit,
  nav: viVNNav,
  onboarding: viVNOnboarding,
  settings: viVNSettings,
  versions: viVNVersions,
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
    dashboard: enUSDashboard,
  },

  'pt-BR': ptBRResources,
  pt: ptBRResources,

  'es-MX': esMXResources,
  es: esMXResources,

  'zh-CN': zhCNResources,
  zh: zhCNResources,

  'ja-JP': jaJPResources,
  ja: jaJPResources,
  
  'fr-FR': frFRResources,
  fr: frFRResources,
  
  'ru-RU': {
    nav: ruRUNav,
    common: ruRuCommon,
    settings: ruRUSettings,
    git: ruRUGit,
    changelog: ruRUChangelog,
    onboarding: ruRUOnboarding,
    versions: ruRUVersions,
    dashboard: ruRUDashboard,
  },

  'ar-MA': arMAResources,
  ar: arMAResources,
  'vi-VN': viVNResources,
  vi: viVNResources,
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

// Chromium picks CJK font fallbacks and line-breaking rules from <html lang>,
// which index.html hardcodes to "en". Left stale, Japanese text can be drawn
// with Chinese glyph forms. src/index.css keys its CJK stacks off :lang().
function syncDocumentLanguage(lng: string): void {
  document.documentElement.lang = lng
}

i18n.on('languageChanged', syncDocumentLanguage)
syncDocumentLanguage(i18n.resolvedLanguage || i18n.language || 'en-US')

export default i18n
