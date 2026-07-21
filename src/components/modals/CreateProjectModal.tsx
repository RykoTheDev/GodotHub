import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import type { Category, InstalledGodotVersion, ProjectTemplate } from '../../types'
import { api } from '../../lib/api'
import { Dropdown } from '../ui/Dropdown'

interface Props {
  installedVersions: InstalledGodotVersion[]
  defaultLocation?: string | null
  categories?: Category[]
  onClose: () => void
  onCreated: () => void
}

const ICON_PRESET_SVG = (
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth={1.5}
    className="w-5 h-5 text-muted"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Zm16.5-13.5h.008v.008h-.008V7.5Z"
    />
  </svg>
)

export function CreateProjectModal({
  installedVersions,
  defaultLocation,
  onClose,
  onCreated,
  categories = [],
}: Props) {
  const [name, setName] = useState('')
  const [location, setLocation] = useState(defaultLocation ?? '')
  const [version, setVersion] = useState(installedVersions[0]?.tag ?? '')
  const [iconPath, setIconPath] = useState<string | null>(null)
  const [templateId, setTemplateId] = useState<string | null>(null)
  const [category, setCategory] = useState('')
  const [templates, setTemplates] = useState<ProjectTemplate[]>([])
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    api.listTemplates().then(setTemplates).catch(() => {})
  }, [])

  const pickLocation = async () => {
    const folder = await api.pickFolder()
    if (folder) setLocation(folder)
  }

  const pickIcon = async () => {
    const file = await api.pickFile()
    if (file) {
      setIconPath(file)
    }
  }

  const clearIcon = () => {
    setIconPath(null)
  }

  const submit = async () => {
    if (!name || !location) {
      setError('Give the project a name and a folder to create it in.')
      return
    }
    setBusy(true)
    setError(null)
    try {
      await api.createProject(name, location, version, iconPath, templateId, category || null)
      onCreated()
    } catch (e) {
      setError(String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 12, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
        className="bg-surface border border-line rounded-2xl p-8 w-full max-w-2xl flex flex-col gap-6 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div>
          <h3 className="font-display font-semibold text-xl">New Project</h3>
          <p className="text-xs text-muted mt-1">
            Creates a fresh project.godot in the folder you choose.
          </p>
        </div>

        {/* Row 1: Name + Location */}
        <div className="grid grid-cols-2 gap-4">
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-muted">Name</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="focus-ring bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm focus:border-accent-dim transition-colors"
              placeholder="My Awesome Game"
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-muted">Location</label>
            <div className="flex gap-2.5">
              <input
                value={location}
                readOnly
                className="flex-1 bg-raised border border-line rounded-lg px-3.5 py-2.5 text-sm font-mono text-muted truncate"
                placeholder="Choose a folder"
              />
              <motion.button
                whileHover={{ y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={pickLocation}
                className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-sm transition-colors shrink-0"
              >
                Browse
              </motion.button>
            </div>
          </div>
        </div>

        {/* Row 2: Template + Category */}
        <div className="grid grid-cols-2 gap-4">
          {templates.length > 0 && (
            <div className="flex flex-col gap-2">
              <label className="text-xs font-medium text-muted">
                Template{' '}
                <span className="text-muted/60 font-normal">(optional)</span>
              </label>
              <div className="flex flex-wrap gap-1.5">
                <button
                  type="button"
                  onClick={() => setTemplateId(null)}
                  className={`focus-ring cursor-pointer px-2.5 py-1.5 rounded-lg border text-[11px] font-medium transition-colors ${
                    templateId === null
                      ? 'border-accent bg-accent/10 text-accent-bright'
                      : 'border-line text-muted hover:border-accent-dim hover:text-ink'
                  }`}
                >
                  Blank
                </button>
                {templates.map((t) => (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => setTemplateId(t.id)}
                    className={`focus-ring cursor-pointer px-2.5 py-1.5 rounded-lg border text-[11px] font-medium transition-colors ${
                      templateId === t.id
                        ? 'border-accent bg-accent/10 text-accent-bright'
                        : 'border-line text-muted hover:border-accent-dim hover:text-ink'
                    }`}
                  >
                    {t.name}
                  </button>
                ))}
              </div>
              {templateId && (
                <p className="text-[10px] text-muted/60">
                  Files from the template will be copied into the new project.
                </p>
              )}
            </div>
          )}

          {categories.length > 0 && (
            <div className={`flex flex-col gap-2 ${templates.length === 0 ? 'col-span-2' : ''}`}>
              <label className="text-xs font-medium text-muted">
                Category{' '}
                <span className="text-muted/60 font-normal">(optional)</span>
              </label>
              <Dropdown
                value={category}
                onChange={setCategory}
                emptyLabel="No category"
                options={categories.map((c) => ({
                  value: c.name,
                  label: c.name,
                  dotClassName: undefined,
                  dotColor: c.color,
                }))}
              />
            </div>
          )}
        </div>

        {/* Row 3: Version + Icon */}
        <div className="grid grid-cols-2 gap-4">
          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-muted">Godot Version</label>
            <Dropdown
              value={version}
              onChange={setVersion}
              options={installedVersions.map((v) => ({
                value: v.tag,
                label: v.custom_name || v.tag,
                dotClassName: 'bg-mint',
              }))}
            />
            {installedVersions.length === 0 && (
              <p className="text-xs text-amber">
                No engine installed yet, grab one from the Versions tab first.
              </p>
            )}
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-medium text-muted">
              Project Icon{' '}
              <span className="text-muted/60 font-normal">(optional)</span>
            </label>
            <div className="flex items-center gap-3">
              {/* Icon preview */}
              <div className="w-11 h-11 rounded-xl border border-line bg-raised flex items-center justify-center overflow-hidden shrink-0">
                {ICON_PRESET_SVG}
              </div>
              <div className="flex gap-2 flex-1">
                <motion.button
                  whileHover={{ y: -1 }}
                  whileTap={{ scale: 0.96 }}
                  onClick={pickIcon}
                  className="focus-ring cursor-pointer px-3 py-2 rounded-lg border border-line hover:border-accent-dim hover:bg-raised text-xs transition-colors"
                >
                  {iconPath ? 'Change' : 'Choose'}
                </motion.button>
                {iconPath && (
                  <motion.button
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    whileHover={{ y: -1 }}
                    whileTap={{ scale: 0.96 }}
                    onClick={clearIcon}
                    className="focus-ring cursor-pointer px-3 py-2 rounded-lg border border-line text-muted hover:text-danger hover:border-danger/30 hover:bg-danger/10 text-xs transition-colors"
                  >
                    Reset
                  </motion.button>
                )}
              </div>
            </div>
            {iconPath && (
              <p className="text-[10px] text-muted/60 font-mono truncate mt-0.5">
                {iconPath}
              </p>
            )}
            <p className="text-[10px] text-muted/40">
              SVG, PNG, or JPG. Defaults to Godot logo.
            </p>
          </div>
        </div>

        {error && <p className="text-xs text-danger">{error}</p>}

        <div className="flex justify-end gap-2.5 mt-1 pt-3 border-t border-line">
          <motion.button
            whileHover={{ y: -1 }}
            whileTap={{ scale: 0.96 }}
            onClick={onClose}
            className="focus-ring cursor-pointer px-4 py-2.5 rounded-lg text-sm text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            Cancel
          </motion.button>
          <motion.button
            whileHover={busy ? undefined : { y: -1 }}
            whileTap={busy ? undefined : { scale: 0.96 }}
            onClick={submit}
            disabled={busy}
            className="focus-ring px-5 cursor-pointer py-2.5 rounded-lg bg-accent hover:bg-accent-bright disabled:opacity-50 text-sm font-medium text-white transition-colors"
          >
            {busy ? 'Creating…' : 'Create Project'}
          </motion.button>
        </div>
      </motion.div>
    </motion.div>
  )
}
