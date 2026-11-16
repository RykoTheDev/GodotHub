String? _pendingAction;

/// Asks the next view that checks for [action] to perform it once it is
/// built, for example to open a section after a tab switch.
void setPendingAction(String action) => _pendingAction = action;

/// Takes the pending action only when it is [action], leaving others for the
/// view they belong to.
bool consumePendingActionIf(String action) {
  if (_pendingAction != action) return false;
  _pendingAction = null;
  return true;
}

String? consumePendingAction() {
  final action = _pendingAction;
  _pendingAction = null;
  return action;
}
