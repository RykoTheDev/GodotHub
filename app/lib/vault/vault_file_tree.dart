import 'package:flutter/material.dart';

import '../design/design.dart';
import '../modals/project_size_modal.dart' show formatTreeSize;
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

typedef VaultTreeEntry = ({String path, bool isDir, int size});

VaultTreeEntry vaultEntryOf(VaultFileEntry e) => (path: e.path, isDir: e.isDir, size: e.size.toInt());

VaultTreeEntry projectEntryOf(ProjectFileEntry e) => (path: e.path, isDir: e.isDir, size: e.size.toInt());

class VaultTreeNode {
  VaultTreeNode({required this.name, required this.path, required this.rel, required this.isDir, required this.size});

  final String name;
  final String path;
  final String rel;
  final bool isDir;
  final int size;
  final List<VaultTreeNode> children = [];
}

List<VaultTreeNode> buildVaultTree(List<VaultTreeEntry> entries) {
  final root = <VaultTreeNode>[];
  final map = <String, VaultTreeNode>{};
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
        node = VaultTreeNode(
          name: part,
          path: accumulated + (e.isDir && isLast ? '/' : ''),
          rel: accumulated,
          isDir: isLast ? e.isDir : true,
          size: isLast ? e.size : 0,
        );
        map[accumulated] = node;
        current.add(node);
      }
      current = node.children;
    }
  }
  return root;
}

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

class VaultCheckMark extends StatelessWidget {
  const VaultCheckMark({super.key, required this.checked, this.hovered = false});

  final bool checked;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.space(4);
    return GhAnimatedBox(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: checked ? theme.accent : theme.base,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: checked
            ? theme.accent
            : hovered
            ? theme.accentDim
            : theme.outline.withValues(alpha: 0.6),
      ),
      child: checked ? GhIcon(GhIcons.check, size: theme.space(3), color: Colors.white) : null,
    );
  }
}

class _TreeRow extends StatefulWidget {
  const _TreeRow({required this.depth, required this.children});

  final int depth;
  final List<Widget> children;

  @override
  State<_TreeRow> createState() => _TreeRowState();
}

class _TreeRowState extends State<_TreeRow> {
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
        padding: EdgeInsetsDirectional.fromSTEB(
          widget.depth * theme.rem(1) + theme.rem(0.5),
          theme.space(1),
          theme.space(2),
          theme.space(1),
        ),
        child: Row(spacing: theme.space(2), children: widget.children),
      ),
    );
  }
}

Widget _chevron(BuildContext context, {required bool collapsed, required VoidCallback onPressed}) {
  final theme = GhTheme.of(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return GhPressable(
    onPressed: onPressed,
    semanticLabel: collapsed ? ghTr('expand') : ghTr('collapse'),
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    builder: (context, states) => Padding(
      padding: EdgeInsets.all(theme.space(0.5)),
      child: Transform.flip(
        flipX: collapsed && rtl,
        child: GhIcon(
          collapsed ? GhIcons.chevronRight : GhIcons.chevronDown,
          size: theme.space(3),
          color: states.active ? theme.ink : theme.muted,
        ),
      ),
    ),
  );
}

Widget _glyph(GhTheme theme, bool isDir) => GhIcon(
  isDir ? _folderGlyph : _fileGlyph,
  size: theme.space(3.5),
  color: isDir ? theme.accentBright.withValues(alpha: 0.7) : theme.muted.withValues(alpha: 0.6),
);

Widget _size(GhTheme theme, VaultTreeNode node) => Text(
  formatTreeSize(node.size),
  style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
);

Set<String> _initialCollapsed(List<VaultTreeEntry> entries) => {
  for (final e in entries)
    if (e.isDir) e.path,
};

class VaultFileTree extends StatefulWidget {
  const VaultFileTree({super.key, required this.entries});

  final List<VaultTreeEntry> entries;

  @override
  State<VaultFileTree> createState() => _VaultFileTreeState();
}

class _VaultFileTreeState extends State<VaultFileTree> {
  late final Set<String> _collapsed = _initialCollapsed(widget.entries);

  void _toggle(String path) => setState(() {
    if (!_collapsed.remove(path)) _collapsed.add(path);
  });

  Widget _node(BuildContext context, VaultTreeNode node, int depth) {
    final theme = GhTheme.of(context);
    final collapsed = _collapsed.contains(node.path);
    final hasChildren = node.children.isNotEmpty;
    final style = depth == 0
        ? theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)
        : theme.text(size: GhTextSize.xs, color: theme.muted);
    return Column(
      key: ValueKey(node.path),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TreeRow(
          depth: depth,
          children: [
            if (hasChildren)
              _chevron(context, collapsed: collapsed, onPressed: () => _toggle(node.path))
            else
              SizedBox(width: theme.space(4)),
            _glyph(theme, node.isDir),
            Expanded(
              child: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
            if (!node.isDir && node.size > 0) _size(theme, node),
          ],
        ),
        if (hasChildren && !collapsed)
          for (final child in node.children) _node(context, child, depth + 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final root = buildVaultTree(widget.entries);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final n in root) _node(context, n, 0)]);
  }
}

class SelectableVaultFileTree extends StatefulWidget {
  const SelectableVaultFileTree({super.key, required this.entries, required this.selected, required this.onToggle});

  final List<VaultTreeEntry> entries;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  State<SelectableVaultFileTree> createState() => _SelectableVaultFileTreeState();
}

class _SelectableVaultFileTreeState extends State<SelectableVaultFileTree> {
  late final Set<String> _collapsed = _initialCollapsed(widget.entries);

  void _toggleCollapse(String path) => setState(() {
    if (!_collapsed.remove(path)) _collapsed.add(path);
  });

  bool _covered(String rel) {
    for (final sel in widget.selected) {
      if (rel == sel) continue;
      if (rel.startsWith('$sel/')) return true;
    }
    return false;
  }

  Widget _node(BuildContext context, VaultTreeNode node, int depth) {
    final theme = GhTheme.of(context);
    final collapsed = _collapsed.contains(node.path);
    final hasChildren = node.children.isNotEmpty;
    final covered = _covered(node.rel);
    final checked = covered || widget.selected.contains(node.rel);
    final onToggle = covered ? null : () => widget.onToggle(node.rel);
    return Column(
      key: ValueKey(node.path),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TreeRow(
          depth: depth,
          children: [
            if (hasChildren)
              _chevron(context, collapsed: collapsed, onPressed: () => _toggleCollapse(node.path))
            else
              SizedBox(width: theme.space(4)),
            GhPressable(
              onPressed: onToggle,
              toggled: checked,
              semanticLabel: node.name,
              disabledOpacity: 0.6,
              disabledCursor: SystemMouseCursors.forbidden,
              borderRadius: BorderRadius.circular(5),
              ripple: false,
              builder: (context, states) => VaultCheckMark(checked: checked, hovered: states.active),
            ),
            _glyph(theme, node.isDir),
            Expanded(
              child: Opacity(
                opacity: covered ? 0.6 : 1,
                child: MouseRegion(
                  cursor: covered ? MouseCursor.defer : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.xs, color: checked ? theme.ink : theme.muted),
                    ),
                  ),
                ),
              ),
            ),
            if (!node.isDir && node.size > 0) _size(theme, node),
          ],
        ),
        if (hasChildren && !collapsed)
          for (final child in node.children) _node(context, child, depth + 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final root = buildVaultTree(widget.entries);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final n in root) _node(context, n, 0)]);
  }
}
