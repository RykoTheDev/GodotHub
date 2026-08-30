import { invoke } from '@tauri-apps/api/core'
import type { ProjectTemplate, TemplateFileEntry, TemplateSyncResult } from '../types'

export const templatesApi = {
  list: () => invoke<ProjectTemplate[]>('list_templates'),
  saveAsTemplate: (projectId: string, name: string, description: string) =>
    invoke<ProjectTemplate>('save_project_as_template', { projectId, name, description }),
  delete: (templateId: string) =>
    invoke<void>('delete_template', { templateId }),
  getPreview: (templateId: string) =>
    invoke<TemplateFileEntry[]>('get_template_preview', { templateId }),
  syncWithScanDir: () =>
    invoke<TemplateSyncResult>('sync_templates_with_scan_dir'),
}
