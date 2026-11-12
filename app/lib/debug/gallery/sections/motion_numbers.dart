import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../motion/animated_number.dart';
import '../../../motion/ease.dart';
import '../../../motion/motion.dart';
import '../../../ui/core/button.dart';
import '../gallery_kit.dart';

final motionNumbersSections = <GallerySection>[
  GallerySection('Animated number', (context) => const _NumberPlayground()),
  GallerySection('Eases', (context) => const _EaseBoard()),
];

class _NumberPlayground extends StatefulWidget {
  const _NumberPlayground();

  @override
  State<_NumberPlayground> createState() => _NumberPlaygroundState();
}

class _NumberPlaygroundState extends State<_NumberPlayground> {
  static const _jumps = <(num, num)>[
    (9, 10),
    (10, 9),
    (99, 100),
    (999, 1000),
    (1234, 987),
    (0, 12345),
    (12345, 0),
    (1999, 2001),
    (-5, 5),
    (1.5, 2.25),
  ];

  final _random = math.Random();
  num _value = 1234;
  int _epoch = 0;
  Timer? _pending;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  void _set(num value) {
    _pending?.cancel();
    setState(() => _value = value);
  }

  void _jump(num from, num to) {
    _pending?.cancel();
    setState(() {
      _value = from;
      _epoch++;
    });
    _pending = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _value = to);
      }
    });
  }

  String _label(num v) => ghFormatNumber(v);

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    const tabular = [FontFeature.tabularFigures()];
    final samples = <(String, TextStyle)>[
      ('view header: text-4xl bold muted', theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted)),
      (
        'dashboard stat: 1.6rem bold tabular leading-none',
        theme.text(size: GhTextSize.x2l, weight: GhWeight.bold, lineHeight: 1).copyWith(fontSize: theme.rem(1.6), fontFeatures: tabular),
      ),
      (
        'onboarding stat: text-4xl bold tabular tracking-tight',
        theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, letterSpacingEm: -0.025).copyWith(fontFeatures: tabular),
      ),
      ('stat tile: text-3xl semibold tabular', theme.text(size: GhTextSize.x3l, weight: GhWeight.semibold).copyWith(fontFeatures: tabular)),
      ('stat tile: text-2xl semibold tabular', theme.text(size: GhTextSize.x2l, weight: GhWeight.semibold).copyWith(fontFeatures: tabular)),
      ('header count: text-xs muted tabular', theme.text(size: GhTextSize.xs, color: theme.muted).copyWith(fontFeatures: tabular)),
    ];
    final countStyle = theme
        .text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.5))
        .copyWith(fontFeatures: tabular);
    final mode = !motion.prefs.animatedNumbers || motion.prefs.intensity == GhMotionIntensity.none
        ? 'plain text (animated numbers off or intensity none)'
        : motion.numbersOn
        ? 'animated'
        : 'formatted, no animation (OS reduced motion)';
    final note = theme.text(size: GhTextSize.x3s, color: theme.muted, mono: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Controls',
          spacing: 8,
          children: [
            GhButton(onPressed: () => _set(_value - 1), label: '-1', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_value + 1), label: '+1', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_value - 10), label: '-10', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_value + 10), label: '+10', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_value + 100), label: '+100', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_value * 10), label: 'x10', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_value ~/ 10), label: '/10', variant: GhButtonVariant.outline),
            GhButton(onPressed: () => _set(_random.nextInt(100000)), label: 'Random', variant: GhButtonVariant.outline),
          ],
        ),
        GalleryGroup(
          title: 'Jumps (remount at the first value, then change after 500 ms)',
          spacing: 8,
          children: [
            for (final (from, to) in _jumps)
              GhButton(onPressed: () => _jump(from, to), label: '${_label(from)} to ${_label(to)}', variant: GhButtonVariant.outline),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'value ${ghPlainNumber(_value)}, mode: $mode. Durations are fixed (900 ms transform, 450 ms opacity) and ignore the speed setting.',
            style: note,
          ),
        ),
        KeyedSubtree(
          key: ValueKey(_epoch),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GalleryGroup(
                title: 'Sizes used in the app',
                spacing: 28,
                children: [
                  for (final (label, style) in samples)
                    GalleryItem(
                      label: label,
                      child: GhAnimatedNumber(_value, style: style),
                    ),
                  GalleryItem(
                    label: 'section count: text-3xs medium muted/50 tabular',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PINNED',
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
                        ),
                        const SizedBox(width: 6),
                        Text('· ', style: countStyle),
                        GhAnimatedNumber(_value, style: countStyle),
                      ],
                    ),
                  ),
                ],
              ),
              GalleryGroup(
                title: 'Digit widths',
                spacing: 28,
                children: [
                  GalleryItem(
                    label: 'proportional digits',
                    child: GhAnimatedNumber(
                      _value,
                      style: theme.text(size: GhTextSize.x3l, weight: GhWeight.semibold),
                    ),
                  ),
                  GalleryItem(
                    label: 'tabular digits',
                    child: GhAnimatedNumber(
                      _value,
                      style: theme.text(size: GhTextSize.x3l, weight: GhWeight.semibold).copyWith(fontFeatures: tabular),
                    ),
                  ),
                ],
              ),
              GalleryGroup(
                title: 'Alignment',
                spacing: 16,
                children: [
                  for (final (label, alignment) in [
                    ('start', AlignmentDirectional.centerStart),
                    ('center', AlignmentDirectional.center),
                    ('end', AlignmentDirectional.centerEnd),
                  ])
                    GalleryItem(
                      label: label,
                      child: _Frame(alignment: alignment, value: _value),
                    ),
                  GalleryItem(
                    label: 'start, right to left',
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: _Frame(alignment: AlignmentDirectional.centerStart, value: _value),
                    ),
                  ),
                ],
              ),
              GalleryGroup(
                title: 'Locales',
                spacing: 28,
                children: [
                  for (final locale in ['en-US', 'de-DE', 'fr-FR', 'es-ES', 'ru-RU'])
                    GalleryItem(
                      label: locale,
                      child: GhAnimatedNumber(
                        _value,
                        locale: locale,
                        style: theme.text(size: GhTextSize.x2l, weight: GhWeight.semibold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.alignment, required this.value});

  final AlignmentDirectional alignment;
  final num value;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      width: 220,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.raised,
        border: Border.all(color: theme.outline),
        borderRadius: BorderRadius.circular(theme.radiusTile),
      ),
      child: Align(
        alignment: alignment,
        child: GhAnimatedNumber(
          value,
          style: theme.text(size: GhTextSize.x2l, weight: GhWeight.semibold),
        ),
      ),
    );
  }
}

