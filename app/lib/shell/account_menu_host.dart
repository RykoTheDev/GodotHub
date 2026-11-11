import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/git_auth.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/changelog.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../state/workspaces.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/shell/account_menu.dart';
import '../ui/shell/workspace_switcher.dart';
import 'workspace_modals.dart';

class AccountMenuHost extends ConsumerStatefulWidget {
  const AccountMenuHost({super.key, required this.trigger, required this.onNavigate});

  final GhDropdownTriggerBuilder trigger;
  final ValueChanged<String> onNavigate;

  @override
  ConsumerState<AccountMenuHost> createState() => _AccountMenuHostState();
}

class _AccountMenuHostState extends ConsumerState<AccountMenuHost> {
  String? _osName;
  GitAuthState? _gitAuth;

  void _load(bool open) {
    if (!open) return;
    Api.getOsUsername().then(
      (name) {
        if (mounted) setState(() => _osName = name);
      },
      onError: (Object _) {
        if (mounted) setState(() => _osName = null);
      },
    );
    GitAuthApi.getState().then(
      (state) {
        if (mounted) setState(() => _gitAuth = state);
      },
      onError: (Object _) {
        if (mounted) setState(() => _gitAuth = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspacesEnabled = ref.watch(settingsProvider.select((s) => s.value?.workspacesEnabled ?? false));
    final hasNewChangelog = ref.watch(changelogBadgeProvider);
    final view = ref.watch(workspacesProvider);
    final workspaceItem = workspacesEnabled
        ? ghWorkspaceMenuItem(
            workspaces: [for (final w in view.workspaces) GhWorkspace(id: w.id, name: w.name, icon: w.icon, color: w.color)],
            activeId: view.activeId,
            onSwitch: (id) => ref.read(workspacesProvider.notifier).switchWorkspace(id).ignore(),
            onEdit: requestEditWorkspace,
            onCreate: requestCreateWorkspace,
          )
        : null;
    return GhAccountMenu(
      trigger: widget.trigger,
      onNavigate: widget.onNavigate,
      onOpenChange: _load,
      userName: _osName,
      githubUsername: _gitAuth?.github?.username,
      gitlabUsername: _gitAuth?.gitlab?.username,
      hasNewChangelog: hasNewChangelog,
      workspaceItem: workspaceItem,
      onReportBug: () => AppSignals.emit(reportBugSignal),
      onSupport: () => Api.openUrl(ghSupportUrl).ignore(),
      onManageAccounts: () => AppSignals.emit(openSettingsCategorySignal, 'integrations'),
    );
  }
}
