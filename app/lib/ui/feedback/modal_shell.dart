import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../../motion/motion.dart';
import '../../motion/presence.dart';
import '../core/ui_settings.dart';
import 'modal_events.dart';
import 'modal_header.dart';
import '../shell/smooth_scroll.dart';

enum GhModalWidth {
  sm(24),
  md(28),
  lg(32),
  xl(36),
  x2l(42),
  x3l(48),
  x4l(56),
  x5l(64),
  x6l(72);

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
    this.rawFooter,
    this.bodyHeight,
    this.panelHeight,
    this.titleMaxLines = 2,
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
  final Widget? rawFooter;
  final double? bodyHeight;
  final double? panelHeight;
  final int? titleMaxLines;
  final FocusNode? initialFocus;
  final bool Function()? isMenuOpen;
  final bool staticPreview;

  static double tallBodyHeight(BuildContext context) => math.min(MediaQuery.sizeOf(context).height * 0.6, GhTheme.of(context).rem(34));

  @override
  State<GhModalShell> createState() => _GhModalShellState();
}

class _GhModalShellState extends State<GhModalShell> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'GhModalShell');
  late final GhModalFocusHandle _handle = GhModalFocusHandle(_scope);
  FocusNode? _returnFocus;
  ModalRoute<Object?>? _route;
  bool _initialized = false;
  bool _released = false;

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
    _route?.popped.then((_) => _release());
  }

  void _release() {
    if (_released || widget.staticPreview) {
      return;
    }
    _released = true;
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
    _release();
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
    final panelHeight = widget.panelHeight;
    Widget dialog = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(theme.radiusModal), boxShadow: GhShadows.xl2()),
      child: Column(
        mainAxisSize: panelHeight != null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GhModalHeader(
            icon: widget.icon,
            title: widget.title,
            titleMaxLines: widget.titleMaxLines,
            onClose: widget.showClose && widget.onClose != null ? _close : null,
          ),
          if (panelHeight != null)
            Expanded(child: GhCascadeItem(child: widget.child))
          else
            Flexible(
              child: GhCascadeItem(
                child: bodyHeight != null ? SizedBox(height: bodyHeight, child: widget.child) : GhScrollView(child: widget.child),
              ),
            ),
          ?widget.rawFooter,
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.line)),
              ),
              child: Padding(
                padding: EdgeInsets.all(theme.space(4)),
                child: Row(spacing: theme.space(2.5), children: [for (final part in footer) ghModalPart(part)]),
              ),
            ),
        ],
      ),
    );
    if (!widget.staticPreview) {
      dialog = GhPresenceLayerView(layer: GhPresenceSpecs.modalPanel, child: dialog);
    }
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
                        height: panelHeight == null ? null : math.min(panelHeight, maxHeight),
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

Widget ghModalPart(Widget part) {
  if (part is Spacer) {
    return part;
  }
  if (part is Flexible) {
    return Flexible(
      key: part.key,
      flex: part.flex,
      fit: part.fit,
      child: GhCascadeItem(child: part.child),
    );
  }
  return GhCascadeItem(child: part);
}

class GhModalRoute<T> extends PopupRoute<T> {
  GhModalRoute({required this.builder, super.settings, this.motion = const GhMotionData()});

  final WidgetBuilder builder;
  final GhMotionData motion;

  static GhPresenceSpec get spec => GhPresenceSpecs.modal;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => motion.off ? Duration.zero : motion.gsap(spec.enterLength);

  @override
  Duration get reverseTransitionDuration => motion.off ? Duration.zero : motion.gsap(spec.exitLength);

  @override
  bool didPop(T? result) {
    final controller = this.controller;
    if (controller != null && !motion.off && controller.value > 0 && controller.value < 1) {
      controller.reverseDuration = Duration(microseconds: (reverseTransitionDuration.inMicroseconds / controller.value).round());
    }
    return super.didPop(result);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => GhMotion(
    prefs: motion.prefs,
    osReduced: motion.osReduced,
    child: Builder(builder: builder),
  );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return _GhModalTransition(animation: animation, child: child);
  }
}

class _GhRouteClock extends ChangeNotifier implements GhPresenceClock {
  _GhRouteClock(this.animation) {
    animation.addListener(notifyListeners);
    animation.addStatusListener(_onStatus);
    if (animation.status == AnimationStatus.reverse) {
      _exitFrom = animation.value;
    }
  }

  final Animation<double> animation;
  double? _exitFrom;

  GhPresenceSpec get _spec => GhModalRoute.spec;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      _exitFrom ??= animation.value;
    } else if (status == AnimationStatus.forward) {
      _exitFrom = null;
    }
  }

  @override
  bool get exiting => _exitFrom != null;

  @override
  double get time {
    final from = _exitFrom;
    if (from == null) {
      return animation.value * _spec.enterLength;
    }
    if (from <= 0) {
      return _spec.exitLength;
    }
    return ((from - animation.value) / from).clamp(0.0, 1.0) * _spec.exitLength;
  }

  @override
  double get enteredAt => (_exitFrom ?? animation.value) * _spec.enterLength;

  @override
  void dispose() {
    animation.removeListener(notifyListeners);
    animation.removeStatusListener(_onStatus);
    super.dispose();
  }
}

class _GhModalTransition extends StatefulWidget {
  const _GhModalTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_GhModalTransition> createState() => _GhModalTransitionState();
}

class _GhModalTransitionState extends State<_GhModalTransition> {
  late _GhRouteClock _clock = _GhRouteClock(widget.animation);
  final GhCascadeRegistry _registry = GhCascadeRegistry();

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(_GhModalTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onStatus);
      widget.animation.addStatusListener(_onStatus);
      _clock.dispose();
      _clock = _GhRouteClock(widget.animation);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exiting = _clock.exiting;
    return GhPresenceScope(
      clock: _clock,
      spec: GhModalRoute.spec,
      registry: _registry,
      parent: GhPresenceScope.maybeOf(context),
      child: IgnorePointer(
        ignoring: exiting,
        child: ExcludeFocus(
          excluding: exiting,
          child: GhPresenceLayerView(layer: GhModalRoute.spec.layer, child: widget.child),
        ),
      ),
    );
  }
}

Future<T?> showGhModal<T>(BuildContext context, WidgetBuilder builder, {bool useRootNavigator = true, RouteSettings? settings}) {
  final returnFocus = FocusManager.instance.primaryFocus;
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
  final uiSettings = GhUiSettings.of(context);
  final motion = GhMotion.of(context);
  return navigator.push(
    GhModalRoute<T>(
      settings: settings,
      motion: motion,
      builder: (routeContext) => themes.wrap(
        GhUiSettings(
          data: uiSettings,
          child: Directionality(
            textDirection: direction,
            child: GhModalReturnFocus(
              node: returnFocus,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    ),
  );
}
