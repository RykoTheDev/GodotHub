import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';
import 'news.dart';
import 'projects.dart';
import 'settings.dart';

const defaultDiscordAppId = '1538556630713638973';

const discordViewPresence = <String, ({String details, String state})>{
  'onboarding': (details: 'Setting up GodotHub', state: 'Getting everything just right...'),
  'dashboard': (details: 'in Dashboard', state: 'Checking in on those juicy stats'),
  'projects': (details: 'Browsing Projects', state: 'Deciding what to work on...'),
  'versions': (details: 'Browsing Versions', state: 'Deciding which one to install...'),
  'templates': (details: 'Browsing Templates', state: 'Looking to start with...'),
  'asset-store': (details: 'Browsing the Asset Store', state: 'Looking for something to use...'),
  'news': (details: 'Reading Godot News', state: 'Latest from the Godot itself'),
  'updates': (details: 'Reading Updates by Dev', state: 'What is bro yappin. about now?'),
  'changelog': (details: 'Checking the Changelog', state: "to see what's new..."),
  'settings': (details: 'Configuring Settings', state: 'Tweaking the app to my liking'),
};

const _fallbackPresence = (details: 'Using GodotHub', state: 'Managing my Projects');

@immutable
class DiscordActivity {
  const DiscordActivity({this.name = 'GodotHub', required this.details, required this.state, this.startTimestamp});

  final String name;
  final String details;
  final String state;
  final int? startTimestamp;

  Map<String, Object?> toJson() => {
    'name': name,
    'details': details,
    'state': state,
    if (startTimestamp != null) 'timestamps': {'start': startTimestamp},
  };

  String get key => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is DiscordActivity &&
      other.name == name &&
      other.details == details &&
      other.state == state &&
      other.startTimestamp == startTimestamp;

  @override
  int get hashCode => Object.hash(name, details, state, startTimestamp);

  @override
  String toString() => 'DiscordActivity($key)';
}

String discordAppIdOf(AppSettings settings) {
  final custom = settings.discordAppId?.trim() ?? '';
  return custom.isEmpty ? defaultDiscordAppId : custom;
}

Project? discordRunningProject(List<Project> projects) {
  Project? best;
  for (final project in projects) {
    final started = project.sessionStartedAtMs;
    if (started == null || started == BigInt.zero) continue;
    if (best == null || started > best.sessionStartedAtMs!) best = project;
  }
  return best;
}

String _folderName(String path) => path.split(RegExp(r'[\\/]')).last;

DiscordActivity buildDiscordActivity({required AppSettings settings, Project? running, String? resolvedName, String? view}) {
  if (running != null) {
    final start = running.sessionStartedAtMs?.toInt();
    final hidden = !settings.discordRpcShowProjects || settings.discordRpcExcludedProjects.contains(running.id);
    if (hidden) {
      return DiscordActivity(details: 'Working on a Top Secret Project', state: 'Please do not disturb', startTimestamp: start);
    }
    DiscordProjectPresence? custom;
    for (final presence in settings.discordRpcProjectPresences) {
      if (presence.id == running.id) {
        custom = presence;
        break;
      }
    }
    final storedIsFolderName = running.name == _folderName(running.path);
    final customDetails = custom?.details?.trim() ?? '';
    final customState = custom?.state?.trim() ?? '';
    final resolved = resolvedName ?? '';
    return DiscordActivity(
      details: customDetails.isNotEmpty ? customDetails : (storedIsFolderName && resolved.isNotEmpty ? resolved : running.name),
      state: customState.isNotEmpty
          ? customState
          : (running.godotVersion.isNotEmpty ? 'Godot ${running.godotVersion}' : 'Working on a Project'),
      startTimestamp: start,
    );
  }
  final preset = (view == null ? null : discordViewPresence[view]) ?? _fallbackPresence;
  return DiscordActivity(details: preset.details, state: preset.state);
}

abstract interface class DiscordRpcClient {
  Future<void> connect(String appId);

  Future<void> disconnect();

  Future<void> setActivity(DiscordActivity activity);

  Stream<bool> get connectionChanges;
}

class NoopDiscordRpcClient implements DiscordRpcClient {
  const NoopDiscordRpcClient();

