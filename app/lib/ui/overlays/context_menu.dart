import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../motion/presence.dart';
import 'menu.dart';
import 'popup_registry.dart';

class GhContextMenu extends StatefulWidget {
  const GhContextMenu({
    super.key,
    required this.items,
    required this.position,
    required this.onClose,
    this.compact = false,
    this.label,
    this.visible = true,
    this.onExited,
  });

  final List<GhMenuItem> items;
  final Offset position;
  final VoidCallback onClose;
  final bool compact;
  final String? label;
  final bool visible;
  final VoidCallback? onExited;

  @override
  State<GhContextMenu> createState() => _GhContextMenuState();
}

class _GhContextMenuState extends State<GhContextMenu> with WidgetsBindingObserver {
  final _portal = OverlayPortalController();
  final Map<String, FocusNode> _nodes = {};
  final List<ScrollPosition> _scrollPositions = [];
  GhPopupHandle? _handle;
  Timer? _pendingSecondaryClose;
  bool _closed = false;
  bool _up = false;
  bool _leftwards = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _portal.show();
    _handle = GhPopupRegistry.open(close: _close, surface: () => null, origin: () => null, onEscape: _close);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closed) {
        return;
      }
      _attachScroll();
      ghFirstFocusableMenuNode(_orderedNodes())?.requestFocus();
    });
  }

  @override
  void didUpdateWidget(GhContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pendingSecondaryClose?.cancel();
    _pendingSecondaryClose = null;
    if (oldWidget.visible && !widget.visible) {
      _dismiss();
    }
  }

  void _dismiss() {
    _closed = true;
    _handle?.release();
    _detachScroll();
  }

  void _onExited() {
    if (_portal.isShowing) {
      _portal.hide();
    }
    widget.onExited?.call();
  }

  void _placed(bool up, bool leftwards) {
    if (up == _up && leftwards == _leftwards) {
      return;
    }
    _up = up;
    _leftwards = leftwards;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingSecondaryClose?.cancel();
    _handle?.release();
    _detachScroll();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() => _close();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _close();
    }
  }

  void _close() {
    if (_closed) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _close());
      return;
    }
    _closed = true;
    _pendingSecondaryClose?.cancel();
    _handle?.release();
    _detachScroll();
    widget.onClose();
  }

  void _attachScroll() {
    var state = context.findAncestorStateOfType<ScrollableState>();
    while (state != null) {
      state.position.addListener(_close);
      _scrollPositions.add(state.position);
      state = state.context.findAncestorStateOfType<ScrollableState>();
    }
  }

  void _detachScroll() {
    for (final position in _scrollPositions) {
      position.removeListener(_close);
    }
    _scrollPositions.clear();
  }

  void _onTapOutside(PointerDownEvent event) {
    if (event.buttons & kSecondaryButton != 0) {
      _pendingSecondaryClose?.cancel();
      _pendingSecondaryClose = Timer(Duration.zero, _close);
      return;
    }
    _close();
  }

  FocusNode _node(String id) => _nodes.putIfAbsent(id, () => GhMenuItemFocusNode(debugLabel: 'GhContextMenu $id'));

  Iterable<FocusNode> _orderedNodes() => widget.items.map((item) => _node(item.id));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return ghMenuArrowNavigation(event, _orderedNodes());
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildOverlay,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final overlayBox = Overlay.maybeOf(context, rootOverlay: true)?.context.findRenderObject();
    var point = widget.position;
    if (overlayBox is RenderBox && overlayBox.hasSize) {
      point = overlayBox.globalToLocal(point);
    }
    final rows = <Widget>[];
    for (final item in widget.items) {
      rows.add(
        GhMenuButton(
          item: item,
          compact: widget.compact,
          caret: item.hasChildren,
          focusNode: _node(item.id),
          onSelect: () {
            _close();
            item.onSelected?.call();
          },
        ),
      );
      if (item.dividerAfter) {
        rows.add(GhMenuDivider(compact: widget.compact));
      }
    }
    return CustomSingleChildLayout(
      delegate: _ContextMenuLayout(point, onPlaced: _placed),
      child: GhPresence(
        visible: widget.visible,
        kind: GhPresenceKind.popover,
        up: _up,
        origin: Alignment(_leftwards ? 1 : -1, _up ? 1 : -1),
        onExited: _onExited,
        child: TapRegion(
          onTapOutside: _onTapOutside,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onKey,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: widget.label,
              child: GhMenuSurface(
                compact: widget.compact,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

(bool, bool) ghContextMenuFlips({required Offset point, required Size menu, required Size viewport}) {
  const pad = ghMenuViewportPad;
  final x = point.dx;
  final y = point.dy;
  final spaceBelow = viewport.height - y;
  final spaceRight = viewport.width - x;
  return (spaceBelow < menu.height + pad && y > spaceBelow, spaceRight < menu.width + pad && x > spaceRight);
}

Offset ghContextMenuPosition({required Offset point, required Size menu, required Size viewport}) {
  const pad = ghMenuViewportPad;
  final x = point.dx;
  final y = point.dy;
  final (up, leftwards) = ghContextMenuFlips(point: point, menu: menu, viewport: viewport);
  final left = math.max(pad, math.min(leftwards ? x - menu.width : x, viewport.width - menu.width - pad));
  final top = math.max(pad, math.min(up ? y - menu.height : y, viewport.height - menu.height - pad));
  return Offset(left, top);
}

class _ContextMenuLayout extends SingleChildLayoutDelegate {
  _ContextMenuLayout(this.point, {this.onPlaced});

  final Offset point;
  final void Function(bool up, bool leftwards)? onPlaced;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints(maxWidth: constraints.maxWidth);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final (up, leftwards) = ghContextMenuFlips(point: point, menu: childSize, viewport: size);
    onPlaced?.call(up, leftwards);
    return ghContextMenuPosition(point: point, menu: childSize, viewport: size);
  }

  @override
  bool shouldRelayout(_ContextMenuLayout oldDelegate) => oldDelegate.point != point;
}

class GhContextMenuArea extends StatefulWidget {
  const GhContextMenuArea({super.key, required this.items, required this.child, this.compact = false, this.label, this.enabled = true});

  final List<GhMenuItem> Function() items;
  final Widget child;
  final bool compact;
  final String? label;
  final bool enabled;

  @override
  State<GhContextMenuArea> createState() => _GhContextMenuAreaState();
}

class _AreaMenu {
  _AreaMenu(this.generation, this.position);

  final int generation;
  final Offset position;
  bool closing = false;
}

class _GhContextMenuAreaState extends State<GhContextMenuArea> {
  final List<_AreaMenu> _menus = [];
  int _generation = 0;

  void _open(Offset position) {
    setState(() {
      for (final menu in _menus) {
        menu.closing = true;
      }
      _menus.add(_AreaMenu(++_generation, position));
    });
  }

  void _close(_AreaMenu menu) {
    if (mounted && !menu.closing) {
      setState(() => menu.closing = true);
    }
  }

  void _remove(_AreaMenu menu) {
    if (mounted) {
      setState(() => _menus.remove(menu));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: widget.enabled ? (details) => _open(details.globalPosition) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          for (final menu in _menus)
            Positioned(
              key: ValueKey(menu.generation),
              left: 0,
              top: 0,
              child: GhContextMenu(
                items: widget.items(),
                position: menu.position,
                compact: widget.compact,
                label: widget.label,
                visible: !menu.closing,
                onClose: () => _close(menu),
                onExited: () => _remove(menu),
              ),
            ),
        ],
      ),
    );
  }
}
