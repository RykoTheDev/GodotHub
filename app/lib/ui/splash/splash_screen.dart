import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/ease.dart';
import '../../motion/intro.dart';
import '../../motion/motion.dart';
import '../../motion/tween.dart';

abstract final class GhSplashTiming {
  static const word = 'GodotHub';
  static const letterDuration = 0.9;
  static const letterStagger = 0.045;
  static const trackAt = 0.25;
  static const trackDuration = 0.6;
  static const trackFrom = GhPose(scaleX: 0, opacity: 0);
  static const barDuration = 1.1;
  static const barFrom = -120.0;
  static const barTo = 220.0;
  static final barEase = GsapEase('power2.inOut');
  static const perspective = 600.0;
  static const fontRem = 3.5;
  static const trackWidth = 160.0;
  static const trackHeight = 3.0;
  static const gap = 12.0;
}

class GhSplashScreen extends StatefulWidget {
  const GhSplashScreen({super.key});

  @override
  State<GhSplashScreen> createState() => _GhSplashScreenState();
}

class _GhSplashScreenState extends State<GhSplashScreen> with TickerProviderStateMixin {
  late final GhTimeline _timeline = GhTimeline(vsync: this);
  late final AnimationController _bar = AnimationController(vsync: this);
  late final List<Animation<double>> _letters;
  late final Animation<double> _track;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _letters = ghStaggerTracks(
      _timeline,
      count: GhSplashTiming.word.length,
      at: 0,
      duration: GhSplashTiming.letterDuration,
      each: GhSplashTiming.letterStagger,
    );
    _track = _timeline.add(GhTrack(start: GhSplashTiming.trackAt, duration: GhSplashTiming.trackDuration, ease: GhEase.out));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final motion = GhMotion.of(context);
    _timeline.play(motion);
    if (!motion.off) {
      _bar.duration = motion.gsap(GhSplashTiming.barDuration);
      _bar.repeat();
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final fontSize = theme.rem(GhSplashTiming.fontRem);
    final style = theme
        .text(size: GhTextSize.base, weight: FontWeight.w900, lineHeight: 1)
        .copyWith(fontSize: fontSize, fontStyle: FontStyle.italic, letterSpacing: -0.025 * fontSize, color: theme.ink);
    return SizedBox.expand(
      child: ColoredBox(
        color: theme.base,
        child: ClipRect(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GhLetterRow(text: GhSplashTiming.word, style: style, animations: _letters, perspective: GhSplashTiming.perspective),
                const SizedBox(height: GhSplashTiming.gap),
                GhPoseTransition(
                  animation: _track,
                  from: GhSplashTiming.trackFrom,
                  child: _Track(bar: _bar, theme: theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.bar, required this.theme});

  final AnimationController bar;
  final GhTheme theme;

  @override
  Widget build(BuildContext context) {
    final accent = theme.accent;
    return Container(
      width: GhSplashTiming.trackWidth,
      height: GhSplashTiming.trackHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(999)),
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: GhSplashTiming.trackWidth / 2,
            child: AnimatedBuilder(
              animation: bar,
              builder: (context, child) {
                final percent = bar.isAnimating
                    ? GhSplashTiming.barFrom + (GhSplashTiming.barTo - GhSplashTiming.barFrom) * GhSplashTiming.barEase.transform(bar.value)
                    : 0.0;
                return FractionalTranslation(translation: Offset(percent / 100, 0), child: child);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(colors: [accent.withValues(alpha: 0), accent, accent.withValues(alpha: 0)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
