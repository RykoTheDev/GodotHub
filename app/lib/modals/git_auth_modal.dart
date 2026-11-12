import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/git_auth.dart';
import '../api/opener.dart';
import '../design/design.dart';
import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

enum GitAuthStatus { starting, waiting, success, error, expired }

String formatAuthRemaining(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String _s(String key, {Map<String, Object?> args = const {}}) => ghTr('settings:$key', args: args);

Future<void> showGitAuthModal(
  BuildContext context, {
  required String provider,
  String? baseUrl,
  String? clientId,
  required ValueChanged<String> onConnected,
}) => showGhModal<void>(
  context,
  (modal) => GitAuthModal(
    provider: provider,
    baseUrl: baseUrl,
    clientId: clientId,
    onClose: () => Navigator.of(modal).pop(),
    onConnected: onConnected,
  ),
);

class GitAuthModal extends StatefulWidget {
  const GitAuthModal({super.key, required this.provider, this.baseUrl, this.clientId, required this.onClose, required this.onConnected});

  final String provider;
  final String? baseUrl;
  final String? clientId;
  final VoidCallback onClose;
  final ValueChanged<String> onConnected;

  @override
  State<GitAuthModal> createState() => _GitAuthModalState();
}

class _GitAuthModalState extends State<GitAuthModal> {
  final FocusNode _dialog = FocusNode(debugLabel: 'GitAuthModal');
  DeviceFlowStart? _flow;
  GitAuthStatus _status = GitAuthStatus.starting;
  String? _message;
  bool _copied = false;
  bool _linkCopied = false;
  bool _opened = false;
  int? _remaining;
  int _attempt = 0;
  Timer? _poll;
  Timer? _tick;
  Timer? _copiedTimer;
  Timer? _linkTimer;
  Timer? _closeTimer;

  String get _providerLabel => widget.provider == 'github' ? 'GitHub' : 'GitLab';

  String? get _verificationUrl {
    final flow = _flow;
    if (flow == null) return null;
    return flow.verificationUriComplete.isNotEmpty ? flow.verificationUriComplete : flow.verificationUri;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _attempt++;
    for (final timer in [_poll, _tick, _copiedTimer, _linkTimer, _closeTimer]) {
      timer?.cancel();
    }
    _dialog.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    _poll?.cancel();
    _tick?.cancel();
    setState(() {
      _flow = null;
      _status = GitAuthStatus.starting;
      _message = null;
      _opened = false;
      _remaining = null;
    });
    try {
      final info = await GitAuthApi.startDeviceFlow(widget.provider, widget.baseUrl, widget.clientId);
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _flow = info;
        _status = GitAuthStatus.waiting;
        _remaining = info.expiresIn.toInt();
      });
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _countDown(attempt));
      _schedulePoll(info, attempt);
    } catch (e) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _status = GitAuthStatus.error;
        _message = '$e';
      });
    }
  }

  void _countDown(int attempt) {
    if (!mounted || attempt != _attempt || _status != GitAuthStatus.waiting) return;
    final next = (_remaining ?? 0) - 1;
    if (next <= 0) {
      _poll?.cancel();
      _tick?.cancel();
      setState(() {
        _remaining = 0;
        _status = GitAuthStatus.expired;
      });
      return;
    }
    setState(() => _remaining = next);
  }

  void _schedulePoll(DeviceFlowStart info, int attempt) {
    _poll = Timer(Duration(seconds: info.interval.toInt()), () => _pollOnce(info, attempt));
  }

  Future<void> _pollOnce(DeviceFlowStart info, int attempt) async {
    if (!mounted || attempt != _attempt || _status != GitAuthStatus.waiting) return;
    try {
      final result = await GitAuthApi.pollDeviceFlow(widget.provider, info.deviceCode, widget.baseUrl, widget.clientId);
      if (!mounted || attempt != _attempt || _status != GitAuthStatus.waiting) return;
      switch (result.status) {
        case dto.DeviceFlowStatus.success:
          _tick?.cancel();
          final username = result.username ?? '';
          setState(() {
            _status = GitAuthStatus.success;
            _message = username;
          });
          widget.onConnected(username);
          _closeTimer = Timer(const Duration(milliseconds: 1600), () {
            if (mounted) widget.onClose();
          });
        case dto.DeviceFlowStatus.error:
          _tick?.cancel();
          setState(() {
            _status = GitAuthStatus.error;
            _message = result.message;
          });
        case dto.DeviceFlowStatus.pending:
          _schedulePoll(info, attempt);
      }
    } catch (e) {
      if (!mounted || attempt != _attempt) return;
      _tick?.cancel();
      setState(() {
        _status = GitAuthStatus.error;
        _message = '$e';
      });
    }
  }

  Future<bool> _copyCode() async {
    final flow = _flow;
    if (flow == null) return false;
    try {
      await Clipboard.setData(ClipboardData(text: flow.userCode));
      if (!mounted) return true;
      setState(() => _copied = true);
      _copiedTimer?.cancel();
      _copiedTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _copied = false);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _copyAndOpen() async {
    await _copyCode();
    final url = _verificationUrl;
    if (url == null || !mounted) return;
    OpenerApi.openUrl(url).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
    setState(() => _opened = true);
  }

  Future<void> _copyLink() async {
    final url = _verificationUrl;
    if (url == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      setState(() => _linkCopied = true);
      _linkTimer?.cancel();
      _linkTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _linkCopied = false);
      });
    } catch (_) {}
  }

  Widget _primary(GhTheme theme, {required FaIconData icon, required String label, required VoidCallback onPressed}) => GhPressable(
    onPressed: onPressed,
    rippleColor: Colors.white,
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    builder: (context, states) => GhAnimatedBox(
      color: states.active ? theme.accentBright : theme.accent,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: theme.space(2),
        children: [
          GhIcon(icon, size: theme.space(4), color: Colors.white),
          Flexible(
            child: Text(
              label,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _step(
    GhTheme theme, {
    required int index,
    required String title,
    required bool done,
    required bool active,
    bool last = false,
    Widget? child,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3.5),
        children: [
          SizedBox(
            width: theme.space(7),
            child: Column(
              children: [
                Container(
                  width: theme.space(7),
                  height: theme.space(7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? theme.mint.withValues(alpha: 0.15)
                        : active
                        ? theme.accent
                        : theme.raised,
                    border: done || active ? null : Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: done
                      ? GhIcon(GhIcons.check, size: theme.space(3), color: theme.mint)
                      : Text(
                          '$index',
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: active ? Colors.white : theme.muted),
                        ),
                ),
                if (!last)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.space(1)),
                      child: Container(width: 1, color: theme.outline.withValues(alpha: 0.4)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: theme.space(1), bottom: last ? 0 : theme.space(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2.5),
                children: [
                  Text(
                    title,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: active || done ? theme.ink : theme.muted),
                  ),
                  ?child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waiting(GhTheme theme, DeviceFlowStart flow) {
    final groups = flow.userCode.split('-');
    final url = _verificationUrl;
    final remaining = _remaining;
    final expiringSoon = remaining != null && remaining <= 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _step(
          theme,
          index: 1,
          title: _s('git_auth_step_copy'),
          done: _copied || _opened,
          active: !_copied && !_opened,
          child: GhPressable(
            onPressed: _copyCode,
            semanticLabel: '${_s('git_auth_copy_code')}: ${flow.userCode}',
            borderRadius: BorderRadius.circular(16),
            builder: (context, states) => GhAnimatedBox(
              color: theme.base,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
              padding: EdgeInsetsDirectional.fromSTEB(theme.space(4), theme.space(3), theme.space(3), theme.space(3)),
              child: Row(
                spacing: theme.space(3),
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        groups.join(' – '),
                        textDirection: TextDirection.ltr,
                        style: theme.text(
                          size: GhTextSize.x2l,
                          weight: GhWeight.semibold,
                          mono: true,
                          color: theme.ink,
                          letterSpacingEm: 0.2,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: theme.space(7),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2.5)),
                    decoration: BoxDecoration(
                      color: _copied ? theme.mint.withValues(alpha: 0.15) : theme.raised,
                      borderRadius: BorderRadius.circular(theme.space(3.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1),
                      children: [
                        GhIcon(
                          _copied ? GhIcons.check : GhIcons.copy,
                          size: theme.space(3),
                          color: _copied ? theme.mint : (states.active ? theme.ink : theme.muted),
                        ),
                        Text(
                          _copied ? _s('git_auth_copied') : _s('git_auth_copy_code'),
                          style: theme.text(
                            size: GhTextSize.x2s,
                            weight: GhWeight.semibold,
                            color: _copied ? theme.mint : (states.active ? theme.ink : theme.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _step(
          theme,
          index: 2,
          title: _s('git_auth_step_paste', args: {'provider': _providerLabel}),
          done: _opened,
          active: !_opened,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              _primary(
                theme,
                icon: GhIcons.externalLink,
                label: _s('git_auth_copy_and_open', args: {'provider': _providerLabel}),
                onPressed: _copyAndOpen,
              ),
              if (url != null)
                GhPressable(
                  onPressed: _copyLink,
                  semanticLabel: _s('git_auth_copy_link'),
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  builder: (context, states) => GhAnimatedBox(
                    color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: states.active ? theme.accentDim : theme.line),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: theme.space(2),
                      children: [
                        GhIcon(
                          _linkCopied ? GhIcons.check : GhIcons.copy,
                          size: theme.space(4),
                          color: _linkCopied ? theme.mint : (states.active ? theme.ink : theme.muted),
                        ),
                        Flexible(
                          child: Text(
                            url.replaceFirst(RegExp('^https?://'), ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: theme.text(size: GhTextSize.sm, color: states.active ? theme.ink : theme.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _step(
          theme,
          index: 3,
          title: _s('git_auth_step_approve'),
          done: false,
          active: _opened,
          last: true,
          child: Semantics(
            liveRegion: true,
            child: Row(
              spacing: theme.space(3),
              children: [
                GhSpinnerIcon(size: 3.5, color: theme.muted),
                Expanded(
                  child: Text(
                    _s('git_auth_waiting'),
                    style: theme.text(size: GhTextSize.xs, color: theme.muted),
                  ),
                ),
                if (remaining != null)
                  Text(
                    _s('git_auth_expires_in', args: {'time': formatAuthRemaining(remaining)}),
                    style: theme
                        .text(size: GhTextSize.xs, color: expiringSoon ? theme.danger : theme.muted.withValues(alpha: 0.7))
                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(GhTheme theme) {
    final flow = _flow;
    switch (_status) {
      case GitAuthStatus.starting:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(8)),
          child: Column(
            spacing: theme.space(3),
            children: [
              GhSpinnerIcon(size: 5, color: theme.accentBright),
              Text(
                ghTr('starting'),
                style: theme.text(size: GhTextSize.sm, color: theme.muted),
              ),
            ],
          ),
        );
      case GitAuthStatus.success:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(6)),
          child: Column(
            spacing: theme.space(1.5),
            children: [
              Text(
                ghTr('settings:git_connected_as', args: {'username': _message ?? ''}),
                textAlign: TextAlign.center,
                style: theme.text(size: GhTextSize.base, weight: GhWeight.semibold, color: theme.ink),
              ),
              Text(
                _s('git_auth_success_hint'),
                style: theme.text(size: GhTextSize.xs, color: theme.muted),
              ),
            ],
          ),
        );
      case GitAuthStatus.error || GitAuthStatus.expired:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(4),
            children: [
              Center(
                child: Container(
                  width: theme.space(11),
                  height: theme.space(11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: theme.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.danger),
                ),
              ),
              Column(
                spacing: theme.space(1),
                children: [
                  Text(
                    _status == GitAuthStatus.expired ? _s('git_auth_expired') : _s('git_auth_failed'),
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                  ),
                  if (_status == GitAuthStatus.error && (_message?.isNotEmpty ?? false))
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: theme.rem(20)),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                      ),
                    ),
                ],
              ),
              _primary(theme, icon: GhIcons.refresh, label: _s('git_auth_try_again'), onPressed: _start),
            ],
          ),
        );
      case GitAuthStatus.waiting:
        return flow == null ? const SizedBox.shrink() : _waiting(theme, flow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final host = widget.provider == 'gitlab' && widget.baseUrl != null ? widget.baseUrl!.replaceFirst(RegExp('^https?://'), '') : null;
    final title = _s('git_auth_title', args: {'provider': _providerLabel});
    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(dismissible: false, color: Color(0xB3000000)),
        Center(
          child: Padding(
            padding: EdgeInsets.all(theme.space(4)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.rem(28), maxHeight: MediaQuery.sizeOf(context).height - theme.space(8)),
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: title,
                child: FocusScope(
                  autofocus: true,
                  onKeyEvent: (node, event) =>
                      event.logicalKey == LogicalKeyboardKey.escape ? KeyEventResult.handled : KeyEventResult.ignored,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
                        boxShadow: GhShadows.xl2(),
                      ),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(theme.space(7), theme.space(9), theme.space(7), theme.space(6)),
                                  child: Column(
                                    spacing: theme.space(3),
                                    children: [
                                      SizedBox(
                                        width: theme.space(16),
                                        height: theme.space(16),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: theme.raised,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                                              ),
                                              child: GhIcon(
                                                widget.provider == 'github' ? GhIcons.github : GhIcons.gitlab,
                                                size: theme.space(8),
                                                color: theme.ink,
                                              ),
                                            ),
                                            if (_status == GitAuthStatus.success)
                                              PositionedDirectional(
                                                bottom: -theme.space(1),
                                                end: -theme.space(1),
                                                child: Container(
                                                  width: theme.space(6),
                                                  height: theme.space(6),
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: theme.mint,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: theme.surface, width: 4),
                                                  ),
                                                  child: GhIcon(GhIcons.check, size: theme.space(3), color: Colors.white),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: theme.text(
                                          size: GhTextSize.xl,
                                          weight: FontWeight.w900,
                                          color: theme.ink,
                                          letterSpacingEm: -0.025,
                                        ),
                                      ),
                                      if (host != null)
                                        Text(
                                          host,
                                          textDirection: TextDirection.ltr,
                                          style: theme.text(size: GhTextSize.xs, color: theme.muted),
                                        ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(theme.space(7), 0, theme.space(7), theme.space(9)),
                                  child: _body(theme),
                                ),
                              ],
                            ),
                          ),
                          PositionedDirectional(
                            top: theme.space(4),
                            end: theme.space(4),
                            child: GhPressable(
                              onPressed: widget.onClose,
                              semanticLabel: ghTr('close'),
                              borderRadius: BorderRadius.circular(theme.space(4)),
                              builder: (context, states) => GhAnimatedBox(
                                width: theme.space(8),
                                height: theme.space(8),
                                color: states.active ? theme.ink.withValues(alpha: 0.1) : theme.ink.withValues(alpha: 0),
                                borderRadius: BorderRadius.circular(theme.space(4)),
                                alignment: Alignment.center,
                                child: GhIcon(GhIcons.x, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
