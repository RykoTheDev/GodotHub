import 'package:flutter/material.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../logic/project_sort.dart' show stableSorted;
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';

class BulkTagModal extends StatefulWidget {
  const BulkTagModal({super.key, required this.projects, required this.onClose, required this.onApplied, this.saveTags});

  final List<Project> projects;
  final VoidCallback onClose;
  final VoidCallback onApplied;
  final Future<Project> Function(String id, String path, List<String> tags)? saveTags;

  @override
  State<BulkTagModal> createState() => _BulkTagModalState();
}

class _BulkTagModalState extends State<BulkTagModal> {
  final TextEditingController _input = TextEditingController();
  late List<Project> _projects = widget.projects;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  List<(String, int)> get _allTags {
    final counts = <String, int>{};
    for (final p in _projects) {
      for (final tag in p.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return stableSorted([for (final e in counts.entries) (e.key, e.value)], (a, b) => b.$2.compareTo(a.$2));
  }

  Future<void> _apply(List<String> Function(List<String> tags) fn) async {
    final save = widget.saveTags ?? ProjectsApi.saveTags;
    final next = <Project>[];
    for (final p in _projects) {
      try {
        next.add(await save(p.id, p.path, fn(p.tags)));
      } catch (_) {
        next.add(p);
      }
    }
    if (mounted) setState(() => _projects = next);
    widget.onApplied();
  }

  Future<void> _addTag() async {
    final tag = _input.text.trim();
    if (tag.isEmpty) return;
    _input.clear();
    await _apply((tags) => tags.contains(tag) ? tags : [...tags, tag]);
    ghToasts.pushToast(GhToastType.success, ghTr('tags_added_to_selection', count: _projects.length));
  }

  Future<void> _removeTag(String tag) async {
    await _apply((tags) => [for (final t in tags) if (t != tag) t]);
    ghToasts.pushToast(GhToastType.success, ghTr('tags_removed_from_selection', count: _projects.length));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final tags = _allTags;
    final enabled = _input.text.trim().isNotEmpty;
    final addRadius = BorderRadius.circular(theme.radiusItem);
    return GhModalShell(
      icon: GhIcon(GhIcons.tags, size: theme.space(5), color: theme.ink),
      title: tr.bulk_tags_title,
      maxWidth: GhModalWidth.md,
      onClose: widget.onClose,
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Row(
              spacing: theme.space(2),
              children: [
                Expanded(
                  child: GhTextInput(
                    controller: _input,
                    placeholder: tr.tag_input_placeholder,
                    onSubmitted: (_) => _addTag(),
                    size: GhTextSize.xs,
                    background: theme.base,
                    focusBorderColor: theme.accentDim,
                    placeholderColor: theme.muted,
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                  ),
                ),
                GhPressable(
                  onPressed: enabled ? _addTag : null,
                  borderRadius: addRadius,
                  builder: (context, states) => GhAnimatedBox(
                    color: theme.accent.withValues(alpha: states.active ? 0.25 : 0.15),
                    borderRadius: addRadius,
                    border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1.5),
                      children: [
                        GhIcon(GhIcons.plus, size: theme.space(3), color: theme.accentBright),
                        Text(tr.add_tag, style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.accentBright)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (tags.isEmpty)
              Text(tr.no_common_tags, style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.5)))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(1),
                children: [
                  for (final (tag, count) in tags)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                      decoration: BoxDecoration(
                        color: theme.raised,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        spacing: theme.space(2),
                        children: [
                          Expanded(
                            child: Text(
                              tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                            ),
                          ),
                          Text(
                            '$count/${_projects.length}',
                            style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
                          ),
                          GhPressable(
                            onPressed: () => _removeTag(tag),
                            semanticLabel: tr.remove_tag.args({'tag': tag}),
                            borderRadius: BorderRadius.circular(theme.rem(0.25)),
                            builder: (context, states) => GhAnimatedBox(
                              color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
                              borderRadius: BorderRadius.circular(theme.rem(0.25)),
                              padding: EdgeInsets.all(theme.space(1)),
                              child: GhIcon(
                                GhIcons.x,
                                size: theme.space(3),
                                color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
