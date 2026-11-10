import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/ui_prefs.dart';

const contributorsCacheKey = 'godothub_contributors_cache';
const contributorsCacheTtl = Duration(hours: 24);
const contributorsRepoOwner = 'RykoTheDev';
const contributorsRepoName = 'GodotHub';

@immutable
class Contributor {
  const Contributor({required this.login, required this.avatarUrl, required this.contributions});

  factory Contributor.fromJson(Map<String, Object?> json) => Contributor(
    login: json['login'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    contributions: (json['contributions'] as num?)?.toInt() ?? 0,
  );

  final String login;
  final String avatarUrl;
  final int contributions;

  Map<String, Object?> toJson() => {'login': login, 'avatar_url': avatarUrl, 'contributions': contributions};

  @override
  bool operator ==(Object other) =>
      other is Contributor && other.login == login && other.avatarUrl == avatarUrl && other.contributions == contributions;

  @override
  int get hashCode => Object.hash(login, avatarUrl, contributions);
}

@immutable
class ContributorsState {
  const ContributorsState({this.contributors = const [], this.loading = true});

  final List<Contributor> contributors;
  final bool loading;

  @override
  bool operator ==(Object other) =>
      other is ContributorsState && listEquals(other.contributors, contributors) && other.loading == loading;

  @override
  int get hashCode => Object.hash(Object.hashAll(contributors), loading);
}

typedef ContributorsFetcher = Future<List<Contributor>> Function();

Future<List<Contributor>> fetchGithubContributors() async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.https('api.github.com', '/repos/$contributorsRepoOwner/$contributorsRepoName/contributors', {'per_page': '100'}),
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    final data = jsonDecode(body) as List<Object?>;
    return [for (final item in data.whereType<Map<String, Object?>>()) Contributor.fromJson(item)];
  } finally {
    client.close(force: true);
  }
}

final contributorsFetcherProvider = Provider<ContributorsFetcher>((ref) => fetchGithubContributors);

final contributorsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

List<Contributor>? readContributorsCache(DateTime now) {
  try {
    final raw = UiPrefsStore.instance.getItem(contributorsCacheKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final timestamp = (decoded['timestamp'] as num).toInt();
    if (now.millisecondsSinceEpoch - timestamp > contributorsCacheTtl.inMilliseconds) return null;
    final data = decoded['data'] as List<Object?>;
    return [for (final item in data.whereType<Map<String, Object?>>()) Contributor.fromJson(item)];
  } catch (_) {
    return null;
  }
}

void writeContributorsCache(List<Contributor> data, DateTime now) {
  try {
    UiPrefsStore.instance.setItem(
      contributorsCacheKey,
      jsonEncode({'data': [for (final c in data) c.toJson()], 'timestamp': now.millisecondsSinceEpoch}),
    );
  } catch (_) {}
}

final contributorsProvider = NotifierProvider<ContributorsNotifier, ContributorsState>(ContributorsNotifier.new);

class ContributorsNotifier extends Notifier<ContributorsState> {
  @override
  ContributorsState build() {
    final now = ref.read(contributorsClockProvider);
    final cached = readContributorsCache(now());
    if (cached != null) return ContributorsState(contributors: cached, loading: false);
    var cancelled = false;
    ref.onDispose(() => cancelled = true);
    final fetcher = ref.read(contributorsFetcherProvider);
    scheduleMicrotask(() async {
      try {
        final data = await fetcher();
        if (cancelled) return;
        final filtered = data.where((c) => c.login != 'dependabot[bot]').toList(growable: false);
        writeContributorsCache(filtered, now());
        state = ContributorsState(contributors: filtered, loading: false);
      } catch (_) {
        if (cancelled) return;
        state = ContributorsState(contributors: state.contributors, loading: false);
      }
    });
    return const ContributorsState();
  }
}