enum _Clock { gsap, css, fixed }

class _EaseSpec {
  const _EaseSpec(this.name, this.spec, this.curve, this.seconds, this.clock);

  final String name;
  final String spec;
  final Curve curve;
  final double seconds;
  final _Clock clock;

  Duration duration(GhMotionData motion) {
    final base = Duration(microseconds: (seconds * 1e6).round());
    return switch (clock) {
      _Clock.gsap => motion.gsap(seconds),
      _Clock.css => motion.css(base),
      _Clock.fixed => base,
    };
  }

  String get clockLabel => switch (clock) {
    _Clock.gsap => 'GSAP',
    _Clock.css => 'CSS',
    _Clock.fixed => 'fixed',
  };
}

final _eases = <_EaseSpec>[
  _EaseSpec('GhEase.out', 'expo.out', GhEase.out, 0.6, _Clock.gsap),
  _EaseSpec('GhEase.soft', 'power3.out', GhEase.soft, 0.4, _Clock.gsap),
  _EaseSpec('GhEase.easeIn', 'power2.in', GhEase.easeIn, 0.4, _Clock.gsap),
  _EaseSpec('GhEase.spring', 'back.out(1.8)', GhEase.spring, 0.7, _Clock.gsap),
  _EaseSpec('GhEase.pop', 'back.out(2.6)', GhEase.pop, 0.85, _Clock.gsap),
  _EaseSpec('GhEase.elastic', 'elastic.out(1.1, 0.4)', GhEase.elastic, 0.9, _Clock.gsap),
  _EaseSpec('GhEase.defaultEase', 'power1.out', GhEase.defaultEase, 0.5, _Clock.gsap),
  _EaseSpec('GhEase.cssEase', 'ease', GhEase.cssEase, 0.15, _Clock.css),
  _EaseSpec('GhEase.cssEaseOut', 'ease-out (number-flow opacity)', GhEase.cssEaseOut, 0.45, _Clock.fixed),
  _EaseSpec('number-flow transform', 'linear(...)', GhNumberFlowTiming.transformEase, 0.9, _Clock.fixed),
  _EaseSpec('power2.out', 'power2.out', GsapEase('power2.out'), 0.4, _Clock.gsap),
  _EaseSpec('power3.in', 'power3.in', GsapEase('power3.in'), 0.42, _Clock.gsap),
  _EaseSpec('power2.inOut', 'power2.inOut', GsapEase('power2.inOut'), 0.75, _Clock.gsap),
  _EaseSpec('power3.inOut', 'power3.inOut', GsapEase('power3.inOut'), 0.85, _Clock.gsap),
  _EaseSpec('back.out(1.5)', 'back.out(1.5)', GsapEase('back.out(1.5)'), 0.8, _Clock.gsap),
  _EaseSpec('elastic.out(1.15, 0.32)', 'elastic.out(1.15, 0.32)', GsapEase('elastic.out(1.15, 0.32)'), 0.8, _Clock.gsap),
  _EaseSpec('elastic.out(1, 0.5)', 'elastic.out(1, 0.5)', GsapEase('elastic.out(1, 0.5)'), 1.0, _Clock.gsap),
  _EaseSpec('power1.out', 'power1.out (GSAP default)', GsapEase('power1.out'), 0.5, _Clock.gsap),
];

class _EaseBoard extends StatefulWidget {
  const _EaseBoard();

  @override
  State<_EaseBoard> createState() => _EaseBoardState();
}

