import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../git/diff_body.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';

double diffModalBodyHeight(BuildContext context, double content) {
  final limit = math.max(160.0, MediaQuery.sizeOf(context).height * 0.88 - 96);
  return math.min(content, limit);
}

class DiffSkeleton extends StatelessWidget {
  const DiffSkeleton({super.key});

  static const double height = 14 * 16 + 13 * 6 + 40;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(theme.space(5)),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(1.5),
          children: [
            for (var i = 0; i < 14; i++)
              Container(
                width: constraints.maxWidth * (40 + ((i * 37) % 55)) / 100,
                height: theme.space(4),
                decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.rem(0.25))),
              ),
          ],
        ),
      ),
    );
  }
}

class DiffEmpty extends StatelessWidget {
  const DiffEmpty({super.key, this.icon = true});

  final bool icon;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final color = theme.muted.withValues(alpha: 0.6);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(icon ? 10 : 8)),
      child: Column(
        spacing: theme.space(2),
        children: [
          if (icon)
            Opacity(
              opacity: 0.4,
              child: GhIcon(GhIcons.code, size: theme.space(6), color: color),
            ),
          Text(
            ghTr('git:diff_no_diff'),
            style: theme.text(size: icon ? GhTextSize.sm : GhTextSize.xs, color: color),
          ),
        ],
      ),
    );
  }
}

class DiffViewerModal extends StatefulWidget {
  const DiffViewerModal({super.key, required this.title, required this.fetchDiff, required this.onClose});

  final String title;
  final Future<GitDiffResult> Function() fetchDiff;
  final VoidCallback onClose;

  @override
  State<DiffViewerModal> createState() => _DiffViewerModalState();
}

class _DiffViewerModalState extends State<DiffViewerModal> {
  GitDiffResult? _diff;
  List<DiffRow> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.fetchDiff().then(
      (diff) {
        if (mounted) {
          setState(() {
            _diff = diff;
            _rows = buildDiffRows(diff);
            _loading = false;
          });
        }
      },
      onError: (Object _) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final diff = _diff;
    final empty = diff == null || diff.hunks.isEmpty;
    final counts = diff == null ? (adds: 0, dels: 0) : diffCounts(diff);
    final bar = theme.space(3) + theme.space(2.5) + 18;
    final content = _loading
        ? DiffSkeleton.height
        : empty
        ? 140.0
        : _rows.fold<double>(16, (sum, row) => sum + row.height);
    return GhModalShell(
      icon: GhIcon(GhIcons.code, size: theme.space(5), color: theme.accentBright),
      title: widget.title,
      maxWidth: GhModalWidth.x3l,
      onClose: widget.onClose,
      bodyHeight: diffModalBodyHeight(context, bar + content),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: bar,
              padding: EdgeInsets.fromLTRB(theme.space(5), theme.space(3), theme.space(5), theme.space(2.5)),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.6))),
              ),
              child: Row(
                spacing: theme.space(2),
                children: [
                  if (!_loading && !empty) ...[
                    Text(
                      '+${counts.adds}',
                      style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, mono: true, color: theme.mint),
                    ),
                    Text(
                      '-${counts.dels}',
                      style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, mono: true, color: theme.danger),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: DiffSkeleton())
          else if (empty)
            const SliverToBoxAdapter(child: DiffEmpty())
          else
            DiffBodySliver(rows: _rows),
        ],
      ),
    );
  }
}
