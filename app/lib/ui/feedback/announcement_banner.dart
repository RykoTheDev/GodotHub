import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import '../core/i18n.dart';

abstract final class GhAnnouncement {
  static const dismissKey = 'godothub_announcement_dismissed';
  static const usageKey = 'godothub_announcement_usage_seconds';
  static const usageThresholdSeconds = 30 * 60;
  static const tickSeconds = 15;
  static const supportUrl = 'https://www.patreon.com/cw/TheRyko/membership';
}

class GhAnnouncementController extends ChangeNotifier {
  GhAnnouncementController({required this.getItem, required this.setItem, this.isHidden});

  final String? Function(String key) getItem;
  final void Function(String key, String value) setItem;
  final bool Function()? isHidden;

  bool _visible = false;
  bool _dismissed = false;
  int _usage = 0;
  Timer? _timer;

  bool get visible => _visible;

  void start() {
    _timer?.cancel();
    try {
      _dismissed = getItem(GhAnnouncement.dismissKey) == '1';
    } catch (_) {}
    _usage = 0;
    try {
      _usage = num.tryParse(getItem(GhAnnouncement.usageKey) ?? '')?.toInt() ?? 0;
    } catch (_) {}
    if (!_dismissed && _usage >= GhAnnouncement.usageThresholdSeconds) {
      _setVisible(true);
    }
    _timer = Timer.periodic(const Duration(seconds: GhAnnouncement.tickSeconds), (_) => _tick());
  }

  void _tick() {
    if ((isHidden?.call() ?? false) || _dismissed) {
      return;
    }
    _usage += GhAnnouncement.tickSeconds;
    try {
      setItem(GhAnnouncement.usageKey, '$_usage');
    } catch (_) {}
    if (_usage >= GhAnnouncement.usageThresholdSeconds) {
      _setVisible(true);
    }
  }

  void show() => _setVisible(true);

  void dismiss() {
    _dismissed = true;
    _setVisible(false);
    try {
      setItem(GhAnnouncement.dismissKey, '1');
    } catch (_) {}
  }

  void _setVisible(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class GhAnnouncementBanner extends StatelessWidget {
  const GhAnnouncementBanner({super.key, required this.controller, required this.onSupport});

  final GhAnnouncementController controller;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.visible) {
          return const SizedBox.shrink();
        }
        final theme = GhTheme.of(context);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(theme.space(4), 0, theme.space(4), theme.space(4)),
            child: GhAnnouncementCard(onSupport: onSupport, onDismiss: controller.dismiss),
          ),
        );
      },
    );
  }
}

class GhAnnouncementCard extends StatelessWidget {
  const GhAnnouncementCard({
    super.key,
    required this.onSupport,
    required this.onDismiss,
    this.title,
    this.body,
    this.supportLabel,
    this.dismissLabel,
    this.animate = true,
  });

  final VoidCallback onSupport;
  final VoidCallback onDismiss;
  final String? title;
  final String? body;
  final String? supportLabel;
  final String? dismissLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    final card = Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(theme.space(5), theme.space(3), theme.space(3), theme.space(3)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
        boxShadow: GhShadows.lg(Colors.black.withValues(alpha: 0.4)),
      ),
      child: Row(
        spacing: theme.space(3.5),
        children: [
          Container(
            width: theme.space(9),
            height: theme.space(9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.radiusTile),
              border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
            ),
            child: GhIcon(GhIcons.heart, size: theme.space(4), color: theme.danger),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title ?? tr.common.announcement_support_title, style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink)),
                SizedBox(height: theme.space(0.5)),
                Text(body ?? tr.common.announcement_support_body, style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
              ],
            ),
          ),
          _SupportButton(label: supportLabel ?? tr.common.support, onPressed: onSupport),
          _DismissButton(label: dismissLabel ?? tr.common.dismiss, onPressed: onDismiss),
        ],
      ),
    );
    if (!animate) {
      return card;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: GhCurves.outExpo,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: card,
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(9),
        color: theme.danger.withValues(alpha: states.active ? 0.25 : 0.15),
        borderRadius: radius,
        boxShadow: states.active ? GhShadows.hoverLift() : const [],
        padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            GhIconMotionScale(
              states: states,
              child: GhIcon(GhIcons.heart, size: theme.space(3.5), color: theme.danger),
            ),
            Text(label, style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.danger)),
          ],
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) => GhAnimatedBox(
        width: theme.space(8),
        height: theme.space(8),
        alignment: Alignment.center,
        color: states.active ? theme.overlay : theme.overlay.withValues(alpha: 0),
        borderRadius: radius,
        boxShadow: states.active ? GhShadows.hoverLift() : const [],
        child: GhIconMotionScale(
          states: states,
          child: GhAnimatedIcon(
            GhIcons.x,
            size: theme.space(4),
            color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
