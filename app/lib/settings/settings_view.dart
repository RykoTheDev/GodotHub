import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../logic/debug_mode.dart';
import '../logic/pending_save.dart';
import '../logic/settings_category_nav.dart';
import '../modals/bug_report_modal.dart';
import '../modals/check_for_updates_modal.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/app_version.dart';
import '../state/keyboard_shortcuts.dart';
import '../state/section_search.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'categories/accessibility_settings.dart';
import 'categories/advanced_settings.dart';
import 'categories/appearance_settings.dart';
import 'categories/behavior_settings.dart';
import 'categories/credits_settings.dart';
import 'categories/data_settings.dart';
import 'categories/debug_settings.dart';
import 'categories/display_settings.dart';
import 'categories/experimental_settings.dart';
import 'categories/integrations_settings.dart';
import 'categories/motion_settings.dart';
import 'categories/storage_settings.dart';

String _ts(String key, {Map<String, Object?> args = const {}}) => ghTr('settings:$key', args: args);

const settingsCategories = <(String, FaIconData)>[
  ('appearance', GhIcons.palette),
  ('motion', GhIcons.play),
  ('display', GhIcons.monitor),
  ('accessibility', GhIcons.universalAccess),
  ('behavior', GhIcons.gear),
  ('storage', GhIcons.hardDrive),
  ('integrations', GhIcons.plug),
  ('data', GhIcons.history),
  ('advanced', GhIcons.code),
  ('experimental', GhIcons.flask),
];

const _debugCategory = ('debug', GhIcons.bug);

List<(String, FaIconData)> settingsRail({required bool debug}) => debug ? [...settingsCategories, _debugCategory] : settingsCategories;

String settingsCategoryLabel(String id) => id == 'debug' ? 'Debug' : _ts(id);

