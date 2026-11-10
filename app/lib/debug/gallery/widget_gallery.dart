import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../i18n/i18n.dart';
import '../../i18n/i18n_controller.dart';
import '../../i18n/languages.dart';
import '../../motion/motion.dart';
import '../../ui/core/interaction.dart';
import 'gallery_kit.dart';
import 'sections/controls.dart';
import 'sections/feedback.dart';
import 'sections/foundation.dart';
import 'sections/motion_numbers.dart';
import 'sections/motion_presence.dart';
import 'sections/motion_reveal.dart';
import 'sections/overlays.dart';
import 'sections/shell.dart';

List<GallerySection> get allGallerySections => [
  ...foundationSections,
  ...controlsSections,
  ...overlaysSections,
  ...feedbackSections,
  ...shellSections,
  ...motionPresenceSections,
  ...motionRevealSections,
  ...motionNumbersSections,
];

class GalleryConfig {
  const GalleryConfig({
    this.presetId = 'custom',
    this.mode = 'dark',
    this.accent = defaultAccent,
    this.background = defaultBackground,
    this.raisedContrast = 8,
    this.cornerRadius = defaultCornerRadius,
    this.uiDensity = defaultUiDensity,
    this.fontScale = defaultFontScale,
    this.rtl = false,
    this.motion = const GhMotionPrefs(),
    this.reducedMotion = false,
  });

  final String presetId;
  final String mode;
  final String accent;
  final String background;
  final double raisedContrast;
  final double cornerRadius;
  final double uiDensity;
  final double fontScale;
  final bool rtl;
  final GhMotionPrefs motion;
  final bool reducedMotion;

  GhTheme theme(Brightness platform) => GhTheme.fromSettings(
    accentColor: accent,
    backgroundColor: background,
    themeMode: mode,
    themePreset: presetId,
    raisedContrast: raisedContrast,
    cornerRadius: cornerRadius,
    uiDensity: uiDensity,
    fontScale: fontScale,
    projectIconOpacity: defaultProjectIconOpacity,
    showScrollbars: true,
    platformBrightness: platform,
  );

  GalleryConfig copyWith({
    String? presetId,
    String? mode,
    String? accent,
    String? background,
    double? raisedContrast,
    double? cornerRadius,
    double? uiDensity,
    double? fontScale,
    bool? rtl,
    GhMotionPrefs? motion,
    bool? reducedMotion,
  }) {
    return GalleryConfig(
      presetId: presetId ?? this.presetId,
      mode: mode ?? this.mode,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      raisedContrast: raisedContrast ?? this.raisedContrast,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      uiDensity: uiDensity ?? this.uiDensity,
      fontScale: fontScale ?? this.fontScale,
      rtl: rtl ?? this.rtl,
      motion: motion ?? this.motion,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }
}

class WidgetGallery extends StatefulWidget {
  const WidgetGallery({super.key, this.initialSection, this.initialConfig = const GalleryConfig(), this.onClose});

  final String? initialSection;
  final GalleryConfig initialConfig;
  final VoidCallback? onClose;

  @override
  State<WidgetGallery> createState() => _WidgetGalleryState();
}

class _WidgetGalleryState extends State<WidgetGallery> {
  late GalleryConfig _config = widget.initialConfig;
  late int _index = _initialIndex();

  int _initialIndex() {
    final index = allGallerySections.indexWhere((s) => s.title == widget.initialSection);
    return index < 0 ? 0 : index;
  }

  void _update(GalleryConfig config) => setState(() => _config = config);

