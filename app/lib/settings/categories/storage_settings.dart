import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../../logic/settings_copy.dart';
import '../../src/rust/api/types.dart';
import '../../state/projects.dart';
import '../../state/settings.dart';
import '../../ui/controls/slider.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/core/i18n.dart';
import '../../ui/reusables/dir_list.dart';
import '../settings_parts.dart';
import 'settings_option_controls.dart';

String _ts(String key, {num? count, Map<String, Object?> args = const {}}) => settingsTr(key, count: count, args: args);

class StorageSettings extends ConsumerStatefulWidget {
  const StorageSettings({super.key, this.pickFolder});

  final Future<String?> Function()? pickFolder;

  @override
  ConsumerState<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettings> {
  String? _scanMessage;

  void _save(AppSettings Function(AppSettings s) change) => saveSettings(ref, change).ignore();

  Future<void> _runScan(AppSettings settings) async {
    setState(() => _scanMessage = _ts('scanning'));
    try {
      final results = await Future.wait([
        settings.projectScanDirs.isNotEmpty
            ? Api.scanForProjects(settings.projectScanDirs, settings.scanDepth).then((list) => list.length)
            : Future.value(0),
        settings.versionScanDirs.isNotEmpty
            ? Api.scanForVersions(settings.versionScanDirs, settings.scanDepth).then((list) => list.length)
            : Future.value(0),
      ]);
      if (mounted) {
        setState(() => _scanMessage = _ts('scan_result', args: {'projects': results[0], 'versions': results[1]}));
      }
      await ref.read(projectsProvider.notifier).refresh();
    } catch (e) {
      if (mounted) setState(() => _scanMessage = '$e');
    }
  }

  Widget _folderBox(GhTheme theme, {required FaIconData icon, required Color color, required String label, required Widget list}) {
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2.5),
        children: [
          Row(
            spacing: theme.space(2),
            children: [
              GhIcon(icon, size: theme.space(4), color: color),
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
              ),
            ],
          ),
          list,
        ],
      ),
    );
  }

  Widget _slider(
    GhTheme theme, {
    required String id,
    required String titleKey,
    required String displayKey,
    required int value,
    required int max,
    required int defaultValue,
    required AppSettings Function(AppSettings s, int v) change,
  }) {
    return SettingsSubsection(
      id: id,
      inline: true,
      fill: true,
      title: _ts(titleKey),
      searchText: _ts(titleKey),
      child: GhSlider(
        display: Text(
          _ts(displayKey, count: value),
          style: theme
              .text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        value: value.toDouble(),
        min: 1,
        max: max.toDouble(),
        defaultValue: defaultValue.toDouble(),
        onChanged: (next) => _save((s) => change(s, next.round())),
      ),
    );
  }

  Widget _watchers(GhTheme theme, AppSettings settings) {
    Widget toggle(String key, bool checked, AppSettings Function(AppSettings s, bool v) change) => GhToggle(
      checked: checked,
      label: _ts(key),
      onChanged: (value) {
        _save((s) => change(s, value));
        ignoreAll(Api.restartWatchers);
      },
    );
    return SettingsSubsection(
      id: 'storage-watchers',
      title: _ts('file_watchers_title'),
      searchText: [
        _ts('file_watchers_title'),
        _ts('watch_projects_label'),
        _ts('watch_versions_label'),
        _ts('watch_template_label'),
      ].join(' '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(5),
        children: [
          SettingRow(
            label: _ts('watch_projects_label'),
            child: toggle('watch_projects_label', settings.autoWatchProjectDirs, (s, v) => copySettings(s, autoWatchProjectDirs: v)),
          ),
          SettingRow(
            label: _ts('watch_versions_label'),
            divider: true,
            child: toggle('watch_versions_label', settings.autoWatchVersionDirs, (s, v) => copySettings(s, autoWatchVersionDirs: v)),
          ),
          SettingRow(
            label: _ts('watch_template_label'),
            divider: true,
            child: toggle('watch_template_label', settings.autoWatchTemplateDir, (s, v) => copySettings(s, autoWatchTemplateDir: v)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final theme = GhTheme.of(context);
    final scanMessage = _scanMessage;
    final templateDir = settings.templateScanDir;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'storage-folders',
          title: _ts('storage_title'),
          searchText: [
            _ts('storage_title'),
            _ts('section_projects'),
            _ts('section_godot_versions'),
            _ts('section_templates'),
            _ts('new_project_default'),
            _ts('download_folder'),
          ].join(' '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(3),
            children: [
              _folderBox(
                theme,
                icon: GhIcons.folder,
                color: theme.accent,
                label: _ts('section_projects'),
                list: GhDirList(
                  dirs: settings.projectScanDirs,
                  onChanged: (dirs) => _save((s) => copySettings(s, projectScanDirs: dirs)),
                  emptyHint: _ts('empty_hint_projects'),
                  defaultDir: settings.defaultProjectLocation,
                  onSetDefault: (dir) => _save((s) => copySettings(s, defaultProjectLocation: () => dir)),
                  defaultLabel: _ts('new_project_default'),
                  pickFolder: widget.pickFolder,
                ),
              ),
              _folderBox(
                theme,
                icon: GhIcons.cloudArrowDown,
                color: theme.mint,
                label: _ts('section_godot_versions'),
                list: GhDirList(
                  dirs: settings.versionScanDirs,
                  onChanged: (dirs) => _save((s) => copySettings(s, versionScanDirs: dirs)),
                  emptyHint: _ts('empty_hint_versions'),
                  defaultDir: settings.downloadDir,
                  onSetDefault: (dir) => _save((s) => copySettings(s, downloadDir: () => dir)),
                  defaultLabel: _ts('download_folder'),
                  showFallbackDescription: true,
                  pickFolder: widget.pickFolder,
                ),
              ),
              _folderBox(
                theme,
                icon: GhIcons.rocket,
                color: theme.amber,
                label: _ts('section_templates'),
                list: GhDirList(
                  single: true,
                  dirs: templateDir == null ? const [] : [templateDir],
                  onChanged: (dirs) => _save((s) => copySettings(s, templateScanDir: () => dirs.firstOrNull)),
                  emptyHint: _ts('no_folder_set'),
                  pickFolder: widget.pickFolder,
                ),
              ),
            ],
          ),
        ),
        _slider(
          theme,
          id: 'storage-scan-depth',
          titleKey: 'scan_depth_label',
          displayKey: 'folders_deep',
          value: settings.scanDepth,
          max: 10,
          defaultValue: 2,
          change: (s, v) => copySettings(s, scanDepth: v),
        ),
        _slider(
          theme,
          id: 'storage-icon-scan-depth',
          titleKey: 'icon_scan_depth_label',
          displayKey: 'folders_deep',
          value: settings.iconScanDepth,
          max: 20,
          defaultValue: 4,
          change: (s, v) => copySettings(s, iconScanDepth: v),
        ),
        _slider(
          theme,
          id: 'storage-concurrency',
          titleKey: 'download_concurrency_label',
          displayKey: 'at_once',
          value: settings.downloadConcurrency,
          max: 10,
          defaultValue: 3,
          change: (s, v) => copySettings(s, downloadConcurrency: v),
        ),
        _watchers(theme, settings),
        Row(
          spacing: theme.space(3),
          children: [
            SettingsOutlineButton(label: ghTr('scan_now'), icon: GhIcons.refresh, onPressed: () => _runScan(settings)),
            if (scanMessage != null)
              Flexible(
                child: Text(
                  scanMessage,
                  style: theme.text(size: GhTextSize.xs, color: theme.muted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
