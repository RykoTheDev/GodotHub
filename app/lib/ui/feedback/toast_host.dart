import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/presence.dart';
import '../core/interaction.dart';
import '../core/i18n.dart';
import 'toast.dart';

class GhToastCard extends StatelessWidget {
  const GhToastCard({super.key, required this.toast, required this.onDismiss, this.dismissLabel, this.collapse = 0});

  final GhToastItem toast;
  final VoidCallback onDismiss;
  final String? dismissLabel;
  final double collapse;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final open = (1 - collapse).clamp(0.0, 1.0);
    final radius = BorderRadius.circular(theme.radiusMenu);
    final (icon, color) = switch (toast.type) {
      GhToastType.success => (GhIcons.checkCircle, theme.mint),
      GhToastType.error => (GhIcons.alertTriangle, theme.danger),
      GhToastType.info => (GhIcons.checkCircle, theme.accentBright),
    };
    final action = toast.action;
    return Container(
      width: theme.space(80),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: GhShadows.lg(Colors.black.withValues(alpha: 0.2))),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: GhBlur.filter(GhBlur.backdrop),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(3) * open),
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.95),
              borderRadius: radius,
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
            ),
            child: ClipRect(
              clipBehavior: collapse > 0 ? Clip.hardEdge : Clip.none,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: open,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.space(2.5),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(0.5)),
                      child: GhIcon(icon, size: theme.space(4), color: color),
                    ),
                    Expanded(
                      child: Text(
                        toast.message,
                        style: theme.text(size: GhTextSize.xs, color: theme.ink, lineHeight: 1.375),
                      ),
                    ),
                    if (action != null)
                      _ToastActionButton(
                        label: action.label,
                        onPressed: () {
                          onDismiss();
                          action.onClick();
                        },
                      ),
                    _ToastDismissButton(label: dismissLabel ?? context.tr.common.dismiss, onPressed: onDismiss),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastActionButton extends StatelessWidget {
  const _ToastActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhPressable(
      onPressed: onPressed,
      focusStyle: GhFocusStyle.outline,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: radius,
        boxShadow: states.active ? GhShadows.hoverLift() : const [],
        padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
        child: GhAnimatedText(
          label,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: states.active ? theme.ink : theme.accentBright),
        ),
      ),
    );
  }
}

class _ToastDismissButton extends StatelessWidget {
  const _ToastDismissButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.rem(0.25));
    return GhPressable(
      onPressed: onPressed,
      focusStyle: GhFocusStyle.outline,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: radius,
        boxShadow: states.active ? GhShadows.hoverLift() : const [],
        padding: EdgeInsets.all(theme.space(0.5)),
        child: GhIconMotionScale(
          states: states,
          child: GhAnimatedIcon(GhIcons.x, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _ToastEntry {
  _ToastEntry(this.item);

  final GhToastItem item;
  bool leaving = false;
}

class GhToastHost extends StatefulWidget {
  const GhToastHost({super.key, this.store, this.child});

  static const leaveMarginTop = -9.0;

  final GhToastStore? store;
  final Widget? child;

  @override
  State<GhToastHost> createState() => _GhToastHostState();
}

double ghToastCollapse(GhPresenceClock? clock) {
  if (clock == null || !clock.exiting) {
    return 0;
  }
  return GhPresenceSpecs.toastLeave.progress(clock.time);
}

class _GhToastHostState extends State<GhToastHost> {
  final Map<int, _ToastEntry> _entries = {};
  final OverlayPortalController _portal = OverlayPortalController();
  VoidCallback? _unsubscribe;
  bool _subscribed = false;

  GhToastStore get _store => widget.store ?? ghToasts;

  @override
  void initState() {
    super.initState();
    _subscribe();
    if (widget.child == null) {
      _portal.show();
    }
  }

  @override
  void didUpdateWidget(GhToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.store ?? ghToasts) != _store) {
      _unsubscribe?.call();
      _subscribe();
    }
    if (widget.child == null && !_portal.isShowing) {
      _portal.show();
    }
  }

  void _subscribe() {
    _subscribed = false;
    _unsubscribe = _store.subscribe(_onToasts);
    _subscribed = true;
  }

  void _onToasts(List<GhToastItem> toasts) {
    final ids = {for (final toast in toasts) toast.id};
    for (final toast in toasts) {
      _entries.putIfAbsent(toast.id, () => _ToastEntry(toast));
    }
    for (final entry in _entries.values) {
      if (entry.leaving || ids.contains(entry.item.id)) {
        continue;
      }
      entry.leaving = true;
    }
    if (_subscribed && mounted) {
      setState(() {});
    }
  }

  void _remove(int id) {
    if (!mounted) {
      return;
    }
    final entry = _entries[id];
    if (entry == null || !entry.leaving) {
      return;
    }
    setState(() => _entries.remove(id));
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _entries.clear();
    super.dispose();
  }

  Widget _toast(GhTheme theme, _ToastEntry entry, bool first) {
    final id = entry.item.id;
    final gap = theme.space(2);
    return GhPresence(
      key: ValueKey(id),
      visible: !entry.leaving,
      kind: GhPresenceKind.toast,
      onExited: () => _remove(id),
      frame: (context, clock, child) => AnimatedBuilder(
        animation: clock,
        child: child,
        builder: (context, child) {
          final top = first ? 0.0 : math.max(0.0, gap + GhToastHost.leaveMarginTop * ghToastCollapse(clock));
          return Padding(
            padding: EdgeInsets.only(top: top),
            child: child,
          );
        },
      ),
      child: GhPresenceBuilder(
        builder: (context, clock, _) =>
            GhToastCard(toast: entry.item, collapse: ghToastCollapse(clock), onDismiss: () => _store.dismissToast(id)),
      ),
    );
  }

  Widget _stack(BuildContext context) {
    final theme = GhTheme.of(context);
    final ordered = _entries.values.toList()..sort((a, b) => a.item.id.compareTo(b.item.id));
    return PositionedDirectional(
      bottom: theme.space(4),
      end: theme.space(4),
      child: DefaultTextStyle(
        style: theme.text(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (var i = 0; i < ordered.length; i++) _toast(theme, ordered[i], i == 0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (child != null) {
      return Stack(fit: StackFit.passthrough, children: [child, _stack(context)]);
    }
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _stack,
      overlayLocation: OverlayChildLocation.rootOverlay,
      child: const SizedBox.shrink(),
    );
  }
}
