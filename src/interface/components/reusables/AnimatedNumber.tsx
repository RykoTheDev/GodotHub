import NumberFlow from '@number-flow/react'
import { useSettings } from '../../../hooks/useSettings'

export function AnimatedNumber({ value }: { value: number }) {
  const { settings } = useSettings()
  if (!settings.animated_numbers) return <span>{value}</span>
  return <NumberFlow value={value} />
}
