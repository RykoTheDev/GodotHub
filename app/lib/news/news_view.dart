import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../logic/locale.dart';
import '../motion/animated_number.dart';
import '../motion/presence.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/news.dart';
import '../state/settings.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/spin.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';

String? formatNewsDate(String? iso) {
  if (iso == null) return null;
  final date = DateTime.tryParse(iso);
  if (date == null) return null;
  return formatLocaleDate(
    date.toLocal(),
    const GhDateFormatOptions(day: GhDatePart.numeric, month: GhDatePart.short, year: GhDatePart.numeric),
  );
}

List<List<T>> splitNewsColumns<T>(List<T> items, int columns) {
  if (columns <= 1) return [items];
  final perColumn = (items.length / columns).ceil();
  return [for (var c = 0; c < columns; c++) items.skip(c * perColumn).take(perColumn).toList()];
}

class NewsView extends ConsumerWidget {
  const NewsView({super.key, this.connected = false, this.prefs});

  final bool connected;
  final UiPrefsStore? prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final news = ref.watch(newsProvider);
    final feed = news.data;
    final notifier = ref.read(newsProvider.notifier);
    final loading = news.loading;
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: connected ? insets.start : (insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start),
      end: connected ? insets.end : (insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end),
      bottom: connected ? insets.bottom : (insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom),
    );
    final items = feed.items;
    final Widget body;
    if (loading && items.isEmpty) {
      body = _Masonry(children: [for (var i = 0; i < 6; i++) const _NewsCardSkeleton()]);
    } else if (news.error != null && items.isEmpty) {
      body = _NewsMessage(
        danger: true,
        icon: GhIcons.wifiOff,
        text: '${ghTr('news_error')} ${news.error}',
        action: _OutlineButton(icon: GhIcons.refresh, label: ghTr('try_again'), onPressed: () => notifier.reload().ignore()),
      );
    } else if (items.isEmpty) {
      body = _NewsMessage(icon: GhIcons.news, text: ghTr('news_empty'));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Masonry(
            children: [for (final item in items) NewsCard(key: ValueKey(item.id), item: item)],
          ),
          if (feed.hasMore)
            Padding(
              padding: EdgeInsets.only(top: theme.space(6)),
              child: Center(child: _ShowMoreButton(onPressed: notifier.showMore)),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end, bottom: theme.space(4)),
          child: GhViewHeader(
            connected: connected,
            title: ghTr('section_news'),
            metric: [
              DefaultTextStyle.merge(
                style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
                child: GhAnimatedNumber(feed.total),
              ),
              Text(
                ghTr('news_count').toUpperCase(),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            actions: [_RefreshButton(loading: loading, onPressed: () => notifier.reload().ignore())],
            child: Wrap(
              spacing: theme.space(1.5),
              runSpacing: theme.space(1.5),
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  ghTr('news_subtitle'),
                  style: theme.text(size: GhTextSize.xs, color: theme.muted),
                ),
                if (feed.fromCache)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                    decoration: BoxDecoration(
                      color: theme.overlay,
                      borderRadius: BorderRadius.circular(theme.radiusTag),
                      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1),
                      children: [
                        GhIcon(GhIcons.wifiOff, size: theme.space(3), color: theme.muted.withValues(alpha: 0.7)),
                        Text(
                          ghTr('news_cached'),
                          style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              topButtonBottom: theme.space(16),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(connected ? 3 : 2), theme.space(2), theme.space(5), theme.space(8)),
                child: body,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Masonry extends StatelessWidget {
  const _Masonry({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final columns = MediaQuery.sizeOf(context).width >= 1024 ? 2 : 1;
    final split = splitNewsColumns(children, columns);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(3),
      children: [
        for (final column in split)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final child in column)
                  Padding(
                    padding: EdgeInsets.only(bottom: theme.space(3)),
                    child: child,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class NewsCard extends StatefulWidget {
  const NewsCard({super.key, required this.item});

  final NewsItem item;

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _imageFailed = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final item = widget.item;
    final date = formatNewsDate(item.published);
    final radius = BorderRadius.circular(theme.radiusItem);
    final image = item.image;
    final category = item.category;
    final summary = item.summary;
    final author = item.author;
    return GhPressable(
      onPressed: () => OpenerApi.openUrl(item.link).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.radiusItem - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image != null && image.isNotEmpty && !_imageFailed)
                SizedBox(
                  height: theme.space(36),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        image,
                        frameBuilder: ghFadeInFrameBuilder,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stack) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_imageFailed) setState(() => _imageFailed = true);
                          });
                          return const SizedBox.shrink();
                        },
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: theme.space(14),
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [theme.overlay, theme.overlay.withValues(alpha: 0)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.space(5),
                  image != null && image.isNotEmpty && !_imageFailed ? theme.space(3) : theme.space(5),
                  theme.space(5),
                  theme.space(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(3),
                  children: [
                    Row(
                      children: [
                        if (category != null && category.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(theme.radiusTag),
                              border: Border.all(color: theme.accentDim.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: theme.text(
                                size: GhTextSize.x3s,
                                weight: GhWeight.semibold,
                                color: theme.accentBright,
                                letterSpacingEm: 0.05,
                              ),
                            ),
                          ),
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: states.hovered ? 1 : 0,
                          duration: GhDurations.color,
                          child: GhIcon(GhIcons.externalLink, size: theme.space(3), color: theme.muted),
                        ),
                      ],
                    ),
                    GhReveal(
                      id: 'news:${item.link}',
                      kind: GhRevealKind.heading,
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.ink, lineHeight: 1.375),
                      ),
                    ),
                    if (summary != null && summary.isNotEmpty)
                      Text(
                        summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                      ),
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1)),
                      child: Row(
                        spacing: theme.space(3),
                        children: [
                          if (date != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: theme.space(1.5),
                              children: [
                                GhIcon(GhIcons.clock, size: theme.space(3), color: theme.muted),
                                Text(
                                  date,
                                  style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                                ),
                              ],
                            ),
                          if (author != null && author.isNotEmpty)
                            Flexible(
                              child: Text(
                                author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCardSkeleton extends StatelessWidget {
  const _NewsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    Widget bar(double height, {double? width, double? fraction, double? radius}) {
      final box = Container(
        height: height,
        width: width,
        decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(radius ?? theme.rem(0.25))),
      );
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: fraction == null ? box : FractionallySizedBox(widthFactor: fraction, child: box),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: theme.space(36), color: theme.raised),
          Padding(
            padding: EdgeInsets.fromLTRB(theme.space(5), theme.space(3), theme.space(5), theme.space(5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(3),
              children: [
                bar(theme.space(4), width: theme.space(16), radius: theme.radiusTag),
                bar(theme.space(4), fraction: 0.8),
                bar(theme.space(3), fraction: 1),
                bar(theme.space(3), fraction: 0.75),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(1)),
                  child: bar(theme.space(3), width: theme.space(24)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsMessage extends StatelessWidget {
  const _NewsMessage({required this.icon, required this.text, this.action, this.danger = false});

  final FaIconData icon;
  final String text;
  final Widget? action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tone = danger ? theme.danger : theme.muted;
    return GhDashedBox(
      color: danger ? theme.danger.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5),
      radius: BorderRadius.circular(theme.radiusItem),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(24)),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            spacing: theme.space(4),
            children: [
              Container(
                width: theme.space(12),
                height: theme.space(12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: danger ? theme.danger.withValues(alpha: 0.1) : theme.overlay,
                  borderRadius: BorderRadius.circular(theme.radiusTile),
                  border: Border.all(color: danger ? theme.danger.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5)),
                ),
                child: GhIcon(icon, size: theme.space(5), color: tone),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.rem(20)),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: loading ? null : onPressed,
      borderRadius: radius,
      builder: (context, states) {
        final color = states.active ? theme.ink : theme.muted;
        final icon = GhIcon(GhIcons.refresh, size: theme.space(3.5), color: color);
        return GhAnimatedBox(
          height: theme.space(8),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
          color: states.active ? theme.raised : theme.overlay,
          borderRadius: radius,
          border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              loading ? GhSpinning(child: icon) : icon,
              Text(
                ghTr('refresh'),
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.icon, required this.label, required this.onPressed});

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            GhIcon(icon, size: theme.space(3.5), color: theme.ink),
            Text(
              label,
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(9),
        padding: EdgeInsets.symmetric(horizontal: theme.space(5)),
        alignment: Alignment.center,
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
        child: Text(
          ghTr('show_more'),
          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
        ),
      ),
    );
  }
}
