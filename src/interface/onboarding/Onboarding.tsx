import type { AppSettings } from '../../types'
import { OnboardingView } from '../views/OnboardingView'

interface Props {
  settings: AppSettings
  onComplete: (settings: AppSettings) => Promise<AppSettings> | void
}

export function Onboarding({ settings, onComplete }: Props) {
  return (
    <OnboardingView
      settings={settings}
      onComplete={onComplete}
    />
  )
}
