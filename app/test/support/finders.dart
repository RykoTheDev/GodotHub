import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// `find.byTooltip` for the app's tooltips. Flutter's own finder only matches the
/// SDK's deprecated `package:flutter/material.dart` Tooltip, and the app's
/// tooltips are `material_ui` ones with `excludeFromSemantics: true`, so it finds
/// none of them.
Finder findTooltip(String message) => find.byWidgetPredicate((widget) => widget is Tooltip && widget.message == message);
