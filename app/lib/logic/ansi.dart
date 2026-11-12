import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class AnsiStyle {
  const AnsiStyle({this.color, this.background, this.bold, this.dim, this.italic, this.underline});

  final String? color;
  final String? background;
  final bool? bold;
  final bool? dim;
  final bool? italic;
  final bool? underline;

  @override
  bool operator ==(Object other) =>
      other is AnsiStyle &&
      other.runtimeType == runtimeType &&
      other.color == color &&
      other.background == background &&
      other.bold == bold &&
      other.dim == dim &&
      other.italic == italic &&
      other.underline == underline;

  @override
  int get hashCode => Object.hash(runtimeType, color, background, bold, dim, italic, underline);

  @override
  String toString() => 'AnsiStyle(color: $color, background: $background, bold: $bold, dim: $dim, italic: $italic, underline: $underline)';
}

@immutable
class AnsiSpan extends AnsiStyle {
  const AnsiSpan({required this.text, super.color, super.background, super.bold, super.dim, super.italic, super.underline});

  AnsiSpan.styled(AnsiStyle style, this.text)
    : super(
        color: style.color,
        background: style.background,
        bold: style.bold,
        dim: style.dim,
        italic: style.italic,
        underline: style.underline,
      );

  final String text;

  @override
  bool operator ==(Object other) => other is AnsiSpan && other.text == text && super == other;

  @override
  int get hashCode => Object.hash(text, super.hashCode);

  @override
  String toString() =>
      'AnsiSpan(${text.replaceAll('\x1b', r'\e')}, color: $color, background: $background, bold: $bold, dim: $dim, italic: $italic, underline: $underline)';
}

@immutable
class AnsiCssStyle {
  const AnsiCssStyle({this.color, this.backgroundColor, this.fontWeight, this.opacity, this.fontStyle, this.textDecoration});

  final String? color;
  final String? backgroundColor;
  final int? fontWeight;
  final double? opacity;
  final String? fontStyle;
  final String? textDecoration;

  @override
  bool operator ==(Object other) =>
      other is AnsiCssStyle &&
      other.color == color &&
      other.backgroundColor == backgroundColor &&
      other.fontWeight == fontWeight &&
      other.opacity == opacity &&
      other.fontStyle == fontStyle &&
      other.textDecoration == textDecoration;

  @override
  int get hashCode => Object.hash(color, backgroundColor, fontWeight, opacity, fontStyle, textDecoration);

  @override
  String toString() =>
      'AnsiCssStyle(color: $color, backgroundColor: $backgroundColor, fontWeight: $fontWeight, opacity: $opacity, fontStyle: $fontStyle, textDecoration: $textDecoration)';
}

const List<String> _ansi16 = [
  '#3f4451',
  '#e05561',
  '#8cc265',
  '#d18f52',
  '#4aa5f0',
  '#c162de',
  '#42b3c2',
  '#d7dae0',
  '#4f5666',
  '#ff616e',
  '#a5e075',
  '#f0a45d',
  '#4dc4ff',
  '#de73ff',
  '#4cd1e0',
  '#e6e6e6',
];

const List<int> _cubeSteps = [0, 95, 135, 175, 215, 255];

String _rgbToHex(num r, num g, num b) {
  String channel(num value) => math.max(0, math.min(255, value)).round().toRadixString(16).padLeft(2, '0');
  return '#${channel(r)}${channel(g)}${channel(b)}';
}

String? ansi256Color(int index) {
  if (index < 0) return null;
  if (index < 16) return _ansi16[index];
  if (index < 232) {
    final offset = index - 16;
    return _rgbToHex(_cubeSteps[(offset ~/ 36) % 6], _cubeSteps[(offset ~/ 6) % 6], _cubeSteps[offset % 6]);
  }
  if (index < 256) {
    final grey = 8 + (index - 232) * 10;
    return _rgbToHex(grey, grey, grey);
  }
  return null;
}

final RegExp _nonSgrEscape = RegExp(r'\u001b\][^\u0007\u001b]*(?:\u0007|\u001b\\)|\u001b\[[0-9;?]*[A-Za-ln-~]|\u001b[@-Z\\_]');

final RegExp _sgrWithStyle = RegExp(r'\u001b\[[0-9;]*m');

