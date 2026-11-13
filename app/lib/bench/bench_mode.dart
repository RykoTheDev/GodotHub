import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../projects/project_card.dart';
import '../projects/project_tile.dart';
import '../state/keyboard_shortcuts.dart';
import '../state/news.dart';
import '../state/projects.dart';
import '../state/app_signals.dart';

const benchMode = bool.fromEnvironment('GODOTHUB_BENCH');

int? _mainStartUs;

void benchMarkMain() => _mainStartUs ??= DateTime.now().microsecondsSinceEpoch;

String? benchDataDir() => benchMode ? Platform.environment['GODOTHUB_BENCH_DATA'] : null;

class BenchHost extends ConsumerStatefulWidget {
  const BenchHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BenchHost> createState() => _BenchHostState();
}

class _BenchHostState extends ConsumerState<BenchHost> {
  final _timings = <FrameTiming>[];
  int _lastFrameUs = 0;
  int _windowStart = 0;
  int _windowEnd = 0;

  String get _task => Platform.environment['GODOTHUB_BENCH_TASK'] ?? 'idle';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    SchedulerBinding.instance.addPersistentFrameCallback((_) => _lastFrameUs = Timeline.now);
    unawaited(_run());
  }

  void _onTimings(List<FrameTiming> timings) => _timings.addAll(timings);

  void _begin() {
    _timings.clear();
    _gapFrom = 0;
    _gapTo = 0;
    _windowStart = Timeline.now;
    _windowEnd = 1 << 62;
  }

  Future<void> _end() async {
    _windowEnd = Timeline.now;
    await _sleep(1200);
  }

  List<FrameTiming> get _window => [
    for (final t in _timings)
      if (t.timestampInMicroseconds(FramePhase.vsyncStart) >= _windowStart &&
          t.timestampInMicroseconds(FramePhase.vsyncStart) <= _windowEnd)
        t,
  ];

  int get _epochUs => DateTime.now().microsecondsSinceEpoch;

  Future<void> _frame() => SchedulerBinding.instance.endOfFrame;

  Future<void> _sleep(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  List<Element> _find(bool Function(Widget widget) test) {
    final out = <Element>[];
    void visit(Element element) {
      if (test(element.widget)) out.add(element);
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return out;
  }

  bool _visible(Element element) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    var hidden = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Offstage && widget.offstage) hidden = true;
      return !hidden;
    });
    return !hidden;
  }

  List<Element> _cards() => _find((w) => w is ProjectCard || w is ProjectTile).where(_visible).toList();

  Future<int> _waitReady() async {
    while (true) {
      final projects = ref.read(projectsProvider).data;
      if (projects.isNotEmpty && _cards().isNotEmpty) {
        await _frame();
        return _epochUs;
      }
      await _sleep(4);
    }
  }

  Future<int> _waitInteractive() async {
    var calm = 0;
    while (calm < 3) {
      final sw = Stopwatch()..start();
      await Future<void>.delayed(Duration.zero);
      calm = sw.elapsedMilliseconds < 16 ? calm + 1 : 0;
      await _sleep(4);
    }
    return _epochUs - 3 * 4000;
  }

  Future<void> _write(Map<String, Object?> data) async {
    final out = Platform.environment['GODOTHUB_BENCH_OUT'];
    if (out != null) await File(out).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<void> _run() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    final firstFrame = _epochUs;
    final ready = await _waitReady();
    final interactive = await _waitInteractive();
    final result = <String, Object?>{
      'task': _task,
      'mainStartUs': _mainStartUs,
      'firstFrameUs': firstFrame,
      'readyUs': ready,
      'interactiveUs': interactive,
      'cards': _cards().length,
    };
    switch (_task) {
      case 'views':
        await _sleep(6000);
        result['views'] = await _views();
      case 'scroll':
        await _sleep(6000);
        result['scroll'] = await _scroll();
      case 'drag':
        await _sleep(6000);
        result['drag'] = await _drag();
      case 'idle':
        return;
    }
    await _write(result);
    exit(0);
  }

  int _gapFrom = 0;
  int _gapTo = 0;

  List<double> _vsyncDeltas() {
    final starts = _window.map((t) => t.timestampInMicroseconds(FramePhase.vsyncStart)).toList()..sort();
    return [
      for (var i = 1; i < starts.length; i++)
        if (!(starts[i - 1] <= _gapTo && starts[i] >= _gapFrom)) (starts[i] - starts[i - 1]) / 1000,
    ];
  }

  Map<String, Object?> _frameDetail() => {
    'vsyncDeltasMs': _vsyncDeltas(),
    'buildMs': [for (final t in _window) t.buildDuration.inMicroseconds / 1000],
    'rasterMs': [for (final t in _window) t.rasterDuration.inMicroseconds / 1000],
    'totalMs': [for (final t in _window) t.totalSpan.inMicroseconds / 1000],
  };

  Future<Map<String, Object?>> _switchTo(String view) async {
    final t0 = Timeline.now;
    _lastFrameUs = t0;
    AppSignals.emit(setTabSignal, view);
    while (ref.read(currentViewProvider) != view) {
      await _frame();
    }
    await _frame();
    final content = (Timeline.now - t0) / 1000;
    while ((Timeline.now - _lastFrameUs) < 250000 && (Timeline.now - t0) < 5000000) {
      await _sleep(20);
    }
    return {'view': view, 'contentMs': content, 'settledMs': (_lastFrameUs - t0) / 1000};
  }

  Future<Map<String, Object?>> _views() async {
    final first = <Map<String, Object?>>[];
    for (final v in ['versions', 'settings', 'projects']) {
      first.add(await _switchTo(v));
      await _sleep(1500);
    }
    final warm = <Map<String, Object?>>[];
    for (var i = 0; i < 5; i++) {
      for (final v in ['versions', 'settings', 'projects']) {
        warm.add(await _switchTo(v));
        await _sleep(1000);
      }
    }
    return {'first': first, 'warm': warm};
  }

  ScrollPosition? _projectScroller() {
    final cards = _cards();
    if (cards.isEmpty) return null;
    final state = Scrollable.maybeOf(cards.first);
    return state?.position;
  }

  Future<List<Map<String, Object?>>> _scroll() async {
    final position = _projectScroller();
    if (position == null) return [];
    final runs = <Map<String, Object?>>[];
    position.jumpTo(0);
    await _sleep(500);
    for (var pass = 0; pass < 3; pass++) {
      for (final down in [true, false]) {
        final from = position.pixels;
        final to = down ? position.maxScrollExtent : 0.0;
        final distance = (to - from).abs() + 200;
        final duration = distance / 1500;
        _begin();
        final done = Completer<void>();
        late final Ticker ticker;
        ticker = Ticker((elapsed) {
          final t = elapsed.inMicroseconds / 1e6;
          final travelled = (t * 1500).clamp(0, distance);
          final target = down ? from + travelled : from - travelled;
          position.jumpTo(target.clamp(0.0, position.maxScrollExtent).toDouble());
          if (t >= duration) {
            ticker.dispose();
            done.complete();
          }
        })..start();
        await done.future;
        await _frame();
        await _end();
        runs.add({
          'direction': down ? 'down' : 'up',
          'extent': position.maxScrollExtent,
          'pixelsAfter': position.pixels,
          ..._frameDetail(),
        });
      }
    }
    return runs;
  }

  Future<List<Map<String, Object?>>> _drag() async {
    final runs = <Map<String, Object?>>[];
    final binding = GestureBinding.instance;
    final clock = Stopwatch()..start();
    for (var pass = 0; pass < 3; pass++) {
      _projectScroller()?.jumpTo(0);
      await _sleep(800);
      final cards = _cards();
      if (cards.length < 2) return runs;
      Offset pick(Element e) {
        final box = e.renderObject! as RenderBox;
        return box.localToGlobal(Offset(box.size.width * 0.3, box.size.height * 0.5));
      }

      final from = pick(cards[1]);
      final pitch = pick(cards[1]).dy - pick(cards[0]).dy;
      final to = from + Offset(0, pitch * 6);
      Duration stamp() => clock.elapsed;
      binding.handlePointerEvent(PointerHoverEvent(position: from, timeStamp: stamp()));
      _begin();
      binding.handlePointerEvent(PointerDownEvent(pointer: 900 + pass, position: from, buttons: kPrimaryMouseButton, timeStamp: stamp()));
      Offset at(int k) => Offset.lerp(from, to, k / 60)!;
      var last = from;
      for (var k = 1; k <= 60; k++) {
        final p = at(k);
        binding.handlePointerEvent(
          PointerMoveEvent(pointer: 900 + pass, position: p, delta: p - last, buttons: kPrimaryMouseButton, timeStamp: stamp()),
        );
        last = p;
        await _sleep(16);
      }
      final holdStart = Timeline.now;
      await _sleep(400);
      final holdEnd = Timeline.now;
      _gapFrom = holdStart;
      _gapTo = holdEnd;
      for (var k = 59; k >= 0; k--) {
        final p = at(k);
        binding.handlePointerEvent(
          PointerMoveEvent(pointer: 900 + pass, position: p, delta: p - last, buttons: kPrimaryMouseButton, timeStamp: stamp()),
        );
        last = p;
        await _sleep(16);
      }
      binding.handlePointerEvent(PointerUpEvent(pointer: 900 + pass, position: from, timeStamp: stamp()));
      await _frame();
      await _end();
      final detail = _frameDetail();
      runs.add({...detail, 'holdMs': (holdEnd - holdStart) / 1000});
      await _sleep(1000);
    }
    return runs;
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
