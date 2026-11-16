import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../api/templates.dart';
import '../api/vault.dart';
import '../api/workspaces.dart';
import '../design/design.dart';
import '../motion/intro.dart';
import '../motion/motion.dart';
import '../motion/tween.dart';
import '../onboarding/welcome_intro.dart';
import '../titlebar/providers.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';

const flutterWelcomeSeenKey = 'godothub_flutter_welcome_seen';

enum FlutterWelcomeStart { show, markSeen, skip }

FlutterWelcomeStart flutterWelcomeStart({required String channel, required bool setupComplete, required String? seen}) {
  if (channel != 'stable' || seen != null) return FlutterWelcomeStart.skip;
  return setupComplete ? FlutterWelcomeStart.show : FlutterWelcomeStart.markSeen;
}

class FlutterWelcomeCounts {
  const FlutterWelcomeCounts({this.projects, this.workspaces, this.templates, this.vaultItems});

  final int? projects;
  final int? workspaces;
  final int? templates;
  final int? vaultItems;

  static Future<int?> _count(Future<int> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  static Future<FlutterWelcomeCounts> load({required bool workspacesEnabled}) async {
    final results = await Future.wait([
      _count(() async => (await ProjectsApi.list()).length),
      workspacesEnabled ? _count(() async => (await WorkspacesApi.list()).workspaces.length) : Future<int?>.value(),
      _count(() async => (await TemplatesApi.list()).length),
      _count(() async => (await VaultApi.list()).length),
    ]);
    return FlutterWelcomeCounts(projects: results[0], workspaces: results[1], templates: results[2], vaultItems: results[3]);
  }
}

class FlutterWelcomeModal extends ConsumerStatefulWidget {
  const FlutterWelcomeModal({super.key, required this.counts, required this.onContinue, required this.onChangelog});

  final FlutterWelcomeCounts counts;
  final VoidCallback onContinue;
  final VoidCallback onChangelog;

  @override
  ConsumerState<FlutterWelcomeModal> createState() => _FlutterWelcomeModalState();
}

class _FlutterWelcomeModalState extends ConsumerState<FlutterWelcomeModal> with TickerProviderStateMixin {
  late final GhWelcomeIntroTimeline _intro = GhWelcomeIntroTimeline(vsync: this, letters: welcomeWordmark.length);
  bool _rings = false;
  bool _started = false;

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
    super.dispose();
  }

