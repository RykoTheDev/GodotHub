import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../design/design.dart';
import '../motion/ease.dart';
import '../motion/intro.dart';
import '../motion/motion.dart';
import '../motion/tween.dart';
import '../titlebar/providers.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

const welcomeWordmark = 'GodotHub';

class WelcomeIntro extends ConsumerStatefulWidget {
  const WelcomeIntro({super.key, required this.target, required this.onLeave, required this.onDone, this.targetHidden});

  final GlobalKey target;
  final VoidCallback onLeave;
  final VoidCallback onDone;
  final ValueChanged<bool>? targetHidden;

  @override
  ConsumerState<WelcomeIntro> createState() => _WelcomeIntroState();
}

class _WelcomeIntroState extends ConsumerState<WelcomeIntro> with TickerProviderStateMixin {
  late final GhWelcomeIntroTimeline _intro = GhWelcomeIntroTimeline(vsync: this, letters: welcomeWordmark.length);
  late final AnimationController _leave = AnimationController(vsync: this);
  final GlobalKey _wordmark = GlobalKey();
  String? _name;
  bool _rings = false;
  bool _started = false;
  bool _leaving = false;
  Offset _travel = Offset.zero;
  double _scale = 1;

  static const _total = 1.05;

  Animation<double> _interval(double start, double duration, Curve curve) => CurvedAnimation(
    parent: _leave,
    curve: Interval(start / _total, ((start + duration) / _total).clamp(0, 1), curve: curve),
  );

  late final List<Animation<double>> _fades = [for (var i = 0; i < 4; i++) _interval(i * 0.04, 0.3, GhEase.easeIn)];
  late final Animation<double> _fly = _interval(0.1, 0.95, GsapEase('power3.inOut'));
  late final Animation<double> _bg = _interval(0.25, 0.55, GsapEase('power2.out'));

