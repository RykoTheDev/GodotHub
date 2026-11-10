import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/git_graph.dart';
import 'package:godothub/src/rust/api/types.dart';

GitLogEntry _c(String hash, [List<String> parents = const []]) =>
    GitLogEntry(hash: hash, parents: parents, message: 'commit $hash', author: 'dev', date: '2026-01-01');

const _e = LaneCell.empty();
LaneCell _l(int lane) => LaneCell.line(lane);
LaneCell _d(int lane) => LaneCell.dot(lane);

List<List<Object>> _layout(List<GitLogEntry> commits) => [
  for (final row in buildGraphRows(commits)) [row.commit.hash, row.lane, row.cells, row.joins],
];

void main() {
  group('constants and helpers', () {
    test('lane colors cycle through the palette', () {
      expect(laneColors, hasLength(10));
      expect(colorFor(0), '#5865f2');
      expect(colorFor(3), '#f23f42');
      expect(colorFor(9), '#e11d48');
      expect(colorFor(10), '#5865f2');
      expect(colorFor(13), '#f23f42');
    });

    test('geometry constants match the web graph', () {
      expect(laneW, 20);
      expect(rowH, 44);
      expect(dotR, 4.5);
    });

    test('short hash keeps at most seven code units', () {
      expect(shortHash('0123456789abcdef'), '0123456');
      expect(shortHash('0123456'), '0123456');
      expect(shortHash('abc'), 'abc');
      expect(shortHash(''), '');
    });
  });

  group('buildGraphRows', () {
    test('empty history has no rows', () {
      expect(buildGraphRows(const []), isEmpty);
    });

    test('linear history stays on lane zero', () {
      expect(_layout([_c('A', ['B']), _c('B', ['C']), _c('C')]), [
        ['A', 0, [_d(0)], <int>[]],
        ['B', 0, [_d(0)], <int>[]],
        ['C', 0, [_d(0)], <int>[]],
      ]);
    });

    test('rows keep the original commit objects', () {
      final commits = [_c('A', ['B']), _c('B')];
      final rows = buildGraphRows(commits);
      expect(identical(rows[0].commit, commits[0]), isTrue);
      expect(identical(rows[1].commit, commits[1]), isTrue);
    });

    test('feature branch merged into main opens a lane and closes it at the fork point', () {
      expect(
        _layout([
          _c('M', ['A', 'F']),
          _c('F', ['E']),
          _c('A', ['B']),
          _c('E', ['B']),
          _c('B'),
        ]),
        [
          ['M', 0, [_d(0), _l(1)], [1]],
          ['F', 1, [_l(0), _d(1)], <int>[]],
          ['A', 0, [_d(0), _l(1)], <int>[]],
          ['E', 1, [_l(0), _d(1)], <int>[]],
          ['B', 0, [_d(0), _l(1)], [1]],
        ],
      );
    });

    test('branches that end leave empty cells until trailing lanes are trimmed', () {
      expect(
        _layout([
          _c('T1', ['R']),
          _c('T2', ['S']),
          _c('T3', ['U']),
          _c('S'),
          _c('U'),
          _c('R'),
        ]),
        [
          ['T1', 0, [_d(0)], <int>[]],
          ['T2', 1, [_l(0), _d(1)], <int>[]],
          ['T3', 2, [_l(0), _l(1), _d(2)], <int>[]],
          ['S', 1, [_l(0), _d(1), _l(2)], <int>[]],
          ['U', 2, [_l(0), _e, _d(2)], <int>[]],
          ['R', 0, [_d(0)], <int>[]],
        ],
      );
    });

    test('a merge that is not a tip reuses the lane of its first parent', () {
      expect(
        _layout([
          _c('A', ['B']),
          _c('M', ['B', 'C']),
          _c('B'),
          _c('C'),
        ]),
        [
          ['A', 0, [_d(0)], <int>[]],
          ['M', 0, [_d(0), _l(1)], [1]],
          ['B', 0, [_d(0), _l(1)], <int>[]],
          ['C', 1, [_e, _d(1)], <int>[]],
        ],
      );
    });

    test('octopus merge opens one lane per extra parent and closes them together', () {
      expect(
        _layout([
          _c('O', ['A', 'B', 'C']),
          _c('B', ['A']),
          _c('C', ['A']),
          _c('A'),
        ]),
        [
          ['O', 0, [_d(0), _l(1), _l(2)], [1, 2]],
          ['B', 1, [_l(0), _d(1), _l(2)], <int>[]],
          ['C', 2, [_l(0), _l(1), _d(2)], <int>[]],
          ['A', 0, [_d(0), _l(1), _l(2)], [1, 2]],
        ],
      );
    });

    test('a merge parent that is already a tip joins the existing lane', () {
      expect(
        _layout([
          _c('H', ['B']),
          _c('M', ['A', 'B']),
          _c('A', ['B']),
          _c('B'),
        ]),
        [
          ['H', 0, [_d(0)], <int>[]],
          ['M', 1, [_l(0), _d(1)], [0]],
          ['A', 1, [_l(0), _d(1)], <int>[]],
          ['B', 0, [_d(0), _l(1)], [1]],
        ],
      );
    });

    test('two unrelated roots each get their own lane', () {
      expect(_layout([_c('X'), _c('Y')]), [
        ['X', 0, [_d(0)], <int>[]],
        ['Y', 0, [_d(0)], <int>[]],
      ]);
      expect(_layout([_c('X', ['P']), _c('Y', ['Q']), _c('P'), _c('Q')]), [
        ['X', 0, [_d(0)], <int>[]],
        ['Y', 1, [_l(0), _d(1)], <int>[]],
        ['P', 0, [_d(0), _l(1)], <int>[]],
        ['Q', 1, [_e, _d(1)], <int>[]],
      ]);
    });

    test('repeated merges of the same branch reuse its lane', () {
      expect(
        _layout([
          _c('M2', ['M1', 'F2']),
          _c('F2', ['F1']),
          _c('M1', ['A', 'F1']),
          _c('F1', ['A']),
          _c('A'),
        ]),
        [
          ['M2', 0, [_d(0), _l(1)], [1]],
          ['F2', 1, [_l(0), _d(1)], <int>[]],
          ['M1', 0, [_d(0), _l(1)], [1]],
          ['F1', 1, [_l(0), _d(1)], <int>[]],
          ['A', 0, [_d(0), _l(1)], [1]],
        ],
      );
    });

    test('graph rows compare by commit identity and layout', () {
      final commit = _c('A');
      final a = GraphRow(commit: commit, lane: 0, cells: [_d(0)], joins: const []);
      final b = GraphRow(commit: commit, lane: 0, cells: [_d(0)], joins: const []);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == GraphRow(commit: _c('A'), lane: 0, cells: [_d(0)], joins: const []), isFalse);
      expect(_l(1), isNot(_d(1)));
      expect(_e.lane, isNull);
    });
  });
}
