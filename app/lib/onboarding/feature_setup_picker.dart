import 'package:flutter/material.dart';

import '../design/design.dart';
import '../logic/features.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

String _ts(String key, {num? count}) => ghTr('settings:$key', count: count);

String featureLabel(String id) {
  for (final core in GhCoreFeature.values) {
    if (core.id == id) return core.label();
  }
  return GhFeatureId.fromId(id)?.label() ?? id;
}

class FeatureSetupPicker extends StatefulWidget {
  const FeatureSetupPicker({super.key, required this.value, required this.onChanged});

  final AppSettings value;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<FeatureSetupPicker> createState() => _FeatureSetupPickerState();
}

class _FeatureSetupPickerState extends State<FeatureSetupPicker> {
  late bool _customizing = matchSetupProfile(enabledFeatures(widget.value)) == null;

  void _pick(GhSetupProfile? profile) {
    if (profile == null) {
      setState(() => _customizing = true);
      return;
    }
    setState(() => _customizing = false);
    widget.onChanged(withFeatures(widget.value, profile.features));
  }

  void _toggle(GhFeatureId id, bool on) {
    final next = {...enabledFeatures(widget.value)};
    if (on) {
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.onChanged(withFeatures(widget.value, next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final enabled = enabledFeatures(widget.value);
    final matched = matchSetupProfile(enabled);
    final selected = _customizing ? null : matched;
    final wide = MediaQuery.sizeOf(context).width >= 1280;
    final columns = wide ? 4 : 2;
    final gap = theme.space(2.5);
    final profiles = GhSetupProfile.values;
    final rows = <List<GhSetupProfile>>[
      for (var i = 0; i < profiles.length; i += columns) profiles.sublist(i, (i + columns).clamp(0, profiles.length)),
    ];
    final customActive = selected == null;
    final itemRadius = BorderRadius.circular(theme.radiusItem);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [
        Semantics(
          label: _ts('features_title'),
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              for (final row in rows)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: gap,
                    children: [
                      for (final profile in row) Expanded(child: _profileCard(theme, profile, selected == profile)),
                      for (var i = row.length; i < columns; i++) const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
              GhPressable(
                onPressed: () => _pick(null),
                checked: customActive,
                semanticLabel: _ts('setup_profile_custom'),
                borderRadius: itemRadius,
                builder: (context, states) {
                  final body = GhAnimatedBox(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(3)),
                    color: customActive
                        ? theme.accent.withValues(alpha: 0.1)
                        : (states.highlighted ? theme.overlay.withValues(alpha: 0.6) : Colors.transparent),
                    borderRadius: itemRadius,
                    border: customActive ? Border.all(color: theme.accent) : null,
                    child: Row(
                      spacing: theme.space(3),
                      children: [
                        Container(
                          width: theme.space(8),
                          height: theme.space(8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusTile)),
                          child: GhIcon(GhIcons.pencil, size: theme.space(3.5), color: theme.muted),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ts('setup_profile_custom'),
                                style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                              ),
                              Text(
                                _ts('setup_profile_custom_desc'),
                                style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _ts('features_enabled_count', count: enabled.length + GhCoreFeature.values.length),
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted),
                        ),
                        _RadioDot(active: customActive),
                      ],
                    ),
                  );
                  if (customActive) return body;
                  return GhDashedBox(
                    color: states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.6),
                    radius: itemRadius,
                    child: body,
                  );
                },
              ),
            ],
          ),
        ),
        if (_customizing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(1.5),
            children: [
              _groupLabel(theme, _ts('features_always_on')),
              for (final core in GhCoreFeature.values)
                _FeatureRow(icon: core.icon, label: core.label(), description: core.description(), checked: true, disabled: true),
              Padding(
                padding: EdgeInsets.only(top: theme.space(2)),
                child: _groupLabel(theme, _ts('features_optional')),
              ),
              for (final feature in GhFeatureId.values)
                _FeatureRow(
                  icon: feature.icon,
                  label: feature.label(),
                  description: feature.description(),
                  checked: enabled.contains(feature),
                  onChanged: (on) => _toggle(feature, on),
                ),
            ],
          ),
      ],
    );
  }

  Widget _groupLabel(GhTheme theme, String text) => Padding(
    padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
    child: Text(
      text.toUpperCase(),
      style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted.withValues(alpha: 0.7), letterSpacingEm: 0.025),
    ),
  );

  Widget _profileCard(GhTheme theme, GhSetupProfile profile, bool active) {
    final included = profile.features.toSet();
    final radius = BorderRadius.circular(theme.radiusItem);
    final iconBox = theme.space(5);
    return GhPressable(
      key: ValueKey('profile:${profile.id}'),
      onPressed: () => _pick(profile),
      checked: active,
      semanticLabel: profile.label(),
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.all(theme.space(3.5)),
        color: active
            ? theme.accent.withValues(alpha: 0.1)
            : (states.highlighted ? theme.overlay.withValues(alpha: 0.6) : theme.base.withValues(alpha: 0.4)),
        borderRadius: radius,
        border: Border.all(color: active ? theme.accent : (states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(2),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.label(),
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                  ),
                ),
                _RadioDot(active: active),
              ],
            ),
            Text(
              profile.description(),
              style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
            ),
            const Spacer(),
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.only(top: theme.space(1)),
                child: Wrap(
                  spacing: theme.space(1),
                  runSpacing: theme.space(1),
                  children: [
                    for (final core in GhCoreFeature.values)
                      Container(
                        width: iconBox,
                        height: iconBox,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(theme.radiusTag),
                        ),
                        child: GhIcon(core.icon, size: theme.space(3), color: theme.accentBright),
                      ),
                    for (final feature in GhFeatureId.values)
                      Container(
                        width: iconBox,
                        height: iconBox,
                        alignment: Alignment.center,
                        decoration: included.contains(feature)
                            ? BoxDecoration(
                                color: theme.overlay,
                                borderRadius: BorderRadius.circular(theme.radiusTag),
                                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                              )
                            : null,
                        child: GhIcon(
                          feature.icon,
                          size: theme.space(3),
                          color: included.contains(feature) ? theme.ink : theme.muted.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.space(4.5);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? theme.accent : null,
        border: Border.all(color: active ? theme.accent : theme.outline.withValues(alpha: 0.6)),
      ),
      child: active ? GhIcon(GhIcons.check, size: theme.space(2.5), color: Colors.white) : null,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.checked,
    this.disabled = false,
    this.onChanged,
  });

  final FaIconData icon;
  final String label;
  final String description;
  final bool checked;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
      decoration: BoxDecoration(
        color: theme.base.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        spacing: theme.space(3),
        children: [
          Container(
            width: theme.space(8),
            height: theme.space(8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: checked ? theme.accent.withValues(alpha: 0.1) : theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusTile),
            ),
            child: GhIcon(icon, size: theme.space(3.5), color: checked ? theme.accentBright : theme.muted),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                ),
                Text(
                  description,
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
              ],
            ),
          ),
          GhToggle(checked: checked, disabled: disabled, label: label, onChanged: (next) => onChanged?.call(next)),
        ],
      ),
    );
  }
}
