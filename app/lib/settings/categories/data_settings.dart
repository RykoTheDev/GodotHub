import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/projects.dart';
import '../../api/settings.dart';
import '../../design/design.dart';
import '../../src/rust/api/types.dart';
import '../../state/app_signals.dart';
import '../../state/categories.dart';
import '../../state/projects.dart';
import '../../state/settings.dart';
import '../../state/shell_signals.dart';
import '../../state/workspaces.dart';
import '../../ui/core/i18n.dart';
import 'settings_buttons.dart';

String _ts(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

typedef SettingsSavePathPicker = Future<String?> Function(String defaultName);
typedef SettingsDataFilePicker = Future<String?> Function();

abstract final class SettingsFilePickers {
  @visibleForTesting
  static SettingsSavePathPicker? debugPickSavePath;
  @visibleForTesting
  static SettingsDataFilePicker? debugPickDataFile;

  static Future<String?> pickSavePath(String defaultName) => (debugPickSavePath ?? ProjectsApi.pickSavePath)(defaultName);

  static Future<String?> pickDataFile() => (debugPickDataFile ?? ProjectsApi.pickDataFile)();
}

enum _Busy { export, import }

class DataSettings extends ConsumerStatefulWidget {
  const DataSettings({super.key});

  @override
  ConsumerState<DataSettings> createState() => _DataSettingsState();
}

class _DataSettingsState extends ConsumerState<DataSettings> {
  _Busy? _settingsBusy;
  String? _settingsMessage;
  _Busy? _workspaceBusy;
  String? _workspaceMessage;
  _Busy? _appBusy;
  String? _appMessage;
  _Busy? _statsBusy;
  String? _statsMessage;

  Future<void> _run(_Busy kind, void Function(_Busy? busy, String? message) set, Future<String?> Function() action) async {
    setState(() => set(kind, null));
    String? message;
    try {
      message = await action();
    } catch (e) {
      message = '$e';
    }
    if (mounted) setState(() => set(null, message));
  }

  Future<void> _apply(AppSettings imported) => ref.read(settingsProvider.notifier).save(imported);

  Future<void> _refreshProjects() => ref.read(projectsProvider.notifier).refresh();

  void _exportSettings() => _run(
    _Busy.export,
    (b, m) {
      _settingsBusy = b;
      _settingsMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickSavePath('godothub-settings.json');
      if (path == null) return null;
      await SettingsApi.exportSettings(path);
      return _ts('settings_exported');
    },
  );

  void _importSettings() => _run(
    _Busy.import,
    (b, m) {
      _settingsBusy = b;
      _settingsMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickDataFile();
      if (path == null) return null;
      final imported = await SettingsApi.importSettings(path);
      await _apply(imported);
      await _refreshProjects();
      return _ts('settings_imported');
    },
  );

  void _exportWorkspace() => _run(
    _Busy.export,
    (b, m) {
      _workspaceBusy = b;
      _workspaceMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickSavePath('godothub-workspace-backup.json');
      if (path == null) return null;
      await SettingsApi.exportWorkspaceBackup(path);
      return _ts('workspace_backup_exported');
    },
  );

  void _importWorkspace() => _run(
    _Busy.import,
    (b, m) {
      _workspaceBusy = b;
      _workspaceMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickDataFile();
      if (path == null) return null;
      final imported = await SettingsApi.importWorkspaceBackup(path);
      await _apply(imported);
      await _refreshProjects();
      await ref.read(categoriesProvider.notifier).refresh();
      AppSignals.emit(refreshTemplatesSignal);
      return _ts('workspace_backup_imported');
    },
  );

  void _exportApp() => _run(
    _Busy.export,
    (b, m) {
      _appBusy = b;
      _appMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickSavePath('godothub-full-backup.json');
      if (path == null) return null;
      await SettingsApi.exportAppBackup(path);
      return _ts('app_backup_exported');
    },
  );

  void _importApp() => _run(
    _Busy.import,
    (b, m) {
      _appBusy = b;
      _appMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickDataFile();
      if (path == null) return null;
      final imported = await SettingsApi.importAppBackup(path);
      await _apply(imported);
      await _refreshProjects();
      await ref.read(categoriesProvider.notifier).refresh();
      await ref.read(workspacesProvider.notifier).refresh();
      AppSignals.emit(refreshTemplatesSignal);
      return _ts('app_backup_imported');
    },
  );

  void _exportStats() => _run(
    _Busy.export,
    (b, m) {
      _statsBusy = b;
      _statsMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickSavePath('godothub-time-stats.json');
      if (path == null) return null;
      await ProjectsApi.exportProjectStats(path);
      return _ts('stats_exported');
    },
  );

  void _importStats() => _run(
    _Busy.import,
    (b, m) {
      _statsBusy = b;
      _statsMessage = m;
    },
    () async {
      final path = await SettingsFilePickers.pickDataFile();
      if (path == null) return null;
      final count = await ProjectsApi.importProjectStats(path);
      await _refreshProjects();
      return _ts('stats_imported', count: count.toInt());
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        _BackupRow(
          title: _ts('settings_backup_title'),
          message: _settingsMessage,
          busy: _settingsBusy,
          exportLabel: _ts('export_settings_btn'),
          importLabel: _ts('import_settings_btn'),
          onExport: _exportSettings,
          onImport: _importSettings,
        ),
        _BackupRow(
          title: _ts('workspace_backup_title'),
          message: _workspaceMessage,
          busy: _workspaceBusy,
          exportLabel: _ts('workspace_backup_export_btn'),
          importLabel: _ts('workspace_backup_restore_btn'),
          onExport: _exportWorkspace,
          onImport: _importWorkspace,
        ),
        _BackupRow(
          title: _ts('app_backup_title'),
          message: _appMessage,
          busy: _appBusy,
          exportLabel: _ts('app_backup_export_btn'),
          importLabel: _ts('app_backup_restore_btn'),
          onExport: _exportApp,
          onImport: _importApp,
        ),
        _BackupRow(
          title: _ts('time_tracking_title'),
          message: _statsMessage,
          busy: _statsBusy,
          exportLabel: _ts('export_stats_btn'),
          importLabel: _ts('import_stats_btn'),
          onExport: _exportStats,
          onImport: _importStats,
        ),
      ],
    );
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.title,
    required this.message,
    required this.busy,
    required this.exportLabel,
    required this.importLabel,
    required this.onExport,
    required this.onImport,
  });

  final String title;
  final String? message;
  final _Busy? busy;
  final String exportLabel;
  final String importLabel;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final saving = _ts('saving');
    final message = this.message;
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusItem)),
      child: Row(
        spacing: theme.space(6),
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                ),
                if (message != null)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(1.5)),
                    child: Text(
                      message,
                      style: theme.text(size: GhTextSize.xs, color: theme.muted),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(2),
            children: [
              SettingsButton(onPressed: busy == null ? onExport : null, label: busy == _Busy.export ? saving : exportLabel),
              SettingsButton(onPressed: busy == null ? onImport : null, label: busy == _Busy.import ? saving : importLabel),
            ],
          ),
        ],
      ),
    );
  }
}
