import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../logic/locale.dart';
import '../src/rust/api/types.dart';
import '../state/godot_versions.dart';

const versionFiltersKey = 'godothub_version_filters';
const versionSortKey = 'godothub_version_sort';
const versionInstalledSortKey = 'godothub_version_sort_installed';
const newIssueUrl = 'https://github.com/RykoTheDev/GodotHub/issues/new';

enum VersionSort {
  latest('latest', 'sort_version_latest'),
  oldest('oldest', 'sort_version_oldest'),
  recentlyInstalled('recently_installed', 'sort_version_recently_installed'),
  oldestInstalled('oldest_installed', 'sort_version_oldest_installed'),
  nameAsc('name_asc', 'sort_name_asc'),
  nameDesc('name_desc', 'sort_name_desc');

  const VersionSort(this.id, this.labelKey);

  final String id;
  final String labelKey;

  static VersionSort parse(String? id, {required bool installed}) {
    for (final value in values) {
      if (value.id != id) continue;
      if (!installed && (value == recentlyInstalled || value == oldestInstalled)) return latest;
      return value;
    }
    return latest;
  }
}

const availableSortOptions = [VersionSort.latest, VersionSort.oldest];

enum BuildTypeFilter { standard, mono, both }

enum ChannelFilter { stable, unstable, both }

@immutable
class VersionFilters {
  const VersionFilters({this.buildType = BuildTypeFilter.both, this.channel = ChannelFilter.both});

  final BuildTypeFilter buildType;
  final ChannelFilter channel;

  VersionFilters copyWith({BuildTypeFilter? buildType, ChannelFilter? channel}) =>
      VersionFilters(buildType: buildType ?? this.buildType, channel: channel ?? this.channel);

  String encode() => jsonEncode({'buildType': buildType.name, 'channel': channel.name});

  static VersionFilters decode(String? raw) {
    if (raw == null) return const VersionFilters();
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return const VersionFilters();
      BuildTypeFilter build = BuildTypeFilter.both;
      ChannelFilter channel = ChannelFilter.both;
      for (final value in BuildTypeFilter.values) {
        if (value.name == data['buildType']) build = value;
      }
      for (final value in ChannelFilter.values) {
        if (value.name == data['channel']) channel = value;
      }
      return VersionFilters(buildType: build, channel: channel);
    } catch (_) {
      return const VersionFilters();
    }
  }

  @override
  bool operator ==(Object other) => other is VersionFilters && other.buildType == buildType && other.channel == channel;

  @override
  int get hashCode => Object.hash(buildType, channel);
}

final _chunk = RegExp(r'(\d+)|(\D+)');
final _leadingV = RegExp('^v');
final _versionSeparator = RegExp(r'[.\-]');
final _digits = RegExp(r'^\d+$');
final _minor = RegExp(r'^(\d+)\.(\d+)');

int naturalCompare(String a, String b) {
  final left = _chunk.allMatches(a).toList();
  final right = _chunk.allMatches(b).toList();
  for (var i = 0; i < left.length && i < right.length; i++) {
    final x = left[i];
    final y = right[i];
    if (x.group(1) != null && y.group(1) != null) {
      final diff = BigInt.parse(x.group(1)!).compareTo(BigInt.parse(y.group(1)!));
      if (diff != 0) return diff;
      continue;
    }
    final diff = ghLocaleCompare(x.group(0)!, y.group(0)!);
    if (diff != 0) return diff;
  }
  return left.length.compareTo(right.length);
}

String versionCore(String raw) {
  final parts = raw.trim().toLowerCase().replaceFirst(_leadingV, '').split(_versionSeparator).where((p) => p.isNotEmpty).toList();
  final numeric = <String>[];
  var i = 0;
  while (i < parts.length && _digits.hasMatch(parts[i])) {
    numeric.add(parts[i]);
    i++;
  }
  final channel = i < parts.length ? parts[i] : 'stable';
  return '${numeric.join('.')}-$channel';
}

List<T> reverseTagOrder<T>(List<T> rows, String Function(T row) tagOf) {
  final blocks = <List<T>>[];
  for (final row in rows) {
    if (blocks.isNotEmpty && tagOf(blocks.last.first) == tagOf(row)) {
      blocks.last.add(row);
    } else {
      blocks.add([row]);
    }
  }
  return [for (final block in blocks.reversed) ...block];
}

String minorGroup(String tag) {
  final m = _minor.firstMatch(tag.trim().replaceFirst(_leadingV, ''));
  return m == null ? 'Other' : '${m[1]}.${m[2]}';
}

String sourcePageUrl(VersionSource source, String tag, [String? miseSource]) => switch (source) {
  VersionSource.github => 'https://github.com/godotengine/godot-builds/releases/tag/$tag',
  VersionSource.mise =>
    miseSource != null && miseSource.isNotEmpty
        ? '${miseSource.replaceFirst(RegExp(r'/$'), '')}/tag/$tag'
        : 'https://github.com/godotengine/godot/releases/tag/$tag',
  VersionSource.archive => 'https://godotengine.org/download/archive/$tag/',
};

