import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'rust/api/dto.dart' as dto;
import 'rust/api/ui_prefs.dart' as prefs_api;

abstract interface class UiPrefsBackend {
  Future<Map<String, String>> load();
  Future<void> set(String key, String json);
  Future<void> remove(String key);
}

class BridgeUiPrefsBackend implements UiPrefsBackend {
  const BridgeUiPrefsBackend();

  @override
  Future<Map<String, String>> load() async => (await dto.getUiPrefs()).values;

  @override
  Future<void> set(String key, String json) => dto.setUiPref(key: key, value: json);

  @override
  Future<void> remove(String key) => prefs_api.removeUiPref(key: key);
}

class MemoryUiPrefsBackend implements UiPrefsBackend {
  MemoryUiPrefsBackend([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<Map<String, String>> load() async => Map.of(values);

  @override
  Future<void> set(String key, String json) async => values[key] = json;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

class UiPrefsStore {
  UiPrefsStore([UiPrefsBackend? backend]) : _backend = backend ?? const BridgeUiPrefsBackend();

  static UiPrefsStore instance = UiPrefsStore();

  final UiPrefsBackend _backend;
  final Map<String, String> _cache = {};
  Future<void> _pending = Future.value();

  Future<void> load() async {
    try {
      fill(await _backend.load());
    } catch (error) {
      debugPrint('Failed to load UI preferences: $error');
      _cache.clear();
    }
  }

  void fill(Map<String, String> rawJsonValues) {
    _cache.clear();
    for (final entry in rawJsonValues.entries) {
      final Object? value;
      try {
        value = jsonDecode(entry.value);
      } catch (_) {
        continue;
      }
      if (value == null) continue;
      _cache[entry.key] = value is String ? value : jsonEncode(value);
    }
  }

  String? getItem(String key) => _cache[key];

  void setItem(String key, String value) {
    if (_cache[key] == value) return;
    _cache[key] = value;
    _persist(() => _backend.set(key, jsonEncode(value)), 'set_ui_pref');
  }

  void removeItem(String key) {
    if (!_cache.containsKey(key)) return;
    _cache.remove(key);
    _persist(() => _backend.remove(key), 'remove_ui_pref');
  }

  Future<void> flush() => _pending;

  void _persist(Future<void> Function() write, String command) {
    _pending = _pending.then((_) => write()).catchError((Object error) {
      debugPrint('Failed to save UI preference ($command): $error');
    });
  }
}
