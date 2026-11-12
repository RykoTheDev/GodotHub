import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/events.dart';
import '../api/git.dart';
import '../api/git_auth.dart';
import '../api/opener.dart';
import '../design/design.dart';
import '../logic/settings_copy.dart';
import '../modals/commit_details_modal.dart';
import '../modals/diff_viewer_modal.dart';
import '../modals/protected_branch_modal.dart';
import '../src/rust/api/types.dart';
import '../state/app_lifecycle.dart';
import '../state/app_signals.dart';
import '../state/git_status.dart' show refreshGitStatusSignal;
import '../state/settings.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/controls/spin.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/context_menu.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/modal_kit.dart';
import 'commit_graph.dart';
import 'git_section.dart';
import 'git_worktrees.dart';
import '../ui/shell/smooth_scroll.dart';

const gitAutoFetchInterval = Duration(milliseconds: 180000);

String _g(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('git:$key', count: count, args: args);

bool isStagedChange(GitChangedFile f) => f.status.isNotEmpty && f.status[0] != ' ' && f.status[0] != '?';

bool isUnstagedChange(GitChangedFile f) => f.status == '??' || (f.status.length > 1 && f.status[1] != ' ' && f.status[1] != '?');

String suggestedPrBranch(String message) {
  var slug = message.split('\n').first.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > 48) slug = slug.substring(0, 48);
  slug = slug.replaceFirst(RegExp(r'-+$'), '');
  return slug.isEmpty ? 'changes' : slug;
}

enum _Remote { push, pull, fetch }

enum _Phase { running, done, error }

class GitSidebar extends ConsumerStatefulWidget {
  const GitSidebar({
    super.key,
    required this.project,
    this.gitStatus,
    required this.onClose,
    required this.onRefresh,
    this.onSwitchProject,
    this.connected = false,
  });

  final Project project;
  final GitStatus? gitStatus;
  final VoidCallback onClose;
  final VoidCallback onRefresh;
  final Future<void> Function(Project project)? onSwitchProject;
  final bool connected;

  @override
  ConsumerState<GitSidebar> createState() => _GitSidebarState();
}

class _GitSidebarState extends ConsumerState<GitSidebar> {
  final TextEditingController _message = TextEditingController();
  final TextEditingController _query = TextEditingController();
  final TextEditingController _newBranch = TextEditingController();
  final OverlayPortalController _branchPortal = OverlayPortalController();
  final Object _branchGroup = Object();
  StreamSubscription<AppEvent>? _changes;
  Timer? _remoteTimer;
  Timer? _autoFetch;
  GitAuthState? _auth;
  bool _committing = false;
  List<GitChangedFile> _files = const [];
  bool _changesLoading = true;
  List<GitRemoteInfo> _remotes = const [];
  bool _remotesLoading = true;
  List<GitBranchInfo> _branches = const [];
  bool _branchesLoading = true;
  String? _switchingBranch;
  bool _syncing = false;
  ({_Remote action, _Phase phase})? _remote;
  List<GitLogEntry> _commits = const [];
  bool _commitsLoading = true;
  List<GitStashEntry> _stashes = const [];
  String? _stashBusy;
  ({Offset position, bool visible, int key})? _menu;
  GitAheadBehind? _aheadBehind;
  bool _merging = false;
  List<String> _conflicts = const [];
  String? _mergeBusy;
  bool _newBranchMode = false;
  String? _deletingBranch;
  bool _publishingBranch = false;
  bool _branchProtected = false;
  String _protectionKey = '';
  int _generation = 0;
  int _menuKey = 0;

  String get _path => widget.project.path;

  @override
  void initState() {
    super.initState();
    _message.addListener(_changed);
    _query.addListener(_changed);
    _newBranch.addListener(_changed);
    _changes = AppEvents.of(AppEventKind.gitProjectChanged).listen((_) {
      _refreshChanges();
      _refreshLog();
      _refreshAheadBehind();
      _refreshMergeState();
    });
    _start();
  }

