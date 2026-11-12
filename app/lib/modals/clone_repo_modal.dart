import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/git.dart';
import '../api/git_auth.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/launch_errors.dart';
import '../logic/settings_copy.dart';
import '../src/rust/api/types.dart';
import '../state/settings.dart';
import '../state/task_tray.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

String repoBaseName(String url) {
  var cleaned = url.trim().replaceFirst(RegExp(r'/+$'), '');
  while (cleaned.endsWith('.git')) {
    cleaned = cleaned.substring(0, cleaned.length - 4);
  }
  final last = cleaned.split('/').last;
  return last.isEmpty ? 'repo' : last;
}

bool repoMatches(UserRepoInfo r, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return r.name.toLowerCase().contains(q) ||
      r.fullName.toLowerCase().contains(q) ||
      (r.description ?? '').toLowerCase().contains(q) ||
      (r.language ?? '').toLowerCase().contains(q);
}

enum CloneTab { browse, url }

class CloneRepoModal extends ConsumerStatefulWidget {
  const CloneRepoModal({
    super.key,
    this.defaultLocation,
    this.categories = const [],
    this.categoriesEnabled = false,
    required this.onClose,
    required this.onCloned,
  });

  final String? defaultLocation;
  final List<Category> categories;
  final bool categoriesEnabled;
  final VoidCallback onClose;
  final ValueChanged<String> onCloned;

  @override
  ConsumerState<CloneRepoModal> createState() => _CloneRepoModalState();
}

class _CloneRepoModalState extends ConsumerState<CloneRepoModal> {
  final TextEditingController _url = TextEditingController();
  late final TextEditingController _location = TextEditingController(text: widget.defaultLocation ?? '');
  final TextEditingController _search = TextEditingController();
  final FocusNode _urlNode = FocusNode(debugLabel: 'CloneRepoModal url');
  final FocusNode _searchNode = FocusNode(debugLabel: 'CloneRepoModal search');
  String? _error;
  bool _busy = false;
  bool _attempted = false;
  late bool _openAfter = ref.read(settingsProvider).value?.openAfterImport ?? true;
  String? _category;
  GitAuthState? _auth;
  CloneTab _tab = CloneTab.browse;
  List<UserRepoInfo> _repos = const [];
  bool _reposLoading = false;
  bool _reposLoadingMore = false;
  String? _reposError;
  bool _hasMore = false;
  int _page = 1;
  UserRepoInfo? _selected;
  String? _provider;
  int _request = 0;

