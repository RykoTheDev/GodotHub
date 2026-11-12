import '../src/rust/api/git.dart' as rust;
import '../src/rust/api/types.dart';
import '../src/rust/api/watcher.dart' as watcher;

abstract final class GitApi {
  static Future<GitStatus> status(String path) => rust.getGitStatus(path: path);

  static Future<Map<String, GitStatus>> batchStatus(List<String> paths) => rust.batchGitStatus(paths: paths);

  static Future<String> clone(String url, String dest) => rust.cloneRepo(url: url, dest: dest);

  static Future<String> pull(String path) => rust.gitPull(path: path);

  static Future<String> fetch(String path) => rust.gitFetch(path: path);

  static Future<String> push(String path, [bool? force]) => rust.gitPush(path: path, force: force ?? false);

  static Future<String> pushForce(String path) => rust.gitPush(path: path, force: true);

  static Future<List<GitLogEntry>> logEntries(String path) => rust.gitLogEntries(path: path);

  static Future<List<GitRemoteInfo>> listRemotes(String path) => rust.gitListRemotes(path: path);

  static Future<GitAheadBehind?> aheadBehind(String path) => rust.gitAheadBehind(path: path);

  static Future<GitCommitDetails> showCommit(String path, String hash) => rust.gitShowCommit(path: path, hash: hash);

  static Future<void> startFsWatcher(String path) => watcher.startGitFsWatcher(path: path);

  static Future<void> stopFsWatcher() => watcher.stopGitFsWatcher();

  static Future<List<GitBranchInfo>> listBranches(String path) => rust.gitListBranches(path: path);

  static Future<void> switchBranch(String path, String name) => rust.gitSwitchBranch(path: path, name: name);

  static Future<void> branchPublish(String path, String name) => rust.gitBranchPublish(path: path, name: name);

  static Future<void> createBranch(String path, String name) => rust.gitCreateBranch(path: path, name: name);

  static Future<void> deleteBranch(String path, String name) => rust.gitDeleteBranch(path: path, name: name);

  static Future<String> stashPush(String path, [List<String>? paths]) => rust.gitStashPush(path: path, paths: paths);

  static Future<List<GitStashEntry>> stashList(String path) => rust.gitStashList(path: path);

  static Future<void> stashApply(String path, int index) => rust.gitStashApply(path: path, index: BigInt.from(index));

  static Future<GitDiffResult> stashShow(String path, int index) => rust.gitStashShow(path: path, index: BigInt.from(index));

  static Future<void> stashPop(String path, int index) => rust.gitStashPop(path: path, index: BigInt.from(index));

  static Future<void> stashDrop(String path, int index) => rust.gitStashDrop(path: path, index: BigInt.from(index));

  static Future<List<GitChangedFile>> changedFiles(String path) => rust.gitChangedFiles(path: path);

  static Future<void> discardChanges(String path, bool removeUntracked) =>
      rust.gitDiscardChanges(path: path, removeUntracked: removeUntracked);

  static Future<void> discardFile(String path, String filePath) => rust.gitDiscardFile(path: path, filePath: filePath);

  static Future<GitInitOutcome> initProject(String path, [GitInitOptions? options]) => rust.gitInitProject(path: path, options: options);

  static Future<bool> isAvailable() => rust.gitIsAvailable();

  static Future<void> stageFile(String path, String filePath) => rust.gitStageFile(path: path, filePath: filePath);

  static Future<void> unstageFile(String path, String filePath) => rust.gitUnstageFile(path: path, filePath: filePath);

  static Future<String> commit(String path, String message, [bool? amend]) =>
      rust.gitCommit(path: path, message: message, amend: amend ?? false);

  static Future<GitDiffResult> fileDiff(String path, String filePath) => rust.gitFileDiff(path: path, filePath: filePath);

  static Future<void> undoCommit(String path) => rust.gitUndoCommit(path: path);

  static Future<void> undoPull(String path) => rust.gitUndoPull(path: path);

  static Future<List<String>> mergeConflictFiles(String path) => rust.gitMergeConflictFiles(path: path);

  static Future<void> resolveConflictOurs(String path, String filePath) => rust.gitResolveConflictOurs(path: path, filePath: filePath);

  static Future<void> resolveConflictTheirs(String path, String filePath) => rust.gitResolveConflictTheirs(path: path, filePath: filePath);

  static Future<void> resolveConflictManual(String path, String filePath) => rust.gitResolveConflictManual(path: path, filePath: filePath);

  static Future<void> abortMerge(String path) => rust.gitAbortMerge(path: path);

  static Future<bool> isMerging(String path) => rust.gitIsMerging(path: path);

  static Future<void> openTerminal(String path) => rust.openTerminal(path: path);

  static Future<List<GitWorktree>> worktreeList(String path) => rust.gitWorktreeList(path: path);

  static Future<void> worktreeSwitch(String path, String worktreePath) => rust.gitWorktreeSwitch(path: path, worktreePath: worktreePath);

  static Future<void> worktreeAdd(String path, String worktreePath, [String? branch]) =>
      rust.gitWorktreeAdd(path: path, worktreePath: worktreePath, branch: branch);

  static Future<void> worktreeRemove(String path, String worktreePath, [bool force = false]) =>
      rust.gitWorktreeRemove(path: path, worktreePath: worktreePath, force: force);
}
