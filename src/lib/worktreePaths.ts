export function normalizeWorktreePath(path: string): string {
  const normalized = path.replace(/\\/g, '/').replace(/\/+$/, '')
  return /^(?:[a-z]:|\/\/)/i.test(normalized) ? normalized.toLowerCase() : normalized
}

export function isWithinWorktree(projectPath: string, worktreePath: string): boolean {
  const project = normalizeWorktreePath(projectPath)
  const root = normalizeWorktreePath(worktreePath)
  return project === root || project.startsWith(`${root}/`)
}

export function worktreeProjectPath(projectPath: string, currentRoot: string, nextRoot: string): string {
  const project = projectPath.replace(/\\/g, '/').replace(/\/+$/, '')
  const root = currentRoot.replace(/\\/g, '/').replace(/\/+$/, '')
  const joined = `${nextRoot.replace(/\\/g, '/').replace(/\/+$/, '')}${project.slice(root.length)}`
  return projectPath.includes('\\') ? joined.replace(/\//g, '\\') : joined
}

export function defaultWorktreePath(projectPath: string): string {
  const path = projectPath.replace(/\\/g, '/').replace(/\/+$/, '')
  const split = path.lastIndexOf('/')
  return `${path.slice(0, split + 1)}${path.slice(split + 1)}-worktree`
}
