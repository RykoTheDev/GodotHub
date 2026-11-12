import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/design.dart';
import '../../logic/settings_copy.dart';
import '../../modals/theme_presets_modal.dart';
import '../../src/rust/api/types.dart';
import '../../state/app_lifecycle.dart';
import '../../state/settings.dart';
import '../../ui/controls/slider.dart';
import '../../ui/controls/text_input.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/core/interaction.dart';
import '../../ui/feedback/modal_shell.dart';
import '../../ui/shell/color_swatch_picker.dart';
import '../settings_parts.dart';
import 'look_parts.dart';


GhThemeMode resolvedMode(AppSettings settings) => resolveThemeMode(settings.themeMode, ghPlatformBrightness());

AppSettings withThemeMode(AppSettings settings, String mode) {
  final targetDark = resolveThemeMode(mode, ghPlatformBrightness()) == GhThemeMode.dark;
  final background = isDarkColor(settings.backgroundColor) == targetDark
      ? settings.backgroundColor
      : (targetDark ? defaultBackground : defaultBackgroundLight);
  return copySettings(settings, themeMode: mode, backgroundColor: background);
}

AppSettings withCustomTheme(AppSettings settings) {
  final defaults = customThemeDefaults(resolvedMode(settings));
  return copySettings(settings, themePreset: 'custom', accentColor: defaults.accentColor, backgroundColor: defaults.backgroundColor);
}

AppSettings? withPreset(AppSettings settings, String id) {
  if (id == settings.themePreset) return null;
  if (id == 'custom') return withCustomTheme(settings);
  final preset = themePreset(id);
  if (preset == null) return null;
  return copySettings(settings, themePreset: id, themeMode: preset.mode.name);
}

AppSettings withThemeColorsReset(AppSettings settings) {
  final defaults = customThemeDefaults(resolvedMode(settings));
  return copySettings(settings, accentColor: defaults.accentColor, backgroundColor: defaults.backgroundColor);
}

AppSettings withAppearanceReset(AppSettings settings) {
  final defaults = customThemeDefaults(resolvedMode(settings));
  return copySettings(
    settings,
    accentColor: defaults.accentColor,
    backgroundColor: defaults.backgroundColor,
    cornerRadius: defaultCornerRadius,
    uiDensity: defaultUiDensity,
    fontScale: defaultFontScale,
    themeMode: 'dark',
    customCss: '',
    animationIntensity: 'full',
    viewEntrance: 'fade',
    projectIconOpacity: defaultProjectIconOpacity.round(),
    projectCardStyle: 'hub',
    raisedContrast: defaultRaisedContrast,
    themePreset: 'custom',
  );
}

class AppearanceSettings extends ConsumerStatefulWidget {
  const AppearanceSettings({super.key});