class _EaseBoardState extends State<_EaseBoard> {
  int _run = 0;
  bool _loop = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Playback',
          spacing: 8,
          children: [
            GhButton(onPressed: () => setState(() => _run++), label: 'Play all', variant: GhButtonVariant.primary),
            GhButton(
              onPressed: () => setState(() => _loop = !_loop),
              label: _loop ? 'Loop on' : 'Loop off',
              variant: _loop ? GhButtonVariant.primary : GhButtonVariant.outline,
            ),
            Text(
              'GSAP durations use the time scale (${motion.timeScale.toStringAsFixed(2)}x), CSS durations the speed, fixed ones ignore both. Click a graph to replay it.',
              style: theme.text(size: GhTextSize.x3s, color: theme.muted, mono: true),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final spec in _eases) _EaseCard(spec: spec, run: _run, loop: _loop)],
        ),
      ],
    );
  }
}

class _EaseCard extends StatefulWidget {
  const _EaseCard({required this.spec, required this.run, required this.loop});

  final _EaseSpec spec;
  final int run;
  final bool loop;

  @override
  State<_EaseCard> createState() => _EaseCardState();
}

class _EaseCardState extends State<_EaseCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)..addStatusListener(_status);
  Timer? _again;

  @override
  void didUpdateWidget(_EaseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.run != oldWidget.run || (widget.loop && !oldWidget.loop)) {
      _play();
    }
    if (!widget.loop) {
      _again?.cancel();
    }
  }

  void _status(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.loop) {
      _again?.cancel();
      _again = Timer(const Duration(milliseconds: 700), () {
        if (mounted && widget.loop) {
          _play();
        }
      });
    }
  }

  void _play() {
    _again?.cancel();
    final duration = widget.spec.duration(GhMotion.of(context));
    _controller.duration = duration.inMicroseconds <= 0 ? const Duration(microseconds: 1) : duration;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _again?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final spec = widget.spec;
    final actual = spec.duration(GhMotion.of(context));
    final ms = (actual.inMicroseconds / 1000).round();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _play,
        child: Container(
          width: 196,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.raised,
            border: Border.all(color: theme.outline),
            borderRadius: BorderRadius.circular(theme.radiusTile),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.name,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${spec.spec}\n${spec.clockLabel} ${(spec.seconds * 1000).round()} ms, plays $ms ms',
                style: theme.text(size: GhTextSize.x4s, color: theme.muted, mono: true),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 176,
                height: 116,
                child: CustomPaint(
                  painter: _EasePainter(
                    curve: spec.curve,
                    progress: _controller,
                    grid: theme.line,
                    stroke: theme.accent,
                    dot: theme.accentBright,
                    track: theme.outline,
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

class _EasePainter extends CustomPainter {
  _EasePainter({
    required this.curve,
    required this.progress,
    required this.grid,
    required this.stroke,
    required this.dot,
    required this.track,
  }) : super(repaint: progress);

  final Curve curve;
  final Animation<double> progress;
  final Color grid;
  final Color stroke;
  final Color dot;
  final Color track;

  static const _samples = 240;
  static const _trackHeight = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = 0.0;
    var hi = 1.0;
    final values = <double>[];
    for (var i = 0; i <= _samples; i++) {
      final v = curve.transform(i / _samples);
      values.add(v);
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
    final graph = Rect.fromLTWH(6, 6, size.width - 12, size.height - _trackHeight - 16);
    double gx(double t) => graph.left + t * graph.width;
    double gy(double v) => graph.bottom - (v - lo) / (hi - lo) * graph.height;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(graph.left, gy(0)), Offset(graph.right, gy(0)), gridPaint)
      ..drawLine(Offset(graph.left, gy(1)), Offset(graph.right, gy(1)), gridPaint)
      ..drawLine(Offset(graph.left, graph.top), Offset(graph.left, graph.bottom), gridPaint)
      ..drawLine(Offset(graph.right, graph.top), Offset(graph.right, graph.bottom), gridPaint);
    final path = Path()..moveTo(gx(0), gy(values.first));
    for (var i = 1; i <= _samples; i++) {
      path.lineTo(gx(i / _samples), gy(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final t = progress.value;
    final v = curve.transform(t.clamp(0.0, 1.0));
    final dotPaint = Paint()..color = dot;
    canvas.drawCircle(Offset(gx(t), gy(v)), 4, dotPaint);
    final trackY = size.height - _trackHeight / 2 - 2;
    double tx(double value) => graph.left + (value - lo) / (hi - lo) * graph.width;
    canvas
      ..drawLine(
        Offset(graph.left, trackY),
        Offset(graph.right, trackY),
        Paint()
          ..color = track
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(Offset(tx(0), trackY - 5), Offset(tx(0), trackY + 5), gridPaint)
      ..drawLine(Offset(tx(1), trackY - 5), Offset(tx(1), trackY + 5), gridPaint)
      ..drawCircle(Offset(tx(v), trackY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(_EasePainter oldDelegate) =>
      oldDelegate.curve != curve ||
      oldDelegate.grid != grid ||
      oldDelegate.stroke != stroke ||
      oldDelegate.dot != dot ||
      oldDelegate.track != track;
}
