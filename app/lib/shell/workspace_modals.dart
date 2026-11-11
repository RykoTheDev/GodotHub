import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modals/create_workspace_modal.dart';
import '../modals/workspace_edit_modal.dart';
import '../state/app_signals.dart';
import '../state/shell_signals.dart';
import '../state/workspaces.dart';
import '../ui/feedback/modal_shell.dart';

void requestCreateWorkspace() => AppSignals.emit(createWorkspaceRequestSignal);

void requestEditWorkspace(String id) => AppSignals.emit(editWorkspaceRequestSignal, id);

class WorkspaceModals extends ConsumerStatefulWidget {
  const WorkspaceModals({super.key});

  @override
  ConsumerState<WorkspaceModals> createState() => _WorkspaceModalsState();
}

class _WorkspaceModalsState extends ConsumerState<WorkspaceModals> {
  final List<StreamSubscription<AppSignal>> _subscriptions = [];
  bool _creating = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(AppSignals.on(createWorkspaceRequestSignal).listen((_) => _openCreate()))
      ..add(
        AppSignals.on(editWorkspaceRequestSignal).listen((signal) {
          final id = signal.detail;
          if (id is String) _openEdit(id);
        }),
      );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _openCreate() async {
    if (_creating || !mounted) return;
    _creating = true;
    final notifier = ref.read(workspacesProvider.notifier);
    final view = ref.read(workspacesProvider);
    final active = view.workspaces.where((w) => w.id == view.activeId).firstOrNull;
    await showGhModal<void>(context, (context) {
      void close() => Navigator.of(context).pop();
      return CreateWorkspaceModal(
        takenNames: [for (final w in view.workspaces) w.name],
        copySource: active,
        onClose: close,
        onCreate: (draft, start) async {
          await notifier.createWorkspace(draft.name, draft.icon, draft.color, start == WorkspaceStart.copy ? view.activeId : null);
          if (context.mounted) close();
        },
      );
    });
    _creating = false;
  }

  Future<void> _openEdit(String id) async {
    if (_editingId != null || !mounted) return;
    final view = ref.read(workspacesProvider);
    final editing = view.workspaces.where((w) => w.id == id).firstOrNull;
    if (editing == null) return;
    _editingId = id;
    final notifier = ref.read(workspacesProvider.notifier);
    await showGhModal<void>(context, (context) {
      void close() => Navigator.of(context).pop();
      return WorkspaceEditModal(
        workspace: editing,
        takenNames: [for (final w in view.workspaces) if (w.id != editing.id) w.name],
        canDelete: view.workspaces.length > 1,
        onClose: close,
        onSave: (name, icon, color) async {
          await Future.wait([
            if (name.trim() != editing.name) notifier.renameWorkspace(editing.id, name),
            if (icon != editing.icon || color != editing.color) notifier.updateWorkspaceStyle(editing.id, icon, color),
          ]);
          if (context.mounted) close();
        },
        onDelete: () async {
          await notifier.deleteWorkspace(editing.id);
          if (context.mounted) close();
        },
      );
    });
    _editingId = null;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
