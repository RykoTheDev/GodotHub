import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef GhTickListener = void Function(int now);

class GhSharedTicker extends ChangeNotifier implements ValueListenable<int> {
  GhSharedTicker._();

  static final GhSharedTicker instance = GhSharedTicker._();

  static const interval = Duration(milliseconds: 1000);

  final Set<GhTickListener> _subscribers = {};
  int _listenerCount = 0;
  Timer? _timer;
  int _current = DateTime.now().millisecondsSinceEpoch;

  int get currentTick => _current;

  @override
  int get value => _current;

  bool get running => _timer != null;

  int get subscriberCount => _subscribers.length + _listenerCount;

  VoidCallback subscribe(GhTickListener listener) {
    _subscribers.add(listener);
    _start();
    var active = true;
    return () {
      if (!active) {
        return;
      }
      active = false;
      _subscribers.remove(listener);
      _stop();
    };
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _listenerCount += 1;
    _start();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_listenerCount > 0) {
      _listenerCount -= 1;
    }
    _stop();
  }

  void _start() {
    if (_timer != null || subscriberCount == 0) {
      return;
    }
    _current = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(interval, (_) {
      _current = DateTime.now().millisecondsSinceEpoch;
      for (final listener in _subscribers.toList()) {
        listener(_current);
      }
      notifyListeners();
    });
  }

  void _stop() {
    if (_timer != null && subscriberCount == 0) {
      _timer!.cancel();
      _timer = null;
    }
  }
}

class GhNow extends StatefulWidget {
  const GhNow({super.key, this.active = true, required this.builder});

  final bool active;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<GhNow> createState() => _GhNowState();
}

class _GhNowState extends State<GhNow> {
  late int _now = DateTime.now().millisecondsSinceEpoch;
  VoidCallback? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(GhNow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _sync();
    }
  }

  void _sync() {
    _unsubscribe?.call();
    _unsubscribe = null;
    if (!widget.active) {
      return;
    }
    _now = GhSharedTicker.instance.currentTick;
    _unsubscribe = GhSharedTicker.instance.subscribe((now) {
      if (mounted) {
        setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.fromMillisecondsSinceEpoch(_now));
}
