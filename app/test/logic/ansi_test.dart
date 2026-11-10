import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/ansi.dart';

const _esc = '\x1b';

const _palette = [
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

String _sgr(String params) => '$_esc[${params}m';

AnsiSpan _only(String input) {
  final spans = parseAnsi(input);
  expect(spans, hasLength(1));
  return spans.single;
}

void main() {
  group('ansi256Color', () {
    test('first sixteen indexes use the theme palette', () {
      for (var i = 0; i < 16; i++) {
        expect(ansi256Color(i), _palette[i]);
      }
    });

    test('indexes 16 to 231 map onto the 6x6x6 cube', () {
      expect(ansi256Color(16), '#000000');
      expect(ansi256Color(21), '#0000ff');
      expect(ansi256Color(100), '#878700');
      expect(ansi256Color(196), '#ff0000');
      expect(ansi256Color(208), '#ff8700');
      expect(ansi256Color(231), '#ffffff');
    });

    test('indexes 232 to 255 are the grey ramp', () {
      expect(ansi256Color(232), '#080808');
      expect(ansi256Color(244), '#808080');
      expect(ansi256Color(255), '#eeeeee');
    });

    test('out of range indexes resolve to nothing', () {
      expect(ansi256Color(-1), isNull);
      expect(ansi256Color(256), isNull);
      expect(ansi256Color(100000), isNull);
    });
  });

  group('parseAnsi basics', () {
    test('empty input has no spans', () {
      expect(parseAnsi(''), isEmpty);
    });

    test('plain text is a single unstyled span', () {
      expect(parseAnsi('hello world'), [const AnsiSpan(text: 'hello world')]);
    });

    test('text around SGR codes is split into styled spans', () {
      expect(parseAnsi('a${_sgr('1')}b${_sgr('0')}c'), [
        const AnsiSpan(text: 'a'),
        const AnsiSpan(text: 'b', bold: true),
        const AnsiSpan(text: 'c'),
      ]);
    });

    test('codes with no text between them produce no empty spans', () {
      expect(parseAnsi('${_sgr('31')}${_sgr('1')}${_sgr('0')}'), isEmpty);
      expect(parseAnsi('${_sgr('31')}${_sgr('1')}x'), [AnsiSpan(text: 'x', color: _palette[1], bold: true)]);
    });

    test('adjacent spans with the same style are not merged', () {
      expect(parseAnsi('a${_sgr('5')}b'), [const AnsiSpan(text: 'a'), const AnsiSpan(text: 'b')]);
    });

    test('surrogate pairs survive splitting', () {
      expect(parseAnsi('\u{1F600}${_sgr('31')}\u{1F600}'), [
        const AnsiSpan(text: '\u{1F600}'),
        AnsiSpan(text: '\u{1F600}', color: _palette[1]),
      ]);
    });
  });

  group('parseAnsi SGR attributes', () {
    test('1 2 3 4 set bold dim italic underline', () {
      expect(_only('${_sgr('1')}x'), const AnsiSpan(text: 'x', bold: true));
      expect(_only('${_sgr('2')}x'), const AnsiSpan(text: 'x', dim: true));
      expect(_only('${_sgr('3')}x'), const AnsiSpan(text: 'x', italic: true));
      expect(_only('${_sgr('4')}x'), const AnsiSpan(text: 'x', underline: true));
    });

    test('22 clears bold and dim to false', () {
      expect(_only('${_sgr('1;2;22')}x'), const AnsiSpan(text: 'x', bold: false, dim: false));
      expect(_only('${_sgr('22')}x'), const AnsiSpan(text: 'x', bold: false, dim: false));
    });

    test('23 and 24 clear italic and underline to false', () {
      expect(_only('${_sgr('3;23')}x'), const AnsiSpan(text: 'x', italic: false));
      expect(_only('${_sgr('4;24')}x'), const AnsiSpan(text: 'x', underline: false));
    });

    test('0 and empty params reset everything', () {
      expect(parseAnsi('${_sgr('1;3;4;31;42')}a${_sgr('0')}b'), [
        AnsiSpan(text: 'a', bold: true, italic: true, underline: true, color: _palette[1], background: _palette[2]),
        const AnsiSpan(text: 'b'),
      ]);
      expect(parseAnsi('${_sgr('1;31')}a${_sgr('')}b'), [
        AnsiSpan(text: 'a', bold: true, color: _palette[1]),
        const AnsiSpan(text: 'b'),
      ]);
    });

    test('a reset inside a sequence only clears what came before it', () {
      expect(_only('${_sgr('1;31;0;3')}x'), const AnsiSpan(text: 'x', italic: true));
    });

    test('styles accumulate across sequences', () {
      expect(parseAnsi('${_sgr('1')}a${_sgr('31')}b${_sgr('44')}c'), [
        const AnsiSpan(text: 'a', bold: true),
        AnsiSpan(text: 'b', bold: true, color: _palette[1]),
        AnsiSpan(text: 'c', bold: true, color: _palette[1], background: _palette[4]),
      ]);
    });

    test('30-37 and 90-97 set the foreground', () {
      for (var i = 0; i < 8; i++) {
        expect(_only('${_sgr('${30 + i}')}x').color, _palette[i]);
        expect(_only('${_sgr('${90 + i}')}x').color, _palette[8 + i]);
      }
    });

    test('40-47 and 100-107 set the background', () {
      for (var i = 0; i < 8; i++) {
        expect(_only('${_sgr('${40 + i}')}x').background, _palette[i]);
        expect(_only('${_sgr('${100 + i}')}x').background, _palette[8 + i]);
      }
    });

    test('39 and 49 clear only their own channel', () {
      expect(_only('${_sgr('1;31;41;39')}x'), AnsiSpan(text: 'x', bold: true, background: _palette[1]));
      expect(_only('${_sgr('1;31;41;49')}x'), AnsiSpan(text: 'x', bold: true, color: _palette[1]));
    });

    test('codes it does not handle are ignored', () {
      for (final code in ['5', '7', '8', '9', '21', '25', '27', '28', '29', '38', '48', '53', '108', '999']) {
        expect(_only('${_sgr(code)}x'), const AnsiSpan(text: 'x'), reason: code);
      }
    });

    test('empty parts and leading zeros are tolerated', () {
      expect(_only('${_sgr('1;;4')}x'), const AnsiSpan(text: 'x', bold: true, underline: true));
      expect(_only('${_sgr('031')}x').color, _palette[1]);
      expect(_only('${_sgr('31;')}x').color, _palette[1]);
      expect(_only('${_sgr(';')}x'), const AnsiSpan(text: 'x'));
    });
  });

  group('parseAnsi extended colors', () {
    test('38;5 and 48;5 use the 256 colour table', () {
      expect(_only('${_sgr('38;5;196')}x'), const AnsiSpan(text: 'x', color: '#ff0000'));
      expect(_only('${_sgr('48;5;21')}x'), const AnsiSpan(text: 'x', background: '#0000ff'));
      expect(_only('${_sgr('38;5;9')}x').color, _palette[9]);
      expect(_only('${_sgr('38;5;244')}x').color, '#808080');
    });

    test('an unknown 256 index keeps the previous colour and skips its arguments', () {
      expect(_only('${_sgr('31;38;5;256')}x').color, _palette[1]);
      expect(_only('${_sgr('38;5;300;1')}x'), const AnsiSpan(text: 'x', bold: true));
      expect(_only('${_sgr('38;5')}x'), const AnsiSpan(text: 'x'));
    });

    test('codes after a 256 colour still apply', () {
      expect(_only('${_sgr('38;5;196;1')}x'), const AnsiSpan(text: 'x', color: '#ff0000', bold: true));
    });

    test('38;2 and 48;2 build truecolor hex values', () {
      expect(_only('${_sgr('38;2;255;128;0')}x'), const AnsiSpan(text: 'x', color: '#ff8000'));
      expect(_only('${_sgr('48;2;1;2;3')}x'), const AnsiSpan(text: 'x', background: '#010203'));
      expect(
        _only('${_sgr('38;2;10;20;30;48;2;40;50;60;4')}x'),
        const AnsiSpan(text: 'x', color: '#0a141e', background: '#28323c', underline: true),
      );
    });

    test('truecolor channels clamp to 255', () {
      expect(_only('${_sgr('38;2;300;0;999')}x').color, '#ff00ff');
      expect(_only('${_sgr('38;2;99999999999999999999;0;0')}x').color, '#ff0000');
      expect(_only('${_sgr('38;2;${'9' * 400};0;0')}x').color, '#ff0000');
    });

    test('truncated truecolor is ignored', () {
      expect(_only('${_sgr('31;38;2;10;20')}x').color, _palette[1]);
      expect(_only('${_sgr('38;2;10;20')}x'), const AnsiSpan(text: 'x'));
      expect(_only('${_sgr('38;2')}x'), const AnsiSpan(text: 'x'));
    });

    test('38 followed by an unknown mode lets the next code run', () {
      expect(_only('${_sgr('38;1')}x'), const AnsiSpan(text: 'x', bold: true));
      expect(_only('${_sgr('48;3;4')}x'), const AnsiSpan(text: 'x', italic: true, underline: true));
    });

    test('a huge 256 index resolves to nothing', () {
      expect(_only('${_sgr('31;38;5;99999999999999999999')}x').color, _palette[1]);
    });
  });

  group('non-SGR escapes', () {
    test('cursor and erase sequences are removed', () {
      expect(parseAnsi('a$_esc[2Kb$_esc[1Ac$_esc[10;20Hd'), [const AnsiSpan(text: 'abcd')]);
    });

    test('private mode sequences are removed', () {
      expect(parseAnsi('$_esc[?25la$_esc[?2004hb'), [const AnsiSpan(text: 'ab')]);
    });

    test('OSC sequences end at BEL or ST', () {
      expect(parseAnsi('$_esc]0;title\x07a'), [const AnsiSpan(text: 'a')]);
      expect(parseAnsi('$_esc]8;;https://godotengine.org$_esc\\link$_esc]8;;$_esc\\'), [const AnsiSpan(text: 'link')]);
    });

    test('two character escapes from @ to Z, backslash and underscore are removed', () {
      expect(parseAnsi('a${_esc}Mb$_esc@c${_esc}Zd$_esc\\e${_esc}_f'), [const AnsiSpan(text: 'abcdef')]);
    });

    test('non-SGR escapes are stripped per span without changing style', () {
      expect(parseAnsi('a$_esc[2Kb${_sgr('32')}c$_esc]0;t\x07d'), [
        const AnsiSpan(text: 'ab'),
        AnsiSpan(text: 'cd', color: _palette[2]),
      ]);
    });
  });

  group('malformed sequences', () {
    test('an unterminated CSI is kept as raw text', () {
      expect(parseAnsi('text$_esc[31'), [const AnsiSpan(text: 'text$_esc[31')]);
    });

    test('a lone escape is kept', () {
      expect(parseAnsi('a$_esc'), [const AnsiSpan(text: 'a$_esc')]);
      expect(parseAnsi('a$_esc=b'), [const AnsiSpan(text: 'a$_esc=b')]);
    });

    test('colon separated and private m sequences are not SGR', () {
      expect(parseAnsi('$_esc[1:2mX'), [const AnsiSpan(text: '$_esc[1:2mX')]);
      expect(parseAnsi('$_esc[?1mX'), [const AnsiSpan(text: '$_esc[?1mX')]);
    });

    test('an unterminated OSC is kept', () {
      expect(parseAnsi('$_esc]0;title'), [const AnsiSpan(text: '$_esc]0;title')]);
    });

    test('an escape split by an SGR code is kept by parseAnsi but removed by stripAnsi', () {
      final input = '$_esc${_sgr('0')}[A';
      expect(parseAnsi(input), [const AnsiSpan(text: _esc), const AnsiSpan(text: '[A')]);
      expect(stripAnsi(input), '');
    });
  });

  group('stripAnsi', () {
    test('returns the same string when there is no escape', () {
      const input = 'no escapes here';
      expect(identical(stripAnsi(input), input), isTrue);
      expect(stripAnsi(''), '');
    });

    test('removes SGR and non-SGR sequences', () {
      expect(stripAnsi('${_sgr('1;31')}Error:${_sgr('0')} $_esc[2Kfailed$_esc]0;t\x07'), 'Error: failed');
      expect(stripAnsi('${_sgr('38;2;1;2;3')}x${_sgr('')}'), 'x');
    });

    test('keeps malformed sequences', () {
      expect(stripAnsi('a$_esc[31'), 'a$_esc[31');
      expect(stripAnsi('$_esc[1:2mX'), '$_esc[1:2mX');
    });
  });

  group('ansiSpanStyle', () {
    test('maps attributes to css-like values', () {
      expect(
        ansiSpanStyle(const AnsiSpan(text: 'x', color: '#111111', background: '#222222', bold: true, dim: true, italic: true, underline: true)),
        const AnsiCssStyle(
          color: '#111111',
          backgroundColor: '#222222',
          fontWeight: 600,
          opacity: 0.7,
          fontStyle: 'italic',
          textDecoration: 'underline',
        ),
      );
    });

    test('false and missing attributes leave values unset', () {
      expect(ansiSpanStyle(const AnsiStyle()), const AnsiCssStyle());
      expect(ansiSpanStyle(const AnsiStyle(bold: false, dim: false, italic: false, underline: false)), const AnsiCssStyle());
    });
  });
}
