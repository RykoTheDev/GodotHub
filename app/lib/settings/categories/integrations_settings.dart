import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/git_auth.dart';
import '../../api/opener.dart';
import '../../api/settings.dart';
import '../../design/design.dart';
import '../../logic/locale.dart';
import '../../logic/settings_copy.dart';
import '../../modals/git_auth_modal.dart';
import '../../modals/restore_progress_modal.dart';
import '../../src/rust/api/types.dart';
import '../../state/projects.dart';
import '../../state/settings.dart';
import '../../ui/controls/text_input.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/core/i18n.dart';
import '../../ui/core/interaction.dart';
import '../../ui/core/tooltip.dart';
import '../../ui/feedback/modal_shell.dart';
import '../../ui/feedback/toast.dart';
import '../../ui/overlays/dropdown.dart';
import '../../ui/overlays/menu.dart';
import '../../versions/version_settings.dart';
import '../settings_parts.dart';
import 'cli_tool_section.dart';
import 'settings_buttons.dart';

String _ts(String key, {Map<String, Object?> args = const {}}) => ghTr('settings:$key', args: args);

void _toastError(Object error) => ghToasts.pushToast(GhToastType.error, '$error');

class IntegrationsSettings extends ConsumerStatefulWidget {
  const IntegrationsSettings({super.key});

  @override
  ConsumerState<IntegrationsSettings> createState() => _IntegrationsSettingsState();
}

