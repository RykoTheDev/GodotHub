import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'strings.dart';

@immutable
class GhWorkspaceRef {
  const GhWorkspaceRef({required this.id, required this.name, required this.icon});

  final String id;
  final String name;
  final String icon;
}

class GhWorkspaceSwitchCard extends StatelessWidget {
  const GhWorkspaceSwitchCard({
    super.key,
    required this.icon,
    required this.name,
    this.label = GhFeedbackStrings.workspaceSwitchedTo,
  });

  final FaIconData icon;
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(10), vertical: theme.space(7)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusCard),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        boxShadow: GhShadows.xl2(Colors.black.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(3),
        children: [
          Container(
            width: theme.space(12),
            height: theme.space(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.overlay,
              shape: BoxShape.circle,
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
            ),
            child: GhIcon(icon, size: theme.space(5), color: theme.ink),
          ),
          Text(
            label.toUpperCase(),
            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.25),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.6),
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.x3l, weight: GhWeight.bold, color: theme.ink, letterSpacingEm: -0.025),
            ),
          ),
        ],
      ),
    );
  }
}

class GhWorkspaceSwitchNotice extends StatefulWidget {
  const GhWorkspaceSwitchNotice({
    super.key,
    required this.activeId,
    required this.workspaces,
    this.label = GhFeedbackStrings.workspaceSwitchedTo,
  });

  static const hold = Duration(milliseconds: 1100);
  static const enter = Duration(milliseconds: 400);
  static const exit = Duration(milliseconds: 300);

  final String? activeId;
  final List<GhWorkspaceRef> workspaces;
  final String label;

  @override
  State<GhWorkspaceSwitchNotice> createState() => _GhWorkspaceSwitchNoticeState();
}

class _GhWorkspaceSwitchNoticeState extends State<GhWorkspaceSwitchNotice> with SingleTickerProviderStateMixin {
  static final _total = GhWorkspaceSwitchNotice.enter + GhWorkspaceSwitchNotice.hold + GhWorkspaceSwitchNotice.exit;

  late final AnimationController _controller = AnimationController(vsync: this, duration: _total)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _notice = null);
      }
    });
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: GhCurves.outExpo)),
      weight: GhWorkspaceSwitchNotice.enter.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: GhWorkspaceSwitchNotice.hold.inMilliseconds.toDouble()),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: GhCurves.easeIn)),
      weight: GhWorkspaceSwitchNotice.exit.inMilliseconds.toDouble(),
    ),
  ]).animate(_controller);

  String? _previousId;
  GhWorkspaceRef? _notice;
  int _key = 0;

  @override
  void initState() {
    super.initState();
    _previousId = widget.activeId;
  }

  @override
  void didUpdateWidget(GhWorkspaceSwitchNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeId = widget.activeId;
    if (activeId == null) {
      return;
    }
    final previous = _previousId;
    _previousId = activeId;
    if (previous == null || previous == activeId) {
      return;
    }
    for (final workspace in widget.workspaces) {
      if (workspace.id == activeId) {
        _notice = workspace;
        _key += 1;
        _controller.forward(from: 0);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (notice == null) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        child: Center(
          child: FadeTransition(
            key: ValueKey(_key),
            opacity: _opacity,
            child: GhWorkspaceSwitchCard(icon: workspaceIcon(notice.icon), name: notice.name, label: widget.label),
          ),
        ),
      ),
    );
  }
}
