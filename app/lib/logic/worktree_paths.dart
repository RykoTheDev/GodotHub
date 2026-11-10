final _backslashes = RegExp(r'\\');
final _trailingSlashes = RegExp(r'/+$');
final _caseInsensitiveRoot = RegExp(r'^(?:[a-z]:|//)', caseSensitive: false);

String _slashed(String path) => path.replaceAll(_backslashes, '/').replaceAll(_trailingSlashes, '');

String normalizeWorktreePath(String path) {
  final normalized = _slashed(path);
  return _caseInsensitiveRoot.hasMatch(normalized) ? normalized.toLowerCase() : normalized;
}

bool isWithinWorktree(String projectPath, String worktreePath) {
  final project = normalizeWorktreePath(projectPath);
  final root = normalizeWorktreePath(worktreePath);
  return project == root || project.startsWith('$root/');
}

String worktreeProjectPath(String projectPath, String currentRoot, String nextRoot) {
  final project = _slashed(projectPath);
  final root = _slashed(currentRoot);
  final tail = root.length >= project.length ? '' : project.substring(root.length);
  final joined = '${_slashed(nextRoot)}$tail';
  return projectPath.contains(r'\') ? joined.replaceAll('/', r'\') : joined;
}

String defaultWorktreePath(String projectPath) {
  final path = _slashed(projectPath);
  final split = path.lastIndexOf('/');
  return '${path.substring(0, split + 1)}${path.substring(split + 1)}-worktree';
}