  @override
  Widget build(BuildContext context) {
    final theme = _config.theme(MediaQuery.platformBrightnessOf(context));
    final sections = allGallerySections;
    final section = sections[_index.clamp(0, sections.length - 1)];
    return AnimatedTheme(
      data: theme.toThemeData(),
      duration: GhDurations.color,
      curve: GhCurves.outExpo,
      child: Builder(
        builder: (context) {
          final t = GhTheme.of(context);
          return GhMotion(
            prefs: _config.motion,
            osReduced: _config.reducedMotion ? true : null,
            child: Directionality(
              textDirection: _config.rtl ? TextDirection.rtl : TextDirection.ltr,
              child: ColoredBox(
                color: t.base,
                child: DefaultTextStyle(
                  style: t.text(size: GhTextSize.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Nav(sections: sections, index: _index, onSelect: (i) => setState(() => _index = i), onClose: widget.onClose),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Controls(config: _config, onChanged: _update),
                            Expanded(
                              child: SingleChildScrollView(
                                key: PageStorageKey(section.title),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.title,
                                      style: t.text(size: GhTextSize.x2l, weight: GhWeight.semibold),
                                    ),
                                    const SizedBox(height: 16),
                                    Builder(builder: section.builder),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.sections, required this.index, required this.onSelect, this.onClose});

  final List<GallerySection> sections;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = GhTheme.of(context);
    return Container(
      width: 220,
      color: t.surface,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Widget gallery',
                    style: t.text(size: GhTextSize.sm, weight: GhWeight.semibold),
                  ),
                ),
                if (onClose != null)
                  GhPressable(
                    onPressed: onClose,
                    semanticLabel: 'Close gallery',
                    builder: (context, states) => GhIcon(GhIcons.x, size: 14, color: states.hovered ? t.ink : t.muted),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < sections.length; i++)
            GhPressable(
              onPressed: () => onSelect(i),
              borderRadius: BorderRadius.circular(t.radiusMd),
              selected: i == index,
              builder: (context, states) => GhAnimatedBox(
                color: i == index ? t.accent.withValues(alpha: 0.15) : (states.hovered ? t.raised : t.raised.withValues(alpha: 0)),
                borderRadius: BorderRadius.circular(t.radiusMd),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Text(
                  sections[i].title,
                  style: t.text(size: GhTextSize.xs, weight: GhWeight.medium, color: i == index ? t.ink : t.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.config, required this.onChanged});

  final GalleryConfig config;
  final ValueChanged<GalleryConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = GhTheme.of(context);
    final mode = GhThemeMode.parse(config.mode);
    final accents = mode == GhThemeMode.light ? accentPresetsLight : accentPresetsDark;
    final backgrounds = mode == GhThemeMode.light ? bgPresetsLight : bgPresetsDark;
    Widget chip(String label, bool selected, VoidCallback onTap) => GhPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(t.radiusTag),
      builder: (context, states) => GhAnimatedBox(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: selected ? t.accent : (states.hovered ? t.raised : t.surface),
        borderRadius: BorderRadius.circular(t.radiusTag),
        child: Text(
          label,
          style: t.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: selected ? Colors.white : t.muted),
        ),
      ),
    );
    Widget swatch(String hex, bool selected, VoidCallback onTap) => GhPressable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(99),
      builder: (context, states) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: colorFromHex(hex),
          shape: BoxShape.circle,
          border: Border.all(color: selected ? t.ink : t.line, width: selected ? 2 : 1),
        ),
      ),
    );
    Widget slider(String label, double value, double min, double max, int divisions, ValueChanged<double> onChange) => SizedBox(
      width: 190,
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label ${value.toStringAsFixed(2)}',
              style: t.text(size: GhTextSize.x3s, color: t.muted),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: t.accent,
                inactiveTrackColor: t.line,
                thumbColor: t.ink,
              ),
              child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChange),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          chip('Custom', config.presetId == 'custom', () => onChanged(config.copyWith(presetId: 'custom'))),
          for (final preset in themePresets)
            chip(preset.name, config.presetId == preset.id, () => onChanged(config.copyWith(presetId: preset.id, mode: preset.mode.name))),
          chip(
            'dark',
            config.mode == 'dark',
            () => onChanged(config.copyWith(mode: 'dark', background: isDarkColor(config.background) ? null : defaultBackground)),
          ),
          chip(
            'light',
            config.mode == 'light',
            () => onChanged(config.copyWith(mode: 'light', background: isDarkColor(config.background) ? defaultBackgroundLight : null)),
          ),
          chip('RTL', config.rtl, () => onChanged(config.copyWith(rtl: !config.rtl))),
          for (final language in ghLanguages.where((l) => !l.isSystem))
            chip(language.value, GhI18n.instance.language == language.value, () {
              GhI18n.instance.setLanguageSetting(language.value);
              onChanged(config.copyWith(rtl: ghTextDirectionOf(language.value) == TextDirection.rtl ? config.rtl : false));
            }),
          Wrap(
            spacing: 4,
            children: [
              for (final hex in accents)
                swatch(hex, hex == config.accent, () => onChanged(config.copyWith(accent: hex, presetId: 'custom'))),
            ],
          ),
          Wrap(
            spacing: 4,
            children: [
              for (final hex in backgrounds)
                swatch(hex, hex == config.background, () => onChanged(config.copyWith(background: hex, presetId: 'custom'))),
            ],
          ),
          slider('radius', config.cornerRadius, 0, 20, 20, (v) => onChanged(config.copyWith(cornerRadius: v))),
          slider('density', config.uiDensity, 0.75, 1.25, 10, (v) => onChanged(config.copyWith(uiDensity: v))),
          slider('text', config.fontScale, 0.85, 1.3, 9, (v) => onChanged(config.copyWith(fontScale: v))),
          slider('raised', config.raisedContrast, 0, 40, 40, (v) => onChanged(config.copyWith(raisedContrast: v))),
          for (final intensity in GhMotionIntensity.values)
            chip(
              'motion ${intensity.name}',
              config.motion.intensity == intensity,
              () => onChanged(config.copyWith(motion: config.motion.copyWith(intensity: intensity))),
            ),
          for (final entrance in GhViewEntrance.values)
            chip(
              'entrance ${entrance.name}',
              config.motion.entrance == entrance,
              () => onChanged(config.copyWith(motion: config.motion.copyWith(entrance: entrance))),
            ),
          slider('speed', config.motion.speed, 0.5, 2, 15, (v) => onChanged(config.copyWith(motion: config.motion.copyWith(speed: v)))),
          chip('OS reduced motion', config.reducedMotion, () => onChanged(config.copyWith(reducedMotion: !config.reducedMotion))),
          chip(
            'scroll reveal',
            config.motion.scrollReveal,
            () => onChanged(config.copyWith(motion: config.motion.copyWith(scrollReveal: !config.motion.scrollReveal))),
          ),
          chip('tilt', config.motion.tilt, () => onChanged(config.copyWith(motion: config.motion.copyWith(tilt: !config.motion.tilt)))),
          chip(
            'ripple',
            config.motion.ripple,
            () => onChanged(config.copyWith(motion: config.motion.copyWith(ripple: !config.motion.ripple))),
          ),
          chip('press', config.motion.press, () => onChanged(config.copyWith(motion: config.motion.copyWith(press: !config.motion.press)))),
          chip(
            'numbers',
            config.motion.animatedNumbers,
            () => onChanged(config.copyWith(motion: config.motion.copyWith(animatedNumbers: !config.motion.animatedNumbers))),
          ),
        ],
      ),
    );
  }
}
