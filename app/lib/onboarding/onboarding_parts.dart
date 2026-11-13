import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../design/design.dart';
import '../modals/git_auth_modal.dart';
import '../modals/restore_progress_modal.dart';
import '../motion/animated_number.dart';
import '../motion/ease.dart';
import '../motion/motion.dart';
import '../motion/tween.dart';
import '../src/rust/api/events.dart' show ScanProgress;
import '../src/rust/api/types.dart';
import '../state/workspaces.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/spin.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/shell/workspace_form.dart';
import 'mini_app_preview.dart';
import '../ui/shell/smooth_scroll.dart';

String _to(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('onboarding:$key', count: count, args: args);

class StepShell extends StatelessWidget {
  const StepShell({super.key, required this.icon, required this.title, required this.description, required this.child, this.wide = false});

  final FaIconData icon;
  final String title;
  final String description;
  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: theme.rem(wide ? 48 : 36)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(6),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(4),
            children: [
              Container(
                width: theme.space(11),
                height: theme.space(11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.radiusTile),
                  border: Border.all(color: theme.accentDim.withValues(alpha: 0.3)),
                ),
                child: GhIcon(icon, size: theme.space(5), color: theme.accentBright),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.text(size: GhTextSize.x2l, weight: GhWeight.semibold, color: theme.ink, letterSpacingEm: -0.025),
                      ),
                    ),
                    SizedBox(height: theme.space(1.5)),
                    Text(
                      description,
                      style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class ProgressRow extends StatelessWidget {
  const ProgressRow({super.key, required this.label, required this.progress, required this.running});

  final String label;
  final ScanProgress? progress;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final p = progress;
    final hasProgress = p != null && p.total > 0;
    final pct = hasProgress ? math.min(p.current / p.total, 1.0) : 0.0;
    final mono = theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
      decoration: _rowBox(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.text(size: GhTextSize.xs, color: theme.muted),
                ),
              ),
              if (hasProgress)
                Text('${p.current} / ${p.total}', style: mono)
              else if (running)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    GhSpinning(
                      child: GhIcon(GhIcons.refresh, size: theme.space(3), color: theme.accentBright),
                    ),
                    Text(
                      '…',
                      style: theme.text(size: GhTextSize.xs, mono: true, color: theme.accentBright),
                    ),
                  ],
                )
              else
                Text(ghTr('none'), style: mono),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: theme.space(1.5),
              color: theme.line.withValues(alpha: 0.4),
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: GhMotion.of(context).css(GhDurations.progress),
                curve: GhCurves.outExpo,
                widthFactor: hasProgress ? pct : (running ? 0.3 : 0),
                heightFactor: 1,
                child: GhAnimatedBox(
                  duration: GhDurations.progress,
                  color: hasProgress ? theme.accent : theme.accent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _rowBox(GhTheme theme) => BoxDecoration(
  color: theme.overlay,
  borderRadius: BorderRadius.circular(theme.radiusItem),
  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
);

Widget sectionCaps(GhTheme theme, String text, {double inset = 0}) => Padding(
  padding: EdgeInsets.symmetric(horizontal: inset),
  child: Text(
    text.toUpperCase(),
    style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted.withValues(alpha: 0.7), letterSpacingEm: 0.025),
  ),
);

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
      decoration: _rowBox(theme),
      child: Row(
        spacing: theme.space(4),
        children: [
          Text(
            label,
            style: theme.text(size: GhTextSize.xs, color: theme.muted),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DefaultTextStyle.merge(
                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                child: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        sectionCaps(theme, title, inset: theme.space(1)),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(1.5), children: children),
      ],
    );
  }
}

@immutable
class DiscoveryRow {
  const DiscoveryRow({required this.key, required this.primary, this.secondary, this.badges = const []});

  final String key;
  final String primary;
  final String? secondary;
  final List<String> badges;
}

class DiscoveryList extends StatelessWidget {
  const DiscoveryList({
    super.key,
    required this.heading,
    required this.rows,
    required this.selected,
    required this.imported,
    required this.busy,
    required this.onToggle,
    required this.onAdd,
    required this.addLabel,
    this.loading = false,
    this.loadingLabel,
    this.hint,
  });

