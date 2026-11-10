import 'package:flutter/foundation.dart';

import '../src/rust/api/types.dart';

enum ConsoleLevel { error, warning, info }

const List<ConsoleLevel> consoleLevels = [ConsoleLevel.error, ConsoleLevel.warning, ConsoleLevel.info];

final RegExp _warningPattern = RegExp(r'\b(warn|warning|warnings|deprecated|inconsistent)\b', caseSensitive: false);
final RegExp _errorPattern = RegExp(
  r"\b(error|errors|failed|failure|fatal|exception|crash|crashed|broken|unable|cannot|can't|refused|denied)\b",
  caseSensitive: false,
);

final Expando<ConsoleLevel> _levelCache = Expando<ConsoleLevel>('consoleLevel');

ConsoleLevel _detectLevel(ConsoleLine line) {
  if (_warningPattern.hasMatch(line.text)) return ConsoleLevel.warning;
  if (_errorPattern.hasMatch(line.text)) return ConsoleLevel.error;
  return line.stream == ConsoleStream.stderr ? ConsoleLevel.error : ConsoleLevel.info;
}

ConsoleLevel classifyConsoleLine(ConsoleLine line) {
  final cached = _levelCache[line];
  if (cached != null) return cached;
  final level = _detectLevel(line);
  _levelCache[line] = level;
  return level;
}

@immutable
class ConsoleEntry {
  const ConsoleEntry({required this.line, required this.level});

  final ConsoleLine line;
  final ConsoleLevel level;

  @override
  bool operator ==(Object other) => other is ConsoleEntry && identical(other.line, line) && other.level == level;

  @override
  int get hashCode => Object.hash(identityHashCode(line), level);

  @override
  String toString() => 'ConsoleEntry(${line.text}, $level)';
}

final RegExp _stackFramePattern = RegExp(r'^\s*at:');

List<ConsoleEntry> annotateConsoleLines(List<ConsoleLine> lines) {
  ConsoleLevel? carried;
  final entries = <ConsoleEntry>[];
  for (final line in lines) {
    final previous = carried;
    final level = previous != null && _stackFramePattern.hasMatch(line.text) ? previous : classifyConsoleLine(line);
    carried = level;
    entries.add(ConsoleEntry(line: line, level: level));
  }
  return entries;
}

Map<ConsoleLevel, int> countConsoleLevels(List<ConsoleEntry> entries) {
  final counts = <ConsoleLevel, int>{ConsoleLevel.error: 0, ConsoleLevel.warning: 0, ConsoleLevel.info: 0};
  for (final entry in entries) {
    counts[entry.level] = counts[entry.level]! + 1;
  }
  return counts;
}
