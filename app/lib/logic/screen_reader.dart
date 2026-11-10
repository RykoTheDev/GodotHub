import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../state/app_signals.dart';

const String announceEvent = 'app:announce';

@immutable
class ScreenReaderAnnouncement {
  const ScreenReaderAnnouncement(this.message);

  final String? message;

  @override
  bool operator ==(Object other) => other is ScreenReaderAnnouncement && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ScreenReaderAnnouncement($message)';
}

void announce(String message) {
  AppSignals.emit(announceEvent, ScreenReaderAnnouncement(message));
}

class ScreenReaderAnnouncer extends StatefulWidget {
  const ScreenReaderAnnouncer({super.key, required this.enabled, this.child});

  final bool enabled;
  final Widget? child;

  @override
  State<ScreenReaderAnnouncer> createState() => _ScreenReaderAnnouncerState();
}

class _ScreenReaderAnnouncerState extends State<ScreenReaderAnnouncer> {
  StreamSubscription<AppSignal>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = AppSignals.on(announceEvent).listen(_handle);
  }

  void _handle(AppSignal signal) {
    final detail = signal.detail;
    final message = detail is ScreenReaderAnnouncement ? detail.message : null;
    if (message == null || message.isEmpty) return;
    if (!mounted || !widget.enabled) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        view,
        message,
        Directionality.maybeOf(context) ?? TextDirection.ltr,
        assertiveness: Assertiveness.polite,
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
