Future<void> Function()? _pending;

void registerPendingSave(Future<void> Function() fn) {
  _pending = fn;
}

Future<void> flushPendingSave() async {
  final fn = _pending;
  _pending = null;
  if (fn != null) await fn();
}
