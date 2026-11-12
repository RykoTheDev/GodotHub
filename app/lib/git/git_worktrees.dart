import 'dart:async';

import 'package:flutter/material.dart';

import '../api/events.dart';
import '../api/git.dart';
import '../design/design.dart';
import '../logic/worktree_paths.dart';
import '../modals/create_worktree_modal.dart';
import '../state/projects.dart' show copyProject;
import '../src/rust/api/types.dart';
import '../ui/controls/checkbox.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';
import 'git_section.dart';

String worktreeLabel(GitWorktree wt) =>
    wt.branch ?? ghTr('git:worktree_detached', args: {'hash': wt.head.length > 7 ? wt.head.substring(0, 7) : wt.head});

GitWorktree? currentWorktreeOf(String projectPath, List<GitWorktree> worktrees) {
  GitWorktree? best;
  for (final wt in worktrees) {
    if (isWithinWorktree(projectPath, wt.path) && (best == null || wt.path.length > best.path.length)) best = wt;
  }
  return best;
}

class GitWorktrees extends StatefulWidget {
  const GitWorktrees({super.key, required this.project, this.onSwitchProject, required this.onChanged});

  final Project project;
  final Future<void> Function(Project project)? onSwitchProject;
  final VoidCallback onChanged;

  @override
  State<GitWorktrees> createState() => _GitWorktreesState();
}

class _GitWorktreesState extends State<GitWorktrees> {
  List<GitWorktree> _worktrees = const [];
  bool _loading = true;
  String? _error;
  ({String action, String path})? _busy;
  int _request = 0;
  StreamSubscription<AppEvent>? _changes;

