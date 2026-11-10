import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/discord_rpc.dart';
import 'package:godothub/state/news.dart';
import 'package:godothub/state/projects.dart';
import 'package:godothub/state/settings.dart';

import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';

Project project({String id = 'p', String name = 'game', String path = '/work/game', String version = '4.3', int? started}) => Project(
  id: id,
  name: name,
  path: path,
  godotVersion: version,
  createdAt: '2026-01-01',
  pinned: false,
  sortOrder: 0,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.zero,
  sessionStartedAtMs: started == null ? null : BigInt.from(started),
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

class FakeProjects extends ProjectsNotifier {
  FakeProjects(this.list);

  final List<Project> list;

  @override
  Future<List<Project>> fetch() async => list;

  @override
  void setup() {}
}

class FakeClient implements DiscordRpcClient {
  final calls = <String>[];
  final activities = <DiscordActivity>[];
  final connection = StreamController<bool>.broadcast();
  bool fail = false;

  @override
  Future<void> connect(String appId) async {
    calls.add('connect $appId');
    if (fail) throw StateError('no discord');
  }

  @override
  Future<void> disconnect() async => calls.add('disconnect');

  @override
  Future<void> setActivity(DiscordActivity activity) async => activities.add(activity);

  @override
  Stream<bool> get connectionChanges => connection.stream;
}

void main() {
  group('buildDiscordActivity', () {
    final settings = defaultSettings;

    test('falls back to view presets and a generic preset', () {
      expect(buildDiscordActivity(settings: settings, view: 'versions'),
          const DiscordActivity(details: 'Browsing Versions', state: 'Deciding which one to install...'));
      expect(buildDiscordActivity(settings: settings),
          const DiscordActivity(details: 'Using GodotHub', state: 'Managing my Projects'));
      expect(buildDiscordActivity(settings: settings, view: 'vault').details, 'Using GodotHub');
    });

    test('running project uses resolved names only for folder-named projects', () {
      final folderNamed = project(name: 'game', path: r'C:\work\game', started: 100);
      expect(
        buildDiscordActivity(settings: settings, running: folderNamed, resolvedName: 'Space Game'),
        const DiscordActivity(details: 'Space Game', state: 'Godot 4.3', startTimestamp: 100),
      );
      expect(buildDiscordActivity(settings: settings, running: folderNamed).details, 'game');
      final renamed = project(name: 'My Game', path: '/work/game', version: '', started: 5);
      expect(
        buildDiscordActivity(settings: settings, running: renamed, resolvedName: 'Space Game'),
        const DiscordActivity(details: 'My Game', state: 'Working on a Project', startTimestamp: 5),
      );
    });

    test('custom presences, hidden names and exclusions', () {
      final running = project(started: 9);
      final custom = copySettings(
        settings,
        discordRpcProjectPresences: const [DiscordProjectPresence(id: 'p', details: '  Boss fight ', state: ' ')],
      );
      expect(buildDiscordActivity(settings: custom, running: running).details, 'Boss fight');
      expect(buildDiscordActivity(settings: custom, running: running).state, 'Godot 4.3');
      const secret = DiscordActivity(details: 'Working on a Top Secret Project', state: 'Please do not disturb', startTimestamp: 9);
      expect(buildDiscordActivity(settings: copySettings(settings, discordRpcShowProjects: false), running: running), secret);
      expect(buildDiscordActivity(settings: copySettings(settings, discordRpcExcludedProjects: const ['p']), running: running), secret);
    });

    test('picks the most recently started session and the app id fallback', () {
      final a = project(id: 'a', started: 10);
      final b = project(id: 'b', started: 30);
      final idle = project(id: 'c', started: 0);
      expect(discordRunningProject([a, idle, b])?.id, 'b');
      expect(discordRunningProject([idle, project(id: 'd')]), isNull);
      expect(discordAppIdOf(settings), defaultDiscordAppId);
      expect(discordAppIdOf(copySettings(settings, discordAppId: () => ' 42 ')), '42');
      expect(const DiscordActivity(details: 'd', state: 's', startTimestamp: 1).toJson(), {
        'name': 'GodotHub',
        'details': 'd',
        'state': 's',
        'timestamps': {'start': 1},
      });
    });
  });

  group('discordRpcProvider', () {
    late FakeRustApi rust;
    late FakeClient client;

    setUp(() {
      rust = installFakeRust();
      client = FakeClient();
      rust.on('crateApiProjectsGetProjectName', ({required String path}) async => 'Space Game');
    });

    Future<ProviderContainer> start({AppSettings? settings, List<Project> projects = const []}) async {
      final c = ProviderContainer(
        overrides: [
          discordRpcClientProvider.overrideWithValue(client),
          fakeSettings(() => settings ?? defaultSettings),
          projectsProvider.overrideWith(() => FakeProjects(projects)),
        ],
      );
      addTearDown(c.dispose);
      c.listen(discordRpcProvider, (_, _) {});
      await pumpEventQueue();
      return c;
    }

    test('connects when enabled, sends the presence once, and follows view changes', () async {
      final c = await start();
      expect(client.calls, ['connect $defaultDiscordAppId']);
      expect(c.read(discordRpcProvider).connected, isTrue);
      expect(client.activities.map((a) => a.details), ['Using GodotHub']);

      AppSignals.emit(viewChangedSignal, 'news');
      await pumpEventQueue();
      expect(client.activities.map((a) => a.details), ['Using GodotHub', 'Reading Godot News']);
      AppSignals.emit(viewChangedSignal, 'news');
      await pumpEventQueue();
      expect(client.activities, hasLength(2));
      expect(c.read(discordRpcProvider).view, 'news');
    });

    test('disconnects when turned off and reconnects with a new app id', () async {
      final c = await start();
      await c.read(settingsProvider.notifier).save(copySettings(defaultSettings, discordRpcEnabled: false));
      await pumpEventQueue();
      expect(client.calls.last, 'disconnect');
      expect(c.read(discordRpcProvider).connected, isFalse);

      await c.read(settingsProvider.notifier).save(copySettings(defaultSettings, discordAppId: () => '77'));
      await pumpEventQueue();
      expect(client.calls.last, 'connect 77');
      expect(client.activities, hasLength(2));
    });

    test('backend connection events gate sending and resend after reconnect', () async {
      client.fail = true;
      await start();
      expect(client.activities, isEmpty);
      client.connection.add(true);
      await pumpEventQueue();
      expect(client.activities, hasLength(1));
      client.connection.add(false);
      client.connection.add(true);
      await pumpEventQueue();
      expect(client.activities, hasLength(2));
    });

    test('a running project resolves its display name', () async {
      final c = await start(projects: [project(started: 1000)]);
      await pumpEventQueue();
      expect(rust.callCount('crateApiProjectsGetProjectName'), 1);
      expect(c.read(discordRpcProvider).activity, const DiscordActivity(details: 'Space Game', state: 'Godot 4.3', startTimestamp: 1000));
      expect(client.activities.last.details, 'Space Game');
    });

    test('an onboarding draft replaces settings and ignores projects', () async {
      final c = await start(projects: [project(started: 1000)]);
      c.read(discordRpcDraftProvider.notifier).set(copySettings(defaultSettings, discordRpcEnabled: false));
      await pumpEventQueue();
      expect(client.calls.last, 'disconnect');
      expect(c.read(discordRpcProvider).activity?.details, 'Using GodotHub');
      c.read(discordRpcDraftProvider.notifier).set(null);
      await pumpEventQueue();
      expect(client.calls.last, 'connect $defaultDiscordAppId');
      expect(c.read(discordRpcProvider).activity?.details, 'Space Game');
    });
  });
}
