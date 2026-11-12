import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api/templates.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';

const _folderSvg =
    '<svg viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M2 4.5A2.5 2.5 0 0 1 4.5 2h2.879a1.5 1.5 0 0 1 1.06.44l1.122 1.12A1.5 1.5 0 0 0 10.62 4H15.5A2.5 2.5 0 0 1 18 6.5v.5H2v-2.5Z"/><path d="M2 8.5V15a2.5 2.5 0 0 0 2.5 2.5h11A2.5 2.5 0 0 0 18 15V8.5H2Z"/></svg>';
const _fileSvg =
    '<svg viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M4.5 2A1.5 1.5 0 0 0 3 3.5v13A1.5 1.5 0 0 0 4.5 18h11a1.5 1.5 0 0 0 1.5-1.5V6.621a1.5 1.5 0 0 0-.44-1.06l-3.12-3.122A1.5 1.5 0 0 0 12.378 2H4.5Z"/></svg>';

String templateFileSize(int bytes) {
  if (bytes == 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class TemplateTreeNode {
  TemplateTreeNode({required this.name, required this.path, required this.isDir, required this.size});

  final String name;
  final String path;
  final bool isDir;
  final int size;
  final List<TemplateTreeNode> children = [];
}

List<TemplateTreeNode> buildTemplateTree(List<TemplateFileEntry> entries) {
  final root = <TemplateTreeNode>[];
  final map = <String, TemplateTreeNode>{};
  for (final e in entries) {
    final parts = e.path.split('/').where((p) => p.isNotEmpty).toList();
    var current = root;
    var accumulated = '';
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      accumulated = accumulated.isEmpty ? part : '$accumulated/$part';
      final isLast = i == parts.length - 1;
      var node = map[accumulated];
      if (node == null) {
        node = TemplateTreeNode(
          name: part,
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
  return root;
}

class TemplatePreviewModal extends StatefulWidget {
  const TemplatePreviewModal({super.key, required this.template, required this.onClose});

  final ProjectTemplate template;
  final VoidCallback onClose;

  @override
  State<TemplatePreviewModal> createState() => _TemplatePreviewModalState();
}

class _TemplatePreviewModalState extends State<TemplatePreviewModal> {
  List<TemplateFileEntry> _entries = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    TemplatesApi.getPreview(widget.template.id).then(
      (entries) {
        if (mounted) {
          setState(() {
            _entries = entries;
            _loading = false;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final description = widget.template.description;
    final fileCount = _entries.where((e) => !e.isDir).length;
    final dirCount = _entries.where((e) => e.isDir).length;
    final totalSize = _entries.fold<int>(0, (acc, e) => acc + e.size.toInt());
    Widget centered(String text, Color color) => Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space(12)),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: theme.text(size: GhTextSize.sm, color: color)),
      ),
    );
    final error = _error;
    return GhModalShell(
      icon: GhIcon(GhIcons.copy, size: theme.space(5), color: theme.accentBright),
      title: widget.template.name,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (description.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space(3)),
                child: Text(description, style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625)),
              ),
            if (_loading)
              centered(ghTr('loading'), theme.muted)
            else if (error != null)
              centered(error, theme.danger)
            else if (_entries.isEmpty)
              centered(ghTr('template_empty'), theme.muted)
            else ...[
              Padding(
                padding: EdgeInsetsDirectional.only(start: theme.space(1), end: theme.space(1), bottom: theme.space(2)),
                child: Row(
                  spacing: theme.space(2),
                  children: [
                    GhIcon(GhIcons.info, size: theme.space(3), color: theme.muted.withValues(alpha: 0.5)),
                    Flexible(
                      child: Text(
                        [
                          ghTr('file_count', count: fileCount),
                          if (dirCount > 0) ghTr('folder_count', count: dirCount),
                          if (totalSize > 0) templateFileSize(totalSize),
                        ].join(' · '),
                        style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              TemplateFileTree(entries: _entries),
            ],
          ],
        ),
      ),
    );
  }
}

class TemplateFileTree extends StatefulWidget {
  const TemplateFileTree({super.key, required this.entries});

  final List<TemplateFileEntry> entries;

  @override
  State<TemplateFileTree> createState() => _TemplateFileTreeState();
}

class _TemplateFileTreeState extends State<TemplateFileTree> {
  late final Set<String> _collapsed = {
    for (final e in widget.entries)
      if (e.isDir) e.path,
  };
  late final List<TemplateTreeNode> _root = buildTemplateTree(widget.entries);

  void _toggle(String path) => setState(() {
    if (!_collapsed.remove(path)) _collapsed.add(path);
  });

  List<Widget> _node(GhTheme theme, TemplateTreeNode node, int depth) {
    final isCollapsed = _collapsed.contains(node.path);
    final hasChildren = node.children.isNotEmpty;
    final color = depth == 0 ? theme.ink : theme.muted;
    final iconSize = theme.space(3.5);
    return [
      _TreeRow(
        key: ValueKey(node.path),
        depth: depth,
        child: Row(
          spacing: theme.space(2),
          children: [
            if (hasChildren)
              GhPressable(
                onPressed: () => _toggle(node.path),
                semanticLabel: isCollapsed ? ghTr('expand') : ghTr('collapse'),
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                builder: (context, states) => Padding(
                  padding: EdgeInsets.all(theme.space(0.5)),
                  child: isCollapsed
                      ? Transform.flip(
                          flipX: Directionality.of(context) == TextDirection.rtl,
                          child: GhIcon(GhIcons.chevronRight, size: theme.space(3), color: states.active ? theme.ink : theme.muted),
                        )
                      : GhIcon(GhIcons.chevronDown, size: theme.space(3), color: states.active ? theme.ink : theme.muted),
                ),
              )
            else
              SizedBox(width: theme.space(4)),
            SvgPicture.string(
              node.isDir ? _folderSvg : _fileSvg,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                node.isDir ? theme.accentBright.withValues(alpha: 0.7) : theme.muted.withValues(alpha: 0.6),
                BlendMode.srcIn,
              ),
            ),
            Expanded(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.xs, weight: depth == 0 ? GhWeight.medium : GhWeight.normal, color: color),
              ),
            ),
            if (!node.isDir && node.size > 0)
              Text(
                templateFileSize(node.size),
                style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
      if (hasChildren && !isCollapsed)
        for (final child in node.children) ..._node(theme, child, depth + 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final node in _root) ..._node(theme, node, 0)],
    );
  }
}

class _TreeRow extends StatefulWidget {
  const _TreeRow({super.key, required this.depth, required this.child});

  final int depth;
  final Widget child;

  @override
  State<_TreeRow> createState() => _TreeRowState();
}

class _TreeRowState extends State<_TreeRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GhAnimatedBox(
        color: _hover ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        padding: EdgeInsetsDirectional.only(
          start: widget.depth * 16 + theme.space(2),
          end: theme.space(2),
          top: theme.space(1),
          bottom: theme.space(1),
        ),
        child: widget.child,
      ),
    );
  }
}
