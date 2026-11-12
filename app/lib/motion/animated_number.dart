import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'ease.dart';
import 'motion.dart';

abstract final class GhNumberFlowTiming {
  static const transform = Duration(milliseconds: 900);
  static const opacity = Duration(milliseconds: 450);

  static const transformEasing =
      'linear(0,.005,.019,.039,.066,.096,.129,.165,.202,.24,.278,.316,.354,.39,.426,.461,.494,.526,.557,.586,.614,.64,.665,.689,.711,.731,.751,.769,.786,.802,.817,.831,.844,.856,.867,.877,.887,.896,.904,.912,.919,.925,.931,.937,.942,.947,.951,.955,.959,.962,.965,.968,.971,.973,.976,.978,.98,.981,.983,.984,.986,.987,.988,.989,.99,.991,.992,.992,.993,.994,.994,.995,.995,.996,.996,.9963,.9967,.9969,.9972,.9975,.9977,.9979,.9981,.9982,.9984,.9985,.9987,.9988,.9989,1)';

  static final List<double> transformPoints = List.unmodifiable(
    transformEasing.substring(7, transformEasing.length - 1).split(',').map(double.parse),
  );

  static final transformEase = CssLinearEase(transformPoints);
  static const opacityEase = GhEase.cssEaseOut;

  static double get _transformSeconds => transform.inMicroseconds / 1e6;
}

class GhAnimatedNumber extends StatelessWidget {
  const GhAnimatedNumber(this.value, {super.key, this.style, this.locale});

  final num value;
  final TextStyle? style;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final motion = GhMotion.of(context);
    if (!motion.prefs.animatedNumbers || motion.prefs.intensity == GhMotionIntensity.none) {
      return Text(ghPlainNumber(value), style: style);
    }
    return _NumberFlow(value: value, style: style, locale: locale, animate: motion.numbersOn);
  }
}

String ghPlainNumber(num value) {
  if (value is double) {
    if (value.isNaN) {
      return 'NaN';
    }
    if (value.isInfinite) {
      return value > 0 ? 'Infinity' : '-Infinity';
    }
    if (value == value.truncateToDouble() && value.abs() < 1e21) {
      return value.toInt().toString();
    }
  }
  return value.toString();
}

String ghFormatNumber(num value, {String? locale}) => _formatParts(value, _Separators.of(locale)).map((p) => p.$2).join();

@immutable
class _Separators {
  const _Separators(this.group, this.decimal, {this.minimumGrouping = 1});

  final String group;
  final String decimal;
  final int minimumGrouping;

  static const _comma = _Separators(',', '.');
  static const _dot = _Separators('.', ',');
  static const _space = _Separators(' ', ',');

  static _Separators of(String? locale) {
    if (locale == null || locale.isEmpty) {
      return _comma;
    }
    final tag = locale.replaceAll('_', '-').toLowerCase();
    switch (tag) {
      case 'es-mx' || 'es-us' || 'es-419':
        return _comma;
      case 'pt-pt':
        return const _Separators(' ', ',', minimumGrouping: 2);
      case 'ar-ma' || 'ar-dz' || 'ar-tn' || 'ar-ly':
        return _dot;
      case 'de-ch':
        return const _Separators('’', '.');
    }
    return switch (tag.split('-').first) {
      'de' || 'id' || 'it' || 'nl' || 'pt' || 'tr' || 'vi' || 'da' || 'el' || 'ro' || 'hr' || 'sl' => _dot,
      'es' => const _Separators('.', ',', minimumGrouping: 2),
      'pl' => const _Separators(' ', ',', minimumGrouping: 2),
      'fr' => const _Separators(' ', ','),
      'ru' || 'uk' || 'cs' || 'sk' || 'fi' || 'sv' || 'nb' || 'no' || 'hu' || 'bg' || 'lt' || 'lv' || 'et' => _space,
      _ => _comma,
    };
  }
}

