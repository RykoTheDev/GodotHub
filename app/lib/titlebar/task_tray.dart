import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../motion/motion.dart';
import '../state/task_tray.dart';
import '../ui/core/i18n.dart';
import 'title_bar_theme.dart';
import '../ui/shell/smooth_scroll.dart';

const _menuWidth = 320.0;
const _triggerWidth = 36.0;

class TaskTray extends ConsumerStatefulWidget {
  const TaskTray({super.key});

  @override
  ConsumerState<TaskTray> createState() => _TaskTrayState();
}

class _TaskTrayState extends ConsumerState<TaskTray> {
  final MenuController _menu = MenuController();
  bool _open = false;
  Timer? _autoClose;

  void _syncAutoClose(bool empty) {
    if (_open && empty) {
      _autoClose ??= Timer(taskTrayEmptyAutoClose, () {
        _autoClose = null;
        if (mounted && _menu.isOpen) _menu.close();
      });
    } else {
      _autoClose?.cancel();
      _autoClose = null;
    }
  }

  void _onOpen() {
    setState(() => _open = true);
    _syncAutoClose(ref.read(taskTrayProvider).isEmpty);
  }

  void _onClose() {
    _autoClose?.cancel();
    _autoClose = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  String _subtitle(BuildContext context, List<TrayTask> tasks, int active) {
    final tr = context.tr.common;
    if (active > 0) return tr.task_tray_active_count.args({'active': active, 'recent': tasks.length - active});
    if (tasks.isEmpty) return tr.task_tray_empty;
    return tr.task_tray_only_recent(count: tasks.length);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(taskTrayProvider.select((tasks) => tasks.isEmpty), (_, empty) => _syncAutoClose(empty));
    final tokens = TitleBarTokens.of(context);
    final tasks = ref.watch(taskTrayProvider);
    final count = ref.watch(taskTrayActiveCountProvider);
    final dismissible = ref.watch(taskTrayDismissibleCountProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MenuAnchor(
        controller: _menu,
        style: tokens.menuStyle(padding: const EdgeInsets.all(8)),
        alignmentOffset: const Offset(_triggerWidth - _menuWidth, 8),
        onOpen: _onOpen,
        onClose: _onClose,
        menuChildren: [
          SizedBox(
            width: _menuWidth - 16,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 384 - 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: tokens.line.withValues(alpha: 0.5))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.common.task_tray_title.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: tokens.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(_subtitle(context, tasks, count), style: TextStyle(fontSize: 10, color: tokens.muted.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  if (tasks.isEmpty)
                    const _TaskTrayEmpty()
                  else
                    Flexible(
                      child: GhScrollView(
                        primary: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [for (final task in tasks) _TaskItem(key: ValueKey('task-${task.id}'), task: task)],
                        ),
                      ),
                    ),
                  if (tasks.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: tokens.line.withValues(alpha: 0.5))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr.common.task_tray_auto_dismiss,
                              style: TextStyle(fontSize: 9, color: tokens.muted.withValues(alpha: 0.4)),
                            ),
                          ),
                          if (dismissible > 0)
                            TitleBarButton(
                              key: const ValueKey('task-tray-dismiss'),
                              onPressed: ref.read(taskTrayProvider.notifier).clearCompleted,
                              builder: (context, hovered) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hovered ? tokens.raised : Colors.transparent,
                                  borderRadius: BorderRadius.circular(tokens.itemRadius),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GhIcon(GhIcons.x, size: 12, color: hovered ? tokens.ink : tokens.muted),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.tr.common.task_tray_dismiss.args({'count': dismissible}),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: hovered ? tokens.ink : tokens.muted,
                                      ),
                                    ),
                                  ],
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
        builder: (context, controller, child) => TitleBarButton(
          key: const ValueKey('task-tray-trigger'),
          tooltip: context.tr.common.task_tray_aria,
          semanticLabel: context.tr.common.task_tray_aria,
          expanded: _open,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          builder: (context, hovered) => Container(
            width: _triggerWidth,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hovered ? tokens.ink.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(tokens.itemRadius),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GhIcon(GhIcons.bell, size: 16, color: hovered ? tokens.ink : tokens.muted),
                if (count > 0)
                  PositionedDirectional(
                    top: -6,
                    end: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: tokens.amber, shape: BoxShape.circle),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, height: 1, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskTrayEmpty extends StatelessWidget {
  const _TaskTrayEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.raised,
              borderRadius: BorderRadius.circular(tokens.btnRadius),
              border: Border.all(color: tokens.line.withValues(alpha: 0.5)),
            ),
            child: GhIcon(GhIcons.bell, size: 16, color: tokens.muted.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr.common.no_tasks_running,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends ConsumerWidget {
  const _TaskItem({super.key, required this.task});

  final TrayTask task;

  (FaIconData, Color) _icon(TitleBarTokens tokens) => switch (task.type) {
    TaskType.downloadGodot || TaskType.downloadTemplates => (GhIcons.download, tokens.amber),
    TaskType.downloadAsset => (GhIcons.store, tokens.accentBright),
    TaskType.scanProjects ||
    TaskType.scanVersions => task.status == TaskStatus.running ? (GhIcons.search, tokens.accentBright) : (GhIcons.check, tokens.mint),
    TaskType.syncTemplates => (GhIcons.copy, tokens.accentBright),
    TaskType.cloneRepo => (GhIcons.gitBranch, tokens.mint),
    TaskType.importProjects => (GhIcons.folderPlus, tokens.accentBright),
    TaskType.importVersions => (GhIcons.cloudArrowDown, tokens.accentBright),
  };

  Widget _action(
    TitleBarTokens tokens, {
    required String key,
    required FaIconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? hoverColor,
    Color? hoverBackground,
  }) {
    return TitleBarIconButton(
      key: ValueKey(key),
      icon: icon,
      iconSize: 12,
      width: 20,
      height: 20,
      radius: tokens.btnRadius,
      color: tokens.muted.withValues(alpha: 0.5),
      hoverColor: hoverColor ?? tokens.ink,
      hoverBackground: hoverBackground ?? tokens.raised,
      semanticLabel: label,
      tooltip: label,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = TitleBarTokens.of(context);
    final tr = context.tr;
    final tray = ref.read(taskTrayProvider.notifier);
    final (icon, iconColor) = _icon(tokens);
    final downloadKey = task.downloadKey;
    final templateTag = task.templateTag;
    final status = task.status;
    final description = task.description;
    final error = task.errorMessage;
    final fraction = task.progress?.fraction;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.raised,
              borderRadius: BorderRadius.circular(tokens.btnRadius),
              border: Border.all(color: tokens.line.withValues(alpha: 0.5)),
            ),
            child: GhIcon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tokens.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (downloadKey != null) ...[
                      if (status == TaskStatus.queued) ...[
                        _action(
                          tokens,
                          key: 'task-move-up-${task.id}',
                          icon: GhIcons.chevronUp,
                          label: tr.common.download_queue_move_up,
                          onPressed: () => tray.moveDownload(downloadKey, -1),
                        ),
                        _action(
                          tokens,
                          key: 'task-move-down-${task.id}',
                          icon: GhIcons.chevronDown,
                          label: tr.common.download_queue_move_down,
                          onPressed: () => tray.moveDownload(downloadKey, 1),
                        ),
                      ],
                      if (status == TaskStatus.running)
                        _action(
                          tokens,
                          key: 'task-pause-${task.id}',
                          icon: GhIcons.pause,
                          label: tr.versions.pause_download,
                          onPressed: () => tray.pauseDownload(downloadKey),
                        ),
                      if (status == TaskStatus.paused)
                        _action(
                          tokens,
                          key: 'task-resume-${task.id}',
                          icon: GhIcons.play,
                          label: tr.versions.resume_download,
                          hoverColor: tokens.mint,
                          hoverBackground: tokens.mint.withValues(alpha: 0.1),
                          onPressed: () => tray.resumeDownload(downloadKey),
                        ),
                      if (status == TaskStatus.paused || status == TaskStatus.queued)
                        _action(
                          tokens,
                          key: 'task-cancel-${task.id}',
                          icon: GhIcons.x,
                          label: tr.versions.cancel_download,
                          hoverColor: tokens.danger,
                          hoverBackground: tokens.danger.withValues(alpha: 0.1),
                          onPressed: () => tray.cancelDownload(downloadKey),
                        ),
                    ],
                    if (templateTag != null && status.active)
                      _action(
                        tokens,
                        key: 'task-cancel-${task.id}',
                        icon: GhIcons.x,
                        label: tr.common.cancel,
                        hoverColor: tokens.danger,
                        hoverBackground: tokens.danger.withValues(alpha: 0.1),
                        onPressed: () => tray.cancelTemplates(templateTag),
                      ),
                    const SizedBox(width: 6),
                    _StatusBadge(status: status),
                  ],
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.muted),
                    ),
                  ),
                if (error != null && error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      error,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.danger),
                    ),
                  ),
                if (fraction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Positioned.fill(child: ColoredBox(color: tokens.line.withValues(alpha: 0.6))),
                            AnimatedFractionallySizedBox(
                              duration: GhMotion.of(context).css(GhDurations.progress),
                              curve: GhCurves.outExpo,
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: fraction,
                              heightFactor: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: tokens.accent, borderRadius: BorderRadius.circular(999)),
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
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final tr = context.tr.common;
    final (String label, Color color, FaIconData? icon) = switch (status) {
      TaskStatus.queued => (tr.queued, tokens.muted, null),
      TaskStatus.running => (tr.active, tokens.accentBright, GhIcons.refresh),
      TaskStatus.paused => (tr.paused, tokens.amber, GhIcons.pause),
      TaskStatus.completed => (tr.done, tokens.mint, GhIcons.circleCheck),
      TaskStatus.error => (tr.task_error_status, tokens.danger, GhIcons.circleX),
    };
    return Container(
      key: ValueKey('task-status-${status.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: status == TaskStatus.queued ? 0.15 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[GhIcon(icon, size: 10, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: status == TaskStatus.queued ? color.withValues(alpha: 0.7) : color,
            ),
          ),
        ],
      ),
    );
  }
}
