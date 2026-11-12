import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../../motion/presence.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart';
import 'menu.dart';
import 'popup_registry.dart';

const double _submenuFallbackHeight = 260;
const double _submenuFallbackWidth = 220;
const Duration ghSubmenuHoverDelay = Duration(milliseconds: 160);

typedef GhDropdownTriggerBuilder = Widget Function(BuildContext context, bool open, VoidCallback toggle);
typedef GhDropdownContentBuilder = Widget Function(BuildContext context, VoidCallback close);

@immutable
class GhDropdownHeaderItem {
  const GhDropdownHeaderItem({required this.id, required this.icon, required this.label, required this.onPressed, this.tooltip});

  final String id;
  final FaIconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback onPressed;
}

class GhDropdown extends StatefulWidget {
  const GhDropdown({
    super.key,
    required this.trigger,
    this.items = const [],
    this.header = const [],
    this.align = GhSide.right,
    this.side = GhSide.bottom,
    this.compact = false,
    this.activeStyle = GhMenuActiveStyle.accent,
    this.menuMinWidth,
    this.expand = false,
    this.content,
    this.onOpenChange,
  }) : assert(align == GhSide.left || align == GhSide.right),
       assert(side != GhSide.right);

  final GhDropdownTriggerBuilder trigger;
  final List<GhMenuItem> items;
  final List<GhDropdownHeaderItem> header;
  final GhSide align;
  final GhSide side;
  final bool compact;
  final GhMenuActiveStyle activeStyle;
  final double? menuMinWidth;
  final bool expand;
  final GhDropdownContentBuilder? content;
  final ValueChanged<bool>? onOpenChange;

  @override
  State<GhDropdown> createState() => _GhDropdownState();
}

