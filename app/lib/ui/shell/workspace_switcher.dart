import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../overlays/menu.dart';
import 'strings.dart';

@immutable
class GhWorkspace {
  const GhWorkspace({required this.id, required this.name, required this.icon, required this.color});

  final String id;
  final String name;
  final String icon;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is GhWorkspace && other.id == id && other.name == name && other.icon == icon && other.color == color;

  @override
  int get hashCode => Object.hash(id, name, icon, color);
}

class GhWorkspaceBadge extends StatelessWidget {
  const GhWorkspaceBadge({super.key, required this.workspace, this.active = false});

  final GhWorkspace workspace;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      width: theme.space(6),
      height: theme.space(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white.withValues(alpha: 0.15) : theme.raised,
        border: Border.all(color: active ? Colors.white.withValues(alpha: 0.2) : theme.outline.withValues(alpha: 0.5)),
      ),
      child: GhIcon(workspaceIcon(workspace.icon), size: theme.space(3), color: active ? Colors.white : theme.muted),
    );
  }
}

class GhWorkspaceMenuBadge extends StatelessWidget {
  const GhWorkspaceMenuBadge({super.key, required this.workspace});

  final GhWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return SizedBox(
      width: theme.space(7),
      height: theme.space(7),
      child: Center(child: GhWorkspaceBadge(workspace: workspace)),
    );
  }
}

String ghWorkspaceShortcut(int index, {bool? isMac}) {
  final mac = isMac ?? defaultTargetPlatform == TargetPlatform.macOS;
  return '${mac ? '⌥' : 'Alt+'}${index + 1}';
}

GhMenuItem? ghWorkspaceMenuItem({
  required List<GhWorkspace> workspaces,
  required String? activeId,
  required ValueChanged<String> onSwitch,
  required ValueChanged<String> onEdit,
  required VoidCallback onCreate,
  bool? isMac,
  String editLabel = GhShellStrings.editWorkspaceTitle,
  String createLabel = GhShellStrings.createWorkspace,
}) {
  if (workspaces.isEmpty) {
    return null;
  }
  final active = workspaces.firstWhere((w) => w.id == activeId, orElse: () => workspaces.first);
  return GhMenuItem(
    id: 'workspace',
    label: active.name,
    leading: GhWorkspaceMenuBadge(workspace: active),
    dividerAfter: true,
    action: GhMenuItemAction(icon: GhIcons.pencil, label: editLabel, onPressed: () => onEdit(active.id)),
    children: [
      for (var index = 0; index < workspaces.length; index++)
        GhMenuItem(
          id: workspaces[index].id,
          label: workspaces[index].name,
          leading: GhWorkspaceBadge(workspace: workspaces[index], active: workspaces[index].id == active.id),
          active: workspaces[index].id == active.id,
          shortcut: index < 9 ? ghWorkspaceShortcut(index, isMac: isMac) : null,
          dividerAfter: index == workspaces.length - 1,
          onSelected: () => onSwitch(workspaces[index].id),
        ),
      GhMenuItem(id: 'create', label: createLabel, icon: GhIcons.plus, onSelected: onCreate),
    ],
  );
}
