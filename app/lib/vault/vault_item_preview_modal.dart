import 'package:flutter/material.dart';

import '../design/design.dart';
import '../logic/format_bytes.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import 'vault_file_tree.dart';
import 'vault_modal_parts.dart';

class VaultItemPreviewModal extends StatelessWidget {
  const VaultItemPreviewModal({super.key, required this.item, required this.onClose});

  final VaultItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final files = item.files;
    final fileCount = files.where((e) => !e.isDir).length;
    final dirCount = files.where((e) => e.isDir).length;
    final totalSize = files.fold<int>(0, (acc, e) => acc + e.size.toInt());
    final summary = StringBuffer(ghTr('file_count', count: fileCount));
    if (dirCount > 0) summary.write(' · ${ghTr('folder_count', count: dirCount)}');
    if (totalSize > 0) summary.write(' · ${formatBytes(totalSize)}');
    final faint = theme.muted.withValues(alpha: 0.5);
    return GhModalShell(
      icon: GhIcon(GhIcons.briefcase, size: theme.space(5), color: theme.accentBright),
      title: item.name,
      maxWidth: GhModalWidth.lg,
      onClose: onClose,
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.description.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space(3)),
                child: Text(
                  item.description,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                ),
              ),
            if (item.tags.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: theme.space(3)),
                child: Wrap(
                  spacing: theme.space(1.5),
                  runSpacing: theme.space(1.5),
                  children: [for (final tag in item.tags) VaultTagChip(tag, large: true)],
                ),
              ),
            if (files.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.space(12)),
                child: Text(
                  ghTr('vault_item_empty'),
                  textAlign: TextAlign.center,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted),
                ),
              )
            else ...[
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(1), 0, theme.space(1), theme.space(2)),
                child: Row(
                  spacing: theme.space(2),
                  children: [
                    GhIcon(GhIcons.info, size: theme.space(3), color: faint),
                    Flexible(
                      child: Text(
                        summary.toString(),
                        style: theme.text(size: GhTextSize.x3s, mono: true, color: faint),
                      ),
                    ),
                  ],
                ),
              ),
              VaultFileTree(entries: files.map(vaultEntryOf).toList()),
            ],
          ],
        ),
      ),
    );
  }
}
