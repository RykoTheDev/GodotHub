import { useEffect, useRef, useState } from 'react'
import { api, getCachedProjectIcon, getCachedProjectName } from '../lib/api'
import { useProjectResolutionEpoch } from './useProjectResolutionEpoch'
import type { Project } from '../types'

const sizes = new Map<string, number>()
const sizeRequests = new Map<string, Promise<number>>()

export function useProjectTileData(project: Project, showSize: boolean, preview: boolean) {
  const epoch = useProjectResolutionEpoch()
  const sizeKey = `${epoch}:${project.path}`
  const cardRef = useRef<HTMLElement>(null)
  const [icon, setIcon] = useState(() => getCachedProjectIcon(project.path))
  const [name, setName] = useState(() => getCachedProjectName(project.path))
  const [size, setSize] = useState<number | null | undefined>(() => sizes.get(sizeKey))
  const [now, setNow] = useState(() => Date.now())

  useEffect(() => {
    let cancelled = false
    setIcon(getCachedProjectIcon(project.path))
    setName(getCachedProjectName(project.path))
    if (preview) return
    api.getProjectIcon(project.path).then(value => { if (!cancelled) setIcon(value) }).catch(() => {})
    api.getProjectName(project.path).then(value => { if (!cancelled) setName(value) }).catch(() => {})
    return () => { cancelled = true }
  }, [project.path, epoch, preview])

  useEffect(() => {
    setSize(sizes.get(sizeKey))
    if (!showSize || preview || sizes.has(sizeKey)) return
    let cancelled = false
    const load = () => {
      let pending = sizeRequests.get(sizeKey)
      if (!pending) {
        pending = api.getProjectSize(project.path).then(info => {
          sizes.set(sizeKey, info.total_size)
          sizeRequests.delete(sizeKey)
          return info.total_size
        })
        sizeRequests.set(sizeKey, pending)
      }
      pending.then(value => { if (!cancelled) setSize(value) })
        .catch(() => { sizeRequests.delete(sizeKey); if (!cancelled) setSize(null) })
    }
    if (!cardRef.current || !('IntersectionObserver' in window)) { load(); return () => { cancelled = true } }
    const observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) { observer.disconnect(); load() }
    }, { rootMargin: '100px' })
    observer.observe(cardRef.current)
    return () => { cancelled = true; observer.disconnect() }
  }, [project.path, sizeKey, showSize, preview])

  useEffect(() => {
    setNow(Date.now())
    if (!project.session_started_at_ms || preview) return
    const timer = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(timer)
  }, [project.session_started_at_ms, preview])

  return { cardRef, icon, displayName: name ?? project.name, size, now }
}
