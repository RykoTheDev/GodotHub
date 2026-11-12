import 'package:godothub/src/rust/api/types.dart';

import 'fake_rust.dart';

class FakeGitRepo {
  FakeGitRepo({
    this.files = const [],
    this.remotes = const [],
    this.branches = const [GitBranchInfo(name: 'main', isCurrent: true, hasUpstream: true)],
    this.commits = const [],
    this.stashes = const [],
    this.worktrees = const [],
    this.auth = const GitAuthState(pats: []),
    this.protectedBranch = false,
    this.merging = false,
    this.conflicts = const [],
    GitAheadBehind? aheadBehind,
  }) : aheadBehind = aheadBehind ?? GitAheadBehind(ahead: BigInt.zero, behind: BigInt.zero);

  List<GitChangedFile> files;
  List<GitRemoteInfo> remotes;
  List<GitBranchInfo> branches;
  List<GitLogEntry> commits;
  List<GitStashEntry> stashes;
  List<GitWorktree> worktrees;
  GitAuthState auth;
  bool protectedBranch;
  bool merging;
  List<String> conflicts;
  GitAheadBehind aheadBehind;
  GitDiffResult diff = const GitDiffResult(hunks: []);
  final List<String> calls = [];

  void install(FakeRustApi rust) {
    Future<void> record(String call) async => calls.add(call);
    rust
      ..on('crateApiWatcherStartGitFsWatcher', ({required String path}) => record('watch'))
      ..on('crateApiWatcherStopGitFsWatcher', () => record('unwatch'))
      ..on('crateApiGitAuthGetGitAuthState', () async => auth)
      ..on('crateApiGitAuthDisconnectGitAuth', ({required String provider}) => record('disconnect:$provider'))
      ..on('crateApiGitAuthGitBranchProtection', ({required String path}) async => protectedBranch)
      ..on('crateApiGitGitChangedFiles', ({required String path}) async => files)
      ..on('crateApiGitGitListRemotes', ({required String path}) async => remotes)
      ..on('crateApiGitGitListBranches', ({required String path}) async => branches)
      ..on('crateApiGitGitLogEntries', ({required String path}) async => commits)
      ..on('crateApiGitGitStashList', ({required String path}) async => stashes)
      ..on('crateApiGitGitAheadBehind', ({required String path}) async => aheadBehind)
      ..on('crateApiGitGitIsMerging', ({required String path}) async => merging)
      ..on('crateApiGitGitMergeConflictFiles', ({required String path}) async => conflicts)
      ..on('crateApiGitGitWorktreeList', ({required String path}) async => worktrees)
      ..on('crateApiGitGitStageFile', ({required String path, required String filePath}) => record('stage:$filePath'))
      ..on('crateApiGitGitUnstageFile', ({required String path, required String filePath}) => record('unstage:$filePath'))
      ..on('crateApiGitGitDiscardFile', ({required String path, required String filePath}) => record('discard:$filePath'))
      ..on('crateApiGitGitDiscardChanges', ({required String path, required bool removeUntracked}) => record('discard-all'))
      ..on('crateApiGitGitCommit', ({required String path, required String message, required bool amend}) async {
        calls.add('commit:$message');
        return 'abc1234';
      })
      ..on('crateApiGitGitCreateBranch', ({required String path, required String name}) => record('create:$name'))
      ..on('crateApiGitGitSwitchBranch', ({required String path, required String name}) async {
        calls.add('switch:$name');
        branches = [
          for (final b in branches) GitBranchInfo(name: b.name, isCurrent: b.name == name, hasUpstream: b.hasUpstream),
          if (!branches.any((b) => b.name == name)) GitBranchInfo(name: name, isCurrent: true, hasUpstream: false),
        ];
      })
      ..on('crateApiGitGitDeleteBranch', ({required String path, required String name}) => record('delete:$name'))
      ..on('crateApiGitGitBranchPublish', ({required String path, required String name}) => record('publish:$name'))
      ..on('crateApiGitGitPush', ({required String path, bool? force}) async {
        calls.add(force == true ? 'push-force' : 'push');
        return '';
      })
      ..on('crateApiGitGitPull', ({required String path}) async {
        calls.add('pull');
        return '';
      })
      ..on('crateApiGitGitFetch', ({required String path}) async {
        calls.add('fetch');
        return '';
      })
      ..on('crateApiGitGitStashPush', ({required String path, List<String>? paths}) async {
        calls.add('stash');
        return '';
      })
      ..on('crateApiGitGitStashApply', ({required String path, required BigInt index}) => record('apply:$index'))
      ..on('crateApiGitGitStashPop', ({required String path, required BigInt index}) => record('pop:$index'))
      ..on('crateApiGitGitStashDrop', ({required String path, required BigInt index}) => record('drop:$index'))
      ..on('crateApiGitGitStashShow', ({required String path, required BigInt index}) async => diff)
      ..on('crateApiGitGitFileDiff', ({required String path, required String filePath}) async => diff)
      ..on('crateApiGitGitUndoCommit', ({required String path}) => record('undo-commit'))
      ..on('crateApiGitGitUndoPull', ({required String path}) => record('undo-pull'))
      ..on('crateApiGitGitAbortMerge', ({required String path}) => record('abort-merge'))
      ..on('crateApiGitGitResolveConflictOurs', ({required String path, required String filePath}) => record('ours:$filePath'))
      ..on('crateApiGitGitResolveConflictTheirs', ({required String path, required String filePath}) => record('theirs:$filePath'))
      ..on('crateApiGitGitResolveConflictManual', ({required String path, required String filePath}) => record('manual:$filePath'))
      ..on(
        'crateApiGitGitWorktreeAdd',
        ({required String path, required String worktreePath, String? branch}) => record('wt-add:$worktreePath'),
      )
      ..on(
        'crateApiGitGitWorktreeRemove',
        ({required String path, required String worktreePath, bool? force}) => record('wt-remove:$worktreePath'),
      )
      ..on('crateApiGitGitWorktreeSwitch', ({required String path, required String worktreePath}) => record('wt-switch:$worktreePath'))
      ..on('crateApiGitAuthGitOpenPullRequest', ({
        required String path,
        required String branch,
        required String base,
        required String title,
      }) async {
        calls.add('pr:$branch->$base:$title');
        return 'https://example.invalid/pr';
      });
  }
}
