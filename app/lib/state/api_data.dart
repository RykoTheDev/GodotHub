import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import 'app_signals.dart';

@immutable
class ApiData<T> {
  const ApiData({required this.data, this.loaded = false, this.loading = true, this.error});

  final T data;
  final bool loaded;
  final bool loading;
  final String? error;

  ApiData<T> copyWith({T? data, bool? loaded, bool? loading, String? error, bool clearError = false}) {
    return ApiData<T>(
      data: data ?? this.data,
      loaded: loaded ?? this.loaded,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ApiData<T> && other.data == data && other.loaded == loaded && other.loading == loading && other.error == error;

  @override
  int get hashCode => Object.hash(data, loaded, loading, error);
}

abstract class ApiDataNotifier<T> extends Notifier<ApiData<T>> {
  T get initial;

  bool get keepsError => false;

  Future<T> fetch();

  void setup() {}

  int _generation = 0;

  @override
  ApiData<T> build() {
    setup();
    final generation = ++_generation;
    scheduleMicrotask(() {
      if (generation == _generation) {
        refresh();
      }
    });
    final previous = stateOrNull;
    return previous == null ? ApiData<T>(data: initial) : previous.copyWith(loading: true);
  }

  Future<void> refresh() async {
    final generation = _generation;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await fetch();
      if (generation != _generation || !ref.mounted) return;
      state = ApiData<T>(data: data, loaded: true, loading: false);
    } catch (error) {
      if (generation != _generation || !ref.mounted) return;
      state = ApiData<T>(data: initial, loaded: true, loading: false, error: keepsError ? '$error' : null);
    }
  }

  void setData(T Function(T previous) update) => state = state.copyWith(data: update(state.data));
}

extension GhRefEvents on Ref {
  void listenAppEvent(AppEventKind kind, void Function(AppEvent event) handler) {
    final subscription = AppEvents.of(kind).listen(handler);
    onDispose(subscription.cancel);
  }

  void listenAppEvents(Set<AppEventKind> kinds, void Function(AppEvent event) handler) {
    final subscription = AppEvents.ofAny(kinds).listen(handler);
    onDispose(subscription.cancel);
  }

  void listenSignal(String name, void Function(AppSignal signal) handler) {
    final subscription = AppSignals.on(name).listen(handler);
    onDispose(subscription.cancel);
  }
}