Widget settingsCategoryContent(String id, {VoidCallback? onCheckUpdates, VoidCallback? onReportBug}) => switch (id) {
  'appearance' => const AppearanceSettings(),
  'motion' => const MotionSettings(),
  'display' => const DisplaySettings(),
  'accessibility' => const AccessibilitySettings(),
  'behavior' => const BehaviorSettings(),
  'storage' => const StorageSettings(),
  'integrations' => const IntegrationsSettings(),
  'data' => const DataSettings(),
  'advanced' => AdvancedSettings(onCheckUpdates: onCheckUpdates, onReportBug: onReportBug),
  'experimental' => const ExperimentalSettings(),
  'debug' => const DebugSettings(),
  'credits' => const CreditsSettings(),
  _ => const SizedBox.shrink(),
};

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key, this.connected = false, this.prefs});

  final bool connected;
  final UiPrefsStore? prefs;

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  String _cat = 'appearance';
  final Map<String, FocusNode> _railNodes = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final SectionSearchNotifier _search = ref.read(sectionSearchProvider.notifier);

  FocusNode _railNode(String id) => _railNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'settings-rail:$id'));

  @override
  void initState() {
    super.initState();
    final pending = consumePendingSettingsCategory();
    if (pending != null && settingsCategories.any((c) => c.$1 == pending)) _cat = pending;
    _subscriptions
      ..add(AppSignals.on(focusSearchSignal).listen((_) => _search.focusNode.requestFocus()))
      ..add(
        AppSignals.on(openSettingsCategorySignal).listen((signal) {
          final detail = signal.detail;
          if (detail is! String) return;
          consumePendingSettingsCategory();
          _changeCategory(detail);
        }),
      );
    debugUnlocked.addListener(_onDebugChanged);
  }

  @override
  void dispose() {
    debugUnlocked.removeListener(_onDebugChanged);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final node in _railNodes.values) {
      node.dispose();
    }
    flushPendingSave().catchError((Object _) {});
    super.dispose();
  }

  void _onDebugChanged() {
    if (!mounted) return;
    setState(() {
      if (!debugUnlocked.value && _cat == 'debug') _cat = 'appearance';
    });
  }

  void _changeCategory(String next) {
    if (!mounted) return;
    _search.reset();
    setState(() => _cat = next);
  }

  void _openUpdates() {
    showGhModal<void>(
      context,
      (modal) => CheckForUpdatesModal(
        onClose: () => Navigator.of(modal).pop(),
        onOpenTokenSettings: () {
          _changeCategory('integrations');
          _search.setQuery('');
        },
      ),
    ).ignore();
  }

  void _openBugReport() {
    showGhModal<void>(context, (modal) => BugReportModal(onClose: () => Navigator.of(modal).pop())).ignore();
  }

  KeyEventResult _onRailKey(FocusNode node, KeyEvent event, List<(String, FaIconData)> categories) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!down && !up) return KeyEventResult.ignored;
    final index = categories.indexWhere((c) => c.$1 == _cat);
    final length = categories.length;
    final next = categories[down ? (index + 1) % length : (index - 1 + length) % length].$1;
    _changeCategory(next);
    _railNode(next).requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final search = ref.watch(sectionSearchProvider);
    final appVersion = ref.watch(appVersionProvider).value;
    final debug = debugUnlocked.value;
    final categories = settingsRail(debug: debug);
    final cat = !debug && _cat == 'debug' ? 'appearance' : _cat;
    FaIconData? activeIcon;
    for (final c in categories) {
      if (c.$1 == cat) activeIcon = c.$2;
    }
    final insets = GhViewInsets.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end),
          child: GhViewHeader(
            connected: widget.connected,
            title: ghTr('nav:settings'),
            child: GhSearchBar(
              value: search.query,
              focusNode: _search.focusNode,
              placeholder: _ts('search_placeholder'),
              onChanged: _search.setQuery,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end, bottom: insets.bottom, top: theme.space(2)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(4),
              children: [
                SizedBox(
                  width: theme.space(52),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: widget.connected ? theme.space(3) : 0),
                    child: Semantics(
                      container: true,
                      label: _ts('settings_title'),
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onKeyEvent: (node, event) => _onRailKey(node, event, categories),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: theme.space(1),
                          children: [
                            for (final (id, icon) in categories)
                              _RailButton(
                                key: ValueKey('settings-rail:$id'),
                                focusNode: _railNode(id),
                                icon: icon,
                                label: settingsCategoryLabel(id),
                                active: cat == id,
                                danger: id == 'experimental',
                                onPressed: () {
                                  _changeCategory(id);
                                  _railNode(id).requestFocus();
                                },
                              ),
                            if (appVersion != null && appVersion.isNotEmpty) ...[
                              const Spacer(),
                              Padding(
                                padding: EdgeInsetsDirectional.only(
                                  top: theme.space(6),
                                  start: theme.space(1),
                                  bottom: widget.connected ? theme.space(3) : 0,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _VersionButton(
                                    label: _ts('app_version_label', args: {'version': appVersion}),
                                    onPressed: () => _changeCategory('credits'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: widget.connected
                        ? BorderRadiusDirectional.only(topStart: Radius.circular(theme.radiusTag))
                        : BorderRadius.circular(theme.radiusCard),
                    child: ColoredBox(
                      color: theme.raised,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CategoryHeader(
                            icon: activeIcon,
                            label: settingsCategoryLabel(cat),
                            iconOpacity: settings.projectIconOpacity / 100,
                          ),
                          Expanded(
                            child: GhOverlayScrollArea(
                              hideThumb: !settings.showScrollbars,
                              hideTopButton: true,
                              scrollToTopOn: cat,
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(theme.space(5), theme.space(3), theme.space(5), theme.space(4)),
                                child: search.noResults
                                    ? _NoResults(onClear: _search.clear)
                                    : KeyedSubtree(
                                        key: ValueKey('settings-content:$cat'),
                                        child: settingsCategoryContent(cat, onCheckUpdates: _openUpdates, onReportBug: _openBugReport),
                                      ),
                              ),
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
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    super.key,
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.active,
    required this.danger,
    required this.onPressed,
  });

  final FocusNode focusNode;
  final FaIconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      focusNode: focusNode,
      onPressed: onPressed,
      selected: active,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) {
        final hover = states.highlighted && !active;
        final Color background;
        final Color? border;
        if (active) {
          background = danger ? theme.danger.withValues(alpha: 0.1) : theme.overlay;
          border = danger ? theme.danger.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5);
        } else if (hover) {
          background = danger ? theme.danger.withValues(alpha: 0.1) : theme.raised.withValues(alpha: 0.6);
          border = null;
        } else {
          background = theme.raised.withValues(alpha: 0);
          border = null;
        }
        final Color textColor = active ? (danger ? theme.danger : theme.ink) : (hover ? (danger ? theme.danger : theme.ink) : theme.muted);
        final Color iconColor = active ? (danger ? theme.danger : theme.accent) : theme.muted;
        return GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(3) - 1, vertical: theme.space(2.5) - 1),
          color: background,
          borderRadius: radius,
          border: Border.all(color: border ?? background.withValues(alpha: 0)),
          boxShadow: active ? GhShadows.md(Colors.black.withValues(alpha: 0.1)) : const [],
          child: Row(
            spacing: theme.space(2.5),
            children: [
              GhIcon(icon, size: theme.space(4), color: iconColor),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: textColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VersionButton extends StatelessWidget {
  const _VersionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(9999);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
        color: states.highlighted ? theme.raised : theme.raised.withValues(alpha: 0.6),
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        child: Text(
          label,
          style: theme.text(
            size: GhTextSize.x3s,
            mono: true,
            color: theme.muted.withValues(alpha: states.highlighted ? 1 : 0.6),
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.icon, required this.label, required this.iconOpacity});

  final FaIconData? icon;
  final String label;
  final double iconOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final glyph = icon;
    return Container(
      padding: EdgeInsets.fromLTRB(theme.space(5), theme.space(4), theme.space(5), theme.space(3)),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.6))),
      ),
      child: Row(
        spacing: theme.space(1.5),
        children: [
          if (glyph != null)
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: theme.space(12),
                child: ClipRect(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
                      end: rtl ? Alignment.centerLeft : Alignment.centerRight,
                      colors: const [Colors.black, Colors.black, Colors.transparent],
                      stops: const [0, 0.35, 0.9],
                    ).createShader(bounds),
                    child: Opacity(
                      opacity: math.max(0, math.min(1, iconOpacity)),
                      child: GhIcon(glyph, size: 48, color: theme.accentBright),
                    ),
                  ),
                ),
              ),
            ),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.x3l, weight: FontWeight.w900, color: theme.ink.withValues(alpha: 0.4), lineHeight: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space(16)),
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
              borderRadius: BorderRadius.circular(theme.radiusTile),
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
            ),
            child: GhIcon(GhIcons.search, size: theme.space(5), color: theme.muted.withValues(alpha: 0.5)),
          ),
          Text(
            _ts('no_settings_match'),
            textAlign: TextAlign.center,
            style: theme.text(size: GhTextSize.sm, color: theme.muted),
          ),
          GhPressable(
            onPressed: onClear,
            builder: (context, states) => Text(
              _ts('clear'),
              style: theme.text(
                size: GhTextSize.xs,
                weight: GhWeight.medium,
                color: states.highlighted ? theme.accentBright : theme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