class _IntegrationsSettingsState extends ConsumerState<IntegrationsSettings> {
  GitAuthState? _gitAuth;
  final _gitlabUrl = TextEditingController();
  final _gitlabClientId = TextEditingController();
  bool _patOpen = false;
  final _patHost = TextEditingController();
  final _patUser = TextEditingController();
  final _patToken = TextEditingController();
  String? _patMessage;
  String? _syncBusy;
  String? _syncMessage;
  String? _syncUrl;
  String? _lastPushedAt;
  final _manualGistUrl = TextEditingController();
  bool _manualPullBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshGitAuth();
    SettingsApi.gistSyncGetInfo().then((info) {
      if (!mounted || info == null) return;
      setState(() {
        _syncUrl = info.gistUrl;
        _lastPushedAt = _formatPushed(info.pushedAt) ?? _lastPushedAt;
      });
    }, onError: (Object _) {});
    for (final controller in [_gitlabUrl, _gitlabClientId, _manualGistUrl]) {
      controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [_gitlabUrl, _gitlabClientId, _patHost, _patUser, _patToken, _manualGistUrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _formatPushed(String iso) {
    if (iso.isEmpty) return null;
    final date = DateTime.tryParse(iso);
    return date == null ? null : formatLocaleDateTime(date.toLocal());
  }

  Future<void> _refreshGitAuth() async {
    try {
      final state = await GitAuthApi.getState();
      if (mounted) setState(() => _gitAuth = state);
    } catch (_) {}
  }

  void _save(AppSettings Function(AppSettings current) change) {
    final current = ref.read(settingsProvider).value;
    if (current == null) return;
    ref.read(settingsProvider.notifier).save(change(current)).ignore();
  }

  void _signIn(String provider, {String? baseUrl, String? clientId}) {
    showGitAuthModal(context, provider: provider, baseUrl: baseUrl, clientId: clientId, onConnected: (_) => _refreshGitAuth()).ignore();
  }

  Future<void> _disconnect(String provider) async {
    try {
      await GitAuthApi.disconnect(provider);
    } catch (e) {
      _toastError(e);
    }
    await _refreshGitAuth();
  }

  Future<void> _savePat() async {
    setState(() => _patMessage = null);
    try {
      await GitAuthApi.savePat(_patHost.text, _patUser.text, _patToken.text);
      _patHost.clear();
      _patUser.clear();
      _patToken.clear();
      if (mounted) setState(() => _patOpen = false);
      await _refreshGitAuth();
    } catch (e) {
      if (mounted) setState(() => _patMessage = '$e');
    }
  }

  Future<void> _removePat(String host) async {
    try {
      await GitAuthApi.removePat(host);
    } catch (e) {
      _toastError(e);
    }
    await _refreshGitAuth();
  }

  Future<void> _syncPush() async {
    setState(() {
      _syncBusy = 'push';
      _syncMessage = null;
    });
    try {
      final result = await SettingsApi.gistSyncPush();
      if (!mounted) return;
      setState(() {
        _syncUrl = result.gistUrl;
        _lastPushedAt = _formatPushed(result.pushedAt);
        _syncMessage = _ts('sync_push_done');
      });
    } catch (e) {
      if (mounted) setState(() => _syncMessage = '$e');
    } finally {
      if (mounted) setState(() => _syncBusy = null);
    }
  }

  void _openRestore() {
    showGhModal<void>(context, (modal) => RestoreProgressModal(onClose: () => Navigator.of(modal).pop())).ignore();
  }

  Future<void> _manualPull() async {
    final url = _manualGistUrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _manualPullBusy = true);
    try {
      await SettingsApi.gistSyncSaveGistUrl(url);
      final info = await SettingsApi.gistSyncGetInfo();
      if (!mounted) return;
      if (info != null) setState(() => _syncUrl = info.gistUrl);
      _openRestore();
    } catch (e) {
      if (mounted) setState(() => _syncMessage = '$e');
    } finally {
      if (mounted) setState(() => _manualPullBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final github = _gitAuth?.github;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        SettingsSubsection(
          id: 'integrations-git',
          titleWidget: _iconTitle(theme, GhIcons.gitBranch, 'Git'),
          searchText:
              '${_ts('git_sign_in_github')} ${_ts('git_sign_in_gitlab')} ${_ts('git_pat_title')} ${_ts('github_token_title')} ${_ts('test')}',
          child: _git(theme, github),
        ),
        if (github != null)
          SettingsSubsection(
            id: 'integrations-sync',
            titleWidget: _iconTitle(theme, GhIcons.cloudArrowDown, _ts('sync_title')),
            searchText: '${_ts('sync_title')} ${_ts('sync_push_btn')} ${_ts('sync_pull_btn')}',
            child: _sync(theme),
          ),
        SettingsSubsection(
          id: 'integrations-discord',
          title: _ts('onboarding_discord_rpc'),
          searchText: [
            'onboarding_discord_rpc',
            'discord_app_id_label',
            'discord_app_id_desc',
            'discord_developer_portal',
            'discord_show_projects_label',
            'discord_excluded_label',
            'discord_custom_label',
          ].map(_ts).join(' '),
          child: _DiscordSettings(settings: settings, onSave: _save),
        ),
        SettingsSubsection(
          id: 'integrations-mise',
          title: _ts('mise_label'),
          searchText: '${_ts('mise_label')} mise',
          child: const MiseSetting(),
        ),
        const CliToolSection(),
      ],
    );
  }

  Widget _iconTitle(GhTheme theme, FaIconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: theme.space(2),
    children: [
      GhIcon(icon, size: theme.space(3.5), color: theme.muted),
      Text(
        label,
        style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
      ),
    ],
  );

  Widget _card(GhTheme theme, List<Widget> children) => Container(
    padding: EdgeInsets.all(theme.space(4)),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(2.5), children: children),
  );

