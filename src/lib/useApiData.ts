import { useCallback, useEffect, useState } from 'react'

export function useApiData<T>(
  fetcher: () => Promise<T>,
  deps: unknown[],
  initial: T | undefined = undefined,
) {
  const [data, setData] = useState<T>(initial as T)
  const [loaded, setLoaded] = useState(false)
  const [loading, setLoading] = useState(true)

  const refresh = useCallback(async () => {
    setLoading(true)
    try {
      setData(await fetcher())
    } catch {
      setData(initial as T)
    } finally {
      setLoaded(true)
      setLoading(false)
    }
  }, deps)

  useEffect(() => {
    refresh()
  }, [refresh])

  return { data, loaded, loading, refresh, setData } as const
}

export function useApiDataWithError<T>(
  fetcher: () => Promise<T>,
  deps: unknown[],
  initial: T | undefined = undefined,
) {
  const [data, setData] = useState<T>(initial as T)
  const [loaded, setLoaded] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      setData(await fetcher())
    } catch (e) {
      setData(initial as T)
      setError(String(e))
    } finally {
      setLoaded(true)
      setLoading(false)
    }
  }, deps)

  useEffect(() => {
    refresh()
  }, [refresh])

  return { data, loaded, loading, error, refresh, setData } as const
}
