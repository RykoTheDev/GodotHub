import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/console_log.dart';
import 'package:godothub/src/rust/api/types.dart';

var _seq = 0;

ConsoleLine _out(String text) => ConsoleLine(seq: BigInt.from(_seq++), stream: ConsoleStream.stdout, text: text);

ConsoleLine _err(String text) => ConsoleLine(seq: BigInt.from(_seq++), stream: ConsoleStream.stderr, text: text);

void main() {
  test('levels are ordered error, warning, info', () {
    expect(consoleLevels, [ConsoleLevel.error, ConsoleLevel.warning, ConsoleLevel.info]);
    expect(ConsoleLevel.values.map((l) => l.name), ['error', 'warning', 'info']);
  });

  group('classifyConsoleLine', () {
    test('warning words win', () {
      for (final text in ['WARNING: unused variable', 'warn: x', '3 warnings', 'Deprecated call', 'inconsistent state']) {
        expect(classifyConsoleLine(_out(text)), ConsoleLevel.warning, reason: text);
      }
      expect(classifyConsoleLine(_out('warning: error while loading')), ConsoleLevel.warning);
      expect(classifyConsoleLine(_err('warning on stderr')), ConsoleLevel.warning);
    });

    test('error words mark errors on any stream', () {
      for (final text in [
        'ERROR: res://main.gd:3',
        '2 errors',
        'Load failed',
        'failure',
        'FATAL',
        'Unhandled exception',
        'the game crashed',
        'crash',
        'broken pipe',
        'Unable to open file',
        'cannot find',
        "can't open",
        'connection refused',
        'access denied',
      ]) {
        expect(classifyConsoleLine(_out(text)), ConsoleLevel.error, reason: text);
      }
    });

    test('words only match on ASCII word boundaries', () {
      expect(classifyConsoleLine(_out('terror')), ConsoleLevel.info);
      expect(classifyConsoleLine(_out('errored out')), ConsoleLevel.info);
      expect(classifyConsoleLine(_out('error_code')), ConsoleLevel.info);
      expect(classifyConsoleLine(_out('warned')), ConsoleLevel.info);
      expect(classifyConsoleLine(_out('error-code')), ConsoleLevel.error);
      expect(classifyConsoleLine(_out('éerror')), ConsoleLevel.error);
      expect(classifyConsoleLine(_out('[warn]')), ConsoleLevel.warning);
    });

    test('plain lines fall back to the stream', () {
      expect(classifyConsoleLine(_out('Godot Engine v4.3')), ConsoleLevel.info);
      expect(classifyConsoleLine(_err('Godot Engine v4.3')), ConsoleLevel.error);
      expect(classifyConsoleLine(_out('')), ConsoleLevel.info);
    });

    test('the level is cached per line object', () {
      final line = _out('error');
      expect(classifyConsoleLine(line), ConsoleLevel.error);
      expect(classifyConsoleLine(line), ConsoleLevel.error);
    });
  });

  group('annotateConsoleLines', () {
    test('stack frames inherit the previous level', () {
      final lines = [
        _err('ERROR: boom'),
        _out('   at: res://player.gd:10'),
        _out(' at: res://enemy.gd:4'),
        _out('at: res://main.gd:2'),
        _out('hello'),
        _out('at: warning in frame'),
      ];
      expect(annotateConsoleLines(lines).map((e) => e.level), [
        ConsoleLevel.error,
        ConsoleLevel.error,
        ConsoleLevel.error,
        ConsoleLevel.error,
        ConsoleLevel.info,
        ConsoleLevel.info,
      ]);
    });

    test('a leading stack frame is classified on its own', () {
      expect(annotateConsoleLines([_out('at: error here')]).single.level, ConsoleLevel.error);
      expect(annotateConsoleLines([_out(' at: x')]).single.level, ConsoleLevel.info);
    });

    test('only a frame at the start of the text inherits', () {
      final entries = annotateConsoleLines([_err('fatal'), _out('x at: y'), _out('at:')]);
      expect(entries.map((e) => e.level), [ConsoleLevel.error, ConsoleLevel.info, ConsoleLevel.info]);
    });

    test('entries keep their line objects', () {
      final line = _out('hi');
      final entry = annotateConsoleLines([line]).single;
      expect(identical(entry.line, line), isTrue);
      expect(entry, ConsoleEntry(line: line, level: ConsoleLevel.info));
    });

    test('empty input', () {
      expect(annotateConsoleLines(const []), isEmpty);
    });
  });

  test('countConsoleLevels counts every level in order', () {
    final counts = countConsoleLevels(
      annotateConsoleLines([_err('x'), _out('at: y'), _out('warning'), _out('ok'), _out('ok')]),
    );
    expect(counts.keys, [ConsoleLevel.error, ConsoleLevel.warning, ConsoleLevel.info]);
    expect(counts, {ConsoleLevel.error: 2, ConsoleLevel.warning: 1, ConsoleLevel.info: 2});
    expect(countConsoleLevels(const []), {ConsoleLevel.error: 0, ConsoleLevel.warning: 0, ConsoleLevel.info: 0});
  });
}
