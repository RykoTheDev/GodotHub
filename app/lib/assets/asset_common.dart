import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

const assetPageSize = 12;

/// Web pages for the two sources, offered when a search fails.
const assetLibrarySiteUrl = 'https://godotengine.org/asset-library/asset';
const assetStoreSiteUrl = 'https://store.godotengine.org/';

const assetVersionOptions = ['4.7', '4.6', '4.5', '4.4', '4.3', '4.2', '4.1', '4.0'];

String assetDirname(String path) {
  final idx = path.lastIndexOf('/') > path.lastIndexOf('\\') ? path.lastIndexOf('/') : path.lastIndexOf('\\');
  return idx > 0 ? path.substring(0, idx) : path;
}

(String, String) parseStoreId(String id) {
  final rest = id.startsWith('store:') ? id.substring('store:'.length) : id;
  final idx = rest.indexOf('/');
  return idx > 0 ? (rest.substring(0, idx), rest.substring(idx + 1)) : (rest, '');
}

List<int?> assetPageItems(int page, int pages) {
  if (pages <= 7) return [for (var i = 0; i < pages; i++) i];
  final items = <int?>[0];
  if (page > 2) items.add(null);
  final start = page - 1 < 1 ? 1 : page - 1;
  final end = page + 1 > pages - 2 ? pages - 2 : page + 1;
  for (var i = start; i <= end; i++) {
    items.add(i);
  }
  if (page < pages - 3) items.add(null);
  items.add(pages - 1);
  return items;
}

void scrollAssetsToTop(BuildContext context) {
  final position = Scrollable.maybeOf(context)?.position;
  if (position != null && position.hasPixels) position.jumpTo(position.minScrollExtent);
}

class AssetDropButton extends StatelessWidget {
  const AssetDropButton({super.key, required this.label, required this.open, required this.onPressed, this.maxLabelWidth});

  final String label;
  final bool open;
  final VoidCallback onPressed;
  final double? maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.text(size: GhTextSize.base, weight: GhWeight.medium),
    );
    return GhPressable(
      onPressed: onPressed,
      expanded: open,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(8),
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            if (maxLabelWidth != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth!),
                child: text,
              )
            else
              text,
            GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
          ],
        ),
      ),
    );
  }
}

class AssetPageButton extends StatelessWidget {
  const AssetPageButton({super.key, this.icon, this.page, this.current = false, required this.onPressed, required this.semanticLabel});

  final FaIconData? icon;
  final int? page;
  final bool current;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      selected: current,
      disabledOpacity: 0.4,
      disabledCursor: SystemMouseCursors.forbidden,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active && onPressed != null;
        return GhAnimatedBox(
          height: theme.space(9),
          width: icon != null ? theme.space(9) : null,
          constraints: icon == null ? BoxConstraints(minWidth: theme.space(9)) : null,
          padding: icon == null ? EdgeInsets.symmetric(horizontal: theme.space(2.5)) : null,
          alignment: icon != null ? Alignment.center : null,
          color: current ? theme.accent : (hover ? theme.raised : theme.overlay),
          borderRadius: radius,
          border: current ? null : Border.all(color: theme.outline.withValues(alpha: 0.5)),
          child: icon != null
              ? Transform.flip(
                  flipX: rtl,
                  child: GhIcon(icon!, size: theme.space(4), color: hover ? theme.ink : theme.muted),
                )
              : Center(
                  widthFactor: 1,
                  child: ExcludeSemantics(
                    child: Text(
                      '${page! + 1}',
                      style: theme.text(
                        size: GhTextSize.xs,
                        weight: GhWeight.medium,
                        color: current ? Colors.white : (hover ? theme.ink : theme.muted),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class AssetPagination extends StatelessWidget {
  const AssetPagination({
    super.key,
    required this.page,
    required this.pages,
    required this.paging,
    required this.onNavigate,
    this.numbered = true,
    this.canPrev,
    this.canNext,
  });

  final int page;
  final int pages;
  final bool paging;
  final ValueChanged<int> onNavigate;
  final bool numbered;
  final bool? canPrev;
  final bool? canNext;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final prevEnabled = !paging && (canPrev ?? page > 0);
    final nextEnabled = !paging && (canNext ?? page + 1 < pages);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: theme.space(1.5),
      runSpacing: theme.space(1.5),
      children: [
        AssetPageButton(
          icon: GhIcons.chevronLeft,
          semanticLabel: ghTr('asset_prev_page'),
          onPressed: prevEnabled ? () => onNavigate(page - 1) : null,
        ),
        if (numbered)
          for (final item in assetPageItems(page, pages))
            if (item == null)
              ExcludeSemantics(
                child: SizedBox(
                  width: theme.space(6),
                  child: Text(
                    '…',
                    textAlign: TextAlign.center,
                    style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.5)),
                  ),
                ),
              )
            else
              AssetPageButton(
                page: item,
                current: item == page,
                semanticLabel: ghTr('asset_page_x_of_y', args: {'page': item + 1, 'total': pages}),
                onPressed: paging ? null : () => onNavigate(item),
              ),
        AssetPageButton(
          icon: GhIcons.chevronRight,
          semanticLabel: ghTr('asset_next_page'),
          onPressed: nextEnabled ? () => onNavigate(page + 1) : null,
        ),
      ],
    );
  }
}
