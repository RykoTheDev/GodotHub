import { useEffect, useState } from 'react'

interface Contributor {
  login: string
  avatar_url: string
  contributions: number
}

const CACHE_KEY = 'godothub_contributors_cache'
const CACHE_TTL_MS = 24 * 60 * 60 * 1000

const REPO_OWNER = 'RykoTheDev'
const REPO_NAME = 'GodotHub'

function readCache(): Contributor[] | null {
  try {
    const raw = localStorage.getItem(CACHE_KEY)
    if (!raw) return null
    const { data, timestamp } = JSON.parse(raw) as {
      data: Contributor[]
      timestamp: number
    }
    if (Date.now() - timestamp > CACHE_TTL_MS) return null
    return data
  } catch {
    return null
  }
}

function writeCache(data: Contributor[]) {
  try {
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({ data, timestamp: Date.now() }),
    )
  } catch {}
}

export function useContributors(): {
  contributors: Contributor[]
  loading: boolean
} {
  const [contributors, setContributors] = useState<Contributor[]>(() => {
    return readCache() ?? []
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false

    fetch(
      `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contributors?per_page=100`,
    )
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`)
        return r.json()
      })
      .then((data: Contributor[]) => {
        if (cancelled) return
        const filtered = data.filter((c) => c.login !== 'dependabot[bot]')
        setContributors(filtered)
        writeCache(filtered)
        setLoading(false)
      })
      .catch(() => {
        if (cancelled) return
        setLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [])

  return { contributors, loading }
}
