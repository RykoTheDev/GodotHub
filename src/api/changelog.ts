import { invoke } from '@tauri-apps/api/core'
import type {
  ChangelogDraft,
  ChangelogEntry,
  ChangelogNote,
} from '../types'

export const changelogApi = {
  list: () => invoke<ChangelogEntry[]>('list_changelog_entries'),
  listGitTags: () => invoke<string[]>('list_git_tags'),
  generateDraft: (from: string, to: string) =>
    invoke<ChangelogDraft>('generate_changelog_draft', { from, to }),
  add: (
    version: string,
    date: string,
    notes: ChangelogNote[],
    knownIssues: string[],
  ) =>
    invoke<ChangelogEntry>('add_changelog_entry', {
      version,
      date,
      notes,
      knownIssues,
    }),
  update: (
    id: string,
    version: string,
    date: string,
    notes: ChangelogNote[],
    knownIssues: string[],
  ) =>
    invoke<ChangelogEntry>('update_changelog_entry', {
      id,
      version,
      date,
      notes,
      knownIssues,
    }),
  delete: (id: string) =>
    invoke<void>('delete_changelog_entry', { id }),
}
