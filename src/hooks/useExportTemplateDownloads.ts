import { useCallback, useRef, useState } from 'react'
import { api } from '../lib/api'
import { pushToast } from '../lib/toast'
import i18n from '../i18n'
import { useTauriEvent } from '../lib/useTauriEvent'
import type {
  ExportTemplateDownload,
  ExportTemplatesError,
  ExportTemplatesProgress,
  ExportTemplatesStage,
} from '../types'

/**
 * Tracks export-template downloads started from the Versions view. Progress is
 * intentionally kept out of the versions context so a 1 GB download does not
 * re-render every consumer of it.
 */
export function useExportTemplateDownloads(
  onInstalled: () => void | Promise<void>,
) {
  const [downloads, setDownloads] = useState<Record<string, ExportTemplateDownload>>({})
  const installedRef = useRef(onInstalled)
  installedRef.current = onInstalled

  const clear = useCallback((tag: string) => {
    setDownloads((prev) => {
      if (!(tag in prev)) return prev
      const next = { ...prev }
      delete next[tag]
      return next
    })
  }, [])

  useTauriEvent<string>('export-templates-queued', (tag) => {
    setDownloads((prev) => ({
      ...prev,
      [tag]: prev[tag] ?? { downloaded: 0, total: 0, stage: 'downloading' },
    }))
  })

  useTauriEvent<ExportTemplatesProgress>('export-templates-progress', (payload) => {
    setDownloads((prev) => ({
      ...prev,
      [payload.tag]: {
        downloaded: payload.downloaded,
        total: payload.total,
        stage: 'downloading',
      },
    }))
  })

  useTauriEvent<ExportTemplatesStage>('export-templates-stage', ({ tag, stage }) => {
    setDownloads((prev) =>
      prev[tag] ? { ...prev, [tag]: { ...prev[tag], stage } } : prev,
    )
  })

  useTauriEvent<string>('export-templates-complete', clear)
  useTauriEvent<string>('export-templates-canceled', clear)
  useTauriEvent<ExportTemplatesError>('export-templates-error', ({ tag }) => clear(tag))

  const install = useCallback(
    async (tag: string) => {
      setDownloads((prev) => ({
        ...prev,
        [tag]: { downloaded: prev[tag]?.downloaded ?? 0, total: prev[tag]?.total ?? 0, stage: 'downloading' },
      }))
      try {
        const result = await api.installExportTemplates(tag)
        if (result) {
          pushToast(
            'success',
            i18n.t('versions:export_templates_installed_toast', { tag }),
          )
          await installedRef.current()
        }
      } catch (error) {
        pushToast(
          'error',
          i18n.t('versions:export_templates_install_failed', {
            error: String(error),
          }),
          6000,
        )
      } finally {
        clear(tag)
      }
    },
    [clear],
  )

  const cancel = useCallback(async (tag: string) => {
    try {
      await api.cancelExportTemplates(tag)
    } catch {
      // The download may have finished between the click and the command.
    }
  }, [])

  return { downloads, install, cancel }
}
