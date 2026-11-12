import 'package:flutter/material.dart';

import '../api/vault.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import 'vault_file_tree.dart';
import 'vault_modal_parts.dart';
import 'vault_source_section.dart';

class AddVaultItemModal extends StatefulWidget {
  const AddVaultItemModal({super.key, required this.item, required this.projects, required this.onClose});

  final VaultItem item;
  final List<Project> projects;
  final VoidCallback onClose;

  @override
  State<AddVaultItemModal> createState() => _AddVaultItemModalState();
}

class _AddVaultItemModalState extends State<AddVaultItemModal> {
  final Set<String> _selected = {};
  bool _busy = false;
  List<VaultProjectImportResult>? _conflicts;

  String _projectName(String id) => widget.projects.where((p) => p.id == id).firstOrNull?.name ?? id;

  void _finish(List<VaultProjectImportResult> results) {
    final count = results.where((r) => !r.skipped).length;
    ghToasts.pushToast(GhToastType.success, ghTr('vault_added_to_projects_toast', count: count));
    widget.onClose();
  }

  Future<void> _run(bool overwrite) async {
    final ids = _selected.toList();
    if (ids.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final results = await VaultApi.addToProjects(widget.item.id, ids, overwrite);
      if (!overwrite) {
        if (results.any((r) => r.conflicts.isNotEmpty)) {
          if (mounted) setState(() => _conflicts = results);
          return;
        }
        _finish(await VaultApi.addToProjects(widget.item.id, ids, true));
        return;
      }
      _finish(results);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _conflictView(GhTheme theme, List<VaultProjectImportResult> conflicts) {
    final projects = conflicts.where((r) => r.conflicts.isNotEmpty).toList();
    final total = projects.fold<int>(0, (sum, r) => sum + r.conflicts.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        Container(
          padding: EdgeInsets.all(theme.space(3)),
          decoration: BoxDecoration(
            color: theme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(2.5),
            children: [
              Padding(
                padding: EdgeInsets.only(top: theme.space(0.5)),
                child: GhIcon(GhIcons.alertTriangle, size: theme.space(4), color: theme.danger),
              ),
              Expanded(
                child: Text(
                  ghTr('vault_conflict_summary_desc', count: total),
                  style: theme.text(size: GhTextSize.xs, color: theme.ink, lineHeight: 1.625),
                ),
              ),
            ],
          ),
        ),
        VaultTreeBox(
          padding: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              for (final result in projects)
                Column(
                  key: ValueKey(result.projectId),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(0.5),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
                      child: Text(
                        _projectName(result.projectId),
                        style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.ink),
                      ),
                    ),
                    for (final path in result.conflicts)
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(theme.space(3), theme.space(0.5), theme.space(1), theme.space(0.5)),
                        child: Text(
                          path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _projectList(GhTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ghTr('vault_target_projects_label'),
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
            ),
            Text(
              ghTr('vault_selected_count', args: {'count': _selected.length}),
              style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
            ),
          ],
        ),
        VaultTreeBox(
          maxHeightRem: 16,
          child: widget.projects.isEmpty
              ? VaultTreeMessage(ghTr('vault_select_project'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in widget.projects)
                      Builder(
                        key: ValueKey(p.id),
                        builder: (context) {
                          final checked = _selected.contains(p.id);
                          final radius = BorderRadius.circular(theme.radiusItem);
                          return GhPressable(
                            onPressed: () => setState(() {
                              if (!_selected.remove(p.id)) _selected.add(p.id);
                            }),
                            toggled: checked,
                            borderRadius: radius,
                            builder: (context, states) => GhAnimatedBox(
                              color: states.active ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
                              borderRadius: radius,
                              padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
                              child: Row(
                                spacing: theme.space(2),
                                children: [
                                  VaultCheckMark(checked: checked),
                                  GhIcon(GhIcons.folder, size: theme.space(3.5), color: theme.muted),
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.text(size: GhTextSize.xs, color: checked ? theme.ink : theme.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final conflicts = _conflicts;
    return GhModalShell(
      icon: GhIcon(GhIcons.folderPlus, size: theme.space(4), color: theme.ink),
      title: ghTr('vault_add_title'),
      maxWidth: GhModalWidth.md,
      onClose: widget.onClose,
      footer: conflicts != null
          ? [
              VaultCancelButton(onPressed: () => setState(() => _conflicts = null)),
              Expanded(
                child: VaultPrimaryButton(
                  label: _busy ? ghTr('vault_adding') : ghTr('vault_overwrite_btn'),
                  danger: true,
                  onPressed: _busy ? null : () => _run(true),
                ),
              ),
            ]
          : [
              VaultCancelButton(onPressed: widget.onClose),
              Expanded(
                child: VaultPrimaryButton(
                  label: _busy ? ghTr('vault_adding') : ghTr('vault_add_btn'),
                  onPressed: _selected.isEmpty || _busy ? null : () => _run(false),
                ),
              ),
            ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: conflicts != null ? _conflictView(theme, conflicts) : _projectList(theme),
      ),
    );
  }
}
