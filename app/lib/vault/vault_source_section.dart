import 'package:flutter/material.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import 'project_picker.dart';
import 'vault_file_tree.dart';

class VaultTreeBox extends StatelessWidget {
  const VaultTreeBox({super.key, required this.child, this.maxHeightRem = 14, this.padding = 1});

  final Widget child;
  final double maxHeightRem;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: theme.rem(maxHeightRem)),
      decoration: BoxDecoration(
        color: theme.base,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(padding: EdgeInsets.all(theme.space(padding)), child: child),
    );
  }
}

class VaultTreeMessage extends StatelessWidget {
  const VaultTreeMessage(this.text, {super.key, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space(10)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.text(size: GhTextSize.xs, color: danger ? theme.danger : theme.muted),
      ),
    );
  }
}

class VaultSourceSection extends StatefulWidget {
  const VaultSourceSection({
    super.key,
    required this.projects,
    required this.projectId,
    required this.selected,
    required this.index,
    required this.canRemove,
    required this.onProjectChange,
    required this.onToggle,
    required this.onRemove,
  });

  final List<Project> projects;
  final String? projectId;
  final Set<String> selected;
  final int index;
  final bool canRemove;
  final ValueChanged<String> onProjectChange;
  final ValueChanged<String> onToggle;
  final VoidCallback onRemove;

  @override
  State<VaultSourceSection> createState() => _VaultSourceSectionState();
}

class _VaultSourceSectionState extends State<VaultSourceSection> {
  List<VaultTreeEntry> _tree = const [];
  bool _loading = false;
  String? _error;
  String? _loadedPath;
  int _request = 0;

  Project? get _project => widget.projects.where((p) => p.id == widget.projectId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VaultSourceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_project?.path != _loadedPath) _load();
  }

  void _load() {
    final project = _project;
    _loadedPath = project?.path;
    final request = ++_request;
    if (project == null) {
      _tree = const [];
      return;
    }
    _loading = true;
    _error = null;
    ProjectsApi.getFileTree(project.path).then(
      (entries) {
        if (!mounted || request != _request) return;
        setState(() {
          _tree = entries.map(projectEntryOf).toList();
          _loading = false;
        });
      },
      onError: (Object e) {
        if (!mounted || request != _request) return;
        setState(() {
          _error = '$e';
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final project = _project;
    final error = _error;
    return Container(
      padding: EdgeInsets.all(theme.space(3)),
      decoration: BoxDecoration(
        color: theme.overlay.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          Row(
            spacing: theme.space(2),
            children: [
              Text(
                ghTr('vault_source_n', args: {'index': widget.index + 1}).toUpperCase(),
                style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
              ),
              Expanded(
                child: VaultProjectPicker(projects: widget.projects, selectedId: widget.projectId, onSelect: widget.onProjectChange),
              ),
              if (widget.canRemove)
                GhPressable(
                  onPressed: widget.onRemove,
                  semanticLabel: ghTr('vault_remove_source'),
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  builder: (context, states) => GhAnimatedBox(
                    color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(theme.radiusBtn),
                    padding: EdgeInsets.all(theme.space(1.5)),
                    child: GhIcon(
                      GhIcons.trash,
                      size: theme.space(3.5),
                      color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          if (project != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ghTr('vault_select_files_label'),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
                    ),
                    Text(
                      ghTr('vault_selected_count', args: {'count': widget.selected.length}),
                      style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                VaultTreeBox(
                  child: _loading
                      ? VaultTreeMessage(ghTr('loading'))
                      : error != null
                      ? VaultTreeMessage(error, danger: true)
                      : _tree.isEmpty
                      ? VaultTreeMessage(ghTr('vault_project_empty'))
                      : SelectableVaultFileTree(
                          key: ValueKey(project.path),
                          entries: _tree,
                          selected: widget.selected,
                          onToggle: widget.onToggle,
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