List<(String, String)> _formatParts(num value, _Separators separators) {
  if (value.isNaN) {
    return const [('nan', 'NaN')];
  }
  final parts = <(String, String)>[];
  if (value.isNegative) {
    parts.add(('minusSign', '-'));
  }
  if (value.isInfinite) {
    return parts..add(('infinity', '∞'));
  }
  final magnitude = value.abs();
  String whole;
  var fraction = '';
  if (magnitude is int) {
    whole = magnitude.toString();
  } else {
    final fixed = magnitude.toDouble().toStringAsFixed(3);
    final dot = fixed.indexOf('.');
    whole = dot < 0 ? fixed : fixed.substring(0, dot);
    fraction = dot < 0 ? '' : fixed.substring(dot + 1).replaceFirst(RegExp(r'0+$'), '');
  }
  if (whole.length >= 3 + separators.minimumGrouping) {
    final head = whole.length % 3 == 0 ? 3 : whole.length % 3;
    parts.add(('integer', whole.substring(0, head)));
    for (var i = head; i < whole.length; i += 3) {
      parts
        ..add(('group', separators.group))
        ..add(('integer', whole.substring(i, i + 3)));
    }
  } else {
    parts.add(('integer', whole));
  }
  if (fraction.isNotEmpty) {
    parts
      ..add(('decimal', separators.decimal))
      ..add(('fraction', fraction));
  }
  return parts;
}

@immutable
class _Part {
  const _Part.digit(this.type, this.key, this.digit, this.pos) : symbol = '';

  const _Part.symbol(this.type, this.key, this.symbol) : digit = 0, pos = 0;

  final String type;
  final String key;
  final int digit;
  final String symbol;
  final int pos;

  bool get isDigit => type == 'integer' || type == 'fraction';
}

@immutable
class _Data {
  const _Data(this.pre, this.integer, this.fraction, this.post, this.text, this.value);

  final List<_Part> pre;
  final List<_Part> integer;
  final List<_Part> fraction;
  final List<_Part> post;
  final String text;
  final double value;
}

_Data _toData(num value, String? locale) {
  final parts = _formatParts(value, _Separators.of(locale));
  final counts = <String, int>{};
  int bump(String type) => counts[type] = (counts[type] ?? -1) + 1;
  final pre = <_Part>[];
  final fraction = <_Part>[];
  final post = <_Part>[];
  final raw = <(String, String)>[];
  final text = StringBuffer();
  var seenInteger = false;
  var seenDecimal = false;
  for (final (kind, part) in parts) {
    text.write(part);
    final type = kind == 'minusSign' || kind == 'plusSign' ? 'sign' : kind;
    switch (type) {
      case 'integer':
        seenInteger = true;
        for (final ch in part.split('')) {
          raw.add(('integer', ch));
        }
      case 'group':
        raw.add(('group', part));
      case 'decimal':
        seenDecimal = true;
        fraction.add(_Part.symbol(type, '$type:${bump(type)}', part));
      case 'fraction':
        for (final ch in part.split('')) {
          final n = bump(type);
          fraction.add(_Part.digit(type, '$type:$n', int.parse(ch), -1 - n));
        }
      default:
        (seenInteger || seenDecimal ? post : pre).add(_Part.symbol(type, '$type:${bump(type)}', part));
    }
  }
  final integer = <_Part>[];
  for (var i = raw.length - 1; i >= 0; i--) {
    final (type, ch) = raw[i];
    final n = bump(type);
    integer.insert(0, type == 'integer' ? _Part.digit(type, '$type:$n', int.parse(ch), n) : _Part.symbol(type, '$type:$n', ch));
  }
  return _Data(pre, integer, fraction, post, text.toString(), value.toDouble());
}

class _Anim {
  _Anim(this.from, this.start, this.duration, this.curve);

  final double from;
  final double start;
  final double duration;
  final Curve curve;

  double get end => start + duration;

  double at(double now) {
    final p = duration <= 0 ? 1.0 : ((now - start) / duration).clamp(0.0, 1.0);
    return from * (1 - curve.transform(p));
  }
}

class _Track {
  final List<_Anim> anims = [];
  double base = 0;

  void add(double from, double now, Duration duration, Curve curve) {
    anims.add(_Anim(from, now, duration.inMicroseconds / 1e6, curve));
  }

  double value(double now) {
    var v = base;
    for (final a in anims) {
      if (now < a.end) {
        v += a.at(now);
      }
    }
    return v;
  }