  Widget _cardHeading(GhTheme theme, FaIconData icon, Color color, String label, {Widget? chip}) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: theme.space(2),
    children: [
      GhIcon(icon, size: theme.space(4), color: color),
      Text(
        label,
        style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
      ),
      ?chip,
    ],
  );

  Widget _connectedChip(GhTheme theme, String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
    decoration: BoxDecoration(
      color: theme.mint.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(theme.radiusTag),
      border: Border.all(color: theme.mint.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.mint),
    ),
  );

  Widget _providerCard(GhTheme theme, {required String provider, required FaIconData icon, required Color color, required String name}) {
    final account = provider == 'github' ? _gitAuth?.github : _gitAuth?.gitlab;
    final host = account?.host;
    return _card(theme, [
      Row(
        spacing: theme.space(4),
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _cardHeading(
                theme,
                icon,
                color,
                name,
                chip: account == null
                    ? null
                    : _connectedChip(
                        theme,
                        host != null && host.isNotEmpty
                            ? _ts('git_connected_to', args: {'host': host, 'username': account.username})
                            : _ts('git_connected_as', args: {'username': account.username}),
                      ),
              ),
            ),
          ),
          if (account != null)
            SettingsButton(
              onPressed: () => _disconnect(provider),
              label: _ts('git_disconnect'),
              tone: SettingsButtonTone.dangerQuiet,
              compact: true,
            )
          else
            SettingsButton(
              onPressed: () => _signIn(provider),
              label: _ts(provider == 'github' ? 'git_sign_in_github' : 'git_sign_in_gitlab'),
              tone: SettingsButtonTone.accent,
              compact: true,
            ),
        ],
      ),
    ]);
  }

  Widget _input(
    GhTheme theme,
    TextEditingController controller,
    String placeholder, {
    bool obscure = false,
    bool mono = true,
    Color? background,
    GhTextSize size = GhTextSize.xs,
    double padX = 3.5,
    double padY = 2.5,
    ValueChanged<String>? onSubmitted,
  }) => GhTextInput(
    controller: controller,
    placeholder: placeholder,
    semanticLabel: placeholder,
    obscureText: obscure,
    mono: mono,
    size: size,
    onSubmitted: onSubmitted,
    background: background ?? theme.overlay,
    borderColor: theme.outline.withValues(alpha: 0.5),
    focusBorderColor: theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    padding: EdgeInsets.symmetric(horizontal: theme.space(padX), vertical: theme.space(padY)),
  );

  Widget _git(GhTheme theme, GitAccountInfo? github) {
    final pats = _gitAuth?.pats ?? const <GitPatInfo>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        _providerCard(theme, provider: 'github', icon: GhIcons.github, color: theme.ink, name: 'GitHub'),
        _providerCard(theme, provider: 'gitlab', icon: GhIcons.gitlab, color: theme.amber, name: 'GitLab'),
        _card(theme, [
          _cardHeading(theme, GhIcons.plug, theme.accentBright, _ts('git_self_hosted_title')),
          Text(
            _ts('git_self_hosted_desc'),
            style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
          ),
          Row(
            spacing: theme.space(2),
            children: [
              Expanded(child: _input(theme, _gitlabUrl, _ts('git_self_hosted_url_placeholder'))),
              Expanded(child: _input(theme, _gitlabClientId, _ts('git_self_hosted_client_id'))),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SettingsButton(
              onPressed: _gitlabUrl.text.trim().isEmpty || _gitlabClientId.text.trim().isEmpty
                  ? null
                  : () => _signIn('gitlab', baseUrl: _gitlabUrl.text.trim(), clientId: _gitlabClientId.text.trim()),
              label: _ts('git_sign_in_self_hosted'),
              tone: SettingsButtonTone.quiet,
              compact: true,
            ),
          ),
        ]),
        _card(theme, [
          _cardHeading(theme, GhIcons.code, theme.danger, _ts('git_pat_title')),
          if (pats.isEmpty && !_patOpen)
            Text(
              _ts('git_pat_empty'),
              style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.6)),
            ),
          if (pats.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [for (final pat in pats) _patRow(theme, pat)],
            ),
          if (_patOpen) _patForm(theme) else _addPatButton(theme),
        ]),
        if (github == null)
          Container(
            padding: EdgeInsets.only(top: theme.space(5)),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.line)),
            ),
            child: const GithubTokenField(),
          ),
      ],
    );
  }

  Widget _patRow(GhTheme theme, GitPatInfo pat) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
    decoration: BoxDecoration(
      color: theme.overlay,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
    ),
    child: Row(
      spacing: theme.space(3),
      children: [
        Expanded(
          child: Row(
            spacing: theme.space(2),
            children: [
              Text(
                pat.host,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, mono: true, color: theme.ink),
              ),
              Flexible(
                child: Text(
                  pat.username,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                ),
              ),
            ],
          ),
        ),
        GhTooltip(
          message: _ts('git_pat_remove'),
          side: GhSide.left,
          child: _IconAction(
            icon: GhIcons.trash,
            label: _ts('git_pat_remove'),
            onPressed: () => _removePat(pat.host),
            radius: theme.radiusBtn,
            box: null,
            padding: theme.space(1.5),
            idle: theme.muted.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );

  Widget _patForm(GhTheme theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: theme.space(2.5),
    children: [
      Row(
        spacing: theme.space(2),
        children: [
          Expanded(child: _input(theme, _patHost, _ts('git_pat_host_placeholder'))),
          Expanded(child: _input(theme, _patUser, _ts('git_pat_username'))),
        ],
      ),
      _input(theme, _patToken, _ts('git_pat_token'), obscure: true),
      if (_patMessage != null)
        Text(
          _patMessage!,
          style: theme.text(size: GhTextSize.x2s, color: theme.danger),
        ),
      Row(
        spacing: theme.space(2),
        children: [
          SettingsButton(
            onPressed: _savePat,
            label: _ts('git_pat_save'),
            tone: SettingsButtonTone.accent,
            compact: true,
            radius: theme.radiusItem,
          ),
          SettingsButton(
            onPressed: () => setState(() {
              _patOpen = false;
              _patMessage = null;
            }),
            label: ghTr('cancel'),
            tone: SettingsButtonTone.quiet,
            compact: true,
            radius: theme.radiusItem,
            paddingX: 3.5,
          ),
        ],
      ),
    ],
  );

  Widget _addPatButton(GhTheme theme) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SettingsButton(
      onPressed: () => setState(() => _patOpen = true),
      label: _ts('git_pat_add'),
      icon: GhIcons.plus,
      tone: SettingsButtonTone.quiet,
      compact: true,
      radius: theme.radiusItem,
    ),
  );

  Widget _sync(GhTheme theme) {
    final busy = _syncBusy != null;
    final syncUrl = _syncUrl;
    final message = _syncMessage;
    final lastPushed = _lastPushedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        Row(
          spacing: theme.space(4),
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message != null)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1.5)),
                      child: Text(
                        message,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted),
                      ),
                    ),
                  if (syncUrl != null)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1.5)),
                      child: GhPressable(
                        onPressed: () => OpenerApi.openUrl(syncUrl).catchError(_toastError),
                        borderRadius: BorderRadius.circular(theme.radiusTag),
                        builder: (context, states) => Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: theme.space(1.5),
                          children: [
                            GhIcon(GhIcons.externalLink, size: theme.space(3), color: theme.accentBright),
                            Text(
                              _ts('sync_open_gist'),
                              style: theme
                                  .text(size: GhTextSize.xs, color: theme.accentBright)
                                  .copyWith(decoration: states.active ? TextDecoration.underline : null),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (lastPushed != null)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1)),
                      child: Text(
                        _ts('sync_last_pushed', args: {'time': lastPushed}),
                        style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                SettingsButton(
                  onPressed: busy ? null : _syncPush,
                  icon: GhIcons.cloudArrowDown,
                  label: _syncBusy == 'push' ? _ts('saving') : _ts('sync_push_btn'),
                ),
                SettingsButton(
                  onPressed: busy ? null : _openRestore,
                  icon: GhIcons.cloudArrowDown,
                  tone: SettingsButtonTone.accent,
                  label: _syncBusy == 'pull' ? _ts('saving') : _ts('sync_pull_btn'),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.only(top: theme.space(3)),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.3))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              Text(
                _ts('sync_manual_hint'),
                style: theme.text(size: GhTextSize.xs, color: theme.muted),
              ),
              Row(
                spacing: theme.space(2),
                children: [
                  Expanded(
                    child: _input(
                      theme,
                      _manualGistUrl,
                      _ts('sync_manual_placeholder'),
                      mono: false,
                      background: theme.base,
                      padX: 3,
                      padY: 2,
                      onSubmitted: (_) => _manualPull(),
                    ),
                  ),
                  SettingsButton(
                    onPressed: _manualPullBusy || _manualGistUrl.text.trim().isEmpty ? null : _manualPull,
                    label: _manualPullBusy ? _ts('saving') : _ts('sync_manual_pull_btn'),
                    compact: true,
                    radius: theme.radiusItem,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.radius,
    required this.box,
    required this.padding,
    required this.idle,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;
  final double radius;
  final double? box;
  final double padding;
  final Color idle;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final shape = BorderRadius.circular(radius);
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: shape,
      builder: (context, states) => GhAnimatedBox(
        width: box,
        height: box,
        alignment: Alignment.center,
        padding: box == null ? EdgeInsets.all(padding) : null,
        color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
        borderRadius: shape,
        child: GhIcon(icon, size: theme.space(3.5), color: states.active ? theme.danger : idle),
      ),
    );
  }
}

class _DiscordSettings extends ConsumerStatefulWidget {
  const _DiscordSettings({required this.settings, required this.onSave});

  final AppSettings settings;
  final void Function(AppSettings Function(AppSettings current) change) onSave;

  @override
  ConsumerState<_DiscordSettings> createState() => _DiscordSettingsState();
}

class _DiscordSettingsState extends ConsumerState<_DiscordSettings> {
  late final TextEditingController _appId = TextEditingController(text: widget.settings.discordAppId ?? '');

  @override
  void didUpdateWidget(_DiscordSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.settings.discordAppId ?? '';
    if (next != _appId.text) _appId.text = next;
  }

  @override
  void dispose() {
    _appId.dispose();
    super.dispose();
  }

  Widget _section(GhTheme theme, List<Widget> children) => Container(
    padding: EdgeInsets.only(top: theme.space(5)),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: theme.line)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(2.5), children: children),
  );

  Text _label(GhTheme theme, String text) => Text(
    text,
    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
  );

  Widget _addMenu(GhTheme theme, String label, List<Project> options, void Function(Project project) onPick) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: GhDropdown(
      align: GhSide.left,
      items: [for (final p in options) GhMenuItem(id: p.id, label: p.name, onSelected: () => onPick(p))],
      trigger: (context, open, toggle) => SettingsButton(
        onPressed: toggle,
        label: label,
        icon: GhIcons.plus,
        tone: SettingsButtonTone.quiet,
        compact: true,
        radius: theme.radiusItem,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = widget.settings;
    final projects = ref.watch(projectsProvider.select((s) => s.data));
    String nameOf(String id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return id;
    }

    final excluded = settings.discordRpcExcludedProjects;
    final presences = settings.discordRpcProjectPresences;
    final help = theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(5),
      children: [
        SettingRow(
          label: _ts('onboarding_discord_rpc'),
          child: GhToggle(
            checked: settings.discordRpcEnabled,
            label: _ts('onboarding_discord_rpc'),
            onChanged: (checked) => widget.onSave((s) => copySettings(s, discordRpcEnabled: checked)),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2.5),
          children: [
            _label(theme, _ts('discord_app_id_label')),
            GhTextInput(
              controller: _appId,
              placeholder: _ts('discord_app_id_placeholder'),
              semanticLabel: _ts('discord_app_id_label'),
              mono: true,
              onChanged: (value) => widget.onSave((s) => copySettings(s, discordAppId: () => value.isEmpty ? null : value)),
              background: theme.base,
              borderColor: theme.outline.withValues(alpha: 0.5),
              focusBorderColor: theme.accentDim,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
            ),
            if ((settings.discordAppId ?? '').trim().isEmpty)
              Text(
                _ts('discord_builtin_hint'),
                style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.mint),
              ),
            Text.rich(
              TextSpan(
                text: '${_ts('discord_app_id_desc')} ',
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GhPressable(
                      onPressed: () => OpenerApi.openUrl('https://discord.com/developers/applications').catchError(_toastError),
                      builder: (context, states) => Text(
                        _ts('discord_developer_portal'),
                        style: help.copyWith(
                          color: states.active ? theme.accentBright : theme.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: help,
            ),
          ],
        ),
        _section(theme, [
          SettingRow(
            label: _ts('discord_show_projects_label'),
            child: GhToggle(
              checked: settings.discordRpcShowProjects,
              label: _ts('discord_show_projects_label'),
              onChanged: (checked) => widget.onSave((s) => copySettings(s, discordRpcShowProjects: checked)),
            ),
          ),
        ]),
        _section(theme, [
          _label(theme, _ts('discord_excluded_label')),
          _addMenu(theme, _ts('discord_exclude_project'), [
            for (final p in projects)
              if (!excluded.contains(p.id)) p,
          ], (p) => widget.onSave((s) => copySettings(s, discordRpcExcludedProjects: [...s.discordRpcExcludedProjects, p.id]))),
          if (excluded.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                for (final id in excluded)
                  Container(
                    key: ValueKey('excluded:$id'),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                    decoration: BoxDecoration(
                      color: theme.raised,
                      borderRadius: BorderRadius.circular(theme.radiusItem),
                      border: Border.all(color: theme.line),
                    ),
                    child: Row(
                      spacing: theme.space(3),
                      children: [
                        Expanded(
                          child: Text(
                            nameOf(id),
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.xs, color: theme.ink),
                          ),
                        ),
                        _IconAction(
                          icon: GhIcons.x,
                          label: _ts('discord_excluded_remove'),
                          onPressed: () => widget.onSave(
                            (s) => copySettings(
                              s,
                              discordRpcExcludedProjects: [
                                for (final x in s.discordRpcExcludedProjects)
                                  if (x != id) x,
                              ],
                            ),
                          ),
                          radius: theme.radiusMd,
                          box: theme.space(6),
                          padding: 0,
                          idle: theme.muted,
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Text(
              _ts('discord_excluded_empty'),
              style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
            ),
        ]),
        _section(theme, [
          _label(theme, _ts('discord_custom_label')),
          _addMenu(
            theme,
            _ts('discord_custom_add'),
            [
              for (final p in projects)
                if (!presences.any((pr) => pr.id == p.id) && !excluded.contains(p.id)) p,
            ],
            (p) => widget.onSave(
              (s) => copySettings(
                s,
                discordRpcProjectPresences: [
                  ...s.discordRpcProjectPresences,
                  DiscordProjectPresence(id: p.id),
                ],
              ),
            ),
          ),
          if (presences.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                for (final pr in presences)
                  _PresenceCard(key: ValueKey('presence:${pr.id}'), presence: pr, name: nameOf(pr.id), onSave: widget.onSave),
              ],
            ),
        ]),
      ],
    );
  }
}

class _PresenceCard extends StatefulWidget {
  const _PresenceCard({super.key, required this.presence, required this.name, required this.onSave});

  final DiscordProjectPresence presence;
  final String name;
  final void Function(AppSettings Function(AppSettings current) change) onSave;

  @override
  State<_PresenceCard> createState() => _PresenceCardState();
}

class _PresenceCardState extends State<_PresenceCard> {
  late final TextEditingController _details = TextEditingController(text: widget.presence.details ?? '');
  late final TextEditingController _state = TextEditingController(text: widget.presence.state ?? '');

  @override
  void dispose() {
    _details.dispose();
    _state.dispose();
    super.dispose();
  }

  void _set({String? details, String? state}) {
    final id = widget.presence.id;
    widget.onSave(
      (s) => copySettings(
        s,
        discordRpcProjectPresences: [
          for (final x in s.discordRpcProjectPresences)
            if (x.id == id)
              DiscordProjectPresence(
                id: x.id,
                details: details == null ? x.details : (details.isEmpty ? null : details),
                state: state == null ? x.state : (state.isEmpty ? null : state),
              )
            else
              x,
        ],
      ),
    );
  }

  Widget _field(GhTheme theme, TextEditingController controller, String placeholder, ValueChanged<String> onChanged) => GhTextInput(
    controller: controller,
    placeholder: placeholder,
    semanticLabel: placeholder,
    size: GhTextSize.xs,
    onChanged: onChanged,
    background: theme.base,
    borderColor: theme.outline.withValues(alpha: 0.5),
    focusBorderColor: theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final id = widget.presence.id;
    return Container(
      padding: EdgeInsets.all(theme.space(3)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          Row(
            spacing: theme.space(3),
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                ),
              ),
              _IconAction(
                icon: GhIcons.x,
                label: _ts('discord_custom_remove'),
                onPressed: () => widget.onSave(
                  (s) => copySettings(
                    s,
                    discordRpcProjectPresences: [
                      for (final x in s.discordRpcProjectPresences)
                        if (x.id != id) x,
                    ],
                  ),
                ),
                radius: theme.radiusMd,
                box: theme.space(6),
                padding: 0,
                idle: theme.muted,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(1.5),
            children: [
              _field(theme, _details, _ts('discord_custom_details_placeholder'), (v) => _set(details: v)),
              _field(theme, _state, _ts('discord_custom_state_placeholder'), (v) => _set(state: v)),
            ],
          ),
        ],
      ),
    );
  }
}
