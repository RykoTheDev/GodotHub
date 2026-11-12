import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../motion/drag_feel.dart';
import '../../../motion/intro.dart';
import '../../../motion/motion.dart';
import '../../../motion/reveal.dart';
import '../../../motion/shared_ticker.dart';
import '../../../motion/tween.dart';
import '../../../ui/core/button.dart';
import '../../../ui/core/interaction.dart';
import '../../../ui/splash/splash_screen.dart';
import '../gallery_kit.dart';

final motionRevealSections = <GallerySection>[
  GallerySection('Reveal', (context) => const _RevealDemo()),
  GallerySection('Scroll reveal', (context) => const _ScrollRevealDemo()),
  GallerySection('Shell intro', (context) => const _ShellIntroDemo()),
  GallerySection('Splash', (context) => const _SplashDemo()),
  GallerySection('Welcome intro', (context) => const _WelcomeDemo()),
  GallerySection('Interactions', (context) => const _InteractionsDemo()),
  GallerySection('Drag feel and ticker', (context) => const _DragDemo()),
];

class _Frame extends StatelessWidget {
  const _Frame({required this.width, required this.height, required this.child});

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.base,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.line),
      ),
      child: child,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.subtitle, this.width, this.height});

  final String title;
  final String? subtitle;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(theme.space(3)),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusCard),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold),
          ),
          if (subtitle != null) ...[
            SizedBox(height: theme.space(1)),
            Text(
              subtitle!,
              style: theme.text(size: GhTextSize.xs, color: theme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index, this.label});

  final int index;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.space(1.5)),
      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: theme.accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(theme.radiusTile)),
            alignment: Alignment.center,
            child: GhIcon(GhIcons.folder, size: 12, color: theme.accentBright),
          ),
          SizedBox(width: theme.space(3)),
          Expanded(
            child: Text(
              label ?? 'Project ${index + 1}',
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium),
            ),
          ),
          Text(
            '4.${index % 5}',
            style: theme.text(size: GhTextSize.xs, color: theme.muted, mono: true),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: GhLiveReveal.listenable,
      builder: (context, live, _) => Text(
        live ? 'Live reveal is on' : 'Live reveal is off until a shell intro finishes',
        style: theme.text(size: GhTextSize.xs, color: theme.muted),
      ),
    );
  }
}

class _RevealDemo extends StatefulWidget {
  const _RevealDemo();

  @override
  State<_RevealDemo> createState() => _RevealDemoState();
}