  bool activeAt(double now) => anims.any((a) => now < a.end);

  void clear() => anims.clear();
}

class _SymbolValue {
  _SymbolValue(this.text);

  final String text;
  bool present = true;
  final presence = _Track();
}

class _Char {
  _Char.digit(this.key, this.type, this.digit, this.pos) : isDigit = true, text = '';

  _Char.symbol(this.key, this.type, this.text) : isDigit = false, digit = 0, pos = 0 {
    values.add(_SymbolValue(text));
  }

  final String key;
  final String type;
  final bool isDigit;
  int digit;
  int pos;
  String text;
  final List<_SymbolValue> values = [];
  bool present = true;
  double? popped;
  final shift = _Track();
  final presence = _Track();
  final spin = _Track();
  double prevPos = 0;
  int prevDigit = 0;

  String get glyph => isDigit ? '$digit' : text;

  _SymbolValue? valueFor(String text) {
    for (final v in values) {
      if (v.text == text) {
        return v;
      }
    }
    return null;
  }

  int delta(int trend) {
    const length = 10;
    final t = digit - prevDigit;
    final e = trend != 0 ? trend : t.sign;
    if (e < 0 && digit > prevDigit) {
      return digit - length - prevDigit;
    }
    if (e > 0 && digit < prevDigit) {
      return length - prevDigit + digit;
    }
    return t;
  }
}

class _Section {
  _Section(this.flow, {required this.right});

  final _Flow flow;
  final bool right;
  final Map<String, _Char> children = {};
  List<_Char> dom = [];
  final shift = _Track();
  double prevEdge = 0;

  double widthOf(_Char c) => flow.glyphs.width(c.glyph);

  double get width {
    var w = 0.0;
    for (final c in dom) {
      if (c.popped == null) {
        w += widthOf(c);
      }
    }
    return w;
  }

  Map<_Char, double> flowOffsets() {
    final result = <_Char, double>{};
    var acc = 0.0;
    for (final c in right ? dom.reversed : dom) {
      if (c.popped != null) {
        continue;
      }
      result[c] = acc;
      acc += widthOf(c);
    }
    return result;
  }

  double pos(_Char c, Map<_Char, double> offsets) {
    final w = widthOf(c);
    final edge = c.popped ?? offsets[c] ?? 0;
    if (right) {
      return c.isDigit ? -edge - w / 2 : -edge;
    }
    return c.isDigit ? edge + w / 2 : edge;
  }

  void init(List<_Part> parts) {
    for (final p in parts) {
      final c = _create(p, atZero: false);
      children[p.key] = c;
      dom.add(c);
    }
  }

  _Char _create(_Part p, {required bool atZero}) =>
      p.isDigit ? _Char.digit(p.key, p.type, atZero ? 0 : p.digit, p.pos) : _Char.symbol(p.key, p.type, p.symbol);

  void remove(_Char c) {
    children.remove(c.key);
    dom.remove(c);
  }

  void willUpdate() {
    final offsets = flowOffsets();
    for (final c in children.values) {
      c.prevPos = pos(c, offsets);
      c.prevDigit = c.digit;
    }
  }

