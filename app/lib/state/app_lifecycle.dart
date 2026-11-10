import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

WidgetsBinding? ghBindingOrNull() {
  try {
    return WidgetsBinding.instance;
  } on FlutterError {
    return null;
  }
}

bool ghAppHidden() {
  final state = ghBindingOrNull()?.lifecycleState;
  return state == AppLifecycleState.hidden || state == AppLifecycleState.paused || state == AppLifecycleState.detached;
}

Brightness ghPlatformBrightness() =>
    ghBindingOrNull()?.platformDispatcher.platformBrightness ?? PlatformDispatcher.instance.platformBrightness;

class _GhBindingObserver with WidgetsBindingObserver {
  _GhBindingObserver({this.onResumed, this.onBrightness});

  final VoidCallback? onResumed;
  final void Function(Brightness brightness)? onBrightness;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed?.call();
  }

  @override
  void didChangePlatformBrightness() => onBrightness?.call(ghPlatformBrightness());
}

extension GhRefLifecycle on Ref {
  void listenAppResumed(VoidCallback handler) => _observe(_GhBindingObserver(onResumed: handler));

  void listenPlatformBrightness(void Function(Brightness brightness) handler) =>
      _observe(_GhBindingObserver(onBrightness: handler));

  void _observe(_GhBindingObserver observer) {
    final binding = ghBindingOrNull();
    if (binding == null) return;
    binding.addObserver(observer);
    onDispose(() => binding.removeObserver(observer));
  }
}
