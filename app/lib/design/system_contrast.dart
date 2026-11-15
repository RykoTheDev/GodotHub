import 'dart:ffi';
import 'dart:io';

import 'palette.dart';

class SystemContrastColors {
  const SystemContrastColors({
    required this.window,
    required this.windowText,
    required this.highlight,
    required this.highlightText,
    required this.buttonFace,
    required this.grayText,
    required this.hotlight,
  });

  final String window;
  final String windowText;
  final String highlight;
  final String highlightText;
  final String buttonFace;
  final String grayText;
  final String hotlight;

  @override
  bool operator ==(Object other) =>
      other is SystemContrastColors &&
      other.window == window &&
      other.windowText == windowText &&
      other.highlight == highlight &&
      other.highlightText == highlightText &&
      other.buttonFace == buttonFace &&
      other.grayText == grayText &&
      other.hotlight == hotlight;

  @override
  int get hashCode => Object.hash(window, windowText, highlight, highlightText, buttonFace, grayText, hotlight);
}

const _colorWindow = 5;
const _colorWindowText = 8;
const _colorHighlight = 13;
const _colorHighlightText = 14;
const _colorButtonFace = 15;
const _colorGrayText = 17;
const _colorHotlight = 26;

String _hexOfColorRef(int value) => rgbToHex(value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff);

SystemContrastColors? readSystemContrastColors() {
  if (!Platform.isWindows) return null;
  try {
    final user32 = DynamicLibrary.open('user32.dll');
    final getSysColor = user32.lookupFunction<Uint32 Function(Int32), int Function(int)>('GetSysColor');
    String color(int index) => _hexOfColorRef(getSysColor(index));
    return SystemContrastColors(
      window: color(_colorWindow),
      windowText: color(_colorWindowText),
      highlight: color(_colorHighlight),
      highlightText: color(_colorHighlightText),
      buttonFace: color(_colorButtonFace),
      grayText: color(_colorGrayText),
      hotlight: color(_colorHotlight),
    );
  } catch (_) {
    return null;
  }
}
