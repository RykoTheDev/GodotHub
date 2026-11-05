import {
  createContext,
  createElement,
  useContext,
  useLayoutEffect,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from 'react'

type Store<T> = {
  get: () => T
  set: (next: T) => void
  subscribe: (listener: () => void) => () => void
}

function createStore<T>(initial: T): Store<T> {
  let value = initial
  const listeners = new Set<() => void>()
  return {
    get: () => value,
    set: (next) => {
      if (Object.is(next, value)) return
      value = next
      listeners.forEach((listener) => listener())
    },
    subscribe: (listener) => {
      listeners.add(listener)
      return () => {
        listeners.delete(listener)
      }
    },
  }
}

export function createContextProvider<T>(useHook: () => T, name: string) {
  const Ctx = createContext<Store<T> | null>(null)
  Ctx.displayName = name

  function Provider({ children }: { children: ReactNode }) {
    const value = useHook()
    const [store] = useState(() => createStore(value))
    useLayoutEffect(() => {
      store.set(value)
    })
    return createElement(Ctx.Provider, { value: store }, children)
  }
  Provider.displayName = `${name}.Provider`

  function useCtx(): T
  function useCtx<S>(selector: (value: T) => S): S
  function useCtx<S>(selector?: (value: T) => S): T | S {
    const store = useContext(Ctx)
    if (!store) {
      throw new Error(`use${name}() must be used within a <${name}>`)
    }
    const read = () => (selector ? selector(store.get()) : store.get())
    return useSyncExternalStore(store.subscribe, read, read)
  }
  useCtx.displayName = `use${name}`

  return { Provider, useCtx } as const
}
