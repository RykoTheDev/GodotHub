import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/shared.dart';
import '../core/interaction.dart';

typedef GhSegmentedOption = ({String value, String label, bool mono});

GhSegmentedOption ghSegment(String value, String label, {bool mono = false}) => (value: value, label: label, mono: mono);

class GhSegmented extends StatefulWidget {
  const GhSegmented({super.key, required this.value, required this.options, required this.onChanged});

  final String value;
  final List<GhSegmentedOption> options;
  final ValueChanged<String> onChanged;

  @override
  State<GhSegmented> createState() => _GhSegmentedState();
}

class _GhSegmentedState extends State<GhSegmented> {
  final Object _sharedTag = Object();

  @override
  void dispose() {
    GhSharedElements.forget(_sharedTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Container(
      padding: EdgeInsets.all(theme.space(1)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1),
        children: [
          for (final option in widget.options)
            GhPressable(
              key: ValueKey('segment:${option.value}'),
              onPressed: () => widget.onChanged(option.value),
              selected: widget.value == option.value,
              borderRadius: radius,
              builder: (context, states) {
                final active = widget.value == option.value;
                return Stack(
                  children: [
                    if (active)
                      Positioned.fill(
                        child: GhShared(
                          key: const ValueKey('segment-thumb'),
                          tag: _sharedTag,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: theme.accent, borderRadius: radius),
                          ),
                        ),
                      ),
                    GhAnimatedBox(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(1.5)),
                      color: !active && states.highlighted ? theme.raised.withValues(alpha: 0.5) : theme.raised.withValues(alpha: 0),
                      borderRadius: radius,
                      child: Text(
                        option.label,
                        style: theme.text(
                          size: GhTextSize.xs,
                          weight: GhWeight.medium,
                          mono: option.mono,
                          color: active ? Colors.white : (states.highlighted ? theme.ink : theme.muted),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
