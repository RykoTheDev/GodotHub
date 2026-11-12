import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/ease.dart';
import '../../motion/motion.dart';
import '../../motion/tween.dart';
import '../core/i18n.dart';

@immutable
class GhWorkspaceRef {
  const GhWorkspaceRef({required this.id, required this.name, required this.icon});

  final String id;
  final String name;
  final String icon;
}

class GhWorkspaceSwitchCard extends StatelessWidget {
  const GhWorkspaceSwitchCard({super.key, required this.icon, required this.name, this.label});

  final FaIconData icon;
  final String name;
  final String? label;

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
            (label ?? context.tr.common.workspace_switched_to).toUpperCase(),
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
  const GhWorkspaceSwitchNotice({super.key, required this.activeId, required this.workspaces, this.label});

  static const enterSeconds = 0.4;
  static const holdSeconds = 1.1;
  static const exitSeconds = 0.3;
  static const offHold = Duration(milliseconds: 1500);
  static const enterFrom = GhPose(opacity: 0, scale: 0.9, y: 12);
  static const exitTo = GhPose(opacity: 0, scale: 0.96, y: -8);

  final String? activeId;
  final List<GhWorkspaceRef> workspaces;
  final String? label;

  @override
  State<GhWorkspaceSwitchNotice> createState() => _GhWorkspaceSwitchNoticeState();
}

class _GhWorkspaceSwitchNoticeState extends State<GhWorkspaceSwitchNotice> with SingleTickerProviderStateMixin {
  late final GhTimeline _timeline = GhTimeline(vsync: this);
  late final Animation<double> _in;
  late final Animation<double> _out;

  String? _previousId;
  GhWorkspaceRef? _notice;
  Timer? _timer;
  int _key = 0;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _in = _timeline.add(GhTrack(start: 0, duration: GhWorkspaceSwitchNotice.enterSeconds, ease: GhEase.spring));
    _out = _timeline.add(
      GhTrack(
        start: GhWorkspaceSwitchNotice.enterSeconds + GhWorkspaceSwitchNotice.holdSeconds,
        duration: GhWorkspaceSwitchNotice.exitSeconds,
        ease: GhEase.easeIn,
      ),
    );
    _timeline.finish();
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
        _play();
        return;
      }
    }
  }

  void _play() {
    final run = ++_run;
    _timer?.cancel();
    final motion = GhMotion.of(context);
    if (motion.off) {
      _timeline.controller.value = GhWorkspaceSwitchNotice.enterSeconds / _timeline.length;
      _timer = Timer(GhWorkspaceSwitchNotice.offHold, () => _hide(run));
      return;
    }
    _timeline.play(motion).whenCompleteOrCancel(() {
      if (_timeline.controller.isCompleted) {
        _hide(run);
      }
    });
  }

  void _hide(int run) {
    if (!mounted || run != _run) {
      return;
    }
    setState(() => _notice = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeline.dispose();
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
          child: AnimatedBuilder(
            key: ValueKey(_key),
            animation: _timeline.controller,
            child: GhWorkspaceSwitchCard(icon: workspaceIcon(notice.icon), name: notice.name, label: widget.label),
            builder: (context, child) {
              final entered = GhPose.lerp(GhWorkspaceSwitchNotice.enterFrom, GhPose.identity, _in.value);
              return GhPoseView(allowBlur: false, pose: GhPose.lerp(entered, GhWorkspaceSwitchNotice.exitTo, _out.value), child: child!);
            },
          ),
        ),
      ),
    );
  }
}
