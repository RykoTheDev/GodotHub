import {
  useEffect,
  useRef,
  useState,
  type ComponentType,
} from 'react'
import { useTranslation, Trans } from 'react-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { AnimatedNumber } from '../components/reusables/AnimatedNumber'
import { api } from '../../lib/api'
import { consumePendingAction } from '../../lib/pendingAction'
import { useSettings } from '../../hooks/useSettings'
import { useWorkspaces } from '../../hooks/useWorkspaces'
import type { ProjectTemplate, TemplateSyncResult } from '../../types'
import { useGodotVersionsContext } from '../../hooks/godotVersionsContext'
import { useProjectsContext } from '../../hooks/projectsContext'
import { useTaskTray } from '../../hooks/useTaskTray'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { SearchBar } from '../components/ui/SearchBar'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ScanButton } from '../components/reusables/ScanButton'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { TemplatePreviewModal } from '../components/modals/TemplatePreviewModal'
import { CreateProjectModal } from '../components/modals/CreateProjectModal'
import { AssetLibraryBrowser } from '../components/asset-library/AssetLibraryBrowser'
import {
  IconCopy,
  IconFolderPlus,
  IconSearch,
  IconStore,
  IconTrash,
  type IconProps,
} from '../lib/icons'

function TabSwitcher({
  value,
  onChange,
  options,
}: {
  value: string
  onChange: (value: string) => void
  options: {
    value: string
    label: string
    icon: ComponentType<IconProps>
  }[]
}) {
  return (
    <div className="inline-flex self-start shrink-0 h-12 items-center rounded-btn border border-outline/50 bg-overlay p-1 gap-1">
      {options.map(({ value: v, label, icon: Icon }) => {
        const active = value === v
        return (
          <button
            key={v}
            type="button"
            onClick={() => onChange(v)}
            className={`focus-ring cursor-pointer h-full flex items-center gap-1.5 px-3.5 rounded-btn text-xs font-medium transition-colors ${
              active
                ? 'bg-accent text-white'
                : 'text-muted hover:text-ink hover:bg-raised'
            }`}
          >
            <Icon className="w-3.5 h-3.5" />
            {label}
          </button>
        )
      })}
    </div>
  )
}

