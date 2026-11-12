import 'package:flutter/material.dart';

import '../design/design.dart';
import '../src/rust/api/types.dart';

const double diffLineHeight = 20;
const double diffHeaderHeight = 28;

@immutable
class DiffRow {
  const DiffRow.header(String this.text) : kind = null, content = null, oldNum = null, newNum = null;

  const DiffRow.line({required String this.kind, required String this.content, this.oldNum, this.newNum}) : text = null;

  final String? text;
  final String? kind;
  final String? content;
  final int? oldNum;
  final int? newNum;

  bool get isHeader => text != null;

  double get height => isHeader ? diffHeaderHeight : diffLineHeight;
}

List<DiffRow> buildDiffRows(GitDiffResult diff) {
  final rows = <DiffRow>[];
  for (final h in diff.hunks) {
    rows.add(DiffRow.header('@@ -${h.oldStart},${h.oldLines} +${h.newStart},${h.newLines} @@'));
    var oldLn = h.oldStart;
    var newLn = h.newStart;
    for (final l in h.lines) {
      final isAdd = l.kind == 'add';
      final isDel = l.kind == 'delete';
      rows.add(DiffRow.line(kind: l.kind, content: l.content, oldNum: isAdd ? null : oldLn, newNum: isDel ? null : newLn));
      if (isDel) {
        oldLn += 1;
      } else if (isAdd) {
        newLn += 1;
      } else {
        oldLn += 1;
        newLn += 1;
      }
    }
  }
  return rows;
}

({int adds, int dels}) diffCounts(GitDiffResult diff) {
  var adds = 0;
  var dels = 0;
  for (final h in diff.hunks) {
    for (final l in h.lines) {
      if (l.kind == 'add') adds++;
      if (l.kind == 'delete') dels++;
    }
  }
  return (adds: adds, dels: dels);
}

class DiffRowView extends StatelessWidget {
  const DiffRowView({super.key, required this.row});

  final DiffRow row;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    if (row.isHeader) {
      return Container(
        height: diffHeaderHeight,
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
        decoration: BoxDecoration(
          color: theme.accent.withValues(alpha: 0.05),
          border: Border.symmetric(horizontal: BorderSide(color: theme.accent.withValues(alpha: 0.1))),
        ),
        child: Text(
          row.text!,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, mono: true, color: theme.accentBright),
        ),
      );
    }
    final isAdd = row.kind == 'add';
    final isDel = row.kind == 'delete';
    final gutter = theme.text(size: GhTextSize.xs, mono: true, color: theme.muted.withValues(alpha: 0.4), lineHeight: 20 / 12);
    Widget number(int? value) => SizedBox(
      width: 40,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: theme.space(3)),
        child: Text(value?.toString() ?? '', textAlign: TextAlign.end, maxLines: 1, style: gutter),
      ),
    );
    return Container(
      height: diffLineHeight,
      color: isAdd
          ? theme.mint.withValues(alpha: 0.05)
          : isDel
          ? theme.danger.withValues(alpha: 0.05)
          : null,
      padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(child: number(row.oldNum)),
          ExcludeSemantics(child: number(row.newNum)),
          SizedBox(
            width: 16,
            child: Text(
              isAdd
                  ? '+'
                  : isDel
                  ? '-'
                  : ' ',
              style: gutter.copyWith(
                color: isAdd
                    ? theme.mint
                    : isDel
                    ? theme.danger
                    : theme.muted.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.content!,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: gutter.copyWith(color: theme.ink.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class DiffBodySliver extends StatelessWidget {
  const DiffBodySliver({super.key, required this.rows});

  final List<DiffRow> rows;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverVariedExtentList.builder(
        itemCount: rows.length,
        itemExtentBuilder: (index, _) => index < rows.length ? rows[index].height : null,
        itemBuilder: (context, index) => DiffRowView(row: rows[index]),
      ),
    );
  }
}