  void didUpdate(int trend, double now) {
    final offsets = flowOffsets();
    for (final c in children.values.toList()) {
      if (c.type != 'decimal') {
        final d = c.prevPos - pos(c, offsets);
        if (d.abs() > 1e-9) {
          c.shift.add(d, now, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
        }
      }
      if (c.isDigit) {
        final delta = c.delta(trend);
        if (delta != 0) {
          c.spin.add(-delta.toDouble(), now, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
        }
      }
    }
  }

  void updateDigits(List<_Part> parts, bool animate) {
    final keys = {for (final p in parts) p.key};
    final removed = children.values.where((c) => !keys.contains(c.key)).toList();
    for (final c in children.values) {
      c.popped = null;
    }
    _addNewAndUpdateExisting(parts, animate);
    for (final c in removed) {
      if (c.isDigit) {
        c.digit = 0;
      }
    }
    _pop(removed, animate);
  }

  void updateSymbols(List<_Part> parts, bool animate) {
    final keys = {for (final p in parts) p.key};
    _pop(children.values.where((c) => !keys.contains(c.key)).toList(), animate);
    _addNewAndUpdateExisting(parts, animate);
  }

  void _pop(List<_Char> chars, bool animate) {
    final offsets = flowOffsets();
    final measured = [for (final c in chars) c.popped ?? offsets[c] ?? 0.0];
    for (var i = 0; i < chars.length; i++) {
      chars[i].popped = measured[i];
    }
    for (final c in chars) {
      flow.setPresent(this, c, false, animate);
    }
  }

  void _addNewAndUpdateExisting(List<_Part> parts, bool animate) {
    final added = <(_Char, _Part)>[];
    final existing = <(_Char, _Part)>[];
    final ordered = <_Char>[];
    for (final p in parts) {
      var c = children[p.key];
      if (c != null) {
        c.popped = null;
        flow.setPresent(this, c, true, animate);
        existing.add((c, p));
      } else {
        c = _create(p, atZero: true);
        children[p.key] = c;
        if (animate) {
          c.presence.add(-0.9999, flow.now, GhNumberFlowTiming.opacity, GhNumberFlowTiming.opacityEase);
        }
        added.add((c, p));
      }
      ordered.add(c);
    }
    final placed = ordered.toSet();
    final others = dom.where((c) => !placed.contains(c)).toList();
    dom = right ? [...others, ...ordered] : [...ordered, ...others];
    if (animate) {
      final offsets = flowOffsets();
      for (final (c, _) in added) {
        c.prevPos = pos(c, offsets);
        c.prevDigit = c.digit;
      }
    }
    for (final (c, p) in [...added, ...existing]) {
      if (c.isDigit) {
        c
          ..digit = p.digit
          ..pos = p.pos;
      } else {
        flow.setSymbol(c, p.symbol, animate);
      }
    }
  }
}

class _Glyphs {
  _Glyphs(this.source, this.scaler) : style = source.copyWith(height: 1, leadingDistribution: TextLeadingDistribution.even) {
    final probe = TextPainter(
      text: TextSpan(text: '0', style: source),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    lineHeight = probe.height;
    probe.dispose();
    em = scaler.scale(style.fontSize ?? 14);
    pad = (em * 0.125).roundToDouble();
  }

  final TextStyle source;
  final TextStyle style;
  final TextScaler scaler;
  late final double lineHeight;
  late final double em;
  late final double pad;
  final Map<String, TextPainter> _painters = {};

  double get row => em + pad * 2;
  double get boxHeight => math.max(lineHeight, em + pad * 4);

  TextPainter of(String text) => _painters.putIfAbsent(
    text,
    () => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(),
  );

  double width(String text) => of(text).width;

  double baseline(TextBaseline baseline) => of('0').computeDistanceToActualBaseline(baseline);

  bool matches(TextStyle style, TextScaler scaler) => style == source && scaler == this.scaler;

  void dispose() {
    for (final p in _painters.values) {
      p.dispose();
    }
    _painters.clear();
  }
}

class _Flow extends ChangeNotifier {
  _Flow(this.glyphs, _Data initial) : data = initial {
    pre = _Section(this, right: true)..init(initial.pre);
    integer = _Section(this, right: true)..init(initial.integer);
    fraction = _Section(this, right: false)..init(initial.fraction);
    post = _Section(this, right: false)..init(initial.post);
  }

  _Glyphs glyphs;
  _Data data;
  late final _Section pre;
  late final _Section integer;
  late final _Section fraction;
  late final _Section post;
  final numberShift = _Track();
  final numberWidth = _Track();
  double now = 0;
  double busyUntil = 0;
  int version = 0;
  double? _lastLeft;
  bool _pendingShift = false;
  double _pendingShiftAt = 0;

  List<_Section> get sections => [pre, integer, fraction, post];

  bool get busy => now < busyUntil;

  double get width => pre.width + integer.width + fraction.width + post.width;

  List<double> _edges() {
    final p = pre.width;
    final i = integer.width;
    final f = fraction.width;
    return [p, p + i, p + i, p + i + f];
  }

  void update(_Data next, {required bool animate}) {
    final prev = data;
    data = next;
    final diff = next.value - prev.value;
    final trend = diff > 0 ? 1 : (diff < 0 ? -1 : 0);
    var prevPre = 0.0;
    var prevNumber = 0.0;
    if (animate) {
      prevPre = pre.width;
      prevNumber = integer.width + fraction.width;
      final edges = _edges();
      for (var i = 0; i < 4; i++) {
        sections[i]
          ..prevEdge = edges[i]
          ..willUpdate();
      }
    }
    pre.updateSymbols(next.pre, animate);
    integer.updateDigits(next.integer, animate);
    fraction.updateDigits(next.fraction, animate);
    post.updateSymbols(next.post, animate);
    if (animate) {
      busyUntil = math.max(busyUntil, now + GhNumberFlowTiming._transformSeconds);
      numberShift.add(prevPre - pre.width, now, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
      numberWidth.add(prevNumber - (integer.width + fraction.width), now, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
      final edges = _edges();
      for (var i = 0; i < 4; i++) {
        final s = sections[i];
        final d = s.prevEdge - edges[i];
        if (d.abs() > 1e-9 && s.children.isNotEmpty) {
          s.shift.add(d, now, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
        }
        s.didUpdate(trend, now);
      }
      _pendingShift = true;
      _pendingShiftAt = now;
    } else {
      _pendingShift = false;
    }
    version++;
  }

  void setPresent(_Section section, _Char c, bool present, bool animate) {
    if (c.present == present) {
      return;
    }
    c.present = present;
    if (!animate) {
      if (present) {
        c.presence.base = 0;
      } else {
        section.remove(c);
      }
      return;
    }
    c.presence
      ..base = present ? 0 : -0.999
      ..add(present ? -0.9999 : 0.999, now, GhNumberFlowTiming.opacity, GhNumberFlowTiming.opacityEase);
  }

  void setSymbol(_Char c, String text, bool animate) {
    if (c.text == text) {
      return;
    }
    final old = c.valueFor(c.text);
    if (old != null) {
      _presentValue(c, old, false, animate);
    }
    final next = c.valueFor(text);
    if (next != null) {
      _presentValue(c, next, true, animate);
    } else {
      final v = _SymbolValue(text);
      c.values.add(v);
      if (animate) {
        v.presence.add(-0.9999, now, GhNumberFlowTiming.opacity, GhNumberFlowTiming.opacityEase);
      }
    }
    c.text = text;
  }

  void _presentValue(_Char c, _SymbolValue v, bool present, bool animate) {
    if (v.present == present) {
      return;
    }
    v.present = present;
    if (!animate) {
      if (present) {
        v.presence.base = 0;
      } else {
        c.values.remove(v);
      }
      return;
    }
    v.presence
      ..base = present ? 0 : -0.999
      ..add(present ? -0.9999 : 0.999, now, GhNumberFlowTiming.opacity, GhNumberFlowTiming.opacityEase);
  }

  void applyHostShift(double left) {
    final last = _lastLeft;
    _lastLeft = left;
    if (!_pendingShift) {
      return;
    }
    _pendingShift = false;
    if (last == null) {
      return;
    }
    final h = last - left;
    if (h.abs() < 1e-6) {
      return;
    }
    numberShift.add(h, _pendingShiftAt, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
    for (final s in sections) {
      if (s.children.isNotEmpty) {
        s.shift.add(h, _pendingShiftAt, GhNumberFlowTiming.transform, GhNumberFlowTiming.transformEase);
      }
    }
  }

  void settle() {
    busyUntil = math.min(busyUntil, now);
    _pendingShift = false;
    numberShift.clear();
    numberWidth.clear();
    for (final s in sections) {
      s.shift.clear();
      for (final c in s.children.values.toList()) {
        if (!c.present) {
          s.remove(c);
          continue;
        }
        c.shift.clear();
        c.presence
          ..clear()
          ..base = 0;
        c.spin.clear();
        c.values.removeWhere((v) => !v.present);
        for (final v in c.values) {
          v.presence
            ..clear()
            ..base = 0;
        }
      }
    }
  }

  void repaint() => notifyListeners();
}

class _NumberFlow extends StatefulWidget {
  const _NumberFlow({required this.value, required this.style, required this.locale, required this.animate});

  final num value;
  final TextStyle? style;
  final String? locale;
  final bool animate;

  @override
  State<_NumberFlow> createState() => _NumberFlowState();
}

class _NumberFlowState extends State<_NumberFlow> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  _Flow? _flow;
  double _base = 0;
  double _elapsed = 0;

  double get _now => _base + _elapsed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_NumberFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    final flow = _flow!;
    if (!widget.animate && oldWidget.animate) {
      _settle();
    }
    if (widget.value != oldWidget.value || widget.locale != oldWidget.locale) {
      final animate = widget.animate && TickerMode.valuesOf(context).enabled;
      flow.now = _now;
      flow.update(_toData(widget.value, widget.locale), animate: animate);
      if (animate && !_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  void _sync() {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final scaler = MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final flow = _flow;
    if (flow == null) {
      _flow = _Flow(_Glyphs(style, scaler), _toData(widget.value, widget.locale));
      return;
    }
    if (flow.glyphs.matches(style, scaler)) {
      return;
    }
    final old = flow.glyphs;
    flow
      ..glyphs = _Glyphs(style, scaler)
      ..version += 1;
    old.dispose();
  }

  void _tick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / 1e6;
    final flow = _flow!;
    flow.now = _now;
    if (!flow.busy) {
      _settle();
    }
    flow.repaint();
  }

  void _settle() {
    final flow = _flow!;
    flow.now = _now;
    flow.settle();
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _base += _elapsed;
    _elapsed = 0;
    flow.now = _now;
  }

  @override
  void dispose() {
    _ticker.dispose();
    final flow = _flow!;
    flow.glyphs.dispose();
    flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = _flow!;
    return Semantics(
      label: flow.data.text,
      image: true,
      child: _FlowView(flow: flow, version: flow.version),
    );
  }
}

class _FlowView extends LeafRenderObjectWidget {
  const _FlowView({required this.flow, required this.version});

  final _Flow flow;
  final int version;

  @override
  _RenderFlow createRenderObject(BuildContext context) => _RenderFlow(flow, version);

  @override
  void updateRenderObject(BuildContext context, _RenderFlow renderObject) {
    renderObject
      ..flow = flow
      ..version = version;
  }
}

class _RenderFlow extends RenderBox {
  _RenderFlow(this._flow, this._version);

  _Flow _flow;
  int _version;

  set flow(_Flow value) {
    if (identical(value, _flow)) {
      return;
    }
    if (attached) {
      _flow.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _flow = value;
    markNeedsLayout();
  }

  set version(int value) {
    if (value == _version) {
      return;
    }
    _version = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _flow.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _flow.removeListener(markNeedsPaint);
    super.detach();
  }

  Size get _natural => Size(_flow.width, _flow.glyphs.boxHeight);

  @override
  double computeMinIntrinsicWidth(double height) => _flow.width;

  @override
  double computeMaxIntrinsicWidth(double height) => _flow.width;

  @override
  double computeMinIntrinsicHeight(double width) => _flow.glyphs.boxHeight;

  @override
  double computeMaxIntrinsicHeight(double width) => _flow.glyphs.boxHeight;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => constraints.constrain(_natural);

  @override
  double? computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    final height = constraints.constrain(_natural).height;
    return (height - _flow.glyphs.em) / 2 + _flow.glyphs.baseline(baseline);
  }

  @override
  void performLayout() {
    size = constraints.constrain(_natural);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => (size.height - _flow.glyphs.em) / 2 + _flow.glyphs.baseline(baseline);

  @override
  bool hitTestSelf(Offset position) => true;

  double _layoutLeft() {
    var x = 0.0;
    RenderObject node = this;
    while (true) {
      final data = node.parentData;
      if (data is BoxParentData) {
        x += data.offset.dx;
      }
      final parent = node.parent;
      if (parent is! RenderBox || parent.isRepaintBoundary) {
        break;
      }
      node = parent;
    }
    return x;
  }

  _Frame _frame(Offset offset) {
    final flow = _flow;
    final g = flow.glyphs;
    final now = flow.now;
    final emTop = offset.dy + (size.height - g.em) / 2;
    final preW = flow.pre.width;
    final intW = flow.integer.width;
    final fracW = flow.fraction.width;
    final x = offset.dx;
    final outer = <_Placed>[];
    final inner = <_Placed>[];
    _collectSection(outer, flow.pre, x + preW, emTop, now);
    _collectSection(inner, flow.integer, x + preW + intW, emTop, now);
    _collectSection(inner, flow.fraction, x + preW + intW, emTop, now);
    _collectSection(outer, flow.post, x + preW + intW + fracW, emTop, now);
    Rect? mask;
    if (flow.busy) {
      final left = x + preW + flow.numberShift.value(now) - g.em / 2;
      final width = math.max(0.0, intW + fracW + g.em + flow.numberWidth.value(now));
      mask = Rect.fromLTWH(left, emTop - g.pad * 2, width, g.em + g.pad * 4);
    }
    return _Frame(outer, inner, mask);
  }

  void _collectSection(List<_Placed> out, _Section s, double edge, double emTop, double now) {
    if (s.dom.isEmpty) {
      return;
    }
    final offsets = s.flowOffsets();
    final base = edge + s.shift.value(now);
    for (final c in s.dom) {
      final w = s.widthOf(c);
      final e = c.popped ?? offsets[c] ?? 0;
      final left = (s.right ? base - e - w : base + e) + c.shift.value(now);
      final opacity = (1 + c.presence.value(now)).clamp(0.0, 1.0);
      if (c.isDigit) {
        _collectDigit(out, c, left + w / 2, emTop, now, opacity);
      } else {
        _collectSymbol(out, s, c, left, w, emTop, now, opacity);
      }
    }
  }

  void _collectDigit(List<_Placed> out, _Char c, double center, double emTop, double now, double opacity) {
    final g = _flow.glyphs;
    if (!c.spin.activeAt(now)) {
      final text = '${c.digit}';
      out.add(_Placed(text, g.of(text), Offset(center - g.width(text) / 2, emTop), opacity));
      return;
    }
    final m = (c.digit + c.spin.value(now)) % 10;
    for (var n = 0; n < 10; n++) {
      final raw = (10 + n - m) % 10;
      final offset = raw - 10 * (raw / 5).floorToDouble();
      if (offset.abs() >= 1) {
        continue;
      }
      final text = '$n';
      out.add(_Placed(text, g.of(text), Offset(center - g.width(text) / 2, emTop + offset * g.row), opacity));
    }
  }

  void _collectSymbol(List<_Placed> out, _Section s, _Char c, double left, double w, double emTop, double now, double opacity) {
    final g = _flow.glyphs;
    for (final v in c.values) {
      final width = g.width(v.text);
      final x = v.present ? left : (s.right ? left + w - width : left);
      final valueOpacity = (1 + v.presence.value(now)).clamp(0.0, 1.0);
      out.add(_Placed(v.text, g.of(v.text), Offset(x, emTop), opacity * valueOpacity));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _flow.applyHostShift(_layoutLeft());
    final frame = _frame(offset);
    final canvas = context.canvas;
    _paintGlyphs(canvas, frame.outer);
    final mask = frame.mask;
    if (mask == null) {
      _paintGlyphs(canvas, frame.inner);
      return;
    }
    canvas
      ..save()
      ..clipRect(mask)
      ..saveLayer(mask, Paint());
    _paintGlyphs(canvas, frame.inner);
    canvas.saveLayer(mask, Paint()..blendMode = BlendMode.dstIn);
    _paintMask(canvas, mask, _flow.glyphs.em / 2, _flow.glyphs.pad * 2);
    canvas
      ..restore()
      ..restore()
      ..restore();
  }

  void _paintGlyphs(Canvas canvas, List<_Placed> glyphs) {
    final em = _flow.glyphs.em;
    for (final glyph in glyphs) {
      if (glyph.opacity <= 0.002) {
        continue;
      }
      final p = glyph.painter;
      if (glyph.opacity >= 1) {
        p.paint(canvas, glyph.offset);
        continue;
      }
      canvas.saveLayer(
        Rect.fromLTWH(glyph.offset.dx - em, glyph.offset.dy - em, p.width + em * 2, p.height + em * 2),
        Paint()..color = Color.fromRGBO(0, 0, 0, glyph.opacity),
      );
      p.paint(canvas, glyph.offset);
      canvas.restore();
    }
  }

  void _paintMask(Canvas canvas, Rect r, double fadeX, double fadeY) {
    if (r.width <= 0 || r.height <= 0) {
      return;
    }
    final n = math.min(fadeX, r.width / 2);
    final t = math.min(fadeY, r.height / 2);
    const clear = Color(0x00000000);
    const solid = Color(0xFF000000);
    final fx = n / r.width;
    final fy = t / r.height;
    canvas
      ..drawRect(
        Rect.fromLTRB(r.left, r.top + t, r.right, r.bottom - t),
        Paint()..shader = ui.Gradient.linear(r.centerLeft, r.centerRight, const [clear, solid, solid, clear], [0, fx, 1 - fx, 1]),
      )
      ..drawRect(
        Rect.fromLTRB(r.left + n, r.top, r.right - n, r.bottom),
        Paint()..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [clear, solid, solid, clear], [0, fy, 1 - fy, 1]),
      );
    if (n <= 0 || t <= 0) {
      return;
    }
    final corner = Paint()..shader = ui.Gradient.radial(Offset.zero, 1, const [solid, clear], const [0, .71]);
    const tile = 1 / math.sqrt2;
    for (final (cx, cy, sx, sy) in [
      (r.left + n, r.top + t, -1, -1),
      (r.right - n, r.top + t, 1, -1),
      (r.right - n, r.bottom - t, 1, 1),
      (r.left + n, r.bottom - t, -1, 1),
    ]) {
      canvas
        ..save()
        ..translate(cx, cy)
        ..scale(n * math.sqrt2, t * math.sqrt2)
        ..drawRect(Rect.fromLTWH(sx < 0 ? -tile : 0, sy < 0 ? -tile : 0, tile, tile), corner)
        ..restore();
    }
  }
}

class _Placed {
  const _Placed(this.text, this.painter, this.offset, this.opacity);

  final String text;
  final TextPainter painter;
  final Offset offset;
  final double opacity;
}

class _Frame {
  const _Frame(this.outer, this.inner, this.mask);

  final List<_Placed> outer;
  final List<_Placed> inner;
  final Rect? mask;
}

@immutable
class GhNumberGlyph {
  const GhNumberGlyph(this.text, this.offset, this.opacity, {required this.masked});

  final String text;
  final Offset offset;
  final double opacity;
  final bool masked;

  @override
  String toString() => 'GhNumberGlyph($text, $offset, ${opacity.toStringAsFixed(3)}${masked ? ', masked' : ''})';
}

@immutable
class GhNumberFlowSnapshot {
  const GhNumberFlowSnapshot({required this.size, required this.em, required this.glyphs, required this.mask, required this.text});

  final Size size;
  final double em;
  final List<GhNumberGlyph> glyphs;
  final Rect? mask;
  final String text;

  bool get animating => mask != null;

  List<GhNumberGlyph> visible({double minOpacity = 0.01}) {
    final band = mask;
    return [
      for (final g in glyphs)
        if (g.opacity >= minOpacity &&
            (!g.masked || band == null || (g.offset.dy + em > band.top + 1e-6 && g.offset.dy < band.bottom - 1e-6)))
          g,
    ];
  }
}

@visibleForTesting
GhNumberFlowSnapshot? debugGhNumberFlow(BuildContext context) {
  _RenderFlow? found;
  void visit(RenderObject node) {
    if (found != null) {
      return;
    }
    if (node is _RenderFlow) {
      found = node;
      return;
    }
    node.visitChildren(visit);
  }

  final root = context.findRenderObject();
  if (root == null) {
    return null;
  }
  visit(root);
  final render = found;
  if (render == null) {
    return null;
  }
  final frame = render._frame(Offset.zero);
  return GhNumberFlowSnapshot(
    size: render.size,
    em: render._flow.glyphs.em,
    mask: frame.mask,
    text: render._flow.data.text,
    glyphs: [
      for (final g in frame.outer) GhNumberGlyph(g.text, g.offset, g.opacity, masked: false),
      for (final g in frame.inner) GhNumberGlyph(g.text, g.offset, g.opacity, masked: true),
    ],
  );
}
