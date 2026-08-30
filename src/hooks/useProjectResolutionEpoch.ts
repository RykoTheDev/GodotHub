import { useEffect, useState } from 'react'
import {
  getResolutionEpoch,
  subscribeResolutionEpoch,
} from '../api/projects'

export function useProjectResolutionEpoch(): number {
  const [epoch, setEpoch] = useState(getResolutionEpoch)

  useEffect(
    () => subscribeResolutionEpoch(() => setEpoch(getResolutionEpoch())),
    [],
  )

  return epoch
}
