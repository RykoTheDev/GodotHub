import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../motion/animated_number.dart';
import '../motion/motion.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/dnd/sortable.dart';

enum CategorySectionVariant { list, grid }

class HiddenCategoryEntry {
  const HiddenCategoryEntry(this.category, this.count);

  final Category category;
  final int count;
}

class CategorySectionHeader extends StatelessWidget {
  const CategorySectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.open,
    required this.onToggle,
    this.color,
    this.leading,
    this.highlight = false,
    this.releaseHint = false,
    this.variant = CategorySectionVariant.list,
    this.onContextMenu,
  });

  final String title;
  final int count;
  final bool open;
  final VoidCallback onToggle;
  final Color? color;
  final Widget? leading;
  final bool highlight;
  final bool releaseHint;
  final CategorySectionVariant variant;
  final ValueChanged<Offset>? onContextMenu;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(theme.radiusItem);
    final grid = variant == CategorySectionVariant.grid;
    return Padding(
      padding: EdgeInsets.only(bottom: grid ? theme.space(1) : 0),
      child: GhPressable(
        onPressed: onToggle,
        expanded: open,
        borderRadius: radius,
        onSecondaryTapUp: onContextMenu == null ? null : (details) => onContextMenu!(details.globalPosition),
        builder: (context, states) {
          final hover = states.active;
          return GhAnimatedBox(
            color: highlight
                ? theme.accent.withValues(alpha: 0.1)
                : (hover ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0)),
            borderRadius: radius,
            border: highlight ? Border.all(color: theme.accent.withValues(alpha: 0.3)) : null,
            padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(grid ? 1.5 : 1)),
            child: Row(
              spacing: theme.space(1.5),
              children: [
                AnimatedRotation(
                  turns: open ? 0 : (rtl ? 0.25 : -0.25),
                  duration: motion.css(const Duration(milliseconds: 500)),
                  curve: GhCurves.spring,
                  child: GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted.withValues(alpha: 0.5)),
                ),
                ?leading,
                if (color != null)
                  Container(
                    width: theme.space(2),
                    height: theme.space(2),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(
                      size: GhTextSize.xs,
                      weight: GhWeight.semibold,
                      color: hover ? theme.muted : theme.muted.withValues(alpha: 0.5),
                      letterSpacingEm: 0.05,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    margin: EdgeInsets.symmetric(horizontal: theme.space(1.5)),
                    color: theme.outline.withValues(alpha: 0.3),
                  ),
                ),
                if (releaseHint)
                  Text(
                    context.tr.common.release_to_drop,
                    style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.accentBright),
                  ),
                DefaultTextStyle.merge(
                  style: theme
                      .text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.5))
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [const Text('· '), GhAnimatedNumber(count)]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProjectCategorySection extends StatefulWidget {
  const ProjectCategorySection({
    super.key,
    required this.title,
    required this.count,
    required this.bodySlivers,
    this.color,
    this.defaultOpen = true,
    this.droppableId,
    this.variant = CategorySectionVariant.list,
    this.onContextMenu,
  });

  static const dropOpenDelay = Duration(milliseconds: 450);

  final String title;
  final Color? color;
  final int count;
  final bool defaultOpen;
  final String? droppableId;
  final CategorySectionVariant variant;
  final ValueChanged<Offset>? onContextMenu;
  final List<Widget> bodySlivers;

  @override
  State<ProjectCategorySection> createState() => _ProjectCategorySectionState();
}

class _ProjectCategorySectionState extends State<ProjectCategorySection> {
  bool? _toggled;
  bool _dropOpen = false;
  Timer? _timer;

  bool get _open => _toggled ?? widget.defaultOpen;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncDrop(GhDropState state) {
    if (!state.dragging) {
      _timer?.cancel();
      _timer = null;
      if (_dropOpen) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? setState(() => _dropOpen = false) : null);
      return;
    }
    if (!state.isOver || _open) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer(ProjectCategorySection.dropOpenDelay, () {
      _timer = null;
      if (mounted) {
        setState(() {
          _dropOpen = true;
          _toggled = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final grid = widget.variant == CategorySectionVariant.grid;
    final id = widget.droppableId ?? 'cat-${widget.title}';
    return GhDroppable(
      id: id,
      disabled: widget.droppableId == null,
      builder: (context, state) {
        _syncDrop(state);
        final open = _open;
        final isEmpty = widget.count == 0;
        final headerIsZone = !open || _dropOpen;
        final bodyIsZone = open && isEmpty && !_dropOpen;
        final hint = Text(
          state.isOver ? context.tr.common.release_to_drop : context.tr.common.empty_category,
          style: theme.text(
            size: GhTextSize.xs,
            weight: state.isOver ? GhWeight.medium : GhWeight.normal,
            color: state.isOver ? theme.accentBright : theme.muted.withValues(alpha: 0.4),
          ),
        );
        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: CategorySectionHeader(
              title: widget.title,
              color: widget.color,
              count: widget.count,
              open: open,
              variant: widget.variant,
              highlight: headerIsZone && state.isOver,
              releaseHint: headerIsZone && state.isOver,
              onContextMenu: widget.onContextMenu,
              onToggle: () => setState(() => _toggled = !open),
            ),
          ),
          if (open) ...[
            if (!grid) SliverToBoxAdapter(child: SizedBox(height: theme.space(2))),
            ...widget.bodySlivers,
            if (isEmpty)
              SliverToBoxAdapter(
                child: grid
                    ? Container(
                        constraints: const BoxConstraints(minHeight: 100),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: state.isOver ? theme.accent.withValues(alpha: 0.1) : theme.overlay.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(theme.radiusItem),
                          border: Border.all(
                            color: state.isOver ? theme.accent.withValues(alpha: 0.5) : theme.outline.withValues(alpha: 0.3),
                            width: state.isOver ? 2 : 1,
                          ),
                        ),
                        child: hint,
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(vertical: theme.space(6)),
                        alignment: Alignment.center,
                        decoration: bodyIsZone && state.isOver
                            ? BoxDecoration(
                                color: theme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(theme.radiusItem),
                                border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
                              )
                            : null,
                        child: hint,
                      ),
              ),
            if (!grid) SliverToBoxAdapter(child: SizedBox(height: theme.space(0.5))),
          ],
          if (grid) SliverToBoxAdapter(child: SizedBox(height: theme.space(6))),
        ];
        return DecoratedSliver(
          decoration: BoxDecoration(
            color: state.dragging && state.containsTarget ? theme.accent.withValues(alpha: 0.05) : null,
            borderRadius: BorderRadius.circular(theme.radiusItem),
          ),
          sliver: SliverMainAxisGroup(slivers: slivers),
        );
      },
    );
  }
}

class HiddenCategoriesSection extends StatefulWidget {
  const HiddenCategoriesSection({super.key, required this.entries, required this.onUnhide});

  final List<HiddenCategoryEntry> entries;
  final ValueChanged<String> onUnhide;

  @override
  State<HiddenCategoriesSection> createState() => _HiddenCategoriesSectionState();
}

class _HiddenCategoriesSectionState extends State<HiddenCategoriesSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CategorySectionHeader(
          title: tr.hidden_categories,
          count: widget.entries.length,
          open: _open,
          leading: GhIcon(GhIcons.eyeSlash, size: theme.space(3), color: theme.muted.withValues(alpha: 0.6)),
          onToggle: () => setState(() => _open = !_open),
        ),
        if (_open)
          Padding(
            padding: EdgeInsets.only(top: theme.space(2), bottom: theme.space(0.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
                  child: Text(
                    tr.hidden_categories_hint,
                    style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
                  ),
                ),
                for (final entry in widget.entries) _row(context, theme, entry),
              ],
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, GhTheme theme, HiddenCategoryEntry entry) {
    final tr = context.tr.common;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
      decoration: BoxDecoration(
        color: theme.overlay.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        spacing: theme.space(2),
        children: [
          Container(
            width: theme.space(2),
            height: theme.space(2),
            decoration: BoxDecoration(
              color: colorFromHex(entry.category.color),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          Expanded(
            child: Text(
              entry.category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.xs, color: theme.ink),
            ),
          ),
          Text(
            ghTr('hidden_category_projects', count: entry.count),
            style: theme
                .text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7))
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          GhPressable(
            onPressed: () => widget.onUnhide(entry.category.id),
            semanticLabel: tr.unhide_category_aria.args({'name': entry.category.name}),
            borderRadius: radius,
            builder: (context, states) {
              final hover = states.active;
              return GhAnimatedBox(
                color: hover ? theme.raised : theme.raised.withValues(alpha: 0),
                borderRadius: radius,
                border: Border.all(color: hover ? theme.accentDim : theme.line),
                padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.eye, size: theme.space(3), color: hover ? theme.ink : theme.muted),
                    Text(
                      tr.unhide,
                      style: theme.text(size: GhTextSize.x2s, color: hover ? theme.ink : theme.muted),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
