import { useEffect, useMemo, useRef, useState } from 'react'
import { useTranslation, Trans } from 'react-i18next'
import { api } from '../lib/api'
import { pushToast } from '../lib/toast'
import { formatLocaleDate } from '../lib/locale'
import { useSettings } from '../hooks/useSettings'
import { useWorkspaces } from '../hooks/useWorkspaces'
import { useProjectsContext } from '../hooks/projectsContext'
import type { VaultItem } from '../types'
import { ViewHeader } from '../components/reusables/ViewHeader'
import { SearchBar } from '../components/ui/SearchBar'
import { Dropdown } from '../components/ui/Dropdown'
import { OverlayScrollArea } from '../components/reusables/OverlayScrollArea'
import { ConfirmDialog } from '../components/modals/ConfirmDialog'
import { Tooltip } from '../components/reusables/Tooltip'
import { SaveToVaultModal } from '../components/vault/SaveToVaultModal'
import { AddVaultItemModal } from '../components/vault/AddVaultItemModal'
import { EditVaultItemModal } from '../components/vault/EditVaultItemModal'
import { VaultItemPreviewModal } from '../components/vault/VaultItemPreviewModal'
import {
  IconBriefcase,
  IconChevronDown,
  IconFolderPlus,
  IconPencil,
  IconPlus,
  IconSearch,
  IconTrash,
} from '../lib/icons'

const VAULT_SORT_KEY = 'godothub_vault_sort'

type VaultSortOption = 'name_asc' | 'name_desc' | 'newest' | 'oldest'

const VAULT_SORT_OPTIONS: { value: VaultSortOption; labelKey: string }[] = [
  { value: 'name_asc', labelKey: 'sort_name_asc' },
  { value: 'name_desc', labelKey: 'sort_name_desc' },
  { value: 'newest', labelKey: 'sort_created_desc' },
  { value: 'oldest', labelKey: 'sort_created_asc' },
]

