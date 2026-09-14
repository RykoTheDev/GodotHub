import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useTranslation } from 'react-i18next'
import type { AliasInfo, InstalledGodotVersion } from '../../types'
import { api } from '../../lib/api'
import { isWindows } from '../../lib/platform'
import { ConfirmDialog } from './ConfirmDialog'
import { ModalShell } from './ModalShell'
import {
  IconCheck,
  IconCopy,
  IconExternalLink,
  IconPlus,
  IconTerminal,
  IconTrash,
} from '../../lib/icons'

export function VersionAliasesModal({
  versions,
  aliases,
  aliasesDir,
  initialTag,
  onClose,
  onCreate,
  onDelete,
}: {
  versions: InstalledGodotVersion[]
  aliases: AliasInfo[]
  aliasesDir: string
  initialTag?: string
  onClose: () => void
  onCreate: (name: string, tag: string) => Promise<AliasInfo>
  onDelete: (name: string) => Promise<void>
}) {
  const { t: tv } = useTranslation('versions')
  const { t: tc } = useTranslation('common')

  const [name, setName] = useState('')
  const [tag, setTag] = useState(initialTag ?? versions[0]?.tag ?? '')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [copied, setCopied] = useState<string | null>(null)
  const [pendingDelete, setPendingDelete] = useState<AliasInfo | null>(null)

  const folder = aliasesDir || aliases[0]?.aliases_dir || ''

  // Mono builds load their GodotSharp runtime from next to the executable, so on
  // Windows their aliases are launcher scripts rather than links.
  const needsMonoScriptNote = (versionTag: string) =>
    isWindows && versions.some((v) => v.tag === versionTag && v.is_mono)

  const copy = async (target: string, value: string) => {
    try {
      await navigator.clipboard.writeText(value)
      setCopied(target)
      setTimeout(() => setCopied(null), 1500)
    } catch {}
  }

  const submit = async () => {
    const trimmed = name.trim()
    if (!trimmed || !tag || busy) return
    setBusy(true)
    setError(null)
    try {
      await onCreate(trimmed, tag)
      setName('')
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  const confirmDelete = async () => {
    const target = pendingDelete
    if (!target) return
    setPendingDelete(null)
    setError(null)
    try {
      await onDelete(target.name)
    } catch (e) {
      setError(String(e))
    }
  }

  return (
    <>
      <ModalShell
        icon={<IconTerminal className="w-5 h-5 text-accent-bright" />}
        title={tv('aliases_title')}
        description={tv('aliases_desc')}
        maxWidth="max-w-xl"
        onClose={onClose}
        footer={
          <>
            {folder && (
              <button
                type="button"
                onClick={() => api.openProjectFolder(folder).catch(() => {})}
                className="focus-ring cursor-pointer flex items-center gap-2 px-4 py-2.5 rounded-item border border-line text-sm text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
              >
                <IconExternalLink className="w-4 h-4" />
                {tv('current_open_folder')}
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="focus-ring cursor-pointer ml-auto px-4 py-2.5 rounded-item bg-accent hover:bg-accent/90 text-sm font-medium text-white transition-colors"
            >
              {tc('close')}
            </button>
          </>
        }
      >
        <div className="px-6 pb-6 flex flex-col gap-4">
          <div className="flex flex-col gap-2.5 rounded-item border border-outline/50 bg-overlay p-3.5">
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void submit()
                }}
                placeholder={tv('alias_name_placeholder')}
                aria-label={tv('alias_name_label')}
                spellCheck={false}
                className="focus-ring flex-1 min-w-0 bg-raised border border-line rounded-btn px-3 py-2 text-sm font-mono text-ink outline-none placeholder:text-muted/60"
              />
              <motion.button
                whileTap={{ scale: 0.96 }}
                type="button"
                disabled={!name.trim() || !tag || busy}
                onClick={() => void submit()}
                className={`focus-ring flex items-center gap-1.5 px-4 py-2 rounded-btn text-sm font-medium border transition-colors ${
                  !name.trim() || !tag || busy
                    ? 'bg-raised text-muted/40 border-line cursor-not-allowed'
                    : 'bg-accent text-white border-accent hover:bg-accent-bright cursor-pointer'
                }`}
              >
                <IconPlus className="w-3.5 h-3.5" />
                {tv('alias_add')}
              </motion.button>
            </div>

            {versions.length > 0 ? (
              <div className="flex flex-wrap gap-1.5">
                {versions.map((v) => {
                  const active = tag === v.tag
                  return (
                    <button
                      key={v.tag}
                      type="button"
                      onClick={() => setTag(v.tag)}
                      className={`focus-ring cursor-pointer inline-flex items-center gap-1.5 px-2.5 py-1 rounded-tag text-[11px] font-medium border transition-colors ${
                        active
                          ? 'bg-accent/15 text-accent-bright border-accent-dim/50'
                          : 'bg-overlay text-muted border-outline/50 hover:text-ink hover:bg-raised'
                      }`}
                    >
                      {active && <IconCheck className="w-2.5 h-2.5" />}
                      {v.is_mono && (
                        <span className="text-[9px] font-bold uppercase tracking-wider">
                          {tv('mono_short')}
                        </span>
                      )}
                      {v.custom_name || v.tag}
                    </button>
                  )
                })}
              </div>
            ) : (
              <p className="text-xs text-amber">{tv('aliases_no_versions')}</p>
            )}

            {needsMonoScriptNote(tag) && (
              <p className="text-[11px] text-muted leading-relaxed">
                {tv('alias_mono_script_note')}
              </p>
            )}
          </div>

          {error && (
            <p className="text-xs text-danger leading-relaxed">{error}</p>
          )}

          {aliases.length === 0 ? (
            <p className="text-xs text-muted leading-relaxed px-1">
              {tv('aliases_empty')}
            </p>
          ) : (
            <div className="flex flex-col gap-2">
              {aliases.map((alias) => (
                <div
                  key={alias.name}
                  className="flex items-center gap-3 px-3 py-2.5 rounded-item bg-overlay border border-outline/50"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 min-w-0">
                      <p className="font-mono text-sm text-ink truncate">
                        {alias.name}
                      </p>
                      <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-tag bg-black/15 text-muted border border-outline/40 shrink-0">
                        {alias.tag}
                      </span>
                      {alias.method === 'shim' && (
                        <span
                          title={
                            needsMonoScriptNote(alias.tag)
                              ? tv('alias_mono_script_note')
                              : undefined
                          }
                          className="text-[10px] font-semibold px-1.5 py-0.5 rounded-tag bg-amber/10 text-amber border border-amber/30 shrink-0"
                        >
                          {tv('alias_shim_badge')}
                        </span>
                      )}
                    </div>
                    <p
                      className="font-mono text-[11px] text-muted truncate mt-0.5"
                      title={alias.alias_path}
                    >
                      {alias.alias_path}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => copy(alias.name, alias.alias_path)}
                    aria-label={tv('alias_copy_path')}
                    className="focus-ring cursor-pointer shrink-0 flex items-center gap-1.5 px-2.5 py-1.5 rounded-btn border border-line text-xs text-muted hover:text-ink hover:border-accent-dim hover:bg-raised transition-colors"
                  >
                    {copied === alias.name ? (
                      <IconCheck className="w-3.5 h-3.5 text-mint" />
                    ) : (
                      <IconCopy className="w-3.5 h-3.5" />
                    )}
                    {copied === alias.name ? tv('current_copied') : tv('current_copy')}
                  </button>
                  <button
                    type="button"
                    onClick={() => setPendingDelete(alias)}
                    aria-label={tv('alias_remove')}
                    className="focus-ring cursor-pointer shrink-0 p-2 rounded-btn text-muted/70 hover:text-danger hover:bg-danger/10 transition-colors"
                  >
                    <IconTrash className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>
          )}

          {folder && (
            <p className="text-xs text-muted leading-relaxed">
              {tv('aliases_path_hint')}
            </p>
          )}
        </div>
      </ModalShell>

      <AnimatePresence>
        {pendingDelete && (
          <ConfirmDialog
            title={tv('alias_remove_title')}
            description={tv('alias_remove_desc', { name: pendingDelete.name })}
            confirmLabel={tv('alias_remove')}
            variant="danger"
            onConfirm={() => void confirmDelete()}
            onCancel={() => setPendingDelete(null)}
          />
        )}
      </AnimatePresence>
    </>
  )
}
