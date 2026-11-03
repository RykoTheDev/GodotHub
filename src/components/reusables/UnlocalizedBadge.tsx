import { useTranslation } from 'react-i18next'

export function UnlocalizedBadge({ checks }: { checks: [string, string][] }) {
  const { i18n } = useTranslation()
  const lng = i18n.resolvedLanguage || i18n.language || 'en-US'
  if (lng.toLowerCase().startsWith('en')) return null

  const enT = i18n.getFixedT('en-US')
  const lngT = i18n.getFixedT(lng)
  const unlocalized = checks.every(([ns, key]) => {
    const en = enT(key, { ns })
    const loc = lngT(key, { ns })
    return typeof en === 'string' && en.length > 0 && en === loc
  })
  if (!unlocalized) return null

  return (
    <span className="shrink-0 inline-flex items-center h-5 px-2 rounded-tag bg-amber/15 border border-amber/40 text-amber text-3xs font-semibold uppercase tracking-wide">
      Unlocalized
    </span>
  )
}
