import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _whitespace = RegExp(r'\s+');

bool matchesSearch(String query, Iterable<String?> terms) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final hay = terms.where((term) => term != null && term.isNotEmpty).join(' ').toLowerCase();
  return q.split(_whitespace).every(hay.contains);
}

@immutable
class SectionSearchState {
  const SectionSearchState({this.query = '', this.visible});

  final String query;
  final Set<String>? visible;

  bool get noResults => query.trim().isNotEmpty && visible != null && visible!.isEmpty;

  @override
  bool operator ==(Object other) => other is SectionSearchState && other.query == query && setEquals(other.visible, visible);

  @override
  int get hashCode => Object.hash(query, visible == null ? null : Object.hashAllUnordered(visible!));
}

final sectionSearchProvider = NotifierProvider.autoDispose<SectionSearchNotifier, SectionSearchState>(SectionSearchNotifier.new);

class SectionSearchNotifier extends Notifier<SectionSearchState> {
  late final FocusNode focusNode = FocusNode(debugLabel: 'section-search');

  @override
  SectionSearchState build() {
    ref.onDispose(focusNode.dispose);
    return const SectionSearchState();
  }

  void setQuery(String query) => state = SectionSearchState(query: query, visible: state.visible);

  void reportMatch(String id, bool matched) {
    final previous = state.visible;
    final Set<String> next;
    if (previous == null) {
      next = matched ? {id} : <String>{};
    } else {
      next = {...previous};
      if (matched) {
        next.add(id);
      } else {
        next.remove(id);
      }
    }
    state = SectionSearchState(query: state.query, visible: next);
  }

  void clear() {
    state = SectionSearchState(visible: state.visible);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (ref.mounted && focusNode.context != null) focusNode.requestFocus();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void reset() => state = SectionSearchState(query: state.query);
}
