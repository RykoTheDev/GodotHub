import { useCallback, useEffect, useMemo, useState } from 'react'
import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'
import { api } from '../lib/api'
import type { AppSettings, Project } from '../types'

interface DiscordActivity {
  name?: string
  state?: string
  details?: string
  stateUrl?: string
  detailsUrl?: string
  assets?: {
    largeImage?: string
    largeText?: string
    largeUrl?: string
    smallImage?: string
    smallText?: string
    smallUrl?: string
  }
  buttons?: { label: string; url: string }[]
  party?: { id?: string; currentSize?: number; maxSize?: number }
  timestamps?: { start?: number; end?: number }
  activityType?: number
  statusDisplayType?: number
}

export const DEFAULT_DISCORD_APP_ID = '1538556630713638973'

function connect(appId: string) {
  return invoke('plugin:discord-rpc|connect', { appId })
}

function disconnect() {
  return invoke('plugin:discord-rpc|disconnect')
}

function setActivity(payload: DiscordActivity) {
  return invoke('plugin:discord-rpc|set_activity', { payload })
}

const VIEW_PRESENCE: Record<string, { details: string; state: string }> = {
  onboarding: {
    details: 'Setting up GodotHub',
    state: 'Getting everything just right...',
  },
  dashboard: {
    details: 'in Dashboard',
    state: 'Checking in on those juicy stats',
  },
  projects: {
    details: 'Browsing Projects',
    state: 'Deciding what to work on...',
  },
  versions: {
    details: 'Browsing Versions',
    state: 'Deciding which one to install...',
  },
  templates: {
    details: 'Browsing Templates',
    state: 'Looking to start with...',
  },
  'asset-store': {
    details: 'Browsing the Asset Store',
    state: 'Looking for something to use...',
  },
  news: {
    details: 'Reading Godot News',
    state: 'Latest from the Godot itself',
  },
  updates: {
    details: 'Reading Updates by Dev',
    state: 'What is bro yappin. about now?',
  },
  changelog: {
    details: 'Checking the Changelog',
    state: "to see what's new...",
  },
  settings: {
    details: 'Configuring Settings',
    state: 'Tweaking the app to my liking',
  },
}

export function useDiscordRpc(settings: AppSettings, projects: Project[]) {
  const enabled = settings.discord_rpc_enabled

  const appId = settings.discord_app_id?.trim() || DEFAULT_DISCORD_APP_ID
  const [connected, setConnected] = useState(false)
  const [view, setView] = useState<string | null>(null)

  const handleViewChanged = useCallback((e: Event) => {
    const detail = (e as CustomEvent).detail
    if (typeof detail === 'string') setView(detail)
  }, [])

  useEffect(() => {
    window.addEventListener('app:view-changed', handleViewChanged)
    return () =>
      window.removeEventListener('app:view-changed', handleViewChanged)
  }, [handleViewChanged])

  useEffect(() => {
    if (!enabled || !appId) {
      setConnected(false)
      void disconnect().catch(() => {})
      return
    }
    let cancelled = false
    connect(appId)
      .then(() => {
        if (!cancelled) setConnected(true)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [enabled, appId])

  useEffect(() => {
    let unlisten: (() => void) | undefined
    listen<boolean>('discord-rpc://connected', (e) => {
      setConnected(e.payload)
    }).then((un) => {
      unlisten = un
    })
    return () => {
      unlisten?.()
    }
  }, [])

  const running = useMemo(() => {
    return projects
      .filter((p) => p.session_started_at_ms)
      .sort(
        (a, b) =>
          (b.session_started_at_ms ?? 0) - (a.session_started_at_ms ?? 0),
      )[0]
  }, [projects])

  const [resolvedName, setResolvedName] = useState<string | null>(null)

  useEffect(() => {
    if (!running) {
      setResolvedName(null)
      return
    }
    setResolvedName(null)
    let cancelled = false
    api
      .getProjectName(running.path)
      .then((name) => {
        if (!cancelled && name) setResolvedName(name)
      })
      .catch(() => {})
    return () => {
      cancelled = true
    }
  }, [running?.id])

  const folderName = running?.path.split(/[\\/]/).pop() ?? ''
  const storedIsFolderName = running?.name === folderName

  const hideProjectNames = !settings.discord_rpc_show_projects
  const excludedKey = settings.discord_rpc_excluded_projects.join('\u0001')
  const presencesKey = settings.discord_rpc_project_presences
    .map((p) => `${p.id}:${p.details ?? ''}:${p.state ?? ''}`)
    .join('\u0001')

  const activity = useMemo(() => {
    if (running) {
      const hidden =
        hideProjectNames ||
        settings.discord_rpc_excluded_projects.includes(running.id)
      if (hidden) {
        return {
          name: 'GodotHub',
          details: 'Working on a Top Secret Project',
          state: 'Please do not disturb',
          timestamps: { start: running.session_started_at_ms ?? undefined },
        } satisfies DiscordActivity
      }
      const custom = settings.discord_rpc_project_presences.find(
        (p) => p.id === running.id,
      )
      return {
        name: 'GodotHub',
        details:
          custom?.details?.trim() ||
          (storedIsFolderName ? resolvedName || running.name : running.name),
        state:
          custom?.state?.trim() ||
          (running.godot_version
            ? `Godot ${running.godot_version}`
            : 'Working on a Project'),
        timestamps: { start: running.session_started_at_ms ?? undefined },
      } satisfies DiscordActivity
    }
    const preset = (view && VIEW_PRESENCE[view]) || {
      details: 'Using GodotHub',
      state: 'Managing my Projects',
    }
    return {
      name: 'GodotHub',
      details: preset.details,
      state: preset.state,
    } satisfies DiscordActivity
  }, [running, resolvedName, storedIsFolderName, hideProjectNames, excludedKey, presencesKey, settings.discord_rpc_excluded_projects, settings.discord_rpc_project_presences, view])

  const activityKey = JSON.stringify(activity)

  useEffect(() => {
    if (!connected) return
    void setActivity(activity).catch(() => {})
  }, [connected, activityKey])
}
