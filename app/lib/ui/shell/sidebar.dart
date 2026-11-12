import 'dart:math' as math;
import 'dart:ui' show FontFeature, PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../../design/design.dart';
import '../../logic/debug_mode.dart' show registerSettingsClick;
import '../controls/negative_margin.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart';
import '../overlays/dropdown.dart';
import '../overlays/menu.dart';
import 'account_menu.dart';
import 'disclosure.dart';
import 'overlay_scroll_area.dart';
import 'resize_knob.dart';
import '../core/i18n.dart';
import '../../motion/motion.dart';
import '../../motion/presence.dart';
import '../../motion/shared.dart';

export '../../logic/debug_mode.dart' show GhSettingsClickCounter;

Widget _sidebarLabel(Widget child) => GhCascadeItem(role: GhCascadeRole.label, child: child);

@immutable
class GhSidebarGroup {
  const GhSidebarGroup({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final FaIconData icon;
}

@immutable
class GhSidebarTab {
  const GhSidebarTab({
    required this.id,
    required this.label,
    required this.icon,
    this.isNew = false,
    this.group,
    this.shortcut,
    this.badge,
  });

  final String id;
  final String label;
  final FaIconData icon;
  final bool isNew;
  final GhSidebarGroup? group;
  final int? shortcut;
  final int? badge;
}

typedef GhAccountMenuBuilder = Widget Function(BuildContext context, GhDropdownTriggerBuilder trigger);

String ghSidebarBadgeLabel(int count) => count > 9 ? '9+' : '$count';

String ghModLabel(String key, {bool? isMac}) {
  final mac = isMac ?? defaultTargetPlatform == TargetPlatform.macOS;
  return mac ? '⌘$key' : 'Ctrl+$key';
}

class GhSidebar extends StatefulWidget {
  const GhSidebar({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabChange,
    this.connected = false,
    this.paletteKey = 'p',
    this.onOpenCommandPalette,
    this.onOpenUpdatesModal,
    this.updateAvailable = false,
    this.workspacesEnabled = false,
    this.fixedResizeKnob = false,
    this.initialWidth = defaultWidth,
    this.onWidthChanged,
    this.initialCollapsed = false,
    this.onCollapsedChanged,
    this.initialSeenNewTabs = const [],
    this.onSeenNewTabsChanged,
    this.initialClosedGroups = const [],
    this.onClosedGroupsChanged,
    this.workspaceTipSeen = false,
    this.onWorkspaceTipDismissed,
    this.onSettingsClick,
    this.accountMenuBuilder,
    this.isMac,
    this.youLabel,
    this.settingsLabel,
    this.searchLabel,
    this.expandLabel,
    this.collapseLabel,
    this.newBadgeLabel,
    this.updateAvailableLabel,
    this.workspaceTipTitle,
    this.workspaceTipBody,
    this.workspaceTipDismiss,
  });

  final List<GhSidebarTab> tabs;
  final String activeTab;
  final ValueChanged<String> onTabChange;
  final bool connected;
  final String paletteKey;
  final VoidCallback? onOpenCommandPalette;
  final VoidCallback? onOpenUpdatesModal;
  final bool updateAvailable;
  final bool workspacesEnabled;
  final bool fixedResizeKnob;
  final double initialWidth;
  final ValueChanged<double>? onWidthChanged;
  final bool initialCollapsed;
  final ValueChanged<bool>? onCollapsedChanged;
  final List<String> initialSeenNewTabs;
  final ValueChanged<List<String>>? onSeenNewTabsChanged;
  final List<String> initialClosedGroups;
  final ValueChanged<List<String>>? onClosedGroupsChanged;
  final bool workspaceTipSeen;
  final VoidCallback? onWorkspaceTipDismissed;
  final VoidCallback? onSettingsClick;
  final GhAccountMenuBuilder? accountMenuBuilder;
  final bool? isMac;
  final String? youLabel;
  final String? settingsLabel;
  final String? searchLabel;
  final String? expandLabel;
  final String? collapseLabel;
  final String? newBadgeLabel;
  final String? updateAvailableLabel;
  final String? workspaceTipTitle;
  final String? workspaceTipBody;
  final String? workspaceTipDismiss;

  static const double collapsedWidth = 68;
  static const double defaultWidth = 256;
  static const double minWidth = 195;
  static const double maxWidth = 350;
  static const Duration widthDuration = Duration(milliseconds: 500);

  static double clampWidth(double width) => width.clamp(minWidth, maxWidth).toDouble();

  @override
  State<GhSidebar> createState() => _GhSidebarState();
}

class _TabGroup {
  _TabGroup(this.id, this.group, this.tabs);

  final String id;
  final GhSidebarGroup? group;
  final List<GhSidebarTab> tabs;
}

enum GhSidebarTabLayout { full, square, narrow }

class _GhSidebarState extends State<GhSidebar> {
  late double _width = GhSidebar.clampWidth(widget.initialWidth);
  late bool _collapsed = widget.initialCollapsed;
  late List<String> _seenNew = List.of(widget.initialSeenNewTabs);
  late bool _tipSeen = widget.workspaceTipSeen;
  late List<String> _closedGroups = List.of(widget.initialClosedGroups);
  bool _dragging = false;
  bool _revealed = false;
  bool _edgeHovered = false;
  double? _knobY;
  Duration? _lastDown;
  double _startX = 0;
  double _startWidth = 0;
  final Object _sharedTag = Object();
  int _expandCount = 0;

  @override
  void dispose() {
    GhSharedElements.forget(_sharedTag);
    super.dispose();
  }

  @override
  void didUpdateWidget(GhSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceTipSeen != widget.workspaceTipSeen && widget.workspaceTipSeen) {
      _tipSeen = true;
    }
    if (oldWidget.activeTab != widget.activeTab) {
      final groupId = _activeGroupId();
      if (groupId != null && _closedGroups.contains(groupId)) {
        final next = _closedGroups.where((g) => g != groupId).toList();
        _closedGroups = next;
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClosedGroupsChanged?.call(List.unmodifiable(next)));
      }
    }
  }

