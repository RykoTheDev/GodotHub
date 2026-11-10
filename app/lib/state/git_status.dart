import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/git.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';
import 'app_lifecycle.dart';

const String refreshGitStatusSignal = 'app:refresh-git-status';
const Duration gitStatusPollInterval = Duration(milliseconds: 30000);
const Duration gitStatusFreshFor = Duration(milliseconds: 5000);
const Duration gitStatusRefreshDebounce = Duration(milliseconds: 300);

@immutable
class GitStatusStoreState {
  const GitStatusStoreState({this.statusMap = const {}, this.fetches = 0});

  final Map<String, GitStatus> statusMap;
  final int fetches;
}

final gitStatusStoreProvider = NotifierProvider<GitStatusStore, GitStatusStoreState>(GitStatusStore.new);

class GitStatusStore extends Notifier<GitStatusStoreState> {
  final Map<Object, List<String>> _activePaths = {};
  int _lastFetchedAt = 0;
  String _lastFetchedKey = '';
  Future<void>? _inFlight;
  Future<void>? _queuedForced;
  Timer? _pollTimer;
  Timer? _debounceTimer;

  bool get hasFetched => _lastFetchedAt != 0;

  Map<String, GitStatus> get statusMap => state.statusMap;

  @override
  GitStatusStoreState build() {
    ref.listenSignal(refreshGitStatusSignal, (_) {
      if (_pollTimer == null) return;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(gitStatusRefreshDebounce, () => unawaited(refresh(true)));
    });
    ref.listenAppResumed(() {
      if (_pollTimer != null) unawaited(refresh(false));
    });
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
      _debounceTimer?.cancel();
    });
    return const GitStatusStoreState();
  }

  void register(Object id, List<String> paths) {
    _activePaths[id] = paths;
    _pollTimer ??= Timer.periodic(gitStatusPollInterval, (_) {
      if (!ghAppHidden()) unawaited(refresh(true));
    });
  }

  void unregister(Object id) {
    _activePaths.remove(id);
    if (_pollTimer == null || _activePaths.isNotEmpty) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
  }

  List<String> _wantedPaths() => ({for (final paths in _activePaths.values) ...paths}.toList()..sort());

  Map<String, GitStatus> _merge(Map<String, GitStatus> next) {
    final current = state.statusMap;
    final merged = <String, GitStatus>{};
    var changed = next.length != current.length;
    for (final entry in next.entries) {
      final previous = current[entry.key];
      final same = previous != null && previous == entry.value;
      merged[entry.key] = same ? previous : entry.value;
      if (!same) changed = true;
    }
    return changed ? merged : current;
  }

  Future<void> refresh(bool force) {
    final inFlight = _inFlight;
    if (inFlight != null) {
      if (!force) return inFlight;
      return _queuedForced ??= inFlight.then((_) {
        _queuedForced = null;
        return refresh(true);
      });
    }
    final paths = _wantedPaths();
    if (paths.isEmpty) return Future<void>.value();
    final key = paths.join('|');
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && key == _lastFetchedKey && now - _lastFetchedAt < gitStatusFreshFor.inMilliseconds) {
      return Future<void>.value();
    }
    final request = Future<Map<String, GitStatus>>.sync(() => GitApi.batchStatus(paths))
        .then<void>((statuses) {
          if (!ref.mounted) return;
          final merged = _merge(statuses);
          _lastFetchedAt = DateTime.now().millisecondsSinceEpoch;
          _lastFetchedKey = key;
          state = GitStatusStoreState(statusMap: merged, fetches: state.fetches + 1);
        })
        .catchError((Object _) {})
        .whenComplete(() => _inFlight = null);
    _inFlight = request;
    return request;
  }
}

@immutable
class GitStatusMapView {
  const GitStatusMapView({required this.statusMap, required this.loading});

  final Map<String, GitStatus> statusMap;
  final bool loading;

  @override
  bool operator ==(Object other) =>
      other is GitStatusMapView && identical(other.statusMap, statusMap) && other.loading == loading;

  @override
  int get hashCode => Object.hash(identityHashCode(statusMap), loading);
}

typedef GitStatusRequest = ({String pathsKey, bool active});

GitStatusRequest gitStatusRequest(List<String> paths, bool active) => (pathsKey: paths.join('|'), active: active);

final gitStatusMapProvider = NotifierProvider.autoDispose
    .family<GitStatusMapNotifier, GitStatusMapView, GitStatusRequest>(GitStatusMapNotifier.new);

class GitStatusMapNotifier extends Notifier<GitStatusMapView> {
  GitStatusMapNotifier(this.request);

  final GitStatusRequest request;

  @override
  GitStatusMapView build() {
    final store = ref.read(gitStatusStoreProvider.notifier);
    ref.listen(gitStatusStoreProvider, (_, next) {
      state = GitStatusMapView(statusMap: next.statusMap, loading: false);
    });
    var loading = !store.hasFetched;
    if (!request.active) return GitStatusMapView(statusMap: store.statusMap, loading: loading);
    final list = request.pathsKey.isEmpty ? const <String>[] : request.pathsKey.split('|');
    if (list.isEmpty) return GitStatusMapView(statusMap: store.statusMap, loading: false);
    final id = Object();
    store.register(id, list);
    ref.onDispose(() => store.unregister(id));
    final current = store.statusMap;
    if (list.any((path) => !current.containsKey(path))) loading = true;
    unawaited(
      store.refresh(false).whenComplete(() {
        if (ref.mounted && state.loading) state = GitStatusMapView(statusMap: state.statusMap, loading: false);
      }),
    );
    return GitStatusMapView(statusMap: current, loading: loading);
  }
}