class _GhDropdownState extends State<GhDropdown> with WidgetsBindingObserver {
  final _portal = OverlayPortalController();
  final _surfaceKey = GlobalKey();
  final _group = Object();
  final _contentNode = FocusNode(skipTraversal: true, canRequestFocus: false, debugLabel: 'GhDropdown content');
  final Map<String, FocusNode> _nodes = {};
  final Map<String, OverlayPortalController> _submenus = {};
  final List<ScrollPosition> _scrollPositions = [];
  GhPopupHandle? _handle;
  Timer? _submenuTimer;
  String? _openSubmenu;
  bool _open = false;
  bool _up = false;
  final Map<String, bool> _submenuOnLeft = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _submenuTimer?.cancel();
    _handle?.release();
    _detachScroll();
    _contentNode.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_open) {
      _closeAll();
    }
  }

  FocusNode _node(String key) => _nodes.putIfAbsent(key, () => GhMenuItemFocusNode(debugLabel: 'GhDropdown $key'));

  OverlayPortalController _submenuPortal(String id) => _submenus.putIfAbsent(id, OverlayPortalController.new);

  void _toggle() => _setOpen(!_open);

  void _setOpen(bool next) {
    if (next == _open) {
      return;
    }
    if (next) {
      setState(() => _open = true);
      _portal.show();
      _handle = GhPopupRegistry.open(
        close: _closeAll,
        surface: () => _surfaceKey.currentContext,
        origin: () => mounted ? context : null,
        onEscape: _closeAll,
      );
      _attachScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) {
          ghFirstFocusableMenuNode(_orderedNodes())?.requestFocus();
        }
      });
    } else {
      _hide();
    }
    widget.onOpenChange?.call(next);
  }

  void _hide() {
    _submenuTimer?.cancel();
    _handle?.release();
    _handle = null;
    _detachScroll();
    if (mounted) {
      setState(() {
        _open = false;
        _openSubmenu = null;
      });
    }
  }

  void _onMenuExited() {
    if (_open) {
      return;
    }
    if (_portal.isShowing) {
      _portal.hide();
    }
    for (final portal in _submenus.values) {
      if (portal.isShowing) {
        portal.hide();
      }
    }
  }

  void _onSubmenuExited(String id) {
    if (_open && _openSubmenu == id) {
      return;
    }
    final portal = _submenus[id];
    if (portal != null && portal.isShowing) {
      portal.hide();
    }
  }

  void _placed(bool up) {
    if (up == _up) {
      return;
    }
    _up = up;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _placedSubmenu(String id, bool onLeft) {
    if (_submenuOnLeft[id] == onLeft) {
      return;
    }
    _submenuOnLeft[id] = onLeft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Alignment _menuOrigin(BuildContext context) {
    if (widget.side == GhSide.left) {
      return Alignment.topRight;
    }
    final right = mirrorSide(widget.align, Directionality.of(context)) == GhSide.right;
    return Alignment(right ? 1 : -1, _up ? 1 : -1);
  }

  void _closeAll() {
    if (!_open) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _closeAll());
      return;
    }
    _hide();
    widget.onOpenChange?.call(false);
  }

  void _attachScroll() {
    var state = context.findAncestorStateOfType<ScrollableState>();
    while (state != null) {
      state.position.addListener(_closeAll);
      _scrollPositions.add(state.position);
      state = state.context.findAncestorStateOfType<ScrollableState>();
    }
  }

  void _detachScroll() {
    for (final position in _scrollPositions) {
      position.removeListener(_closeAll);
    }
    _scrollPositions.clear();
  }

  void _scheduleSubmenu(String? id) {
    _submenuTimer?.cancel();
    _submenuTimer = Timer(ghSubmenuHoverDelay, () => _setSubmenu(id));
  }

  void _setSubmenu(String? id) {
    if (!mounted || !_open || id == _openSubmenu) {
      return;
    }
    if (id != null) {
      _submenuPortal(id).show();
    }
    setState(() => _openSubmenu = id);
  }

  void _handleItemPressed(GhMenuItem item) {
    if (item.hasChildren) {
      _submenuTimer?.cancel();
      _setSubmenu(item.id);
      return;
    }
    _closeAll();
    item.onSelected?.call();
  }

  Iterable<FocusNode> _orderedNodes() sync* {
    yield* _contentNode.traversalDescendants.whereType<GhMenuItemFocusNode>();
    for (final item in widget.items) {
      yield _node(item.id);
      if (item.action != null) {
        yield _node('${item.id}\u0000action');
      }
      if (_openSubmenu == item.id) {
        for (final child in item.children) {
          yield _node('${item.id}\u0000${child.id}');
        }
      }
    }
  }

  KeyEventResult _onMenuKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _closeAll();
      return KeyEventResult.handled;
    }
    return ghMenuArrowNavigation(event, _orderedNodes());
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = widget.trigger(context, _open, _toggle);
    if (widget.expand) {
      trigger = SizedBox(
        width: double.infinity,
        child: Align(alignment: AlignmentDirectional.centerStart, heightFactor: 1, child: trigger),
      );
    }
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildOverlay,
      child: TapRegion(groupId: _group, child: trigger),
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final anchor = MatrixUtils.transformRect(info.childPaintTransform, Offset.zero & info.childSize);
    return CustomSingleChildLayout(
      delegate: _DropdownLayout(
        anchor: anchor,
        side: widget.side,
        align: mirrorSide(widget.align, Directionality.of(context)),
        onPlaced: _placed,
      ),
      child: GhPresence(
        visible: _open,
        kind: GhPresenceKind.popover,
        up: _up,
        origin: _menuOrigin(context),
        onExited: _onMenuExited,
        child: TapRegion(
          groupId: _group,
          onTapOutside: (_) => _closeAll(),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onMenuKey,
            child: MouseRegion(onExit: (_) => _scheduleSubmenu(null), child: _menu(context)),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final theme = GhTheme.of(context);
    final rows = <Widget>[
      if (widget.header.isNotEmpty) _header(theme),
      if (widget.content != null)
        Focus(
          focusNode: _contentNode,
          child: Builder(builder: (context) => widget.content!(context, _closeAll)),
        ),
      for (final item in widget.items) _itemRow(context, theme, item),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: GhMenuSurface(
        key: _surfaceKey,
        compact: widget.compact,
        minWidth: widget.menuMinWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
      ),
    );
  }

  Widget _header(GhTheme theme) {
    final buttons = <Widget>[];
    for (final h in widget.header) {
      if (buttons.isNotEmpty) {
        buttons.add(SizedBox(width: theme.space(1)));
      }
      buttons.add(
        GhTooltip(
          message: h.tooltip ?? h.label,
          side: GhSide.top,
          child: GhMenuIconButton(
            icon: h.icon,
            iconSize: theme.space(4),
            semanticLabel: h.label,
            onPressed: () {
              _closeAll();
              h.onPressed();
            },
          ),
        ),
      );
    }
    return Container(
      margin: EdgeInsets.only(bottom: theme.space(1)),
      padding: EdgeInsets.all(theme.space(widget.compact ? 0.5 : 1)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GhMenuColors.divider)),
      ),
      child: Row(children: buttons),
    );
  }

  Widget _itemRow(BuildContext context, GhTheme theme, GhMenuItem item) {
    final compact = widget.compact;
    final button = GhMenuButton(
      item: item,
      compact: compact,
      caret: item.hasChildren,
      activeStyle: widget.activeStyle,
      focusNode: _node(item.id),
      onSelect: () => _handleItemPressed(item),
    );
    final action = item.action;
    Widget row = button;
    if (action != null) {
      row = Row(
        children: [
          Expanded(child: button),
          SizedBox(width: theme.space(0.5)),
          GhCascadeItem(
            role: GhCascadeRole.menuItem,
            child: GhTooltip(
              message: action.label,
              side: GhSide.top,
              child: GhMenuIconButton(
                icon: action.icon,
                iconSize: theme.space(3.5),
                semanticLabel: action.label,
                focusNode: _node('${item.id}\u0000action'),
                onPressed: () {
                  _closeAll();
                  action.onPressed();
                },
              ),
            ),
          ),
        ],
      );
    }
    Widget wrapper = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        if (item.dividerAfter) GhMenuDivider(compact: compact),
      ],
    );
    if (item.hasChildren) {
      wrapper = OverlayPortal.overlayChildLayoutBuilder(
        controller: _submenuPortal(item.id),
        overlayLocation: OverlayChildLocation.rootOverlay,
        overlayChildBuilder: (context, info) => _submenu(context, item, info),
        child: wrapper,
      );
    }
    return MouseRegion(onEnter: (_) => _scheduleSubmenu(item.hasChildren ? item.id : null), child: wrapper);
  }

  Widget _submenu(BuildContext context, GhMenuItem item, OverlayChildLayoutInfo info) {
    final anchor = MatrixUtils.transformRect(info.childPaintTransform, Offset.zero & info.childSize);
    final children = <Widget>[];
    for (final child in item.children) {
      children.add(
        GhMenuButton(
          item: child,
          compact: true,
          activeStyle: widget.activeStyle,
          focusNode: _node('${item.id}\u0000${child.id}'),
          onSelect: () {
            _closeAll();
            child.onSelected?.call();
          },
        ),
      );
      if (child.dividerAfter) {
        children.add(const GhMenuDivider(compact: true));
      }
    }
    return CustomSingleChildLayout(
      delegate: _SubmenuLayout(
        anchor: anchor,
        inset: (widget.compact ? 8 : 10) + ghMenuGap,
        onPlaced: (onLeft) => _placedSubmenu(item.id, onLeft),
      ),
      child: GhPresence(
        visible: _open && _openSubmenu == item.id,
        kind: GhPresenceKind.popover,
        origin: _submenuOnLeft[item.id] == true ? Alignment.centerRight : Alignment.centerLeft,
        onExited: () => _onSubmenuExited(item.id),
        child: TapRegion(
          groupId: _group,
          child: MouseRegion(
            onEnter: (_) => _scheduleSubmenu(item.id),
            onExit: (_) => _scheduleSubmenu(null),
            child: GhMenuSurface(
              compact: true,
              maxHeight: info.overlaySize.height * 0.7,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

class GhMenuIconButton extends StatelessWidget {
  const GhMenuIconButton({super.key, required this.icon, required this.onPressed, this.iconSize, this.semanticLabel, this.focusNode});

  final FaIconData icon;
  final VoidCallback? onPressed;
  final double? iconSize;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hovered = states.hovered && !states.disabled;
        final foreground = hovered ? theme.ink : theme.muted;
        return GhLiftBox(
          width: theme.space(8),
          height: theme.space(8),
          alignment: Alignment.center,
          color: hovered ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          lift: hovered,
          child: GhIconMotionScale(
            states: states,
            child: GhAnimatedIcon(icon, color: foreground, size: iconSize ?? theme.space(4)),
          ),
        );
      },
    );
  }
}

class _DropdownLayout extends SingleChildLayoutDelegate {
  _DropdownLayout({required this.anchor, required this.side, required this.align, this.onPlaced});

  final Rect anchor;
  final GhSide side;
  final GhSide align;
  final ValueChanged<bool>? onPlaced;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    onPlaced?.call(ghDropdownOpensUp(anchor: anchor, menu: childSize, viewport: size, side: side));
    return ghDropdownPosition(anchor: anchor, menu: childSize, viewport: size, side: side, align: align);
  }

  @override
  bool shouldRelayout(_DropdownLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.side != side || oldDelegate.align != align;
}

bool ghDropdownOpensUp({required Rect anchor, required Size menu, required Size viewport, required GhSide side}) {
  if (side == GhSide.left) {
    return false;
  }
  final spaceBelow = viewport.height - anchor.bottom;
  final spaceAbove = anchor.top;
  return side == GhSide.top || (spaceBelow < menu.height && spaceAbove > spaceBelow);
}

Offset ghDropdownPosition({required Rect anchor, required Size menu, required Size viewport, required GhSide side, required GhSide align}) {
  const pad = ghMenuViewportPad;
  const gap = ghMenuGap;
  final mh = menu.height;
  final mw = menu.width;
  if (side == GhSide.left) {
    var left = anchor.left - mw - gap;
    if (left < pad) {
      left = anchor.right + gap;
    }
    var top = anchor.top;
    if (top + mh > viewport.height - pad) {
      top = viewport.height - mh - pad;
    }
    if (top < pad) {
      top = pad;
    }
    return Offset(left, top);
  }
  final spaceBelow = viewport.height - anchor.bottom;
  final spaceAbove = anchor.top;
  final up = side == GhSide.top || (spaceBelow < mh && spaceAbove > spaceBelow);
  final spaceLeft = anchor.right;
  final spaceRight = viewport.width - anchor.left;
  final leftSide = align == GhSide.right ? !(spaceLeft < mw && spaceRight > spaceLeft) : spaceRight < mw && spaceLeft > spaceRight;
  var left = leftSide ? anchor.right - mw : anchor.left;
  left = math.max(pad, math.min(left, viewport.width - mw - pad));
  var top = up ? anchor.top - mh - gap : anchor.bottom + gap;
  if (up) {
    if (top < pad) {
      top = pad;
    }
  } else if (top + mh > viewport.height - pad) {
    top = viewport.height - mh - pad;
  }
  return Offset(left, top);
}

class _SubmenuLayout extends SingleChildLayoutDelegate {
  _SubmenuLayout({required this.anchor, required this.inset, this.onPlaced});

  final Rect anchor;
  final double inset;
  final ValueChanged<bool>? onPlaced;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final spaceRight = size.width - anchor.right - inset;
    final spaceLeft = anchor.left - inset;
    final onLeft = spaceRight < _submenuFallbackWidth && spaceLeft > spaceRight;
    onPlaced?.call(onLeft);
    const minTop = ghMenuGap;
    final maxTop = size.height - _submenuFallbackHeight - ghMenuGap;
    final top = math.min(math.max(anchor.top, minTop), math.max(minTop, maxTop));
    final left = onLeft ? anchor.left - inset - childSize.width : anchor.right + inset;
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_SubmenuLayout oldDelegate) => oldDelegate.anchor != anchor || oldDelegate.inset != inset;
}
