import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../../logic/pending_save.dart';
import '../../logic/settings_copy.dart';
import '../../state/app_signals.dart';
import '../../state/settings.dart';
import '../../state/shell_signals.dart';
import '../../ui/core/i18n.dart';
import '../../ui/feedback/confirm_dialog.dart';
import '../../ui/feedback/toast.dart';
import '../settings_parts.dart';
import 'settings_option_controls.dart';

String _ts(String key, {num? count, Map<String, Object?> args = const {}}) => settingsTr(key, count: count, args: args);

class AdvancedSettings extends ConsumerWidget {
  const AdvancedSettings({super.key, this.onCheckUpdates, this.onReportBug});

  final VoidCallback? onCheckUpdates;
  final VoidCallback? onReportBug;

  Future<void> _restart(BuildContext context) async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: _ts('restart_app_confirm_title'),
      description: _ts('restart_app_confirm_desc'),
      confirmLabel: _ts('restart_app'),
    );
    if (!confirmed) return;
    try {
      await flushPendingSave();
      await Api.relaunch();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: _ts('reset_all_title'),
      description: _ts('reset_all_desc'),
      confirmLabel: _ts('reset_settings'),
      variant: GhConfirmVariant.danger,
    );
    if (!confirmed) return;
    try {
      await ref.read(settingsProvider.notifier).resetToDefaults();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: _ts('delete_all_title'),
      description: _ts('delete_all_desc'),
      confirmLabel: _ts('delete_app_data'),
      variant: GhConfirmVariant.danger,
    );
    if (!confirmed) return;
    try {
      await Api.resetAppData();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
      return;
    }
    try {
      await Api.relaunch();
    } catch (_) {
      ref.invalidate(settingsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'advanced-setup',
          inline: true,
          title: _ts('setup_wizard_again'),
          searchText: '${_ts('setup_wizard_again')} ${_ts('open_setup')}',
          child: SettingsOutlineButton(
            label: _ts('open_setup'),
            onPressed: () => saveSettings(ref, (s) => copySettings(s, setupComplete: false)).ignore(),
          ),
        ),
        SettingsActionCard(
          title: ghTr('check_updates_title_modal'),
          action: SettingsOutlineButton(
            label: ghTr('check_updates_title_modal'),
            icon: GhIcons.refresh,
            onPressed: onCheckUpdates ?? () => AppSignals.emit(previewUpdateModalSignal),
          ),
        ),
        SettingsActionCard(
          title: _ts('restart_app'),
          action: SettingsOutlineButton(label: _ts('restart_app'), icon: GhIcons.refresh, onPressed: () => _restart(context)),
        ),
        SettingsActionCard(
          title: ghTr('report_a_bug'),
          action: SettingsOutlineButton(
            label: ghTr('report_bug'),
            icon: GhIcons.bug,
            onPressed: onReportBug ?? () => AppSignals.emit(reportBugSignal),
          ),
        ),
        SettingsActionCard(
          title: _ts('reset_settings'),
          action: SettingsOutlineButton(label: ghTr('reset'), tone: SettingsButtonTone.subtleDanger, onPressed: () => _reset(context, ref)),
        ),
        SettingsActionCard(
          title: _ts('delete_app_data'),
          danger: true,
          action: SettingsOutlineButton(
            label: _ts('delete_all'),
            icon: GhIcons.bomb,
            tone: SettingsButtonTone.danger,
            onPressed: () => _wipe(context, ref),
          ),
        ),
      ],
    );
  }
}
