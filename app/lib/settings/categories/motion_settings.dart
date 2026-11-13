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

class MotionSettings extends ConsumerWidget {
  const MotionSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    void update(AppSettings next) => ref.read(settingsProvider.notifier).save(next).ignore();
    final off = settings.animationIntensity == 'none';
    Widget toggle(String id, String key, bool checked, AppSettings Function(bool) apply) => SettingsSubsection(
      id: id,
      inline: true,
      title: lts(key),
      searchText: lts(key),
      child: GhToggle(checked: checked, label: lts(key), disabled: off, onChanged: (value) => update(apply(value))),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'motion-intensity',
          inline: true,
          title: lts('animation_intensity_label'),
          searchText: '${lts('animation_intensity_label')} ${lts('animation_full')} ${lts('animation_subtle')} ${lts('animation_none')}',
          child: GhSegmented(
            value: settings.animationIntensity,
            onChanged: (value) => update(copySettings(settings, animationIntensity: value)),
            options: [
              ghSegment('full', lts('animation_full')),
              ghSegment('subtle', lts('animation_subtle')),
              ghSegment('none', lts('animation_none')),
            ],
          ),
        ),
        SettingsSubsection(
          id: 'motion-speed',
          inline: true,
          fill: true,
          title: lts('animation_speed_label'),
          searchText: lts('animation_speed_label'),
          child: GhSlider(
            display: Text('${settings.animationSpeed.toStringAsFixed(1)}×', style: lookValueStyle(theme, mono: true)),
            value: settings.animationSpeed,
            min: 0.5,
            max: 2,
            step: 0.1,
            defaultValue: 1.5,
            onChanged: (value) => update(copySettings(settings, animationSpeed: value)),
          ),
        ),
        SettingsSubsection(
          id: 'motion-view-entrance',
          inline: true,
          title: lts('view_entrance_label'),
          searchText:
              '${lts('view_entrance_label')} ${lts('entrance_fade')} ${lts('entrance_slide')} ${lts('entrance_scale')} ${lts('entrance_none')}',
          child: GhSegmented(
            value: settings.viewEntrance,
            onChanged: (value) => update(copySettings(settings, viewEntrance: value)),
            options: [
              ghSegment('slide', lts('entrance_slide')),
              ghSegment('fade', lts('entrance_fade')),
              ghSegment('scale', lts('entrance_scale')),
              ghSegment('none', lts('entrance_none')),
            ],
          ),
        ),
        toggle(
          'motion-scroll-reveal',
          'scroll_reveal_label',
          settings.motionScrollReveal,
          (v) => copySettings(settings, motionScrollReveal: v),
        ),
        SettingsSubsection(
          id: 'motion-animation-threshold',
          inline: true,
          fill: true,
          title: lts('animation_threshold_label'),
          searchText: lts('animation_threshold_label'),
          child: GhSlider(
            display: Text(lts('n_projects', count: settings.animationThreshold), style: lookValueStyle(theme)),
            value: settings.animationThreshold.toDouble(),
            min: 10,
            max: 100,
            step: 5,
            defaultValue: 20,
            onChanged: (value) => update(copySettings(settings, animationThreshold: value.round())),
          ),
        ),
        toggle(
          'motion-click-ripple',
          'click_ripple_label',
          settings.motionClickRipple,
          (v) => copySettings(settings, motionClickRipple: v),
        ),
        toggle(
          'motion-press-bounce',
          'press_bounce_label',
          settings.motionPressBounce,
          (v) => copySettings(settings, motionPressBounce: v),
        ),
        toggle(
          'motion-animated-numbers',
          'animated_numbers_label',
          settings.animatedNumbers,
          (v) => copySettings(settings, animatedNumbers: v),
        ),
      ],
    );
  }
}
