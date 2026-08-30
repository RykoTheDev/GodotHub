let splashConsumed = false
let switchToSettings = false

export function markUiSwitchToSettings() {
  switchToSettings = true
}

export function shouldOpenSettingsAfterSwitch(): boolean {
  return switchToSettings
}

export function clearUiSwitchToSettings() {
  switchToSettings = false
}

export function shouldShowSplash(): boolean {
  return !splashConsumed
}

export function markSplashConsumed() {
  splashConsumed = true
}
