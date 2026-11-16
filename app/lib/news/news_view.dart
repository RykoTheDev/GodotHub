import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../logic/locale.dart';
import '../motion/animated_number.dart';
import '../motion/motion.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/news.dart';
import '../state/settings.dart';
import '../ui/controls/spin.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/card_grid.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/showcase_card.dart';
import '../ui/reusables/state_panel.dart';
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

/// The site the feed comes from (crates/godothub-core/src/news.rs reads
/// its rss.xml), offered when the feed can't be loaded or is empty.
const godotBlogUrl = 'https://godotengine.org/';

void _openUrl(String url) => OpenerApi.openUrl(url).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')).ignore();

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
    final openSite = GhButton(
      onPressed: () => _openUrl(godotBlogUrl),
      label: ghTr('news_open_site'),
      icon: GhIcons.externalLink,
      variant: GhButtonVariant.ghost,
    );
    final Widget body;
    if (loading && items.isEmpty) {
      body = GhCardGrid.fill(
        rows: 2,
        breakpoints: GhGridBreakpoints.reading,
        builder: (context, _) => const GhCardSkeleton(mediaHeight: 38, footer: false, showcase: true),
      );
    } else if (news.error != null && items.isEmpty) {
      body = GhStatePanel.error(
        title: ghTr('news_error'),
        message: '${news.error}',
        onRetry: () => notifier.reload().ignore(),
        actions: [openSite],
      );
    } else if (items.isEmpty) {
      body = GhStatePanel.empty(
        icon: GhIcons.news,
        title: ghTr('news_empty'),
        actions: [
          GhButton(
            onPressed: () => notifier.reload().ignore(),
            label: ghTr('refresh'),
            icon: GhIcons.refresh,
            variant: GhButtonVariant.outline,
          ),
          openSite,
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(4),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // The newest post gets a wide hero once the grid has room for
              // three columns; below that it is just the first card.
              final columns = GhGridBreakpoints.reading.columnsFor(constraints.maxWidth, fontScale: theme.fontScale);
              final featured = items.length > 1 && columns >= 3;
              final rest = (featured ? items.skip(1) : items).toList();
              // While more posts can be loaded, show only complete rows; the
              // rest arrive with "Show more" instead of leaving a ragged row.
              final full = (rest.length ~/ columns) * columns;
              final shown = feed.hasMore && full > 0 ? rest.take(full) : rest;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(4),
                children: [
                  if (featured) NewsFeaturedCard(key: ValueKey('featured:${items.first.id}'), item: items.first),
                  GhCardGrid(
                    breakpoints: GhGridBreakpoints.reading,
                    gap: 4,
                    children: [for (final item in shown) NewsCard(key: ValueKey(item.id), item: item)],
                  ),
                ],
              );
            },
          ),
          if (feed.hasMore)
            Padding(
              padding: EdgeInsets.only(top: theme.space(3)),
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
                ghTr('news_count'),
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
                  GhBadge(
                    label: ghTr('news_cached'),
                    icon: GhIcons.wifiOff,
                    tooltip: ghTr('news_cached'),
                    size: GhTextSize.x2s,
                    maxWidth: theme.space(140),
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
              topButtonBottom: theme.space(24),
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

/// One blog post as a showcase card: the article image full bleed (or a
/// generated cover), the category as a glass chip, then author and date,
/// a bold title, a three-line summary and a "Read" cue that slides on
/// hover. The whole card opens the post.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final category = item.category;
    return GhCard(
      lift: true,
      semanticLabel: item.title,
      onPressed: () => _openUrl(item.link),
      builder: (context, highlighted) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GhCover(
            seed: item.title,
            imageUrl: item.image,
            fallbackIcon: GhIcons.news,
            zoom: highlighted,
            height: 38,
            topStart: [if (category != null && category.isNotEmpty) GhGlassChip(label: category)],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(theme.space(4.5), theme.space(4), theme.space(4.5), theme.space(4.5)),
              child: _NewsText(item: item, highlighted: highlighted, titleSize: GhTextSize.lg, summaryLines: 3),
            ),
          ),
        ],
      ),
    );
  }
}

/// The newest post across the full width on wide layouts: the image on one
/// side, a large title and a longer summary on the other.
class NewsFeaturedCard extends StatelessWidget {
  const NewsFeaturedCard({super.key, required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final category = item.category;
    return GhCard(
      lift: true,
      semanticLabel: item.title,
      onPressed: () => _openUrl(item.link),
      builder: (context, highlighted) => SizedBox(
        height: theme.space(80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: GhCover(
                seed: item.title,
                imageUrl: item.image,
                fallbackIcon: GhIcons.news,
                zoom: highlighted,
                height: 80,
                topStart: [
                  GhGlassChip(label: ghTr('news_featured'), icon: GhIcons.star, iconColor: theme.amber),
                  if (category != null && category.isNotEmpty) GhGlassChip(label: category),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(theme.space(7)),
                child: _NewsText(item: item, highlighted: highlighted, titleSize: GhTextSize.x2l, summaryLines: 5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsText extends StatelessWidget {
  const _NewsText({required this.item, required this.highlighted, required this.titleSize, required this.summaryLines});

  final NewsItem item;
  final bool highlighted;
  final GhTextSize titleSize;
  final int summaryLines;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final date = formatNewsDate(item.published);
    final author = item.author;
    final hasAuthor = author != null && author.isNotEmpty;
    final summary = item.summary?.trim();
    final meta = [if (hasAuthor) author, ?date].join('  ·  ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2.5),
      children: [
        Row(
          spacing: theme.space(2),
          children: [
            if (hasAuthor) GhInitialsAvatar(name: author, size: 5),
            Flexible(
              child: Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
              ),
            ),
          ],
        ),
        GhReveal(
          id: 'news:${item.link}',
          kind: GhRevealKind.heading,
          child: Text(
            item.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.text(size: titleSize, weight: GhWeight.bold, lineHeight: 1.25, letterSpacingEm: -0.015),
          ),
        ),
        if (summary != null && summary.isNotEmpty)
          Text(
            summary,
            maxLines: summaryLines,
            overflow: TextOverflow.ellipsis,
            style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.55),
          ),
        const Spacer(),
        Row(
          spacing: theme.space(2),
          children: [
            Text(
              ghTr('news_read_more'),
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: highlighted ? theme.accentBright : theme.ink),
            ),
            AnimatedSlide(
              offset: Offset(highlighted && !motion.off ? 0.35 : 0, 0),
              duration: motion.css(GhDurations.interactive),
              curve: GhCurves.outExpo,
              child: GhIcon(GhIcons.chevronRight, size: theme.space(3), color: highlighted ? theme.accentBright : theme.muted),
            ),
          ],
        ),
      ],
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
