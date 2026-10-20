import { api } from './api'
import { pushToast } from './toast'

export function reportLaunchError(err: unknown): void {
  const message = String(err)
  const match = message.match(/Godot (.+?) is not installed/i)
  if (match) {
    const tag = match[1]
    pushToast('error', message, 8000, {
      label: 'Download',
      onClick: () => {
        pushToast('info', `Downloading Godot ${tag}…`)
        api
          .downloadVersionForTag(tag)
          .catch((e) => pushToast('error', String(e)))
      },
    })
    return
  }
  pushToast('error', message)
}
