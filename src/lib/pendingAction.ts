let pendingAction: string | null = null

export function consumePendingAction(): string | null {
  const action = pendingAction
  pendingAction = null
  return action
}
