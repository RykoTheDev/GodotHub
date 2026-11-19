import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/src/rust/api/window.dart';
import 'package:godothub/window/app_window.dart';

const screen = Rect.fromLTWH(0, 0, 1920, 1040);

void main() {
  test('restores the Tauri window state from physical pixels', () {
    const saved = WindowState(width: 2560, height: 1582, x: 666, y: 302, maximized: false);
    final restored = restoredWindow(saved: saved, scale: 2, workAreas: const [screen])!;
    expect(restored.size, const Size(1280, 791));
    expect(restored.position, const Offset(333, 151));
  });

  test('keeps the minimum size', () {
    const saved = WindowState(width: 800, height: 600, x: 10, y: 10, maximized: false);
    final restored = restoredWindow(saved: saved, scale: 1, workAreas: const [screen])!;
    expect(restored.size, minimumWindowSize);
  });

  test('ignores missing state', () {
    expect(restoredWindow(saved: null, scale: 1, workAreas: const [screen]), isNull);
  });

  test('keeps the size when the position is off every display', () {
    const offscreen = WindowState(width: 1500, height: 900, x: 5000, y: 5000, maximized: false);
    final restored = restoredWindow(saved: offscreen, scale: 1, workAreas: const [screen])!;
    expect(restored.size, const Size(1500, 900));
    expect(restored.position, isNull);
  });

  test('keeps an oversized window from a vanished display on the screen', () {
    const external = WindowState(width: 2500, height: 1400, x: 3000, y: 0, maximized: false);
    final restored = restoredWindow(saved: external, scale: 1, workAreas: const [screen])!;
    expect(restored.size, const Size(1920, 1040));
    expect(restored.position, isNull);
  });

  test('keeps the size when a top panel hides the origin a Wayland window reports', () {
    const wayland = WindowState(width: 1500, height: 900, x: 0, y: 0, maximized: false);
    const belowPanel = Rect.fromLTWH(0, 32, 1920, 1048);
    final restored = restoredWindow(saved: wayland, scale: 1, workAreas: const [belowPanel])!;
    expect(restored.size, const Size(1500, 900));
    expect(restored.position, isNull);
  });

  test('saves logical bounds as physical pixels', () {
    final state = windowStateFrom(bounds: const Rect.fromLTWH(333, 151, 1280, 791), maximized: true, scale: 1.5);
    expect([state.x, state.y, state.width, state.height, state.maximized], [500, 227, 1920, 1187, true]);
  });
}
