import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/projects.dart';
import '../logic/running_projects.dart';
import 'providers.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/toast.dart';
import 'title_bar_theme.dart';

const timerStartDelayMs = 3000;

class RunningProject {
  const RunningProject({required this.id, required this.name, required this.version, required this.startedAtMs});

  final String id;
  final String name;
  final String version;
  final int startedAtMs;
}

class RunningProjectsSource {
  const RunningProjectsSource({required this.load, required this.launched, required this.exited, required this.stop});

  factory RunningProjectsSource.native() {
    return RunningProjectsSource(
      load: () async {
        final projects = await fetchRunningProjects();
        return [
          for (final project in projects)
            RunningProject(
              id: project.id,
              name: project.name,
              version: project.version,
              startedAtMs: project.launchedAtMs.toInt() + timerStartDelayMs,
            ),
        ];
      },
      launched: () => AppEvents.payloads(AppEventKind.projectLaunched, (event) => event.projectLaunched).map(
        (project) => RunningProject(
          id: project.id,
          name: project.name,
          version: project.version,
          startedAtMs: DateTime.now().millisecondsSinceEpoch + timerStartDelayMs,
        ),
      ),
      exited: () => AppEvents.payloads(AppEventKind.projectExited, (event) => event.projectExited).map(
        (project) => project.id,
      ),
      stop: ProjectsApi.stop,
    );
  }

  final Future<List<RunningProject>> Function() load;
  final Stream<RunningProject> Function() launched;
  final Stream<String> Function() exited;
  final Future<void> Function(String id) stop;
}

String formatDuration(int ms) {
  final totalSeconds = math.max(0, ms ~/ 1000);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

String runningProjectsDescription(int count, [Translations? translations]) =>
    (translations ?? t).common.running_projects_desc(count: count);

class RunningProjectsChip extends ConsumerStatefulWidget {
  const RunningProjectsChip({super.key, this.source, this.onOpenConsole});

  final RunningProjectsSource? source;
  final void Function(String id, String name)? onOpenConsole;

  @override
  ConsumerState<RunningProjectsChip> createState() => _RunningProjectsChipState();
}

class _RunningProjectsChipState extends ConsumerState<RunningProjectsChip> {
  final MenuController _menu = MenuController();
  final List<RunningProject> _running = [];
  final List<StreamSubscription<Object>> _subscriptions = [];
  Timer? _ticker;
  int _now = DateTime.now().millisecondsSinceEpoch;
  bool _open = false;

  RunningProjectsSource get _source => widget.source ?? ref.read(runningProjectsSourceProvider);

  @override
  void initState() {
    super.initState();
    final source = _source;
    _subscriptions.add(source.launched().listen(_onLaunched, onError: (Object _) {}));
    _subscriptions.add(source.exited().listen(_onExited, onError: (Object _) {}));
    _loadInitial(source);
  }

  Future<void> _loadInitial(RunningProjectsSource source) async {
    List<RunningProject> projects;
    try {
      projects = await source.load();
    } on Object {
      return;
    }
    if (!mounted || projects.isEmpty) return;
    final known = _running.map((project) => project.id).toSet();
    final adopted = projects.where((project) => !known.contains(project.id)).toList();
    if (adopted.isEmpty) return;
    setState(() => _running.addAll(adopted));
    _syncTicker();
  }

  void _onLaunched(RunningProject project) {
    if (!mounted || _running.any((existing) => existing.id == project.id)) return;
    setState(() => _running.add(project));
    _syncTicker();
  }

  void _onExited(String id) {
    if (!mounted) return;
    setState(() => _running.removeWhere((project) => project.id == id));
    if (_running.isEmpty && _menu.isOpen) _menu.close();
    _syncTicker();
  }

  void _syncTicker() {
    if (_running.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _now = DateTime.now().millisecondsSinceEpoch;
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now().millisecondsSinceEpoch);
    });
  }

  Future<void> _stop(String id) async {
    try {
      await _source.stop(id);
    } on Object catch (error) {
      pushToast(GhToastType.error, '$error');
    }
  }

  void _openConsole(RunningProject project) {
    _menu.close();
    final void Function(String id, String name) handler =
        widget.onOpenConsole ?? ref.read(titleBarConsoleOpenerProvider);
    handler(project.id, project.name);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_running.isEmpty) return const SizedBox.shrink();
    final tokens = TitleBarTokens.of(context);
    final maxListHeight = math.min(MediaQuery.sizeOf(context).height * 0.6, 416.0);
    return MenuAnchor(
      controller: _menu,
      style: tokens.menuStyle(),
      alignmentOffset: const Offset(0, 8),
      onOpen: () => setState(() => _open = true),
      onClose: () {
        if (mounted) setState(() => _open = false);
      },
      menuChildren: [
        SizedBox(
          width: 276,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: tokens.line.withValues(alpha: 0.5))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.common.running.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: tokens.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      runningProjectsDescription(_running.length, context.tr),
                      style: TextStyle(fontSize: 10, color: tokens.muted.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final project in _running)
                        _RunningProjectRow(
                          key: ValueKey('running-${project.id}'),
                          project: project,
                          now: _now,
                          onOpenConsole: () => _openConsole(project),
                          onStop: () => _stop(project.id),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) => TitleBarButton(
        key: const ValueKey('running-projects-chip'),
        semanticLabel: context.tr.common.running,
        expanded: _open,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        builder: (context, hovered) => Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: tokens.overlay,
            borderRadius: BorderRadius.circular(tokens.itemRadius),
            border: Border.all(color: hovered ? tokens.accent : tokens.line.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: tokens.mint, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${_running.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: hovered ? tokens.ink : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunningProjectRow extends StatefulWidget {
  const _RunningProjectRow({
    super.key,
    required this.project,
    required this.now,
    required this.onOpenConsole,
    required this.onStop,
  });

  final RunningProject project;
  final int now;
  final VoidCallback onOpenConsole;
  final VoidCallback onStop;

  @override
  State<_RunningProjectRow> createState() => _RunningProjectRowState();
}

class _RunningProjectRowState extends State<_RunningProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final project = widget.project;
    final subtitle =
        '${project.version.isNotEmpty ? 'Godot ${project.version} · ' : ''}${formatDuration(widget.now - project.startedAtMs)}';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? tokens.raised : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.itemRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: TitleBarButton(
                semanticLabel: '${context.tr.common.console_title} - ${project.name}',
                onPressed: widget.onOpenConsole,
                builder: (context, hovered) => Opacity(
                  opacity: hovered ? 0.8 : 1,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tokens.mint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(tokens.btnRadius),
                        ),
                        child: GhIcon(GhIcons.terminal, size: 14, color: tokens.mint),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.ink),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: tokens.muted.withValues(alpha: 0.6),
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
            const SizedBox(width: 4),
            TitleBarIconButton(
              key: ValueKey('stop-${project.id}'),
              icon: GhIcons.x,
              width: 24,
              height: 24,
              radius: tokens.btnRadius,
              color: tokens.muted.withValues(alpha: 0.5),
              hoverColor: tokens.danger,
              hoverBackground: tokens.danger.withValues(alpha: 0.1),
              semanticLabel: '${context.tr.common.stop} ${project.name}',
              onPressed: widget.onStop,
            ),
          ],
        ),
      ),
    );
  }
}
