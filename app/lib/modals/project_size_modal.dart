import 'package:flutter/material.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../logic/project_sort.dart' show stableSorted;
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/modal_kit.dart';

const _folderGlyph = FaIconData(
  'hero',
  'folder-solid',
  20,
  20,
  'M2 4.5A2.5 2.5 0 0 1 4.5 2h2.879a1.5 1.5 0 0 1 1.06.44l1.122 1.12A1.5 1.5 0 0 0 10.62 4H15.5A2.5 2.5 0 0 1 18 6.5v.5H2v-2.5ZM2 8.5V15a2.5 2.5 0 0 0 2.5 2.5h11A2.5 2.5 0 0 0 18 15V8.5H2Z',
);

const _fileGlyph = FaIconData(
  'hero',
  'document-solid',
  20,
  20,
  'M4.5 2A1.5 1.5 0 0 0 3 3.5v13A1.5 1.5 0 0 0 4.5 18h11a1.5 1.5 0 0 0 1.5-1.5V6.621a1.5 1.5 0 0 0-.44-1.06l-3.12-3.122A1.5 1.5 0 0 0 12.378 2H4.5Z',
);

String formatTreeSize(int bytes) {
  if (bytes == 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

class SizeTreeNode {
  SizeTreeNode({required this.name, required this.path, required this.isDir, required this.size});

  final String name;
  final String path;
  final bool isDir;
  int size;
  List<SizeTreeNode> children = [];
}

List<SizeTreeNode> buildSizeTree(List<ProjectFileEntry> entries) {
  final root = <SizeTreeNode>[];
  final map = <String, SizeTreeNode>{};
  for (final e in entries) {
    final parts = e.path.split('/').where((p) => p.isNotEmpty).toList();
    var current = root;
    var accumulated = '';
    for (var i = 0; i < parts.length; i++) {
      accumulated = accumulated.isEmpty ? parts[i] : '$accumulated/${parts[i]}';
      final isLast = i == parts.length - 1;
      var node = map[accumulated];
      if (node == null) {
        node = SizeTreeNode(
          name: parts[i],
          path: accumulated + (e.isDir && isLast ? '/' : ''),
          isDir: isLast ? e.isDir : true,
          size: isLast ? e.size.toInt() : 0,
        );
        map[accumulated] = node;
        current.add(node);
      }
      current = node.children;
    }
  }
  int calc(SizeTreeNode node) {
    if (!node.isDir) return node.size;
    var total = 0;
    for (final child in node.children) {
      total += calc(child);
    }
    node.size = total;
    return total;
  }

  void sort(List<SizeTreeNode> nodes, void Function(List<SizeTreeNode>) assign) {
    final sorted = stableSorted(nodes, (a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return b.size - a.size;
    });
    assign(sorted);
    for (final n in sorted) {
      if (n.children.isNotEmpty) sort(n.children, (list) => n.children = list);
    }
  }

  for (final node in root) {
    calc(node);
  }
  var result = root;
  sort(root, (list) => result = list);
  return result;
}

class ProjectSizeModal extends StatefulWidget {
  const ProjectSizeModal({super.key, required this.projectPath, required this.onClose});

  final String projectPath;
  final VoidCallback onClose;

  @override
  State<ProjectSizeModal> createState() => _ProjectSizeModalState();
}

class _ProjectSizeModalState extends State<ProjectSizeModal> {
  List<SizeTreeNode> _tree = const [];
  bool _empty = true;
  bool _loading = true;
  String? _error;
  Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    ProjectsApi.getFileTree(widget.projectPath).then(
      (entries) {
        if (!mounted) return;
        setState(() {
          _tree = buildSizeTree(entries);
          _empty = entries.isEmpty;
          _collapsed = {for (final e in entries) if (e.isDir) e.path};
          _loading = false;
        });
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _error = '$e';
            _loading = false;
          });
        }
      },
    );
  }

  void _toggle(String path) => setState(() {
    if (!_collapsed.remove(path)) _collapsed.add(path);
  });

  List<Widget> _rows(GhTheme theme, List<SizeTreeNode> nodes, int depth) {
    final tr = context.tr.common;
    final rows = <Widget>[];
    for (final node in nodes) {
      final collapsed = _collapsed.contains(node.path);
      final hasChildren = node.children.isNotEmpty;
      final color = depth == 0 ? theme.ink : theme.muted;
      rows.add(
        _HoverRow(
          key: ValueKey(node.path),
          padding: EdgeInsetsDirectional.only(start: depth * 16.0 + 8, end: theme.space(2), top: theme.space(1), bottom: theme.space(1)),
          child: Row(
            spacing: theme.space(2),
            children: [
              if (hasChildren)
                GhPressable(
                  onPressed: () => _toggle(node.path),
                  semanticLabel: collapsed ? tr.expand : tr.collapse,
                  builder: (context, states) => Padding(
                    padding: EdgeInsets.all(theme.space(0.5)),
                    child: Transform.flip(
                      flipX: collapsed && Directionality.of(context) == TextDirection.rtl,
                      child: GhIcon(
                        collapsed ? GhIcons.chevronRight : GhIcons.chevronDown,
                        size: theme.space(3),
                        color: states.active ? theme.ink : theme.muted,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(width: theme.space(4)),
              GhIcon(
                node.isDir ? _folderGlyph : _fileGlyph,
                size: theme.space(3.5),
                color: node.isDir ? theme.accentBright.withValues(alpha: 0.7) : theme.muted.withValues(alpha: 0.6),
              ),
              Expanded(
                child: Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.xs, weight: depth == 0 ? GhWeight.medium : GhWeight.normal, color: color),
                ),
              ),
              if (node.size > 0)
                Text(
                  formatTreeSize(node.size),
                  style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ),
      );
      if (hasChildren && !collapsed) rows.addAll(_rows(theme, node.children, depth + 1));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    Widget centered(Widget child) => Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space(12)),
      child: Center(child: child),
    );
    final Widget body;
    if (_loading) {
      body = centered(
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            GhSpinnerIcon(size: 4, color: theme.muted),
            Text(tr.project_size_scanning, style: theme.text(size: GhTextSize.sm, color: theme.muted)),
          ],
        ),
      );
    } else if (_error != null) {
      body = centered(Text(_error!, style: theme.text(size: GhTextSize.sm, color: theme.danger)));
    } else if (_empty) {
      body = centered(Text(tr.project_size_empty, style: theme.text(size: GhTextSize.sm, color: theme.muted)));
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _rows(theme, _tree, 0));
    }
    return GhModalShell(
      icon: GhIcon(GhIcons.hardDrive, size: theme.space(5), color: theme.accentBright),
      title: tr.project_size,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      child: Padding(padding: EdgeInsets.all(theme.space(6)), child: body),
    );
  }
}

class _HoverRow extends StatefulWidget {
  const _HoverRow({super.key, required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GhAnimatedBox(
        color: _hovered ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}
