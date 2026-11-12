import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../../logic/features.dart';
import '../../logic/platform.dart';
import '../../logic/settings_copy.dart';
import '../../onboarding/feature_setup_picker.dart';
import '../../src/rust/api/types.dart';
import '../../state/settings.dart';
import '../../ui/controls/key_recorder.dart';
import '../../ui/controls/slider.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/overlays/dropdown.dart';
import '../../ui/overlays/menu.dart';
import '../settings_parts.dart';
import 'settings_option_controls.dart';

String _ts(String key, {num? count, Map<String, Object?> args = const {}}) => settingsTr(key, count: count, args: args);

const landingTabOptions = [
  (id: 'dashboard', labelKey: 'landing_dashboard'),
  (id: 'projects', labelKey: 'landing_projects'),
  (id: 'versions', labelKey: 'landing_versions'),
  (id: 'news', labelKey: 'landing_news'),
];

const namingConventionOptions = [
  (value: 'keep', labelKey: 'naming_keep'),
  (value: 'kebab-case', labelKey: 'naming_kebab'),
  (value: 'snake_case', labelKey: 'naming_snake'),
  (value: 'camelCase', labelKey: 'naming_camel'),
  (value: 'PascalCase', labelKey: 'naming_pascal'),
  (value: 'Title Case', labelKey: 'naming_title'),
];

class BehaviorSettings extends ConsumerWidget {
  const BehaviorSettings({super.key, this.isMacOverride});

