import { Component, type ReactNode } from 'react'
import { IconAlertTriangle, IconRefresh, IconBug } from './Icons'

interface Props {
  children: ReactNode
  name: string
}

interface State {
  error: Error | null
}

export class ViewErrorBoundary extends Component<Props, State> {
  state: State = { error: null }

  static getDerivedStateFromError(error: Error): State {
    return { error }
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error(`[${this.props.name}] crashed:`, error, info.componentStack)
  }

  handleRetry = () => {
    this.setState({ error: null })
  }

  render() {
    const { error } = this.state
    const { name, children } = this.props

    if (!error) return children

    return (
      <div className="flex flex-col items-center justify-center min-h-[300px] gap-4 px-6 py-12">
        <div className="w-12 h-12 rounded-xl bg-danger/10 flex items-center justify-center">
          <IconAlertTriangle className="w-6 h-6 text-danger" />
        </div>
        <div className="text-center max-w-sm">
          <h3 className="font-semibold text-sm text-ink mb-1">
            {name} encountered an error
          </h3>
          <p className="text-xs text-muted leading-relaxed">
            Something went wrong while rendering this view. You can switch to another tab
            or try reloading this one.
          </p>
        </div>
        <pre className="text-[11px] text-danger/80 bg-danger/5 border border-danger/20 rounded-lg px-4 py-3 max-w-full overflow-auto max-h-24 select-all">
          {error.message}
        </pre>
        <div className="flex items-center gap-3">
          <button
            onClick={this.handleRetry}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2 rounded-lg bg-accent hover:bg-accent-bright text-xs font-medium text-white transition-colors"
          >
            <IconRefresh className="w-3.5 h-3.5" />
            Retry
          </button>
          <button
            onClick={() => window.dispatchEvent(new CustomEvent('app:report-bug'))}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2 rounded-lg border border-danger/40 text-danger hover:bg-danger/10 hover:border-danger text-xs font-medium transition-colors"
          >
            <IconBug className="w-3.5 h-3.5" />
            Report Bug
          </button>
        </div>
      </div>
    )
  }
}
