import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/git/diff_body.dart';
import 'package:godothub/git/git_sidebar.dart';
import 'package:godothub/git/git_worktrees.dart';
import 'package:godothub/logic/open_todos.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/modals/clone_repo_modal.dart';
import 'package:godothub/modals/commit_details_modal.dart';
import 'package:godothub/modals/contributor_prs_modal.dart';
import 'package:godothub/modals/create_worktree_modal.dart';
import 'package:godothub/modals/diff_viewer_modal.dart';
import 'package:godothub/modals/git_auth_modal.dart';
import 'package:godothub/modals/protected_branch_modal.dart';
import 'package:godothub/modals/release_notes_draft_modal.dart';
import 'package:godothub/src/rust/api/dto.dart' as dto;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_git.dart';
import '../support/fake_rust.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
final opened = <String>[];

GitDiffResult sampleDiff() => const GitDiffResult(
  hunks: [
    GitDiffHunk(
      oldStart: 3,
      oldLines: 2,
      newStart: 3,
      newLines: 3,
      lines: [
        GitDiffLine(kind: 'context', content: 'extends Node'),
        GitDiffLine(kind: 'delete', content: 'var speed = 1'),
        GitDiffLine(kind: 'add', content: 'var speed = 2'),
        GitDiffLine(kind: 'add', content: 'var jump = 4'),
      ],
    ),
  ],
);

Widget sidebar({VoidCallback? onRefresh}) => SizedBox(
  width: 360,
  height: 1000,
  child: GitSidebar(project: base.demo, onClose: () {}, onRefresh: onRefresh ?? () {}),
);

Future<void> hover(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 300));
}

Finder labeled(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label).first;

