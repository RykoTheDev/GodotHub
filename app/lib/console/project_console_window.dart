import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/exports.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/ansi.dart';
import '../logic/console_log.dart';
import '../logic/format_bytes.dart';
import '../logic/running_projects.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_lifecycle.dart';
import '../state/app_signals.dart';
import '../state/settings.dart';
import '../titlebar/providers.dart' show openConsoleSignal;
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';
import 'console_request.dart';
import '../ui/shell/smooth_scroll.dart';

const consolePollMs = 180;
const consolePollIdleMs = 1000;
const consoleMaxRenderedLines = 2000;
const consoleMaxStoredLines = 5000;
const consolePillStorageKey = 'new_ui_console_pill';
const consolePillMargin = 10.0;
const consoleSnapDistance = 56.0;
const _logColor = Color(0xFFD7DAE0);

Offset clampConsolePill(Offset pos, Size frame, Size size) {
  final maxX = math.max(consolePillMargin, frame.width - size.width - consolePillMargin);
  final maxY = math.max(consolePillMargin, frame.height - size.height - consolePillMargin);
  return Offset(math.min(math.max(pos.dx, consolePillMargin), maxX), math.min(math.max(pos.dy, consolePillMargin), maxY));
}

Offset snapConsolePill(Offset pos, Size frame, Size size) {
  final clamped = clampConsolePill(pos, frame, size);
  final maxX = math.max(consolePillMargin, frame.width - size.width - consolePillMargin);
  final maxY = math.max(consolePillMargin, frame.height - size.height - consolePillMargin);
  final x = clamped.dx - consolePillMargin < consoleSnapDistance
      ? consolePillMargin
      : maxX - clamped.dx < consoleSnapDistance
      ? maxX
      : clamped.dx;
  final y = clamped.dy - consolePillMargin < consoleSnapDistance
      ? consolePillMargin
      : maxY - clamped.dy < consoleSnapDistance
      ? maxY
      : clamped.dy;
  return Offset(x, y);
}

@immutable
class ConsoleTabState {
  const ConsoleTabState({
    required this.name,
    this.exportRun,
    this.lines = const [],
    this.nextSeq = 0,
    this.running = true,
    this.exitCode,
    this.done = false,
    this.restored = false,
  });

  final String name;
  final ExportRun? exportRun;
  final List<ConsoleLine> lines;
  final int nextSeq;
  final bool running;
  final int? exitCode;
  final bool done;
  final bool restored;

  ConsoleTabState copyWith({
    ExportRun? exportRun,
    List<ConsoleLine>? lines,
    int? nextSeq,
    bool? running,
    ValueGetter<int?>? exitCode,
    bool? done,
    bool? restored,
  }) => ConsoleTabState(
    name: name,
    exportRun: exportRun ?? this.exportRun,
    lines: lines ?? this.lines,
    nextSeq: nextSeq ?? this.nextSeq,
    running: running ?? this.running,
    exitCode: exitCode != null ? exitCode() : this.exitCode,
    done: done ?? this.done,
    restored: restored ?? this.restored,
  );
}

enum _Tone { running, ok, error, neutral }

final Expando<List<AnsiSpan>> _spanCache = Expando<List<AnsiSpan>>('consoleSpans');

TextStyle _spanStyle(AnsiSpan span, Color base) {
  final css = ansiSpanStyle(span);
  var color = css.color != null ? colorFromHex(css.color!) : base;
  final opacity = css.opacity;
  if (opacity != null) color = color.withValues(alpha: color.a * opacity);
  return TextStyle(
    color: color,
    backgroundColor: css.backgroundColor != null ? colorFromHex(css.backgroundColor!) : null,
    fontWeight: css.fontWeight != null ? FontWeight.w600 : null,
    fontStyle: css.fontStyle != null ? FontStyle.italic : null,
    decoration: css.textDecoration != null ? TextDecoration.underline : null,
  );
}

class ConsoleRow extends StatelessWidget {
  const ConsoleRow({super.key, required this.line, required this.level});

