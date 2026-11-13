import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/events.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/duration.dart';
import '../logic/last_opened.dart';
import '../logic/settings_copy.dart';
import '../motion/motion.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/godot_versions.dart';
import '../state/keyboard_shortcuts.dart' show setTabSignal;
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../todos/todo_due_tile.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart';
import '../ui/feedback/toast.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'activity_panel.dart';
import 'dashboard_logic.dart';
import 'dashboard_parts.dart';

const _runningStartDelayMs = 3000;

class DashboardRunningProject {
  const DashboardRunningProject({required this.id, required this.name, required this.version, required this.startedAtMs});

  final String id;
  final String name;
  final String version;
  final int startedAtMs;
}

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key, this.connected = false, this.active = true, this.prefs});

  final bool connected;
  final bool active;
  final UiPrefsStore? prefs;

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final TextEditingController _nameDraft = TextEditingController();
  final FocusNode _nameNode = FocusNode(debugLabel: 'Dashboard name');
  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _osName;
  int _greetingHour = DateTime.now().hour;
  TimeInsights? _insights;
  List<DashboardRunningProject> _running = const [];
  bool _editingName = false;
  bool _nameCancelled = false;
  bool _nameHovered = false;
  bool _nameFocusWithin = false;
  Timer? _greetingTimer;
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    Api.getOsUsername().then(
      (name) {
        if (mounted) setState(() => _osName = name);
      },
      onError: (Object _) {
        if (mounted) setState(() => _osName = null);
      },
    );
    _nameNode.addListener(() {
      if (!_nameNode.hasFocus && _editingName) _commitName();
    });
    _subscriptions
      ..add(
        AppEvents.payloads(AppEventKind.projectLaunched, (event) => event.projectLaunched).listen((p) {
          if (!widget.active || _running.any((x) => x.id == p.id)) return;
          setState(
            () => _running = [
              ..._running,
              DashboardRunningProject(
                id: p.id,
                name: p.name,
                version: p.version,
                startedAtMs: DateTime.now().millisecondsSinceEpoch + _runningStartDelayMs,
              ),
            ],
          );
        }),
      )
      ..add(
        AppEvents.payloads(AppEventKind.projectExited, (event) => event.projectExited).listen((p) {
          if (!widget.active) return;
          setState(() => _running = _running.where((x) => x.id != p.id).toList());
        }),
      );
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _epoch++;
      _activate();
    } else if (!widget.active && oldWidget.active) {
      _greetingTimer?.cancel();
      _greetingTimer = null;
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _greetingTimer?.cancel();
    _nameDraft.dispose();
    _nameNode.dispose();
    super.dispose();
  }

  void _activate() {
    Api.getTimeInsights().then((value) {
      if (mounted) setState(() => _insights = value);
    }, onError: (Object _) {});
    Api.listRunningProjects().then((list) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(
        () => _running = [
          for (final p in list)
            DashboardRunningProject(
              id: p.id,
              name: p.name,
              version: p.version,
              startedAtMs: (p.launchedAtMs > BigInt.zero ? p.launchedAtMs.toInt() : now) + _runningStartDelayMs,
            ),
        ],
      );
    }, onError: (Object _) {});
    _syncGreeting();
  }

  void _syncGreeting() {
    _greetingTimer?.cancel();
    final now = DateTime.now();
    if (now.hour != _greetingHour) setState(() => _greetingHour = now.hour);
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    _greetingTimer = Timer(next.difference(now) + const Duration(milliseconds: 50), () {
      if (mounted) _syncGreeting();
    });
  }

  void _saveName(AppSettings settings, String? name) {
    ref.read(settingsProvider.notifier).save(copySettings(settings, dashboardCustomName: () => name)).ignore();
  }

  void _commitName() {
    if (!_editingName) return;
    setState(() => _editingName = false);
    if (_nameCancelled) {
      _nameCancelled = false;
      return;
    }
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    final trimmed = _nameDraft.text.trim();
    _saveName(settings, trimmed.isEmpty ? null : trimmed);
  }

  void _cancelName() {
    _nameCancelled = true;
    setState(() => _editingName = false);
    _nameCancelled = false;
  }

  void _startEditingName(AppSettings settings) {
    final current = (settings.dashboardCustomName?.isNotEmpty ?? false) ? settings.dashboardCustomName! : (_osName ?? '');
    _nameDraft.text = current.length > 15 ? current.substring(0, 15) : current;
    setState(() => _editingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameNode.requestFocus();
      _nameDraft.selection = TextSelection(baseOffset: 0, extentOffset: _nameDraft.text.length);
    });
  }

  void _stopProject(String id) {
    ProjectsApi.stop(id).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
  }

  void _openEngine(String tag) {
    Api.openGodotVersion(tag).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
  }

  Widget _iconButton(
    GhTheme theme, {
    required FaIconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required Color hoverColor,
    required Color hoverBackground,
    GhSide side = GhSide.top,
    double iconSize = 4,
  }) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhTooltip(
      message: label,
      side: side,
      child: GhPressable(
        onPressed: onPressed,
        semanticLabel: label,
        borderRadius: radius,
        builder: (context, states) => GhAnimatedBox(
          padding: EdgeInsets.all(theme.space(1.5)),
          borderRadius: radius,
          color: states.active ? hoverBackground : hoverBackground.withValues(alpha: 0),
          child: GhIcon(icon, size: theme.space(iconSize), color: states.active ? hoverColor : color),
        ),
      ),
    );
  }

  Widget _nameEditor(GhTheme theme) {
    return TextFieldTapRegion(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1.5),
        children: [
          SizedBox(
            width: theme.space(64),
            child: GhTextInput(
              controller: _nameDraft,
              focusNode: _nameNode,
              size: GhTextSize.xl,
              weight: GhWeight.medium,
              placeholder: td('dashboard_name_placeholder'),
              onChanged: (value) {
                if (value.length > 15) {
                  _nameDraft.value = TextEditingValue(text: value.substring(0, 15), selection: const TextSelection.collapsed(offset: 15));
                }
              },
              onSubmitted: (_) => _commitName(),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                  _cancelName();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              background: theme.base,
              borderColor: theme.accent,
              focusBorderColor: theme.accent,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
            ),
          ),
          _iconButton(
            theme,
            icon: GhIcons.check,
            label: td('dashboard_rename_save'),
            onPressed: _commitName,
            color: theme.accent,
            hoverColor: theme.accent,
            hoverBackground: theme.accent.withValues(alpha: 0.1),
          ),
          _iconButton(
            theme,
            icon: GhIcons.x,
            label: td('cancel'),
            onPressed: _cancelName,
            color: theme.muted.withValues(alpha: 0.6),
            hoverColor: theme.ink,
            hoverBackground: theme.surface,
          ),
        ],
      ),
    );
  }

  Widget _hero(GhTheme theme, AppSettings settings) {
    final displayName = dashboardDisplayName(settings.dashboardCustomName, _osName);
    final greeting = td('greeting_${greetingKey(_greetingHour)}');
    final headline = theme.text(size: GhTextSize.x5l, weight: GhWeight.bold, color: theme.ink, lineHeight: 1.25);
    final revealed = _nameHovered || _nameFocusWithin;
    final hasCustom = settings.dashboardCustomName?.isNotEmpty ?? false;
    final Widget name = _editingName
        ? _nameEditor(theme)
        : Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                text: greeting,
                children: [
                  if (displayName.isNotEmpty) ...[
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: displayName,
                      style: TextStyle(color: theme.accentBright),
                    ),
                  ],
                ],
              ),
              style: headline,
            ),
          );
    return Container(
      margin: EdgeInsets.only(bottom: theme.space(4)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: widget.connected ? BorderRadius.zero : BorderRadius.circular(theme.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.accent.withValues(alpha: 0), theme.accent.withValues(alpha: 0.6), theme.accent.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(6), vertical: theme.space(7)),
            child: Row(
              spacing: theme.space(3),
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onFocusChange: (focused) => setState(() => _nameFocusWithin = focused),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _nameHovered = true),
                        onExit: (_) => setState(() => _nameHovered = false),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: theme.space(1.5),
                          children: [
                            Flexible(child: name),
                            if (!_editingName) ...[
                              _HoverReveal(
                                visible: revealed,
                                child: _iconButton(
                                  theme,
                                  icon: GhIcons.pencil,
                                  label: td('dashboard_rename_aria'),
                                  onPressed: () => _startEditingName(settings),
                                  color: theme.muted.withValues(alpha: 0.4),
                                  hoverColor: theme.ink,
                                  hoverBackground: theme.surface,
                                  side: GhSide.right,
                                  iconSize: 3.5,
                                ),
                              ),
                              if (hasCustom)
                                _HoverReveal(
                                  visible: revealed,
                                  child: _iconButton(
                                    theme,
                                    icon: GhIcons.x,
                                    label: td('dashboard_rename_reset'),
                                    onPressed: () => _saveName(settings, null),
                                    color: theme.muted.withValues(alpha: 0.4),
                                    hoverColor: theme.danger,
                                    hoverBackground: theme.danger.withValues(alpha: 0.1),
                                    side: GhSide.right,
                                    iconSize: 3.5,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _Clock(
                  active: widget.active,
                  timeFormat: LastOpenedTimeFormat.parse(settings.lastOpenedTimeFormat),
                  dateFormat: LastOpenedDateFormat.parse(settings.lastOpenedDateFormat),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(GhTheme theme, List<(int, Widget)> cells, {required int columns, required double gap}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [for (final (span, child) in cells) Expanded(flex: span, child: child)],
      ),
    );
  }

  Widget _kpis(GhTheme theme, List<Project> projects, bool wide) {
    final insights = _insights;
    final delta = monthDeltaPercent(insights);
    final cards = [
      DashKpiCard(
        label: td('dashboard_stat_projects'),
        icon: GhIcons.folder,
        value: '${projects.length}',
        animate: projects.length,
        gradient: const [Color(0xFF7AA0FF), Color(0xFF4F7CFF)],
        onPressed: () => AppSignals.emit(setTabSignal, 'projects'),
      ),
      DashKpiCard(
        label: td('dashboard_stat_total_time'),
        hint: td('dashboard_stat_total_time_hint'),
        icon: GhIcons.clock,
        value: formatDuration(totalProjectMs(projects)),
        gradient: const [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
        delay: 40,
      ),
      DashKpiCard(
        label: td('dashboard_insights_current_streak'),
        icon: GhIcons.rocket,
        value: td('dashboard_insights_days', count: insights?.currentStreakDays ?? 0),
        gradient: const [Color(0xFF4ADE80), Color(0xFF2FBF71)],
        delay: 80,
      ),
      DashKpiCard(
        label: td('dashboard_insights_this_month'),
        icon: GhIcons.arrowUpDown,
        value: formatDuration((insights?.thisMonthSeconds.toInt() ?? 0) * 1000),
        sub: delta == null
            ? null
            : delta >= 0
            ? td('dashboard_insights_delta_up', args: {'pct': delta})
            : td('dashboard_insights_delta_down', args: {'pct': delta.abs()}),
        subDown: delta != null && delta < 0,
        gradient: const [Color(0xFFFBBF24), Color(0xFFF0B132)],
        delay: 120,
      ),
    ];
    final columns = wide ? 4 : 2;
    final gap = theme.space(4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        for (var i = 0; i < cards.length; i += columns)
          _row(theme, [for (var c = i; c < i + columns; c++) (1, cards[c])], columns: columns, gap: gap),
      ],
    );
  }

  Widget _projectList(GhTheme theme, List<Project> list, LastOpenedTimeFormat timeFormat, {bool showOpened = true}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: theme.space(2),
    children: [for (final p in list) DashProjectRow(key: ValueKey(p.id), project: p, timeFormat: timeFormat, showOpened: showOpened)],
  );

  Widget _engines(GhTheme theme, List<InstalledGodotVersion> installed) {
    return DashPanel(
      title: td('dashboard_engines'),
      icon: GhIcons.rocket,
      delay: 300,
      child: installed.isEmpty
          ? DashEmptyCard(text: td('dashboard_engines_empty'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [for (final v in installed.take(4)) _EngineRow(version: v, onOpen: () => _openEngine(v.tag))],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final projects = ref.watch(projectsProvider.select((s) => s.data));
    final installed = ref.watch(godotVersionsProvider.select((s) => s.installed));
    final timeFormat = LastOpenedTimeFormat.parse(settings.lastOpenedTimeFormat);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final recent = recentProjects(projects);
    final pinned = pinnedProjects(projects);
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
      end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
      bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
    );
    final gap = theme.space(5);
    final topTime = _TopByTime(projects: projects);
    final recentPanel = DashPanel(
      title: td('dashboard_recent'),
      icon: GhIcons.history,
      delay: 200,
      child: recent.isNotEmpty ? _projectList(theme, recent, timeFormat) : DashEmptyCard(text: td('dashboard_recent_empty')),
    );
    final runningPanel = _RunningPanel(running: _running, onStop: _stopProject, active: widget.active);
    final pinnedPanel = DashPanel(
      title: td('dashboard_pinned'),
      icon: GhIcons.pin,
      delay: 260,
      child: pinned.isNotEmpty
          ? _projectList(theme, pinned, timeFormat, showOpened: false)
          : DashEmptyCard(text: td('dashboard_pinned_empty')),
    );
    final enginesPanel = _engines(theme, installed);
    final Widget grid = wide
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              _row(theme, [(7, topTime), (5, recentPanel)], columns: 2, gap: gap),
              _row(theme, [(1, runningPanel), (1, pinnedPanel), (1, enginesPanel)], columns: 3, gap: gap),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [topTime, recentPanel, runningPanel, pinnedPanel, enginesPanel],
          );
    return DashActivation(
      epoch: _epoch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end),
            child: _hero(theme, settings),
          ),
          Expanded(
            child: Padding(
              padding: scrollInsets,
              child: GhOverlayScrollArea(
                hideThumb: !settings.showScrollbars,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(theme.space(widget.connected ? 3 : 2), 0, theme.space(5), theme.space(4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: gap,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(1.5)),
                        child: const DashQuickActions(),
                      ),
                      _kpis(theme, projects, wide),
                      DashActivityPanel(insights: _insights, timeFormat: timeFormat, active: widget.active),
                      if (settings.projectTodosEnabled)
                        DashPanel(title: td('dashboard_todos'), icon: GhIcons.checkCircle, delay: 160, child: const TodoDueTile()),
                      grid,
                      SizedBox(height: theme.space(2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverReveal extends StatelessWidget {
  const _HoverReveal({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(opacity: visible ? 1 : 0, duration: GhDurations.interactive, child: child);
}

class _Clock extends StatefulWidget {
  const _Clock({required this.active, required this.timeFormat, required this.dateFormat});

  final bool active;
  final LastOpenedTimeFormat timeFormat;
  final LastOpenedDateFormat dateFormat;

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Clock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!widget.active) return;
    _now = DateTime.now();
    _schedule();
  }

  void _schedule() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    _timer = Timer(next.difference(now) + const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: theme.space(1),
      children: [
        Semantics(
          label: td('dashboard_clock_aria'),
          child: Text(
            formatTime(_now, widget.timeFormat),
            style: theme
                .text(size: GhTextSize.x3l, weight: GhWeight.semibold, color: theme.ink, lineHeight: 1)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        Text(
          formatDate(_now, widget.dateFormat),
          style: theme.text(size: GhTextSize.sm, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1),
        ),
      ],
    );
  }
}

class _TopByTime extends StatelessWidget {
  const _TopByTime({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final top = topProjectsByTime(projects);
    final max = top.fold(1, (m, p) => math.max(m, p.totalTimeSeconds.toInt()));
    final radius = BorderRadius.circular(theme.radiusItem);
    return DashPanel(
      title: td('dashboard_top_time'),
      icon: GhIcons.stopwatch,
      delay: 180,
      child: top.isEmpty
          ? DashEmptyCard(text: td('dashboard_top_time_empty'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2.5),
              children: [
                for (final (i, p) in top.indexed)
                  GhPressable(
                    key: ValueKey(p.id),
                    onPressed: () => AppSignals.emit(openProjectSignal, p.id),
                    borderRadius: radius,
                    builder: (context, states) {
                      final seconds = p.totalTimeSeconds.toInt();
                      return GhAnimatedBox(
                        padding: EdgeInsets.all(theme.space(2.5)),
                        color: states.active ? theme.raised : theme.overlay,
                        borderRadius: radius,
                        border: Border.all(
                          color: states.active ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          spacing: theme.space(3),
                          children: [
                            Container(
                              width: theme.space(6),
                              height: theme.space(6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.raised,
                                borderRadius: BorderRadius.circular(theme.radiusBtn),
                                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: theme.text(
                                  size: GhTextSize.x3s,
                                  weight: GhWeight.bold,
                                  color: states.active ? theme.accentBright : theme.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    spacing: theme.space(2),
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                                        ),
                                      ),
                                      Text(
                                        formatDuration(seconds * 1000),
                                        style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: theme.space(2)),
                                  Container(
                                    height: theme.space(1.5),
                                    decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(999)),
                                    clipBehavior: Clip.antiAlias,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: AnimatedFractionallySizedBox(
                                      duration: GhMotion.of(context).css(GhDurations.progress),
                                      curve: GhCurves.outExpo,
                                      widthFactor: math.max(seconds / max, 0.03),
                                      heightFactor: 1,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          gradient: LinearGradient(colors: [theme.accentDim, theme.accentBright]),
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
                    },
                  ),
              ],
            ),
    );
  }
}

class _RunningPanel extends StatefulWidget {
  const _RunningPanel({required this.running, required this.onStop, required this.active});

  final List<DashboardRunningProject> running;
  final ValueChanged<String> onStop;
  final bool active;

  @override
  State<_RunningPanel> createState() => _RunningPanelState();
}

class _RunningPanelState extends State<_RunningPanel> {
  int _now = DateTime.now().millisecondsSinceEpoch;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_RunningPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active || oldWidget.running.isEmpty != widget.running.isEmpty) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (!widget.active || widget.running.isEmpty) return;
    _now = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return DashPanel(
      title: td('dashboard_running'),
      icon: GhIcons.play,
      delay: 220,
      child: widget.running.isEmpty
          ? DashEmptyCard(text: td('dashboard_running_empty'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                for (final p in widget.running)
                  GhReveal(
                    key: ValueKey(p.id),
                    id: 'running:${p.id}',
                    child: Container(
                      padding: EdgeInsets.all(theme.space(2.5)),
                      decoration: BoxDecoration(
                        color: theme.overlay,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        border: Border.all(color: theme.mint.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        spacing: theme.space(3),
                        children: [
                          Container(
                            width: theme.space(2),
                            height: theme.space(2),
                            decoration: BoxDecoration(color: theme.mint, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                                ),
                                Text(
                                  '${p.version.isNotEmpty ? 'Godot ${p.version} · ' : ''}${formatDuration(_now - p.startedAtMs)}',
                                  style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          GhPressable(
                            onPressed: () => widget.onStop(p.id),
                            semanticLabel: '${td('stop')} ${p.name}',
                            borderRadius: radius,
                            builder: (context, states) => GhAnimatedBox(
                              width: theme.space(6),
                              height: theme.space(6),
                              alignment: Alignment.center,
                              borderRadius: radius,
                              color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
                              child: GhIcon(
                                GhIcons.x,
                                size: theme.space(3.5),
                                color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EngineRow extends StatefulWidget {
  const _EngineRow({required this.version, required this.onOpen});

  final InstalledGodotVersion version;
  final VoidCallback onOpen;

  @override
  State<_EngineRow> createState() => _EngineRowState();
}

class _EngineRowState extends State<_EngineRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final v = widget.version;
    final name = (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhReveal(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: GhDurations.interactive,
          padding: EdgeInsets.all(theme.space(2.5)),
          decoration: dashRowDecoration(theme, _hovered),
          child: Row(
            spacing: theme.space(3),
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, mono: true, color: theme.ink),
                    ),
                    Text(
                      v.executablePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              GhPressable(
                onPressed: widget.onOpen,
                semanticLabel: name,
                borderRadius: radius,
                builder: (context, states) => GhAnimatedBox(
                  padding: EdgeInsets.all(theme.space(1.5)),
                  borderRadius: radius,
                  color: states.active ? theme.surface : theme.surface.withValues(alpha: 0),
                  child: GhIcon(
                    GhIcons.terminal,
                    size: theme.space(3.5),
                    color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.6),
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
