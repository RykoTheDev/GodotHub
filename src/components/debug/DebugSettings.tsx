import { useState, type ReactNode } from 'react'
import { relaunch } from '@tauri-apps/plugin-process'
import { api } from '../../lib/api'
import { pushToast } from '../../lib/toast'
import { setDebugUnlocked } from '../../lib/debugMode'
import { useSettings } from '../../hooks/useSettings'
import { useAppVersion } from '../../hooks/useAppVersion'

const buttonClass =
  'focus-ring cursor-pointer shrink-0 px-3 py-1.5 rounded-item border border-outline/50 bg-raised/40 hover:bg-raised text-xs font-medium text-ink transition-colors'
const dangerButtonClass =
  'focus-ring cursor-pointer shrink-0 px-3 py-1.5 rounded-item border border-danger/30 bg-danger/10 hover:bg-danger/20 text-xs font-medium text-danger transition-colors'

function Section({
  title,
  description,
  children,
}: {
  title: string
  description?: string
  children: ReactNode
}) {
  return (
    <section className="flex flex-col gap-5 rounded-item bg-overlay px-5 py-5">
      <div>
        <h3 className="font-display font-semibold text-sm">{title}</h3>
        {description && <p className="text-[11px] text-muted mt-1">{description}</p>}
      </div>
      {children}
    </section>
  )
}

function Row({
  label,
  description,
  children,
}: {
  label: string
  description?: string
  children: ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-4">
      <div>
        <span className="text-xs font-medium text-muted block">{label}</span>
        {description && (
          <p className="text-[11px] text-muted mt-1 leading-relaxed">{description}</p>
        )}
      </div>
      <div className="flex shrink-0 items-center gap-2">{children}</div>
    </div>
  )
}

export function DebugSettings() {
  const { settings, update } = useSettings()
  const appVersion = useAppVersion()
  const [crash, setCrash] = useState(false)
  const [confirmWipe, setConfirmWipe] = useState(false)

  if (crash) throw new Error('Debug crash test triggered from Settings > Debug')

  const copyDebugInfo = async () => {
    const info = {
      app_version: appVersion,
      user_agent: navigator.userAgent,
      language: navigator.language,
      window: `${window.innerWidth}x${window.innerHeight} @${window.devicePixelRatio}x`,
      online: navigator.onLine,
      settings,
    }
    try {
      await navigator.clipboard.writeText(JSON.stringify(info, null, 2))
      pushToast('success', 'Debug info copied to clipboard')
    } catch (e) {
      pushToast('error', `Could not copy debug info: ${String(e)}`)
    }
  }

  const wipeAppData = async () => {
    try {
      await api.resetAppData()
      await relaunch()
    } catch (e) {
      pushToast('error', `Could not wipe app data: ${String(e)}`)
    }
  }

  return (
    <div className="flex flex-col gap-3">
      <Section
        title="Debug"
        description="Developer tools for testing GodotHub. These are not translated and may change at any time. Only you can see this tab; it stays unlocked until you hide it."
      >
        <Row
          label="Hide Debug tab"
          description="Locks this tab again. Click the sidebar Settings button 5 times quickly to bring it back."
        >
          <button type="button" className={buttonClass} onClick={() => setDebugUnlocked(false)}>
            Hide
          </button>
        </Row>
        <Row
          label="Copy debug info"
          description="Copies the app version, platform, window size and current settings as JSON, for bug reports."
        >
          <button type="button" className={buttonClass} onClick={() => void copyDebugInfo()}>
            Copy
          </button>
        </Row>
      </Section>

      <Section title="Toasts" description="Fire a test notification of each kind.">
        <Row label="Show test toast">
          <button
            type="button"
            className={buttonClass}
            onClick={() => pushToast('success', 'This is a success toast')}
          >
            Success
          </button>
          <button
            type="button"
            className={buttonClass}
            onClick={() => pushToast('info', 'This is an info toast')}
          >
            Info
          </button>
          <button
            type="button"
            className={buttonClass}
            onClick={() => pushToast('error', 'This is an error toast')}
          >
            Error
          </button>
        </Row>
      </Section>

      <Section title="Caches & watchers">
        <Row
          label="Clear project icon and name cache"
          description="Reloads every project's icon and name from disk."
        >
          <button
            type="button"
            className={buttonClass}
            onClick={() => {
              api.clearProjectIconCache()
              api.clearProjectNameCache()
              pushToast('success', 'Project icon and name cache cleared')
            }}
          >
            Clear
          </button>
        </Row>
        <Row
          label="Restart file watchers"
          description="Tears down and recreates the project, version and template watchers."
        >
          <button
            type="button"
            className={buttonClass}
            onClick={() =>
              void api
                .restartWatchers()
                .then(() => pushToast('success', 'File watchers restarted'))
                .catch((e) => pushToast('error', `Could not restart watchers: ${String(e)}`))
            }
          >
            Restart
          </button>
        </Row>
      </Section>

      <Section title="App">
        <Row
          label="Show onboarding"
          description="Reopens the first-run setup wizard. Your settings are kept."
        >
          <button
            type="button"
            className={buttonClass}
            onClick={() => void update({ ...settings, setup_complete: false })}
          >
            Open
          </button>
        </Row>
        <Row
          label="Reload window"
          description="Reloads the interface without restarting the backend."
        >
          <button type="button" className={buttonClass} onClick={() => window.location.reload()}>
            Reload
          </button>
        </Row>
        <Row label="Restart app" description="Fully restarts GodotHub.">
          <button type="button" className={buttonClass} onClick={() => void relaunch()}>
            Restart
          </button>
        </Row>
        <Row
          label="Trigger crash"
          description="Throws a render error to test the crash screen."
        >
          <button type="button" className={dangerButtonClass} onClick={() => setCrash(true)}>
            Crash
          </button>
        </Row>
      </Section>

      <Section
        title="Danger zone"
        description="Destructive actions, for testing a fresh install."
      >
        <Row
          label="Wipe all app data"
          description="Deletes every workspace, project entry, setting and cache, then restarts. Installed Godot files on disk are not touched."
        >
          {confirmWipe ? (
            <>
              <button type="button" className={dangerButtonClass} onClick={() => void wipeAppData()}>
                Confirm wipe
              </button>
              <button type="button" className={buttonClass} onClick={() => setConfirmWipe(false)}>
                Cancel
              </button>
            </>
          ) : (
            <button type="button" className={dangerButtonClass} onClick={() => setConfirmWipe(true)}>
              Wipe
            </button>
          )}
        </Row>
      </Section>
    </div>
  )
}