  final bool? isMacOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final theme = GhTheme.of(context);
    final mac = isMacOverride ?? isMac;
    void save(AppSettings Function(AppSettings s) change) => saveSettings(ref, change).ignore();
    Widget toggle(String labelKey, bool checked, AppSettings Function(AppSettings s, bool v) change) =>
        GhToggle(checked: checked, label: _ts(labelKey), onChanged: (value) => save((s) => change(s, value)));
    final landingTabs = [
      for (final option in landingTabOptions)
        if (isFeatureEnabled(settings, option.id)) option,
    ];
    final landingLabelKey =
        landingTabs.where((l) => l.id == settings.defaultLandingTab).map((l) => l.labelKey).firstOrNull ?? 'landing_projects';
    final conventionLabel =
        namingConventionOptions.where((o) => o.value == settings.directoryNamingConvention).map((o) => _ts(o.labelKey)).firstOrNull ??
        _ts(namingConventionOptions.first.labelKey);
    final showReopen = settings.closeOnProjectOpen && (mac || settings.minimizeToTray);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'behavior-features',
          title: _ts('features_title'),
          searchText: [
            _ts('features_title'),
            _ts('features_desc'),
            _ts('setup_profile_minimal'),
            _ts('setup_profile_essentials'),
            _ts('setup_profile_studio'),
            _ts('setup_profile_complete'),
            _ts('setup_profile_custom'),
          ].join(' '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: theme.space(1)),
                child: Text(
                  _ts('features_desc'),
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
              ),
              FeatureSetupPicker(
                value: settings,
                onChanged: (next) => ignoreAll(() async {
                  await ref.read(settingsProvider.notifier).save(next);
                  await Api.restartWatchers();
                }),
              ),
            ],
          ),
        ),
        SettingsSubsection(
          id: 'behavior-landing',
          inline: true,
          title: _ts('landing_tab_label'),
          searchText: [_ts('landing_tab_label'), for (final l in landingTabs) _ts(l.labelKey)].join(' '),
          child: GhDropdown(
            items: [
              for (final l in landingTabs)
                GhMenuItem(
                  id: l.id,
                  label: _ts(l.labelKey),
                  active: settings.defaultLandingTab == l.id,
                  onSelected: () => save((s) => copySettings(s, defaultLandingTab: l.id)),
                ),
            ],
            trigger: (context, open, toggle) => SettingsDropdownTrigger(label: _ts(landingLabelKey), open: open, onPressed: toggle),
          ),
        ),
        SettingsSubsection(
          id: 'behavior-launch',
          title: _ts('behavior'),
          searchText: [
            _ts('behavior'),
            _ts('launch_console_label'),
            _ts('close_on_open_label'),
            _ts('minimize_tray_label'),
            _ts('reopen_label'),
            _ts('tray_recent_label'),
            _ts('palette_shortcut'),
          ].join(' '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(5),
            children: [
              SettingRow(
                label: _ts('launch_console_label'),
                child: toggle('launch_console_label', settings.launchWithConsole, (s, v) => copySettings(s, launchWithConsole: v)),
              ),
              SettingRow(
                label: _ts('builtin_console_label'),
                child: toggle('builtin_console_label', settings.builtinConsole, (s, v) => copySettings(s, builtinConsole: v)),
              ),
              SettingRow(
                label: _ts('close_on_open_label'),
                divider: true,
                child: toggle('close_on_open_label', settings.closeOnProjectOpen, (s, v) => copySettings(s, closeOnProjectOpen: v)),
              ),
              if (!mac)
                SettingRow(
                  label: _ts('minimize_tray_label'),
                  divider: true,
                  child: toggle('minimize_tray_label', settings.minimizeToTray, (s, v) => copySettings(s, minimizeToTray: v)),
                ),
              if (showReopen)
                SettingRow(
                  label: _ts('reopen_label'),
                  divider: true,
                  child: toggle('reopen_label', settings.reopenAfterGodotCloses, (s, v) => copySettings(s, reopenAfterGodotCloses: v)),
                ),
              Container(
                padding: EdgeInsets.only(top: theme.space(5)),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.line)),
                ),
                child: GhSlider(
                  label: _ts('tray_recent_label'),
                  display: Text(
                    _ts('n_projects', count: settings.trayRecentProjectsCount),
                    style: theme.text(size: GhTextSize.xs, color: theme.ink).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  value: settings.trayRecentProjectsCount.toDouble(),
                  min: 1,
                  max: 10,
                  defaultValue: 5,
                  onChanged: (value) {
                    save((s) => copySettings(s, trayRecentProjectsCount: value.round()));
                    ignoreAll(Api.refreshTrayMenu);
                  },
                ),
              ),
              GhKeyRecorder(
                value: settings.commandPaletteKeybind,
                isMac: isMacOverride,
                onChanged: (value) => save((s) => copySettings(s, commandPaletteKeybind: value)),
                onReset: () => save((s) => copySettings(s, commandPaletteKeybind: 'p')),
              ),
            ],
          ),
        ),
        SettingsSubsection(
          id: 'behavior-projects',
          title: _ts('behavior_projects_title'),
          searchText: [
            _ts('behavior_projects_title'),
            _ts('auto_scan_label'),
            _ts('use_workspaces_label'),
            _ts('init_git_label'),
            _ts('naming_convention_label'),
          ].join(' '),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(5),
            children: [
              SettingRow(
                label: _ts('auto_scan_label'),
                child: toggle('auto_scan_label', settings.autoScanOnStartup, (s, v) => copySettings(s, autoScanOnStartup: v)),
              ),
              SettingRow(
                label: _ts('use_workspaces_label'),
                divider: true,
                child: toggle('use_workspaces_label', settings.workspacesEnabled, (s, v) => copySettings(s, workspacesEnabled: v)),
              ),
              SettingRow(
                label: _ts('init_git_label'),
                divider: true,
                child: toggle('init_git_label', settings.gitInitNewProjects, (s, v) => copySettings(s, gitInitNewProjects: v)),
              ),
              SettingRow(
                label: _ts('naming_convention_label'),
                divider: true,
                child: GhDropdown(
                  items: [
                    for (final option in namingConventionOptions)
                      GhMenuItem(
                        id: option.value,
                        label: _ts(option.labelKey),
                        active: settings.directoryNamingConvention == option.value,
                        onSelected: () => save((s) => copySettings(s, directoryNamingConvention: option.value)),
                      ),
                  ],
                  trigger: (context, open, toggle) => SettingsDropdownTrigger(label: conventionLabel, open: open, onPressed: toggle),
                ),
              ),
            ],
          ),
        ),
        SettingsSubsection(
          id: 'behavior-notifications',
          title: _ts('desktop_notifications_label'),
          searchText: '${_ts('desktop_notifications_label')} ${_ts('behavior')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(5),
            children: [
              SettingRow(
                label: _ts('desktop_notifications_label'),
                child: toggle(
                  'desktop_notifications_label',
                  settings.desktopNotificationsEnabled,
                  (s, v) => copySettings(s, desktopNotificationsEnabled: v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