  @override
  void initState() {
    super.initState();
    _changes = AppEvents.of(AppEventKind.gitProjectChanged).listen((_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _request++;
    _changes?.cancel();
    super.dispose();
  }

  GitWorktree? get _current => currentWorktreeOf(widget.project.path, _worktrees);

  Future<void> _refresh() async {
    final version = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await GitApi.worktreeList(widget.project.path);
      if (mounted && version == _request) setState(() => _worktrees = entries);
    } catch (e) {
      if (mounted && version == _request) setState(() => _error = '$e');
    } finally {
      if (mounted && version == _request) setState(() => _loading = false);
    }
  }

  Future<void> _switchTo(GitWorktree wt) async {
    final onSwitch = widget.onSwitchProject;
    if (_busy != null || onSwitch == null || identical(wt, _current)) return;
    setState(() => _busy = (action: 'switch', path: wt.path));
    try {
      final project = widget.project;
      final path = worktreeProjectPath(project.path, _current?.path ?? project.path, wt.path);
      await GitApi.worktreeSwitch(project.path, path);
      if (!mounted) return;
      await onSwitch(copyProject(project, path: path));
      ghToasts.pushToast(GhToastType.success, ghTr('git:switched_worktree_ok'));
    } catch (e) {
      if (mounted) ghToasts.pushToast(GhToastType.error, '$e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _create() => showGhModal<void>(
    context,
    (modal) => CreateWorktreeModal(
      repositoryPath: _current?.path ?? widget.project.path,
      onClose: () => Navigator.of(modal).pop(),
      onCreated: () {
        Navigator.of(modal).pop();
        if (!mounted) return;
        _refresh();
        widget.onChanged();
        ghToasts.pushToast(GhToastType.success, ghTr('git:worktree_created_ok'));
      },
    ),
  );

  Future<void> _confirmRemove(GitWorktree wt) async {
    final removed = await showGhModal<bool>(
      context,
      (modal) => RemoveWorktreeModal(projectPath: widget.project.path, worktree: wt, onClose: (done) => Navigator.of(modal).pop(done)),
    );
    if (removed != true || !mounted) return;
    await _refresh();
    widget.onChanged();
    ghToasts.pushToast(GhToastType.success, ghTr('git:worktree_removed_ok'));
  }

  Widget _action(
    GhTheme theme, {
    required String tooltip,
    required String label,
    required Widget icon,
    required VoidCallback? onPressed,
    required Color hover,
  }) => GhTooltip(
    message: tooltip,
    child: GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      disabledOpacity: 0.4,
      disabledCursor: SystemMouseCursors.forbidden,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      builder: (context, states) => GhAnimatedBox(
        width: theme.space(7),
        height: theme.space(7),
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        alignment: Alignment.center,
        child: IconTheme.merge(
          data: IconThemeData(color: states.active ? hover : theme.muted),
          child: icon,
        ),
      ),
    ),
  );

  Widget _row(GhTheme theme, GitWorktree wt) {
    final current = identical(wt, _current);
    final switching = _busy?.action == 'switch' && _busy?.path == wt.path;
    final disabled = _busy != null || (_loading && _worktrees.isEmpty);
    final clean = wt.hasUncommitted ? ghTr('git:worktree_dirty') : ghTr('git_clean');
    final name = wt.branch ?? wt.path;
    return _HoverBox(
      current: current,
      builder: (hovered) => Row(
        spacing: theme.space(2),
        children: [
          GhIcon(GhIcons.clone, size: theme.space(3.5), color: current ? theme.accentBright : theme.muted.withValues(alpha: 0.6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: theme.space(1.5),
                  runSpacing: theme.space(0.5),
                  children: [
                    GhTooltip(
                      message: wt.branch ?? wt.head,
                      child: Text(
                        worktreeLabel(wt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.ink),
                      ),
                    ),
                    if (wt.isMain)
                      Text(
                        ghTr('git:worktree_main'),
                        style: theme.text(size: GhTextSize.x4s, color: theme.muted.withValues(alpha: 0.7)),
                      ),
                    GhTooltip(
                      message: clean,
                      child: Semantics(
                        label: clean,
                        child: Container(
                          width: theme.space(1.5),
                          height: theme.space(1.5),
                          decoration: BoxDecoration(
                            color: wt.hasUncommitted ? theme.amber : theme.mint.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GhTooltip(
                  message: wt.path,
                  child: Text(
                    wt.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),
          ),
          if (current)
            Container(
              padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(1)),
              decoration: BoxDecoration(color: theme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(theme.radiusTag)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(1),
                children: [
                  GhIcon(GhIcons.check, size: theme.space(2.5), color: theme.accentBright),
                  Text(
                    ghTr('git:worktree_current'),
                    style: theme.text(size: GhTextSize.x4s, weight: GhWeight.medium, color: theme.accentBright),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(0.5),
              children: [
                if (widget.onSwitchProject != null)
                  _action(
                    theme,
                    tooltip: ghTr('git:switch_worktree'),
                    label: ghTr('git:switch_worktree_named', args: {'name': name}),
                    hover: theme.accentBright,
                    onPressed: disabled ? null : () => _switchTo(wt),
                    icon: switching
                        ? GhSpinnerIcon(size: 3.5, color: theme.muted)
                        : Transform.flip(
                            flipX: Directionality.of(context) == TextDirection.rtl,
                            child: GhIcon(GhIcons.chevronRight, size: theme.space(3.5)),
                          ),
                  ),
                if (!wt.isMain)
                  Opacity(
                    opacity: hovered ? 1 : 0.6,
                    child: _action(
                      theme,
                      tooltip: ghTr('git:remove_worktree'),
                      label: ghTr('remove_category_aria', args: {'name': name}),
                      hover: theme.danger,
                      onPressed: disabled ? null : () => _confirmRemove(wt),
                      icon: GhIcon(GhIcons.trash, size: theme.space(3.5)),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final muted = theme.text(size: GhTextSize.x2s, color: theme.muted);
    return GitSection(
      title: ghTr('git:worktrees_title'),
      count: _worktrees.length,
      storageKey: 'git-sidebar-worktrees',
      defaultOpen: false,
      children: [
        if (_loading && _worktrees.isEmpty && _error == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(3)),
            child: Row(
              spacing: theme.space(2),
              children: [
                GhSpinnerIcon(size: 3.5, color: theme.muted),
                Text(ghTr('loading'), style: muted),
              ],
            ),
          )
        else if (_error == null && _worktrees.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(3)),
            child: Text(ghTr('git:no_worktrees'), style: muted.copyWith(color: theme.muted.withValues(alpha: 0.7))),
          )
        else
          for (final wt in _worktrees) _row(theme, wt),
        if (_error != null)
          GhAlertBox(
            tone: GhAlertTone.danger,
            padding: 2.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ghTr('git:worktrees_load_error'),
                  style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                ),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(1)),
                  child: Text(
                    _error!,
                    style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(2)),
                  child: GhButton(
                    onPressed: _loading ? null : _refresh,
                    icon: GhIcons.refresh,
                    label: ghTr('retry'),
                    size: GhTextSize.x2s,
                    paddingX: 2,
                    paddingY: 1,
                  ),
                ),
              ],
            ),
          ),
        DashedAction(
          label: ghTr('git:add_worktree'),
          icon: GhIcon(GhIcons.plus, size: theme.space(3.5), color: theme.accentBright),
          onPressed: _busy != null ? null : _create,
          paddingY: 2,
        ),
      ],
    );
  }
}

class _HoverBox extends StatefulWidget {
  const _HoverBox({required this.current, required this.builder});

  final bool current;
  final Widget Function(bool hovered) builder;

  @override
  State<_HoverBox> createState() => _HoverBoxState();
}

class _HoverBoxState extends State<_HoverBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final current = widget.current;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => _hovered = value),
        child: GhAnimatedBox(
          color: current
              ? theme.accent.withValues(alpha: 0.05)
              : (_hovered ? theme.raised.withValues(alpha: 0.6) : theme.base.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: current ? theme.accent.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
          child: widget.builder(_hovered),
        ),
      ),
    );
  }
}

class DashedAction extends StatelessWidget {
  const DashedAction({super.key, required this.label, required this.icon, required this.onPressed, this.paddingY = 1.5});

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final double paddingY;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      disabledOpacity: 0.4,
      disabledCursor: SystemMouseCursors.forbidden,
      builder: (context, states) => CustomPaint(
        foregroundPainter: _DashedBorder(color: theme.outline.withValues(alpha: 0.6), radius: theme.radiusItem),
        child: GhAnimatedBox(
          color: states.active ? theme.raised : theme.base.withValues(alpha: 0.4),
          borderRadius: radius,
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(paddingY)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: theme.space(1.5),
            children: [
              icon,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3), paint);
        distance += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}

class RemoveWorktreeModal extends StatefulWidget {
  const RemoveWorktreeModal({super.key, required this.projectPath, required this.worktree, required this.onClose});

  final String projectPath;
  final GitWorktree worktree;
  final ValueChanged<bool> onClose;

  @override
  State<RemoveWorktreeModal> createState() => _RemoveWorktreeModalState();
}

class _RemoveWorktreeModalState extends State<RemoveWorktreeModal> {
  bool _busy = false;
  bool _discard = false;
  String? _error;

  Future<void> _remove() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GitApi.worktreeRemove(widget.projectPath, widget.worktree.path, _discard);
      widget.onClose(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final wt = widget.worktree;
    return GhModalShell(
      icon: GhIcon(GhIcons.trash, size: theme.space(5), color: theme.danger),
      title: ghTr('git:remove_worktree'),
      maxWidth: GhModalWidth.sm,
      onClose: _busy ? null : () => widget.onClose(false),
      footer: [
        const Spacer(),
        GhButton(onPressed: _busy ? null : () => widget.onClose(false), label: ghTr('cancel')),
        GhBusyButton(
          onPressed: _busy || (wt.hasUncommitted && !_discard) ? null : _remove,
          busy: _busy,
          danger: true,
          paddingX: 4,
          label: _busy ? ghTr('git:worktree_removing') : ghTr('git:remove_worktree'),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
            Text(
              ghTr('git:remove_worktree_confirm_desc', args: {'path': wt.path}),
              style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
              decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusItem)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(1),
                children: [
                  Text(
                    worktreeLabel(wt),
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                  ),
                  Text(
                    wt.path,
                    textDirection: TextDirection.ltr,
                    style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                  ),
                ],
              ),
            ),
            if (wt.hasUncommitted)
              GhAlertBox(
                tone: GhAlertTone.danger,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: theme.space(3)),
                      child: Text(
                        ghTr('git:worktree_discard_warning'),
                        style: theme.text(size: GhTextSize.xs, color: theme.danger, lineHeight: 1.625),
                      ),
                    ),
                    GhCheckbox(
                      checked: _discard,
                      disabled: _busy,
                      label: ghTr('git:worktree_discard_changes'),
                      onChanged: (value) => setState(() => _discard = value),
                      child: Text(ghTr('git:worktree_discard_changes')),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: theme.text(size: GhTextSize.xs, color: theme.danger),
              ),
          ],
        ),
      ),
    );
  }
}
