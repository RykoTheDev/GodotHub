import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:nativeapi/nativeapi.dart' show DisplayManager;
import 'package:window_manager/window_manager.dart';

import '../api/events.dart';
import '../logic/pending_save.dart';
import '../src/rust/api/native.dart' as native;
import '../src/rust/api/window.dart' as rust;
import 'process_exit.dart';
import 'tray.dart';

const Size defaultWindowSize = Size(1280, 720);
const Size minimumWindowSize = Size(1180, 680);

/// The saved size always comes back. The saved position only does when it is on a
/// display: Wayland cannot report a window position (it reads as 0,0, which a top
/// panel puts outside the work area), so a position that fails the check must not
/// cost the user their size. Without a usable position the size is kept to the first
/// work area, so a window saved on a display that is gone cannot open off-screen.
({Size size, Offset? position})? restoredWindow({
  required rust.WindowState? saved,
  required double scale,
  required List<Rect> workAreas,
}) {
  if (saved == null || scale <= 0) {
    return null;
  }
  var size = Size(
    math.max(saved.width / scale, minimumWindowSize.width),
    math.max(saved.height / scale, minimumWindowSize.height),
  );
  final position = Offset(saved.x / scale, saved.y / scale);
  final visible = workAreas.any((area) => area.contains(position + const Offset(48, 16)));
  if (!visible && workAreas.isNotEmpty) {
    final area = workAreas.first;
    size = Size(
      math.max(math.min(size.width, area.width), minimumWindowSize.width),
      math.max(math.min(size.height, area.height), minimumWindowSize.height),
    );
  }
  return (size: size, position: visible ? position : null);
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

const windowCloseChannel = MethodChannel('godothub/window-close');

class AppWindow {
  AppWindow._(this._window, this._scale);

  final Window _window;
  final double _scale;
  Rect? _normalBounds;
  Size? _restoredSize;
  int _restoreRetries = 0;
  Timer? _settleTimer;
  Timer? _hardStopTimer;
  bool _closing = false;
  bool Function()? keepAliveOnClose;
  bool? startedWithOsDecorations;

  /// False while the window is still settling to its restored size on Linux; the app
  /// stays invisible until then, so it appears once, at the right size.
  static final ValueNotifier<bool> settled = ValueNotifier(true);

  static AppWindow? _instance;

  static AppWindow get instance => _instance!;

  static AppWindow? get maybeInstance => _instance;

  bool get isMac => Platform.isMacOS;

  static Future<AppWindow> start({required String title, required bool useOsDecorations}) async {
    final window = WindowManager.instance.getCurrent()!;
    final scale = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final app = AppWindow._(window, scale)..startedWithOsDecorations = useOsDecorations;
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
    // The primary display first: a saved window that is on no display is kept to the first one.
    final primaryArea = DisplayManager.instance.getPrimary()?.workArea.toRect();
    final workAreas = [
      ?primaryArea,
      ...DisplayManager.instance.getAll().map((display) => display.workArea.toRect()).where((r) => r != primaryArea),
    ];
    final restored = restoredWindow(saved: saved, scale: scale, workAreas: workAreas);
    final position = restored?.position;
    if (restored != null && position != null) {
      window.bounds = (position & restored.size).toNative();
    } else {
      window.setSize((restored?.size ?? defaultWindowSize).toNative(), false);
      window.center();
    }
    if (restored != null && !(saved?.maximized ?? false)) {
      // Wayland always composites, so the window can be left invisible while it settles.
      // The OS frame would show over an empty window, and without a compositor it would be black.
      final hideWhileSettling = !useOsDecorations && Platform.environment.containsKey('WAYLAND_DISPLAY');
      app._holdRestoredSize(restored.size, hideWindow: hideWhileSettling);
    }
    app._normalBounds = window.bounds.toRect();
    if (saved?.maximized ?? false) {
      window.maximize();
    }

    window.addListener(app._onWindowEvent);
    AppEvents.of(AppEventKind.secondInstance).listen(app._onSecondInstance);
    AppEvents.of(AppEventKind.showMainWindow).listen((_) => app.showAndFocus());
    AppEvents.of(AppEventKind.hideMainWindow).listen((_) => app.hide());
    AppEvents.of(AppEventKind.exitApp).listen((_) => app.quit());
    windowCloseChannel.setMethodCallHandler((call) async {
      if (call.method == 'close') await app.requestClose();
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      window.show();
      window.focus();
      app._startSettleClock();
    });
    return app;
  }

  /// On Linux the compositor and the window's shadow gutter resize a window again
  /// after it is mapped, so the restored size does not stick (#352). Until the size
  /// has stopped changing, put the restored size back whenever it was changed.
  void _holdRestoredSize(Size size, {required bool hideWindow}) {
    if (!Platform.isLinux) return;
    _restoredSize = size;
    _restoreRetries = 3;
    if (hideWindow) settled.value = false;
    // Only a failsafe: the settle clock proper starts once the window is shown, because
    // the compositor resizes it after it maps, however long the app took to start.
    _hardStopTimer = Timer(const Duration(seconds: 10), _releaseRestoredSize);
  }

  void _startSettleClock() {
    if (_restoredSize == null) return;
    _settleTimer?.cancel();
    _hardStopTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 1500), _releaseRestoredSize);
    _hardStopTimer = Timer(const Duration(seconds: 3), _releaseRestoredSize);
  }

  /// Ends the settle period. Safe to call again.
  void _releaseRestoredSize() {
    _settleTimer?.cancel();
    _hardStopTimer?.cancel();
    _restoredSize = null;
    settled.value = true;
  }

  /// True when the window was put back to the restored size.
  bool _reassertRestoredSize() {
    final target = _restoredSize;
    if (target == null) return false;
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 1200), _releaseRestoredSize);
    final current = _window.bounds.toRect().size;
    if ((current.width - target.width).abs() < 1 && (current.height - target.height).abs() < 1) {
      return false;
    }
    if (_restoreRetries > 0 && !_window.isMaximized && !_window.isMinimized) {
      _restoreRetries--;
      _window.setSize(target.toNative(), false);
      return true;
    }
    _releaseRestoredSize();
    return false;
  }

  Future<void> _onWindowEvent(WindowEvent event) async {
    switch (event) {
      case WindowResizedEvent() || WindowMovedEvent():
        if (_reassertRestoredSize()) break;
        if (!_window.isMaximized && !_window.isMinimized) {
          _normalBounds = _window.bounds.toRect();
        }
      case WindowCloseRequestedEvent():
        event.request.cancel();
        await requestClose();
      default:
        break;
    }
  }

  Future<void> requestClose() async {
    if (_closing) return;
    if (Platform.isMacOS || (keepAliveOnClose?.call() ?? false)) {
      await flushPendingSave().catchError((Object _) {});
      await _saveState();
      hide();
    } else {
      await quit();
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
    native.setMainWindowVisible(visible: true);
  }

  void hide() {
    _window.hide();
    native.setMainWindowVisible(visible: false);
  }

  Future<void> _prepareExit() async {
    _closing = true;
    await flushPendingSave().catchError((Object _) {});
    await _saveState();
    TrayController.instance?.dispose();
  }

  Future<void> quit() async {
    await _prepareExit();
    endProcess(0);
  }

  Future<void> relaunch() async {
    await native.relaunch(args: const []);
    await _prepareExit();
    endProcess(0);
  }

  Future<void> openLaunchArgs() async {
    await rust.openLaunchArgs();
  }
}
