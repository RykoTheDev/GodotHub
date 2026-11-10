import 'dart:async';

import '../api/api.dart';
import '../ui/feedback/toast.dart';

final _notInstalled = RegExp(r'Godot (.+?) is not installed', caseSensitive: false);

void reportLaunchError(Object? err, {GhToastStore? toasts, Future<void> Function(String tag)? download}) {
  final store = toasts ?? ghToasts;
  final message = '$err';
  final match = _notInstalled.firstMatch(message);
  if (match != null) {
    final tag = match[1]!;
    store.pushToast(
      GhToastType.error,
      message,
      ttlMs: 8000,
      action: GhToastAction(
        label: 'Download',
        onClick: () {
          store.pushToast(GhToastType.info, 'Downloading Godot $tag…');
          unawaited(
            Future.sync(() => (download ?? Api.downloadVersionForTag)(tag)).then<void>(
              (_) {},
              onError: (Object e) {
                store.pushToast(GhToastType.error, '$e');
              },
            ),
          );
        },
      ),
    );
    return;
  }
  store.pushToast(GhToastType.error, message);
}
