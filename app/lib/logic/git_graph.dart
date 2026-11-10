import 'package:flutter/foundation.dart';

import '../src/rust/api/types.dart';

const List<String> laneColors = [
  '#5865f2',
  '#23a55a',
  '#f0b132',
  '#f23f42',
  '#eb459e',
  '#00b8d4',
  '#a855f7',
  '#10b981',
  '#f97316',
  '#e11d48',
];

const double laneW = 20;
const double rowH = 44;
const double dotR = 4.5;

String colorFor(int lane) => laneColors[lane % laneColors.length];

String shortHash(String hash) => hash.length > 7 ? hash.substring(0, 7) : hash;

enum LaneCellType { empty, line, dot }

@immutable
class LaneCell {
  const LaneCell.empty() : type = LaneCellType.empty, lane = null;

  const LaneCell.line(int this.lane) : type = LaneCellType.line;

  const LaneCell.dot(int this.lane) : type = LaneCellType.dot;

  final LaneCellType type;
  final int? lane;

  @override
  bool operator ==(Object other) => other is LaneCell && other.type == type && other.lane == lane;

  @override
  int get hashCode => Object.hash(type, lane);

  @override
  String toString() => lane == null ? 'LaneCell.${type.name}()' : 'LaneCell.${type.name}($lane)';
}

@immutable
class GraphRow {
  const GraphRow({required this.commit, required this.lane, required this.cells, required this.joins});

  final GitLogEntry commit;
  final int lane;
  final List<LaneCell> cells;
  final List<int> joins;

  @override
  bool operator ==(Object other) =>
      other is GraphRow &&
      identical(other.commit, commit) &&
      other.lane == lane &&
      listEquals(other.cells, cells) &&
      listEquals(other.joins, joins);

  @override
  int get hashCode => Object.hash(identityHashCode(commit), lane, Object.hashAll(cells), Object.hashAll(joins));

  @override
  String toString() => 'GraphRow(${commit.hash}, lane: $lane, cells: $cells, joins: $joins)';
}

List<GraphRow> buildGraphRows(List<GitLogEntry> commits) {
  final tips = <String?>[];
  final rows = <GraphRow>[];

  for (final commit in commits) {
    final String? firstParent = commit.parents.isEmpty ? null : commit.parents[0];

    var lane = tips.indexWhere((t) => t == commit.hash);
    if (lane == -1 && commit.parents.length > 1) {
      lane = tips.indexWhere((t) => t == firstParent);
    }
    if (lane == -1) {
      lane = tips.length;
      tips.add(commit.hash);
    }

    final closes = <int>[];
    for (var i = 0; i < tips.length; i++) {
      if (i != lane && tips[i] == commit.hash) closes.add(i);
    }

    final cells = <LaneCell>[
      for (var i = 0; i < tips.length; i++)
        if (tips[i] == null)
          const LaneCell.empty()
        else if (i == lane)
          LaneCell.dot(i)
        else
          LaneCell.line(i),
    ];

    final joins = <int>[...closes];
    for (final parent in commit.parents.skip(1)) {
      var pLane = tips.indexWhere((t) => t == parent);
      if (pLane == -1) {
        pLane = tips.length;
        tips.add(parent);
        cells.add(LaneCell.line(pLane));
      }
      joins.add(pLane);
    }

    rows.add(GraphRow(commit: commit, lane: lane, cells: cells, joins: joins));

    tips[lane] = firstParent;
    for (final i in closes) {
      tips[i] = null;
    }
    while (tips.isNotEmpty && tips.last == null) {
      tips.removeLast();
    }
  }

  return rows;
}