  final String heading;
  final List<DiscoveryRow> rows;
  final Set<String> selected;
  final Set<String> imported;
  final bool busy;
  final ValueChanged<String> onToggle;
  final VoidCallback onAdd;
  final String Function(int count) addLabel;
  final bool loading;
  final String? loadingLabel;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    if (loading && rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(1.5),
        children: [
          sectionCaps(theme, heading),
          Container(
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: theme.line.withValues(alpha: 0.6)),
            ),
            child: Row(
              spacing: theme.space(2),
              children: [
                GhSpinning(
                  child: GhIcon(GhIcons.refresh, size: theme.space(3), color: theme.muted),
                ),
                Expanded(
                  child: Text(
                    loadingLabel ?? '',
                    style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    final selectable = rows.where((r) => selected.contains(r.key) && !imported.contains(r.key)).length;
    final radius = BorderRadius.circular(theme.radiusItem);
    final btnRadius = BorderRadius.circular(theme.radiusBtn);
    final hint = this.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        sectionCaps(theme, heading),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: theme.space(56)),
          child: GhScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1),
              children: [
                for (final r in rows)
                  Builder(
                    key: ValueKey(r.key),
                    builder: (context) {
                      final isImported = imported.contains(r.key);
                      return Opacity(
                        opacity: isImported ? 0.6 : 1,
                        child: GhPressable(
                          onPressed: isImported ? null : () => onToggle(r.key),
                          checked: isImported || selected.contains(r.key),
                          semanticLabel: r.primary,
                          disabledOpacity: 1,
                          borderRadius: radius,
                          builder: (context, states) => GhAnimatedBox(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                            color: states.active ? theme.raised.withValues(alpha: 0.4) : theme.base.withValues(alpha: 0.4),
                            borderRadius: radius,
                            border: Border.all(color: theme.line.withValues(alpha: 0.6)),
                            child: Row(
                              spacing: theme.space(2.5),
                              children: [
                                ExcludeSemantics(
                                  child: GhCheckbox(
                                    checked: isImported || selected.contains(r.key),
                                    disabled: isImported,
                                    onChanged: (_) => onToggle(r.key),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.primary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.text(size: GhTextSize.xs, color: theme.ink),
                                      ),
                                      if (r.secondary != null)
                                        Text(
                                          r.secondary!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                                        ),
                                    ],
                                  ),
                                ),
                                for (final badge in r.badges)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
                                    decoration: BoxDecoration(
                                      color: theme.overlay,
                                      borderRadius: BorderRadius.circular(theme.radiusSm),
                                      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      badge,
                                      style: theme.text(size: GhTextSize.x4s, weight: GhWeight.semibold, color: theme.muted),
                                    ),
                                  ),
                                if (isImported) GhIcon(GhIcons.check, size: theme.space(3.5), color: theme.accent),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GhPressable(
            onPressed: busy || selectable == 0 ? null : onAdd,
            borderRadius: btnRadius,
            rippleColor: Colors.white,
            builder: (context, states) => GhAnimatedBox(
              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
              color: states.active ? theme.accentBright : theme.accent,
              borderRadius: btnRadius,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(1.5),
                children: [
                  if (busy)
                    GhSpinning(
                      child: GhIcon(GhIcons.refresh, size: theme.space(3), color: Colors.white),
                    )
                  else
                    GhIcon(GhIcons.plus, size: theme.space(3), color: Colors.white),
                  Text(
                    addLabel(selectable),
                    style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hint != null)
          Text(
            hint,
            style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.625),
          ),
      ],
    );
  }
}

class PathSuggestionChips extends StatelessWidget {
  const PathSuggestionChips({super.key, required this.suggestions, required this.added, required this.onAdd});

  final List<({String path, String source})> suggestions;
  final bool Function(String path) added;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusTag);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        sectionCaps(theme, ghTr('suggested_from_workspaces')),
        Wrap(
          spacing: theme.space(1.5),
          runSpacing: theme.space(1.5),
          children: [
            for (final s in suggestions)
              Builder(
                key: ValueKey(s.path),
                builder: (context) {
                  final isAdded = added(s.path);
                  return GhPressable(
                    onPressed: isAdded ? null : () => onAdd(s.path),
                    disabledOpacity: 1,
                    borderRadius: radius,
                    semanticLabel: s.path,
                    builder: (context, states) {
                      final hover = states.highlighted;
                      final color = isAdded ? theme.accentBright : (hover ? theme.accentBright : theme.muted);
                      final body = GhAnimatedBox(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                        color: isAdded ? theme.accent.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: radius,
                        border: isAdded ? Border.all(color: theme.accentDim.withValues(alpha: 0.4)) : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: theme.space(1.5),
                          children: [
                            GhIcon(isAdded ? GhIcons.check : GhIcons.plus, size: theme.space(3), color: color),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: theme.space(48)),
                              child: Text(
                                s.path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.x2s, mono: true, color: color),
                              ),
                            ),
                            Text(
                              ghTr('from_workspace', args: {'name': s.source}),
                              style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted),
                            ),
                          ],
                        ),
                      );
                      if (isAdded) return body;
                      return DashedOutline(
                        color: hover ? theme.accentDim : theme.outline.withValues(alpha: 0.6),
                        radius: radius,
                        child: body,
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class DashedOutline extends StatelessWidget {
  const DashedOutline({super.key, required this.color, required this.radius, required this.child});

  final Color color;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(foregroundPainter: _DashedRRect(color, radius), child: child);
}

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color, this.radius);

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(radius.toRRect(Offset.zero & size).deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color || old.radius != radius;
}

const maxCelebrationTiles = 12;

class FinishCelebration extends StatefulWidget {
  const FinishCelebration({super.key, required this.projects, required this.versionCount});

  final List<Project> projects;
  final int versionCount;

  @override
  State<FinishCelebration> createState() => _FinishCelebrationState();
}

class _FinishCelebrationState extends State<FinishCelebration> with SingleTickerProviderStateMixin {
  late final GhTimeline _timeline = GhTimeline(vsync: this);
  final _random = math.Random();
  List<Animation<double>> _tracks = const [];
  List<double> _rotations = const [];
  int _projects = 0;
  int _versions = 0;
  Timer? _count;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _scheduleCounts();
  }

  void _scheduleCounts() {
    _count?.cancel();
    _count = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _projects = widget.projects.length;
          _versions = widget.versionCount;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final count = math.min(widget.projects.length, maxCelebrationTiles);
    _rotations = [for (var i = 0; i < count; i++) -12 + _random.nextDouble() * 24];
    _tracks = [for (var i = 0; i < count; i++) _timeline.add(GhTrack(start: 0.25 + i * 0.06, duration: 0.7, ease: GhEase.spring))];
    final motion = GhMotion.of(context);
    if (motion.off) {
      _timeline.finish();
    } else {
      _timeline.play(motion);
    }
  }

  @override
  void didUpdateWidget(FinishCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects.length != widget.projects.length || oldWidget.versionCount != widget.versionCount) _scheduleCounts();
  }

  @override
  void dispose() {
    _count?.cancel();
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final stats = [(ghTr('section_projects'), _projects), (ghTr('section_versions'), _versions)];
    final tiles = widget.projects.take(maxCelebrationTiles).toList();
    final big = theme
        .text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.ink, letterSpacingEm: -0.025)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(5),
      children: [
        Row(
          spacing: theme.space(3),
          children: [
            for (final (label, value) in stats)
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(4)),
                  decoration: BoxDecoration(
                    color: theme.base.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(1),
                    children: [
                      GhAnimatedNumber(value, style: big),
                      Text(
                        label,
                        style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (tiles.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = theme.space(2);
              final width = (constraints.maxWidth - gap * 3) / 4;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < tiles.length; i++)
                    SizedBox(
                      key: ValueKey(tiles[i].id),
                      width: width,
                      child: GhPoseTransition(
                        animation: i < _tracks.length ? _tracks[i] : kAlwaysCompleteAnimation,
                        from: GhPose(y: -36, opacity: 0, rotation: i < _rotations.length ? _rotations[i] : 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
                          decoration: BoxDecoration(
                            color: theme.base.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(theme.radiusItem),
                            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            spacing: theme.space(2),
                            children: [
                              Container(
                                width: theme.space(6),
                                height: theme.space(6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(theme.radiusTag),
                                ),
                                child: Text(
                                  projectInitial(tiles[i].name),
                                  style: theme.text(size: GhTextSize.x3s, weight: GhWeight.bold, color: theme.accentBright),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tiles[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.text(size: GhTextSize.x2s, color: theme.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class OnboardingFirstWorkspace extends ConsumerStatefulWidget {
  const OnboardingFirstWorkspace({super.key});

  @override
  ConsumerState<OnboardingFirstWorkspace> createState() => _OnboardingFirstWorkspaceState();
}

class _OnboardingFirstWorkspaceState extends ConsumerState<OnboardingFirstWorkspace> {
  GhWorkspaceDraft? _draft;
  String? _synced;

  void _commitName(Workspace current, List<String> taken) {
    final draft = _draft;
    if (draft == null) return;
    final trimmed = draft.name.trim();
    if (ghWorkspaceNameError(trimmed, taken) != null || trimmed == current.name) return;
    ref
        .read(workspacesProvider.notifier)
        .renameWorkspace(current.id, trimmed)
        .catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
  }

  void _change(Workspace current, GhWorkspaceDraft next) {
    setState(() => _draft = next);
    if (next.icon != current.icon || next.color != current.color) {
      ref
          .read(workspacesProvider.notifier)
          .updateWorkspaceStyle(current.id, next.icon, next.color)
          .catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(workspacesProvider);
    Workspace? current;
    for (final w in view.workspaces) {
      if (w.id == view.activeId) current = w;
    }
    if (current == null) return const SizedBox.shrink();
    if (_synced != current.id) {
      _synced = current.id;
      _draft = GhWorkspaceDraft(name: current.name, icon: current.icon, color: current.color);
    }
    final draft = _draft!;
    final ws = current;
    final taken = [
      for (final w in view.workspaces)
        if (w.id != ws.id) w.name,
    ];
    return GhWorkspaceForm(
      value: draft,
      onChanged: (next) => _change(ws, next),
      takenNames: taken,
      showErrors: true,
      onSubmit: () => _commitName(ws, taken),
      onNameBlur: () => _commitName(ws, taken),
    );
  }
}

class OnboardingCloudBackup extends StatefulWidget {
  const OnboardingCloudBackup({super.key});

  @override
  State<OnboardingCloudBackup> createState() => _OnboardingCloudBackupState();
}

class _OnboardingCloudBackupState extends State<OnboardingCloudBackup> {
  String? _gitUser;

  @override
  void initState() {
    super.initState();
    Api.gitAuthGetState().then((state) {
      final user = state.github?.username;
      if (mounted && user != null) setState(() => _gitUser = user);
    }, onError: (Object _) {});
  }

  void _signIn() {
    showGhModal<void>(
      context,
      (modal) => GitAuthModal(
        provider: 'github',
        onClose: () => Navigator.of(modal).pop(),
        onConnected: (username) {
          if (mounted) setState(() => _gitUser = username);
          Navigator.of(modal).pop();
        },
      ),
    ).ignore();
  }

  void _restore() {
    showGhModal<void>(context, (modal) => RestoreProgressModal(onClose: () => Navigator.of(modal).pop())).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final user = _gitUser;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2.5),
      children: [
        Text(
          _to('onboard_cloud_heading').toUpperCase(),
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.025),
        ),
        Container(
          padding: EdgeInsets.all(theme.space(4)),
          decoration: _rowBox(theme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(3),
            children: [
              Text(
                _to('onboard_cloud_desc'),
                style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
              ),
              if (user == null)
                GhPressable(
                  onPressed: _signIn,
                  borderRadius: radius,
                  builder: (context, states) => GhAnimatedBox(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
                    color: states.active ? theme.raised : theme.overlay,
                    borderRadius: radius,
                    border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                    child: Text(
                      _to('git_sign_in_github'),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                    ),
                  ),
                )
              else ...[
                Row(
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.check, size: theme.space(3.5), color: theme.mint),
                    Expanded(
                      child: Text(
                        _to('git_connected_as', args: {'username': user}),
                        style: theme.text(size: GhTextSize.xs, color: theme.mint),
                      ),
                    ),
                  ],
                ),
                GhPressable(
                  onPressed: _restore,
                  borderRadius: radius,
                  rippleColor: Colors.white,
                  builder: (context, states) => GhAnimatedBox(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
                    color: states.active ? theme.accentBright : theme.accent,
                    borderRadius: radius,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(2),
                      children: [
                        GhIcon(GhIcons.cloudArrowDown, size: theme.space(3.5), color: Colors.white),
                        Text(
                          ghTr('settings:sync_pull_btn'),
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  ghTr('settings:sync_manual_hint'),
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

const celebrationHold = Duration(milliseconds: 2400);

class LiftedPreview {
  LiftedPreview._(this._entry, this._state);

  final OverlayEntry _entry;
  final GlobalKey<_MorphOverlayState> _state;

  static Future<LiftedPreview?> lift({
    required BuildContext context,
    required GlobalKey preview,
    required Widget Function(double contentOpacity) clone,
    required VoidCallback onShellFade,
  }) async {
    final box = preview.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey<_MorphOverlayState>();
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final lifted = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MorphOverlay(
        key: key,
        rect: rect,
        theme: theme,
        motion: motion,
        clone: clone,
        onLifted: () {
          if (!lifted.isCompleted) lifted.complete();
        },
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    onShellFade();
    await lifted.future;
    return LiftedPreview._(entry, key);
  }

  void morph() {
    final state = _state.currentState;
    if (state == null) {
      if (_entry.mounted) _entry.remove();
      return;
    }
    state.morph();
  }
}

class _MorphOverlay extends StatefulWidget {
  const _MorphOverlay({
    super.key,
    required this.rect,
    required this.theme,
    required this.motion,
    required this.clone,
    required this.onLifted,
    required this.onDone,
  });

  final Rect rect;
  final GhTheme theme;
  final GhMotionData motion;
  final Widget Function(double contentOpacity) clone;
  final VoidCallback onLifted;
  final VoidCallback onDone;

  @override
  State<_MorphOverlay> createState() => _MorphOverlayState();
}

class _MorphOverlayState extends State<_MorphOverlay> with TickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(vsync: this, duration: widget.motion.gsap(0.4));
  late final AnimationController _morph = AnimationController(vsync: this, duration: widget.motion.gsap(1.2));
  late final Animation<double> _cover = CurvedAnimation(parent: _lift, curve: GhEase.easeIn);
  late final Animation<double> _scale = CurvedAnimation(parent: _lift, curve: GhEase.soft);
  late final Animation<double> _grow = CurvedAnimation(
    parent: _morph,
    curve: Interval(0, 0.85 / 1.2, curve: GsapEase('power3.inOut')),
  );
  late final Animation<double> _inner = CurvedAnimation(
    parent: _morph,
    curve: Interval(0, 0.2 / 1.2, curve: GsapEase('power2.out')),
  );
  late final Animation<double> _out = CurvedAnimation(
    parent: _morph,
    curve: Interval(0.8 / 1.2, 1, curve: GsapEase('power2.out')),
  );

  @override
  void initState() {
    super.initState();
    _lift.forward().whenCompleteOrCancel(widget.onLifted);
  }

  void morph() {
    if (!mounted) return;
    _morph.forward().whenCompleteOrCancel(widget.onDone);
  }

  @override
  void dispose() {
    _lift.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_lift, _morph]),
        builder: (context, _) {
          final fade = 1 - _out.value;
          final grow = _grow.value;
          final rect = Rect.lerp(widget.rect, Offset.zero & screen, grow)!;
          final scale = 1 + 0.06 * _scale.value * (1 - grow);
          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: (_cover.value * fade).clamp(0, 1),
                  child: ColoredBox(color: widget.theme.base),
                ),
              ),
              Positioned.fromRect(
                rect: rect,
                child: Opacity(
                  opacity: fade.clamp(0, 1),
                  child: Transform.scale(
                    scale: scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.theme.radiusTile * (1 - grow)),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(width: widget.rect.width, height: widget.rect.height, child: widget.clone(1 - _inner.value)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