final RegExp _sgr = RegExp(r'\u001b\[([0-9;]*)m');

String _stripEscapes(String input) => input.replaceAll(_nonSgrEscape, '');

String stripAnsi(String input) {
  if (!input.contains('\x1b')) return input;
  return _stripEscapes(input.replaceAll(_sgrWithStyle, ''));
}

class _MutableStyle {
  _MutableStyle.from(AnsiStyle style)
    : color = style.color,
      background = style.background,
      bold = style.bold,
      dim = style.dim,
      italic = style.italic,
      underline = style.underline;

  String? color;
  String? background;
  bool? bold;
  bool? dim;
  bool? italic;
  bool? underline;

  void clear() {
    color = null;
    background = null;
    bold = null;
    dim = null;
    italic = null;
    underline = null;
  }

  void setTarget(bool foreground, String value) {
    if (foreground) {
      color = value;
    } else {
      background = value;
    }
  }

  AnsiStyle freeze() => AnsiStyle(color: color, background: background, bold: bold, dim: dim, italic: italic, underline: underline);
}

String? _resolve256(num? value) {
  if (value == null || value is! int) return null;
  return ansi256Color(value);
}

AnsiStyle _applySgr(AnsiStyle style, String params) {
  final codes = <num>[
    for (final part in (params.isEmpty ? '0' : params).split(';'))
      if (part.isNotEmpty) num.parse(part),
  ];
  num? at(int index) => index < codes.length ? codes[index] : null;

  final next = _MutableStyle.from(style);

  for (var i = 0; i < codes.length; i += 1) {
    final code = codes[i];
    if (code == 0) {
      next.clear();
    } else if (code == 1) {
      next.bold = true;
    } else if (code == 2) {
      next.dim = true;
    } else if (code == 3) {
      next.italic = true;
    } else if (code == 4) {
      next.underline = true;
    } else if (code == 22) {
      next.bold = false;
      next.dim = false;
    } else if (code == 23) {
      next.italic = false;
    } else if (code == 24) {
      next.underline = false;
    } else if (code >= 30 && code <= 37) {
      next.color = _ansi16[code.toInt() - 30];
    } else if (code == 39) {
      next.color = null;
    } else if (code >= 40 && code <= 47) {
      next.background = _ansi16[code.toInt() - 40];
    } else if (code == 49) {
      next.background = null;
    } else if (code >= 90 && code <= 97) {
      next.color = _ansi16[code.toInt() - 90 + 8];
    } else if (code >= 100 && code <= 107) {
      next.background = _ansi16[code.toInt() - 100 + 8];
    } else if (code == 38 || code == 48) {
      final foreground = code == 38;
      if (at(i + 1) == 5) {
        final resolved = _resolve256(at(i + 2));
        if (resolved != null) next.setTarget(foreground, resolved);
        i += 2;
      } else if (at(i + 1) == 2) {
        final r = at(i + 2);
        final g = at(i + 3);
        final b = at(i + 4);
        if (r != null && g != null && b != null) {
          next.setTarget(foreground, _rgbToHex(r, g, b));
        }
        i += 4;
      }
    }
  }

  return next.freeze();
}

List<AnsiSpan> parseAnsi(String input) {
  if (input.isEmpty) return const [];
  if (!input.contains('\x1b')) return [AnsiSpan(text: input)];

  final spans = <AnsiSpan>[];
  var style = const AnsiStyle();
  var cursor = 0;

  void push(String text) {
    if (text.isEmpty) return;
    spans.add(AnsiSpan.styled(style, text));
  }

  for (final match in _sgr.allMatches(input)) {
    push(_stripEscapes(input.substring(cursor, match.start)));
    style = _applySgr(style, match.group(1)!);
    cursor = match.end;
  }
  push(_stripEscapes(input.substring(cursor)));

  return spans;
}

AnsiCssStyle ansiSpanStyle(AnsiStyle span) {
  return AnsiCssStyle(
    color: span.color,
    backgroundColor: span.background,
    fontWeight: span.bold == true ? 600 : null,
    opacity: span.dim == true ? 0.7 : null,
    fontStyle: span.italic == true ? 'italic' : null,
    textDecoration: span.underline == true ? 'underline' : null,
  );
}
