import { useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import { api } from '../../lib/api'
import { useProjectsContext } from '../../hooks/projectsContext'
import { ModalShell } from './ModalShell'
import type { AssetLibraryAsset, ProjectTemplate } from '../../types'
import {
  IconAlertTriangle,
  IconCopy,
  IconDownload,
  IconFolderPlus,
  IconSearch,
  IconSpinner,
  IconStore,
} from '../../lib/icons'

export interface AssetInstallOutcome {
  assetId: string
  targetType: 'project' | 'template'
  targetName: string
}

interface Props {
  asset: AssetLibraryAsset
  onClose: () => void
  onInstalled: (outcome: AssetInstallOutcome) => void
}

type Tab = 'project' | 'template'

function parseStoreId(id: string): [string, string] {
  const rest = id.startsWith('store:') ? id.slice('store:'.length) : id
  const idx = rest.indexOf('/')
  return idx > 0 ? [rest.slice(0, idx), rest.slice(idx + 1)] : [rest, '']
}

export function InstallAssetModal({ asset, onClose, onInstalled }: Props) {
  const { t } = useTranslation('common')
  const { projects } = useProjectsContext()
  const [tab, setTab] = useState<Tab>('project')
  const [templates, setTemplates] = useState<ProjectTemplate[]>([])
  const [query, setQuery] = useState('')
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [installing, setInstalling] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    api
      .listTemplates()
      .then(setTemplates)
      .catch(() => setTemplates([]))
  }, [])

  const canCreateTemplate =
    asset.source !== 'store' && asset.asset_type === 'project'

  const rows = useMemo(() => {
    const q = query.trim().toLowerCase()
    const list = tab === 'project' ? projects : templates
    const items = list.filter((item) => {
      const name = item.name.toLowerCase()
      const path = (item.path ?? '').toLowerCase()
      return name.includes(q) || path.includes(q)
    })
    return items.map((item) => ({
      id: item.id,
      name: item.name,
      path: item.path,
      godot_version: item.godot_version,
      description: 'description' in item ? item.description : undefined,
    }))
  }, [tab, query, projects, templates])

  const install = async (targetId: string, targetName: string) => {
    setInstalling(true)
    setError(null)
    try {
      if (asset.source === 'store') {
        const [publisherSlug, assetSlug] = parseStoreId(asset.asset_id)
        if (tab === 'project') {
          await api.installStoreAsset(
            publisherSlug,
            assetSlug,
            asset.title,
            targetId,
            null,
          )
        } else {
          await api.installStoreAsset(
            publisherSlug,
            assetSlug,
            asset.title,
            null,
            targetId,
          )
        }
      } else if (tab === 'project') {
        await api.installAsset(asset.asset_id, targetId, null)
      } else {
        await api.installAsset(asset.asset_id, null, targetId)
      }
      onInstalled({ assetId: asset.asset_id, targetType: tab, targetName })
      onClose()
    } catch (e) {
      setError(String(e))
    } finally {
      setInstalling(false)
    }
  }

  const saveAsNewTemplate = async () => {
    setInstalling(true)
    setError(null)
    try {
      const template = await api.installAssetAsTemplate(asset.asset_id)
      window.dispatchEvent(new Event('app:refresh-templates'))
      onInstalled({
        assetId: asset.asset_id,
        targetType: 'template',
        targetName: template.name,
      })
      onClose()
    } catch (e) {
      setError(String(e))
    } finally {
      setInstalling(false)
    }
  }

  const selectedName = selectedId
    ? tab === 'project'
      ? projects.find((p) => p.id === selectedId)?.name
      : templates.find((tmpl) => tmpl.id === selectedId)?.name
    : null

  const tabBtn = (v: Tab, Icon: typeof IconCopy, label: string) => (
    <button
      type="button"
      onClick={() => {
        setTab(v)
        setSelectedId(null)
      }}
      className={`focus-ring cursor-pointer flex-1 flex items-center justify-center gap-2 px-3 h-8 rounded-btn text-xs font-medium transition-colors ${
        tab === v
          ? 'bg-accent text-white'
          : 'text-muted hover:text-ink hover:bg-raised'
      }`}
    >
      <Icon className="w-3.5 h-3.5" />
      {label}
    </button>
  )

  return (
    <ModalShell
      icon={
        asset.icon_url ? (
          <img
            src={asset.icon_url}
            alt=""
            loading="lazy"
            className="w-full h-full object-cover rounded-tile"
            onError={(e) => {
              e.currentTarget.style.display = 'none'
            }}
          />
        ) : (
          <IconStore className="w-5 h-5 text-muted" />
        )
      }
      title={t('asset_install_modal_title', { title: asset.title })}
      description={t('asset_install_modal_desc')}
      maxWidth="max-w-md"
      onClose={() => !installing && onClose()}
      showClose={false}
      footer={
        <>
          <button
            onClick={onClose}
            disabled={installing}
            className="focus-ring cursor-pointer px-4 py-2 rounded-item text-sm text-muted hover:text-ink hover:bg-raised transition-colors disabled:opacity-40"
          >
            {t('cancel')}
          </button>
          <motion.button
            whileHover={!selectedId || installing ? undefined : { y: -1 }}
            whileTap={!selectedId || installing ? undefined : { scale: 0.96 }}
            onClick={() => selectedId && install(selectedId, selectedName ?? '')}
            disabled={!selectedId || installing}
            className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2 rounded-item bg-accent hover:bg-accent-bright text-white text-sm font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {installing ? (
              <>
                <IconSpinner className="w-3.5 h-3.5 animate-spin" />
                {t('asset_installing')}
              </>
            ) : selectedName ? (
              <>
                <IconDownload className="w-3.5 h-3.5" />
                {t('asset_install_into', { name: selectedName })}
              </>
            ) : (
              <>{t('asset_install_btn')}</>
            )}
          </motion.button>
        </>
      }
    >
        <div className="px-5 pb-4 flex flex-col gap-3">
          <div className="flex items-center gap-1 p-1 rounded-item border border-outline/50 bg-overlay">
            {tabBtn('project', IconFolderPlus, t('asset_install_tab_project'))}
            {tabBtn('template', IconCopy, t('asset_install_tab_template'))}
          </div>
          {canCreateTemplate && tab === 'template' && (
            <button
              type="button"
              onClick={saveAsNewTemplate}
              disabled={installing}
              className="focus-ring cursor-pointer w-full flex items-center gap-3 p-3 rounded-item border border-dashed border-mint/30 bg-mint/5 hover:bg-mint/10 transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-left"
            >
              <span className="w-8 h-8 rounded-tile bg-mint/10 text-mint flex items-center justify-center shrink-0">
                <IconDownload className="w-4 h-4" />
              </span>
              <span className="flex-1 min-w-0">
                <span className="block text-xs font-semibold text-ink">
                  {t('asset_new_template_btn')}
                </span>
                <span className="block text-[11px] text-muted/70 mt-0.5 leading-snug">
                  {t('asset_new_template_hint')}
                </span>
              </span>
              {installing && !selectedId && (
                <IconSpinner className="w-4 h-4 animate-spin text-mint shrink-0" />
              )}
            </button>
          )}

          <div className="shrink-0 flex items-center gap-2 px-3 h-10 rounded-item bg-overlay border border-outline/50 focus-within:border-accent-dim focus-within:bg-raised transition-colors">
            <IconSearch className="w-3.5 h-3.5 text-muted shrink-0" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={
                tab === 'project'
                  ? t('asset_install_search_projects')
                  : t('asset_install_search_templates')
              }
              className="flex-1 min-w-0 bg-transparent outline-none text-sm font-medium text-ink placeholder:text-muted/70"
            />
          </div>

          <div className="flex-1 min-h-0 max-h-72 overflow-y-auto flex flex-col gap-1.5 pb-1">
            {rows.length === 0 ? (
              <div className="border border-dashed border-outline/50 rounded-item py-10 flex flex-col items-center gap-2 text-center">
                <IconStore className="w-5 h-5 text-muted/50" />
                <p className="text-xs text-muted max-w-[220px] leading-relaxed">
                  {tab === 'project'
                    ? t('asset_install_no_projects')
                    : t('asset_install_no_templates')}
                </p>
              </div>
            ) : (
              rows.map((item) => {
                const selected = selectedId === item.id
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelectedId(item.id)}
                    className={`focus-ring cursor-pointer w-full flex items-center gap-3 p-2.5 rounded-item border text-left transition-colors ${
                      selected
                        ? 'border-accent-dim/60 bg-accent/10'
                        : 'border-transparent hover:bg-raised hover:border-outline/50'
                    }`}
                  >
                    <span
                      className={`w-8 h-8 rounded-tile flex items-center justify-center shrink-0 border ${
                        selected
                          ? 'bg-accent/20 text-accent-bright border-accent-dim/40'
                          : 'bg-raised text-muted border-outline/50'
                      }`}
                    >
                      {tab === 'project' ? (
                        <IconFolderPlus className="w-3.5 h-3.5" />
                      ) : (
                        <IconCopy className="w-3.5 h-3.5" />
                      )}
                    </span>
                    <span className="flex-1 min-w-0">
                      <span className="block text-xs font-semibold text-ink truncate">
                        {item.name}
                      </span>
                      <span className="block text-[10px] text-muted/60 truncate mt-0.5 font-mono">
                        {tab === 'project'
                          ? `${item.godot_version ? `Godot ${item.godot_version} · ` : ''}${item.path ?? ''}`
                          : item.description || ''}
                      </span>
                    </span>
                    {selected && (
                      <span className="shrink-0 w-1.5 h-1.5 rounded-full bg-accent" />
                    )}
                  </button>
                )
              })
            )}
          </div>

          {error && (
            <div className="flex items-start gap-2 p-2.5 rounded-item bg-danger/10 border border-danger/20 text-xs text-danger leading-snug">
              <IconAlertTriangle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
              <span className="min-w-0 break-words">{error}</span>
            </div>
          )}
        </div>
    </ModalShell>
  )
}
