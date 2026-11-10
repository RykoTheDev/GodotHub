import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/pending_save.dart';

void main() {
  setUp(() async => flushPendingSave());

  test('flushing with nothing registered completes', () async {
    await expectLater(flushPendingSave(), completes);
  });

  test('a registered save runs once on flush', () async {
    var runs = 0;
    registerPendingSave(() async => runs++);
    await flushPendingSave();
    await flushPendingSave();
    expect(runs, 1);
  });

  test('registering again replaces the previous save', () async {
    final runs = <String>[];
    registerPendingSave(() async => runs.add('first'));
    registerPendingSave(() async => runs.add('second'));
    await flushPendingSave();
    expect(runs, ['second']);
  });

  test('flush waits for the save to finish', () async {
    final gate = Completer<void>();
    var done = false;
    registerPendingSave(() => gate.future);
    final flushing = flushPendingSave().then((_) => done = true);
    await pumpEventQueue();
    expect(done, isFalse);
    gate.complete();
    await flushing;
    expect(done, isTrue);
  });

  test('the slot is cleared before the save runs so a new save can register', () async {
    final runs = <String>[];
    registerPendingSave(() async {
      runs.add('outer');
      registerPendingSave(() async => runs.add('inner'));
    });
    await flushPendingSave();
    expect(runs, ['outer']);
    await flushPendingSave();
    expect(runs, ['outer', 'inner']);
  });

  test('errors propagate and the slot stays cleared', () async {
    registerPendingSave(() async => throw StateError('disk full'));
    await expectLater(flushPendingSave(), throwsStateError);
    registerPendingSave(() => throw StateError('sync'));
    await expectLater(flushPendingSave(), throwsStateError);
    await expectLater(flushPendingSave(), completes);
  });
}
