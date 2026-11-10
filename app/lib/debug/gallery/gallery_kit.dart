import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../ui/core/interaction.dart';

class GallerySection {
  const GallerySection(this.title, this.builder);

  final String title;
  final WidgetBuilder builder;
}

class GalleryGroup extends StatelessWidget {
  const GalleryGroup({super.key, required this.title, required this.children, this.spacing = 16});

  final String title;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05)),
          const SizedBox(height: 10),
          Wrap(spacing: spacing, runSpacing: spacing, crossAxisAlignment: WrapCrossAlignment.center, children: children),
        ],
      ),
    );
  }
}

class GalleryItem extends StatelessWidget {
  const GalleryItem({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 6),
        Text(label, style: theme.text(size: GhTextSize.x4s, color: theme.muted, mono: true)),
      ],
    );
  }
}

enum GalleryState { normal, hover, pressed, focus, disabled }

class GalleryStates extends StatelessWidget {
  const GalleryStates({super.key, required this.builder, this.states = GalleryState.values});

  final Widget Function(BuildContext context, bool enabled) builder;
  final List<GalleryState> states;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final state in states)
          GalleryItem(
            label: state.name,
            child: GhForcedStates(
              hovered: state == GalleryState.hover,
              pressed: state == GalleryState.pressed,
              focused: state == GalleryState.focus,
              child: Builder(builder: (context) => builder(context, state != GalleryState.disabled)),
            ),
          ),
      ],
    );
  }
}
