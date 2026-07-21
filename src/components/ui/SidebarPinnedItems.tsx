import { useEffect, useState } from 'react'
import { api } from '../../lib/api'
import { Tooltip } from './Tooltip'
import { IconPlay, IconX } from '../Icons'
import type { Project } from '../../types'

interface Props {
  projects: Project[]
  collapsed: boolean
  onOpen: (id: string) => void
  onUnpin?: (id: string) => void
}

function SidebarProjectItem({
  project,
  collapsed,
  onOpen,
  onUnpin,
}: {
  project: Project
  collapsed: boolean
  onOpen: (id: string) => void
  onUnpin?: (id: string) => void
}) {
  const [icon, setIcon] = useState<string | null>(null)
  const [settingsName, setSettingsName] = useState<string | null>(null)
  const displayName = settingsName ?? project.name

  useEffect(() => {
    let cancelled = false
    api.getProjectIcon(project.path).then((data) => {
      if (!cancelled) setIcon(data)
    })
    return () => {
      cancelled = true
    }
  }, [project.path])

  useEffect(() => {
    let cancelled = false
    api.getProjectName(project.path).then((data) => {
      if (!cancelled) setSettingsName(data)
    })
    return () => {
      cancelled = true
    }
  }, [project.path])

  if (collapsed) {
    return (
      <Tooltip key={project.id} content={displayName} side="right">
        <button
          onClick={() => onOpen(project.id)}
          aria-label={`Open ${displayName}`}
          className="focus-ring cursor-pointer w-11 h-11 flex items-center justify-center rounded-lg text-muted hover:text-ink hover:bg-raised/60 transition-colors relative overflow-hidden"
        >
          {icon ? (
            <img
              src={icon}
              alt=""
              aria-hidden="true"
              className="absolute inset-0 w-full h-full object-contain opacity-[0.25] grayscale"
            />
          ) : (
            <span className="w-4 h-4 rounded-sm bg-raised border border-line" />
          )}
        </button>
      </Tooltip>
    )
  }

  return (
    <div
      key={project.id}
      className="group/card relative flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-raised/40 transition-colors min-w-0 overflow-hidden"
    >
      {icon ? (
        <img
          src={icon}
          alt=""
          aria-hidden="true"
          className="select-none absolute -left-1 top-1/2 -translate-y-1/2 w-10 h-10 object-contain opacity-[0.1] grayscale pointer-events-none"
        />
      ) : null}
      <span
        className="relative z-1 text-xs text-muted truncate flex-1 min-w-0 cursor-default"
        title={displayName}
      >
        {displayName}
      </span>
      <div className="relative z-1 flex items-center gap-0.5 opacity-0 group-hover/card:opacity-100 transition-opacity">
        <button
          onClick={() => onOpen(project.id)}
          aria-label={`Open ${displayName}`}
          className="focus-ring cursor-pointer p-1 rounded-md text-muted/60 hover:text-accent-bright hover:bg-raised transition-colors"
        >
          <IconPlay className="w-3 h-3" />
        </button>          {onUnpin && (
            <button
              onClick={() => onUnpin(project.id)}
              aria-label={`Remove ${displayName} from sidebar`}
              className="focus-ring cursor-pointer p-1 rounded-md text-muted/60 hover:text-danger hover:bg-danger/10 transition-colors"
            >
              <IconX className="w-3 h-3" />
            </button>
          )}
      </div>
    </div>
  )
}

export function SidebarProjectItems({ projects, collapsed, onOpen, onUnpin }: Props) {
  return (
    <>
      {projects.map((project) => (
        <SidebarProjectItem
          key={project.id}
          project={project}
          collapsed={collapsed}
          onOpen={onOpen}
          onUnpin={onUnpin}
        />
      ))}
    </>
  )
}
