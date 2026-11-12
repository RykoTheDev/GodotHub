import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';

enum GhMotionIntensity {
  full,
  subtle,
  none;

  static GhMotionIntensity parse(String value) => values.firstWhere((v) => v.name == value, orElse: () => GhMotionIntensity.full);
}

enum GhViewEntrance {
  fade,
  slide,
  scale,
  none;

  static GhViewEntrance parse(String value) => values.firstWhere((v) => v.name == value, orElse: () => GhViewEntrance.slide);
}

@immutable
class GhMotionPrefs {
  const GhMotionPrefs({
    this.intensity = GhMotionIntensity.full,
    this.speed = 1.5,
    this.entrance = GhViewEntrance.slide,
    this.threshold = 20,
    this.scrollReveal = true,
    this.tilt = true,
    this.ripple = true,
    this.press = true,
    this.animatedNumbers = true,
  });

  final GhMotionIntensity intensity;
  final double speed;
  final GhViewEntrance entrance;
  final int threshold;
  final bool scrollReveal;
  final bool tilt;
  final bool ripple;
  final bool press;
  final bool animatedNumbers;

  GhMotionPrefs copyWith({
    GhMotionIntensity? intensity,
    double? speed,
    GhViewEntrance? entrance,
    int? threshold,
    bool? scrollReveal,
    bool? tilt,
    bool? ripple,
    bool? press,
    bool? animatedNumbers,
  }) {
    return GhMotionPrefs(
      intensity: intensity ?? this.intensity,
      speed: speed ?? this.speed,
      entrance: entrance ?? this.entrance,
      threshold: threshold ?? this.threshold,
      scrollReveal: scrollReveal ?? this.scrollReveal,
      tilt: tilt ?? this.tilt,
      ripple: ripple ?? this.ripple,
      press: press ?? this.press,
      animatedNumbers: animatedNumbers ?? this.animatedNumbers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GhMotionPrefs &&
      other.intensity == intensity &&
      other.speed == speed &&
      other.entrance == entrance &&
      other.threshold == threshold &&
      other.scrollReveal == scrollReveal &&
      other.tilt == tilt &&
      other.ripple == ripple &&
      other.press == press &&
      other.animatedNumbers == animatedNumbers;

  @override
  int get hashCode => Object.hash(intensity, speed, entrance, threshold, scrollReveal, tilt, ripple, press, animatedNumbers);
}

@immutable
class GhMotionData {
  const GhMotionData({this.prefs = const GhMotionPrefs(), this.osReduced = false, this.isLinux = false});

  final GhMotionPrefs prefs;
  final bool osReduced;
  final bool isLinux;

  static const offTimeScale = 40.0;
  static const _cssOff = Duration(microseconds: 10);

  bool get off => osReduced || prefs.intensity == GhMotionIntensity.none;
  bool get flourishes => !off && prefs.intensity == GhMotionIntensity.full;
  bool get blur => !isLinux;
  double get speed => (prefs.intensity == GhMotionIntensity.subtle ? 1.8 : 1) * prefs.speed;
  double get timeScale => off ? offTimeScale : speed;

  bool get entranceOn => !off && prefs.entrance != GhViewEntrance.none;
  bool get pressOn => !off && prefs.press;
  bool get rippleOn => prefs.ripple && flourishes;
  bool get tiltOn => prefs.tilt && flourishes;
  bool get numbersOn => prefs.animatedNumbers && prefs.intensity != GhMotionIntensity.none && !osReduced;

  Duration gsap(double seconds) => Duration(microseconds: (seconds * 1e6 / timeScale).round());

  Duration css(Duration base) {
    if (off) {
      return _cssOff;
    }
    return Duration(microseconds: (base.inMicroseconds / (speed <= 0 ? 1 : speed)).round());
  }

  @override
  bool operator ==(Object other) =>
      other is GhMotionData && other.prefs == prefs && other.osReduced == osReduced && other.isLinux == isLinux;

  @override
  int get hashCode => Object.hash(prefs, osReduced, isLinux);
}

class GhMotion extends StatelessWidget {
  const GhMotion({super.key, this.prefs = const GhMotionPrefs(), this.osReduced, required this.child});

  final GhMotionPrefs prefs;
  final bool? osReduced;
  final Widget child;

  static GhMotionData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_GhMotionScope>();
    if (scope != null) {
      return scope.data;
    }
    return GhMotionData(osReduced: MediaQuery.maybeDisableAnimationsOf(context) ?? false, isLinux: _isLinux);
  }

  static bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final reduced = osReduced ?? MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return _GhMotionScope(
      data: GhMotionData(prefs: prefs, osReduced: reduced, isLinux: _isLinux),
      child: child,
    );
  }
}

class _GhMotionScope extends InheritedWidget {
  const _GhMotionScope({required this.data, required super.child});

  final GhMotionData data;

  @override
  bool updateShouldNotify(_GhMotionScope oldWidget) => data != oldWidget.data;
}

double ghStaggerAmount(int index, int count, double amount) => count <= 1 ? 0 : index * amount / (count - 1);
