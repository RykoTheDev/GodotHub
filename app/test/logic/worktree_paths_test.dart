import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/worktree_paths.dart';

String b(String path) => path.replaceAll('~', r'\');

void main() {
  test('normalizeWorktreePath', () {
    expect(normalizeWorktreePath(b('C:~Projects~Game~')), 'c:/projects/game');
    expect(normalizeWorktreePath('/Home/User/Game//'), '/Home/User/Game');
    expect(normalizeWorktreePath(b('~~Server~Share~Game')), '//server/share/game');
  });

  test('isWithinWorktree', () {
    expect(isWithinWorktree(b('C:~Projects~Game~sub'), 'c:/projects/game'), isTrue);
    expect(isWithinWorktree('/home/a/GameX', '/home/a/Game'), isFalse);
    expect(isWithinWorktree('/home/a/Game', '/home/a/Game/'), isTrue);
    expect(isWithinWorktree('/home/a/game/x', '/home/a/Game'), isFalse);
  });

  test('worktreeProjectPath', () {
    expect(worktreeProjectPath(b('C:~Repo~games~one'), b('C:~Repo'), b('D:~Wt~repo-wt~')), b('D:~Wt~repo-wt~games~one'));
    expect(worktreeProjectPath('/repo/games/one/', '/repo', '/wt/repo'), '/wt/repo/games/one');
    expect(worktreeProjectPath('/repo', '/repo/longer', '/wt'), '/wt');
  });

  test('defaultWorktreePath', () {
    expect(defaultWorktreePath(b('C:~Repo~Game~')), 'C:/Repo/Game-worktree');
    expect(defaultWorktreePath('/home/me/game'), '/home/me/game-worktree');
    expect(defaultWorktreePath('game'), 'game-worktree');
  });
}
