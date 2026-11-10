import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef GhContextGetter = BuildContext? Function();

class GhPopupHandle {
  GhPopupHandle._(this._close, this._surface, this._origin, this._onEscape);

  final VoidCallback _close;
  final GhContextGetter? _surface;
  final GhContextGetter? _origin;
  final VoidCallback? _onEscape;
  bool _open = true;

  bool get isOpen => _open;

  void release() {
    if (!_open) {
      return;
    }
    _open = false;
    GhPopupRegistry._remove(this);
  }
}

class _OpenCount extends ChangeNotifier implements ValueListenable<int> {
  int _value = 0;
  bool _pending = false;

  @override
  int get value => _value;

  void _set(int next) {
    if (next == _value) {
      return;
    }
    _value = next;
    if (GhPopupRegistry._inBuild) {
      if (_pending) {
        return;
      }
      _pending = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _pending = false;
        notifyListeners();
      });
      return;
    }
    notifyListeners();
  }
}

abstract final class GhPopupRegistry {
  static final _OpenCount _count = _OpenCount();
  static final List<GhPopupHandle> _handles = [];
  static bool _keyboardAttached = false;

  static ValueListenable<int> get openMenuCount => _count;

  static bool get isMenuOpen => _count.value > 0;

  static bool get _inBuild {
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.midFrameMicrotasks;
  }

  static GhPopupHandle open({
    required VoidCallback close,
    GhContextGetter? surface,
    GhContextGetter? origin,
    VoidCallback? onEscape,
  }) {
    final handle = GhPopupHandle._(close, surface, origin ?? surface, onEscape);
    final originContext = handle._origin?.call();
    final others = List.of(_handles);
    _handles.add(handle);
    _sync();
    for (final other in others) {
      if (!other._open) {
        continue;
      }
      if (originContext != null && _contains(other._surface?.call(), originContext)) {
        continue;
      }
      _run(other._close);
    }
    return handle;
  }

  static void _remove(GhPopupHandle handle) {
    _handles.remove(handle);
    _sync();
  }

  static void _sync() {
    _count._set(_handles.length);
    final wantsKeyboard = _handles.any((h) => h._onEscape != null);
    if (wantsKeyboard && !_keyboardAttached) {
      HardwareKeyboard.instance.addHandler(_onKey);
      _keyboardAttached = true;
    } else if (!wantsKeyboard && _keyboardAttached) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      _keyboardAttached = false;
    }
  }

  static void _run(VoidCallback callback) {
    if (_inBuild) {
      SchedulerBinding.instance.addPostFrameCallback((_) => callback());
      return;
    }
    callback();
  }

  static bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    final targets = _handles.where((h) => h._onEscape != null).toList();
    if (targets.isEmpty) {
      return false;
    }
    scheduleMicrotask(() {
      for (final target in targets) {
        if (target._open) {
          target._onEscape!();
        }
      }
    });
    return false;
  }

  static bool _contains(BuildContext? surface, BuildContext origin) {
    if (surface == null || !surface.mounted || !origin.mounted) {
      return false;
    }
    if (identical(surface, origin)) {
      return true;
    }
    var found = false;
    origin.visitAncestorElements((element) {
      if (identical(element, surface)) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  @visibleForTesting
  static void debugReset() {
    for (final handle in List.of(_handles)) {
      handle._open = false;
    }
    _handles.clear();
    _sync();
  }
}