  @override
  void initState() {
    super.initState();
    Api.getOsUsername().then((name) {
      final trimmed = name?.trim() ?? '';
      if (mounted && trimmed.isNotEmpty) setState(() => _name = trimmed);
    }, onError: (Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = GhMotion.of(context);
    if (motion.off) {
      _intro.timeline.finish();
      return;
    }
    _intro.play(motion).then((_) {
      if (mounted && _intro.timeline.controller.isCompleted) setState(() => _rings = true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _leave.dispose();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _diveIn() {
    if (_leaving) return;
    setState(() => _leaving = true);
    final motion = GhMotion.of(context);
    final from = _rectOf(_wordmark);
    final to = _rectOf(widget.target);
    if (motion.off || from == null || to == null) {
      widget.onLeave();
      widget.onDone();
      return;
    }
    final theme = GhTheme.of(context);
    _travel = to.center - from.center;
    _scale = theme.text(size: GhTextSize.xl).fontSize! / theme.rem(5.5);
    widget.targetHidden?.call(true);
    widget.onLeave();
    _leave.duration = motion.gsap(_total);
    _leave.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      widget.targetHidden?.call(false);
      widget.onDone();
    });
  }

  Widget _fadeOut(int index, Widget child) => AnimatedBuilder(
    animation: _fades[index],
    child: child,
    builder: (context, child) {
      final t = _fades[index].value;
      return Opacity(
        opacity: 1 - t,
        child: Transform.translate(offset: Offset(0, 12 * t), child: child),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.rem(5.5);
    final word = theme
        .text(size: GhTextSize.base, weight: FontWeight.w900, color: theme.ink, lineHeight: 1)
        .copyWith(fontSize: size, letterSpacing: -0.025 * size);
    final window = ref.watch(titleBarWindowProvider);
    return IgnorePointer(
      ignoring: _leaving,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.enter): _diveIn},
        child: GhMagneticArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _bg,
                builder: (context, child) => Opacity(opacity: 1 - _bg.value, child: child),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => window.startDragging(),
                  child: ColoredBox(
                    color: theme.base,
                    child: GhPoseTransition(
                      animation: _intro.grid,
                      from: GhWelcomeIntroPoses.grid,
                      child: Opacity(
                        opacity: 0.07,
                        child: CustomPaint(painter: WelcomeDotGridPainter(theme.ink), size: Size.infinite),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _fadeOut(
                        0,
                        GhPoseTransition(
                          animation: _intro.eyebrow,
                          from: GhWelcomeIntroPoses.eyebrow,
                          child: ExcludeSemantics(
                            child: Text(
                              (_name == null ? ghTr('onboarding:welcome_to') : ghTr('onboarding:welcome_to_name', args: {'name': _name}))
                                  .toUpperCase(),
                              style: theme.text(
                                size: GhTextSize.sm,
                                weight: GhWeight.semibold,
                                color: theme.accentBright,
                                letterSpacingEm: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: theme.space(4)),
                      AnimatedBuilder(
                        animation: _fly,
                        builder: (context, child) => Transform.translate(
                          offset: _travel * _fly.value,
                          child: Transform.scale(scale: 1 + (_scale - 1) * _fly.value, child: child),
                        ),
                        child: KeyedSubtree(
                          key: _wordmark,
                          child: GhLetterRow(
                            text: welcomeWordmark,
                            style: word,
                            animations: _intro.letters,
                            perspective: 800,
                            semanticLabel: ghTr('onboarding:welcome_title'),
                          ),
                        ),
                      ),
                      SizedBox(height: theme.space(4)),
                      _fadeOut(
                        1,
                        GhPoseTransition(
                          animation: _intro.line,
                          from: GhWelcomeIntroPoses.line,
                          child: Container(
                            width: theme.space(24),
                            height: 3,
                            decoration: BoxDecoration(color: theme.accentBright, borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                      ),
                      SizedBox(height: theme.space(7)),
                      _fadeOut(
                        2,
                        GhPoseTransition(
                          animation: _intro.desc,
                          from: GhWelcomeIntroPoses.desc,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: theme.rem(32)),
                            child: Text(
                              ghTr('onboarding:welcome_desc'),
                              textAlign: TextAlign.center,
                              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: theme.space(7) + theme.space(2)),
                      _fadeOut(
                        3,
                        GhPoseTransition(
                          animation: _intro.cta,
                          from: GhWelcomeIntroPoses.cta,
                          child: GhMagnet(
                            enabled: !_leaving,
                            child: GhRingPulse(
                              running: _rings && !_leaving,
                              color: theme.accentBright,
                              radius: theme.radiusBtn,
                              child: _DiveInButton(onPressed: _leaving ? null : _diveIn),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiveInButton extends StatelessWidget {
  const _DiveInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GhPressable(
      key: const ValueKey('welcome-dive-in'),
      onPressed: onPressed,
      autofocus: true,
      borderRadius: radius,
      rippleColor: Colors.white,
      disabledOpacity: 1,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(12),
        padding: EdgeInsets.symmetric(horizontal: theme.space(8)),
        color: states.active ? theme.accentBright : theme.accent,
        borderRadius: radius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: theme.space(2.5),
          children: [
            Text(
              ghTr('onboarding:dive_in'),
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: Colors.white),
            ),
            AnimatedSlide(
              offset: Offset(states.active ? (rtl ? -0.15 : 0.15) : 0, 0),
              duration: GhDurations.interactive,
              child: Transform.flip(
                flipX: rtl,
                child: GhIcon(GhIcons.chevronRight, size: theme.space(3.5), color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeDotGridPainter extends CustomPainter {
  const WelcomeDotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reachX = size.width / 2;
    final reachY = size.height / 2;
    final paint = Paint();
    for (var x = 0.0; x < size.width; x += 28) {
      for (var y = 0.0; y < size.height; y += 28) {
        final dx = (x + 1 - center.dx) / reachX;
        final dy = (y + 1 - center.dy) / reachY;
        final d = Offset(dx, dy).distance;
        final fade = d < 0.3 ? 1.0 : (d > 0.75 ? 0.0 : 1 - (d - 0.3) / 0.45);
        if (fade <= 0) continue;
        paint.color = color.withValues(alpha: color.a * fade);
        canvas.drawCircle(Offset(x + 1, y + 1), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WelcomeDotGridPainter oldDelegate) => oldDelegate.color != color;
}
