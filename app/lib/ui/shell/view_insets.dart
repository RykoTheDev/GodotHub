import 'package:flutter/widgets.dart';

class GhViewInsets extends InheritedWidget {
  const GhViewInsets({super.key, required this.insets, required super.child});

  final EdgeInsetsDirectional insets;

  static EdgeInsetsDirectional of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GhViewInsets>()?.insets ?? EdgeInsetsDirectional.zero;

  @override
  bool updateShouldNotify(GhViewInsets oldWidget) => oldWidget.insets != insets;
}

class GhViewInsetPadding extends StatelessWidget {
  const GhViewInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: GhViewInsets.of(context), child: child);
}
