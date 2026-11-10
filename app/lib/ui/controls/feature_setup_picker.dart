import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import 'features.dart';
import 'keyframe.dart';
import 'strings.dart' as s;
import 'toggle.dart';

enum _Card { minimal, essentials, studio, complete, custom }

class GhFeatureSetupPicker extends StatefulWidget {
  const GhFeatureSetupPicker({super.key, required this.enabled, required this.onChanged, this.groupLabel = s.featuresTitle});

  final Set<GhFeatureId> enabled;
  final ValueChanged<Set<GhFeatureId>> onChanged;
  final String groupLabel;

  @override
  State<GhFeatureSetupPicker> createState() => _GhFeatureSetupPickerState();
}

class _GhFeatureSetupPickerState extends State<GhFeatureSetupPicker> {
  late bool _customizing = matchSetupProfile(widget.enabled) == null;

  void _pickProfile(GhSetupProfile profile) {
    setState(() => _customizing = false);
    widget.onChanged(profile.features.toSet());
  }

  void _pickCustom() => setState(() => _customizing = true);

  void _toggle(GhFeatureId id, bool on) {
    final next = {...widget.enabled};
    if (on) {
      next.add(id);
    } else {
      next.remove(id);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final matched = matchSetupProfile(widget.enabled);
    final selected = _customizing ? _Card.custom : (matched == null ? _Card.custom : _Card.values[matched.index]);
    final columns = MediaQuery.sizeOf(context).width >= theme.rem(80) ? 4 : 2;
    final gap = theme.space(2.5);
    final profiles = GhSetupProfile.values;
    final rows = <Widget>[];
    for (var i = 0; i < profiles.length; i += columns) {
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: gap));
      }
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) {
          cells.add(SizedBox(width: gap));
        }
        final index = i + c;
        cells.add(
          Expanded(
            child: index < profiles.length
                ? _ProfileCard(
                    profile: profiles[index],
                    active: selected.index == profiles[index].index,
                    onPressed: () => _pickProfile(profiles[index]),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }
      rows.add(
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
        ),
      );
    }

    final sectionLabel = theme.text(
      size: GhTextSize.x3s,
      weight: GhWeight.semibold,
      color: theme.muted.withValues(alpha: 0.7),
      letterSpacingEm: 0.025,
    );
    final rowGap = theme.space(1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: widget.groupLabel,
          container: true,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...rows,
              SizedBox(height: gap),
              _CustomCard(
                active: selected == _Card.custom,
                count: widget.enabled.length + GhCoreFeature.values.length,
                onPressed: _pickCustom,
              ),
            ],
          ),
        ),
        if (_customizing) ...[
          SizedBox(height: theme.space(4)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
            child: Text(s.featuresAlwaysOn.toUpperCase(), style: sectionLabel),
          ),
          for (final core in GhCoreFeature.values) ...[
            SizedBox(height: rowGap),
            _FeatureRow(icon: core.icon, label: core.label, description: core.description, checked: true),
          ],
          SizedBox(height: rowGap),
          Padding(
            padding: EdgeInsets.only(left: theme.space(1), right: theme.space(1), top: theme.space(2)),
            child: Text(s.featuresOptional.toUpperCase(), style: sectionLabel),
          ),
          for (final feature in GhFeatureId.values) ...[
            SizedBox(height: rowGap),
            _FeatureRow(
              icon: feature.icon,
              label: feature.label,
              description: feature.description,
              checked: widget.enabled.contains(feature),
              onChanged: (on) => _toggle(feature, on),
            ),
          ],
        ],
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.active, required this.onPressed});

  final GhSetupProfile profile;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    final included = profile.features.toSet();
    final chip = theme.space(5);
    final icon = theme.space(3);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        button: false,
        checked: active,
        semanticLabel: profile.label,
        builder: (context, states) {
          final hover = states.hovered && !active;
          return GhAnimatedBox(
            padding: EdgeInsets.all(theme.space(3.5)),
            borderRadius: radius,
            color: active
                ? theme.accent.withValues(alpha: 0.1)
                : (hover ? theme.overlay.withValues(alpha: 0.6) : theme.base.withValues(alpha: 0.4)),
            border: Border.all(color: active ? theme.accent : (hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5))),
            boxShadow: hover ? GhShadows.hoverLift() : const [],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.label,
                        style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                      ),
                    ),
                    SizedBox(width: theme.space(2)),
                    _RadioDot(active: active),
                  ],
                ),
                SizedBox(height: theme.space(2)),
                Text(
                  profile.description,
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
                SizedBox(height: theme.space(2)),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(1)),
                  child: ExcludeSemantics(
                    child: Wrap(
                      spacing: theme.space(1),
                      runSpacing: theme.space(1),
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final core in GhCoreFeature.values)
                          Container(
                            width: chip,
                            height: chip,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(theme.radiusTag),
                            ),
                            child: GhIcon(core.icon, size: icon, color: theme.accentBright),
                          ),
                        for (final feature in GhFeatureId.values)
                          Container(
                            width: chip,
                            height: chip,
                            alignment: Alignment.center,
                            decoration: included.contains(feature)
                                ? BoxDecoration(
                                    color: theme.overlay,
                                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(theme.radiusTag),
                                  )
                                : null,
                            child: GhIcon(
                              feature.icon,
                              size: icon,
                              color: included.contains(feature) ? theme.ink : theme.muted.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  const _CustomCard({required this.active, required this.count, required this.onPressed});

  final bool active;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        button: false,
        checked: active,
        semanticLabel: s.setupProfileCustom,
        builder: (context, states) {
          final hover = states.hovered && !active;
          final borderColor = active ? theme.accent : (hover ? theme.accentDim : theme.outline.withValues(alpha: 0.6));
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: borderColor),
            duration: GhDurations.interactive,
            curve: GhCurves.outExpo,
            builder: (context, color, child) => CustomPaint(
              foregroundPainter: _BorderPainter(color: color ?? borderColor, radius: radius, dashed: !active),
              child: child,
            ),
            child: GhAnimatedBox(
              padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(3)),
              borderRadius: radius,
              color: active
                  ? theme.accent.withValues(alpha: 0.1)
                  : (hover ? theme.overlay.withValues(alpha: 0.6) : theme.overlay.withValues(alpha: 0)),
              boxShadow: hover ? GhShadows.hoverLift() : const [],
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Row(
                  children: [
                    Container(
                      width: theme.space(8),
                      height: theme.space(8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusTile)),
                      child: GhIcon(GhIcons.pencil, size: theme.space(3.5), color: theme.muted),
                    ),
                    SizedBox(width: theme.space(3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.setupProfileCustom,
                            style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                          ),
                          Text(
                            s.setupProfileCustomDesc,
                            style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: theme.space(3)),
                    Text(
                      s.featuresEnabledCount(count),
                      style: theme
                          .text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    SizedBox(width: theme.space(3)),
                    _RadioDot(active: active),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.color, required this.radius, required this.dashed});

  final Color color;
  final BorderRadius radius;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size).deflate(0.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (!dashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      const dash = 3.0;
      final count = (metric.length / (dash * 2)).floor();
      if (count <= 0) {
        canvas.drawPath(path, paint);
        continue;
      }
      final period = metric.length / count;
      for (var i = 0; i < count; i++) {
        final start = i * period;
        canvas.drawPath(metric.extractPath(start, start + period / 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.dashed != dashed;
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.space(4.5);
    return GhKeyframe(
      active: active,
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) {
        final v = active ? GhCurves.spring.transform(t) : 1.0;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: v, child: child),
        );
      },
      child: GhAnimatedBox(
        width: size,
        height: size,
        duration: GhDurations.color,
        alignment: Alignment.center,
        color: active ? theme.accent : theme.accent.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: active ? theme.accent : theme.outline.withValues(alpha: 0.6)),
        child: active ? GhIcon(GhIcons.check, size: theme.space(2.5), color: Colors.white) : null,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label, required this.description, required this.checked, this.onChanged});

  final FaIconData icon;
  final String label;
  final String description;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
      decoration: BoxDecoration(
        color: theme.base.withValues(alpha: 0.4),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(theme.radiusItem),
      ),
      child: Row(
        children: [
          GhAnimatedBox(
            width: theme.space(8),
            height: theme.space(8),
            duration: GhDurations.color,
            alignment: Alignment.center,
            color: checked ? theme.accent.withValues(alpha: 0.1) : theme.overlay,
            borderRadius: BorderRadius.circular(theme.radiusTile),
            child: GhAnimatedIcon(icon, color: checked ? theme.accentBright : theme.muted, size: theme.space(3.5)),
          ),
          SizedBox(width: theme.space(3)),
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
          SizedBox(width: theme.space(3)),
          GhToggle(checked: checked, disabled: onChanged == null, onChanged: onChanged ?? (_) {}, label: label),
        ],
      ),
    );
  }
}
