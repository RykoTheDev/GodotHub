import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../i18n/i18n_controller.dart';

TextDirection? ghPlaintextDirection(String text, {GhI18n? i18n}) {
  final source = i18n ?? GhI18n.instance;
  if (source.textDirection != TextDirection.rtl || source.layoutDirection == TextDirection.rtl) return null;
  return Bidi.startsWithRtl(text) ? TextDirection.rtl : null;
}

Widget ghPlaintext(String text, Widget child) {
  final direction = ghPlaintextDirection(text);
  return direction == null ? child : Directionality(textDirection: direction, child: child);
}
