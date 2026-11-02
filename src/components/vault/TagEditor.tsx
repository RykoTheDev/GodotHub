import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { IconPlus, IconX } from '../../lib/icons'

interface Props {
  tags: string[]
  onChange: (tags: string[]) => void
}

export function TagEditor({ tags, onChange }: Props) {
  const { t } = useTranslation('common')
  const [input, setInput] = useState('')

  const addTag = () => {
    const tag = input.trim()
    if (!tag) return
    setInput('')
    if (!tags.includes(tag)) onChange([...tags, tag])
  }

  const removeTag = (tag: string) => {
    onChange(tags.filter((x) => x !== tag))
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex gap-2">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault()
              addTag()
            }
          }}
          placeholder={t('vault_tag_input_placeholder')}
          className="focus-ring flex-1 min-w-0 bg-raised border border-outline/50 rounded-item px-3 py-2 text-xs text-ink placeholder:text-muted focus:border-accent-dim outline-none "
        />
        <button
          type="button"
          onClick={addTag}
          disabled={!input.trim()}
          className="focus-ring cursor-pointer shrink-0 inline-flex items-center gap-1.5 px-3 rounded-item bg-accent/15 border border-accent/40 text-accent-bright hover:bg-accent/25 text-xs font-medium disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <IconPlus className="w-3 h-3" />
          {t('add_tag')}
        </button>
      </div>

      {tags.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {tags.map((tag) => (
            <span
              key={tag}
              className="inline-flex items-center gap-1 pl-2.5 pr-1.5 py-1 rounded-tag bg-raised border border-outline/50 text-[11px] font-mono text-ink"
            >
              {tag}
              <button
                type="button"
                onClick={() => removeTag(tag)}
                aria-label={t('remove_tag')}
                className="focus-ring cursor-pointer p-0.5 rounded text-muted/60 hover:text-danger hover:bg-danger/10 "
              >
                <IconX className="w-2.5 h-2.5" />
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
