import 'package:flutter/widgets.dart';

import '../../design/design.dart';

/// Column breakpoints for card grids, keyed on the width actually available
/// to the grid (not the window), so the sidebar, view padding and split
/// panes are already accounted for. Widths are logical pixels at 100% font
/// scale; a larger font scale moves every breakpoint out so cards never get
/// cramped.
class GhGridBreakpoints {
  const GhGridBreakpoints(this.steps);

  /// `(minimum available width, columns)` pairs in ascending width order.
  final List<(double, int)> steps;

  /// Standard content cards: Asset Store, Asset Library, Templates.
  ///
  /// | Available width | Columns |
  /// |-----------------|---------|
  /// | < 540           | 1       |
  /// | 540 to 819      | 2       |
  /// | 820 to 1099     | 3       |
  /// | 1100 to 1379    | 4       |
  /// | 1380 to 1659    | 5       |
  /// | 1660 and up     | 6       |
  static const cards = GhGridBreakpoints([(0, 1), (540, 2), (820, 3), (1100, 4), (1380, 5), (1660, 6)]);

  /// Text-heavy cards with a large image, such as News: fewer, wider columns.
  ///
  /// | Available width | Columns |
  /// |-----------------|---------|
  /// | < 640           | 1       |
  /// | 640 to 1019     | 2       |
  /// | 1020 to 1399    | 3       |
  /// | 1400 to 1779    | 4       |
  /// | 1780 and up     | 5       |
  static const reading = GhGridBreakpoints([(0, 1), (640, 2), (1020, 3), (1400, 4), (1780, 5)]);

  int columnsFor(double width, {double fontScale = 1}) {
    var columns = 1;
    for (final (min, count) in steps) {
      if (width >= min * fontScale) columns = count;
    }
    return columns;
  }
}

/// A responsive card grid with equal-height rows. Cards stretch to fill each
/// column; a partly filled last row keeps the same column widths.
class GhCardGrid extends StatelessWidget {
  const GhCardGrid({super.key, required this.children, this.breakpoints = GhGridBreakpoints.cards, this.gap = 3})
    : _fillRows = null,
      _fillBuilder = null;

  /// A grid that fills [rows] full rows at the current column count, for
  /// skeleton placeholders that should match the real layout.
  const GhCardGrid.fill({
    super.key,
    required int rows,
    required IndexedWidgetBuilder builder,
    this.breakpoints = GhGridBreakpoints.cards,
    this.gap = 3,
  }) : children = const [],
       _fillRows = rows,
       _fillBuilder = builder;

  final List<Widget> children;
  final GhGridBreakpoints breakpoints;

  /// Gap between cards in spacing units.
  final double gap;
  final int? _fillRows;
  final IndexedWidgetBuilder? _fillBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final spacing = theme.space(gap);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = breakpoints.columnsFor(constraints.maxWidth, fontScale: theme.fontScale);
        final items = _fillBuilder == null ? children : [for (var i = 0; i < columns * _fillRows!; i++) _fillBuilder(context, i)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing,
          children: [
            for (var start = 0; start < items.length; start += columns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: spacing,
                  children: [
                    for (var i = start; i < start + columns; i++) Expanded(child: i < items.length ? items[i] : const SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
