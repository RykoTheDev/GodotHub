import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:nativeapi/nativeapi.dart' show DisplayManager;
import 'package:window_manager/window_manager.dart';

import '../api/events.dart';
import '../src/rust/api/window.dart' as rust;

const Size defaultWindowSize = Size(1280, 720);
const Size minimumWindowSize = Size(1180, 680);

Rect? restoredBounds({
  required rust.WindowState? saved,
  required double scale,
  required List<Rect> workAreas,
}) {
  if (saved == null || scale <= 0) {
    return null;
  }
  final bounds = Rect.fromLTWH(
    saved.x / scale,
    saved.y / scale,
    math.max(saved.width / scale, minimumWindowSize.width),
    math.max(saved.height / scale, minimumWindowSize.height),
  );
  final visible = workAreas.any((area) => area.contains(bounds.topLeft + const Offset(48, 16)));
  return visible ? bounds : null;
}

rust.WindowState windowStateFrom({required Rect bounds, required bool maximized, required double scale}) {
  return rust.WindowState(
    width: (bounds.width * scale).round(),
    height: (bounds.height * scale).round(),
    x: (bounds.left * scale).round(),
    y: (bounds.top * scale).round(),
    maximized: maximized,
  );
}

class AppWindow {
  AppWindow._(this._window, this._scale);

  final Window _window;
  final double _scale;
  Rect? _normalBounds;
  bool _closing = false;

  static AppWindow? _instance;

  static AppWindow get instance => _instance!;

  bool get isMac => Platform.isMacOS;

  static Future<AppWindow> start({required String title, required bool useOsDecorations}) async {
    final window = WindowManager.instance.getCurrent()!;
    final scale = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final app = AppWindow._(window, scale);
    _instance = app;

    window.title = title;
    window.minimumSize = minimumWindowSize.toNative();
    if (Platform.isMacOS || !useOsDecorations) {
      window.titleBarStyle = TitleBarStyle.hidden;
    }
    if (!Platform.isMacOS && !useOsDecorations) {
      window.isWindowControlButtonsVisible = false;
    }

    final saved = await rust.loadWindowState();
    final workAreas = DisplayManager.instance.getAll().map((display) => display.workArea.toRect()).toList();
    final bounds = restoredBounds(saved: saved, scale: scale, workAreas: workAreas);
    if (bounds != null) {
      window.bounds = bounds.toNative();
    } else {
      window.setSize(defaultWindowSize.toNative(), false);
      window.center();
    }
    app._normalBounds = window.bounds.toRect();
    final maximize = saved?.maximized ?? false;

    window.addListener(app._onWindowEvent);
    AppEvents.of(AppEventKind.secondInstance).listen(app._onSecondInstance);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      window.show();
      if (maximize) {
        window.maximize();
      }
      window.focus();
    });
    return app;
  }

  Future<void> _onWindowEvent(WindowEvent event) async {
    switch (event) {
      case WindowResizedEvent() || WindowMovedEvent():
        if (!_window.isMaximized && !_window.isMinimized) {
          _normalBounds = _window.bounds.toRect();
        }
      case WindowCloseRequestedEvent():
        if (_closing) {
          return;
        }
        event.request.cancel();
        await _saveState();
        if (Platform.isMacOS) {
          _window.hide();
        } else {
          _closing = true;
          _window.close();
        }
      default:
        break;
    }
  }

  Future<void> _saveState() async {
    final bounds = _normalBounds ?? _window.bounds.toRect();
    try {
      await rust.saveWindowState(
        state: windowStateFrom(bounds: bounds, maximized: _window.isMaximized, scale: _scale),
      );
    } catch (_) {}
  }

  Future<void> _onSecondInstance(AppEvent event) async {
    final opened = await rust.openFromArgs(args: event.args ?? const []);
    if (!opened) {
      showAndFocus();
    }
  }

  void showAndFocus() {
    if (_window.isMinimized) {
      _window.restore();
    }
    _window.show();
    _window.focus();
  }

  Future<void> openLaunchArgs() async {
    await rust.openLaunchArgs();
  }
}