  String? _activeGroupId() {
    for (final tab in widget.tabs) {
      if (tab.id == widget.activeTab) {
        return tab.group?.id;
      }
    }
    return null;
  }

  bool get _isMac => widget.isMac ?? defaultTargetPlatform == TargetPlatform.macOS;

  void _saveClosedGroups(List<String> next) {
    setState(() => _closedGroups = next);
    widget.onClosedGroupsChanged?.call(List.unmodifiable(next));
  }

  void _toggleGroup(String id) =>
      _saveClosedGroups(_closedGroups.contains(id) ? _closedGroups.where((g) => g != id).toList() : [..._closedGroups, id]);

  void _markTabSeen(String id) {
    if (_seenNew.contains(id)) {
      return;
    }
    final next = [..._seenNew, id];
    setState(() => _seenNew = next);
    widget.onSeenNewTabsChanged?.call(List.unmodifiable(next));
  }

  void _dismissTip() {
    setState(() => _tipSeen = true);
    widget.onWorkspaceTipDismissed?.call();
  }

  void _toggleCollapsed() {
    setState(() {
      _knobY = null;
      if (_collapsed) {
        _expandCount += 1;
      }
      _collapsed = !_collapsed;
    });
    widget.onCollapsedChanged?.call(_collapsed);
  }

  void _pressTab(GhSidebarTab tab) {
    if (tab.id == 'settings') {
      registerSettingsClick();
      widget.onSettingsClick?.call();
    }
    if (tab.isNew) {
      _markTabSeen(tab.id);
    }
    widget.onTabChange(tab.id);
  }

  List<_TabGroup> _groups() {
    final groups = <_TabGroup>[];
    for (final tab in widget.tabs) {
      final id = tab.group?.id ?? tab.id;
      final last = groups.isEmpty ? null : groups.last;
      if (last != null && tab.group != null && last.id == id) {
        last.tabs.add(tab);
      } else {
        groups.add(_TabGroup(id, tab.group, [tab]));
      }
    }
    return groups;
  }

  void _onStripDown(PointerDownEvent event) {
    final now = event.timeStamp;
    final last = _lastDown;
    _lastDown = now;
    if (last != null && now - last < GhResizeKnob.doubleClickWindow) {
      setState(() {
        _width = GhSidebar.defaultWidth;
        _knobY = null;
      });
      widget.onWidthChanged?.call(_width);
      return;
    }
    _startX = event.position.dx;
    _startWidth = _width;
    setState(() => _dragging = true);
  }

