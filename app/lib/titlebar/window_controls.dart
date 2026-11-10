import 'package:flutter/material.dart';

import '../design/design.dart';
import 'package:window_manager/window_manager.dart';

import '../ui/core/i18n.dart';
import 'title_bar_theme.dart';

abstract interface class TitleBarWindow {
  bool get isMaximized;

  void minimize();

  void toggleMaximize();

  void close();

  void startDragging();

  VoidCallback addMaximizeListener(VoidCallback onChanged);
}

class NativeTitleBarWindow implements TitleBarWindow {
  const NativeTitleBarWindow();

  Window? get _window {
    try {
      return WindowManager.instance.getCurrent();
    } on Object {
      return null;
    }
  }

  void _guard(void Function(Window window) action) {
    final window = _window;
    if (window == null) return;
    try {
      action(window);
    } on Object {
      return;
    }
  }

  @override
  bool get isMaximized {
    final window = _window;
    if (window == null) return false;
    try {
      return window.isMaximized;
    } on Object {
      return false;
    }
  }

  @override
  void minimize() => _guard((window) => window.minimize());

  @override
  void toggleMaximize() => _guard((window) {
    if (window.isMaximized) {
      window.unmaximize();
    } else {
      window.maximize();
    }
  });

  @override
  void close() => _guard((window) => window.close());

  @override
  void startDragging() => _guard((window) => window.startDragging());

  @override
  VoidCallback addMaximizeListener(VoidCallback onChanged) {
    final window = _window;
    if (window == null) return () {};
    try {
      final id = window.addListener((event) {
        if (event is WindowMaximizedEvent || event is WindowRestoredEvent || event is WindowResizedEvent) {
          onChanged();
        }
      });
      return () {
        try {
          window.removeListener(id);
        } on Object {
          return;
        }
      };
    } on Object {
      return () {};
    }
  }
}

class MaximizedStateBuilder extends StatefulWidget {
  const MaximizedStateBuilder({super.key, required this.window, required this.builder});

  final TitleBarWindow window;
  final Widget Function(BuildContext context, bool isMaximized) builder;

  @override
  State<MaximizedStateBuilder> createState() => _MaximizedStateBuilderState();
}

class _MaximizedStateBuilderState extends State<MaximizedStateBuilder> {
  bool _isMaximized = false;
  VoidCallback? _unlisten;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(MaximizedStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.window, widget.window)) {
      _unlisten?.call();
      _attach();
    }
  }

  void _attach() {
    _isMaximized = widget.window.isMaximized;
    _unlisten = widget.window.addMaximizeListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    final next = widget.window.isMaximized;
    if (next != _isMaximized) setState(() => _isMaximized = next);
  }

  @override
  void dispose() {
    _unlisten?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _isMaximized);
}

class WindowControls extends StatelessWidget {
  const WindowControls({
    super.key,
    required this.colored,
    required this.isMaximized,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
  });

  final bool colored;
  final bool isMaximized;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final maximizeLabel = isMaximized ? context.tr.common.restore : context.tr.common.maximize;
    if (colored) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ColoredDot(
            key: const ValueKey('window-minimize'),
            color: tokens.mint,
            shift: 6,
            label: context.tr.common.minimize,
            onPressed: onMinimize,
          ),
          _ColoredDot(
            key: const ValueKey('window-maximize'),
            color: tokens.amber,
            shift: 0,
            label: maximizeLabel,
            onPressed: onToggleMaximize,
          ),
          _ColoredDot(
            key: const ValueKey('window-close'),
            color: tokens.danger,
            shift: -6,
            label: context.tr.common.close,
            onPressed: onClose,
          ),
        ],
      );
    }
    final idle = tokens.ink.withValues(alpha: 0.55);
    final hoverBackground = tokens.ink.withValues(alpha: 0.1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleBarIconButton(
          key: const ValueKey('window-minimize'),
          icon: GhIcons.minus,
          iconSize: 14,
          width: 44,
          height: null,
          radius: 0,
          color: idle,
          hoverColor: tokens.ink,
          hoverBackground: hoverBackground,
          tooltip: context.tr.common.minimize,
          semanticLabel: context.tr.common.minimize,
          onPressed: onMinimize,
        ),
        TitleBarIconButton(
          key: const ValueKey('window-maximize'),
          icon: isMaximized ? GhIcons.windowRestore : GhIcons.windowMaximize,
          iconSize: 12,
          width: 44,
          height: null,
          radius: 0,
          color: idle,
          hoverColor: tokens.ink,
          hoverBackground: hoverBackground,
          tooltip: maximizeLabel,
          semanticLabel: maximizeLabel,
          onPressed: onToggleMaximize,
        ),
        TitleBarIconButton(
          key: const ValueKey('window-close'),
          icon: GhIcons.x,
          iconSize: 14,
          width: 44,
          height: null,
          radius: 0,
          color: idle,
          hoverColor: Colors.white,
          hoverBackground: tokens.danger,
          tooltip: context.tr.common.close,
          semanticLabel: context.tr.common.close,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _ColoredDot extends StatelessWidget {
  const _ColoredDot({
    super.key,
    required this.color,
    required this.shift,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final double shift;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return TitleBarButton(
      onPressed: onPressed,
      tooltip: label,
      semanticLabel: label,
      builder: (context, hovered) => SizedBox(
        width: 36,
        child: Center(
          child: Transform.translate(
            offset: Offset(shift * direction, 0),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: hovered ? Color.lerp(color, Colors.white, 0.2) : color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
