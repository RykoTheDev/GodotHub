import 'package:flutter/material.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../logic/git_graph.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/toast.dart';

class RowGraphPainter extends CustomPainter {
  RowGraphPainter({required this.row, required this.surface});

  final GraphRow row;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < row.cells.length; i++) {
      final cell = row.cells[i];
      if (cell.type == LaneCellType.empty) continue;
      final x = i * laneW + laneW / 2;
      final color = colorFromHex(colorFor(cell.lane!));
      final isDot = cell.type == LaneCellType.dot;
      canvas.drawLine(Offset(x, 0), Offset(x, rowH), line..color = color.withValues(alpha: isDot ? 0.9 : 0.45));
      if (isDot) {
        canvas.drawCircle(Offset(x, rowH / 2), dotR, Paint()..color = color);
        canvas.drawCircle(
          Offset(x, rowH / 2),
          dotR,
          Paint()
            ..color = surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    for (final j in row.joins) {
      final x1 = row.lane * laneW + laneW / 2;
      final x2 = j * laneW + laneW / 2;
      canvas.drawLine(Offset(x1, rowH / 2), Offset(x2, rowH / 2), line..color = colorFromHex(colorFor(j)).withValues(alpha: 0.45));
    }
  }

  @override
  bool shouldRepaint(RowGraphPainter oldDelegate) => oldDelegate.row != row || oldDelegate.surface != surface;
}

class CommitGraph extends StatefulWidget {
  const CommitGraph({super.key, required this.commits, this.remoteUrl, this.onOpenDetails});

  final List<GitLogEntry> commits;
  final String? remoteUrl;
  final ValueChanged<String>? onOpenDetails;

  @override
  State<CommitGraph> createState() => _CommitGraphState();
}

class _CommitGraphState extends State<CommitGraph> {
  late List<GraphRow> _rows = buildGraphRows(widget.commits);

  @override
  void didUpdateWidget(CommitGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.commits, widget.commits)) _rows = buildGraphRows(widget.commits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    if (widget.commits.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
        child: Text(
          ghTr('git:no_commits_found'),
          style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.5)),
        ),
      );
    }
    final remote = widget.remoteUrl;
    final base = remote == null || remote.isEmpty ? null : remote.replaceFirst(RegExp(r'/+$'), '');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final row in _rows) _row(theme, row, base)]),
    );
  }

  Widget _row(GhTheme theme, GraphRow row, String? base) {
    final c = row.commit;
    final url = base != null ? '$base/commit/${c.hash}' : null;
    final open = widget.onOpenDetails;
    final clickable = open != null || url != null;
    final meta = [c.author, c.date].where((part) => part.isNotEmpty).join(' · ');
    return Row(
      key: ValueKey(c.hash),
      mainAxisSize: MainAxisSize.min,
      spacing: theme.space(1.5),
      children: [
        CustomPaint(
          size: Size((row.cells.isEmpty ? 1 : row.cells.length) * laneW, rowH),
          painter: RowGraphPainter(row: row, surface: theme.surface),
        ),
        GhPressable(
          onPressed: !clickable
              ? null
              : () {
                  if (open != null) {
                    open(c.hash);
                  } else {
                    OpenerApi.openUrl(url!).catchError((Object error) => ghToasts.pushToast(GhToastType.error, '$error'));
                  }
                },
          disabledOpacity: null,
          cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
          borderRadius: BorderRadius.circular(theme.radiusMd),
          semanticLabel: c.message,
          builder: (context, states) => GhAnimatedBox(
            height: rowH,
            color: states.active && clickable ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(theme.radiusMd),
            padding: EdgeInsetsDirectional.only(end: theme.space(2)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                Text(
                  shortHash(c.hash),
                  style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, mono: true, color: theme.accentBright),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.xs, color: theme.ink, lineHeight: 1.375),
                      ),
                      if (meta.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: theme.space(0.5)),
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