  void _finishDrag() {
    setState(() => _dragging = false);
    widget.onWidthChanged?.call(_width);
  }

  void _onStripMove(PointerMoveEvent event, bool rtl) {
    if (!_dragging) {
      return;
    }
    if (event.buttons == 0) {
      _finishDrag();
      return;
    }
    final delta = event.position.dx - _startX;
    final next = _startWidth + (rtl ? -delta : delta);
    setState(() => _width = GhSidebar.clampWidth(next.roundToDouble()));
  }

  void _onStripEnd() {
    if (_dragging) {
      _finishDrag();
    }
  }

  void _onWrapperHover(PointerHoverEvent event, double panelWidth, double overhang, double height, bool rtl) {
    if (_dragging || _collapsed || widget.fixedResizeKnob) {
      return;
    }
    final x = event.localPosition.dx;
    final dist = rtl ? x - overhang : panelWidth - x;
    if (dist > GhResizeKnob.resetDistance) {
      if (_knobY != null) {
        setState(() => _knobY = null);
      }
      return;
    }
    if (dist <= GhResizeKnob.trackDistance) {
      setState(() => _knobY = GhResizeKnob.offsetFor(event.localPosition.dy, height));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final overhang = theme.space(4);
    final target = _collapsed ? GhSidebar.collapsedWidth : _width;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: _dragging ? Duration.zero : motion.css(GhSidebar.widthDuration),
      curve: GhCurves.outExpo,
      builder: (context, width, _) => GhNegativeMargin(
        margin: rtl ? EdgeInsets.only(left: overhang) : EdgeInsets.only(right: overhang),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return SizedBox(
              width: width + overhang,
              height: height,
              child: MouseRegion(
                opaque: false,
                hitTestBehavior: HitTestBehavior.deferToChild,
                onEnter: (_) => setState(() => _revealed = true),
                onHover: (event) => _onWrapperHover(event, width, overhang, height, rtl),
                onExit: (_) => setState(() {
                  _revealed = false;
                  _knobY = null;
                }),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(start: 0, top: 0, bottom: 0, width: width, child: _panel(context, theme, width)),
                    if (_collapsed)
                      PositionedDirectional(
                        top: theme.space(2),
                        end: overhang - theme.space(4),
                        width: theme.space(8),
                        height: theme.space(8),
                        child: GhTooltip(
                          message: widget.expandLabel ?? context.tr.common.expand_sidebar,
                          side: GhSide.right,
                          child: _CollapseButton(
                            collapsed: true,
                            revealed: _revealed,
                            label: widget.expandLabel ?? context.tr.common.expand_sidebar,
                            onPressed: _toggleCollapsed,
                          ),
                        ),
                      ),
                    if (!_collapsed)
                      PositionedDirectional(
                        top: 0,
                        bottom: 0,
                        end: overhang - theme.space(3.5),
                        width: theme.space(7),
                        child: _strip(context, theme, rtl),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _strip(BuildContext context, GhTheme theme, bool rtl) {
    return Semantics(
      container: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => setState(() {
          _revealed = true;
          _edgeHovered = true;
        }),
        onExit: (_) => setState(() => _edgeHovered = false),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onStripDown,
          onPointerMove: (event) => _onStripMove(event, rtl),
          onPointerUp: (_) => _onStripEnd(),
          onPointerCancel: (_) => _onStripEnd(),
          child: GhResizeKnob(
            visible: _revealed || _dragging,
            dragging: _dragging,
            hovered: _edgeHovered,
            offsetY: _knobY != null && !widget.fixedResizeKnob ? _knobY! : 0.0,
            width: _width,
          ),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, GhTheme theme, double width) {
    final layoutWidth = math.max(width, _collapsed ? GhSidebar.collapsedWidth : _width);
    final radius = widget.connected ? BorderRadius.zero : BorderRadius.circular(theme.radiusCard);
    final decoration = BoxDecoration(
      color: theme.raised,
      borderRadius: widget.connected ? null : radius,
      border: widget.connected ? BorderDirectional(end: BorderSide(color: theme.line)) : null,
    );
    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: widget.connected ? const EdgeInsetsDirectional.only(end: 1) : EdgeInsets.zero,
          child: OverflowBox(
            alignment: AlignmentDirectional.topStart,
            minWidth: layoutWidth - (widget.connected ? 1 : 0),
            maxWidth: layoutWidth - (widget.connected ? 1 : 0),
            child: GhCascadeHost(cascade: GhPresenceSpecs.sidebarLabels, replay: _expandCount, child: _content(context, theme)),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, GhTheme theme) {
    final collapsed = _collapsed;
    final palette = widget.onOpenCommandPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!collapsed)
          SizedBox(
            height: theme.space(14),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (palette != null) ...[
                    Expanded(
                      child: _SearchButton(
                        label: widget.searchLabel ?? context.tr.common.search,
                        shortcut: ghModLabel(widget.paletteKey.toUpperCase(), isMac: _isMac),
                        onPressed: palette,
                      ),
                    ),
                    SizedBox(width: theme.space(2)),
                  ],
                  GhTooltip(
                    message: widget.collapseLabel ?? context.tr.common.collapse_sidebar,
                    side: GhSide.right,
                    child: _CollapseButton(
                      collapsed: false,
                      revealed: true,
                      label: widget.collapseLabel ?? context.tr.common.collapse_sidebar,
                      onPressed: _toggleCollapsed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (palette != null && collapsed)
          Padding(
            padding: EdgeInsets.only(top: theme.space(3)),
            child: Center(
              child: GhTooltip(
                message: widget.searchLabel ?? context.tr.common.search,
                side: GhSide.right,
                child: _SquareIconButton(
                  icon: GhIcons.search,
                  semanticLabel: widget.searchLabel ?? context.tr.common.search,
                  onPressed: palette,
                ),
              ),
            ),
          ),
        Expanded(
          child: GhOverlayScrollArea(
            hideTopButton: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(theme.space(3), theme.space(2), theme.space(3), theme.space(3)),
              child: _nav(context, theme),
            ),
          ),
        ),
        Padding(padding: EdgeInsets.all(theme.space(3)), child: _footer(context, theme)),
      ],
    );
  }

  List<Widget> _gapped(List<Widget> children, double gap, {bool horizontal = false}) {
    final out = <Widget>[];
    for (final child in children) {
      if (out.isNotEmpty) {
        out.add(horizontal ? SizedBox(width: gap) : SizedBox(height: gap));
      }
      out.add(child);
    }
    return out;
  }

  Widget _nav(BuildContext context, GhTheme theme) {
    final collapsed = _collapsed;
    final entries = <Widget>[];
    for (final group in _groups()) {
      final buttons = [
        for (final tab in group.tabs)
          _tabButton(tab, collapsed ? GhSidebarTabLayout.square : GhSidebarTabLayout.full, collapsedView: collapsed),
      ];
      if (collapsed || group.group == null) {
        entries.addAll(buttons);
        continue;
      }
      entries.add(_groupBlock(context, theme, group, buttons));
    }
    return Column(
      crossAxisAlignment: collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      children: _gapped(entries, theme.space(collapsed ? 1 : 1.5)),
    );
  }

  Widget _groupBlock(BuildContext context, GhTheme theme, _TabGroup group, List<Widget> buttons) {
    GhSidebarTab? activeInGroup;
    var groupBadge = 0;
    for (final tab in group.tabs) {
      if (tab.id == widget.activeTab) {
        activeInGroup = tab;
      }
      groupBadge += tab.badge ?? 0;
    }
    final open = !_closedGroups.contains(group.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GhSidebarGroupHeader(
          group: group.group!,
          open: open,
          activeLabel: activeInGroup?.label,
          badge: groupBadge,
          onPressed: () => _toggleGroup(group.id),
        ),
        GhDisclosure(
          open: open,
          child: Container(
            margin: EdgeInsetsDirectional.only(start: theme.space(5)),
            padding: EdgeInsetsDirectional.only(start: theme.space(2), top: theme.space(1), bottom: theme.space(1)),
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: theme.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: _gapped([for (final button in buttons) GhDisclosureItem(child: button)], theme.space(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabButton(
    GhSidebarTab tab,
    GhSidebarTabLayout layout, {
    required bool collapsedView,
    bool chrome = false,
    bool? menuOpen,
    VoidCallback? onMenuToggle,
  }) {
    final shortcut = tab.shortcut != null ? ghModLabel('${tab.shortcut}', isMac: _isMac) : null;
    final button = GhSidebarTabButton(
      tab: tab,
      layout: layout,
      active: widget.activeTab == tab.id,
      showNew: tab.isNew && !_seenNew.contains(tab.id),
      hideLabel: collapsedView,
      chrome: chrome,
      shortcut: shortcut,
      newBadgeLabel: widget.newBadgeLabel ?? context.tr.common.new_badge,
      menuOpen: menuOpen,
      onPressed: onMenuToggle ?? () => _pressTab(tab),
      sharedTag: _sharedTag,
    );
    if (!collapsedView) {
      return button;
    }
    final tooltip = GhTooltip(
      side: GhSide.right,
      message: tab.label,
      content: shortcut == null ? null : _TooltipWithShortcut(label: tab.label, shortcut: shortcut),
      child: button,
    );
    return layout == GhSidebarTabLayout.square ? _unclamped(tooltip) : tooltip;
  }

  Widget _unclamped(Widget child) => OverflowBox(fit: OverflowBoxFit.deferToChild, maxWidth: double.infinity, child: child);

  Widget _footer(BuildContext context, GhTheme theme) {
    final collapsed = _collapsed;
    final children = <Widget>[];
    final updates = widget.onOpenUpdatesModal;
    if (widget.updateAvailable && updates != null) {
      children.add(
        collapsed
            ? _unclamped(
                GhTooltip(
                  message: widget.updateAvailableLabel ?? context.tr.common.update_available,
                  child: _SquareIconButton(
                    icon: GhIcons.arrowUp,
                    semanticLabel: widget.updateAvailableLabel ?? context.tr.common.update_available,
                    onPressed: updates,
                    dot: true,
                  ),
                ),
              )
            : _UpdateButton(label: widget.updateAvailableLabel ?? context.tr.common.update_available, onPressed: updates),
      );
    }
    if (widget.workspacesEnabled && !collapsed && !_tipSeen) {
      children.add(
        _WorkspaceTip(
          title: widget.workspaceTipTitle ?? context.tr.nav.workspace_tip_title,
          body: widget.workspaceTipBody ?? context.tr.nav.workspace_tip_body,
          dismissLabel: widget.workspaceTipDismiss ?? context.tr.nav.workspace_tip_dismiss,
          onDismiss: _dismissTip,
        ),
      );
    }
    final accountTab = GhSidebarTab(id: 'account', label: widget.youLabel ?? context.tr.nav.you, icon: GhIcons.user);
    final settingsTab = GhSidebarTab(id: 'settings', label: widget.settingsLabel ?? context.tr.nav.settings, icon: GhIcons.gear);
    Widget trigger(BuildContext context, bool open, VoidCallback toggle) => _tabButton(
      accountTab,
      collapsed ? GhSidebarTabLayout.square : GhSidebarTabLayout.full,
      collapsedView: collapsed,
      chrome: true,
      menuOpen: open,
      onMenuToggle: toggle,
    );
    final account =
        widget.accountMenuBuilder?.call(context, trigger) ??
        GhAccountMenu(
          trigger: trigger,
          onNavigate: widget.onTabChange,
          youLabel: widget.youLabel ?? context.tr.nav.you,
          newBadgeLabel: widget.newBadgeLabel ?? context.tr.common.new_badge,
        );
    final settings = _tabButton(
      settingsTab,
      collapsed ? GhSidebarTabLayout.square : GhSidebarTabLayout.narrow,
      collapsedView: true,
      chrome: true,
    );
    children.add(
      collapsed
          ? Column(mainAxisSize: MainAxisSize.min, children: _gapped([account, settings], theme.space(1)))
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: account),
                  SizedBox(width: theme.space(1.5)),
                  settings,
                ],
              ),
            ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      children: _gapped(children, theme.space(collapsed ? 1 : 1.5)),
    );
  }
}

class _TooltipWithShortcut extends StatelessWidget {
  const _TooltipWithShortcut({required this.label, required this.shortcut});

  final String label;
  final String shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        SizedBox(width: theme.space(2)),
        Text(
          shortcut,
          style: theme.text(size: GhTextSize.x4s, mono: true, color: theme.muted),
        ),
      ],
    );
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: theme.text(size: GhTextSize.x4s, mono: true, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.25 / 0.875),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.small = false});

  final int count;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.space(small ? 4 : 5);
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: EdgeInsets.symmetric(horizontal: theme.space(small ? 1 : 1.5)),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(9999)),
      child: Text(
        ghSidebarBadgeLabel(count),
        maxLines: 1,
        softWrap: false,
        style: theme
            .text(size: small ? GhTextSize.x4s : GhTextSize.x3s, weight: GhWeight.semibold, color: Colors.white, lineHeight: 1)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(theme.radiusTag)),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: Colors.white, lineHeight: 1),
      ),
    );
  }
}

class GhSidebarTabButton extends StatelessWidget {
  const GhSidebarTabButton({
    super.key,
    required this.tab,
    required this.onPressed,
    this.layout = GhSidebarTabLayout.full,
    this.active = false,
    this.showNew = false,
    this.hideLabel = false,
    this.chrome = false,
    this.shortcut,
    this.newBadgeLabel,
    this.menuOpen,
    this.sharedTag,
  });

