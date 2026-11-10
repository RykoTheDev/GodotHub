import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../i18n/i18n.dart';
import '../logic/open_todos.dart';
import '../src/ui_prefs.dart';
import 'api_data.dart';
import 'projects.dart';
import 'settings.dart';

const String todosChangedSignal = 'app:todos-changed';
const String todoDueNotifiedKey = 'godothub_todo_due_notified';
const Duration todoDueRecheckInterval = Duration(hours: 1);

final todosEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.hasValue && settings.requireValue.projectTodosEnabled;
});

final openTodosProvider = NotifierProvider<OpenTodosNotifier, OpenTodosSnapshot>(OpenTodosNotifier.new);

class OpenTodosNotifier extends Notifier<OpenTodosSnapshot> {
  @override
  OpenTodosSnapshot build() {
    final enabled = ref.watch(todosEnabledProvider);
    ref.watch(projectsProvider.select((projects) => projects.data.map((p) => p.id).join('|')));
    if (!enabled) {
      clearOpenTodos();
    } else {
      unawaited(refreshOpenTodos());
      ref.listenSignal(todosChangedSignal, (_) => unawaited(refreshOpenTodos()));
    }
    void sync() {
      if (ref.mounted) state = openTodos.value;
    }

    openTodos.addListener(sync);
    ref.onDispose(() => openTodos.removeListener(sync));
    return openTodos.value;
  }
}

({String date, List<String> ids}) _readNotified(String today) {
  try {
    final parsed = jsonDecode(UiPrefsStore.instance.getItem(todoDueNotifiedKey) ?? 'null');
    if (parsed is Map && parsed['date'] == today && parsed['ids'] is List) {
      return (date: today, ids: [for (final id in parsed['ids'] as List) if (id is String) id]);
    }
  } catch (_) {}
  return (date: today, ids: const []);
}

void _writeNotified(({String date, List<String> ids}) value) {
  try {
    UiPrefsStore.instance.setItem(todoDueNotifiedKey, jsonEncode({'date': value.date, 'ids': value.ids}));
  } catch (_) {}
}

void checkDueTodos(OpenTodosSnapshot snapshot) {
  final today = localDateValue();
  final notified = _readNotified(today);
  final due = [
    for (final open in snapshot.todos)
      if ((open.todo.dueDate ?? '').isNotEmpty &&
          open.todo.dueDate!.compareTo(today) <= 0 &&
          !notified.ids.contains('${open.projectId}:${open.todo.id}'))
        open,
  ];
  if (due.isEmpty) return;
  final first = due.first;
  final title = due.length == 1
      ? ghTr('todos:due_notification_title_one', args: {'title': first.todo.title})
      : ghTr('todos:due_notification_title_other', count: due.length);
  final body = due.length == 1
      ? first.projectName
      : [
          for (final open in due.take(3)) '${open.todo.title} (${open.projectName})',
          if (due.length > 3) ghTr('todos:due_notification_more', count: due.length - 3),
        ].join('\n');
  _writeNotified((
    date: today,
    ids: [...notified.ids, for (final open in due) '${open.projectId}:${open.todo.id}'],
  ));
  Api.notify(title, body).ignore();
}

final todoDueNotificationsProvider = Provider<void>((ref) {
  final enabled =
      ref.watch(todosEnabledProvider) && (ref.watch(settingsProvider).value?.desktopNotificationsEnabled ?? false);
  if (!enabled) return;
  final snapshot = ref.watch(openTodosProvider);
  if (!snapshot.loaded) return;
  checkDueTodos(snapshot);
  final timer = Timer.periodic(todoDueRecheckInterval, (_) => checkDueTodos(snapshot));
  ref.onDispose(timer.cancel);
});
