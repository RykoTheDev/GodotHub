import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';

class ThemePresetPreview extends StatelessWidget {
  const ThemePresetPreview({super.key, required this.preset});

  final ThemePreset preset;

  @override
  Widget build(BuildContext context) {
    Color c(String hex) => colorFromHex(hex);
    final line = c(preset.line);
    final surface = c(preset.surface);
    Widget dot(String hex, double size, {bool ring = false}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c(hex),
        shape: BoxShape.circle,
        border: ring ? Border.all(color: Colors.black.withValues(alpha: 0.2)) : null,
      ),
    );
    Widget bar(String hex, {double? width, double height = 4}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: c(hex), borderRadius: BorderRadius.circular(999)),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c(preset.base),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: line)),
            ),
            child: Row(
              spacing: 4,
              children: [dot(preset.danger, 6), dot(preset.amber, 6), dot(preset.mint, 6), const Spacer(), bar(preset.line, width: 28)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(3)),
                  child: Column(
                    spacing: 4,
                    children: [bar(preset.accent, width: 8), bar(preset.line, width: 8), bar(preset.line, width: 8)],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: c(preset.raised),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: line),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              bar(preset.ink, width: constraints.maxWidth * 0.75),
                              bar(preset.muted, width: constraints.maxWidth * 0.5),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        spacing: 4,
                        children: [
                          Expanded(child: bar(preset.line)),
                          Container(
                            width: 12,
                            height: 8,
                            decoration: BoxDecoration(color: c(preset.accent), borderRadius: BorderRadius.circular(2)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: line)),
            ),
            child: Row(
              spacing: 6,
              children: [
                dot(preset.accent, 8, ring: true),
                dot(preset.accentBright, 8, ring: true),
                dot(preset.mint, 8, ring: true),
                dot(preset.amber, 8, ring: true),
                dot(preset.danger, 8, ring: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemePresetsModal extends StatelessWidget {
  const ThemePresetsModal({super.key, required this.mode, required this.currentId, required this.onSelect, required this.onClose});

  final GhThemeMode mode;
  final String currentId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final light = mode == GhThemeMode.light;
    final presets = light ? lightThemePresets : darkThemePresets;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhModalShell(
      icon: GhIcon(light ? GhIcons.sun : GhIcons.moon, size: theme.space(5), color: theme.accentBright),
      title: ghTr(light ? 'settings:preset_light_group' : 'settings:preset_dark_group'),
      maxWidth: GhModalWidth.x2l,
      onClose: onClose,
      child: Padding(
        padding: EdgeInsets.all(theme.space(4)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = theme.space(2);
            final columns = ((constraints.maxWidth + gap) / (170 + gap)).floor().clamp(1, 99);
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final preset in presets)
                  SizedBox(
                    width: width,
                    child: GhPressable(
                      key: ValueKey(preset.id),
                      onPressed: () => onSelect(preset.id),
                      selected: preset.id == currentId,
                      semanticLabel: preset.name,
                      excludeChildSemantics: true,
                      borderRadius: radius,
                      builder: (context, states) {
                        final active = preset.id == currentId;
                        return GhAnimatedBox(
                          padding: EdgeInsets.all(theme.space(3)),
                          color: active ? theme.accent.withValues(alpha: 0.1) : (states.highlighted ? theme.raised : Colors.transparent),
                          borderRadius: radius,
                          border: Border.all(
                            color: active ? theme.accent : (states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: theme.space(2),
                            children: [
                              ThemePresetPreview(preset: preset),
                              Row(
                                spacing: theme.space(1),
                                children: [
                                  if (active) GhIcon(GhIcons.check, size: theme.space(3), color: theme.accentBright),
                                  Expanded(
                                    child: Text(
                                      preset.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
