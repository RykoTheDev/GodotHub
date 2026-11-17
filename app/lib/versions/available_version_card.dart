import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../motion/motion.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../state/godot_versions.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/modal_kit.dart' show GhSpinnerIcon;
import 'version_logic.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

/// Below this width (in spacing units) the card stacks its actions under the
/// release details.
const double availableCardStackBelow = 110;

/// One downloadable release asset in the Available versions list.
///
/// Anatomy: the tag in mono, then channel, .NET and size badges. The trailing
/// side carries exactly one primary action for the current state: Install
/// when not installed, Resume when paused, none while downloading or queued
/// (Pause and Cancel are ghost buttons), and an Installed badge once it is on
/// disk. The release page link is always a ghost icon button.
class AvailableVersionCard extends StatelessWidget {
  const AvailableVersionCard({
    super.key,
    required this.tag,
    required this.asset,
    required this.source,
    required this.installed,
    required this.onInstall,
    required this.onOpenSource,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    this.download,
    this.miseBusy = false,
  });

  final String tag;
  final GodotReleaseAsset asset;
  final VersionSource source;
  final bool installed;
  final DownloadState? download;
  final bool miseBusy;
  final VoidCallback onInstall;
  final VoidCallback onOpenSource;
  final Future<void> Function() onPause;
  final Future<void> Function() onResume;
  final Future<void> Function() onCancel;

  void _guard(Future<void> Function() action) => action().catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

  Widget _progress(BuildContext context, GhTheme theme, DownloadState dl) {
    final paused = dl.status == DownloadStatus.paused;
    String mb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);
    return SizedBox(
      width: theme.space(44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.space(1)),
            child: Container(
              height: theme.space(1.5),
              color: theme.raised,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: GhMotion.of(context).css(GhDurations.progress),
                curve: GhCurves.outExpo,
                widthFactor: dl.total > 0 ? (dl.downloaded / dl.total).clamp(0.0, 1.0) : 0.06,
                child: GhAnimatedBox(
                  duration: GhDurations.progress,
                  color: paused ? theme.muted : theme.amber,
                  borderRadius: BorderRadius.circular(theme.space(1)),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: theme.space(1)),
            child: Text(
              '${paused ? _tv('paused_dot') : ''}${mb(dl.downloaded)} MB${dl.total > 0 ? ' / ${mb(dl.total)} MB' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme
                  .text(size: GhTextSize.x2s, mono: true, color: theme.muted)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ghost(FaIconData icon, String tooltip, VoidCallback onPressed) =>
      GhIconButton(icon: icon, onPressed: onPressed, tooltip: tooltip, variant: GhButtonVariant.ghost, padding: 2, iconSpace: 3.5);

  List<Widget> _actions(BuildContext context, GhTheme theme) {
    final sourceLink = _ghost(GhIcons.externalLink, _tv('view_release_page'), onOpenSource);
    if (miseBusy) {
      return [
        GhSpinnerIcon(size: 4, color: theme.amber),
        Text(
          _tv('mise_installing'),
          style: theme.text(size: GhTextSize.xs, color: theme.muted),
        ),
      ];
    }
    final dl = download;
    if (dl != null) {
      return [
        if (dl.status == DownloadStatus.queued)
          GhBadge(key: const ValueKey('available-queued'), label: ghTr('queued'), icon: GhIcons.clock)
        else
          _progress(context, theme, dl),
        if (dl.status == DownloadStatus.downloading) _ghost(GhIcons.pause, _tv('pause_download'), () => _guard(onPause)),
        _ghost(GhIcons.x, _tv('cancel_download'), () => _guard(onCancel)),
        if (dl.status == DownloadStatus.paused)
          GhIconButton(
            key: const ValueKey('available-resume'),
            icon: GhIcons.play,
            onPressed: () => _guard(onResume),
            tooltip: _tv('resume_download'),
            variant: GhButtonVariant.primary,
            padding: 2,
            iconSpace: 3.5,
          ),
      ];
    }
    if (installed) {
      return [
        sourceLink,
        GhBadge(
          key: const ValueKey('available-installed'),
          label: _tv('installed_label'),
          icon: GhIcons.check,
          tone: GhTone.mint,
          size: GhTextSize.x2s,
        ),
      ];
    }
    return [
      sourceLink,
      GhButton(
        key: const ValueKey('available-install'),
        onPressed: onInstall,
        label: _tv('install'),
        icon: GhIcons.download,
        variant: GhButtonVariant.primary,
        paddingY: 2,
      ),
    ];
  }

  Widget _details(GhTheme theme) {
    final stable = isStableTag(tag);
    return Wrap(
      spacing: theme.space(2),
      runSpacing: theme.space(1.5),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          tag.isEmpty ? _tv('unbound') : tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, mono: true, color: theme.ink),
        ),
        GhBadge(label: stable ? _tv('stable') : _tv('unstable'), tone: stable ? GhTone.muted : GhTone.amber),
        if (asset.isMono) GhBadge(label: '.NET', tone: GhTone.accent, tooltip: _tv('mono')),
        if (source != VersionSource.mise)
          Text(
            '${(asset.size.toDouble() / 1024 / 1024).toStringAsFixed(0)} ${_tv('mb')}',
            style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final busy = download != null || miseBusy;
    return GhReveal(
      id: 'available:${downloadKeyOf(tag, asset.name)}',
      child: GhCard(
        tone: busy ? GhTone.amber : null,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
        builder: (context, highlighted) => LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < theme.space(availableCardStackBelow);
            // Each action keeps its own semantics node; a lone button would
            // otherwise merge into the card's container node.
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [for (final action in _actions(context, theme)) Semantics(container: true, child: action)],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2.5),
                children: [
                  _details(theme),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(fit: BoxFit.scaleDown, child: actions),
                  ),
                ],
              );
            }
            return Row(
              spacing: theme.space(3),
              children: [
                Expanded(child: _details(theme)),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
