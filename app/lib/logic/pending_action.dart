String? _pendingAction;

String? consumePendingAction() {
  final action = _pendingAction;
  _pendingAction = null;
  return action;
}