bool isRateLimited(VersionSource source, String? error) =>
    source == VersionSource.github && RegExp(r'rate\s*limit', caseSensitive: false).hasMatch(error ?? '');

double _installedAt(String iso) => (DateTime.tryParse(iso)?.millisecondsSinceEpoch ?? double.nan).toDouble();

int _byTime(double a, double b) {
  final diff = a - b;
  return diff.isNaN || diff == 0 ? 0 : (diff < 0 ? -1 : 1);
}

List<InstalledGodotVersion> filterAndSortInstalled(List<InstalledGodotVersion> installed, String query, VersionSort sort) {
  final q = query.trim().toLowerCase();
  final list = q.isEmpty
      ? [...installed]
      : [
          for (final v in installed)
            if (v.tag.toLowerCase().contains(q) || (v.customName?.toLowerCase().contains(q) ?? false)) v,
        ];
  String name(InstalledGodotVersion v) => (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag;
  int compare(InstalledGodotVersion a, InstalledGodotVersion b) => switch (sort) {
    VersionSort.oldest => naturalCompare(a.tag, b.tag),
    VersionSort.nameAsc => ghLocaleCompare(name(a), name(b)),
    VersionSort.nameDesc => ghLocaleCompare(name(b), name(a)),
    VersionSort.recentlyInstalled => _byTime(_installedAt(b.installedAt), _installedAt(a.installedAt)),
    VersionSort.oldestInstalled => _byTime(_installedAt(a.installedAt), _installedAt(b.installedAt)),
    VersionSort.latest => naturalCompare(b.tag, a.tag),
  };
  final indexed = [for (var i = 0; i < list.length; i++) (v: list[i], i: i)]
    ..sort((x, y) {
      final diff = compare(x.v, y.v);
      return diff != 0 ? diff : x.i - y.i;
    });
  return [for (final entry in indexed) entry.v];
}

typedef AvailableRow = ({String tag, GodotReleaseAsset asset});

List<(String, List<AvailableRow>)> groupAvailable(List<GodotRelease> available, String query, VersionFilters filters, VersionSort sort) {
  final q = query.trim().toLowerCase();
  final groups = <String, List<AvailableRow>>{};
  for (final release in available) {
    if (q.isNotEmpty && !release.tag.toLowerCase().contains(q)) continue;
    final stable = release.tag.toLowerCase().contains('stable');
    if (filters.channel != ChannelFilter.both && (filters.channel == ChannelFilter.stable) != stable) continue;
    List<AvailableRow>? group;
    for (final asset in release.assets) {
      if (filters.buildType != BuildTypeFilter.both && (filters.buildType == BuildTypeFilter.mono) != asset.isMono) continue;
      (group ??= groups[minorGroup(release.tag)] ??= []).add((tag: release.tag, asset: asset));
    }
  }
  final entries = groups.entries.toList()
    ..sort(
      (a, b) => switch (sort) {
        VersionSort.oldest || VersionSort.nameAsc => naturalCompare(a.key, b.key),
        _ => naturalCompare(b.key, a.key),
      },
    );
  final reverse = sort == VersionSort.oldest || sort == VersionSort.nameAsc;
  return [for (final e in entries) (e.key, reverse ? reverseTagOrder(e.value, (r) => r.tag) : e.value)];
}

bool isAvailableInstalled(List<InstalledGodotVersion> installed, String tag, bool mono) =>
    installed.any((v) => (versionCore(v.tag) == versionCore(tag) || versionCore(v.version) == versionCore(tag)) && v.isMono == mono);

const downloadSourceLabels = {'github': 'GitHub', 'archive': 'Godot Archive', 'mise': 'mise'};

String downloadReport(DownloadErrorInfo error, {required String appVersion, required String os, required String platform}) => [
  'GodotHub - download failed',
  'Version:  ${error.tag}',
  'Source:   ${downloadSourceLabels[error.source] ?? error.source}',
  if (error.assetName.isNotEmpty) 'File:     ${error.assetName}',
  if (error.url.isNotEmpty) 'URL:      ${error.url}',
  'App:      $appVersion',
  'OS:       $os',
  'Platform: $platform',
  '',
  'Error:',
  error.message,
].join('\n');

String downloadIssueUrl(DownloadErrorInfo error, String report) {
  final title = 'Download failed: ${error.tag}';
  final body = ['**What happened?**', '', 'Installing `${error.tag}` failed.', '', '**Details**', '', '```', report, '```'].join('\n');
  return Uri.parse(newIssueUrl).replace(queryParameters: {'title': title, 'body': body}).toString();
}

String installFolderOf(String executablePath) => executablePath.replaceFirst(RegExp(r'[/\\][^/\\]*$'), '');
