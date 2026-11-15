import 'package:flutter/foundation.dart';

import '../src/rust/api/diagnostics.dart' as rust;
import '../src/rust/api/diagnostics.dart' show CrashNotice;

export '../src/rust/api/diagnostics.dart' show CrashNotice;

const diagnosticStackLines = 12;

abstract final class Diagnostics {
  static bool _ready = false;

  static void markReady() => _ready = true;

  static String describe(Object error, StackTrace? stack) {
    final frames = stack?.toString().trimRight().split('\n').take(diagnosticStackLines).join('\n') ?? '';
    return frames.isEmpty ? '$error' : '$error\n$frames';
  }

  static void record(String source, String message) {
    if (!_ready) return;
    try {
      rust.recordDiagnostic(source: source, message: message);
    } catch (_) {}
  }

  static Future<String> tail({int lines = 40}) async {
    if (!_ready) return '';
    try {
      return await rust.diagnosticLogTail(maxLines: lines);
    } catch (_) {
      return '';
    }
  }

  static Future<CrashNotice?> takeCrashNotice() async {
    if (!_ready) return null;
    try {
      return await rust.takeCrashNotice();
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void debugReset() => _ready = false;
}
