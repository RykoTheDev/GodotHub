import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/design.dart';
import '../../logic/settings_copy.dart';
import '../../src/rust/api/types.dart';
import '../../state/settings.dart';
import '../../ui/controls/slider.dart';
import '../../ui/controls/toggle.dart';
import '../settings_parts.dart';
import 'look_parts.dart';

class AccessibilitySettings extends ConsumerWidget {
  const AccessibilitySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    void update(AppSettings next) => ref.read(settingsProvider.notifier).save(next).ignore();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'accessibility-density',
          inline: true,
          fill: true,
          title: lts('ui_density_label'),
          searchText: lts('ui_density_label'),
          child: GhSlider(
            display: Text('${(settings.uiDensity * 100).round()}%', style: lookValueStyle(theme, mono: true)),
            value: settings.uiDensity,
            min: 0.75,
            max: 1.25,
            step: 0.05,
            defaultValue: defaultUiDensity,
            onChanged: (value) => update(copySettings(settings, uiDensity: value)),
          ),
        ),
        SettingsSubsection(
          id: 'accessibility-text-size',
          inline: true,
          fill: true,
          title: lts('text_size_label'),
          searchText: lts('text_size_label'),
          child: GhSlider(
            display: Text('${(settings.fontScale * 100).round()}%', style: lookValueStyle(theme, mono: true)),
            value: settings.fontScale,
            min: 0.85,
            max: 1.3,
            step: 0.05,
            defaultValue: defaultFontScale,
            onChanged: (value) => update(copySettings(settings, fontScale: value)),
          ),
        ),
        SettingsSubsection(
          id: 'accessibility-screen-reader',
          inline: true,
          title: lts('screen_reader_label'),
          searchText: '${lts('screen_reader_label')} ${lts('accessibility')} ${lts('accessibility_desc')}',
          child: GhToggle(
            checked: settings.screenReaderAnnouncements,
            label: lts('screen_reader_label'),
            onChanged: (checked) => update(copySettings(settings, screenReaderAnnouncements: checked)),
          ),
        ),
        SettingsSubsection(
          id: 'accessibility-scrollbars',
          inline: true,
          title: lts('show_scrollbar_label'),
          searchText: lts('show_scrollbar_label'),
          child: GhToggle(
            checked: settings.showScrollbars,
            label: lts('show_scrollbar_label'),
            onChanged: (checked) => update(copySettings(settings, showScrollbars: checked)),
          ),
        ),
        SettingsSubsection(
          id: 'accessibility-tooltip-delay',
          inline: true,
          fill: true,
          title: lts('tooltip_delay_label'),
          searchText: lts('tooltip_delay_label'),
          child: GhSlider(
            display: Text(
              '${settings.tooltipDelay}ms',
              style: theme.text(size: GhTextSize.xs, color: theme.ink),
            ),
            value: settings.tooltipDelay.toDouble(),
            min: 100,
            max: 1000,
            step: 50,
            defaultValue: 350,
            onChanged: (value) => update(copySettings(settings, tooltipDelay: value.round())),
          ),
        ),
        SettingsSubsection(
          id: 'accessibility-sidebar-resize-knob',
          inline: true,
          title: lts('fixed_sidebar_resize_knob_label'),
          searchText: '${lts('fixed_sidebar_resize_knob_label')} ${lts('accessibility')} ${lts('accessibility_desc')}',
          child: GhToggle(
            checked: settings.fixedSidebarResizeKnob,
            label: lts('fixed_sidebar_resize_knob_label'),
            onChanged: (checked) => update(copySettings(settings, fixedSidebarResizeKnob: checked)),
          ),
        ),
      ],
    );
  }
}
