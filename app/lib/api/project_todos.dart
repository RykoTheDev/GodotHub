import '../src/rust/api/project_todos.dart' as todos;
import '../src/rust/api/todo_sync.dart' as sync_api;
import '../src/rust/api/types.dart';

abstract final class ProjectTodosApi {
  static Future<List<ProjectTodo>> list(String projectId) => todos.listProjectTodos(projectId: projectId);

  static Future<List<ProjectTodo>> save(String projectId, List<ProjectTodo> projectTodos) =>
      todos.saveProjectTodos(projectId: projectId, todos: projectTodos);

  static Future<TodoSyncResult> sync(String projectId, bool scanComments) =>
      sync_api.syncProjectTodos(projectId: projectId, scanComments: scanComments);

  static Future<TodoGitActivity> activity(String projectId, int number) => sync_api.todoGitActivity(projectId: projectId, number: number);

  static Future<List<String>> resources(String projectId) => sync_api.listProjectResources(projectId: projectId);

  static Future<void> openLink(String projectId, String path, [int? line]) =>
      sync_api.openTodoLink(projectId: projectId, path: path, line: line);

  static Future<List<OpenTodo>> open() => todos.listOpenTodos();
}
