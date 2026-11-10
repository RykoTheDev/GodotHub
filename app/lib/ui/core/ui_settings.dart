import 'package:flutter/widgets.dart';

@immutable
class GhUiSettingsData {
  const GhUiSettingsData({this.tooltipDelay = const Duration(milliseconds: 350)});

  final Duration tooltipDelay;

  @override
  bool operator ==(Object other) =>
      other is GhUiSettingsData && other.tooltipDelay == tooltipDelay;

  @override
  int get hashCode => tooltipDelay.hashCode;
}

class GhUiSettings extends InheritedWidget {
  const GhUiSettings({super.key, required this.data, required super.child});

  final GhUiSettingsData data;

  static GhUiSettingsData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GhUiSettings>()?.data ?? const GhUiSettingsData();

  @override
  bool updateShouldNotify(GhUiSettings oldWidget) => data != oldWidget.data;
}

enum GhSide { top, bottom, left, right }

GhSide mirrorSide(GhSide side, TextDirection direction) {
  if (direction != TextDirection.rtl) {
    return side;
  }
  return switch (side) {
    GhSide.left => GhSide.right,
    GhSide.right => GhSide.left,
    _ => side,
  };
}
