import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/presence.dart';
import '../core/interaction.dart';
import 'menu.dart';

@immutable
class GhSlashMenuItem {
  const GhSlashMenuItem({required this.id, required this.label, this.hint, this.icon, this.dotColor});

  final String id;
  final String label;
  final String? hint;
  final FaIconData? icon;
  final Color? dotColor;
}

class GhSlashMenu extends StatelessWidget {
  const GhSlashMenu({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.emptyLabel,
    required this.onSelect,
    required this.onHighlight,
    this.footer,
  });

  final String title;
  final String? footer;
  final List<GhSlashMenuItem> items;
  final int selectedIndex;
  final String emptyLabel;
  final void Function(GhSlashMenuItem item, int index) onSelect;
  final ValueChanged<int> onHighlight;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final children = <Widget>[
      Padding(
        padding: EdgeInsetsDirectional.fromSTEB(theme.space(2), theme.space(0.5), theme.space(2), theme.space(1)),
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              maxLines: 1,
              style: theme.text(
                size: GhTextSize.x3s,
                weight: GhWeight.semibold,
                color: theme.muted.withValues(alpha: 0.6),
                letterSpacingEm: 0.05,
              ),
            ),
            SizedBox(width: theme.space(2)),
            Expanded(child: Container(height: 1, color: theme.outline.withValues(alpha: 0.4))),
          ],
        ),
      ),
      if (items.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(2)),
          child: Text(
            emptyLabel,
            style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.7)),
          ),
        )
      else
        for (var i = 0; i < items.length; i++)
          _SlashMenuRow(
            item: items[i],
            active: i == selectedIndex,
            onHighlight: () => onHighlight(i),
            onSelect: () => onSelect(items[i], i),
          ),
      if (footer != null)
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(theme.space(2), theme.space(2), theme.space(2), theme.space(1)),
          child: Text(
            footer!,
            style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.6)),
          ),
        ),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: title,
      child: GhMenuSurface(
        fitContent: false,
        maxHeight: theme.space(64),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

class _SlashMenuRow extends StatelessWidget {
  const _SlashMenuRow({required this.item, required this.active, required this.onHighlight, required this.onSelect});

  final GhSlashMenuItem item;
  final bool active;
  final VoidCallback onHighlight;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhCascadeItem(
      role: GhCascadeRole.menuItem,
      child: MouseRegion(
        onEnter: (_) => onHighlight(),
        child: GhPressable(
          onPressed: onSelect,
          focusStyle: GhFocusStyle.outline,
          borderRadius: radius,
          selected: active,
          builder: (context, states) {
            final hovered = states.hovered;
            final background = active ? theme.accent : (hovered ? theme.raised : theme.raised.withValues(alpha: 0));
            final foreground = active || hovered ? theme.ink : theme.muted;
            final children = <Widget>[
              if (item.dotColor != null)
                ExcludeSemantics(
                  child: Container(
                    width: theme.space(2),
                    height: theme.space(2),
                    decoration: BoxDecoration(color: item.dotColor, shape: BoxShape.circle),
                  ),
                )
              else if (item.icon != null)
                GhIconMotionScale(
                  states: states,
                  child: GhAnimatedIcon(item.icon!, color: foreground, size: theme.space(3.5)),
                ),
              Expanded(
                child: GhAnimatedText(
                  item.label,
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
              ),
              if (item.hint != null)
                Text(
                  item.hint!,
                  maxLines: 1,
                  style: theme.text(
                    size: GhTextSize.x3s,
                    mono: true,
                    lineHeight: 1 / 0.75,
                    color: active ? theme.ink.withValues(alpha: 0.7) : theme.muted.withValues(alpha: 0.5),
                  ),
                ),
            ];
            final spaced = <Widget>[];
            for (var i = 0; i < children.length; i++) {
              if (i > 0) {
                spaced.add(SizedBox(width: theme.space(2)));
              }
              spaced.add(children[i]);
            }
            return GhLiftBox(
              color: background,
              borderRadius: radius,
              lift: hovered,
              padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
              child: Row(children: spaced),
            );
          },
        ),
      ),
    );
  }
}

class GhSlashMenuAnchor extends StatefulWidget {
  const GhSlashMenuAnchor({super.key, required this.open, required this.menu, required this.child});

  final bool open;
  final Widget menu;
  final Widget child;

  @override
  State<GhSlashMenuAnchor> createState() => _GhSlashMenuAnchorState();
}

class _GhSlashMenuAnchorState extends State<GhSlashMenuAnchor> {
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context, info) {
        final theme = GhTheme.of(context);
        final anchor = MatrixUtils.transformRect(info.childPaintTransform, Offset.zero & info.childSize);
        return CustomSingleChildLayout(
          delegate: _SlashMenuLayout(
            anchor: anchor,
            gap: theme.space(2),
            minWidth: theme.space(60),
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
          child: GhPresence(
            visible: widget.open,
            kind: GhPresenceKind.popover,
            child: TextFieldTapRegion(child: widget.menu),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _SlashMenuLayout extends SingleChildLayoutDelegate {
  _SlashMenuLayout({required this.anchor, required this.gap, required this.minWidth, required this.rtl});

  final Rect anchor;
  final double gap;
  final double minWidth;
  final bool rtl;

  double get _width => math.max(anchor.width, minWidth);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.tightFor(width: _width);

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(rtl ? anchor.right - childSize.width : anchor.left, anchor.bottom + gap);

  @override
  bool shouldRelayout(_SlashMenuLayout oldDelegate) =>
      oldDelegate.anchor != anchor || oldDelegate.gap != gap || oldDelegate.minWidth != minWidth || oldDelegate.rtl != rtl;
}