  @override
  Future<void> connect(String appId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> setActivity(DiscordActivity activity) async {}

  @override
  Stream<bool> get connectionChanges => const Stream.empty();
}

final discordRpcClientProvider = Provider<DiscordRpcClient>((ref) => const NoopDiscordRpcClient());

final discordRpcDraftProvider = NotifierProvider<DiscordRpcDraftNotifier, AppSettings?>(DiscordRpcDraftNotifier.new);

class DiscordRpcDraftNotifier extends Notifier<AppSettings?> {
  @override
  AppSettings? build() => null;

  void set(AppSettings? draft) => state = draft;
}

final discordRpcSettingsProvider = Provider<AppSettings?>((ref) => ref.watch(discordRpcDraftProvider) ?? ref.watch(settingsProvider).value);

final discordRpcRunningProjectProvider = Provider<Project?>((ref) {
  if (ref.watch(discordRpcDraftProvider) != null) return null;
  return discordRunningProject(ref.watch(projectsProvider).data);
});

@immutable
class DiscordRpcState {
  const DiscordRpcState({this.connected = false, this.view, this.activity});

  final bool connected;
  final String? view;
  final DiscordActivity? activity;

  @override
  bool operator ==(Object other) =>
      other is DiscordRpcState && other.connected == connected && other.view == view && other.activity == activity;

  @override
  int get hashCode => Object.hash(connected, view, activity);
}

final discordRpcProvider = NotifierProvider<DiscordRpcNotifier, DiscordRpcState>(DiscordRpcNotifier.new);

class DiscordRpcNotifier extends Notifier<DiscordRpcState> {
  bool _connected = false;
  String? _view;
  String? _resolvedName;
  String? _sentKey;
  int _connectGeneration = 0;
  int _nameGeneration = 0;
  bool _ready = false;
  late DiscordRpcClient _client;

  @override
  DiscordRpcState build() {
    _ready = false;
    _client = ref.watch(discordRpcClientProvider);
    ref.listenSignal(viewChangedSignal, (signal) {
      final detail = signal.detail;
      if (detail is String) {
        _view = detail;
        _sync();
      }
    });
    final subscription = _client.connectionChanges.listen((connected) => _setConnected(connected));
    ref.onDispose(subscription.cancel);
    ref.listen<(bool, String)?>(
      discordRpcSettingsProvider.select((settings) => settings == null ? null : (settings.discordRpcEnabled, discordAppIdOf(settings))),
      (_, next) => _applyConnection(next),
      fireImmediately: true,
    );
    ref.listen<Project?>(discordRpcRunningProjectProvider, (previous, next) {
      if (previous?.id != next?.id || !_ready) _resolveName(next);
      _sync();
    }, fireImmediately: true);
    ref.listen<AppSettings?>(discordRpcSettingsProvider, (_, _) => _sync());
    final initial = _compute();
    _ready = true;
    return initial;
  }

  void _applyConnection((bool, String)? target) {
    if (target == null) return;
    final generation = ++_connectGeneration;
    final (enabled, appId) = target;
    if (!enabled || appId.isEmpty) {
      _setConnected(false);
      _client.disconnect().catchError((Object _) {});
      return;
    }
    _client.connect(appId).then((_) {
      if (generation == _connectGeneration && ref.mounted) _setConnected(true);
    }, onError: (Object _) {});
  }

  void _setConnected(bool connected) {
    _connected = connected;
    if (!connected) _sentKey = null;
    _sync();
  }

  void _resolveName(Project? running) {
    final generation = ++_nameGeneration;
    _resolvedName = null;
    if (running == null) return;
    ProjectsApi.getName(running.path).then((name) {
      if (generation != _nameGeneration || !ref.mounted) return;
      if (name != null && name.isNotEmpty) {
        _resolvedName = name;
        _sync();
      }
    }, onError: (Object _) {});
  }

  DiscordRpcState _compute() {
    final settings = ref.read(discordRpcSettingsProvider);
    if (settings == null) return DiscordRpcState(connected: _connected, view: _view);
    final activity = buildDiscordActivity(
      settings: settings,
      running: ref.read(discordRpcRunningProjectProvider),
      resolvedName: _resolvedName,
      view: _view,
    );
    return DiscordRpcState(connected: _connected, view: _view, activity: activity);
  }

  void _sync() {
    if (!_ready || !ref.mounted) return;
    final next = _compute();
    state = next;
    final activity = next.activity;
    if (!_connected || activity == null) return;
    final key = activity.key;
    if (key == _sentKey) return;
    _sentKey = key;
    _client.setActivity(activity).catchError((Object _) {});
  }
}