  @override
  ConsumerState<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends ConsumerState<AppearanceSettings> {
  late final TextEditingController _css = TextEditingController(text: ref.read(settingsProvider).value?.customCss ?? '');
  bool _applied = false;
  Timer? _appliedTimer;

  @override
  void dispose() {
    _appliedTimer?.cancel();
    _css.dispose();
    super.dispose();
  }

  void _update(AppSettings next) => ref.read(settingsProvider.notifier).save(next).ignore();

  void _flashApplied() {
    _appliedTimer?.cancel();
    setState(() => _applied = true);
    _appliedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _applied = false);
    });
  }

  void _openPresets(GhThemeMode mode, AppSettings settings) {
    showGhModal<void>(
      context,
      (modal) => Consumer(
        builder: (context, ref, _) => ThemePresetsModal(
          mode: mode,
          currentId: ref.watch(settingsProvider.select((s) => s.value?.themePreset)) ?? settings.themePreset,
          onSelect: (id) {
            final current = ref.read(settingsProvider).value ?? settings;
            final next = withPreset(current, id);
            if (next != null) _update(next);
          },
          onClose: () => Navigator.of(modal).pop(),
        ),
      ),
    ).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    ref.listen(settingsProvider.select((s) => s.value?.customCss), (previous, next) {
      if (next != null && next != _css.text) _css.text = next;
    });
    final custom = settings.themePreset == 'custom';
    final light = resolvedMode(settings) == GhThemeMode.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'appearance-presets',
          title: lts('theme_preset_label'),
          searchText: '${lts('theme_preset_label')} ${lts('theme_preset_custom')} ${lts('preset_light_group')} ${lts('preset_dark_group')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(4),
                children: [
                  for (final (mode, label, icon, count) in [
                    (GhThemeMode.light, lts('preset_light_group'), GhIcons.sun, lightThemePresets.length),
                    (GhThemeMode.dark, lts('preset_dark_group'), GhIcons.moon, darkThemePresets.length),
                  ])
                    _PresetGroupButton(
                      key: ValueKey('preset-group:${mode.name}'),
                      icon: icon,
                      label: label,
                      count: count,
                      onPressed: () => _openPresets(mode, settings),
                    ),
                  _PresetGroupButton(
                    key: const ValueKey('preset-custom'),
                    icon: GhIcons.palette,
                    label: lts('theme_preset_custom'),
                    selected: custom,
                    onPressed: () => _update(withCustomTheme(settings)),
                  ),
                ],
              ),
              if (custom)
                Container(
                  padding: EdgeInsets.only(top: theme.space(4)),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(3),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: theme.space(2),
                        children: [
                          Text(lts('theme'), style: lookLabelStyle(theme)),
                          Wrap(
                            spacing: theme.space(2),
                            runSpacing: theme.space(2),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GhSegmented(
                                value: settings.themeMode,
                                onChanged: (mode) => _update(withThemeMode(settings, mode)),
                                options: [
                                  ghSegment('dark', lts('theme_dark')),
                                  ghSegment('light', lts('theme_light')),
                                  ghSegment('system', lts('system')),
                                ],
                              ),
                              LookGhostButton(
                                icon: GhIcons.heart,
                                label: lts('reset'),
                                semanticLabel: lts('reset_colors'),
                                onPressed: () => _update(withThemeColorsReset(settings)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: theme.space(8),
                        runSpacing: theme.space(4),
                        children: [
                          GhColorSwatchPicker(
                            label: lts('setting_accent_color'),
                            value: settings.accentColor,
                            presets: light ? accentPresetsLight : accentPresetsDark,
                            onChanged: (hex) => _update(copySettings(settings, accentColor: hex)),
                          ),
                          GhColorSwatchPicker(
                            label: lts('setting_background_color'),
                            value: settings.backgroundColor,
                            presets: light ? bgPresetsLight : bgPresetsDark,
                            onChanged: (hex) => _update(copySettings(settings, backgroundColor: hex)),
                          ),
                        ],
                      ),
                      GhSlider(
                        label: lts('raised_contrast_label'),
                        display: Text(
                          lts('raised_contrast_value', args: {'value': settings.raisedContrast}),
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                        ),
                        value: settings.raisedContrast.toDouble(),
                        min: 0,
                        max: 40,
                        step: 1,
                        defaultValue: defaultRaisedContrast.toDouble(),
                        onChanged: (value) => _update(copySettings(settings, raisedContrast: value.round())),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SettingsSubsection(
          id: 'appearance-radius',
          inline: true,
          fill: true,
          title: lts('onboarding_corner_radius'),
          searchText: lts('onboarding_corner_radius'),
          child: GhSlider(
            display: Text('${formatSettingNumber(settings.cornerRadius)}px', style: lookValueStyle(theme, mono: true)),
            value: settings.cornerRadius,
            min: 0,
            max: 20,
            step: 1,
            defaultValue: defaultCornerRadius,
            onChanged: (value) => _update(copySettings(settings, cornerRadius: value)),
          ),
        ),
        SettingsSubsection(
          id: 'appearance-layout',
          inline: true,
          title: lts('card_layout_label'),
          searchText: lts('card_layout_label'),
          child: GhToggle(
            checked: settings.cardLayout,
            label: lts('card_layout_label'),
            onChanged: (checked) => _update(copySettings(settings, cardLayout: checked)),
          ),
        ),
        SettingsSubsection(
          id: 'appearance-card-style',
          inline: true,
          title: lts('project_card_style_label'),
          searchText: '${lts('project_card_style_label')} ${lts('project_card_style_hub')} ${lts('project_card_style_cover')}',
          child: GhSegmented(
            value: settings.projectCardStyle,
            onChanged: (value) => _update(copySettings(settings, projectCardStyle: value)),
            options: [ghSegment('hub', lts('project_card_style_hub')), ghSegment('cover', lts('project_card_style_cover'))],
          ),
        ),
        SettingsSubsection(
          id: 'appearance-icon-opacity',
          inline: true,
          fill: true,
          title: lts('project_icon_opacity_label'),
          searchText: lts('project_icon_opacity_label'),
          child: GhSlider(
            display: Text('${settings.projectIconOpacity}%', style: lookValueStyle(theme, mono: true)),
            value: settings.projectIconOpacity.toDouble(),
            min: 0,
            max: 50,
            step: 1,
            defaultValue: defaultProjectIconOpacity,
            onChanged: (value) => _update(copySettings(settings, projectIconOpacity: value.round())),
          ),
        ),
        SettingsSubsection(
          id: 'appearance-css',
          title: lts('custom_css_label'),
          searchText: '${lts('custom_css_label')} ${lts('custom_css_apply')} ${lts('clear')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              GhTextInput(
                controller: _css,
                mono: true,
                size: GhTextSize.xs,
                minLines: 8,
                maxLines: 8,
                placeholder: lts('custom_css_placeholder'),
                semanticLabel: lts('custom_css_label'),
                background: theme.base,
                borderColor: theme.outline.withValues(alpha: 0.5),
                focusBorderColor: theme.accentDim,
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                onChanged: (_) {
                  if (_applied) setState(() => _applied = false);
                },
              ),
              Row(
                spacing: theme.space(2),
                children: [
                  LookSolidButton(
                    label: lts('custom_css_apply'),
                    onPressed: () {
                      _update(copySettings(settings, customCss: _css.text));
                      _flashApplied();
                    },
                  ),
                  if (settings.customCss.isNotEmpty)
                    LookOutlineButton(
                      label: lts('clear'),
                      onPressed: () {
                        _css.text = '';
                        _update(copySettings(settings, customCss: ''));
                        _flashApplied();
                      },
                    ),
                  if (_applied)
                    Text(
                      lts('custom_css_applied'),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.mint),
                    ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LookOutlineButton(
            icon: GhIcons.refresh,
            label: lts('reset_appearance'),
            paddingX: 4,
            paddingY: 2,
            onPressed: () {
              _css.text = '';
              _update(withAppearanceReset(settings));
            },
          ),
        ),
      ],
    );
  }
}

class _PresetGroupButton extends StatelessWidget {
  const _PresetGroupButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.count,
    this.selected = false,
  });

  final FaIconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      selected: count == null ? selected : null,
      builder: (context, states) {
        final hover = states.highlighted && !selected;
        return GhAnimatedBox(
          padding: EdgeInsets.all(theme.space(4)),
          color: selected ? theme.accent.withValues(alpha: 0.1) : (hover ? theme.raised : theme.raised.withValues(alpha: 0)),
          borderRadius: radius,
          border: Border.all(color: selected ? theme.accent : (hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5))),
          child: Row(
            spacing: theme.space(3),
            children: [
              GhIcon(icon, size: theme.space(4), color: theme.muted),
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.6)),
                ),
              const Spacer(),
              if (selected)
                GhIcon(GhIcons.check, size: theme.space(3.5), color: theme.accentBright)
              else
                Transform.rotate(
                  angle: rtl ? 1.5707963267948966 : -1.5707963267948966,
                  child: GhIcon(GhIcons.chevronDown, size: theme.space(3.5), color: theme.muted),
                ),
            ],
          ),
        );
      },
    );
  }
}
