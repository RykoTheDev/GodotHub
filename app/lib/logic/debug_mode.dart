import 'package:flutter/foundation.dart';

import '../src/ui_prefs.dart';
import '../ui/feedback/toast.dart';

const String debugUnlockedStorageKey = 'godothub_debug_unlocked';
const int clicksToUnlock = 5;
const Duration clickWindow = Duration(milliseconds: 2000);

class GhSettingsClickCounter {
  GhSettingsClickCounter({this.clicksToUnlock = 5, this.window = clickWindow});

  final int clicksToUnlock;
  final Duration window;
  List<int> _clicks = [];

  bool register([DateTime? now]) {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final windowMs = window.inMilliseconds;
    _clicks = [..._clicks.where((t) => at - t < windowMs), at];
    if (_clicks.length >= clicksToUnlock) {
      _clicks = [];
      return true;
    }
    return false;
  }

  void reset() => _clicks = [];
}

bool _readUnlocked() {
  try {
    return UiPrefsStore.instance.getItem(debugUnlockedStorageKey) == '1';
  } catch (_) {
    return false;
  }
}

class _DebugUnlocked extends ChangeNotifier implements ValueListenable<bool> {
  bool? _value;

  @override
  bool get value => _value ??= _readUnlocked();

  void assign(bool next) => _value = next;

  void notify() => notifyListeners();
}

final _DebugUnlocked _unlocked = _DebugUnlocked();
final GhSettingsClickCounter _counter = GhSettingsClickCounter(clicksToUnlock: clicksToUnlock);

ValueListenable<bool> get debugUnlocked => _unlocked;

bool get isDebugUnlocked => _unlocked.value;

void setDebugUnlocked(bool value) {
  _unlocked.assign(value);
  try {
    if (value) {
      UiPrefsStore.instance.setItem(debugUnlockedStorageKey, '1');
    } else {
      UiPrefsStore.instance.removeItem(debugUnlockedStorageKey);
    }
  } catch (_) {}
  _unlocked.notify();
}

void registerSettingsClick([DateTime? now]) {
  if (_unlocked.value) return;
  if (_counter.register(now)) {
    setDebugUnlocked(true);
    pushToast(GhToastType.info, 'Debug settings unlocked');
  }
}

@visibleForTesting
void debugResetDebugMode() {
  _unlocked._value = null;
  _counter.reset();
}
