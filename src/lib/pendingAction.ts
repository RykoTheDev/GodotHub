let pendingAction: string | null = null

export function setPendingAction(action: string | null) {
  pendingAction = action
}

export function consumePendingAction(): string | null {
  const action = pendingAction
  pendingAction = null
  return action
}