export function TemplatesView({
  connected = false,
  onOpenSettings,
}: {
  connected?: boolean
  onOpenSettings?: () => void
}) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const { activeId } = useWorkspaces()
  const { installed } = useGodotVersionsContext()
  const { refresh: refreshProjects } = useProjectsContext()
  const { registerTask, updateTask, unregisterTask } = useTaskTray()

  const [tab, setTab] = useState<'local' | 'asset'>('local')
  const [templates, setTemplates] = useState<ProjectTemplate[]>([])
  const [loaded, setLoaded] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [syncMessage, setSyncMessage] = useState<string | null>(null)
  const [syncResult, setSyncResult] = useState<TemplateSyncResult | null>(null)
  const [previewTemplate, setPreviewTemplate] = useState<ProjectTemplate | null>(null)
  const [createTemplate, setCreateTemplate] = useState<ProjectTemplate | null>(null)
  const [query, setQuery] = useState('')
  const [assetStats, setAssetStats] = useState({ loading: true, total: 0 })

  const load = async () => {
    try {
      setTemplates(await api.listTemplates())
    } catch {}
    setLoaded(true)
  }

  useEffect(() => {
    load()
  }, [activeId])

  const handleSync = async () => {
    setSyncMessage(null)
    setSyncResult(null)
    registerTask({
      id: 'sync-templates',
      type: 'sync-templates',
      label: tc('syncing'),
      description: tc('loading'),
      progress: null,
      status: 'running',
    })
    try {
      const result = await api.syncTemplatesWithScanDir()
      setSyncResult(result)
      const parts: string[] = []
      if (result.imported.length > 0)
        parts.push(tc('template_imported_count', { count: result.imported.length }))
      if (result.updated.length > 0)
        parts.push(tc('template_updated_count', { count: result.updated.length }))
      if (result.removed.length > 0)
        parts.push(tc('template_removed_count', { count: result.removed.length }))
      setSyncMessage(parts.length > 0 ? parts.join(' · ') : null)
      updateTask('sync-templates', {
        status: 'completed',
        description: parts.length > 0 ? parts.join(' · ') : tc('up_to_date'),
      })
      setTimeout(() => unregisterTask('sync-templates'), 3000)
      await load()
    } catch (e) {
      setSyncMessage(String(e))
      updateTask('sync-templates', {
        status: 'error',
        errorMessage: String(e),
      })
      setTimeout(() => unregisterTask('sync-templates'), 6000)
      throw e
    }
  }

  const syncRef = useRef(handleSync)
  syncRef.current = handleSync
  const loadRef = useRef(load)
  loadRef.current = load
  useEffect(() => {
    if (consumePendingAction() === 'sync-templates') {
      syncRef.current().catch(() => {})
    }
    const handler = () => {
      syncRef.current().catch(() => {})
    }
    const refreshHandler = () => loadRef.current()
    window.addEventListener('app:sync-templates', handler)
    window.addEventListener('app:refresh-templates', refreshHandler)
    return () => {
      window.removeEventListener('app:sync-templates', handler)
      window.removeEventListener('app:refresh-templates', refreshHandler)
    }
  }, [])

  const handleDelete = async (id: string) => {
    if (deleting) return
    setDeleting(true)
    try {
      await api.deleteTemplate(id)
      setTemplates((prev) => prev.filter((t) => t.id !== id))
      setConfirmDelete(null)
    } catch (e) {
      alert(e)
    } finally {
      setDeleting(false)
    }
  }

  const isSearching = query.trim().length > 0
  const filteredTemplates = isSearching
    ? templates.filter(
        (t) =>
          t.name.toLowerCase().includes(query.toLowerCase()) ||
          (t.description &&
            t.description.toLowerCase().includes(query.toLowerCase())),
      )
    : templates

  const syncHadChanges =
    syncResult &&
    (syncResult.imported.length > 0 ||
      syncResult.updated.length > 0 ||
      syncResult.removed.length > 0)

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col gap-2">
      <ViewHeader
        connected={connected}
        title={t('templates')}
        metric={
          tab === 'local' ? (
            <>
              <h2 className="text-4xl font-bold text-muted">
                <AnimatedNumber value={templates.length} />
              </h2>
              <p className="text-lg font-medium uppercase text-muted">
                {tc('template_your_templates')}
              </p>
            </>
          ) : (
            <>
              <h2 className="text-4xl font-bold text-muted">
                <AnimatedNumber value={assetStats.total} />
              </h2>
              <p className="text-lg font-medium uppercase text-muted">
                {tc('asset_store_count')}
              </p>
            </>
          )
        }
        actions={
          <>
            {settings.template_scan_dir && (
                <motion.button
                  type="button"
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.94 }}
                  transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  onClick={() =>
                    api.openProjectFolder(settings.template_scan_dir!)
                  }
                  className="focus-ring cursor-pointer flex items-center justify-center px-6 h-10 rounded-item bg-overlay shadow-md shadow-black/10 border border-outline/50 hover:bg-raised text-muted hover:text-ink font-semibold text-[17px] transition-colors"
                >
                  {tc('template_open_folder_btn')}
                </motion.button>
            )}
            <ScanButton
              onOpenSettings={onOpenSettings}
              scanDirs={
                settings.template_scan_dir
                  ? [settings.template_scan_dir]
                  : []
              }
              scan={() => handleSync()}
            />
          </>
        }
      >
        <div className="flex items-center gap-2">
          <SearchBar
            value={query}
            onChange={setQuery}
            placeholderKey={
              tab === 'local'
                ? 'template_search_placeholder'
                : 'asset_search_placeholder'
            }
            className="flex-1"
          />
          <TabSwitcher
            value={tab}
            onChange={(v) => setTab(v as 'local' | 'asset')}
            options={[
              { value: 'local', label: tc('templates_tab_local'), icon: IconCopy },
              { value: 'asset', label: tc('templates_tab_asset'), icon: IconStore },
            ]}
          />
        </div>
        {tab === 'local' && (templates.length > 0 || syncMessage) && (
          <div className="flex items-center gap-3 flex-wrap">
            {templates.length > 0 && (
              <span className="text-xs text-muted">
                {tc('template_count', { count: templates.length })}
                {isSearching
                  ? ' · ' +
                    tc('showing_count', { count: filteredTemplates.length })
                  : ''}
              </span>
            )}
            {syncMessage && (
              <span
                className={`text-xs ${
                  syncHadChanges ? 'text-mint' : 'text-muted'
                }`}
              >
                {syncMessage}
              </span>
            )}
          </div>
        )}
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-mr-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        topButtonBottom="bottom-17"
      >
        <div
          className={`h-full ${connected ? 'pl-5' : ''} pr-5 pb-4 flex flex-col gap-2`}
        >
          {tab === 'local' ? (
            <>
              {!loaded ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  {Array.from({ length: 3 }).map((_, i) => (
                    <div
                      key={i}
                      className="h-52 rounded-item border border-outline/50 bg-overlay animate-pulse"
                    />
                  ))}
                </div>
              ) : templates.length === 0 ? (
                <div className="rounded-item border border-dashed border-outline/50 py-20 flex flex-col items-center gap-3 text-center px-6">
                  <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
                    <IconCopy className="w-5 h-5 text-muted" />
                  </div>
                  <p className="text-sm text-muted max-w-sm leading-relaxed">
                    <Trans i18nKey="no_templates_yet" ns="common">
                      No templates yet. Right-click a project or open its "More"
                      menu and select{' '}
                      <strong>Save as Template</strong> to create one.
                    </Trans>
                  </p>
                </div>
              ) : filteredTemplates.length === 0 ? (
                <div className="rounded-item border border-dashed border-outline/50 py-16 flex flex-col items-center gap-3 text-center">
                  <IconSearch className="w-5 h-5 text-muted" />
                  <p className="text-sm text-muted">
                    {tc('no_templates_match')}{' '}
                    <strong className="text-ink">"{query}"</strong>.
                  </p>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  <AnimatePresence>
                    {filteredTemplates.map((tmpl) => (
                      <motion.div
                        key={tmpl.id}
                        layout
                        initial={{ opacity: 0, y: 8 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95 }}
                        className="relative border border-outline/50 rounded-item bg-overlay p-5 flex flex-col gap-3 group cursor-pointer hover:border-accent-dim transition-colors"
                        onClick={() => setPreviewTemplate(tmpl)}
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="w-10 h-10 rounded-tile bg-raised border border-outline/50 flex items-center justify-center shrink-0">
                            <IconCopy className="w-4 h-4 text-muted" />
                          </div>
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              setConfirmDelete(tmpl.id)
                            }}
                            className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 opacity-0 group-hover:opacity-100 hover:text-danger hover:bg-danger/10 transition-all"
                            aria-label={tc('delete_template', {
                              name: tmpl.name,
                            })}
                          >
                            <IconTrash className="w-3.5 h-3.5" />
                          </button>
                        </div>
                        <div className="flex-1 min-w-0">
                          <h4 className="font-display font-semibold text-sm truncate">
                            {tmpl.name}
                          </h4>
                          {tmpl.description && (
                            <p className="text-xs text-muted mt-1 leading-relaxed line-clamp-3">
                              {tmpl.description}
                            </p>
                          )}
                        </div>
                        <div className="flex items-center gap-1.5 text-[10px] text-muted/50 font-mono">
                          {tmpl.godot_version && (
                            <span>
                              {tc('godot')} {tmpl.godot_version}
                            </span>
                          )}
                          {tmpl.created_at && (
                            <>
                              <span>·</span>
                              <span>
                                {new Date(tmpl.created_at).toLocaleDateString()}
                              </span>
                            </>
                          )}
                        </div>
                        <motion.button
                          whileHover={{ y: -1 }}
                          whileTap={{ scale: 0.96 }}
                          onClick={(e) => {
                            e.stopPropagation()
                            setCreateTemplate(tmpl)
                          }}
                          className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 px-3 py-2 rounded-item bg-accent/10 border border-accent-dim/30 text-accent-bright text-xs font-semibold hover:bg-accent/20 transition-colors"
                        >
                          <IconFolderPlus className="w-3.5 h-3.5" />
                          {tc('template_create_project')}
                        </motion.button>
                      </motion.div>
                    ))}
                  </AnimatePresence>
                </div>
              )}
            </>
          ) : (
            <AssetLibraryBrowser query={query} onStatsChange={setAssetStats} />
          )}
          <div className="shrink-0 h-4" aria-hidden="true" />
        </div>
      </OverlayScrollArea>

      <AnimatePresence>
        {previewTemplate && (
          <TemplatePreviewModal
            template={previewTemplate}
            onClose={() => setPreviewTemplate(null)}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {createTemplate && (
          <CreateProjectModal
            installedVersions={installed}
            defaultLocation={settings.default_project_location}
            initialTemplateId={createTemplate.id}
            onClose={() => setCreateTemplate(null)}
            onCreated={() => {
              setCreateTemplate(null)
              refreshProjects()
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {confirmDelete && (
          <ConfirmDialog
            variant="danger"
            title={tc('template_delete_title')}
            description={
              templates.find((t) => t.id === confirmDelete)?.name
                ? tc('template_delete_desc', {
                    name: templates.find((t) => t.id === confirmDelete)?.name,
                  })
                : tc('cannot_undo')
            }
            confirmLabel={deleting ? tc('deleting') : tc('delete')}
            onConfirm={() => handleDelete(confirmDelete)}
            onCancel={() => setConfirmDelete(null)}
          />
        )}
      </AnimatePresence>
    </div>
  )
}
