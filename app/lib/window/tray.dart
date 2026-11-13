import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nativeapi/nativeapi.dart' as native_ui;

import '../api/events.dart';
import '../api/settings.dart';
import '../src/rust/api/native.dart' as native;
import '../state/settings.dart';
import 'app_window.dart';

const trayShowLabel = 'Show GodotHub';
const trayRecentLabel = 'Open Recent';
const trayNoRecentLabel = 'No recent projects';
const trayQuitLabel = 'Quit';

sealed class TrayEntry {
  const TrayEntry();
}

class TrayAction extends TrayEntry {
  const TrayAction(this.label, {this.onSelected, this.enabled = true});

  final String label;
  final void Function()? onSelected;
  final bool enabled;
}

class TraySeparator extends TrayEntry {
  const TraySeparator();
}

class TraySubmenu extends TrayEntry {
  const TraySubmenu(this.label, this.entries);

  final String label;
  final List<TrayEntry> entries;
}

abstract interface class TrayBackend {
  void setTooltip(String tooltip);

  void setMenu(List<TrayEntry> entries);

  void dispose();
}

abstract interface class DockMenu {
  void setRecent(List<native.RecentProject> projects);
}

List<TrayEntry> buildTrayMenu({
  required List<native.RecentProject> recent,
  required void Function() onShow,
  required void Function(String id) onOpen,
  required void Function() onQuit,
}) => [
  TrayAction(trayShowLabel, onSelected: onShow),
  const TraySeparator(),
  TraySubmenu(trayRecentLabel, [
    if (recent.isEmpty) const TrayAction(trayNoRecentLabel, enabled: false),
    for (final project in recent) TrayAction(project.label, onSelected: () => onOpen(project.id)),
  ]),
  const TraySeparator(),
  TrayAction(trayQuitLabel, onSelected: onQuit),
];

class TrayController {
  TrayController({
    required TrayBackend backend,
    required String tooltip,
    required this.loadRecent,
    required this.openRecent,
    required this.show,
    required this.quit,
    this.dock,
  }) : _backend = backend {
    backend.setTooltip(tooltip);
  }

  static TrayController? instance;

  final TrayBackend _backend;
  final Future<List<native.RecentProject>> Function() loadRecent;
  final void Function(String id) openRecent;
  final void Function() show;
  final void Function() quit;
  final DockMenu? dock;
  bool minimizeToTray = false;
  int _generation = 0;

  bool keepAliveOnClose() => !Platform.isMacOS && minimizeToTray;

  Future<void> refresh() async {
    final generation = ++_generation;
    final List<native.RecentProject> recent;
    try {
      recent = await loadRecent();
    } catch (_) {
      return;
    }
    if (generation != _generation) return;
    _backend.setMenu(buildTrayMenu(recent: recent, onShow: show, onOpen: openRecent, onQuit: quit));
    dock?.setRecent(recent);
  }

  void dispose() {
    _generation++;
    _backend.dispose();
    if (identical(instance, this)) {
      instance = null;
      SettingsApi.trayRefresher = null;
    }
  }

  static Future<TrayController?> start({required String tooltip}) async {
    final backend = await NativeTrayBackend.create(onClick: () => AppWindow.instance.showAndFocus());
    if (backend == null) return null;
    final controller = TrayController(
      backend: backend,
      tooltip: tooltip,
      loadRecent: native.refreshRecentProjects,
      openRecent: (id) => native.openRecentProject(id: id).ignore(),
      show: () => AppWindow.instance.showAndFocus(),
      quit: () => AppWindow.instance.quit().ignore(),
      dock: Platform.isMacOS ? MacDockMenu() : null,
    );
    instance = controller;
    SettingsApi.trayRefresher = controller.refresh;
    AppWindow.instance.keepAliveOnClose = controller.keepAliveOnClose;
    AppEvents.of(AppEventKind.refreshMenus).listen((_) => controller.refresh().ignore());
    unawaited(controller.refresh());
    return controller;
  }
}

final traySyncProvider = Provider<void>((ref) {
  ref.listen(settingsProvider.select((state) => state.value?.minimizeToTray ?? false), (previous, next) {
    TrayController.instance?.minimizeToTray = next;
  }, fireImmediately: true);
});

class NativeTrayBackend implements TrayBackend {
  NativeTrayBackend._(this._icon);

  final native_ui.TrayIcon _icon;
  final List<(native_ui.MenuItem, native_ui.ListenerId)> _listeners = [];
  final List<Object> _held = [];

  static Future<NativeTrayBackend?> create({required void Function() onClick}) async {
    if (!native_ui.TrayManager.instance.isSupported()) return null;
    final icon = native_ui.TrayIcon.create();
    if (icon == null) return null;
    final asset = Platform.isMacOS ? 'assets/tray/trayTemplate.png' : 'assets/tray/tray.png';
    final bytes = await rootBundle.load(asset);
    icon.icon = native_ui.Image.fromBase64(base64Encode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)));
    icon.isIconTemplate = Platform.isMacOS;
    icon.setContextMenuTrigger(native_ui.ContextMenuTrigger.rightClicked);
    final backend = NativeTrayBackend._(icon);
    icon.addListener((event) {
      if (event is native_ui.TrayIconClickedEvent) onClick();
    });
    return backend;
  }

  @override
  void setTooltip(String tooltip) => _icon.setTooltip(tooltip);

  native_ui.Menu? _build(List<TrayEntry> entries, List<Object> held) {
    final menu = native_ui.Menu.create();
    if (menu == null) return null;
    held.add(menu);
    for (final entry in entries) {
      switch (entry) {
        case TraySeparator():
          menu.addSeparator();
        case TrayAction(:final label, :final onSelected, :final enabled):
          final item = native_ui.MenuItem.createWithLabelAndType(label, native_ui.MenuItemType.normal);
          if (item == null) continue;
          item.isEnabled = enabled;
          if (onSelected != null) {
            final id = item.addListener((event) {
              if (event is native_ui.MenuItemClickedEvent) onSelected();
            });
            _listeners.add((item, id));
          }
          held.add(item);
          menu.addItem(item);
        case TraySubmenu(:final label, :final entries):
          final item = native_ui.MenuItem.createWithLabelAndType(label, native_ui.MenuItemType.submenu);
          if (item == null) continue;
          item.submenu = _build(entries, held);
          held.add(item);
          menu.addItem(item);
      }
    }
    return menu;
  }

  void _release() {
    for (final (item, id) in _listeners) {
      item.removeListener(id);
    }
    _listeners.clear();
  }

  @override
  void setMenu(List<TrayEntry> entries) {
    _release();
    final held = <Object>[];
    _icon.setContextMenu(_build(entries, held));
    _held
      ..clear()
      ..addAll(held);
  }

  @override
  void dispose() {
    _release();
    _icon.setContextMenu(null);
    _held.clear();
    _icon.dispose();
  }
}

class MacDockMenu implements DockMenu {
  MacDockMenu([this._channel = const MethodChannel('godothub/dock')]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openRecent' && call.arguments is String) {
        await native.openRecentProject(id: call.arguments as String);
      }
    });
  }

  final MethodChannel _channel;

  @override
  void setRecent(List<native.RecentProject> projects) {
    _channel.invokeMethod<void>('setRecent', [
      for (final project in projects) {'id': project.id, 'label': project.label, 'path': project.path},
    ]).ignore();
  }
}