  final ConsoleLine line;
  final ConsoleLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final spans = _spanCache[line] ??= parseAnsi(line.text);
    final base = line.text.contains('\u001b')
        ? _logColor
        : switch (level) {
            ConsoleLevel.error => theme.danger.withValues(alpha: 0.85),
            ConsoleLevel.warning => theme.amber.withValues(alpha: 0.85),
            ConsoleLevel.info => _logColor,
          };
    return Text.rich(
      spans.isEmpty
          ? const TextSpan(text: ' ')
          : TextSpan(
              children: [for (final span in spans) TextSpan(text: span.text, style: _spanStyle(span, base))],
            ),
      style: TextStyle(color: base),
    );
  }
}

class ProjectConsoleWindow extends ConsumerStatefulWidget {
  const ProjectConsoleWindow({super.key, this.prefs});

  final UiPrefsStore? prefs;

  @override
  ConsumerState<ProjectConsoleWindow> createState() => _ProjectConsoleWindowState();
}

class _ProjectConsoleWindowState extends ConsumerState<ProjectConsoleWindow> {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final ScrollController _scroll = GhSmoothScrollController();
  final GlobalKey _pillKey = GlobalKey();
  final Map<String, ConsoleTabState> _states = {};
  final Set<ConsoleLevel> _hidden = {};
  bool _open = false;
  bool _minimized = false;
  bool _fullscreen = true;
  String? _activeId;
  Offset? _pillPos;
  Size _frame = Size.zero;
  Timer? _poll;
  (bool, bool, String?) _pollKey = (false, false, null);
  bool _fetching = false;
  bool _pinned = true;
  bool _restoredOnce = false;
  int? _dragPointer;
  Offset _dragOffset = Offset.zero;
  Offset _dragStart = Offset.zero;
  bool _dragMoved = false;

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  @override
  void initState() {
    super.initState();
    try {
      final raw = _prefs.getItem(consolePillStorageKey);
      final parsed = raw == null ? null : jsonDecode(raw);
      if (parsed is Map && parsed['x'] is num && parsed['y'] is num) {
        _pillPos = Offset((parsed['x'] as num).toDouble(), (parsed['y'] as num).toDouble());
      }
    } catch (_) {}
    _scroll.addListener(_onScroll);
    _subscriptions
      ..add(
        AppEvents.of(AppEventKind.exportStarted).listen((event) {
          final run = event.exportRun;
          if (run != null) _openConsole(run.id, name: '${run.projectName} · ${run.presetName}', exportRun: run);
        }),
      )
      ..add(
        AppEvents.of(AppEventKind.exportFinished).listen((event) {
          final run = event.exportRun;
          if (run != null) _patch(run.id, (s) => s.copyWith(exportRun: run));
        }),
      )
      ..add(
        AppEvents.of(AppEventKind.projectLaunched).listen((event) {
          final payload = event.projectLaunched;
          if (payload == null || !payload.console) return;
          _apply(() {
            _states[payload.id] = ConsoleTabState(name: payload.name);
            _activeId = payload.id;
            _open = true;
            _minimized = false;
            _pinToBottom();
          });
        }),
      )
      ..add(
        AppEvents.of(AppEventKind.projectConsoleExit).listen((event) {
          final exit = event.consoleExit;
          if (exit != null) _patch(exit.id, (s) => s.copyWith(running: false, exitCode: () => exit.code));
        }),
      )
      ..add(
        AppSignals.on(openConsoleSignal).listen((signal) {
          final request = ConsoleRequest.from(signal.detail);
          if (request != null) _openConsole(request.id, name: request.name, exportRun: request.exportRun);
        }),
      );
  }

