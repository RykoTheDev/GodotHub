import 'dart:math' as math;

import 'package:flutter/animation.dart';

typedef _EaseFn = double Function(double p);

double Function(double) _outFromIn(_EaseFn easeIn) => (p) => 1 - easeIn(1 - p);

double Function(double) _inOutFromIn(_EaseFn easeIn) =>
    (p) => p < .5 ? easeIn(p * 2) / 2 : 1 - easeIn((1 - p) * 2) / 2;

double Function(double) _inOutFromOut(_EaseFn easeOut) =>
    (p) => p < .5 ? (1 - easeOut(1 - (p * 2))) / 2 : .5 + easeOut((p - .5) * 2) / 2;

double _expoIn(double p) => math.pow(2, 10 * (p - 1)).toDouble() * p + p * p * p * p * p * p * (1 - p);

_EaseFn _powerIn(int power) => (p) => math.pow(p, power).toDouble();

_EaseFn _backOut(double overshoot) => (p) {
      if (p == 0) {
        return 0;
      }
      final q = p - 1;
      return q * q * ((overshoot + 1) * q + overshoot) + 1;
    };

_EaseFn _elasticOut(double amplitude, double? period, {required bool inOut}) {
  final p1 = amplitude >= 1 ? amplitude : 1.0;
  final p2Raw = (period ?? (inOut ? .45 : .3)) / (amplitude < 1 ? amplitude : 1);
  final asin = math.asin(1 / p1);
  final p3 = p2Raw / (2 * math.pi) * (asin.isNaN ? 0 : asin);
  final p2 = 2 * math.pi / p2Raw;
  return (p) => p == 1 ? 1 : p1 * math.pow(2, -10 * p).toDouble() * math.sin((p - p3) * p2) + 1;
}

class GsapEase extends Curve {
  const GsapEase._(this.name, this._fn);

  factory GsapEase(String spec) => _cache.putIfAbsent(spec, () => GsapEase._(spec, _parse(spec)));

  static final Map<String, GsapEase> _cache = {};

  final String name;
  final _EaseFn _fn;

  static const String defaultEase = 'power1.out';

  @override
  double transformInternal(double t) => _fn(t);

  @override
  String toString() => 'GsapEase($name)';

  static _EaseFn _parse(String spec) {
    final match = RegExp(r'^([a-zA-Z0-9]+)(?:\.(in|out|inOut))?(?:\(([^)]*)\))?$').firstMatch(spec.trim());
    if (match == null) {
      throw ArgumentError.value(spec, 'spec', 'unknown GSAP ease');
    }
    final family = match.group(1)!.toLowerCase();
    final type = match.group(2) ?? 'out';
    final args = (match.group(3) ?? '')
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .map(double.parse)
        .toList();

    _EaseFn pick(_EaseFn easeIn, {_EaseFn? easeOut, _EaseFn? easeInOut}) {
      return switch (type) {
        'in' => easeIn,
        'inOut' => easeInOut ?? _inOutFromIn(easeIn),
        _ => easeOut ?? _outFromIn(easeIn),
      };
    }

    switch (family) {
      case 'none' || 'linear' || 'power0':
        return (p) => p;
      case 'power1' || 'quad':
        return pick(_powerIn(2));
      case 'power2' || 'cubic':
        return pick(_powerIn(3));
      case 'power3' || 'quart':
        return pick(_powerIn(4));
      case 'power4' || 'quint' || 'strong':
        return pick(_powerIn(5));
      case 'expo':
        return pick(_expoIn);
      case 'sine':
        return pick((p) => p == 1 ? 1 : -math.cos(p * math.pi / 2) + 1);
      case 'circ':
        return pick((p) => -(math.sqrt(1 - (p * p)) - 1));
      case 'back':
        final overshoot = args.isNotEmpty ? args[0] : 1.70158;
        final out = _backOut(overshoot);
        return switch (type) {
          'in' => (p) => 1 - out(1 - p),
          'inOut' => _inOutFromOut(out),
          _ => out,
        };
      case 'elastic':
        final amplitude = args.isNotEmpty ? args[0] : 1.0;
        final period = args.length > 1 ? args[1] : null;
        final out = _elasticOut(amplitude, period, inOut: type == 'inOut');
        return switch (type) {
          'in' => (p) => 1 - out(1 - p),
          'inOut' => _inOutFromOut(out),
          _ => out,
        };
      default:
        throw ArgumentError.value(spec, 'spec', 'unknown GSAP ease');
    }
  }
}

class CssLinearEase extends Curve {
  const CssLinearEase(this.points);

  final List<double> points;

  @override
  double transformInternal(double t) {
    final segments = points.length - 1;
    final position = t * segments;
    final index = position.floor().clamp(0, segments - 1);
    final local = position - index;
    return points[index] + (points[index + 1] - points[index]) * local;
  }
}

abstract final class GhEase {
  static final out = GsapEase('expo.out');
  static final soft = GsapEase('power3.out');
  static final easeIn = GsapEase('power2.in');
  static final spring = GsapEase('back.out(1.8)');
  static final pop = GsapEase('back.out(2.6)');
  static final elastic = GsapEase('elastic.out(1.1, 0.4)');
  static final defaultEase = GsapEase(GsapEase.defaultEase);

  static const cssEaseOut = Cubic(0, 0, 0.58, 1);
  static const cssEase = Cubic(0.25, 0.1, 0.25, 1);
}