  @override
  void didUpdateWidget(GitSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.path == widget.project.path) return;
    Future.sync(GitApi.stopFsWatcher).catchError((Object _) {});
    _resetForProject();
    _start();
  }

  @override
  void dispose() {
    _generation++;
    _changes?.cancel();
    _remoteTimer?.cancel();
    _autoFetch?.cancel();
    Future.sync(GitApi.stopFsWatcher).catchError((Object _) {});
    _message.dispose();
    _query.dispose();
    _newBranch.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _resetForProject() {
    if (_branchPortal.isShowing) _branchPortal.hide();
    _autoFetch?.cancel();
    _autoFetch = null;
    setState(() {
      _branches = const [];
      _files = const [];
      _commits = const [];
      _remotes = const [];
      _stashes = const [];
      _aheadBehind = null;
      _merging = false;
      _conflicts = const [];
      _menu = null;
      _newBranchMode = false;
      _protectionKey = '';
      _branchProtected = false;
    });
    _newBranch.clear();
    _message.clear();
    _query.clear();
  }

  Future<T?> _quiet<T>(Future<T> future) => future.then<T?>((value) => value, onError: (Object _) => null);

  Future<void> _start() async {
    final generation = ++_generation;
    final path = _path;
    setState(() {
      _changesLoading = true;
      _remotesLoading = true;
      _branchesLoading = true;
      _commitsLoading = true;
    });
    Future.sync(() => GitApi.startFsWatcher(path)).catchError((Object _) {});
    _refreshAuth();
    final results = await Future.wait<Object?>([
      _quiet(GitApi.changedFiles(path)),
      _quiet(GitApi.listRemotes(path)),
      _quiet(GitApi.listBranches(path)),
      _quiet(GitApi.logEntries(path)),
      _quiet(GitApi.stashList(path)),
      _quiet<GitAheadBehind?>(GitApi.aheadBehind(path)),
      _quiet(GitApi.isMerging(path)),
      _quiet(GitApi.mergeConflictFiles(path)),
    ]);
    if (!mounted || generation != _generation) return;
    setState(() {
      if (results[0] case final List<GitChangedFile> v) _files = v;
      if (results[1] case final List<GitRemoteInfo> v) _remotes = v;
      if (results[2] case final List<GitBranchInfo> v) _branches = v;
      if (results[3] case final List<GitLogEntry> v) _commits = v;
      if (results[4] case final List<GitStashEntry> v) _stashes = v;
      if (results[5] case final GitAheadBehind v) _aheadBehind = v;
      if (results[6] case final bool v) _merging = v;
      if (results[7] case final List<String> v) _conflicts = v;
      _changesLoading = false;
      _remotesLoading = false;
      _branchesLoading = false;
      _commitsLoading = false;
    });
    _syncProtection();
    _syncAutoFetch();
  }

  void _notifyStatus() => AppSignals.emit(refreshGitStatusSignal);

  void _ok(String message) {
    ghToasts.pushToast(GhToastType.success, message);
  }

  void _fail(Object error) => ghToasts.pushToast(GhToastType.error, '$error');

  void _notifyDesktop(String message) {
    if (ref.read(settingsProvider).value?.desktopNotificationsEnabled ?? false) {
      Api.notify('GodotHub', message).catchError((Object _) {});
    }
  }

  Future<void> _refreshAuth() async {
    try {
      final state = await GitAuthApi.getState();
      if (!mounted) return;
      setState(() => _auth = state);
      _syncProtection();
    } catch (_) {}
  }

  Future<void> _refreshChanges() async {
    try {
      final files = await GitApi.changedFiles(_path);
      if (mounted) setState(() => _files = files);
    } catch (_) {}
  }

  Future<void> _refreshLog() async {
    try {
      final commits = await GitApi.logEntries(_path);
      if (mounted) setState(() => _commits = commits);
    } catch (_) {}
  }

  Future<void> _refreshStashes() async {
    try {
      final stashes = await GitApi.stashList(_path);
      if (mounted) setState(() => _stashes = stashes);
    } catch (_) {}
  }

  Future<void> _refreshAheadBehind() async {
    try {
      final value = await GitApi.aheadBehind(_path);
      if (mounted) setState(() => _aheadBehind = value);
    } catch (_) {}
  }

  Future<void> _refreshMergeState() async {
    try {
      final results = await Future.wait<Object>([GitApi.isMerging(_path), GitApi.mergeConflictFiles(_path)]);
      if (!mounted) return;
      setState(() {
        _merging = results[0] as bool;
        _conflicts = results[1] as List<String>;
      });
    } catch (_) {}
  }

  Future<void> _refreshBranches() async {
    final branches = await GitApi.listBranches(_path);
    if (!mounted) return;
    setState(() => _branches = branches);
    _syncProtection();
  }

  GitBranchInfo? get _currentBranchInfo => _branches.where((b) => b.isCurrent).firstOrNull;

  void _syncProtection() {
    final branch = _currentBranchInfo?.name;
    final auth = _auth;
    final key = '$_path|${branch ?? ''}|${_remotes.isNotEmpty}|${auth?.github?.username ?? ''}|${auth?.gitlab?.username ?? ''}';
    if (key == _protectionKey) return;
    _protectionKey = key;
    if (_branchProtected) setState(() => _branchProtected = false);
    if (branch == null || _remotes.isEmpty) return;
    GitAuthApi.branchProtection(_path).then((value) {
      if (mounted && _protectionKey == key) setState(() => _branchProtected = value);
    }, onError: (Object _) {});
  }

  void _syncAutoFetch() {
    final enabled = (ref.read(settingsProvider).value?.gitAutoFetch ?? false) && _remotes.isNotEmpty;
    if (!enabled) {
      _autoFetch?.cancel();
      _autoFetch = null;
      return;
    }
    if (_autoFetch != null) return;
    _runAutoFetch();
    _autoFetch = Timer.periodic(gitAutoFetchInterval, (_) => _runAutoFetch());
  }

  Future<void> _runAutoFetch() async {
    if (_remote != null || ghAppHidden()) return;
    try {
      await GitApi.fetch(_path);
    } catch (_) {
      return;
    }
    if (mounted) _refreshAheadBehind();
  }

  Future<void> _afterHeadChange({bool merge = false}) async {
    widget.onRefresh();
    _notifyStatus();
    await _refreshChanges();
    _refreshLog();
    _refreshAheadBehind();
    if (merge) _refreshMergeState();
  }

  Future<void> _switchBranch(String name) async {
    if (_switchingBranch != null || _branches.any((b) => b.name == name && b.isCurrent)) return;
    setState(() => _switchingBranch = name);
    try {
      await GitApi.switchBranch(_path, name);
      await _refreshBranches();
      await _afterHeadChange();
      _ok(_g('switched_ok', args: {'branch': name}));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _switchingBranch = null);
    }
  }

  Future<void> _createBranch() async {
    final name = _newBranch.text.trim();
    if (name.isEmpty || _deletingBranch != null) return;
    try {
      await GitApi.createBranch(_path, name);
      await GitApi.switchBranch(_path, name);
      await _refreshBranches();
      await _afterHeadChange();
      _newBranch.clear();
      if (mounted) setState(() => _newBranchMode = false);
      _ok(_g('branch_created'));
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _deleteBranch(String name) async {
    if (_deletingBranch != null) return;
    setState(() => _deletingBranch = name);
    try {
      await GitApi.deleteBranch(_path, name);
      await _refreshBranches();
      _ok(_g('branch_deleted'));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _deletingBranch = null);
    }
  }

  Future<void> _publishBranch(String name) async {
    if (_publishingBranch) return;
    setState(() => _publishingBranch = true);
    try {
      await GitApi.branchPublish(_path, name);
      await _refreshBranches();
      _refreshAheadBehind();
      _refreshLog();
      _ok(_g('branch_published'));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _publishingBranch = false);
    }
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await GitApi.pull(_path);
      await GitApi.push(_path);
      await _afterHeadChange(merge: true);
      _ok(_g('synced_ok'));
      _notifyDesktop(_g('synced_ok'));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _stashAction(String busy, Future<void> Function() action, String success, {bool refreshChanges = true}) async {
    if (_stashBusy != null) return;
    setState(() => _stashBusy = busy);
    try {
      await action();
      await _refreshStashes();
      if (refreshChanges) {
        await _refreshChanges();
        _notifyStatus();
        _refreshLog();
      }
      _ok(_g(success));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _stashBusy = null);
    }
  }

  Future<void> _stashPush() => _stashAction('push', () => GitApi.stashPush(_path), 'changes_stashed_ok');

  Future<void> _fileAction(Future<void> Function() action, String success) async {
    try {
      await action();
      await _refreshChanges();
      _notifyStatus();
      _ok(_g(success));
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _discardAll() async {
    try {
      await GitApi.stashPush(_path);
      await GitApi.discardChanges(_path, false);
      await _refreshStashes();
      await _refreshChanges();
      _notifyStatus();
      _refreshLog();
      _ok(_g('discard_all_ok'));
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _undo(Future<void> Function() action, String success, {bool aheadBehind = false}) async {
    try {
      await action();
      await _refreshChanges();
      _refreshLog();
      if (aheadBehind) _refreshAheadBehind();
      widget.onRefresh();
      _notifyStatus();
      _ok(_g(success));
    } catch (e) {
      _fail(e);
    }
  }

  bool get _unpublished => _currentBranchInfo != null && !_currentBranchInfo!.hasUpstream && _remotes.isNotEmpty;

  Future<void> _remoteAction(_Remote action) async {
    if (_remote != null) return;
    final current = _currentBranchInfo;
    final publishing = action == _Remote.push && _unpublished && current != null;
    setState(() => _remote = (action: action, phase: _Phase.running));
    void hold(_Phase phase) {
      if (!mounted) return;
      setState(() => _remote = (action: action, phase: phase));
      _remoteTimer?.cancel();
      _remoteTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _remote = null);
      });
    }

    try {
      if (publishing) {
        await GitApi.branchPublish(_path, current.name);
        await _refreshBranches();
      } else {
        await switch (action) {
          _Remote.push => GitApi.push(_path),
          _Remote.pull => GitApi.pull(_path),
          _Remote.fetch => GitApi.fetch(_path),
        };
      }
      await _afterHeadChange(merge: true);
      hold(_Phase.done);
      final label = publishing
          ? _g('branch_published')
          : switch (action) {
              _Remote.push => _g('pushed_ok'),
              _Remote.pull => _g('pulled_ok'),
              _Remote.fetch => _g('fetched_ok'),
            };
      _ok(label);
      _notifyDesktop(label);
    } catch (e) {
      hold(_Phase.error);
      _fail(e);
    }
  }

  Future<void> _confirmForcePush() async {
    final ok = await showGhConfirmDialog(
      context,
      title: _g('force_push_confirm_title'),
      description: _g('force_push_confirm_desc'),
      confirmLabel: _g('force_push'),
      variant: GhConfirmVariant.danger,
    );
    if (!ok) return;
    try {
      await GitApi.pushForce(_path);
      _refreshAheadBehind();
      _ok(_g('force_pushed'));
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _resolve(String kind, String file) async {
    setState(() => _mergeBusy = kind);
    try {
      await switch (kind) {
        'ours' => GitApi.resolveConflictOurs(_path, file),
        'theirs' => GitApi.resolveConflictTheirs(_path, file),
        _ => GitApi.resolveConflictManual(_path, file),
      };
      await _refreshMergeState();
      await _refreshChanges();
      _ok(_g('resolved_$kind'));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _mergeBusy = null);
    }
  }

  Future<void> _abortMerge() async {
    setState(() => _mergeBusy = 'abort');
    try {
      await GitApi.abortMerge(_path);
      await _refreshMergeState();
      await _refreshChanges();
      _refreshLog();
      widget.onRefresh();
      _notifyStatus();
      _ok(_g('merge_aborted'));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _mergeBusy = null);
    }
  }

  Future<void> _disconnect(String provider) async {
    try {
      await GitAuthApi.disconnect(provider);
      await _refreshAuth();
    } catch (_) {}
  }

  List<GitChangedFile> get _visibleFiles {
    final q = _query.text.trim().toLowerCase();
    return q.isEmpty
        ? _files
        : [
            for (final f in _files)
              if (f.path.toLowerCase().contains(q)) f,
          ];
  }

  Future<void> _commit({bool force = false}) async {
    final msg = _message.text.trim();
    if (msg.isEmpty || _committing) return;
    if (_branchProtected && !force) {
      _openProtectedPrompt();
      return;
    }
    setState(() => _committing = true);
    try {
      if (!_visibleFiles.any(isStagedChange)) await GitApi.stageFile(_path, '.');
      await GitApi.commit(_path, msg, false);
      _message.clear();
      widget.onRefresh();
      _notifyStatus();
      _refreshChanges();
      _refreshLog();
      _refreshAheadBehind();
      _ok(_g('committed_ok'));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  Future<void> _commitToPullRequest(String branch) async {
    final msg = _message.text.trim();
    final base = _currentBranchInfo?.name;
    if (msg.isEmpty || base == null || _committing) return;
    setState(() => _committing = true);
    try {
      await GitApi.createBranch(_path, branch);
      await GitApi.switchBranch(_path, branch);
      if (!_visibleFiles.any(isStagedChange)) await GitApi.stageFile(_path, '.');
      await GitApi.commit(_path, msg, false);
      _message.clear();
      await GitApi.branchPublish(_path, branch);
      final url = await GitAuthApi.openPullRequest(_path, branch, base, msg.split('\n').first);
      _ok(_g('pr_opened_ok', args: {'branch': branch}));
      OpenerApi.openUrl(url).catchError(_fail);
    } finally {
      if (mounted) setState(() => _committing = false);
      await _refreshBranches().catchError((Object _) {});
      widget.onRefresh();
      _notifyStatus();
      _refreshChanges();
      _refreshLog();
      _refreshAheadBehind();
    }
  }

  void _openProtectedPrompt() {
    final current = _currentBranchInfo;
    if (current == null) return;
    showGhModal<void>(context, (modal) {
      void close() => Navigator.of(modal).pop();
      return ProtectedBranchModal(
        branch: current.name,
        suggestedBranch: suggestedPrBranch(_message.text),
        onCommitAnyway: () {
          close();
          _commit(force: true);
        },
        onCreatePullRequest: (branch) async {
          await _commitToPullRequest(branch);
          close();
        },
        onClose: close,
      );
    }).ignore();
  }

  void _openDiff(String title, Future<GitDiffResult> Function() fetch) => showGhModal<void>(
    context,
    (modal) => DiffViewerModal(title: title, fetchDiff: fetch, onClose: () => Navigator.of(modal).pop()),
  ).ignore();

  void _openCommit(String hash) => showGhModal<void>(
    context,
    (modal) => CommitDetailsModal(projectPath: _path, hash: hash, onClose: () => Navigator.of(modal).pop()),
  ).ignore();

  void _toggleBranchMenu() {
    if (_branchPortal.isShowing) {
      _closeBranchMenu();
    } else {
      _branchPortal.show();
      setState(() {});
    }
  }

  void _closeBranchMenu() {
    if (_branchPortal.isShowing) _branchPortal.hide();
    if (mounted) setState(() {});
  }

  Widget _iconAction(
    GhTheme theme, {
    required String tooltip,
    required FaIconData icon,
    required VoidCallback? onPressed,
    required Color hover,
    bool spin = false,
    double size = 3,
    double pad = 1,
  }) => GhTooltip(
    message: tooltip,
    child: GhPressable(
      onPressed: onPressed,
      semanticLabel: tooltip,
      disabledOpacity: 0.4,
      borderRadius: BorderRadius.circular(theme.radiusSm),
      builder: (context, states) {
        Widget glyph = GhIcon(icon, size: theme.space(size), color: states.active ? hover : theme.muted.withValues(alpha: 0.6));
        if (spin) glyph = GhSpinning(child: glyph);
        return GhAnimatedBox(
          padding: EdgeInsets.all(theme.space(pad)),
          color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(theme.radiusSm),
          child: glyph,
        );
      },
    ),
  );

  Widget _hint(GhTheme theme, String text) => Padding(
    padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
    child: Text(
      text,
      style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.5)),
    ),
  );

  Widget _account(GhTheme theme, String label, String username, String provider) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
    decoration: BoxDecoration(
      color: theme.base.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: theme.line.withValues(alpha: 0.6)),
    ),
    child: Row(
      spacing: theme.space(2),
      children: [
        Container(
          width: theme.space(7),
          height: theme.space(7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.mint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.mint.withValues(alpha: 0.3)),
          ),
          child: GhIcon(GhIcons.gitBranch, size: theme.space(3.5), color: theme.mint),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
              ),
              Text(
                '@$username',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted),
              ),
            ],
          ),
        ),
        GhPressable(
          onPressed: () => _disconnect(provider),
          borderRadius: BorderRadius.circular(theme.radiusTag),
          builder: (context, states) => GhAnimatedBox(
            color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(theme.radiusTag),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
            child: Text(
              ghTr('git_disconnect'),
              style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: states.active ? theme.danger : theme.muted),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _accounts(GhTheme theme) {
    final auth = _auth;
    final pats = auth?.pats ?? const <GitPatInfo>[];
    final count = (auth?.github != null ? 1 : 0) + (auth?.gitlab != null ? 1 : 0) + pats.length;
    return GitSection(
      title: _g('auth_connected_accounts'),
      count: count,
      storageKey: 'git-sidebar-connected-accounts',
      defaultOpen: false,
      children: count == 0
          ? [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(3)),
                child: Text(
                  _g('auth_connect_hint'),
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.6), lineHeight: 1.625),
                ),
              ),
            ]
          : [
              if (auth?.github case final account?) _account(theme, 'GitHub', account.username, 'github'),
              if (auth?.gitlab case final account?) _account(theme, 'GitLab', account.username, 'gitlab'),
              if (pats.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(theme.space(1), theme.space(1), theme.space(1), 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(1),
                    children: [
                      for (final pat in pats)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
                          decoration: BoxDecoration(
                            color: theme.mint.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(theme.radiusItem),
                            border: Border.all(color: theme.mint.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            spacing: theme.space(1.5),
                            children: [
                              GhIcon(GhIcons.check, size: theme.space(3), color: theme.mint),
                              Expanded(
                                child: Text(
                                  pat.host,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted),
                                ),
                              ),
                              Text(
                                '@${pat.username}',
                                style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
    );
  }

  Widget _tinted(GhTheme theme, {required String label, required Color color, required VoidCallback? onPressed}) => Expanded(
    child: GhPressable(
      onPressed: onPressed,
      disabledOpacity: 0.4,
      disabledCursor: SystemMouseCursors.wait,
      borderRadius: BorderRadius.circular(theme.radiusTag),
      builder: (context, states) => GhAnimatedBox(
        color: color.withValues(alpha: states.active ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(theme.radiusTag),
        padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(1)),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: color),
        ),
      ),
    ),
  );

  Widget _merge(GhTheme theme) {
    final busy = _mergeBusy != null;
    return GitSection(
      title: _g('merge_in_progress'),
      count: _conflicts.length,
      children: [
        if (_conflicts.isEmpty)
          _hint(theme, '…')
        else
          for (final f in _conflicts)
            Container(
              padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
              decoration: BoxDecoration(
                color: theme.danger.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(color: theme.danger.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(1.5),
                children: [
                  Text(
                    f,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.ink),
                  ),
                  Row(
                    spacing: theme.space(1),
                    children: [
                      _tinted(theme, label: _g('use_ours'), color: theme.mint, onPressed: busy ? null : () => _resolve('ours', f)),
                      _tinted(theme, label: _g('use_theirs'), color: theme.amber, onPressed: busy ? null : () => _resolve('theirs', f)),
                      _tinted(
                        theme,
                        label: _g('i_resolved'),
                        color: theme.accentBright,
                        onPressed: busy ? null : () => _resolve('manual', f),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        GhPressable(
          onPressed: busy ? null : _abortMerge,
          disabledOpacity: 0.4,
          disabledCursor: SystemMouseCursors.wait,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          builder: (context, states) => GhAnimatedBox(
            color: theme.danger.withValues(alpha: states.active ? 0.1 : 0),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
            padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: theme.space(1.5),
              children: [
                _mergeBusy == 'abort'
                    ? GhSpinning(
                        child: GhIcon(GhIcons.trash, size: theme.space(3.5), color: theme.danger),
                      )
                    : GhIcon(GhIcons.trash, size: theme.space(3.5), color: theme.danger),
                Text(
                  _g('abort_merge'),
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.danger),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _remoteButton(GhTheme theme, _Remote key) {
    final active = _remote?.action == key;
    final phase = active ? _remote!.phase : null;
    final ahead = _aheadBehind?.ahead.toInt() ?? 0;
    final behind = _aheadBehind?.behind.toInt() ?? 0;
    final pending = switch (key) {
      _Remote.push => ahead,
      _Remote.pull => behind,
      _Remote.fetch => 0,
    };
    final pendingLabel = _g(key == _Remote.push ? 'commits_to_push' : 'commits_to_pull', count: pending);
    final isPublish = key == _Remote.push && _unpublished;
    final publishRemote = _remotes.where((r) => r.name == 'origin').firstOrNull?.name ?? _remotes.firstOrNull?.name;
    final actionLabel = isPublish
        ? (publishRemote != null ? _g('publish_branch_to', args: {'remote': publishRemote}) : _g('publish_branch'))
        : _g(key.name);
    final tooltip = active && !isPublish
        ? _g('${key.name}ing')
        : pending > 0
        ? pendingLabel
        : actionLabel;
    final icon = switch (key) {
      _Remote.push => GhIcons.arrowUp,
      _Remote.pull => GhIcons.cloudArrowDown,
      _Remote.fetch => GhIcons.download,
    };
    final (background, foreground) = switch (phase) {
      _Phase.running => (theme.accent, theme.overlay),
      _Phase.done => (theme.mint, theme.overlay),
      _Phase.error => (theme.danger, theme.overlay),
      null => (theme.overlay, theme.muted),
    };
    return Expanded(
      child: GhTooltip(
        message: tooltip,
        child: GhPressable(
          onPressed: _remote != null ? null : () => _remoteAction(key),
          onSecondaryTapUp: key != _Remote.push || isPublish ? null : (_) => _confirmForcePush(),
          disabledOpacity: null,
          semanticLabel: actionLabel,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          builder: (context, states) {
            final idleHover = phase == null && states.active;
            final Widget glyph = switch (phase) {
              _Phase.running => GhSpinnerIcon(size: 4, color: foreground),
              _Phase.done => GhIcon(GhIcons.check, size: theme.space(3.5), color: foreground),
              _Phase.error => GhIcon(GhIcons.x, size: theme.space(3.5), color: foreground),
              null =>
                isPublish
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
                        child: Text(
                          _g('publish_branch'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: idleHover ? theme.ink : foreground),
                        ),
                      )
                    : GhIcon(icon, size: theme.space(3.5), color: idleHover ? theme.ink : foreground),
            };
            return Stack(
              clipBehavior: Clip.none,
              children: [
                GhAnimatedBox(
                  height: theme.space(8),
                  color: idleHover ? theme.raised : background,
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4))],
                  alignment: Alignment.center,
                  child: glyph,
                ),
                if (phase == null && pending > 0)
                  PositionedDirectional(
                    top: -theme.space(2),
                    end: -theme.space(2),
                    child: Semantics(
                      label: pendingLabel,
                      child: Container(
                        constraints: BoxConstraints(minWidth: theme.space(4)),
                        height: theme.space(4),
                        padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: key == _Remote.push ? theme.mint : theme.danger,
                          borderRadius: BorderRadius.circular(theme.space(2)),
                          border: Border.all(color: theme.raised, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 4))],
                        ),
                        child: Text(
                          pending > 99 ? '99+' : '$pending',
                          style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, color: theme.overlay),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _branchMenu(BuildContext context, GhTheme theme, double width) {
    final rows = <Widget>[];
    if (_branchesLoading) {
      rows.add(_hint(theme, ghTr('loading')));
    } else if (_branches.isEmpty) {
      rows.add(_hint(theme, _g('no_branches')));
    } else {
      for (final b in _branches) {
        final current = b.isCurrent;
        final switching = _switchingBranch == b.name;
        rows.add(
          _BranchRow(
            key: ValueKey(b.name),
            branch: b,
            switching: switching,
            enabled: !current && _switchingBranch == null,
            onSwitch: () {
              _closeBranchMenu();
              _switchBranch(b.name);
            },
            trailing: [
              if (current && !b.hasUpstream)
                _iconAction(
                  theme,
                  tooltip: _g('publish_branch'),
                  icon: GhIcons.arrowUp,
                  hover: theme.accent,
                  spin: _publishingBranch,
                  onPressed: _publishingBranch ? null : () => _publishBranch(b.name),
                ),
              if (!current)
                _iconAction(
                  theme,
                  tooltip: _g('delete_branch'),
                  icon: GhIcons.trash,
                  hover: theme.danger,
                  spin: _deletingBranch == b.name,
                  onPressed: _deletingBranch != null ? null : () => _deleteBranch(b.name),
                ),
            ],
            revealTrailing: !current && b.hasUpstream,
          ),
        );
      }
    }
    final footer = _newBranchMode
        ? Row(
            spacing: theme.space(1),
            children: [
              Expanded(
                child: GhTextInput(
                  controller: _newBranch,
                  autofocus: true,
                  size: GhTextSize.x2s,
                  placeholder: _g('new_branch_placeholder'),
                  onSubmitted: (_) => _createBranch(),
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                      _newBranch.clear();
                      setState(() => _newBranchMode = false);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  background: theme.base,
                  borderColor: theme.outline.withValues(alpha: 0.5),
                  focusBorderColor: theme.accentDim,
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
                ),
              ),
              _iconAction(
                theme,
                tooltip: _g('new_branch_btn'),
                icon: GhIcons.check,
                hover: theme.mint,
                size: 3.5,
                pad: 1.5,
                onPressed: _newBranch.text.trim().isEmpty ? null : _createBranch,
              ),
            ],
          )
        : GhPressable(
            onPressed: () => setState(() => _newBranchMode = true),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            builder: (context, states) => GhAnimatedBox(
              color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(theme.radiusItem),
              padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
              child: Row(
                spacing: theme.space(1.5),
                children: [
                  GhIcon(GhIcons.plus, size: theme.space(3), color: theme.accent),
                  Text(
                    _g('new_branch_btn'),
                    style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
                  ),
                ],
              ),
            ),
          );
    return TapRegion(
      groupId: _branchGroup,
      onTapOutside: (_) => _closeBranchMenu(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _closeBranchMenu();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: width,
            constraints: BoxConstraints(maxHeight: theme.space(56)),
            padding: EdgeInsets.all(theme.space(1.5)),
            decoration: BoxDecoration(
              color: theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusMenu),
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: GhScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...rows,
                  Container(
                    margin: EdgeInsets.only(top: theme.space(1)),
                    padding: EdgeInsets.only(top: theme.space(1)),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
                    ),
                    child: footer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _branchSwitcher(GhTheme theme) {
    final open = _branchPortal.isShowing;
    final current = _switchingBranch ?? _currentBranchInfo?.name ?? widget.gitStatus?.branch ?? '…';
    final ahead = _aheadBehind?.ahead.toInt() ?? 0;
    final behind = _aheadBehind?.behind.toInt() ?? 0;
    Widget chip(String text, Color color) => Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(0.5)),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(theme.radiusTag)),
      child: Text(
        text,
        style: theme.text(size: GhTextSize.x4s, weight: GhWeight.semibold, mono: true, color: color),
      ),
    );
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _branchPortal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context, info) {
        final anchor = MatrixUtils.transformRect(info.childPaintTransform, Offset.zero & info.childSize);
        return Stack(
          children: [Positioned(left: anchor.left, top: anchor.bottom + theme.space(1), child: _branchMenu(context, theme, anchor.width))],
        );
      },
      child: TapRegion(
        groupId: _branchGroup,
        child: GhPressable(
          onPressed: _toggleBranchMenu,
          expanded: open,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          builder: (context, states) => GhAnimatedBox(
            color: states.active ? theme.raised : theme.raised.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
            child: Row(
              spacing: theme.space(1.5),
              children: [
                GhIcon(GhIcons.gitBranch, size: theme.space(3), color: theme.accent),
                Expanded(
                  child: Text(
                    current,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.ink),
                  ),
                ),
                if (behind > 0) chip('↓$behind', theme.danger),
                if (ahead > 0) chip('↑$ahead', theme.mint),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: GhDurations.iconTransform,
                  child: GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _remoteLink(GhTheme theme, GitRemoteInfo remote, {required bool primary}) {
    void open() => OpenerApi.openUrl(remote.webUrl).catchError(_fail);
    return GhTooltip(
      message: remote.webUrl,
      child: GhPressable(
        onPressed: open,
        semanticLabel: remote.repoName,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        builder: (context, states) => GhAnimatedBox(
          color: primary
              ? (states.active ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0))
              : (states.active ? theme.raised : theme.base.withValues(alpha: 0.4)),
          borderRadius: primary ? null : BorderRadius.circular(theme.radiusItem),
          border: primary
              ? null
              : Border.all(color: states.active ? theme.accent.withValues(alpha: 0.4) : theme.line.withValues(alpha: 0.6)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
          child: Row(
            spacing: theme.space(1.5),
            children: [
              if (primary) ProviderBadge(webUrl: remote.webUrl) else GhIcon(GhIcons.gitBranch, size: theme.space(3), color: theme.accent),
              Expanded(
                child: Text(
                  remote.repoName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.ink),
                ),
              ),
              GhIcon(
                GhIcons.externalLink,
                size: theme.space(3),
                color: theme.muted.withValues(alpha: primary ? 0.4 : 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _commitBox(GhTheme theme) {
    final hasRemote = !_remotesLoading && _remotes.isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.base.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasRemote) _remoteLink(theme, _remotes.first, primary: true),
          Container(
            decoration: hasRemote
                ? BoxDecoration(
                    border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.5))),
                  )
                : null,
            child: GhTextInput(
              controller: _message,
              maxLines: 3,
              minLines: 3,
              size: GhTextSize.xs,
              bordered: false,
              placeholder: ghTr('git_commit_placeholder'),
              background: theme.raised.withValues(alpha: 0),
              padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
              onKeyEvent: (node, event) {
                final keyboard = HardwareKeyboard.instance;
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    (keyboard.isControlPressed || keyboard.isMetaPressed)) {
                  _commit();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _commitButton(GhTheme theme) {
    final message = _message.text.trim();
    final branch = _switchingBranch ?? _currentBranchInfo?.name ?? widget.gitStatus?.branch ?? '…';
    final tooltip = _branchProtected
        ? _g('protected_branch_tooltip', args: {'branch': branch})
        : message.isNotEmpty
        ? _g('commit')
        : ghTr('git_commit_placeholder');
    return GhTooltip(
      message: tooltip,
      side: GhSide.top,
      child: GhPressable(
        onPressed: message.isEmpty || _committing ? null : _commit,
        disabledOpacity: 0.4,
        disabledCursor: SystemMouseCursors.forbidden,
        rippleColor: Colors.white,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        builder: (context, states) => GhAnimatedBox(
          color: states.active ? theme.accentBright : theme.accent,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: theme.space(1.5),
            children: [
              GhIcon(_branchProtected ? GhIcons.lock : GhIcons.check, size: theme.space(3.5), color: Colors.white),
              Text(
                _committing ? _g('committing') : _g('commit'),
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stashSection(GhTheme theme) {
    final busy = _stashBusy != null;
    return GitSection(
      title: _g('stashes_title'),
      count: _stashes.length,
      children: [
        DashedAction(
          label: _stashBusy == 'push' ? _g('stashing') : _g('stash'),
          icon: _stashBusy == 'push'
              ? GhSpinning(
                  child: GhIcon(GhIcons.download, size: theme.space(3.5), color: theme.muted),
                )
              : GhIcon(GhIcons.download, size: theme.space(3.5), color: theme.muted),
          onPressed: busy ? null : _stashPush,
        ),
        for (final s in _stashes)
          Builder(
            builder: (context) {
              final index = s.index.toInt();
              final ref = 'stash@{$index}';
              final label = s.message.isNotEmpty ? s.message : ref;
              return _HoverRow(
                key: ValueKey(index),
                bordered: true,
                onPressed: () => _openDiff(ref, () => GitApi.stashShow(_path, index)),
                actions: [
                  _iconAction(
                    theme,
                    tooltip: _g('apply_stash'),
                    icon: GhIcons.play,
                    hover: theme.mint,
                    spin: _stashBusy == 'apply:$index',
                    onPressed: busy ? null : () => _stashAction('apply:$index', () => GitApi.stashApply(_path, index), 'stash_applied_ok'),
                  ),
                  _iconAction(
                    theme,
                    tooltip: _g('pop_stash'),
                    icon: GhIcons.chevronUp,
                    hover: theme.amber,
                    spin: _stashBusy == 'pop:$index',
                    onPressed: busy ? null : () => _stashAction('pop:$index', () => GitApi.stashPop(_path, index), 'stash_popped_ok'),
                  ),
                  _iconAction(
                    theme,
                    tooltip: _g('drop_stash'),
                    icon: GhIcons.trash,
                    hover: theme.danger,
                    spin: _stashBusy == 'drop:$index',
                    onPressed: busy
                        ? null
                        : () =>
                              _stashAction('drop:$index', () => GitApi.stashDrop(_path, index), 'stash_dropped_ok', refreshChanges: false),
                  ),
                ],
                child: Row(
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.download, size: theme.space(3), color: theme.muted.withValues(alpha: 0.4)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GhTooltip(
                            message: label,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text(size: GhTextSize.x2s, color: theme.ink),
                            ),
                          ),
                          GhTooltip(
                            message: ref,
                            child: Text(
                              ref,
                              style: theme.text(size: GhTextSize.x4s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _fileRow(GhTheme theme, GitChangedFile f, {required bool staged}) {
    final raw = f.status.length > (staged ? 0 : 1) ? f.status[staged ? 0 : 1] : ' ';
    final ch = raw == '?' ? 'U' : raw;
    final color = switch (ch) {
      'A' => theme.mint,
      'D' => theme.danger,
      'M' => theme.amber,
      _ => theme.muted.withValues(alpha: 0.5),
    };
    return _HoverRow(
      key: ValueKey('${staged ? 's' : 'u'}:${f.path}'),
      onPressed: () => _openDiff(f.path, () => GitApi.fileDiff(_path, f.path)),
      actions: [
        if (!staged)
          _iconAction(
            theme,
            tooltip: _g('stage_file'),
            icon: GhIcons.plus,
            hover: theme.mint,
            onPressed: () => _fileAction(() => GitApi.stageFile(_path, f.path), 'staged_ok'),
          ),
        if (staged)
          _iconAction(
            theme,
            tooltip: _g('unstage_file'),
            icon: GhIcons.chevronUp,
            hover: theme.amber,
            onPressed: () => _fileAction(() => GitApi.unstageFile(_path, f.path), 'unstaged_ok'),
          ),
        _iconAction(
          theme,
          tooltip: _g('discard_file'),
          icon: GhIcons.trash,
          hover: theme.danger,
          onPressed: () => _fileAction(() => GitApi.discardFile(_path, f.path), 'discarded_ok'),
        ),
      ],
      child: Row(
        spacing: theme.space(1.5),
        children: [
          SizedBox(
            width: theme.space(3),
            child: Text(
              ch,
              style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, mono: true, color: color),
            ),
          ),
          Expanded(
            child: GhTooltip(
              message: f.path,
              child: Text(
                f.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme
                    .text(size: GhTextSize.x2s, mono: true, color: theme.muted)
                    .copyWith(
                      decoration: ch == 'D' ? TextDecoration.lineThrough : null,
                      decorationColor: theme.muted.withValues(alpha: 0.6),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(GhTheme theme, String label, int count) {
    final style = theme.text(
      size: GhTextSize.x4s,
      weight: GhWeight.semibold,
      color: theme.muted.withValues(alpha: 0.5),
      letterSpacingEm: 0.05,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(theme.space(2.5), theme.space(1.5), theme.space(2.5), theme.space(0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: style),
          Text('$count', style: style.copyWith(fontFamily: GhFonts.mono, letterSpacing: 0)),
        ],
      ),
    );
  }

  Widget _changesSection(GhTheme theme) {
    final visible = _visibleFiles;
    final staged = visible.where(isStagedChange).toList();
    final unstaged = visible.where(isUnstagedChange).toList();
    final Widget body;
    if (_changesLoading) {
      body = _hint(theme, ghTr('checking_changes'));
    } else if (_files.isEmpty) {
      body = _hint(theme, _g('working_tree_clean'));
    } else if (_query.text.trim().isNotEmpty && staged.isEmpty && unstaged.isEmpty) {
      body = _hint(theme, _g('no_matching_changes'));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (staged.isNotEmpty) ...[
            _groupHeader(theme, _g('staged_changes'), staged.length),
            for (final f in staged) _fileRow(theme, f, staged: true),
          ],
          if (unstaged.isNotEmpty) ...[
            _groupHeader(theme, _g('changes_title'), unstaged.length),
            for (final f in unstaged) _fileRow(theme, f, staged: false),
          ],
        ],
      );
    }
    return GitSection(
      title: _g('changes_title'),
      count: _files.length,
      onContextMenu: (position) => setState(() => _menu = (position: position, visible: true, key: ++_menuKey)),
      children: [
        if (_files.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: theme.space(1.5)),
            child: GhTextInput(
              controller: _query,
              size: GhTextSize.x2s,
              placeholder: _g('filter_changes'),
              background: theme.base.withValues(alpha: 0.5),
              borderColor: theme.outline.withValues(alpha: 0.5),
              focusBorderColor: theme.accentDim,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
            ),
          ),
        Container(
          height: theme.space(52),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.base.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          ),
          child: GhScrollView(
            padding: EdgeInsets.symmetric(vertical: theme.space(0.5)),
            child: body,
          ),
        ),
      ],
    );
  }

  List<GhMenuItem> _menuItems() {
    void run(Future<void> Function() action) => action();
    return [
      if (_visibleFiles.any(isStagedChange))
        GhMenuItem(
          id: 'unstage-all',
          label: _g('unstage_all_changes'),
          icon: GhIcons.chevronUp,
          onSelected: () => run(() => _fileAction(() => GitApi.unstageFile(_path, '.'), 'unstage_all_ok')),
        ),
      GhMenuItem(
        id: 'stage-all',
        label: _g('stage_all'),
        icon: GhIcons.plus,
        onSelected: () => run(() => _fileAction(() => GitApi.stageFile(_path, '.'), 'stage_all_ok')),
      ),
      GhMenuItem(id: 'stash', label: _g('stash'), icon: GhIcons.download, onSelected: () => run(_stashPush)),
      GhMenuItem(
        id: 'discard-all',
        label: _g('discard_all'),
        icon: GhIcons.trash,
        danger: true,
        dividerAfter: true,
        onSelected: () => run(_discardAll),
      ),
      GhMenuItem(
        id: 'undo-commit',
        label: _g('undo_last_commit'),
        icon: GhIcons.history,
        onSelected: () => run(() => _undo(() => GitApi.undoCommit(_path), 'undo_commit_done')),
      ),
      GhMenuItem(
        id: 'undo-pull',
        label: _g('undo_pull'),
        icon: GhIcons.cloudArrowDown,
        onSelected: () => run(() => _undo(() => GitApi.undoPull(_path), 'undo_pull_done', aheadBehind: true)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    ref.listen(settingsProvider.select((value) => value.value?.gitAutoFetch ?? false), (_, _) => _syncAutoFetch());
    final settings = ref.watch(settingsProvider).value;
    final menu = _menu;
    final autoFetch = settings?.gitAutoFetch ?? false;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        _accounts(theme),
        if (_merging) _merge(theme),
        Row(spacing: theme.space(1.5), children: [for (final key in _Remote.values) _remoteButton(theme, key)]),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
          child: Row(
            spacing: theme.space(1.5),
            children: [
              GhCheckbox(
                checked: autoFetch,
                label: _g('auto_fetch_label'),
                onChanged: settings == null
                    ? null
                    : (value) => ref.read(settingsProvider.notifier).save(copySettings(settings, gitAutoFetch: value)).ignore(),
                child: Text(_g('auto_fetch_label')),
              ),
              GhTooltip(
                message: _g('auto_fetch_hint'),
                side: GhSide.top,
                child: MouseRegion(
                  cursor: SystemMouseCursors.help,
                  child: GhIcon(GhIcons.info, size: theme.space(3), color: theme.muted.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(1.5),
          children: [
            if (_remotesLoading)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
                child: Text(
                  '…',
                  style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.5)),
                ),
              )
            else if (_remotes.isEmpty)
              DashedNote(text: _g('no_remotes')),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(1.5),
                children: [
                  Expanded(child: _branchSwitcher(theme)),
                  GhTooltip(
                    message: _syncing ? ghTr('syncing') : _g('sync'),
                    child: GhPressable(
                      onPressed: _syncing ? null : _sync,
                      semanticLabel: _g('sync'),
                      disabledOpacity: 0.5,
                      disabledCursor: SystemMouseCursors.wait,
                      borderRadius: BorderRadius.circular(theme.radiusItem),
                      builder: (context, states) {
                        Widget glyph = GhIcon(GhIcons.refresh, size: theme.space(4), color: states.active ? theme.accent : theme.muted);
                        if (_syncing) glyph = GhSpinning(child: glyph);
                        return GhAnimatedBox(
                          color: states.active ? theme.raised : theme.raised.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(theme.radiusItem),
                          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                          padding: EdgeInsets.symmetric(horizontal: theme.space(3.5)),
                          alignment: Alignment.center,
                          child: glyph,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _commitBox(theme),
            if (!_remotesLoading && _remotes.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(1),
                children: [
                  for (final r in _remotes.skip(1))
                    Column(
                      key: ValueKey(r.name),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(0.5),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
                          child: Text(
                            r.name.toUpperCase(),
                            style: theme.text(
                              size: GhTextSize.x4s,
                              weight: GhWeight.semibold,
                              color: theme.muted.withValues(alpha: 0.5),
                              letterSpacingEm: 0.05,
                            ),
                          ),
                        ),
                        _remoteLink(theme, r, primary: false),
                      ],
                    ),
                ],
              ),
            _commitButton(theme),
          ],
        ),
        GitWorktrees(
          key: ValueKey(_path),
          project: widget.project,
          onSwitchProject: widget.onSwitchProject,
          onChanged: () {
            widget.onRefresh();
            _notifyStatus();
          },
        ),
        if (_stashes.isNotEmpty) _stashSection(theme),
        _changesSection(theme),
        GitSection(
          title: _g('commits_title'),
          count: _commits.length,
          children: [
            if (_commitsLoading)
              _hint(theme, ghTr('loading'))
            else
              Container(
                constraints: BoxConstraints(maxHeight: theme.space(64)),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.base.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                ),
                child: GhScrollView(
                  child: CommitGraph(commits: _commits, remoteUrl: _remotes.firstOrNull?.webUrl, onOpenDetails: _openCommit),
                ),
              ),
          ],
        ),
      ],
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.raised,
              borderRadius: widget.connected ? null : BorderRadius.circular(theme.radiusCard),
              border: widget.connected ? BorderDirectional(start: BorderSide(color: theme.line)) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: theme.space(12),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(start: theme.space(1)),
                          child: Text(
                            widget.project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                      GhTooltip(
                        message: ghTr('close_sidebar'),
                        side: GhSide.left,
                        child: GhPressable(
                          onPressed: widget.onClose,
                          semanticLabel: ghTr('close_sidebar'),
                          borderRadius: BorderRadius.circular(theme.radiusItem),
                          builder: (context, states) => GhAnimatedBox(
                            width: theme.space(9),
                            height: theme.space(9),
                            color: states.active ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
                            borderRadius: BorderRadius.circular(theme.radiusItem),
                            alignment: Alignment.center,
                            child: GhIcon(GhIcons.x, size: theme.space(4), color: states.active ? theme.ink : theme.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GhScrollView(padding: EdgeInsets.all(theme.space(3)), child: content),
                ),
              ],
            ),
          ),
        ),
        if (menu != null)
          GhContextMenu(
            key: ValueKey(menu.key),
            position: menu.position,
            visible: menu.visible,
            items: _menuItems(),
            onClose: () => setState(() => _menu = (position: menu.position, visible: false, key: menu.key)),
            onExited: () {
              if (_menu?.key == menu.key) setState(() => _menu = null);
            },
          ),
      ],
    );
  }
}

class ProviderBadge extends StatelessWidget {
  const ProviderBadge({super.key, required this.webUrl});

  final String webUrl;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final (label, color) = webUrl.contains('gitlab.com')
        ? ('GitLab', theme.amber)
        : webUrl.contains('github.com')
        ? ('GitHub', theme.ink)
        : ('', theme.muted);
    if (label.isEmpty) return GhIcon(GhIcons.gitBranch, size: theme.space(3), color: theme.muted.withValues(alpha: 0.4));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: label == 'GitHub' ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(theme.radiusTag),
      ),
      child: Text(
        label,
        style: theme.text(size: GhTextSize.x4s, weight: GhWeight.semibold, color: color),
      ),
    );
  }
}

class DashedNote extends StatelessWidget {
  const DashedNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.5)),
      ),
    );
  }
}

class _HoverRow extends StatefulWidget {
  const _HoverRow({super.key, required this.child, required this.actions, required this.onPressed, this.bordered = false});

  final Widget child;
  final List<Widget> actions;
  final VoidCallback onPressed;
  final bool bordered;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final reveal = _hovered || _focused;
    final radius = widget.bordered ? BorderRadius.circular(theme.radiusItem) : null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => _focused = value),
        child: Stack(
          alignment: AlignmentDirectional.centerEnd,
          children: [
            GhPressable(
              onPressed: widget.onPressed,
              borderRadius: radius,
              builder: (context, states) => GhAnimatedBox(
                color: reveal || states.active
                    ? theme.raised.withValues(alpha: 0.6)
                    : (widget.bordered ? theme.base.withValues(alpha: 0.4) : theme.raised.withValues(alpha: 0)),
                borderRadius: radius,
                border: widget.bordered ? Border.all(color: theme.line.withValues(alpha: 0.6)) : null,
                padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                child: widget.child,
              ),
            ),
            PositionedDirectional(
              end: theme.space(1.5),
              child: IgnorePointer(
                ignoring: !reveal,
                child: AnimatedOpacity(
                  opacity: reveal ? 1 : 0,
                  duration: GhDurations.color,
                  alwaysIncludeSemantics: true,
                  child: Container(
                    padding: EdgeInsets.all(theme.space(0.5)),
                    decoration: BoxDecoration(
                      color: theme.base.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(theme.radiusMd),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(0.5), children: widget.actions),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchRow extends StatefulWidget {
  const _BranchRow({
    super.key,
    required this.branch,
    required this.switching,
    required this.enabled,
    required this.onSwitch,
    required this.trailing,
    required this.revealTrailing,
  });

  final GitBranchInfo branch;
  final bool switching;
  final bool enabled;
  final VoidCallback onSwitch;
  final List<Widget> trailing;
  final bool revealTrailing;

  @override
  State<_BranchRow> createState() => _BranchRowState();
}

class _BranchRowState extends State<_BranchRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final current = widget.branch.isCurrent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        children: [
          Expanded(
            child: GhPressable(
              onPressed: widget.enabled ? widget.onSwitch : null,
              disabledOpacity: 0.4,
              disabledCursor: SystemMouseCursors.forbidden,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              builder: (context, states) => GhAnimatedBox(
                color: current ? theme.accent.withValues(alpha: 0.1) : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
                borderRadius: BorderRadius.circular(theme.radiusItem),
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(2), theme.space(1.5), theme.space(1), theme.space(1.5)),
                child: Row(
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.gitBranch, size: theme.space(3), color: current ? theme.accent : theme.muted.withValues(alpha: 0.4)),
                    Expanded(
                      child: Text(
                        widget.branch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(
                          size: GhTextSize.x2s,
                          weight: GhWeight.medium,
                          color: current || states.active ? theme.ink : theme.muted,
                        ),
                      ),
                    ),
                    if (widget.switching)
                      Text(
                        ghTr('git:switching'),
                        style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.5)),
                      ),
                    if (current) GhIcon(GhIcons.check, size: theme.space(3), color: theme.accent),
                  ],
                ),
              ),
            ),
          ),
          if (widget.trailing.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(end: theme.space(1)),
              child: Opacity(
                opacity: !widget.revealTrailing || _hovered ? 1 : 0,
                child: Row(mainAxisSize: MainAxisSize.min, children: widget.trailing),
              ),
            ),
        ],
      ),
    );
  }
}
