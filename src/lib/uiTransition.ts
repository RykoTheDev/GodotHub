let splashConsumed = false
let switchToSettings = false

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

let shellIntroHandedOff = false

export function handOffShellIntro() {
  shellIntroHandedOff = true
}

export function consumeShellIntroHandOff(): boolean {
  const handedOff = shellIntroHandedOff
  shellIntroHandedOff = false
  return handedOff
}
