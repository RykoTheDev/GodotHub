import 'package:flutter/material.dart';

import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';

class VaultProjectPicker extends StatelessWidget {
  const VaultProjectPicker({super.key, required this.projects, required this.selectedId, required this.onSelect});

  final List<Project> projects;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final selected = projects.where((p) => p.id == selectedId).firstOrNull;
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhDropdown(
      align: GhSide.left,
      expand: true,
      items: [for (final p in projects) GhMenuItem(id: p.id, label: p.name, active: p.id == selectedId, onSelected: () => onSelect(p.id))],
      trigger: (context, open, toggle) => GhPressable(
        onPressed: toggle,
        expanded: open,
        borderRadius: radius,
        builder: (context, states) => GhAnimatedBox(
          height: theme.space(10),
          color: theme.base,
          borderRadius: radius,
          border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
          child: Row(
            spacing: theme.space(2),
            children: [
              GhIcon(GhIcons.folder, size: theme.space(3.5), color: theme.muted),
              Expanded(
                child: Text(
                  selected?.name ?? ghTr('vault_select_project'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.sm, color: selected != null ? theme.ink : theme.muted),
                ),
              ),
              GhIcon(GhIcons.chevronDown, size: theme.space(3.5), color: theme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
