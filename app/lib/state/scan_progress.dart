import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import 'api_data.dart';

const Duration scanProgressClearDelay = Duration(milliseconds: 800);

class ScanProgressNotifier extends Notifier<ScanProgress?> {
  ScanProgressNotifier(this.kind);

  final AppEventKind kind;

  @override
  ScanProgress? build() {
    final timers = <Timer>{};
    ref.onDispose(() {
      for (final timer in timers) {
        timer.cancel();
      }
    });
    ref.listenAppEvent(kind, (event) {
      final progress = event.scanProgress;
      if (progress == null) return;
      state = progress;
      if (progress.current >= progress.total) {
        late final Timer timer;
        timer = Timer(scanProgressClearDelay, () {
          timers.remove(timer);
          if (ref.mounted) state = null;
        });
        timers.add(timer);
      }
    });
    return null;
  }
}
