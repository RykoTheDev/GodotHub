import { useEffect, useState } from 'react'
import { getVersion } from '@tauri-apps/api/app'

export function useAppVersion(): string | null {
  const [version, setVersion] = useState<string | null>(null)

  useEffect(() => {
    getVersion().then(setVersion).catch(() => setVersion(null))
  }, [])

  return version
}
