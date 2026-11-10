import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../core/ui_settings.dart';
import 'modal_events.dart';
import 'modal_header.dart';

enum GhModalWidth {
  sm(24),
  md(28),
  lg(32),
  xl(36),
  x2l(42),
  x3l(48),
  x4l(56),
  x5l(64);

  const GhModalWidth(this.rem);

  final double rem;
}

class GhModalReturnFocus extends InheritedWidget {
  const GhModalReturnFocus({super.key, required this.node, required super.child});

  final FocusNode? node;

  static FocusNode? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<GhModalReturnFocus>()?.node;

  @override
  bool updateShouldNotify(GhModalReturnFocus oldWidget) => node != oldWidget.node;
}

class GhModalShell extends StatefulWidget {
  const GhModalShell({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.maxWidth = GhModalWidth.x2l,
    this.onClose,
    this.showClose = true,
    this.onKeyEvent,
    this.footer,
    this.bodyHeight,
    this.initialFocus,
    this.isMenuOpen,
    this.staticPreview = false,
  });

  final Widget icon;
  final String title;
  final Widget child;
  final GhModalWidth maxWidth;
  final VoidCallback? onClose;
  final bool showClose;
  final FocusOnKeyEventCallback? onKeyEvent;
  final List<Widget>? footer;
  final double? bodyHeight;
  final FocusNode? initialFocus;
  final bool Function()? isMenuOpen;
  final bool staticPreview;

  static double tallBodyHeight(BuildContext context) =>
      math.min(MediaQuery.sizeOf(context).height * 0.6, GhTheme.of(context).rem(34));

  @override
  State<GhModalShell> createState() => _GhModalShellState();
}

class _GhModalShellState extends State<GhModalShell> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'GhModalShell');
  late final GhModalFocusHandle _handle = GhModalFocusHandle(_scope);
  FocusNode? _returnFocus;
  ModalRoute<Object?>? _route;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (widget.staticPreview) {
      return;
    }
    _returnFocus = GhModalReturnFocus.maybeOf(context) ?? FocusManager.instance.primaryFocus;
    scheduleMicrotask(() => GhModalEvents.openDialogs.value += 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => scheduleMicrotask(_applyInitialFocus));
  }

  void _applyInitialFocus() {
    if (!mounted) {
      return;
    }
    final preferred = widget.initialFocus;
    if (preferred != null && preferred.context != null && preferred.canRequestFocus) {
      preferred.requestFocus();
      return;
    }
    if (_scope.hasFocus) {
      return;
    }
    (_handle.banner ?? _scope).requestFocus();
  }

  @override
  void dispose() {
    if (!widget.staticPreview) {
      scheduleMicrotask(() {
        final value = GhModalEvents.openDialogs.value;
        GhModalEvents.openDialogs.value = value > 0 ? value - 1 : 0;
      });
      final target = _returnFocus;
      if (target != null) {
        scheduleMicrotask(() {
          if (target.context?.mounted == true && target.canRequestFocus) {
            target.requestFocus();
          }
        });
      }
    }
    _scope.dispose();
    super.dispose();
  }

  bool get _menuOpen => widget.isMenuOpen?.call() ?? GhModalEvents.isMenuOpen;

  void _close() {
    final onClose = widget.onClose;
    if (onClose == null) {
      return;
    }
    final route = _route;
    if (route != null && !route.isCurrent) {
      return;
    }
    onClose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final custom = widget.onKeyEvent?.call(node, event);
    if (custom != null && custom != KeyEventResult.ignored) {
      return custom;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_menuOpen || widget.onClose == null) {
        return KeyEventResult.ignored;
      }
      _close();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    final focusable = _scope.traversalDescendants.where((n) => n.canRequestFocus && !n.skipTraversal).toList();
    if (focusable.isEmpty) {
      return KeyEventResult.handled;
    }
    final current = FocusManager.instance.primaryFocus;
    if (current != null && focusable.contains(current)) {
      return KeyEventResult.ignored;
    }
    final policy = WidgetOrderTraversalPolicy();
    final target = HardwareKeyboard.instance.isShiftPressed
        ? policy.findLastFocus(_scope, ignoreCurrentFocus: true)
        : policy.findFirstFocus(_scope, ignoreCurrentFocus: true);
    target?.requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final pad = theme.space(4);
    final footer = widget.footer;
    final bodyHeight = widget.bodyHeight;
    final dialog = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusModal),
        boxShadow: GhShadows.xl2(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GhModalHeader(
            icon: widget.icon,
            title: widget.title,
            onClose: widget.showClose && widget.onClose != null ? _close : null,
          ),
          Flexible(
            child: bodyHeight != null
                ? SizedBox(height: bodyHeight, child: widget.child)
                : SingleChildScrollView(child: widget.child),
          ),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.line))),
              child: Padding(
                padding: EdgeInsets.all(theme.space(4)),
                child: Row(spacing: theme.space(2.5), children: footer),
              ),
            ),
        ],
      ),
    );
    return GhModalFocusProvider(
      handle: _handle,
      child: DefaultTextStyle(
        style: theme.text(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = math.max(0.0, math.min(viewport.height * 0.88, constraints.maxHeight - pad * 2));
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: const ColoredBox(color: Color(0xB3000000)),
                ),
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: theme.rem(widget.maxWidth.rem), maxHeight: maxHeight),
                      child: SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          scopesRoute: true,
                          namesRoute: true,
                          explicitChildNodes: true,
                          label: widget.title,
                          child: FocusScope(
                            node: _scope,
                            onKeyEvent: _onKey,
                            child: FocusTraversalGroup(policy: WidgetOrderTraversalPolicy(), child: dialog),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GhModalRoute<T> extends PopupRoute<T> {
  GhModalRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: GhCurves.outExpo), child: child);
  }
}

Future<T?> showGhModal<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool useRootNavigator = true,
  RouteSettings? settings,
}) {
  final returnFocus = FocusManager.instance.primaryFocus;
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  final uiSettings = GhUiSettings.of(context);
  return navigator.push(
    GhModalRoute<T>(
      settings: settings,
      builder: (routeContext) => themes.wrap(
        GhUiSettings(
          data: uiSettings,
          child: Directionality(
            textDirection: direction,
            child: GhModalReturnFocus(node: returnFocus, child: Builder(builder: builder)),
          ),
        ),
      ),
    ),
  );
}
