import NumberFlow from '@number-flow/react'
import { useSettings } from '../../hooks/useSettings'

export function AnimatedNumber({ value }: { value: number }) {
  const { settings } = useSettings()
  if (!settings.animated_numbers || settings.animation_intensity === 'none') return <>{value}</>
  return <NumberFlow value={value} />
}
