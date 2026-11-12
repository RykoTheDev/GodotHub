import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../ui/core/i18n.dart';
import '../logic/launch_errors.dart';
import '../modals/duplicate_project_modal.dart';
import '../modals/launch_args_modal.dart';
import '../modals/project_addons_modal.dart';
import '../modals/project_build_modal.dart';
import '../modals/project_doctor_modal.dart';
import '../modals/project_size_modal.dart';
import '../modals/save_as_template_modal.dart';
import '../modals/tag_manager_modal.dart';
import '../modals/time_tracker_modal.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/shell_signals.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';

const uncategorizedDot = Color(0xFF949BA4);

@immutable
class SelectModifiers {
  const SelectModifiers({this.shift = false, this.toggle = false});

  factory SelectModifiers.current() {
    final keyboard = HardwareKeyboard.instance;
    return SelectModifiers(shift: keyboard.isShiftPressed, toggle: keyboard.isControlPressed || keyboard.isMetaPressed);
  }

  final bool shift;
  final bool toggle;

  bool get any => shift || toggle;
}

class ProjectCallbacks {
  const ProjectCallbacks({
    required this.onTogglePin,
    required this.onVersionChange,
    required this.onRemove,
    this.onDelete,
    this.onCategoryChange,
    this.onDuplicate,
    this.onTagsSaved,
    this.onTagClick,
    this.onLaunchArgsChange,
    this.onShowGitSidebar,
    this.onToggleSelect,
  });

  final VoidCallback onTogglePin;
  final ValueChanged<String> onVersionChange;
  final VoidCallback onRemove;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onCategoryChange;
  final VoidCallback? onDuplicate;
  final ValueChanged<Project>? onTagsSaved;
  final ValueChanged<String>? onTagClick;
  final ValueChanged<String>? onLaunchArgsChange;
  final VoidCallback? onShowGitSidebar;
  final ValueChanged<SelectModifiers>? onToggleSelect;

  static const preview = ProjectCallbacks(onTogglePin: _noop, onVersionChange: _noopString, onRemove: _noop);
}

void _noop() {}

void _noopString(String _) {}

void openProjectFolder(Project project) =>
    ProjectsApi.openFolder(project.path).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

void openProjectInIde(Project project) => ProjectsApi.openInEditor(project.path).catchError((Object e) => reportLaunchError(e));

void openProjectTerminal(Project project) =>
    Api.openTerminal(project.path).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

void launchProject(Project project, [bool? console]) => AppSignals.emit(openProjectSignal, {'id': project.id, 'console': console});

void playProject(Project project) => ProjectsApi.open(project.id, false).catchError((Object e) => reportLaunchError(e));

Future<void> confirmRemoveProject(BuildContext context, String displayName, VoidCallback onRemove) async {
  final tr = context.tr.common;
  final ok = await showGhConfirmDialog(
    context,
    title: tr.project_remove_title,
    description: tr.project_remove_desc.args({'name': displayName}),
    confirmLabel: tr.bulk_remove,
  );
  if (ok) onRemove();
}

Future<void> confirmDeleteProject(BuildContext context, String displayName, VoidCallback onDelete) async {
  final tr = context.tr.common;
  final ok = await showGhConfirmDialog(
    context,
    title: tr.project_delete_title,
    description: tr.project_delete_desc.args({'name': displayName}),
    confirmLabel: tr.project_delete_confirm,
    variant: GhConfirmVariant.danger,
  );
  if (ok) onDelete();
}

Future<void> openTagManager(BuildContext context, Project project, ValueChanged<Project>? onSaved) => showGhModal<void>(
  context,
  (modalContext) =>
      TagManagerModal(project: project, onClose: () => Navigator.of(modalContext).pop(), onSaved: (updated) => onSaved?.call(updated)),
);

Future<void> openProjectBuild(BuildContext context, Project project) =>
    showGhModal<void>(context, (modal) => ProjectBuildModal(project: project, onClose: () => Navigator.of(modal).pop()));

Future<void> openProjectDoctor(BuildContext context, Project project, List<InstalledGodotVersion> installedVersions) => showGhModal<void>(
  context,
  (modal) => ProjectDoctorModal(project: project, installedVersions: installedVersions, onClose: () => Navigator.of(modal).pop()),
);

Future<void> openProjectAddons(BuildContext context, Project project) =>
    showGhModal<void>(context, (modal) => ProjectAddonsModal(project: project, onClose: () => Navigator.of(modal).pop()));

Future<void> openLaunchArgs(BuildContext context, Project project, ValueChanged<String>? onSave) => showGhModal<void>(
  context,
  (modal) => LaunchArgsModal(
    currentArgs: project.launchArguments,
    onSave: (args) {
      onSave?.call(args);
      Navigator.of(modal).pop();
    },
    onClose: () => Navigator.of(modal).pop(),
  ),
);

Future<void> openSaveAsTemplate(BuildContext context, Project project) =>
    showGhModal<void>(context, (modal) => SaveAsTemplateModal(project: project, onClose: () => Navigator.of(modal).pop()));

Future<void> openProjectSize(BuildContext context, Project project) =>
    showGhModal<void>(context, (modal) => ProjectSizeModal(projectPath: project.path, onClose: () => Navigator.of(modal).pop()));

Future<void> openTimeTracker(BuildContext context, Project project) =>
    showGhModal<void>(context, (modal) => TimeTrackerModal(project: project, onClose: () => Navigator.of(modal).pop()));

Future<void> openDuplicateProject(BuildContext context, Project project, VoidCallback onDuplicated) => showGhModal<void>(
  context,
  (modal) => DuplicateProjectModal(project: project, onClose: () => Navigator.of(modal).pop(), onDuplicated: onDuplicated),
);

List<GhDropdownHeaderItem> projectHeaderItems(BuildContext context, Project project, {required bool todosEnabled, VoidCallback? onTodos}) {
  final tr = context.tr;
  return [
    GhDropdownHeaderItem(
      id: 'open-folder',
      icon: GhIcons.externalLink,
      label: tr.common.open_folder,
      tooltip: tr.common.open_folder,
      onPressed: () => openProjectFolder(project),
    ),
    GhDropdownHeaderItem(
      id: 'open-ide',
      icon: GhIcons.code,
      label: tr.common.open_in_ide,
      tooltip: tr.common.open_in_ide,
      onPressed: () => openProjectInIde(project),
    ),
    GhDropdownHeaderItem(
      id: 'open-terminal',
      icon: GhIcons.terminal,
      label: tr.common.open_terminal,
      tooltip: tr.common.open_terminal,
      onPressed: () => openProjectTerminal(project),
    ),
    if (todosEnabled && onTodos != null)
      GhDropdownHeaderItem(
        id: 'project-todo',
        icon: GhIcons.checkCircle,
        label: ghTr('todos:next_steps'),
        tooltip: ghTr('todos:next_steps'),
        onPressed: onTodos,
      ),
  ];
}

List<GhMenuItem> categoryMenuChildren(BuildContext context, Project project, List<Category> categories, ValueChanged<String> onChange) => [
  GhMenuItem(
    id: 'category-uncategorized',
    label: context.tr.common.uncategorized,
    dotColor: uncategorizedDot,
    active: project.category == null || project.category!.isEmpty,
    onSelected: () => onChange(''),
  ),
  for (final c in categories)
    GhMenuItem(
      id: 'category-${c.id}',
      label: c.name,
      dotColor: colorFromHex(c.color),
      active: project.category == c.name,
      onSelected: () => onChange(c.name),
    ),
];
