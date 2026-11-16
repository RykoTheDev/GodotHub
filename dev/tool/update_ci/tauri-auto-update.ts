import { check as checkForTestUpdate } from '@tauri-apps/plugin-updater'
import { relaunch as relaunchForTestUpdate } from '@tauri-apps/plugin-process'

setTimeout(() => {
  void checkForTestUpdate().then(async (update) => {
    if (!update) return
    await update.downloadAndInstall()
    await relaunchForTestUpdate()
  })
}, 8000)
