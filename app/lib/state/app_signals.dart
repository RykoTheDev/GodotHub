import 'dart:async';

import 'package:flutter/foundation.dart';

@immutable
class AppSignal {
  const AppSignal(this.name, [this.detail]);

  final String name;
  final Object? detail;

  @override
  String toString() => 'AppSignal($name, $detail)';
}

abstract final class AppSignals {
  static StreamController<AppSignal> _controller = StreamController<AppSignal>.broadcast(sync: true);

  static Stream<AppSignal> get all => _controller.stream;

  static Stream<AppSignal> on(String name) => all.where((signal) => signal.name == name);

  static void emit(String name, [Object? detail]) => _controller.add(AppSignal(name, detail));

  @visibleForTesting
  static void debugReset() {
    _controller.close();
    _controller = StreamController<AppSignal>.broadcast(sync: true);
  }
}
