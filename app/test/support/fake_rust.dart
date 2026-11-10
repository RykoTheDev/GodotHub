import 'dart:async';

import 'package:godothub/api/events.dart';
import 'package:godothub/src/rust/frb_generated.dart';
import 'package:godothub/state/app_signals.dart';

class FakeRustApi implements RustLibApi {
  final Map<String, Function> _handlers = {};
  final Map<String, int> calls = {};
  StreamController<AppEvent> _events = StreamController<AppEvent>.broadcast();

  void on(String method, Function handler) => _handlers[method] = handler;

  int callCount(String method) => calls[method] ?? 0;

  void emit(AppEvent event) => _events.add(event);

  void reset() {
    _handlers.clear();
    calls.clear();
    _events.close();
    _events = StreamController<AppEvent>.broadcast();
    AppEvents.debugReset();
    AppSignals.debugReset();
  }

  @override
  Stream<AppEvent> crateApiEventsAppEvents() => _events.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final raw = invocation.memberName.toString();
    final name = raw.substring(raw.indexOf('"') + 1, raw.lastIndexOf('"'));
    calls[name] = (calls[name] ?? 0) + 1;
    final handler = _handlers[name];
    if (handler == null) {
      throw UnimplementedError('FakeRustApi: no handler for $name');
    }
    return Function.apply(handler, invocation.positionalArguments, invocation.namedArguments);
  }
}

FakeRustApi? _instance;

FakeRustApi installFakeRust() {
  final existing = _instance;
  if (existing != null) {
    existing.reset();
    return existing;
  }
  final fake = FakeRustApi();
  RustLib.initMock(api: fake);
  _instance = fake;
  AppEvents.debugReset();
  AppSignals.debugReset();
  return fake;
}

AppEvent fakeEvent(AppEventKind kind, {String name = '', String json = 'null', ScanProgress? scanProgress, String? text}) {
  return AppEvent(kind: kind, name: name, json: json, scanProgress: scanProgress, text: text);
}