String g(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('git:$key', count: count, args: args);

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    debugResetOpenTodos();
    opened.clear();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
  });
  tearDown(() => OpenerApi.debugOpenUrl = null);

  group('helpers', () {
    test('diff rows number old and new lines like the React renderer', () {
      final rows = buildDiffRows(sampleDiff());
      expect(rows.first.text, '@@ -3,2 +3,3 @@');
      expect([for (final r in rows.skip(1)) (r.oldNum, r.newNum)], [(3, 3), (4, null), (null, 4), (null, 5)]);
      expect(diffCounts(sampleDiff()), (adds: 2, dels: 1));
    });

    test('status, branch and path helpers', () {
      expect(isStagedChange(const GitChangedFile(path: 'a', status: 'M ')), isTrue);
      expect(isUnstagedChange(const GitChangedFile(path: 'a', status: 'M ')), isFalse);
      expect(isUnstagedChange(const GitChangedFile(path: 'a', status: '??')), isTrue);
      expect(isStagedChange(const GitChangedFile(path: 'a', status: '??')), isFalse);
      expect(isUnstagedChange(const GitChangedFile(path: 'a', status: 'MM')), isTrue);
      expect(suggestedPrBranch('Fix: jump height!\nmore'), 'fix-jump-height');
      expect(suggestedPrBranch('***'), 'changes');
      expect(suggestedPrBranch('a' * 60).length, 48);
      expect(repoBaseName('https://github.com/me/game.git/'), 'game');
      expect(repoBaseName(''), 'repo');
      expect(worktreePathWithParent(r'C:\games\demo-worktree', 'D:/trees/'), 'D:/trees/demo-worktree');
      expect(formatAuthRemaining(65), '1:05');
      const main = GitWorktree(path: 'C:/games/demo', head: 'abc', hasUncommitted: false, isMain: true);
      const nested = GitWorktree(path: 'C:/games/demo/sub', branch: 'b', head: 'def', hasUncommitted: false, isMain: false);
      expect(currentWorktreeOf(r'C:\Games\demo\sub\proj', [main, nested]), same(nested));
      const repo = UserRepoInfo(name: 'game', fullName: 'me/game', cloneUrl: 'u', htmlUrl: 'h', private: false, language: 'GDScript');
      expect(repoMatches(repo, 'gdscr'), isTrue);
      expect(repoMatches(repo, 'rust'), isFalse);
    });
  });

  group('sidebar', () {
    testWidgets('lists staged and unstaged changes and stages a file', (tester) async {
      final repo = FakeGitRepo(
        files: const [
          GitChangedFile(path: 'player.gd', status: 'M '),
          GitChangedFile(path: 'enemy.gd', status: '??'),
        ],
        remotes: const [GitRemoteInfo(name: 'origin', webUrl: 'https://github.com/me/game', repoName: 'me/game')],
        aheadBehind: GitAheadBehind(ahead: BigInt.two, behind: BigInt.zero),
      )..install(rust);
      await base.pumpHost(tester, body: sidebar());
      await base.settle(tester);
      expect(find.text(g('staged_changes').toUpperCase()), findsOneWidget);
      expect(find.text('player.gd'), findsOneWidget);
      expect(find.text('enemy.gd'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('me/game'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('↑2'), findsOneWidget);
      await hover(tester, find.text('enemy.gd'));
      await tester.tap(labeled(g('stage_file')));
      await base.settle(tester);
      expect(repo.calls, contains('stage:enemy.gd'));
      expect(repo.calls, contains('watch'));
      await base.drainToasts(tester);
    });

    testWidgets('commits with Ctrl+Enter and stages everything when nothing is staged', (tester) async {
      final repo = FakeGitRepo(
        files: const [GitChangedFile(path: 'a.gd', status: ' M')],
      )..install(rust);
      var refreshed = 0;
      await base.pumpHost(tester, body: sidebar(onRefresh: () => refreshed++));
      await base.settle(tester);
      final message = find.descendant(of: find.byType(GitSidebar), matching: find.byType(TextField)).first;
      await tester.enterText(message, 'Add jump');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await base.settle(tester);
      expect(repo.calls, containsAllInOrder(['stage:.', 'commit:Add jump']));
      expect(refreshed, greaterThan(0));
      await base.drainToasts(tester);
    });

    testWidgets('a protected branch offers a pull request instead', (tester) async {
      final repo = FakeGitRepo(
        protectedBranch: true,
        files: const [GitChangedFile(path: 'a.gd', status: 'M ')],
        remotes: const [GitRemoteInfo(name: 'origin', webUrl: 'https://github.com/me/game', repoName: 'me/game')],
      )..install(rust);
      await base.pumpHost(tester, body: sidebar());
      await base.settle(tester);
      final message = find.descendant(of: find.byType(GitSidebar), matching: find.byType(TextField)).first;
      await tester.enterText(message, 'Tune jump');
      await base.settle(tester, 3);
      await tester.tap(find.text(g('commit')));
      await base.settle(tester);
      expect(find.byType(ProtectedBranchModal), findsOneWidget);
      expect(
        tester.widget<TextField>(find.descendant(of: find.byType(ProtectedBranchModal), matching: find.byType(TextField))).controller!.text,
        'tune-jump',
      );
      await tester.tap(find.text(g('protected_branch_create_pr')));
      await base.settle(tester);
      expect(
        repo.calls,
        containsAllInOrder([
          'create:tune-jump',
          'switch:tune-jump',
          'commit:Tune jump',
          'publish:tune-jump',
          'pr:tune-jump->main:Tune jump',
        ]),
      );
      expect(find.byType(ProtectedBranchModal), findsNothing);
      expect(opened, ['https://example.invalid/pr']);
      await base.drainToasts(tester);
    });

    testWidgets('the branch menu creates and switches to a new branch', (tester) async {
      final repo = FakeGitRepo(
        branches: const [
          GitBranchInfo(name: 'main', isCurrent: true, hasUpstream: true),
          GitBranchInfo(name: 'old', isCurrent: false, hasUpstream: false),
        ],
      )..install(rust);
      await base.pumpHost(tester, body: sidebar());
      await base.settle(tester);
      await tester.tap(find.text('main').first);
      await base.settle(tester, 4);
      expect(find.text('old'), findsOneWidget);
      await tester.tap(find.text(g('new_branch_btn')));
      await base.settle(tester, 3);
      await tester.enterText(find.widgetWithText(TextField, g('new_branch_placeholder')).last, 'feature');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await base.settle(tester);
      expect(repo.calls, containsAllInOrder(['create:feature', 'switch:feature']));
      await base.drainToasts(tester);
    });

    testWidgets('remote actions push and right-click asks to force push', (tester) async {
      final repo = FakeGitRepo(
        remotes: const [GitRemoteInfo(name: 'origin', webUrl: 'https://gitlab.com/me/game', repoName: 'me/game')],
      )..install(rust);
      await base.pumpHost(tester, body: sidebar());
      await base.settle(tester);
      expect(find.text('GitLab'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(g('push')));
      await base.settle(tester);
      expect(repo.calls, contains('push'));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.bySemanticsLabel(g('push')), buttons: kSecondaryButton);
      await base.settle(tester);
      expect(find.text(g('force_push_confirm_title').toUpperCase()), findsOneWidget);
      await tester.tap(find.text(g('force_push')).last);
      await base.settle(tester);
      expect(repo.calls, contains('push-force'));
      await base.drainToasts(tester);
    });

    testWidgets('the changes context menu stashes and discards everything', (tester) async {
      final repo = FakeGitRepo(
        files: const [GitChangedFile(path: 'a.gd', status: ' M')],
      )..install(rust);
      await base.pumpHost(tester, body: sidebar());
      await base.settle(tester);
      await tester.tap(find.text(g('changes_title').toUpperCase()).first, buttons: kSecondaryButton);
      await base.settle(tester, 4);
      await tester.tap(find.text(g('discard_all')));
      await base.settle(tester);
      expect(repo.calls, containsAllInOrder(['stash', 'discard-all']));
      await base.drainToasts(tester);
    });

    testWidgets('merge conflicts can be resolved and stashes applied', (tester) async {
      final repo = FakeGitRepo(
        merging: true,
        conflicts: const ['scene.tscn'],
        stashes: [GitStashEntry(index: BigInt.zero, message: 'WIP on main')],
      )..install(rust);
      await base.pumpHost(tester, body: sidebar());
      await base.settle(tester);
      expect(find.text(g('merge_in_progress').toUpperCase()), findsOneWidget);
      await tester.tap(find.text(g('use_theirs')));
      await base.settle(tester);
      expect(repo.calls, contains('theirs:scene.tscn'));
      expect(find.text('WIP on main'), findsOneWidget);
      await hover(tester, find.text('WIP on main'));
      await tester.tap(labeled(g('apply_stash')));
      await base.settle(tester);
      expect(repo.calls, contains('apply:0'));
      await base.drainToasts(tester);
    });
  });

  group('modals', () {
    testWidgets('diff viewer shows counts and rows', (tester) async {
      await base.openModal(tester, (close) => DiffViewerModal(title: 'player.gd', fetchDiff: () async => sampleDiff(), onClose: close));
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('@@ -3,2 +3,3 @@'), findsOneWidget);
      expect(find.text('var jump = 4'), findsOneWidget);
    });

    testWidgets('diff viewer shows the empty state', (tester) async {
      await base.openModal(
        tester,
        (close) => DiffViewerModal(
          title: 'x',
          fetchDiff: () async => const GitDiffResult(hunks: []),
          onClose: close,
        ),
      );
      expect(find.text(g('diff_no_diff')), findsOneWidget);
    });

    testWidgets('commit details lists files with status badges', (tester) async {
      rust.on(
        'crateApiGitGitShowCommit',
        ({required String path, required String hash}) async => GitCommitDetails(
          hash: 'abcdef1234',
          message: 'Add enemy',
          author: 'Ryko',
          date: '2026-11-01',
          files: const [
            GitCommitFile(path: 'enemy.gd', status: 'A'),
            GitCommitFile(path: 'old.gd', status: 'D'),
          ],
          diff: sampleDiff(),
        ),
      );
      await base.openModal(tester, (close) => CommitDetailsModal(projectPath: 'C:/games/demo', hash: 'abcdef1234', onClose: close));
      expect(find.text('ADD ENEMY'), findsOneWidget);
      expect(find.text('abcdef1'), findsOneWidget);
      expect(find.text('Ryko'), findsOneWidget);
      expect(find.text('enemy.gd'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('worktree remove requires discarding uncommitted changes', (tester) async {
      final repo = FakeGitRepo(
        worktrees: const [
          GitWorktree(path: 'C:/games/demo', branch: 'main', head: 'aaaaaaa', hasUncommitted: false, isMain: true),
          GitWorktree(path: 'C:/games/demo-worktree', branch: 'feature', head: 'bbbbbbb', hasUncommitted: true, isMain: false),
        ],
      )..install(rust);
      UiPrefsStore.instance.setItem('git-sidebar-worktrees', '1');
      await base.pumpHost(
        tester,
        body: SizedBox(
          width: 360,
          child: GitWorktrees(project: base.demo, onChanged: () {}),
        ),
      );
      await base.settle(tester);
      expect(find.text(g('worktree_current')), findsOneWidget);
      await tester.tap(labeled(ghTr('remove_category_aria', args: {'name': 'feature'})));
      await base.settle(tester);
      expect(find.byType(RemoveWorktreeModal), findsOneWidget);
      await tester.tap(find.text(g('remove_worktree')).last);
      await base.settle(tester, 3);
      expect(repo.calls.where((c) => c.startsWith('wt-remove')), isEmpty);
      await tester.tap(find.text(g('worktree_discard_changes')));
      await base.settle(tester, 3);
      await tester.tap(find.text(g('remove_worktree')).last);
      await base.settle(tester);
      expect(repo.calls, contains('wt-remove:C:/games/demo-worktree'));
      await base.drainToasts(tester);
    });

    testWidgets('create worktree defaults the path and passes the branch', (tester) async {
      final repo = FakeGitRepo()..install(rust);
      var created = 0;
      await base.openModal(
        tester,
        (close) => CreateWorktreeModal(repositoryPath: 'C:/games/demo', onClose: close, onCreated: () => created++),
      );
      expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'C:/games/demo-worktree');
      await tester.enterText(find.byType(TextField).last, 'feature');
      await tester.tap(find.text(g('add_worktree_btn')));
      await base.settle(tester);
      expect(repo.calls, contains('wt-add:C:/games/demo-worktree'));
      expect(created, 1);
    });

    testWidgets('device flow shows the code and finishes on success', (tester) async {
      var polls = 0;
      String? connected;
      rust
        ..on(
          'crateApiGitAuthStartDeviceFlow',
          ({required String provider, String? baseUrl, String? clientId}) async => DeviceFlowStart(
            provider: provider,
            deviceCode: 'dev',
            userCode: 'ABCD-1234',
            verificationUri: 'https://github.com/login/device',
            verificationUriComplete: '',
            interval: BigInt.one,
            expiresIn: BigInt.from(900),
          ),
        )
        ..on('crateApiDtoPollDeviceFlow', ({
          required String provider,
          required String deviceCode,
          String? baseUrl,
          String? clientId,
        }) async {
          polls++;
          return polls < 2
              ? const dto.DeviceFlowPoll(status: dto.DeviceFlowStatus.pending)
              : const dto.DeviceFlowPoll(status: dto.DeviceFlowStatus.success, username: 'ryko');
        });
      var closed = 0;
      await base.openModal(
        tester,
        (close) => GitAuthModal(
          provider: 'github',
          onClose: () {
            closed++;
            close();
          },
          onConnected: (name) => connected = name,
        ),
      );
      expect(find.text('ABCD – 1234'), findsOneWidget);
      expect(find.text(ghTr('settings:git_auth_expires_in', args: {'time': '14:59'})), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 50));
      expect(polls, 2);
      expect(connected, 'ryko');
      expect(find.text(ghTr('git_connected_as', args: {'username': 'ryko'})), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(closed, 1);
    });

    testWidgets('clone browses repos, selects one and imports it', (tester) async {
      Map<String, Object?>? cloned;
      String? importedFrom;
      var done = <String>[];
      rust
        ..on(
          'crateApiGitAuthGetGitAuthState',
          () async => const GitAuthState(
            github: GitAccountInfo(username: 'ryko'),
            pats: [],
          ),
        )
        ..on(
          'crateApiGitAuthListUserRepos',
          ({required String provider, required int page}) async => const UserRepoPage(
            repos: [
              UserRepoInfo(name: 'game', fullName: 'ryko/game', cloneUrl: 'https://github.com/ryko/game.git', htmlUrl: '', private: true),
              UserRepoInfo(
                name: 'tools',
                fullName: 'ryko/tools',
                cloneUrl: 'https://github.com/ryko/tools.git',
                htmlUrl: '',
                private: false,
              ),
            ],
            hasMore: false,
          ),
        )
        ..on('crateApiGitCloneRepo', ({required String url, required String dest}) async {
          cloned = {'url': url, 'dest': dest};
          return '$dest/game';
        })
        ..on('crateApiProjectsImportProject', ({required String path, required String godotVersion, String? category}) async {
          importedFrom = path;
          return base.demo;
        });
      await base.openModal(
        tester,
        (close) => CloneRepoModal(defaultLocation: 'C:/games', onClose: close, onCloned: (id) => done = [...done, id]),
        settings: copySettings(baseSettings, setupComplete: true, openAfterImport: false),
      );
      expect(find.text('@ryko'), findsOneWidget);
      expect(find.text('ryko/tools'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'gam');
      await base.settle(tester, 3);
      expect(find.text('ryko/tools'), findsNothing);
      await tester.tap(find.text('ryko/game'));
      await base.settle(tester, 3);
      await tester.tap(find.text(ghTr('clone_import')));
      await base.settle(tester);
      expect(cloned, {'url': 'https://github.com/ryko/game.git', 'dest': 'C:/games'});
      expect(importedFrom, 'C:/games/game');
      expect(done, ['p1']);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('clone without an account validates the url', (tester) async {
      rust.on('crateApiGitAuthGetGitAuthState', () async => const GitAuthState(pats: []));
      await base.openModal(tester, (close) => CloneRepoModal(defaultLocation: 'C:/games', onClose: close, onCloned: (_) {}));
      expect(find.text(ghTr('clone_repo_no_account')), findsOneWidget);
      await tester.tap(find.text(ghTr('clone_import')));
      await base.settle(tester, 3);
      expect(find.text(ghTr('clone_repo_error_url')), findsOneWidget);
    });

    testWidgets('contributor PRs list badges and counts', (tester) async {
      await base.openModal(
        tester,
        (close) => ContributorPrsModal(
          login: 'ryko',
          avatarUrl: '',
          onClose: close,
          fetch: (_) async => const [
            ContributorPr(
              number: 12,
              title: 'Add console',
              state: 'closed',
              htmlUrl: '',
              createdAt: '2026-10-01T00:00:00Z',
              mergedAt: '2026-10-02',
            ),
            ContributorPr(number: 13, title: 'Fix tray', state: 'open', htmlUrl: '', createdAt: '2026-10-05T00:00:00Z'),
          ],
        ),
      );
      expect(find.text(ghTr('contributor_pr_count_other', args: {'count': 2})), findsOneWidget);
      expect(find.text('#12'), findsOneWidget);
      expect(find.text(ghTr('contributor_pr_merged')), findsOneWidget);
      expect(find.text(ghTr('contributor_pr_open')), findsOneWidget);
      expect(
        ContributorPr.fromJson({
          'number': 3,
          'title': 't',
          'state': 'closed',
          'pull_request': {'merged_at': 'x'},
        }).state,
        'merged',
      );
    });

    testWidgets('release notes draft builds notes from a tag range', (tester) async {
      List<ChangelogNote>? used;
      String? version;
      rust
        ..on('crateApiChangelogListGitTags', () async => ['v1.1.0', 'v1.0.0'])
        ..on(
          'crateApiChangelogGenerateChangelogDraft',
          ({required String from, required String to}) async => ChangelogDraft(
            from: from,
            to: to,
            count: BigInt.two,
            nextVersion: 'v1.2.0',
            notes: const [ChangelogDraftNote(category: 'fix', text: 'Fix jump', hash: 'abc1234', author: 'Ryko')],
            skipped: const [ChangelogDraftSkipped(hash: 'def5678', subject: 'chore: bump', reason: 'chore')],
          ),
        );
      await base.openModal(
        tester,
        (close) => ReleaseNotesDraftModal(
          onClose: close,
          onUseDraft: (notes, v, date) {
            used = notes;
            version = v;
          },
        ),
      );
      expect(find.text('v1.1.0'), findsOneWidget);
      expect(find.text('HEAD'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ghTr('changelog_draft_generate')));
      await base.settle(tester);
      expect(find.text('Fix jump'), findsOneWidget);
      expect(find.text('chore: bump'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(ghTr('changelog_draft_include')));
      await base.settle(tester, 3);
      await tester.tap(find.text(ghTr('changelog_draft_use')));
      await base.settle(tester, 3);
      expect(version, 'v1.2.0');
      expect([for (final n in used!) '${n.category}:${n.text}'], ['fix:Fix jump', 'improve:chore: bump']);
    });
  });
}