  List<String> get _providers => [if (_auth?.github != null) 'github', if (_auth?.gitlab != null) 'gitlab'];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _url.addListener(() => setState(() {}));
    GitAuthApi.getState().then(
      (state) {
        if (!mounted) return;
        setState(() {
          _auth = state;
          _provider = _providers.firstOrNull;
          if (_provider == null) _tab = CloneTab.url;
        });
        _focusTab();
        _maybeFetch();
      },
      onError: (Object _) {
        if (mounted) setState(() => _tab = CloneTab.url);
        _focusTab();
      },
    );
  }

  @override
  void dispose() {
    _request++;
    _url.dispose();
    _location.dispose();
    _search.dispose();
    _urlNode.dispose();
    _searchNode.dispose();
    super.dispose();
  }

  void _focusTab() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    (_tab == CloneTab.url ? _urlNode : _searchNode).requestFocus();
  });

  void _setTab(CloneTab tab) {
    setState(() => _tab = tab);
    _focusTab();
    _maybeFetch();
  }

  void _maybeFetch() {
    if (_tab == CloneTab.browse && _provider != null && _repos.isEmpty && !_reposLoading) _fetch(1, append: false);
  }

  Future<void> _fetch(int page, {required bool append}) async {
    final provider = _provider;
    if (provider == null) return;
    final request = ++_request;
    setState(() {
      if (append) {
        _reposLoadingMore = true;
      } else {
        _reposLoading = true;
      }
      _reposError = null;
    });
    try {
      final result = await GitAuthApi.listUserRepos(provider, page);
      if (!mounted || request != _request) return;
      setState(() {
        _repos = append ? [..._repos, ...result.repos] : result.repos;
        _hasMore = result.hasMore;
        _page = page;
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => _reposError = '$e');
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _reposLoading = false;
          _reposLoadingMore = false;
        });
      }
    }
  }

  void _setOpenAfter(bool value) {
    setState(() => _openAfter = value);
    final settings = ref.read(settingsProvider).value;
    if (settings != null) {
      ref.read(settingsProvider.notifier).save(copySettings(settings, openAfterImport: value)).then((_) {}, onError: (Object _) {});
    }
  }

  Future<void> _pickLocation() async {
    try {
      final folder = await ProjectsApi.pickFolder();
      if (folder != null && mounted) {
        setState(() {
          _location.text = folder;
          _error = null;
        });
      }
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  void _select(UserRepoInfo repo) {
    setState(() {
      _selected = repo;
      _url.text = repo.cloneUrl;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final url = _url.text.trim();
    final location = _location.text;
    if (url.isEmpty || location.isEmpty) {
      setState(() {
        _attempted = true;
        _error = url.isEmpty ? ghTr('clone_repo_error_url') : ghTr('clone_repo_error_location');
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final tray = ref.read(taskTrayProvider.notifier);
    final taskId = 'clone-${DateTime.now().millisecondsSinceEpoch}';
    tray.registerTask(
      TrayTask(
        id: taskId,
        type: TaskType.cloneRepo,
        label: '${ghTr('cloning')} ${repoBaseName(url)}',
        description: ghTr('loading'),
        status: TaskStatus.running,
      ),
    );
    try {
      final cloned = await GitApi.clone(url, location);
      tray.updateTask(taskId, description: ghTr('importing_project'), status: TaskStatus.running);
      final project = await ProjectsApi.import(cloned, '', _category);
      tray.updateTask(taskId, status: TaskStatus.completed, description: ghTr('done'));
      tray.scheduleRemoval(taskId, taskCompletedRemovalDelay);
      widget.onCloned(project.id);
      if (ref.read(settingsProvider).value?.desktopNotificationsEnabled ?? false) {
        Api.notify('GodotHub', ghTr('notification_clone_done')).catchError((Object _) {});
      }
      if (_openAfter) ProjectsApi.open(project.id, true).catchError((Object e) => reportLaunchError(e));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      tray.updateTask(taskId, status: TaskStatus.error, errorMessage: '$e');
      tray.scheduleRemoval(taskId, taskErrorRemovalDelay);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _pill(GhTheme theme, {required String label, required bool active, required VoidCallback onPressed, bool small = false}) =>
      GhPressable(
        onPressed: onPressed,
        selected: active,
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        builder: (context, states) => GhAnimatedBox(
          color: active ? theme.accent.withValues(alpha: 0.15) : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
          borderRadius: BorderRadius.circular(theme.radiusBtn),
          border: Border.all(color: active ? theme.accent.withValues(alpha: 0.3) : Colors.transparent),
          padding: EdgeInsets.symmetric(horizontal: theme.space(small ? 2.5 : 3), vertical: theme.space(small ? 1 : 1.5)),
          child: Text(
            label,
            style: theme.text(
              size: small ? GhTextSize.x2s : GhTextSize.xs,
              weight: GhWeight.medium,
              color: active ? theme.accentBright : (states.active ? theme.ink : theme.muted),
            ),
          ),
        ),
      );

  GhTextInput _input(
    GhTheme theme,
    TextEditingController controller, {
    required bool invalid,
    FocusNode? focusNode,
    String? placeholder,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
    Color? textColor,
    bool mono = true,
    EdgeInsetsGeometry? padding,
  }) => GhTextInput(
    controller: controller,
    focusNode: focusNode,
    placeholder: placeholder,
    readOnly: readOnly,
    onTap: onTap,
    onSubmitted: onSubmitted,
    onChanged: onChanged,
    mono: mono,
    textColor: textColor,
    background: theme.overlay,
    placeholderColor: theme.muted.withValues(alpha: 0.7),
    borderColor: invalid ? theme.danger.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5),
    focusBorderColor: invalid ? theme.danger : theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusItem),
    padding: padding ?? EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
  );

  Widget _repoList(GhTheme theme) {
    final filtered = [
      for (final r in _repos)
        if (repoMatches(r, _search.text)) r,
    ];
    final muted = theme.text(size: GhTextSize.sm, color: theme.muted);
    final Widget content;
    if (_reposLoading && _repos.isEmpty) {
      content = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: theme.space(2),
          children: [
            GhSpinnerIcon(size: 4, color: theme.muted),
            Text(ghTr('clone_repo_loading_repos'), style: muted),
          ],
        ),
      );
    } else if (_reposError != null) {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(8)),
        child: Row(
          spacing: theme.space(2),
          children: [
            GhIcon(GhIcons.alertTriangle, size: theme.space(4), color: theme.danger),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(1),
                children: [
                  Text(
                    ghTr('clone_repo_load_error'),
                    style: theme.text(size: GhTextSize.sm, color: theme.danger),
                  ),
                  Text(
                    _reposError!,
                    style: theme.text(size: GhTextSize.xs, mono: true, color: theme.danger.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (filtered.isEmpty) {
      content = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(8)),
        child: Column(
          spacing: theme.space(1),
          children: [
            Opacity(
              opacity: 0.4,
              child: GhIcon(GhIcons.search, size: theme.space(5), color: theme.muted),
            ),
            Text(ghTr('clone_repo_no_repos_found'), style: muted),
          ],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < filtered.length; i++) _repoRow(theme, filtered[i], divider: i > 0),
          if (!_reposLoading)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.line)),
              ),
              child: _reposLoadingMore
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.space(3)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: theme.space(2),
                        children: [
                          GhSpinnerIcon(size: 3, color: theme.muted),
                          Text(
                            ghTr('loading'),
                            style: theme.text(size: GhTextSize.xs, color: theme.muted),
                          ),
                        ],
                      ),
                    )
                  : _hasMore
                  ? GhPressable(
                      onPressed: () => _fetch(_page + 1, append: true),
                      builder: (context, states) => GhAnimatedBox(
                        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                        padding: EdgeInsets.symmetric(vertical: theme.space(3)),
                        alignment: Alignment.center,
                        child: Text(
                          ghTr('load_more'),
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.accentBright),
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.space(3)),
                      child: Text(
                        '${_repos.length} ${ghTr('clone_repo_repos_loaded')}',
                        textAlign: TextAlign.center,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted),
                      ),
                    ),
            ),
        ],
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(child: content),
    );
  }

  Widget _repoRow(GhTheme theme, UserRepoInfo repo, {required bool divider}) {
    final selected = _selected?.cloneUrl == repo.cloneUrl;
    Widget tag(String text, Color background, Color color) => Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(theme.rem(0.25))),
      child: Text(
        text,
        style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: color),
      ),
    );
    return GhPressable(
      key: ValueKey(repo.cloneUrl),
      onPressed: () => _select(repo),
      selected: selected,
      builder: (context, states) => GhAnimatedBox(
        color: selected
            ? theme.accent.withValues(alpha: 0.1)
            : (states.active ? theme.raised.withValues(alpha: 0.5) : theme.raised.withValues(alpha: 0)),
        border: divider ? Border(top: BorderSide(color: theme.line)) : null,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(3),
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: theme.space(2),
                    children: [
                      Flexible(
                        child: Text(
                          repo.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                        ),
                      ),
                      repo.private
                          ? tag(ghTr('remote_private'), theme.amber.withValues(alpha: 0.15), theme.amber)
                          : tag(ghTr('remote_public'), theme.mint.withValues(alpha: 0.15), theme.mint),
                      if (repo.language case final language?) tag(language, theme.overlay, theme.muted),
                    ],
                  ),
                  if (repo.description?.isNotEmpty ?? false)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(0.5)),
                      child: Text(
                        repo.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: theme.space(0.5)),
              child: selected
                  ? GhIcon(GhIcons.check, size: theme.space(4), color: theme.accentBright)
                  : Opacity(
                      opacity: states.active ? 1 : 0,
                      child: Text(
                        ghTr('clone_repo_select'),
                        style: theme.text(size: GhTextSize.xs, color: theme.accent),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _browse(GhTheme theme) {
    final providers = _providers;
    final provider = _provider!;
    final username = (provider == 'github' ? _auth?.github : _auth?.gitlab)?.username;
    String capital(String p) => '${p[0].toUpperCase()}${p.substring(1)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
          child: Row(
            spacing: theme.space(2),
            children: [
              if (providers.length > 1)
                Row(
                  spacing: theme.space(1),
                  children: [
                    for (final p in providers)
                      _pill(
                        theme,
                        label: capital(p),
                        small: true,
                        active: p == provider,
                        onPressed: () {
                          if (p == provider) return;
                          _request++;
                          setState(() {
                            _provider = p;
                            _repos = const [];
                            _selected = null;
                            _reposLoading = false;
                            _reposLoadingMore = false;
                          });
                          _search.clear();
                          _maybeFetch();
                        },
                      ),
                  ],
                )
              else
                Text(
                  capital(provider),
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.accentBright),
                ),
              Opacity(
                opacity: 0.5,
                child: Text(
                  '•',
                  style: theme.text(size: GhTextSize.xs, color: theme.muted),
                ),
              ),
              Text(
                username != null ? '@$username' : '',
                style: theme.text(size: GhTextSize.xs, color: theme.muted),
              ),
              const Spacer(),
              GhPressable(
                onPressed: _reposLoading
                    ? null
                    : () {
                        setState(() {
                          _repos = const [];
                          _selected = null;
                        });
                        _fetch(1, append: false);
                      },
                builder: (context, states) => Text(
                  ghTr('refresh'),
                  style: theme.text(size: GhTextSize.xs, color: states.active ? theme.accentBright : theme.muted),
                ),
              ),
            ],
          ),
        ),
        Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            _input(
              theme,
              _search,
              invalid: false,
              focusNode: _searchNode,
              placeholder: ghTr('clone_repo_search_repos'),
              padding: EdgeInsetsDirectional.fromSTEB(theme.space(9), theme.space(2.5), theme.space(3.5), theme.space(2.5)),
            ),
            PositionedDirectional(
              start: theme.space(3),
              child: IgnorePointer(
                child: GhIcon(GhIcons.search, size: theme.space(3.5), color: theme.muted),
              ),
            ),
          ],
        ),
        _repoList(theme),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final hasProvider = _providers.isNotEmpty;
    final showUrl = _tab == CloneTab.url || !hasProvider;
    return GhModalShell(
      icon: GhIcon(GhIcons.gitBranch, size: theme.space(5), color: theme.accentBright),
      title: ghTr('clone_repo_title'),
      maxWidth: GhModalWidth.x2l,
      showClose: false,
      onClose: widget.onClose,
      rawFooter: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
              child: GhAlertBox(tone: GhAlertTone.danger, icon: GhIcons.alertTriangle, text: _error, strong: true, padding: 3),
            ),
          Container(
            margin: EdgeInsets.only(top: _error != null ? theme.space(6) : 0),
            padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: theme.space(2.5),
              children: [
                GhButton(onPressed: _busy ? null : widget.onClose, label: ghTr('cancel'), disabledOpacity: 0.5),
                GhBusyButton(onPressed: _busy ? null : _submit, busy: _busy, label: _busy ? ghTr('cloning') : ghTr('clone_import')),
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasProvider)
            Padding(
              padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(1), theme.space(6), 0),
              child: Row(
                spacing: theme.space(2),
                children: [
                  _pill(
                    theme,
                    label: ghTr('clone_repo_browse_repos'),
                    active: _tab == CloneTab.browse,
                    onPressed: () => _setTab(CloneTab.browse),
                  ),
                  _pill(theme, label: ghTr('clone_repo_url_manual'), active: _tab == CloneTab.url, onPressed: () => _setTab(CloneTab.url)),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(theme.space(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(4),
              children: [
                if (_tab == CloneTab.browse && _provider != null) _browse(theme),
                if (showUrl) ...[
                  if (!hasProvider)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
                      decoration: BoxDecoration(
                        color: theme.overlay,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        border: Border.all(color: theme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        spacing: theme.space(2),
                        children: [
                          Opacity(
                            opacity: 0.6,
                            child: GhIcon(GhIcons.plug, size: theme.space(3.5), color: theme.muted),
                          ),
                          Expanded(
                            child: Text(
                              ghTr('clone_repo_no_account'),
                              style: theme.text(size: GhTextSize.xs, color: theme.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(0.5),
                    children: [
                      GhFieldLabel(ghTr('clone_repo_url_label'), inset: true),
                      _input(
                        theme,
                        _url,
                        invalid: _attempted && _url.text.trim().isEmpty,
                        focusNode: _urlNode,
                        placeholder: ghTr('clone_repo_url_placeholder'),
                        onChanged: (_) => setState(() {
                          _selected = null;
                          _error = null;
                        }),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_selected case final repo?)
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: theme.space(3), top: theme.space(0.5)),
                          child: Text(
                            repo.fullName,
                            style: theme.text(size: GhTextSize.xs, color: theme.accentBright),
                          ),
                        ),
                    ],
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(0.5),
                  children: [
                    GhFieldLabel(ghTr('destination_folder'), inset: true),
                    Row(
                      spacing: theme.space(2.5),
                      children: [
                        Expanded(
                          child: _input(
                            theme,
                            _location,
                            invalid: _attempted && _location.text.isEmpty,
                            readOnly: true,
                            onTap: _pickLocation,
                            textColor: theme.muted,
                            placeholder: ghTr('choose_folder_placeholder'),
                          ),
                        ),
                        GhButton(onPressed: _pickLocation, label: ghTr('browse'), variant: GhButtonVariant.outline),
                      ],
                    ),
                  ],
                ),
                if (widget.categoriesEnabled)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(2),
                    children: [
                      GhFieldLabel(ghTr('category_optional')),
                      Wrap(
                        spacing: theme.space(1.5),
                        runSpacing: theme.space(1.5),
                        children: [
                          GhChoiceChip(
                            label: ghTr('no_category_label'),
                            active: _category == null,
                            onPressed: () => setState(() => _category = null),
                          ),
                          for (final cat in widget.categories)
                            GhChoiceChip(
                              label: cat.name,
                              active: _category == cat.name,
                              dotColor: colorFromHex(cat.color),
                              onPressed: () => setState(() => _category = cat.name),
                            ),
                        ],
                      ),
                    ],
                  ),
                GhCheckbox(
                  checked: _openAfter,
                  label: ghTr('clone_repo_open_after'),
                  onChanged: _setOpenAfter,
                  child: Text(ghTr('clone_repo_open_after')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