  final GhSidebarTab tab;
  final GhSidebarTabLayout layout;
  final bool active;
  final bool showNew;
  final bool hideLabel;
  final bool chrome;
  final String? shortcut;
  final String? newBadgeLabel;
  final bool? menuOpen;
  final Object? sharedTag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    final badge = tab.badge ?? 0;
    final semantic = hideLabel || badge > 0 ? (badge > 0 ? '${tab.label} ($badge)' : tab.label) : null;
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: semantic,
      expanded: menuOpen,
      builder: (context, states) => _build(context, theme, states, radius, badge),
    );
  }

  Widget _sharedPill(Widget pill) {
    final tag = sharedTag;
    return tag == null ? pill : GhShared(tag: tag, child: pill);
  }

  Widget _build(BuildContext context, GhTheme theme, GhStates states, BorderRadius radius, int badge) {
    final motion = GhMotion.of(context);
    final hover = states.active;
    final foreground = active || hover ? theme.ink : theme.muted;
    final Color background;
    final Color borderColor;
    if (chrome) {
      background = hover ? theme.overlay : theme.overlay.withValues(alpha: 0.8);
      borderColor = hover && !showNew ? theme.outline : theme.outline.withValues(alpha: 0);
    } else {
      background = !active && hover ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0);
      borderColor = theme.outline.withValues(alpha: 0);
    }
    final lift = hover && (chrome || !active);
    Widget icon = GhIconMotionScale(
      states: states,
      child: GhAnimatedIcon(tab.icon, color: active ? theme.accent : theme.muted, size: theme.space(4)),
    );
    final tag = sharedTag;
    if (tag != null) {
      icon = GhSharedIcon(tag: tag, enabled: active, child: icon);
    }
    final row = <Widget>[icon];
    final trailing = <Widget>[];
    if (!hideLabel) {
      if (showNew) {
        trailing.add(_sidebarLabel(_NewBadge(label: newBadgeLabel ?? context.tr.common.new_badge)));
      } else if (badge > 0) {
        trailing.add(_sidebarLabel(_CountBadge(count: badge)));
      } else if (shortcut != null) {
        trailing.add(
          AnimatedOpacity(
            opacity: states.hovered || states.focused ? 1 : 0,
            duration: motion.css(const Duration(milliseconds: 200)),
            curve: GhCurves.outExpo,
            child: _Kbd(label: shortcut!),
          ),
        );
      }
      row.add(SizedBox(width: theme.space(2)));
      row.add(
        Expanded(
          child: _sidebarLabel(
            GhAnimatedText(
              tab.label,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      );
      for (final t in trailing) {
        row.add(SizedBox(width: theme.space(2)));
        row.add(t);
      }
    }
    final square = layout != GhSidebarTabLayout.full;
    final content = square
        ? Center(child: icon)
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
            child: Row(children: row),
          );
    final overlays = <Widget>[
      if (active)
        Positioned.fill(
          child: IgnorePointer(
            child: _sharedPill(
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.overlay,
                  borderRadius: radius,
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  boxShadow: GhShadows.md(),
                ),
              ),
            ),
          ),
        ),
      content,
      if (hideLabel && badge > 0 && !showNew)
        PositionedDirectional(
          top: theme.space(0.5),
          end: theme.space(0.5),
          child: ExcludeSemantics(child: _CountBadge(count: badge, small: true)),
        ),
      if (hideLabel && showNew)
        PositionedDirectional(
          top: theme.space(1),
          end: theme.space(1),
          child: Container(
            width: theme.space(2),
            height: theme.space(2),
            decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
          ),
        ),
    ];
    Widget box = GhLiftBox(
      lift: lift,
      borderRadius: radius,
      color: background,
      border: Border.all(color: borderColor),
      width: layout == GhSidebarTabLayout.full ? double.infinity : theme.space(11),
      height: layout == GhSidebarTabLayout.square ? theme.space(11) : null,
      child: Stack(clipBehavior: Clip.none, fit: square ? StackFit.expand : StackFit.loose, children: overlays),
    );
    if (showNew) {
      box = CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: theme.accent.withValues(alpha: 0.7), borderRadius: radius),
        child: box,
      );
    }
    return DefaultTextStyle.merge(
      style: TextStyle(color: foreground),
      child: box,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  static const double dash = 3;
  static const double gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size).deflate(0.5);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.collapsed, required this.revealed, required this.label, required this.onPressed});

  final bool collapsed;
  final bool revealed;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final button = GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) {
        final hover = states.active;
        final foreground = hover ? theme.ink : theme.muted;
        final icon = AnimatedRotation(
          turns: collapsed ? 0.5 : 0,
          duration: motion.css(GhDurations.iconTransform),
          curve: GhCurves.spring,
          child: GhIconMotionScale(
            states: states,
            child: Transform.flip(
              flipX: rtl,
              child: GhAnimatedIcon(GhIcons.chevronsLeft, color: foreground, size: theme.space(4)),
            ),
          ),
        );
        if (collapsed) {
          return GhAnimatedBox(
            width: theme.space(8),
            height: theme.space(8),
            alignment: Alignment.center,
            color: hover ? theme.raised.withValues(alpha: 0.6) : theme.raised,
            borderRadius: radius,
            border: Border.all(color: theme.line),
            boxShadow: GhShadows.md(),
            child: icon,
          );
        }
        return GhLiftBox(
          lift: hover,
          width: theme.space(9),
          height: theme.space(9),
          alignment: Alignment.center,
          color: hover ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          border: Border.all(color: Colors.transparent),
          child: icon,
        );
      },
    );
    if (!collapsed) {
      return button;
    }
    return IgnorePointer(
      ignoring: !revealed,
      child: AnimatedOpacity(
        opacity: revealed ? 1 : 0,
        duration: motion.css(GhDurations.interactive),
        curve: GhCurves.outExpo,
        child: button,
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.label, required this.shortcut, required this.onPressed});

  final String label;
  final String shortcut;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) {
        final hover = states.active;
        final foreground = hover ? theme.ink : theme.muted;
        return GhLiftBox(
          lift: hover,
          height: theme.space(9),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
          color: hover ? theme.overlay : theme.overlay.withValues(alpha: 0.6),
          borderRadius: radius,
          border: Border.all(color: hover ? theme.outline : theme.outline.withValues(alpha: 0.5)),
          child: Row(
            children: [
              GhIconMotionScale(
                states: states,
                child: GhAnimatedIcon(GhIcons.search, color: foreground, size: theme.space(4)),
              ),
              SizedBox(width: theme.space(2)),
              Expanded(
                child: _sidebarLabel(
                  GhAnimatedText(
                    label,
                    style: theme.text(size: GhTextSize.sm, color: foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
              SizedBox(width: theme.space(2)),
              _sidebarLabel(_Kbd(label: shortcut)),
            ],
          ),
        );
      },
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.semanticLabel, required this.onPressed, this.dot = false});

  final FaIconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hover = states.active;
        return GhLiftBox(
          lift: hover,
          width: theme.space(11),
          height: theme.space(11),
          color: hover ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: GhIconMotionScale(
                  states: states,
                  child: GhAnimatedIcon(icon, color: hover ? theme.ink : theme.muted, size: theme.space(4)),
                ),
              ),
              if (dot)
                PositionedDirectional(
                  top: theme.space(2),
                  end: theme.space(2),
                  width: theme.space(2),
                  height: theme.space(2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.accentBright,
                      shape: BoxShape.circle,
                      boxShadow: [cssShadow(0, 0, 6, 2, theme.accent.withValues(alpha: 0.5))],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) {
        final hover = states.active;
        return GhLiftBox(
          lift: hover,
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
          color: theme.accent.withValues(alpha: hover ? 0.2 : 0.1),
          borderRadius: radius,
          border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
          child: Row(
            children: [
              _sidebarLabel(
                Container(
                  width: theme.space(2),
                  height: theme.space(2),
                  decoration: BoxDecoration(color: theme.accentBright, shape: BoxShape.circle),
                ),
              ),
              SizedBox(width: theme.space(2.5)),
              Expanded(
                child: _sidebarLabel(
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.accentBright),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkspaceTip extends StatelessWidget {
  const _WorkspaceTip({required this.title, required this.body, required this.dismissLabel, required this.onDismiss});

  final String title;
  final String body;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Container(
      padding: EdgeInsets.all(theme.space(3)),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: theme.space(0.5)),
            child: GhIcon(GhIcons.info, size: theme.space(4), color: theme.accentBright),
          ),
          SizedBox(width: theme.space(2.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
                ),
                SizedBox(height: theme.space(0.5)),
                Text(
                  body,
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
              ],
            ),
          ),
          SizedBox(width: theme.space(2.5)),
          GhNegativeMargin(
            margin: EdgeInsets.all(theme.space(1)),
            child: GhPressable(
              onPressed: onDismiss,
              borderRadius: radius,
              semanticLabel: dismissLabel,
              builder: (context, states) => Padding(
                padding: EdgeInsets.all(theme.space(1)),
                child: GhIconMotionScale(
                  states: states,
                  child: GhAnimatedIcon(
                    GhIcons.x,
                    color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.5),
                    size: theme.space(3.5),
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

class GhSidebarGroupHeader extends StatelessWidget {
  const GhSidebarGroupHeader({
    super.key,
    required this.group,
    required this.open,
    required this.onPressed,
    this.activeLabel,
    this.badge = 0,
  });

  final GhSidebarGroup group;
  final bool open;
  final String? activeLabel;
  final int badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    final hasActive = activeLabel != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      expanded: open,
      builder: (context, states) {
        final hover = states.active && !hasActive;
        final foreground = hasActive || hover ? theme.ink : theme.muted;
        final closedActive = !open && hasActive;
        final tail = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!open && badge > 0) ...[_CountBadge(count: badge), SizedBox(width: theme.space(2))],
            GhDisclosureChevron(open: open),
          ],
        );
        return GhLiftBox(
          lift: hover,
          width: double.infinity,
          padding: EdgeInsets.all(theme.space(2)),
          color: hasActive
              ? theme.overlay.withValues(alpha: 0.5)
              : hover
              ? theme.raised.withValues(alpha: 0.6)
              : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          border: Border.all(color: hasActive ? theme.outline.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0)),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    GhIconMotionScale(
                      states: states,
                      child: GhAnimatedIcon(group.icon, color: hasActive ? theme.ink : theme.muted, size: theme.space(4)),
                    ),
                    SizedBox(width: theme.space(2)),
                    Flexible(
                      child: _sidebarLabel(
                        GhAnimatedText(
                          group.label,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: foreground),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (closedActive) ...[
                      SizedBox(width: theme.space(2)),
                      GhIconMotionScale(
                        states: states,
                        child: Transform.rotate(
                          angle: rtl ? math.pi : 0,
                          child: GhIcon(GhIcons.chevronRight, size: theme.space(2), color: theme.muted),
                        ),
                      ),
                      SizedBox(width: theme.space(2)),
                      Flexible(
                        child: _sidebarLabel(
                          Text(
                            activeLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.xs, color: theme.muted),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: theme.space(2)),
              _sidebarLabel(tail),
            ],
          ),
        );
      },
    );
  }
}
