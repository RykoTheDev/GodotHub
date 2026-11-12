import 'package:flutter/material.dart';

import '../api/git.dart';
import '../design/design.dart';
import '../git/diff_body.dart';
import '../logic/git_graph.dart';
import '../src/rust/api/types.dart';
import '../ui/feedback/modal_shell.dart';
import 'diff_viewer_modal.dart';

({String badge, Color color}) commitFileStatus(GhTheme theme, String status) {
  final s = status.isEmpty ? '' : status[0];
  return switch (s) {
    'A' => (badge: 'A', color: theme.mint),
    'D' => (badge: 'D', color: theme.danger),
    'M' || 'T' => (badge: 'M', color: theme.amber),
    'R' => (badge: 'R', color: theme.muted.withValues(alpha: 0.5)),
    _ => (badge: s, color: theme.muted.withValues(alpha: 0.5)),
  };
}

class CommitDetailsModal extends StatefulWidget {
  const CommitDetailsModal({super.key, required this.projectPath, required this.hash, required this.onClose});

  final String projectPath;
  final String hash;
  final VoidCallback onClose;

  @override
  State<CommitDetailsModal> createState() => _CommitDetailsModalState();
}

class _CommitDetailsModalState extends State<CommitDetailsModal> {
  GitCommitDetails? _details;
  List<DiffRow> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    GitApi.showCommit(widget.projectPath, widget.hash).then(
      (details) {
        if (mounted) {
          setState(() {
            _details = details;
            _rows = buildDiffRows(details.diff);
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
    final details = _details;
    final meta = theme.space(3) + theme.space(2.5) + 18;
    final files = details == null || details.files.isEmpty ? 0.0 : theme.space(4) + details.files.length * 26.0;
    final content = _loading || details == null
        ? DiffSkeleton.height
        : files + (_rows.isEmpty ? 100 : _rows.fold<double>(16, (sum, row) => sum + row.height));
    final title = details != null && details.message.isNotEmpty ? details.message : shortHash(widget.hash);
    return GhModalShell(
      icon: GhIcon(GhIcons.gitBranch, size: theme.space(5), color: theme.accentBright),
      title: title,
      maxWidth: GhModalWidth.x3l,
      onClose: widget.onClose,
      bodyHeight: diffModalBodyHeight(context, (details != null ? meta : 0) + content),
      child: CustomScrollView(
        slivers: [
          if (details != null)
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(theme.space(5), theme.space(3), theme.space(5), theme.space(2.5)),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.6))),
                ),
                child: Row(
                  spacing: theme.space(3),
                  children: [
                    Text(
                      shortHash(details.hash),
                      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.accentBright),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: theme.space(1),
                        children: [
                          GhIcon(GhIcons.user, size: theme.space(3), color: theme.muted),
                          Flexible(
                            child: Text(
                              details.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      details.date,
                      style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading || details == null)
            const SliverToBoxAdapter(child: DiffSkeleton())
          else ...[
            if (details.files.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.4))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(0.5),
                    children: [
                      for (final f in details.files)
                        Builder(
                          builder: (context) {
                            final status = commitFileStatus(theme, f.status);
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(1)),
                              child: Row(
                                spacing: theme.space(2),
                                children: [
                                  SizedBox(
                                    width: theme.space(3),
                                    child: Text(
                                      status.badge,
                                      style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, mono: true, color: status.color),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      f.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            if (_rows.isEmpty) const SliverToBoxAdapter(child: DiffEmpty(icon: false)) else DiffBodySliver(rows: _rows),
          ],
        ],
      ),
    );
  }
}
