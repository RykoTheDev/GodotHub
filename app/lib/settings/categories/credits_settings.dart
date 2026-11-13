import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/opener.dart';
import '../../design/design.dart';
import '../../modals/contributor_prs_modal.dart';
import '../../motion/presence.dart';
import '../../state/contributors.dart';
import '../../ui/core/i18n.dart';
import '../../ui/core/interaction.dart';
import '../../ui/feedback/modal_shell.dart';
import '../../ui/feedback/toast.dart';

String _ts(String key) => ghTr('settings:$key');

const creditsDeveloperLogin = 'RykoTheDev';
const creditsDeveloperUrl = 'https://github.com/RykoTheDev';
const creditsDeveloperAvatar = 'https://github.com/RykoTheDev.png?size=80';
const creditsLicense = 'MIT';
const creditsBuiltWith = 'Flutter + Rust';

class CreditsSettings extends ConsumerWidget {
  const CreditsSettings({super.key});

  void _openContributor(BuildContext context, Contributor contributor) {
    showGhModal<void>(
      context,
      (modal) => ContributorPrsModal(login: contributor.login, avatarUrl: contributor.avatarUrl, onClose: () => Navigator.of(modal).pop()),
    ).ignore();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final contributors = ref.watch(contributorsProvider.select((s) => s.contributors));
    final radius = BorderRadius.circular(theme.radiusItem);
    final caption = theme.text(
      size: GhTextSize.x3s,
      weight: GhWeight.semibold,
      color: theme.muted.withValues(alpha: 0.5),
      letterSpacingEm: 0.05,
    );
    Widget infoTile(String label, String value) => Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        color: theme.raised.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(1),
        children: [
          Text(label.toUpperCase(), style: caption),
          Text(
            value,
            style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        Container(
          padding: EdgeInsets.all(theme.space(5)),
          decoration: BoxDecoration(color: theme.overlay, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(5),
            children: [
              Text(
                _ts('credits'),
                style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
              ),
              GhPressable(
                onPressed: () =>
                    OpenerApi.openUrl(creditsDeveloperUrl).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
                borderRadius: radius,
                builder: (context, states) => GhAnimatedBox(
                  borderRadius: radius,
                  color: states.active ? theme.raised : theme.raised.withValues(alpha: 0.4),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(4)),
                  child: Row(
                    spacing: theme.space(4),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.accent.withValues(alpha: 0.2), width: 2),
                        ),
                        child: CreditsAvatar(url: creditsDeveloperAvatar, login: creditsDeveloperLogin, size: theme.space(11), large: true),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creditsDeveloperLogin,
                              style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                            ),
                            Text(
                              _ts('credits_developer'),
                              style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(3),
                children: [
                  Expanded(child: infoTile(_ts('git_option_license'), creditsLicense)),
                  Expanded(child: infoTile(_ts('credits_built_with'), creditsBuiltWith)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(2),
                children: [
                  Text(_ts('credits_contributors').toUpperCase(), style: caption),
                  Wrap(
                    spacing: theme.space(2),
                    runSpacing: theme.space(2),
                    children: [
                      for (final contributor in contributors)
                        if (contributor.login != creditsDeveloperLogin)
                          _ContributorChip(contributor: contributor, onPressed: () => _openContributor(context, contributor)),
                    ],
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

class _ContributorChip extends StatelessWidget {
  const _ContributorChip({required this.contributor, required this.onPressed});

  final Contributor contributor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(999);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        borderRadius: radius,
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0.6),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            CreditsAvatar(url: contributor.avatarUrl, login: contributor.login, size: theme.space(5)),
            Text(
              contributor.login,
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class CreditsAvatar extends StatelessWidget {
  const CreditsAvatar({super.key, required this.url, required this.login, required this.size, this.large = false});

  final String url;
  final String login;
  final double size;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.accent.withValues(alpha: 0.15),
        border: Border.all(color: theme.accentDim.withValues(alpha: 0.3)),
      ),
      child: Text(
        login.isEmpty ? '' : login[0].toUpperCase(),
        style: theme.text(size: large ? GhTextSize.sm : GhTextSize.x4s, weight: GhWeight.bold, color: theme.accent),
      ),
    );
    if (url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        frameBuilder: ghFadeInFrameBuilder,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: login,
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
  }
}