class _RevealDemoState extends State<_RevealDemo> {
  int _replay = 0;
  int _added = 0;
  bool _many = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rows = _many ? 30 : 6;
    final threshold = GhMotion.of(context).prefs.threshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GhButton(onPressed: () => setState(() => _replay += 1), label: 'Replay view reveal', variant: GhButtonVariant.primary),
            GhButton(onPressed: () => setState(() => _added += 1), label: 'Add a row', variant: GhButtonVariant.outline),
            GhButton(onPressed: GhLiveReveal.enable, label: 'Enable live reveal', variant: GhButtonVariant.outline),
            GhButton(
              onPressed: () => setState(() => _many = !_many),
              label: _many ? 'Use 6 project rows' : 'Use 30 project rows (over threshold $threshold)',
              variant: GhButtonVariant.outline,
            ),
            const _LiveBadge(),
          ],
        ),
        SizedBox(height: theme.space(4)),
        GhRevealScope(
          replay: _replay,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GhReveal(
                kind: GhRevealKind.heading,
                child: Text(
                  'Projects',
                  style: theme.text(size: GhTextSize.x2l, weight: GhWeight.bold),
                ),
              ),
              SizedBox(height: theme.space(3)),
              SizedBox(
                width: 560,
                child: Column(
                  children: [
                    for (var i = 0; i < rows; i++)
                      GhReveal(
                        projectId: 'p$i',
                        child: _Row(index: i),
                      ),
                    for (var i = 0; i < _added; i++)
                      GhReveal(
                        key: ValueKey('added$i'),
                        child: _Row(index: i, label: 'Added row ${i + 1}'),
                      ),
                  ],
                ),
              ),
              SizedBox(height: theme.space(4)),
              GhReveal(
                kind: GhRevealKind.heading,
                child: Text(
                  'Tiles',
                  style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold),
                ),
              ),
              SizedBox(height: theme.space(3)),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < 10; i++)
                    GhReveal(
                      kind: GhRevealKind.tile,
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.12 + i * 0.05),
                          borderRadius: BorderRadius.circular(theme.radiusTile),
                        ),
                        child: GhIcon(GhIcons.star, size: 18, color: theme.accentBright),
                      ),
                    ),
                ],
              ),
              SizedBox(height: theme.space(4)),
              GhReveal(
                kind: GhRevealKind.heading,
                child: Text(
                  'Cards',
                  style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold),
                ),
              ),
              SizedBox(height: theme.space(3)),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < 6; i++)
                    GhReveal(
                      child: _Card(title: 'Card ${i + 1}', subtitle: 'Slide, fade or scale per entrance', width: 180),
                    ),
                  GhReveal(
                    kind: GhRevealKind.fade,
                    child: const _Card(title: 'Fade only', subtitle: 'kind: fade', width: 180),
                  ),
                  GhReveal(
                    ownOpacity: true,
                    child: Opacity(
                      opacity: 0.6,
                      child: const _Card(title: 'Own opacity', subtitle: 'Keeps its opacity', width: 180),
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

class _ScrollRevealDemo extends StatefulWidget {
  const _ScrollRevealDemo();

  @override
  State<_ScrollRevealDemo> createState() => _ScrollRevealDemoState();
}

class _ScrollRevealDemoState extends State<_ScrollRevealDemo> {
  int _replay = 0;

  @override
  void initState() {
    super.initState();
    GhLiveReveal.enable();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GhButton(onPressed: () => setState(() => _replay += 1), label: 'Replay', variant: GhButtonVariant.primary),
            Text(
              'Rows below the fold stay hidden and reveal as they scroll in. Turn scroll reveal off to show them at once.',
              style: theme.text(size: GhTextSize.xs, color: theme.muted),
            ),
          ],
        ),
        SizedBox(height: theme.space(4)),
        GalleryGroup(
          title: 'Lazy list in its own scroll view',
          children: [
            _Frame(
              width: 560,
              height: 420,
              child: GhRevealScope(
                key: ValueKey('lazy$_replay'),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: 80,
                  itemBuilder: (context, i) => GhReveal(
                    id: i,
                    child: _Row(index: i),
                  ),
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Long column scrolled by the gallery page',
          children: [
            SizedBox(
              width: 560,
              child: GhRevealScope(
                key: ValueKey('column$_replay'),
                child: Column(
                  children: [
                    for (var i = 0; i < 40; i++)
                      GhReveal(
                        child: _Row(index: i, label: 'Page row ${i + 1}'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShellIntroDemo extends StatefulWidget {
  const _ShellIntroDemo();

  @override
  State<_ShellIntroDemo> createState() => _ShellIntroDemoState();
}

class _ShellIntroDemoState extends State<_ShellIntroDemo> {
  int _replay = 0;
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    const tabs = ['Dashboard', 'Projects', 'Versions', 'Templates', 'Asset store', 'News', 'Vault', 'Tools', 'Settings'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GhButton(onPressed: () => setState(() => _replay += 1), label: 'Replay shell intro', variant: GhButtonVariant.primary),
        SizedBox(height: theme.space(4)),
        _Frame(
          width: 760,
          height: 400,
          child: GhShellIntro(
            replay: _replay,
            child: Column(
              children: [
                GhIntroTitleBar(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                    color: theme.raised,
                    child: Row(
                      children: [
                        GhIntroPart(
                          child: Text(
                            'GodotHub',
                            style: theme.text(
                              size: GhTextSize.lg,
                              weight: FontWeight.w900,
                              color: theme.ink.withValues(alpha: 0.5),
                              lineHeight: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GhIntroPart(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.mint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(theme.radiusItem),
                            ),
                            child: Text(
                              '2 running',
                              style: theme.text(size: GhTextSize.x2s, color: theme.mint, weight: GhWeight.semibold),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GhIntroPart(
                          child: Row(
                            children: [
                              for (final icon in [GhIcons.bookOpen, GhIcons.star, GhIcons.bug, GhIcons.language])
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: GhIcon(icon, size: 13, color: theme.muted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GhIntroSidebar(
                        child: Container(
                          width: 190,
                          color: theme.surface,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < tabs.length; i++)
                                GhPressable(
                                  onPressed: () => setState(() => _active = i),
                                  borderRadius: BorderRadius.circular(theme.radiusItem),
                                  builder: (context, states) => GhAnimatedBox(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    color: i == _active
                                        ? theme.accent.withValues(alpha: 0.15)
                                        : (states.hovered ? theme.raised : theme.raised.withValues(alpha: 0)),
                                    borderRadius: BorderRadius.circular(theme.radiusItem),
                                    child: Text(
                                      tabs[i],
                                      style: theme.text(
                                        size: GhTextSize.xs,
                                        weight: GhWeight.medium,
                                        color: i == _active ? theme.ink : theme.muted,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GhRevealScope(
                          replay: _replay,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GhReveal(
                                  kind: GhRevealKind.heading,
                                  child: Text(
                                    tabs[_active],
                                    style: theme.text(size: GhTextSize.xl, weight: GhWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                for (var i = 0; i < 4; i++) GhReveal(child: _Row(index: i)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashDemo extends StatefulWidget {
  const _SplashDemo();

  @override
  State<_SplashDemo> createState() => _SplashDemoState();
}

class _SplashDemoState extends State<_SplashDemo> {
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GhButton(onPressed: () => setState(() => _replay += 1), label: 'Replay splash', variant: GhButtonVariant.primary),
        SizedBox(height: theme.space(4)),
        _Frame(width: 720, height: 405, child: GhSplashScreen(key: ValueKey(_replay))),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = size.longestSide / 2;
    for (var x = 0.0; x < size.width; x += 28) {
      for (var y = 0.0; y < size.height; y += 28) {
        final d = (Offset(x, y) - center).distance / reach;
        final fade = d < 0.3 ? 1.0 : (d > 0.75 ? 0.0 : 1 - (d - 0.3) / 0.45);
        if (fade <= 0) {
          continue;
        }
        canvas.drawCircle(Offset(x + 1, y + 1), 1, Paint()..color = color.withValues(alpha: color.a * fade));
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.color != color;
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      rippleColor: Colors.white,
      builder: (context, states) => GhAnimatedBox(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: Alignment.center,
        color: states.hovered ? theme.accentBright : theme.accent,
        borderRadius: radius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dive in',
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const GhIcon(GhIcons.chevronRight, size: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _WelcomeDemo extends StatefulWidget {
  const _WelcomeDemo();

  @override
  State<_WelcomeDemo> createState() => _WelcomeDemoState();
}

class _WelcomeDemoState extends State<_WelcomeDemo> {
  int _replay = 0;
  int _letters = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final wordStyle = theme
        .text(size: GhTextSize.base, weight: FontWeight.w900, lineHeight: 1)
        .copyWith(fontSize: theme.rem(3), letterSpacing: -0.025 * theme.rem(3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Letter rise',
          children: [
            GhLetterRise(text: 'GodotHub', style: wordStyle, duration: 1, stagger: 0.05, perspective: 800, replay: _letters),
            GhButton(onPressed: () => setState(() => _letters += 1), label: 'Replay letters', variant: GhButtonVariant.outline),
          ],
        ),
        GalleryGroup(
          title: 'Ring pulse and magnetic button',
          children: [
            _Frame(
              width: 420,
              height: 200,
              child: GhMagneticArea(
                child: Center(
                  child: GhMagnet(
                    child: GhRingPulse(
                      color: theme.accentBright,
                      radius: theme.radiusBtn,
                      child: _CtaButton(onPressed: () {}),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Entrance timeline',
          children: [
            GhButton(onPressed: () => setState(() => _replay += 1), label: 'Replay welcome intro', variant: GhButtonVariant.primary),
            _Frame(width: 760, height: 440, child: _WelcomeStage(key: ValueKey(_replay))),
          ],
        ),
      ],
    );
  }
}

class _WelcomeStage extends StatefulWidget {
  const _WelcomeStage({super.key});

  @override
  State<_WelcomeStage> createState() => _WelcomeStageState();
}

class _WelcomeStageState extends State<_WelcomeStage> with SingleTickerProviderStateMixin {
  static const _word = 'GodotHub';
  late final GhWelcomeIntroTimeline _intro = GhWelcomeIntroTimeline(vsync: this, letters: _word.length);
  bool _rings = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final motion = GhMotion.of(context);
    if (motion.off) {
      _intro.timeline.finish();
      return;
    }
    _intro.play(motion).then((_) {
      if (mounted && _intro.timeline.controller.isCompleted) {
        setState(() => _rings = true);
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.rem(4.5);
    final word = theme
        .text(size: GhTextSize.base, weight: FontWeight.w900, lineHeight: 1)
        .copyWith(fontSize: size, letterSpacing: -0.025 * size);
    return GhMagneticArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          GhPoseTransition(
            animation: _intro.grid,
            from: GhWelcomeIntroPoses.grid,
            child: Opacity(opacity: 0.07, child: CustomPaint(painter: _DotGridPainter(theme.ink))),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GhPoseTransition(
                  animation: _intro.eyebrow,
                  from: GhWelcomeIntroPoses.eyebrow,
                  child: Text(
                    'WELCOME TO',
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.accentBright, letterSpacingEm: 0.3),
                  ),
                ),
                const SizedBox(height: 16),
                GhLetterRow(text: _word, style: word, animations: _intro.letters, perspective: 800),
                const SizedBox(height: 16),
                GhPoseTransition(
                  animation: _intro.line,
                  from: GhWelcomeIntroPoses.line,
                  child: Container(
                    width: 96,
                    height: 3,
                    decoration: BoxDecoration(color: theme.accentBright, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 28),
                GhPoseTransition(
                  animation: _intro.desc,
                  from: GhWelcomeIntroPoses.desc,
                  child: SizedBox(
                    width: 420,
                    child: Text(
                      'Manage Godot versions, projects and templates in one place.',
                      textAlign: TextAlign.center,
                      style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                GhPoseTransition(
                  animation: _intro.cta,
                  from: GhWelcomeIntroPoses.cta,
                  child: GhMagnet(
                    child: GhRingPulse(
                      running: _rings,
                      color: theme.accentBright,
                      radius: theme.radiusBtn,
                      child: _CtaButton(onPressed: () {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionsDemo extends StatefulWidget {
  const _InteractionsDemo();

  @override
  State<_InteractionsDemo> createState() => _InteractionsDemoState();
}

class _InteractionsDemoState extends State<_InteractionsDemo> {
  int _spin = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Press any button for the scale and ripple. Tab to a button and press Enter or Space for the keyboard pulse.',
          style: theme.text(size: GhTextSize.xs, color: theme.muted),
        ),
        SizedBox(height: theme.space(4)),
        GalleryGroup(
          title: 'Press scale by width',
          children: [
            GalleryItem(
              label: 'up to 90px: 0.88',
              child: GhButton(onPressed: () {}, icon: GhIcons.plus, variant: GhButtonVariant.outline),
            ),
            GalleryItem(
              label: 'up to 90px: 0.88',
              child: GhButton(onPressed: () {}, label: 'Save', variant: GhButtonVariant.primary),
            ),
            GalleryItem(
              label: '90 to 260px: 0.955',
              child: GhButton(onPressed: () {}, label: 'Open project folder', icon: GhIcons.folder, variant: GhButtonVariant.outline),
            ),
            GalleryItem(
              label: 'over 260px: 0.985',
              child: SizedBox(
                width: 320,
                child: GhButton(onPressed: () {}, label: 'Create a new project', expand: true, variant: GhButtonVariant.primary),
              ),
            ),
            GalleryItem(
              label: 'no ripple',
              child: GhNoRipple(
                child: GhButton(onPressed: () {}, label: 'No ripple', variant: GhButtonVariant.outline),
              ),
            ),
            GalleryItem(
              label: 'disabled',
              child: GhButton(onPressed: null, label: 'Disabled', variant: GhButtonVariant.outline),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Card tilt',
          children: [
            GalleryItem(
              label: 'tilts toward the pointer',
              child: GhTiltCard(
                borderRadius: BorderRadius.circular(theme.radiusCard),
                child: const _Card(title: 'Project card', subtitle: 'Hover to tilt, press to squash', width: 300, height: 150),
              ),
            ),
            GalleryItem(
              label: 'wide card, weaker tilt',
              child: GhTiltCard(
                borderRadius: BorderRadius.circular(theme.radiusCard),
                child: const _Card(title: 'Wide card', subtitle: 'Strength is min(7, 2400 / width)', width: 520, height: 120),
              ),
            ),
            GalleryItem(
              label: 'under 120px: no tilt',
              child: GhTiltCard(
                borderRadius: BorderRadius.circular(theme.radiusCard),
                child: const _Card(title: 'Small', width: 110, height: 80),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Spin',
          children: [
            GhPressable(
              onPressed: () => setState(() => _spin += 1),
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              semanticLabel: 'Refresh',
              builder: (context, states) => GhAnimatedBox(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                color: states.hovered ? theme.raised : theme.surface,
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                border: Border.all(color: theme.line),
                child: GhSpin(
                  trigger: _spin,
                  child: GhIcon(GhIcons.refresh, size: 14, color: theme.ink),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DragDemo extends StatefulWidget {
  const _DragDemo();

  @override
  State<_DragDemo> createState() => _DragDemoState();
}

class _DragDemoState extends State<_DragDemo> {
  bool _lifted = false;
  int _lift = 0;
  bool _ticking = true;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final constants = {
      'activationDistance': '${GhDragFeel.activationDistance}px',
      'ghostOpacity': '${GhDragFeel.ghostOpacity}',
      'reflow': '${GhDragFeel.reflow.duration.inMilliseconds}ms cubic-bezier(0.22, 1, 0.36, 1)',
      'drop': '${GhDragFeel.drop.duration.inMilliseconds}ms cubic-bezier(0.22, 1, 0.36, 1)',
      'lift.scale': '${GhDragFeel.liftScale}',
      'dropLine': 'height ${GhDragFeel.dropLine.height}, dot ${GhDragFeel.dropLine.dot}, glow ${GhDragFeel.dropLine.glow}',
      'autoScroll':
          'threshold ${GhDragFeel.autoScroll.thresholdX} x ${GhDragFeel.autoScroll.thresholdY}, acceleration ${GhDragFeel.autoScroll.acceleration}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Drag lift',
          children: [
            GhButton(
              onPressed: () => setState(() {
                _lifted = !_lifted;
                _lift += 1;
              }),
              label: _lifted ? 'Drop' : 'Lift',
              variant: GhButtonVariant.primary,
            ),
            GalleryItem(
              label: 'source (ghost while dragging)',
              child: GhDragGhost(
                ghost: _lifted,
                child: const _Card(title: 'Project card', width: 220),
              ),
            ),
            GalleryItem(
              label: 'overlay (drag-lift keyframe)',
              child: _lifted
                  ? GhDragLift(
                      replay: _lift,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(theme.radiusCard),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: const _Card(title: 'Project card', width: 220),
                      ),
                    )
                  : const SizedBox(width: 220, height: 44),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Drag constants',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in constants.entries)
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
                  ),
              ],
            ),
          ],
        ),
        GalleryGroup(
          title: 'Shared ticker',
          children: [
            GhNow(
              active: _ticking,
              builder: (context, now) => Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                style: theme.text(size: GhTextSize.lg, mono: true),
              ),
            ),
            GhButton(
              onPressed: () => setState(() => _ticking = !_ticking),
              label: _ticking ? 'Pause' : 'Resume',
              variant: GhButtonVariant.outline,
            ),
          ],
        ),
      ],
    );
  }
}