  @override
  void dispose() {
    _poll?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _pinToBottom() {
    _pinned = true;
    _stick();
  }

  void _stick([int attempt = 0]) => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_pinned || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels <= 0.5) return;
    _scroll.jumpTo(position.maxScrollExtent);
    if (attempt < 4) _stick(attempt + 1);
  });

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    _pinned = position.maxScrollExtent - position.pixels < 24;
  }

  void _apply(VoidCallback change) {
    if (!mounted) return;
    setState(change);
    _syncPolling();
  }

  void _patch(String id, ConsoleTabState Function(ConsoleTabState state) update) {
    final existing = _states[id];
    if (existing == null || !mounted) return;
    setState(() => _states[id] = update(existing));
  }

  void _openConsole(String id, {String? name, ExportRun? exportRun}) => _apply(() {
    final existing = _states[id];
    _states[id] = existing != null ? existing.copyWith(exportRun: exportRun) : ConsoleTabState(name: name ?? id, exportRun: exportRun);
    _activeId = id;
    _open = true;
    _minimized = false;
    _pinToBottom();
  });

  void _restoreRunning() {
    if (_restoredOnce) return;
    _restoredOnce = true;
    fetchRunningProjects().then((running) {
      final captured = running.where((p) => p.console).toList();
      if (captured.isEmpty || !mounted) return;
      setState(() {
        for (final project in captured) {
          _states.putIfAbsent(project.id, () => ConsoleTabState(name: project.name));
        }
      });
    }, onError: (Object _) {});
  }

  void _syncPolling() {
    final key = (_open, _minimized, _activeId);
    if (key == _pollKey) return;
    _pollKey = key;
    _poll?.cancel();
    _poll = null;
    final id = _activeId;
    if (!_open || id == null) return;
    _tick(id);
    _poll = Timer.periodic(Duration(milliseconds: _minimized ? consolePollIdleMs : consolePollMs), (_) => _tick(id));
  }

  Future<void> _tick(String id) async {
    final current = _states[id];
    if ((current?.done ?? false) || _fetching || ghAppHidden()) return;
    _fetching = true;
    try {
      final snapshot = await ProjectsApi.getConsole(id, BigInt.from(current?.nextSeq ?? 0));
      ExportRun? exportRun;
      final tracked = current?.exportRun;
      if (tracked != null) {
        try {
          exportRun = await ExportsApi.get(id);
        } catch (_) {
          exportRun = tracked;
        }
      }
      if (!mounted || _activeId != id || !_open) return;
      final existing = _states[id];
      final nextSeq = snapshot.nextSeq.toInt();
      final restarted = existing != null && nextSeq < existing.nextSeq;
      final done = !snapshot.running && (exportRun == null || exportRun.status != 'running');
      if (existing != null &&
          !restarted &&
          snapshot.lines.isEmpty &&
          snapshot.running == existing.running &&
          snapshot.exitCode == existing.exitCode &&
          snapshot.restored == existing.restored &&
          done == existing.done &&
          (exportRun ?? existing.exportRun) == existing.exportRun) {
        return;
      }
      final merged = restarted || existing == null ? snapshot.lines : [...existing.lines, ...snapshot.lines];
      final lines = merged.length > consoleMaxStoredLines ? merged.sublist(merged.length - consoleMaxStoredLines) : merged;
      setState(() {
        _states[id] = ConsoleTabState(
          name: existing?.name ?? id,
          exportRun: exportRun ?? existing?.exportRun,
          lines: lines,
          nextSeq: nextSeq,
          running: snapshot.running,
          exitCode: snapshot.exitCode,
          done: done,
          restored: snapshot.restored,
        );
      });
    } catch (_) {
      if (mounted && _activeId == id) _patch(id, (s) => s.copyWith(running: false, done: true));
    } finally {
      _fetching = false;
    }
  }

  void _closeTab(String id) => _apply(() {
    _states.remove(id);
    if (_activeId != id) return;
    _activeId = _states.keys.lastOrNull;
    if (_activeId == null) _open = false;
  });

  void _copyLog() {
    final state = _states[_activeId];
    if (state == null) return;
    Clipboard.setData(ClipboardData(text: state.lines.map((line) => stripAnsi(line.text)).join('\n'))).ignore();
  }

  void _clearLog() {
    final id = _activeId;
    if (id == null) return;
    _pinToBottom();
    _patch(id, (s) => s.copyWith(lines: const []));
    ProjectsApi.clearConsole(id).catchError((Object error) => ghToasts.pushToast(GhToastType.error, '$error'));
  }

  void _stop() {
    final id = _activeId;
    if (id == null) return;
    final action = _states[id]?.exportRun != null
        ? ExportsApi.cancel(id)
        : id.startsWith(toolConsolePrefix)
        ? ExportsApi.stopTool(id)
        : ProjectsApi.stop(id);
    action.catchError((Object error) => ghToasts.pushToast(GhToastType.error, '$error'));
  }

  Size get _pillSize => (_pillKey.currentContext?.findRenderObject() as RenderBox?)?.size ?? Size.zero;

  void _pillDown(PointerDownEvent event) {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    final wrap = context.findRenderObject() as RenderBox?;
    if (box == null || wrap == null) return;
    final origin = wrap.globalToLocal(box.localToGlobal(Offset.zero));
    setState(() => _pillPos = origin);
    _dragPointer = event.pointer;
    _dragOffset = wrap.globalToLocal(event.position) - origin;
    _dragStart = event.position;
    _dragMoved = false;
  }

  void _pillMove(PointerMoveEvent event) {
    final wrap = context.findRenderObject() as RenderBox?;
    if (_dragPointer != event.pointer || wrap == null) return;
    final delta = event.position - _dragStart;
    if (!_dragMoved && delta.dx.abs() + delta.dy.abs() > 4) _dragMoved = true;
    setState(() => _pillPos = clampConsolePill(wrap.globalToLocal(event.position) - _dragOffset, _frame, _pillSize));
  }

  void _pillUp(PointerEvent event) {
    if (_dragPointer != event.pointer) return;
    _dragPointer = null;
    if (!_dragMoved) {
      _apply(() {
        _minimized = false;
        _pinToBottom();
      });
      return;
    }
    final pos = _pillPos;
    if (pos == null) return;
    final snapped = snapConsolePill(pos, _frame, _pillSize);
    try {
      _prefs.setItem(consolePillStorageKey, jsonEncode({'x': snapped.dx, 'y': snapped.dy}));
    } catch (_) {}
    setState(() => _pillPos = snapped);
  }

  String _exitLabel(ConsoleTabState? state) {
    final tr = context.tr.common;
    if (state?.running ?? false) return tr.running;
    final code = state?.exitCode;
    if (code == null) return tr.console_finished;
    return code == 0 ? tr.console_exit_ok : tr.console_exit_code.args({'code': code});
  }

  ({String label, _Tone tone})? _status(ConsoleTabState? state) {
    if (state == null) return null;
    final run = state.exportRun;
    if (run != null) {
      return (
        label: run.status == 'running'
            ? ghTr('build_export.running', args: {'preset': run.presetName})
            : ghTr('build_export.${run.status}'),
        tone: switch (run.status) {
          'running' => _Tone.running,
          'succeeded' => _Tone.ok,
          'failed' => _Tone.error,
          _ => _Tone.neutral,
        },
      );
    }
    final code = state.exitCode;
    return (
      label: _exitLabel(state),
      tone: state.running
          ? _Tone.running
          : code == null
          ? _Tone.neutral
          : code == 0
          ? _Tone.ok
          : _Tone.error,
    );
  }

  Widget _iconButton(
    GhTheme theme, {
    required String label,
    required FaIconData icon,
    required VoidCallback onPressed,
    bool danger = false,
    double size = 3,
  }) => GhTooltip(
    message: label,
    side: GhSide.bottom,
    child: GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      builder: (context, states) => GhAnimatedBox(
        width: theme.space(7),
        height: theme.space(7),
        color: states.active
            ? (danger ? theme.danger.withValues(alpha: 0.1) : theme.raised)
            : (danger ? theme.danger : theme.raised).withValues(alpha: 0),
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        alignment: Alignment.center,
        child: GhIcon(icon, size: theme.space(size), color: states.active ? (danger ? theme.danger : theme.ink) : theme.muted),
      ),
    ),
  );

  Widget _dot(GhTheme theme, Color color) => Container(
    width: theme.space(1.5),
    height: theme.space(1.5),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _levelPill(GhTheme theme, ConsoleLevel level, int count) {
    final tr = context.tr.common;
    final active = !_hidden.contains(level);
    final label = switch (level) {
      ConsoleLevel.error => tr.console_filter_errors,
      ConsoleLevel.warning => tr.console_filter_warnings,
      ConsoleLevel.info => tr.console_filter_info,
    };
    final radius = BorderRadius.circular(theme.space(3));
    return GhTooltip(
      message: label,
      side: GhSide.bottom,
      child: GhPressable(
        onPressed: () => setState(() {
          if (!_hidden.remove(level)) _hidden.add(level);
          _pinToBottom();
        }),
        toggled: active,
        semanticLabel: label,
        borderRadius: radius,
        builder: (context, states) {
          final (background, foreground, border) = !active
              ? (
                  theme.raised.withValues(alpha: 0),
                  states.active ? theme.muted : theme.muted.withValues(alpha: 0.45),
                  theme.line.withValues(alpha: 0.5),
                )
              : switch (level) {
                  ConsoleLevel.error => (theme.danger.withValues(alpha: 0.15), theme.danger, theme.danger.withValues(alpha: 0.35)),
                  ConsoleLevel.warning => (theme.amber.withValues(alpha: 0.15), theme.amber, theme.amber.withValues(alpha: 0.35)),
                  ConsoleLevel.info => (theme.raised, theme.ink, theme.line),
                };
          return GhAnimatedBox(
            height: theme.space(6),
            color: background,
            borderRadius: radius,
            border: Border.all(color: border),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                _dot(theme, foreground.withValues(alpha: foreground.a * (active ? 1 : 0.5))),
                Text(
                  label,
                  style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: foreground),
                ),
                Text(
                  '$count',
                  style: theme
                      .text(
                        size: GhTextSize.x3s,
                        weight: GhWeight.semibold,
                        mono: true,
                        color: foreground.withValues(alpha: foreground.a * (active ? 0.8 : 0.6)),
                      )
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _window(GhTheme theme, ConsoleTabState? state, List<ConsoleEntry> entries, Map<ConsoleLevel, int> counts) {
    final tr = context.tr.common;
    final status = _status(state);
    final visible = [
      for (final entry in entries)
        if (!_hidden.contains(entry.level)) entry,
    ];
    final trimmed = (state?.lines.length ?? 0) - entries.length;
    final filteredOut = entries.length - visible.length;
    final hint = theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6));
    final run = state?.exportRun;
    final running = state?.running ?? false;
    final exitCode = state?.exitCode;
    final hints = <Widget>[
      if (state?.restored ?? false)
        Padding(
          padding: EdgeInsets.only(bottom: theme.space(2)),
          child: Text(running ? tr.console_resumed_hint : tr.console_previous_hint, style: hint),
        ),
      if (trimmed > 0)
        Padding(
          padding: EdgeInsets.only(bottom: theme.space(2)),
          child: Text(ghTr('console_trimmed', count: trimmed), style: hint),
        ),
    ];
    final logStyle = theme.text(mono: true, color: _logColor).copyWith(fontSize: theme.rem(0.71875), height: 1.55);
    final logPadding = EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2));
    final Widget log;
    if (visible.isEmpty) {
      log = Padding(
        padding: logPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...hints,
            Expanded(
              child: Center(
                child: Text(
                  entries.isNotEmpty
                      ? ghTr('console_no_matches', count: filteredOut)
                      : running
                      ? tr.console_waiting
                      : tr.console_empty,
                  style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      log = SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          padding: logPadding,
          itemCount: visible.length + (hints.isEmpty ? 0 : 1),
          itemBuilder: (context, index) {
            if (hints.isNotEmpty && index == 0) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: hints);
            }
            final entry = visible[index - (hints.isEmpty ? 0 : 1)];
            return ConsoleRow(key: ValueKey(entry.line.seq), line: entry.line, level: entry.level);
          },
        ),
      );
    }
    final outline = theme.outline.withValues(alpha: 0.5);
    return Semantics(
      container: true,
      label: tr.console_title,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.raised,
          borderRadius: BorderRadius.circular(theme.radiusXl),
          border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: theme.space(11),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
              decoration: BoxDecoration(
                color: theme.overlay.withValues(alpha: 0.6),
                border: Border(bottom: BorderSide(color: outline)),
              ),
              child: Row(
                spacing: theme.space(2),
                children: [
                  GhIcon(GhIcons.terminal, size: theme.space(3.5), color: theme.muted),
                  Text(
                    tr.console_title.toUpperCase(),
                    style: theme.text(
                      size: GhTextSize.xs,
                      weight: GhWeight.semibold,
                      color: theme.muted.withValues(alpha: 0.8),
                      letterSpacingEm: 0.05,
                    ),
                  ),
                  if (status != null)
                    Builder(
                      builder: (context) {
                        final (background, foreground) = switch (status.tone) {
                          _Tone.running => (theme.mint.withValues(alpha: 0.1), theme.mint),
                          _Tone.ok => (theme.accent.withValues(alpha: 0.1), theme.accentBright),
                          _Tone.error => (theme.danger.withValues(alpha: 0.1), theme.danger),
                          _Tone.neutral => (theme.overlay, theme.muted),
                        };
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(theme.radiusTag)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(1.5),
                            children: [
                              if (status.tone == _Tone.running) _dot(theme, theme.mint),
                              Text(
                                status.label,
                                style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: foreground),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const Spacer(),
                  if (running)
                    _iconButton(
                      theme,
                      label: run != null ? ghTr('build_export.cancel_export') : tr.stop,
                      icon: GhIcons.square,
                      danger: true,
                      onPressed: _stop,
                    ),
                  _iconButton(theme, label: tr.console_clear, icon: GhIcons.trash, onPressed: _clearLog),
                  _iconButton(theme, label: tr.console_copy, icon: GhIcons.clone, onPressed: _copyLog),
                  _iconButton(
                    theme,
                    label: _fullscreen ? tr.collapse : tr.expand,
                    icon: _fullscreen ? GhIcons.windowRestore : GhIcons.windowMaximize,
                    onPressed: () => setState(() => _fullscreen = !_fullscreen),
                  ),
                  _iconButton(theme, label: tr.console_minimize, icon: GhIcons.minus, onPressed: () => _apply(() => _minimized = true)),
                  _iconButton(theme, label: tr.close, icon: GhIcons.x, size: 3.5, onPressed: () => _apply(() => _open = false)),
                ],
              ),
            ),
            Container(
              height: theme.space(10),
              padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
              decoration: BoxDecoration(
                color: theme.overlay.withValues(alpha: 0.3),
                border: Border(bottom: BorderSide(color: outline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GhScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(spacing: theme.space(1), children: [for (final id in _states.keys) _tab(theme, id, _states[id]!)]),
                    ),
                  ),
                  SizedBox(width: theme.space(2)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(1),
                    children: [for (final level in consoleLevels) _levelPill(theme, level, counts[level] ?? 0)],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: const Color(0x59000000),
                child: DefaultTextStyle(style: logStyle, child: log),
              ),
            ),
            if (run != null && run.status != 'running')
              Container(
                padding: EdgeInsets.all(theme.space(3)),
                decoration: BoxDecoration(
                  color: theme.overlay,
                  border: Border(top: BorderSide(color: theme.line)),
                ),
                child: Row(
                  spacing: theme.space(3),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: theme.space(1),
                        children: [
                          Text(
                            '${ghTr('build_export.${run.status}')}${run.sizeBytes != null ? ' · ${formatBigBytes(run.sizeBytes!)}' : ''}',
                            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                          ),
                          Text(
                            run.outputPath,
                            style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                          ),
                          if (run.error != null)
                            Text(
                              run.error!,
                              style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                            ),
                          if (run.status == 'cancelled')
                            Text(
                              ghTr('build_export.cancel_hint'),
                              style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                            ),
                        ],
                      ),
                    ),
                    if (run.status == 'succeeded')
                      GhOutlineAction(
                        onPressed: () =>
                            ExportsApi.openFolder(run.id).catchError((Object error) => ghToasts.pushToast(GhToastType.error, '$error')),
                        icon: GhIcons.folder,
                        label: ghTr('build_export.open_folder'),
                      ),
                  ],
                ),
              ),
            if (state != null && run == null && !running && exitCode != null && exitCode != 0)
              Container(
                height: theme.space(8),
                padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
                decoration: BoxDecoration(
                  color: theme.danger.withValues(alpha: 0.1),
                  border: Border(top: BorderSide(color: theme.danger.withValues(alpha: 0.3))),
                ),
                child: Row(
                  spacing: theme.space(2),
                  children: [
                    GhIcon(GhIcons.chevronUp, size: theme.space(3), color: theme.danger),
                    Expanded(
                      child: Text(
                        tr.console_crash_hint.args({'code': exitCode}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.x2s, color: theme.danger),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tab(GhTheme theme, String id, ConsoleTabState state) {
    final active = id == _activeId;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: () => _apply(() {
        _activeId = id;
        _pinToBottom();
      }),
      selected: active,
      borderRadius: radius,
      builder: (context, states) {
        final color = active
            ? theme.accentBright
            : states.active
            ? theme.ink
            : theme.muted;
        return GhAnimatedBox(
          height: theme.space(6),
          color: active
              ? theme.accent.withValues(alpha: 0.15)
              : states.active
              ? theme.raised
              : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.space(32)),
                child: Text(
                  state.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: color),
                ),
              ),
              GhPressable(
                onPressed: () => _closeTab(id),
                canRequestFocus: false,
                semanticLabel: '${context.tr.common.close} ${state.name}',
                builder: (context, inner) => GhIcon(
                  GhIcons.x,
                  size: theme.space(2.5),
                  color: color.withValues(alpha: color.a * (inner.active ? 1 : 0.6)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(GhTheme theme, ConsoleTabState? state, Map<ConsoleLevel, int> counts) {
    final tr = context.tr.common;
    final errors = counts[ConsoleLevel.error] ?? 0;
    final warnings = counts[ConsoleLevel.warning] ?? 0;
    final running = state?.running ?? false;
    final code = state?.exitCode;
    Widget badge(int count, Color color) => Container(
      constraints: BoxConstraints(minWidth: theme.space(4)),
      height: theme.space(4),
      padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(theme.space(2))),
      child: Text(
        '$count',
        style: theme
            .text(size: GhTextSize.x3s, weight: GhWeight.bold, color: color)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: tr.console_pill_hint,
      child: MouseRegion(
        cursor: _dragPointer != null ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Listener(
          onPointerDown: _pillDown,
          onPointerMove: _pillMove,
          onPointerUp: _pillUp,
          onPointerCancel: _pillUp,
          child: Container(
            key: _pillKey,
            height: theme.space(9),
            constraints: BoxConstraints(maxWidth: math.max(0, _frame.width - theme.space(6))),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5)),
            decoration: BoxDecoration(
              color: theme.raised,
              borderRadius: BorderRadius.circular(theme.space(4.5)),
              border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                GhIcon(GhIcons.grip, size: theme.space(3.5), color: theme.muted.withValues(alpha: 0.4)),
                _dot(
                  theme,
                  running
                      ? theme.mint
                      : (code != null && code != 0)
                      ? theme.danger
                      : theme.muted.withValues(alpha: 0.6),
                ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: theme.space(40)),
                    child: Text(
                      state?.name ?? tr.console_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                    ),
                  ),
                ),
                Text(
                  _exitLabel(state),
                  style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.7)),
                ),
                if (errors > 0) badge(errors, theme.danger) else if (warnings > 0) badge(warnings, theme.amber),
                GhIcon(GhIcons.windowMaximize, size: theme.space(3), color: theme.muted.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings != null && settings.builtinConsole) _restoreRunning();
    final state = _states[_activeId];
    final lines = state?.lines ?? const <ConsoleLine>[];
    final entries = annotateConsoleLines(
      lines.length > consoleMaxRenderedLines ? lines.sublist(lines.length - consoleMaxRenderedLines) : lines,
    );
    final counts = countConsoleLevels(entries);
    if (_pinned) _stick();
    return LayoutBuilder(
      builder: (context, constraints) {
        _frame = constraints.biggest;
        if (!_open) return const SizedBox.expand();
        if (!_minimized) {
          final window = _window(theme, state, entries, counts);
          if (_fullscreen) return Padding(padding: EdgeInsets.all(theme.space(3)), child: window);
          final edge = theme.space(2);
          return Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: edge, bottom: edge),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.max(0, _frame.width - edge * 2),
                  maxHeight: math.max(0, _frame.height - edge * 2),
                ),
                child: SizedBox(width: theme.rem(42), height: theme.space(96), child: window),
              ),
            ),
          );
        }
        final pill = _pill(theme, state, counts);
        final pos = _pillPos;
        if (pos == null || _frame.width <= 0) {
          return Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: theme.space(3), bottom: theme.space(3)),
              child: pill,
            ),
          );
        }
        final clamped = clampConsolePill(pos, _frame, _pillSize);
        return Stack(
          children: [Positioned(left: clamped.dx, top: clamped.dy, child: pill)],
        );
      },
    );
  }
}
