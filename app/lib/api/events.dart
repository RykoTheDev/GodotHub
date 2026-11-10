import 'dart:async';

import 'package:flutter/foundation.dart';

import '../src/rust/api/events.dart' as rust;

export '../src/rust/api/events.dart'
    show AppEvent, AppEventKind, ConsoleExit, DownloadFailure, DownloadUnverified, ProjectExited, ProjectLaunched, ScanProgress;

abstract final class AppEvents {
  static Stream<rust.AppEvent>? _all;

  static Stream<rust.AppEvent> get all => _all ??= rust.appEvents().asBroadcastStream();

  @visibleForTesting
  static void debugReset() => _all = null;

  static Stream<rust.AppEvent> of(rust.AppEventKind kind) => all.where((event) => event.kind == kind);

  static Stream<rust.AppEvent> ofAny(Set<rust.AppEventKind> kinds) =>
      all.where((event) => kinds.contains(event.kind));

  static Stream<T> payloads<T extends Object>(rust.AppEventKind kind, T? Function(rust.AppEvent event) select) =>
      of(kind).map(select).where((payload) => payload != null).cast<T>();
}
