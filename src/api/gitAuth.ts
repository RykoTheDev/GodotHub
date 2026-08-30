import { invoke } from '@tauri-apps/api/core'
import type {
  CreateRepoResult,
  DeviceFlowPoll,
  DeviceFlowStart,
  GitAuthState,
  UserRepoPage,
} from '../types'

export const gitAuthApi = {
  getState: () => invoke<GitAuthState>('get_git_auth_state'),
  createRemoteRepo: (
    provider: 'github' | 'gitlab',
    name: string,
    privateRepo: boolean,
    path: string,
  ) =>
    invoke<CreateRepoResult>('create_remote_repo', {
      provider,
      name,
      privateRepo,
      path,
    }),
  startDeviceFlow: (
    provider: 'github' | 'gitlab',
    baseUrl?: string | null,
    clientId?: string | null,
  ) =>
    invoke<DeviceFlowStart>('start_device_flow', {
      provider,
      baseUrl: baseUrl ?? null,
      clientId: clientId ?? null,
    }),
  pollDeviceFlow: (
    provider: 'github' | 'gitlab',
    deviceCode: string,
    baseUrl?: string | null,
    clientId?: string | null,
  ) =>
    invoke<DeviceFlowPoll>('poll_device_flow', {
      provider,
      deviceCode,
      baseUrl: baseUrl ?? null,
      clientId: clientId ?? null,
    }),
  disconnect: (provider: 'github' | 'gitlab') =>
    invoke<void>('disconnect_git_auth', { provider }),
  listUserRepos: (provider: 'github' | 'gitlab', page: number) =>
    invoke<UserRepoPage>('list_user_repos', { provider, page }),
  savePat: (host: string, username: string, token: string) =>
    invoke<void>('save_git_pat', { host, username, token }),
  removePat: (host: string) => invoke<void>('remove_git_pat', { host }),
}
