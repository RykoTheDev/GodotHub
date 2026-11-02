import { useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { openUrl } from '@tauri-apps/plugin-opener'
import { Dropdown } from './Dropdown'
import { api } from '../../lib/api'
import { useChangelogBadge } from '../../hooks/useChangelogBadge'
import { useSettings } from '../../hooks/useSettings'
import { useWorkspaceMenuItem } from './WorkspaceSwitcher'
import { IconBookOpen, IconBug, IconEye, IconEyeSlash, IconChevronRight, IconGithub, IconGitlab, IconHeart, IconPlug } from '../../lib/icons'
import type { GitAuthState } from '../../types'

export function AccountMenu({
  trigger,
  className,
  onNavigate,
}: {
  trigger: (props: { open: boolean; toggle: () => void }) => ReactNode
  className?: string
  onNavigate: (tab: string) => void
}) {
  const { t } = useTranslation('nav')
  const { t: tc } = useTranslation('common')
  const { hasNewEntry } = useChangelogBadge()
  const { settings, update } = useSettings()
  const workspaceItem = useWorkspaceMenuItem()
  const [osName, setOsName] = useState<string | null>(null)
  const [gitAuth, setGitAuth] = useState<GitAuthState | null>(null)

  const load = (open: boolean) => {
    if (!open) return
    api.getOsUsername().then(setOsName).catch(() => setOsName(null))
    api.gitAuthGetState().then(setGitAuth).catch(() => setGitAuth(null))
  }

  const accounts = [
    { key: 'github', icon: IconGithub, label: 'GitHub', account: gitAuth?.github },
    { key: 'gitlab', icon: IconGitlab, label: 'GitLab', account: gitAuth?.gitlab },
  ].flatMap(({ account, ...rest }) => (account ? [{ ...rest, account }] : []))
  const name = osName || t('you')

  return (
    <Dropdown
      trigger={trigger}
      side="top"
      align="left"
      className={className}
      onOpenChange={load}
      items={[
        ...(settings.workspaces_enabled && workspaceItem ? [workspaceItem] : []),
        {
          key: 'privacy',
          label: settings.privacy_mode ? tc('privacy_mode_disable') : tc('privacy_mode_enable'),
          icon: settings.privacy_mode ? IconEyeSlash : IconEye,
          dividerAfter: true,
          onClick: () => update({ ...settings, privacy_mode: !settings.privacy_mode }),
        },
        {
          key: 'changelog',
          label: t('changelog'),
          icon: IconBookOpen,
          badge: hasNewEntry ? tc('new_badge') : undefined,
          onClick: () => onNavigate('changelog'),
        },
        {
          key: 'bug',
          label: tc('report_a_bug'),
          icon: IconBug,
          danger: true,
          onClick: () => window.dispatchEvent(new Event('app:report-bug')),
        },
        {
          key: 'support',
          label: tc('support'),
          icon: IconHeart,
          onClick: () => openUrl('https://www.patreon.com/cw/TheRyko/membership'),
        },
      ]}
    >
      {(close) => (
      <div className="flex flex-col gap-2 pt-1.5 pb-2.5 mb-1 border-b border-white/6">
        <span className="sensitive px-2.5 font-display text-xl font-black tracking-tight text-ink truncate">{name}</span>
        {accounts.length > 0 && (
        <div className="flex flex-col rounded-2xl border border-outline/40 bg-raised/60 overflow-hidden divide-y divide-outline/40 text-xs">
          {accounts.map(({ key, icon: Icon, label, account }) => (
            <div
              key={key}
              className="h-7 min-w-0 flex items-center gap-2 px-3 bg-accent/10"
            >
              <Icon className="w-3.5 h-3.5 shrink-0 text-ink" />
              <span className="text-muted shrink-0">{label}</span>
              <span className="sensitive ms-auto truncate text-ink">@{account.username}</span>
            </div>
          ))}
          <button
            type="button"
            role="menuitem"
            onClick={() => {
              close()
              window.dispatchEvent(new CustomEvent('app:open-settings-category', { detail: 'integrations' }))
            }}
            className="focus-ring cursor-pointer h-7 min-w-0 flex items-center gap-2 px-3 text-muted hover:text-ink hover:bg-raised transition-colors"
          >
            <IconPlug className="w-3.5 h-3.5 shrink-0" />
            <span className="truncate">{t('account_manage')}</span>
            <IconChevronRight className="w-2.5 h-2.5 shrink-0 ms-auto rtl:rotate-180" />
          </button>
        </div>
        )}
      </div>
      )}
    </Dropdown>
  )
}
