import { memo, useLayoutEffect, useRef, type ComponentType } from 'react'

type AnyFn = (...args: unknown[]) => unknown

export function withStableCallbacks<P extends object>(Component: ComponentType<P>) {
  const Memoized = memo(Component) as unknown as ComponentType<P>

  function Stable(props: P) {
    const latest = useRef(props)
    const proxies = useRef(new Map<string, AnyFn>())

    useLayoutEffect(() => {
      latest.current = props
    })

    const next: Record<string, unknown> = {}
    for (const [key, value] of Object.entries(props)) {
      if (typeof value !== 'function') {
        next[key] = value
        continue
      }
      let proxy = proxies.current.get(key)
      if (!proxy) {
        proxy = (...args: unknown[]) => {
          const current = (latest.current as Record<string, unknown>)[key]
          return typeof current === 'function' ? (current as AnyFn)(...args) : undefined
        }
        proxies.current.set(key, proxy)
      }
      next[key] = proxy
    }

    return <Memoized {...(next as P)} />
  }

  Stable.displayName = `Stable(${Component.displayName || Component.name || 'Component'})`
  return Stable
}
