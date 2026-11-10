import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/window.dart';
import 'package:godothub/window/app_window.dart';

const screen = Rect.fromLTWH(0, 0, 1920, 1040);

void main() {
  test('restores the Tauri window state from physical pixels', () {
    const saved = WindowState(width: 2560, height: 1582, x: 666, y: 302, maximized: false);
    final bounds = restoredBounds(saved: saved, scale: 2, workAreas: const [screen]);
    expect(bounds, const Rect.fromLTWH(333, 151, 1280, 791));
  });

  test('keeps the minimum size', () {
    const saved = WindowState(width: 800, height: 600, x: 10, y: 10, maximized: false);
    final bounds = restoredBounds(saved: saved, scale: 1, workAreas: const [screen])!;
    expect(bounds.size, minimumWindowSize);
  });

  test('ignores missing state and positions off every display', () {
    expect(restoredBounds(saved: null, scale: 1, workAreas: const [screen]), isNull);
    const offscreen = WindowState(width: 1280, height: 720, x: 5000, y: 5000, maximized: false);
    expect(restoredBounds(saved: offscreen, scale: 1, workAreas: const [screen]), isNull);
  });

  test('saves logical bounds as physical pixels', () {
    final state = windowStateFrom(bounds: const Rect.fromLTWH(333, 151, 1280, 791), maximized: true, scale: 1.5);
    expect([state.x, state.y, state.width, state.height, state.maximized], [500, 227, 1920, 1187, true]);
  });
}
