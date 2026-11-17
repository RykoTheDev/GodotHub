import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';

/// Shown on a project card when its `project.godot` could not be read during
/// the last refresh, typically because the project lives on an unplugged
/// drive or an offline network share. The library entry is kept; removing it
/// is always the user's explicit choice.
class ProjectMissingNotice extends StatelessWidget {
  const ProjectMissingNotice({super.key, required this.onRemove, this.compact = false});

  final VoidCallback? onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final remove = onRemove == null
        ? null
        : GhButton(
            label: tr.project_card_remove_library,
            variant: GhButtonVariant.ghost,
            size: GhTextSize.x2s,
            onPressed: onRemove,
            tooltip: compact ? tr.project_missing_desc : null,
          );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(theme.space(compact ? 2 : 2.5)),
        decoration: BoxDecoration(
          color: theme.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(theme.radiusTile),
          border: Border.all(color: theme.amber.withValues(alpha: 0.3)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Narrow cards (kanban columns, small grid tiles) cannot fit the
            // remove action beside the title, so it moves underneath.
            final stacked = remove != null && constraints.maxWidth < theme.space(76);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: theme.space(2),
              children: [
                Padding(
                  padding: EdgeInsets.only(top: theme.space(0.5)),
                  child: GhIcon(GhIcons.alertTriangle, size: theme.space(3), color: theme.amber),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(0.5),
                    children: [
                      Text(
                        tr.project_missing_title,
                        style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold),
                      ),
                      if (!compact)
                        Text(
                          tr.project_missing_desc,
                          style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.5),
                        ),
                      if (stacked) remove,
                    ],
                  ),
                ),
                if (!stacked) ?remove,
              ],
            );
          },
        ),
      ),
    );
  }
}
