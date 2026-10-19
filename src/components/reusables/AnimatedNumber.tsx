import NumberFlow from '@number-flow/react'
import { useSettings } from '../../hooks/useSettings'
import { useUiMotion } from '../../hooks/useUiMotion'

export function AnimatedNumber({ value }: { value: number }) {
  const { settings } = useSettings()
  const {instant, reduced} = useUiMotion()
  if (!settings.animated_numbers || instant || reduced) return <span>{value}</span>
  return <NumberFlow value={value} />
}