  List<_Count> get _counts => [
    if (widget.counts.projects case final n? when n > 0) _Count(GhIcons.folder, ghTr('flutter_welcome_projects', count: n)),
    if (widget.counts.workspaces case final n? when n > 0) _Count(GhIcons.layoutGrid, ghTr('flutter_welcome_workspaces', count: n)),
    if (widget.counts.templates case final n? when n > 0) _Count(GhIcons.rocket, ghTr('flutter_welcome_templates', count: n)),
    if (widget.counts.vaultItems case final n? when n > 0) _Count(GhIcons.briefcase, ghTr('flutter_welcome_vault_items', count: n)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.rem(4.5);
    final word = theme
        .text(size: GhTextSize.base, weight: FontWeight.w900, color: theme.ink, lineHeight: 1)
        .copyWith(fontSize: size, letterSpacing: -0.025 * size);
    final window = ref.watch(titleBarWindowProvider);
    final counts = _counts;
    final highlights = [
      _Highlight(GhIcons.stopwatch, ghTr('flutter_welcome_fast_title'), ghTr('flutter_welcome_fast_desc')),
      _Highlight(GhIcons.cloudArrowDown, ghTr('flutter_welcome_updates_title'), ghTr('flutter_welcome_updates_desc')),
      _Highlight(GhIcons.palette, ghTr('flutter_welcome_design_title'), ghTr('flutter_welcome_design_desc')),
      _Highlight(GhIcons.circleCheck, ghTr('flutter_welcome_data_title'), ghTr('flutter_welcome_data_desc')),
    ];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onContinue,
        const SingleActivator(LogicalKeyboardKey.enter): widget.onContinue,
      },
      child: GhMagneticArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
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
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: theme.space(6), vertical: theme.space(10)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: theme.rem(46)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GhPoseTransition(
                        animation: _intro.eyebrow,
                        from: GhWelcomeIntroPoses.eyebrow,
                        child: ExcludeSemantics(
                          child: Text(
                            ghTr('flutter_welcome_eyebrow'),
                            textAlign: TextAlign.center,
                            style: theme.text(size: GhTextSize.base, weight: GhWeight.semibold, color: theme.accentBright),
                          ),
                        ),
                      ),
                      SizedBox(height: theme.space(4)),
                      GhLetterRow(
                        text: welcomeWordmark,
                        style: word,
                        animations: _intro.letters,
                        perspective: 800,
                        semanticLabel: ghTr('flutter_welcome_title'),
                      ),
                      SizedBox(height: theme.space(4)),
                      GhPoseTransition(
                        animation: _intro.line,
                        from: GhWelcomeIntroPoses.line,
                        child: Container(
                          width: theme.space(24),
                          height: 3,
                          decoration: BoxDecoration(color: theme.accentBright, borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      SizedBox(height: theme.space(6)),
                      GhPoseTransition(
                        animation: _intro.desc,
                        from: GhWelcomeIntroPoses.desc,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: theme.rem(34)),
                              child: Text(
                                ghTr('flutter_welcome_desc'),
                                textAlign: TextAlign.center,
                                style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                              ),
                            ),
                            SizedBox(height: theme.space(7)),
                            _HighlightGrid(highlights: highlights),
                            if (counts.isNotEmpty) ...[SizedBox(height: theme.space(6)), _DataSummary(counts: counts)],
                          ],
                        ),
                      ),
                      SizedBox(height: theme.space(8)),
                      GhPoseTransition(
                        animation: _intro.cta,
                        from: GhWelcomeIntroPoses.cta,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: theme.space(3),
                          runSpacing: theme.space(3),
                          children: [
                            GhButton(
                              key: const ValueKey('flutter-welcome-changelog'),
                              onPressed: widget.onChangelog,
                              label: ghTr('flutter_welcome_changelog'),
                              variant: GhButtonVariant.outline,
                              paddingY: 3,
                            ),
                            GhMagnet(
                              child: GhRingPulse(
                                running: _rings,
                                color: theme.accentBright,
                                radius: theme.radiusBtn,
                                child: GhButton(
                                  key: const ValueKey('flutter-welcome-continue'),
                                  onPressed: widget.onContinue,
                                  label: ghTr('flutter_welcome_continue'),
                                  variant: GhButtonVariant.primary,
                                  autofocus: true,
                                  paddingX: 6,
                                  paddingY: 3,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _Highlight {
  const _Highlight(this.icon, this.title, this.description);

  final FaIconData icon;
  final String title;
  final String description;
}

class _Count {
  const _Count(this.icon, this.label);

  final FaIconData icon;
  final String label;
}

class _HighlightGrid extends StatelessWidget {
  const _HighlightGrid({required this.highlights});

  final List<_Highlight> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final gap = theme.space(3);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= theme.rem(36) ? 2 : 1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [
            for (var i = 0; i < highlights.length; i += columns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: gap,
                  children: [
                    for (final h in highlights.skip(i).take(columns))
                      Expanded(
                        child: _HighlightCard(highlight: h, siblings: highlights),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight, required this.siblings});

  final _Highlight highlight;
  final List<_Highlight> siblings;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(3),
        children: [
          Container(
            width: theme.space(9),
            height: theme.space(9),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: theme.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(theme.radiusMd)),
            child: GhIcon(highlight.icon, size: theme.space(4), color: theme.accentBright),
          ),
          Expanded(
            child: Stack(
              children: [
                for (final other in siblings)
                  Visibility(
                    visible: identical(other, highlight),
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: theme.space(1),
                      children: [
                        Text(
                          other.title,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                        ),
                        Text(
                          other.description,
                          style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.5),
                        ),
                      ],
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

class _DataSummary extends StatelessWidget {
  const _DataSummary({required this.counts});

  final List<_Count> counts;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.space(3),
      children: [
        Text(
          ghTr('flutter_welcome_summary'),
          textAlign: TextAlign.center,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.1),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: theme.space(2),
          runSpacing: theme.space(2),
          children: [
            for (final c in counts)
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                decoration: BoxDecoration(
                  color: theme.raised,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(2),
                  children: [
                    GhIcon(c.icon, size: theme.space(3.5), color: theme.accentBright),
                    Text(
                      c.label,
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
