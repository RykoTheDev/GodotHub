import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../../logic/pending_save.dart';
import '../../logic/platform.dart';
import '../../logic/settings_copy.dart';
import '../../src/rust/api/types.dart';
import '../../state/settings.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/core/i18n.dart';
import '../../ui/feedback/confirm_dialog.dart';
import '../../ui/feedback/toast.dart';
import '../settings_parts.dart';
import 'look_parts.dart';

class DisplaySettings extends ConsumerWidget {
  const DisplaySettings({super.key, this.mac});

  final bool? mac;

  Future<void> _confirmOsDecorations(BuildContext context, WidgetRef ref, bool value) async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: ghTr('restart_required_title'),
      description: ghTr('restart_required_desc'),
      confirmLabel: ghTr('restart_now'),
    );
    if (!confirmed) return;
    final current = ref.read(settingsProvider).value ?? defaultSettings;
    try {
      await ref.read(settingsProvider.notifier).save(copySettings(current, useOsDecorations: value));
      await flushPendingSave();
      await Api.relaunch();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    void update(AppSettings next) => ref.read(settingsProvider.notifier).save(next).ignore();
    final onMac = mac ?? isMac;
    Widget row(String key, bool checked, AppSettings Function(bool) apply) => SettingRow(
      label: lts(key),
      child: GhToggle(checked: checked, label: lts(key), onChanged: (value) => update(apply(value))),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'display-formats',
          title: lts('last_opened_title'),
          searchText:
              '${lts('last_opened_title')} ${lts('time_format_label')} ${lts('date_format_label')} ${lts('12h')} ${lts('24h')} ${lts('dd_mm_yyyy')} ${lts('mm_dd_yyyy')} ${lts('yyyy_mm_dd')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(5),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(2.5),
                children: [
                  Text(lts('time_format_label'), style: lookLabelStyle(theme)),
                  GhSegmented(
                    value: settings.lastOpenedTimeFormat,
                    onChanged: (value) => update(copySettings(settings, lastOpenedTimeFormat: value)),
                    options: [ghSegment('12h', lts('12h')), ghSegment('24h', lts('24h'))],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(2.5),
                children: [
                  Text(lts('date_format_label'), style: lookLabelStyle(theme)),
                  GhSegmented(
                    value: settings.lastOpenedDateFormat,
                    onChanged: (value) => update(copySettings(settings, lastOpenedDateFormat: value)),
                    options: [
                      ghSegment('DD-MM-YYYY', lts('dd_mm_yyyy'), mono: true),
                      ghSegment('MM-DD-YYYY', lts('mm_dd_yyyy'), mono: true),
                      ghSegment('YYYY-MM-DD', lts('yyyy_mm_dd'), mono: true),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!onMac)
          SettingsSubsection(
            id: 'display-os-decorations',
            inline: true,
            title: lts('use_os_decorations'),
            searchText: lts('use_os_decorations'),
            child: GhToggle(
              checked: settings.useOsDecorations,
              label: lts('use_os_decorations'),
              onChanged: (checked) => _confirmOsDecorations(context, ref, checked),
            ),
          ),
        if (!onMac)
          SettingsSubsection(
            id: 'display-colored-titlebar-buttons',
            inline: true,
            title: lts('colored_titlebar_buttons_label'),
            searchText: lts('colored_titlebar_buttons_label'),
            child: GhToggle(
              checked: settings.coloredTitlebarButtons,
              label: lts('colored_titlebar_buttons_label'),
              onChanged: (checked) => update(copySettings(settings, coloredTitlebarButtons: checked)),
            ),
          ),
        SettingsSubsection(
          id: 'display-titlebar',
          title: lts('titlebar_buttons'),
          searchText: '${lts('titlebar_buttons')} ${lts('show_support_label')} ${lts('show_star_label')} ${lts('show_changelog_label')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(4),
            children: [
              row('show_support_label', settings.showSupportButton, (v) => copySettings(settings, showSupportButton: v)),
              row('show_star_label', settings.showStarButton, (v) => copySettings(settings, showStarButton: v)),
              row('show_bug_label', settings.showBugButton, (v) => copySettings(settings, showBugButton: v)),
              row('show_tray_label', settings.showTrayButton, (v) => copySettings(settings, showTrayButton: v)),
              row('show_language_label', settings.showLanguageButton, (v) => copySettings(settings, showLanguageButton: v)),
              row('show_changelog_label', settings.showChangelogButton, (v) => copySettings(settings, showChangelogButton: v)),
            ],
          ),
        ),
      ],
    );
  }
}
