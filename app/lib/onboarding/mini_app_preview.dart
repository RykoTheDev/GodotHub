import 'package:flutter/material.dart';

import '../design/design.dart';
import '../logic/features.dart';
import '../motion/ease.dart';
import '../motion/motion.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/core/i18n.dart';

const _maxTiles = 9;

class DashRise extends StatefulWidget {
  const DashRise({super.key, required this.child});

  final Widget child;

  @override
  State<DashRise> createState() => _DashRiseState();
}

class _DashRiseState extends State<DashRise> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _progress = CurvedAnimation(parent: _controller, curve: GhEase.out);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = GhMotion.of(context);
    if (motion.off) {
      _controller.value = 1;
      return;
    }
    _controller.duration = motion.gsap(0.5);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      child: Transform.translate(offset: Offset(0, 12 * (1 - _progress.value)), child: child),
    ),
  );
}

List<({String id, FaIconData icon, String label})> previewPages(AppSettings settings) => [
  for (final core in GhCoreFeature.values) (id: core.id, icon: core.icon, label: core.label()),
  for (final feature in GhFeatureId.values)
    if (feature.flag == null && isFeatureEnabled(settings, feature.id)) (id: feature.id, icon: feature.icon, label: feature.label()),
];

class MiniAppPreview extends StatelessWidget {
  const MiniAppPreview({
    super.key,
    this.previewKey,
    required this.settings,
    required this.workspace,
    required this.projects,
    required this.versionCount,
    this.hidden = false,
  });

  final Key? previewKey;
  final AppSettings settings;
  final Workspace? workspace;
  final List<Project> projects;
  final int versionCount;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(theme.space(3), 0, theme.space(3), theme.space(3)),
      padding: EdgeInsets.all(theme.space(2.5)),
      decoration: BoxDecoration(
        color: theme.base.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(0.5)),
            child: Text(
              ghTr('onboarding:preview_heading').toUpperCase(),
              style: theme.text(
                size: GhTextSize.x3s,
                weight: GhWeight.semibold,
                color: theme.muted.withValues(alpha: 0.7),
                letterSpacingEm: 0.025,
              ),
            ),
          ),
          Visibility(
            visible: !hidden,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: ExcludeSemantics(
              child: KeyedSubtree(
                key: previewKey,
                child: MiniAppWindow(settings: settings, workspace: workspace, projects: projects, versionCount: versionCount),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniAppWindow extends StatelessWidget {
  const MiniAppWindow({
    super.key,
    required this.settings,
    required this.workspace,
    required this.projects,
    required this.versionCount,
    this.contentOpacity = 1,
  });

  final AppSettings settings;
  final Workspace? workspace;
  final List<Project> projects;
  final int versionCount;
  final double contentOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final pages = previewPages(settings);
    final tiles = projects.take(_maxTiles).toList();
    final extra = projects.length - tiles.length;
    final ws = workspace;
    final tiny = theme.text(size: GhTextSize.x4s, color: theme.ink.withValues(alpha: 0.7));
    return Container(
      height: theme.space(40),
      padding: EdgeInsets.all(theme.space(1)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.base,
        borderRadius: BorderRadius.circular(theme.radiusTile),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Opacity(
        opacity: contentOpacity,
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(1),
            children: [
              Container(
                width: constraints.maxWidth * 0.42,
                padding: EdgeInsets.all(theme.space(1)),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusTag)),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(1),
                    children: [
                      if (ws != null)
                        DashRise(
                          key: ValueKey('ws:${ws.icon}-${ws.name}'),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(0.5)),
                            decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusTag)),
                            child: Row(
                              spacing: theme.space(1),
                              children: [
                                Container(
                                  width: theme.space(3.5),
                                  height: theme.space(3.5),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.raised,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                                  ),
                                  child: GhIcon(workspaceIcon(ws.icon), size: theme.space(2), color: theme.muted),
                                ),
                                Expanded(
                                  child: Text(
                                    ws.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.text(size: GhTextSize.x4s, weight: GhWeight.semibold, color: theme.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final page in pages)
                        DashRise(
                          key: ValueKey('page:${page.id}'),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: 1),
                            child: Row(
                              spacing: theme.space(1),
                              children: [
                                GhIcon(page.icon, size: theme.space(2), color: theme.muted),
                                Expanded(
                                  child: Text(page.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tiny),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(theme.space(1)),
                  child: LayoutBuilder(
                    builder: (context, main) {
                      final gap = theme.space(1);
                      final tile = (main.maxWidth - gap * 2) / 3;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: gap,
                        children: [
                          Container(
                            width: main.maxWidth * 2 / 3,
                            height: theme.space(1.5),
                            decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(999)),
                          ),
                          Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              if (tiles.isNotEmpty)
                                for (final p in tiles)
                                  DashRise(
                                    key: ValueKey('tile:${p.id}'),
                                    child: Container(
                                      width: tile,
                                      height: tile,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: theme.raised,
                                        borderRadius: BorderRadius.circular(theme.radiusTag),
                                        border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        _initial(p.name),
                                        style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, color: theme.muted),
                                      ),
                                    ),
                                  )
                              else
                                for (var i = 0; i < 3; i++)
                                  GhDashedBox(
                                    color: theme.outline.withValues(alpha: 0.4),
                                    radius: BorderRadius.circular(theme.radiusTag),
                                    child: SizedBox.square(dimension: tile),
                                  ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            spacing: theme.space(1),
                            children: [
                              if (extra > 0)
                                Text(
                                  '+$extra',
                                  style: theme.text(size: GhTextSize.x4s, color: theme.muted),
                                ),
                              const Spacer(),
                              if (versionCount > 0)
                                DashRise(
                                  key: ValueKey('versions:$versionCount'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: theme.space(1),
                                    children: [
                                      GhIcon(GhCoreFeature.versions.icon, size: theme.space(2), color: theme.accentBright),
                                      Text(
                                        '$versionCount',
                                        style: theme.text(size: GhTextSize.x4s, color: theme.accentBright),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
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

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

String projectInitial(String name) => _initial(name);
