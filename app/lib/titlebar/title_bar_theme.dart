import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/core/interaction.dart';

class TitleBarTokens {
  const TitleBarTokens({
    required this.ink,
    required this.muted,
    required this.raised,
    required this.overlay,
    required this.line,
    required this.accent,
    required this.accentBright,
    required this.mint,
    required this.amber,
    required this.danger,
    required this.cornerRadius,
  });

  factory TitleBarTokens.from(ThemeData theme, {double cornerRadius = 7}) {
    final gh = theme.extension<GhTheme>();
    if (gh != null) {
      return TitleBarTokens(
        ink: gh.ink,
        muted: gh.muted,
        raised: gh.raised,
        overlay: gh.overlay,
        line: gh.line,
        accent: gh.accent,
        accentBright: gh.accentBright,
        mint: gh.mint,
        amber: gh.amber,
        danger: gh.danger,
        cornerRadius: gh.cornerRadius,
      );
    }
    final scheme = theme.colorScheme;
    return TitleBarTokens(
      ink: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      raised: scheme.surfaceContainerHigh,
      overlay: scheme.surfaceContainer,
      line: scheme.outlineVariant,
      accent: scheme.primary,
      accentBright: Color.lerp(scheme.primary, Colors.white, 0.25)!,
      mint: const Color(0xFF2FBF71),
      amber: const Color(0xFFF0B132),
      danger: const Color(0xFFF2555A),
      cornerRadius: cornerRadius,
    );
  }

  final Color ink;
  final Color muted;
  final Color raised;
  final Color overlay;
  final Color line;
  final Color accent;
  final Color accentBright;
  final Color mint;
  final Color amber;
  final Color danger;
  final double cornerRadius;

  double get tagRadius => cornerRadius;
  double get smRadius => cornerRadius * 0.8;
  double get btnRadius => cornerRadius * 1.6;
  double get itemRadius => cornerRadius * 2.2;
  double get menuRadius => cornerRadius * 2.4;

  static TitleBarTokens of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TitleBarTheme>();
    return scope?.tokens ?? TitleBarTokens.from(Theme.of(context));
  }

  MenuStyle menuStyle({EdgeInsetsGeometry padding = const EdgeInsets.all(6)}) {
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll(overlay),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.1)),
      elevation: const WidgetStatePropertyAll(4),
      padding: WidgetStatePropertyAll(padding),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(menuRadius),
          side: BorderSide(color: line.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class TitleBarTheme extends InheritedWidget {
  const TitleBarTheme({super.key, required this.tokens, required super.child});

  final TitleBarTokens tokens;

  @override
  bool updateShouldNotify(TitleBarTheme oldWidget) => tokens != oldWidget.tokens;
}

class TitleBarButton extends StatefulWidget {
  const TitleBarButton({
    super.key,
    required this.onPressed,
    required this.builder,
    this.tooltip,
    this.semanticLabel,
    this.expanded,
    this.ripple = true,
    this.borderRadius,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool hovered) builder;
  final String? tooltip;
  final String? semanticLabel;
  final bool? expanded;
  final bool ripple;
  final BorderRadius? borderRadius;

  @override
  State<TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<TitleBarButton> {
  bool _hovered = false;
  bool _focused = false;
  int _pulse = 0;

  void _activate() => widget.onPressed?.call();

  void _keyActivate() {
    if (widget.onPressed == null) {
      return;
    }
    setState(() => _pulse += 1);
    _activate();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    Widget result = FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _keyActivate();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _activate : null,
        child: GhPressMotion(
          enabled: enabled,
          ripple: widget.ripple,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(TitleBarTokens.of(context).itemRadius),
          pulse: _pulse,
          child: widget.builder(context, enabled && (_hovered || _focused)),
        ),
      ),
    );
    result = Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      expanded: widget.expanded,
      excludeSemantics: widget.semanticLabel != null,
      child: result,
    );
    final tooltip = widget.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      result = Tooltip(message: tooltip, excludeFromSemantics: true, child: result);
    }
    return result;
  }
}

class TitleBarIconButton extends StatelessWidget {
  const TitleBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.color,
    required this.hoverColor,
    required this.hoverBackground,
    this.background = Colors.transparent,
    this.iconSize = 14,
    this.radius,
    this.tooltip,
    this.semanticLabel,
    this.expanded,
  });

  final FaIconData icon;
  final VoidCallback? onPressed;
  final double width;
  final double? height;
  final Color color;
  final Color hoverColor;
  final Color background;
  final Color hoverBackground;
  final double iconSize;
  final double? radius;
  final String? tooltip;
  final String? semanticLabel;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    return TitleBarButton(
      onPressed: onPressed,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      expanded: expanded,
      borderRadius: BorderRadius.circular(radius ?? tokens.itemRadius),
      builder: (context, hovered) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered ? hoverBackground : background,
          borderRadius: BorderRadius.circular(radius ?? tokens.itemRadius),
        ),
        child: GhIcon(icon, size: iconSize, color: hovered ? hoverColor : color),
      ),
    );
  }
}