export function VaultView({
  connected = false,
}: {
  connected?: boolean
}) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { settings } = useSettings()
  const { activeId } = useWorkspaces()
  const { projects } = useProjectsContext()

  const [items, setItems] = useState<VaultItem[]>([])
  const [loaded, setLoaded] = useState(false)
  const [query, setQuery] = useState('')
  const [activeTags, setActiveTags] = useState<string[]>([])
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [previewItem, setPreviewItem] = useState<VaultItem | null>(null)
  const [editItem, setEditItem] = useState<VaultItem | null>(null)
  const [addItem, setAddItem] = useState<VaultItem | null>(null)
  const [saveOpen, setSaveOpen] = useState(false)
  const [sortBy, setSortBy] = useState<VaultSortOption>(() => {
    try {
      const raw = localStorage.getItem(VAULT_SORT_KEY)
      if (raw === 'name_asc' || raw === 'name_desc' || raw === 'newest' || raw === 'oldest') return raw
    } catch {}
    return 'name_asc'
  })

  const load = async () => {
    try {
      setItems(await api.listVaultItems())
    } catch {}
    setLoaded(true)
  }

  useEffect(() => {
    load()
  }, [activeId])

  useEffect(() => {
    try {
      localStorage.setItem(VAULT_SORT_KEY, sortBy)
    } catch {}
  }, [sortBy])

  const searchRef = useRef<HTMLInputElement | null>(null)
  useEffect(() => {
    const focusSearch = () => searchRef.current?.focus()
    window.addEventListener('app:focus-search', focusSearch)
    return () => window.removeEventListener('app:focus-search', focusSearch)
  }, [])

  const allTags = useMemo(() => {
    const set = new Set<string>()
    for (const item of items) for (const tag of item.tags) set.add(tag)
    return [...set].sort((a, b) => a.localeCompare(b))
  }, [items])

  const toggleTag = (tag: string) => {
    setActiveTags((prev) =>
      prev.includes(tag) ? prev.filter((x) => x !== tag) : [...prev, tag],
    )
  }

  const handleDelete = async (id: string) => {
    if (deleting) return
    setDeleting(true)
    try {
      await api.deleteVaultItem(id)
      setItems((prev) => prev.filter((i) => i.id !== id))
      setConfirmDelete(null)
    } catch (e) {
      pushToast('error', String(e))
    } finally {
      setDeleting(false)
    }
  }

  const isSearching = query.trim().length > 0
  const filteredItems = items
    .filter((item) => {
      if (
        activeTags.length > 0 &&
        !activeTags.every((tag) => item.tags.includes(tag))
      )
        return false
      if (!isSearching) return true
      const q = query.toLowerCase()
      return (
        item.name.toLowerCase().includes(q) ||
        (item.description && item.description.toLowerCase().includes(q)) ||
        item.tags.some((tag) => tag.toLowerCase().includes(q))
      )
    })
    .slice()
    .sort((a, b) => {
      switch (sortBy) {
        case 'name_desc':
          return b.name.localeCompare(a.name)
        case 'newest':
          return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        case 'oldest':
          return new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        case 'name_asc':
        default:
          return a.name.localeCompare(b.name)
      }
    })

  return (
    <div className="flex-1 min-w-0 h-full flex flex-col gap-2">
      <ViewHeader
        connected={connected}
        title={t('vault')}
        metric={
          <>
            <h2 className="text-4xl font-bold text-muted">
              {items.length}
            </h2>
            <p className="text-lg font-medium uppercase text-muted">
              {tc('vault_item_count', { count: items.length })}
            </p>
          </>
        }
        actions={
          <button
            type="button"

            onClick={() => setSaveOpen(true)}
            className="focus-ring cursor-pointer flex items-center gap-1.5 px-6 h-10 rounded-item bg-accent hover:bg-accent-bright text-white font-semibold text-[1.0625rem] "
          >
            <IconPlus className="w-4 h-4" />
            {tc('vault_save_btn')}
          </button>
        }
      >
        <div className="flex items-center gap-2">
          <SearchBar
            value={query}
            onChange={setQuery}
            inputRef={searchRef}
            placeholderKey="vault_search_placeholder"
            className="flex-1"
          />
        </div>
        {allTags.length > 0 && (
          <div className="flex flex-wrap items-center gap-1.5 pt-1">
            {allTags.map((tag) => {
              const active = activeTags.includes(tag)
              return (
                <button
                  key={tag}
                  type="button"
                  onClick={() => toggleTag(tag)}
                  className={`focus-ring cursor-pointer px-2.5 py-1 rounded-tag text-2xs font-mono  ${
                    active
                      ? 'bg-accent text-white'
                      : 'bg-overlay text-muted hover:text-ink hover:bg-raised'
                  }`}
                >
                  {tag}
                </button>
              )
            })}
          </div>
        )}
      </ViewHeader>

      <OverlayScrollArea
        className={`flex-1 min-w-0 ${connected ? '' : '-ms-2 -me-4 -mb-4'}`}
        hideThumb={!settings.show_scrollbars}
        topButtonBottom="bottom-17"
      >
        <div
          className={`h-full ${connected ? 'ps-5' : 'ps-2'} pe-5 pb-4 flex flex-col gap-2`}
        >
          {!loaded ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div
                  key={i}
                  className="h-52 rounded-item border border-outline/50 bg-overlay "
                />
              ))}
            </div>
          ) : items.length === 0 ? (
            <div className="rounded-item border border-dashed border-outline/50 py-20 flex flex-col items-center gap-3 text-center px-6">
              <div className="w-12 h-12 rounded-tile bg-overlay border border-outline/50 flex items-center justify-center">
                <IconBriefcase className="w-5 h-5 text-muted" />
              </div>
              <p className="text-sm text-muted max-w-sm leading-relaxed">
                <Trans
                  i18nKey="vault_empty"
                  ns="common"
                  components={{ 1: <strong /> }}
                />
              </p>
            </div>
          ) : filteredItems.length === 0 ? (
            <div className="rounded-item border border-dashed border-outline/50 py-16 flex flex-col items-center gap-3 text-center">
              <IconSearch className="w-5 h-5 text-muted" />
              <p className="text-sm text-muted">{tc('vault_no_match')}</p>
            </div>
          ) : (
            <>
              <div className="flex items-center justify-start">
                <Dropdown
                  align="left"
                  trigger={({ open, toggle }) => {
                    const activeOption = VAULT_SORT_OPTIONS.find((o) => o.value === sortBy)
                    return (
                      <button
                        type="button"
                        aria-expanded={open}

                        onClick={toggle}
                        className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 h-7 px-3 rounded-item bg-overlay text-muted hover:text-ink hover:bg-raised "
                      >
                        <span className="text-[0.75rem] text-muted">{tc('sort')}:</span>
                        <span className="text-[0.8125rem] font-medium text-ink">
                          {activeOption ? tc(activeOption.labelKey) : tc('sort')}
                        </span>
                        <IconChevronDown className="w-3 h-3 text-muted" />
                      </button>
                    )
                  }}
                  items={VAULT_SORT_OPTIONS.map((opt) => ({
                    key: opt.value,
                    label: tc(opt.labelKey),
                    active: opt.value === sortBy,
                    onClick: () => setSortBy(opt.value),
                  }))}
                />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">

                  {filteredItems.map((item) => (
                    <div
                      key={item.id}
                      className="relative border border-outline/50 rounded-item bg-overlay p-5 flex flex-col gap-3 group cursor-pointer hover:border-accent-dim "
                      onClick={() => setPreviewItem(item)}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="w-10 h-10 rounded-tile bg-raised border border-outline/50 flex items-center justify-center shrink-0">
                          <IconBriefcase className="w-4 h-4 text-muted" />
                        </div>
                        <div className="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 ">
                          <Tooltip content={tc('vault_edit_action')} side="top">
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                setEditItem(item)
                              }}
                              className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 hover:text-ink hover:bg-raised "
                              aria-label={tc('vault_edit_action')}
                            >
                              <IconPencil className="w-3.5 h-3.5" />
                            </button>
                          </Tooltip>
                          <Tooltip content={tc('vault_delete_action', { name: item.name })} side="top">
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                setConfirmDelete(item.id)
                              }}
                              className="focus-ring cursor-pointer p-1.5 rounded-btn text-muted/40 hover:text-danger hover:bg-danger/10 "
                              aria-label={tc('vault_delete_action', { name: item.name })}
                            >
                              <IconTrash className="w-3.5 h-3.5" />
                            </button>
                          </Tooltip>
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <h4 className="font-display font-semibold text-sm truncate">
                          {item.name}
                        </h4>
                        {item.description && (
                          <p className="text-xs text-muted mt-1 leading-relaxed line-clamp-3">
                            {item.description}
                          </p>
                        )}
                      </div>
                      {item.tags.length > 0 && (
                        <div className="flex flex-wrap gap-1">
                          {item.tags.slice(0, 4).map((tag) => (
                            <span
                              key={tag}
                              className="inline-flex items-center px-1.5 py-0.5 rounded-tag bg-raised border border-outline/50 text-3xs font-mono text-muted"
                            >
                              {tag}
                            </span>
                          ))}
                          {item.tags.length > 4 && (
                            <span className="text-3xs text-muted/50 font-mono">
                              +{item.tags.length - 4}
                            </span>
                          )}
                        </div>
                      )}
                      <div className="flex items-center gap-1.5 text-3xs text-muted/50 font-mono">
                        {item.godot_version && (
                          <span>
                            {tc('godot')} {item.godot_version}
                          </span>
                        )}
                        {item.created_at && (
                          <>
                            <span>·</span>
                            <span>{formatLocaleDate(new Date(item.created_at))}</span>
                          </>
                        )}
                      </div>
                      <button

                        onClick={(e) => {
                          e.stopPropagation()
                          setAddItem(item)
                        }}
                        className="focus-ring cursor-pointer flex items-center justify-center gap-1.5 px-3 py-2 rounded-item bg-accent/10 border border-accent-dim/30 text-accent-bright text-xs font-semibold hover:bg-accent/20 "
                      >
                        <IconFolderPlus className="w-3.5 h-3.5" />
                        {tc('vault_add_btn')}
                      </button>
                    </div>
                  ))}

              </div>
            </>
          )}
          <div className="shrink-0 h-4" aria-hidden="true" />
        </div>
      </OverlayScrollArea>


        {previewItem && (
          <VaultItemPreviewModal
            item={previewItem}
            onClose={() => setPreviewItem(null)}
          />
        )}



        {saveOpen && (
          <SaveToVaultModal
            projects={projects}
            onClose={() => setSaveOpen(false)}
            onSaved={() => load()}
          />
        )}



        {editItem && (
          <EditVaultItemModal
            item={editItem}
            onClose={() => setEditItem(null)}
            onSaved={(updated) => {
              setItems((prev) =>
                prev.map((i) => (i.id === updated.id ? updated : i)),
              )
            }}
          />
        )}



        {addItem && (
          <AddVaultItemModal
            item={addItem}
            projects={projects}
            onClose={() => setAddItem(null)}
          />
        )}



        {confirmDelete && (
          <ConfirmDialog
            variant="danger"
            title={tc('vault_delete_title')}
            description={
              items.find((i) => i.id === confirmDelete)?.name
                ? tc('vault_delete_desc', {
                    name: items.find((i) => i.id === confirmDelete)?.name,
                  })
                : tc('cannot_undo')
            }
            confirmLabel={deleting ? tc('deleting') : tc('delete')}
            onConfirm={() => handleDelete(confirmDelete)}
            onCancel={() => setConfirmDelete(null)}
          />
        )}

    </div>
  )
}
