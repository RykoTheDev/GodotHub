import {invoke} from '@tauri-apps/api/core'
import type {ProjectExportCatalog, ProjectExportRun} from '../types'

export const exportsApi = {
  presets: (id: string) => invoke<ProjectExportCatalog>('get_project_export_presets', {id}),
  start: (id: string, presetId: number, outputPath: string, overwrite = false) =>
    invoke<ProjectExportRun>('start_project_export', {id, presetId, outputPath, overwrite}),
  get: (runId: string) => invoke<ProjectExportRun>('get_project_export', {runId}),
  list: (id: string) => invoke<ProjectExportRun[]>('get_project_exports', {id}),
  cancel: (runId: string) => invoke<void>('cancel_project_export', {runId}),
  openFolder: (runId: string) => invoke<void>('open_export_artifact_folder', {runId}),
}
