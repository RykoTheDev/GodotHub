import 'dart:async';

import 'package:flutter/foundation.dart';

import 'strings.dart';

enum GhToastType { success, error, info }

@immutable
class GhToastAction {
  const GhToastAction({required this.label, required this.onClick});

  final String label;
  final VoidCallback onClick;
}

@immutable
class GhToastItem {
  const GhToastItem({required this.id, required this.type, required this.message, this.action});

  final int id;
  final GhToastType type;
  final String message;
  final GhToastAction? action;
}

typedef GhToastListener = void Function(List<GhToastItem> toasts);

class GhToastStore {
  static const defaultTtlMs = 4000;
  static const errorTtlMs = 6000;

  int _nextId = 1;
  List<GhToastItem> _toasts = const [];
  final Set<GhToastListener> _listeners = {};
  final Map<int, Timer> _timers = {};

  List<GhToastItem> get toasts => _toasts;

  void _emit() {
    for (final listener in _listeners.toList()) {
      listener(_toasts);
    }
  }

  int pushToast(GhToastType type, String message, {int ttlMs = defaultTtlMs, GhToastAction? action}) {
    final id = _nextId++;
    _toasts = [..._toasts, GhToastItem(id: id, type: type, message: message, action: action)];
    _emit();
    _timers[id] = Timer(Duration(milliseconds: ttlMs), () {
      _timers.remove(id);
      _toasts = _toasts.where((t) => t.id != id).toList();
      _emit();
    });
    return id;
  }

  void reportError(Object? error) {
    debugPrint('$error');
    final message = switch (error) {
      String value => value,
      Exception() || Error() => _errorMessage(error),
      _ => '',
    };
    pushToast(GhToastType.error, message.isNotEmpty ? message : GhFeedbackStrings.somethingWentWrong, ttlMs: errorTtlMs);
  }

  String _errorMessage(Object? error) {
    final text = error.toString();
    const prefix = 'Exception: ';
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }

  void dismissToast(int id) {
    _timers.remove(id)?.cancel();
    _toasts = _toasts.where((t) => t.id != id).toList();
    _emit();
  }

  VoidCallback subscribe(GhToastListener listener) {
    _listeners.add(listener);
    listener(_toasts);
    return () => _listeners.remove(listener);
  }

  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _toasts = const [];
    _emit();
  }
}

final GhToastStore ghToasts = GhToastStore();

int pushToast(GhToastType type, String message, {int ttlMs = GhToastStore.defaultTtlMs, GhToastAction? action}) =>
    ghToasts.pushToast(type, message, ttlMs: ttlMs, action: action);

void reportError(Object? error) => ghToasts.reportError(error);

void dismissToast(int id) => ghToasts.dismissToast(id);

VoidCallback subscribeToasts(GhToastListener listener) => ghToasts.subscribe(listener);
