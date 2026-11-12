import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/i18n.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart' show GhSide;
import '../overlays/dropdown.dart';
import '../overlays/menu.dart';

enum GhOpenButtonSize { normal, compact }

class GhOpenButton extends StatefulWidget {
  const GhOpenButton({
    super.key,
    required this.label,
    required this.onOpen,
    required this.items,
    required this.moreLabel,
    this.headerItems = const [],
    this.consoleSupported = false,
    this.consoleInitiallyOn = false,
    this.showConsole = true,
    this.disabled = false,
    this.size = GhOpenButtonSize.normal,
    this.disabledReason,
    this.paddingX = 10,
  });

  final String label;
  final void Function(bool? console) onOpen;
  final List<GhMenuItem> items;
  final List<GhDropdownHeaderItem> headerItems;
  final bool consoleSupported;
  final bool consoleInitiallyOn;
  final bool showConsole;
  final bool disabled;
  final String moreLabel;
  final GhOpenButtonSize size;
  final String? disabledReason;
  final double paddingX;

  @override
  State<GhOpenButton> createState() => _GhOpenButtonState();
}

class _GhOpenButtonState extends State<GhOpenButton> {
  late bool _console = widget.consoleSupported && widget.consoleInitiallyOn;

  @override
  void didUpdateWidget(GhOpenButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consoleSupported != widget.consoleSupported || oldWidget.consoleInitiallyOn != widget.consoleInitiallyOn) {
      _console = widget.consoleSupported && widget.consoleInitiallyOn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final compact = widget.size == GhOpenButtonSize.compact;
    final height = theme.space(compact ? 9 : 12);
    final shadow = GhShadows.md(Colors.black.withValues(alpha: 0.1));
    final textStyle = compact
        ? theme.text(size: GhTextSize.xs, weight: GhWeight.semibold)
        : theme.text(weight: GhWeight.semibold).copyWith(fontSize: theme.rem(1.0625));
    final disabled = widget.disabled;
    final mainRadius = BorderRadiusDirectional.horizontal(
      start: Radius.circular(theme.radiusDropdownBtn),
      end: const Radius.circular(4),
    ).resolve(Directionality.of(context));
    final tooltip = disabled ? widget.disabledReason : (_console ? tr.open_with_console : widget.label);
    Widget main = GhPressable(
      onPressed: disabled ? null : () => widget.onOpen((widget.consoleSupported && _console) ? true : null),
      disabledOpacity: null,
      disabledCursor: SystemMouseCursors.forbidden,
      borderRadius: mainRadius,
      tooltip: tooltip,
      semanticLabel: widget.label,
      rippleColor: Colors.white,
      builder: (context, states) {
        final hover = states.active;
        final foreground = disabled ? theme.muted.withValues(alpha: 0.4) : Colors.white;
        return GhAnimatedBox(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: theme.space(compact ? 3 : widget.paddingX)),
          alignment: Alignment.center,
          color: disabled ? theme.raised : (hover ? theme.accentBright : theme.accent),
          borderRadius: mainRadius,
          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          boxShadow: shadow,
          child: Text(
            widget.label,
            maxLines: 1,
            softWrap: false,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            style: textStyle.copyWith(color: foreground),
          ),
        );
      },
    );
    if (compact) main = Expanded(child: main);
    final children = <Widget>[main];
    if (widget.consoleSupported && widget.showConsole) {
      children.add(
        GhTooltip(
          message: tr.open_with_console,
          side: GhSide.top,
          child: GhPressable(
            onPressed: disabled ? null : () => setState(() => _console = !_console),
            toggled: _console,
            semanticLabel: tr.open_with_console,
            borderRadius: BorderRadius.circular(4),
            builder: (context, states) {
              final hover = states.active;
              return GhAnimatedBox(
                width: compact ? theme.space(9) : null,
                height: height,
                padding: compact ? null : EdgeInsets.all(theme.space(2)),
                alignment: Alignment.center,
                color: _console ? theme.raised : theme.overlay,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _console ? theme.mint : (hover ? theme.mint.withValues(alpha: 0.5) : theme.outline.withValues(alpha: 0.5)),
                ),
                boxShadow: shadow,
                child: GhIcon(GhIcons.terminal, size: theme.space(4), color: _console ? theme.mint : (hover ? theme.mint : theme.muted)),
              );
            },
          ),
        ),
      );
    }
    children.add(
      GhDropdown(
        align: GhSide.right,
        side: compact ? GhSide.bottom : GhSide.left,
        compact: true,
        header: widget.headerItems,
        items: widget.items,
        trigger: (context, open, toggle) {
          final radius = BorderRadiusDirectional.horizontal(
            start: const Radius.circular(4),
            end: Radius.circular(theme.radiusDropdown),
          ).resolve(Directionality.of(context));
          return GhPressable(
            onPressed: toggle,
            expanded: open,
            semanticLabel: widget.moreLabel,
            borderRadius: radius,
            builder: (context, states) {
              final hover = states.active;
              return GhAnimatedBox(
                width: compact ? theme.space(8) : null,
                height: height,
                padding: compact ? null : const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                color: open || hover ? theme.raised : theme.overlay,
                borderRadius: radius,
                border: Border.all(color: open ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
                boxShadow: shadow,
                child: GhIcon(GhIcons.more, size: theme.space(4), color: open || hover ? theme.ink : theme.muted),
              );
            },
          );
        },
      ),
    );
    return Row(
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.end,
      spacing: theme.space(1),
      children: children,
    );
  }
}
