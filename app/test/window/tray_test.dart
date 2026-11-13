import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/settings.dart';
import 'package:godothub/src/rust/api/native.dart' as native;
import 'package:godothub/window/tray.dart';

class FakeTrayBackend implements TrayBackend {
  String? tooltip;
  List<TrayEntry> menu = const [];
  int menuUpdates = 0;
  bool disposed = false;

  @override
  void setTooltip(String tooltip) => this.tooltip = tooltip;

  @override
  void setMenu(List<TrayEntry> entries) {
    menu = entries;
    menuUpdates++;
  }

  @override
  void dispose() => disposed = true;

  TrayAction action(String label) {
    for (final entry in [...menu, for (final e in menu) if (e is TraySubmenu) ...e.entries]) {
      if (entry is TrayAction && entry.label == label) return entry;
    }
    throw StateError('no $label');
  }
}

class FakeDock implements DockMenu {
  List<native.RecentProject>? last;

  @override
  void setRecent(List<native.RecentProject> projects) => last = projects;
}

native.RecentProject recent(String id, String label) => native.RecentProject(id: id, label: label, path: 'C:/p/$id');

void main() {
  late FakeTrayBackend backend;
  late List<native.RecentProject> projects;
  late List<String> calls;

  TrayController controller({DockMenu? dock}) => TrayController(
    backend: backend,
    tooltip: 'GodotHub Beta',
    loadRecent: () async => projects,
    openRecent: (id) => calls.add('open:$id'),
    show: () => calls.add('show'),
    quit: () => calls.add('quit'),
    dock: dock,
  );

  setUp(() {
    backend = FakeTrayBackend();
    projects = [];
    calls = [];
  });

  test('the tooltip is the channel display name', () {
    controller();
    expect(backend.tooltip, 'GodotHub Beta');
  });

  test('the menu without recent projects shows a disabled placeholder', () async {
    await controller().refresh();
    expect(backend.menu, hasLength(5));
    expect((backend.menu[0] as TrayAction).label, 'Show GodotHub');
    expect(backend.menu[1], isA<TraySeparator>());
    final submenu = backend.menu[2] as TraySubmenu;
    expect(submenu.label, 'Open Recent');
    expect(submenu.entries, hasLength(1));
    final placeholder = submenu.entries.single as TrayAction;
    expect(placeholder.label, 'No recent projects');
    expect(placeholder.enabled, isFalse);
    expect(placeholder.onSelected, isNull);
    expect(backend.menu[3], isA<TraySeparator>());
    expect((backend.menu[4] as TrayAction).label, 'Quit');
  });

  test('recent projects open by id and show and quit call back', () async {
    projects = [recent('a', 'Alpha'), recent('b', 'Beta')];
    final dock = FakeDock();
    await controller(dock: dock).refresh();
    final submenu = backend.menu[2] as TraySubmenu;
    expect([for (final e in submenu.entries) (e as TrayAction).label], ['Alpha', 'Beta']);
    backend.action('Beta').onSelected!();
    backend.action('Show GodotHub').onSelected!();
    backend.action('Quit').onSelected!();
    expect(calls, ['open:b', 'show', 'quit']);
    expect(dock.last!.map((p) => p.id), ['a', 'b']);
  });

  test('refresh rebuilds the menu and ignores stale and failed loads', () async {
    final tray = controller();
    projects = [recent('a', 'Alpha')];
    await tray.refresh();
    projects = [recent('c', 'Gamma')];
    await tray.refresh();
    expect(backend.menuUpdates, 2);
    expect(((backend.menu[2] as TraySubmenu).entries.single as TrayAction).label, 'Gamma');
    final failing = TrayController(
      backend: backend,
      tooltip: 'x',
      loadRecent: () async => throw StateError('core down'),
      openRecent: (_) {},
      show: () {},
      quit: () {},
    );
    await failing.refresh();
    expect(backend.menuUpdates, 2);
  });

  test('SettingsApi.refreshTrayMenu refreshes the installed tray and is a no-op otherwise', () async {
    SettingsApi.trayRefresher = null;
    await SettingsApi.refreshTrayMenu();
    final tray = controller();
    SettingsApi.trayRefresher = tray.refresh;
    addTearDown(() => SettingsApi.trayRefresher = null);
    projects = [recent('a', 'Alpha')];
    await SettingsApi.refreshTrayMenu();
    expect(backend.menuUpdates, 1);
  });

  test('closing keeps the app alive only when minimizing to tray off macOS', () {
    final tray = controller();
    expect(tray.keepAliveOnClose(), isFalse);
    tray.minimizeToTray = true;
    expect(tray.keepAliveOnClose(), !Platform.isMacOS);
  });

  test('dispose releases the backend', () {
    controller().dispose();
    expect(backend.disposed, isTrue);
  });

  testWidgets('the mac dock menu sends the recent list and opens clicked items', (tester) async {
    final sent = <Object?>[];
    const channel = MethodChannel('godothub/dock-test');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      sent.add(call.arguments);
      return null;
    });
    MacDockMenu(channel).setRecent([recent('a', 'Alpha')]);
    await tester.pump();
    expect(sent.single, [
      {'id': 'a', 'label': 'Alpha', 'path': 'C:/p/a'},
    ]);
  });
}
