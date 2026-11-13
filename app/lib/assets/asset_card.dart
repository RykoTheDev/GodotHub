import 'package:flutter/material.dart';

import '../design/design.dart';
import '../motion/presence.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';

double? parseAssetRating(String raw) {
  final match = RegExp(r'^\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?').firstMatch(raw);
  if (match == null) return null;
  return double.tryParse(match.group(0)!.trim());
}

class AssetCard extends StatefulWidget {
  const AssetCard({super.key, required this.asset, this.onOpenPage, this.actions, this.showSource = false});

  final AssetLibraryAsset asset;
  final VoidCallback? onOpenPage;
  final Widget? actions;
  final bool showSource;

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
  bool _hover = false;

  ({Color bg, Color fg, Color border}) _support(GhTheme theme, String level) => switch (level) {
    'official' => (bg: theme.mint.withValues(alpha: 0.1), fg: theme.mint, border: theme.mint.withValues(alpha: 0.2)),
    'featured' => (bg: theme.accent.withValues(alpha: 0.1), fg: theme.accentBright, border: theme.accentDim.withValues(alpha: 0.4)),
    'community' => (bg: theme.raised, fg: theme.muted, border: theme.line),
    'testing' || 'testers' => (bg: theme.amber.withValues(alpha: 0.1), fg: theme.amber, border: theme.amber.withValues(alpha: 0.2)),
    _ => (bg: theme.raised, fg: theme.muted, border: theme.outline.withValues(alpha: 0.5)),
  };

  Widget _badge(GhTheme theme, {required Color bg, required Color fg, required Color border, required List<Widget> children}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(theme.radiusTag),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
          child: DefaultTextStyle.merge(
            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: fg),
            child: Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(1), children: children),
          ),
        ),
      );

  Widget _icon(String url, {required double opacity}) => Positioned.fill(
    child: Opacity(
      opacity: opacity,
      child: Image.network(
        url,
        frameBuilder: ghFadeInFrameBuilder,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final asset = widget.asset;
    final hover = _hover;
    final metaParts = [
      if (asset.godotVersion.isNotEmpty) 'Godot ${asset.godotVersion}',
      if (asset.category.isNotEmpty) asset.category,
      if (asset.cost.isNotEmpty) asset.cost,
    ];
    final rating = parseAssetRating(asset.rating);
    final hasRating = rating != null && rating.isFinite && rating > 0;
    final iconUrl = asset.iconUrl;
    final radius = BorderRadius.circular(theme.radiusItem);
    final topRadius = BorderRadius.vertical(top: Radius.circular(theme.radiusItem));
    final description = asset.description;
    final support = asset.supportLevel.isNotEmpty ? _support(theme, asset.supportLevel) : null;
    return GhReveal(
      id: 'asset:${asset.assetId}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hover ? theme.raised : theme.overlay,
            borderRadius: radius,
            border: Border.all(color: hover ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: topRadius,
                child: SizedBox(
                  height: theme.space(24),
                  child: ColoredBox(
                    color: theme.raised,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (iconUrl != null && iconUrl.isNotEmpty) _icon(iconUrl, opacity: hover ? 0 : 0.15),
                        if (!hover)
                          PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 0,
                            height: theme.space(10),
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
                        Opacity(
                          opacity: hover ? 1 : 0,
                          child: Container(
                            width: theme.space(14),
                            height: theme.space(14),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: theme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(theme.radiusTile),
                              border: Border.all(color: theme.outline.withValues(alpha: 0.6)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GhIcon(GhIcons.store, size: theme.space(5), color: theme.muted.withValues(alpha: 0.5)),
                                if (iconUrl != null && iconUrl.isNotEmpty) _icon(iconUrl, opacity: 1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(theme.space(4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(1.5),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: theme.space(2),
                        children: [
                          Expanded(
                            child: Text(
                              asset.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, lineHeight: 1.375),
                            ),
                          ),
                          if (widget.onOpenPage != null)
                            Opacity(
                              opacity: hover ? 1 : 0,
                              alwaysIncludeSemantics: true,
                              child: GhPressable(
                                onPressed: widget.onOpenPage,
                                semanticLabel: ghTr('asset_open_page'),
                                borderRadius: BorderRadius.circular(theme.radiusBtn),
                                builder: (context, states) => GhAnimatedBox(
                                  padding: EdgeInsets.all(theme.space(1)),
                                  color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                                  child: GhIcon(
                                    GhIcons.externalLink,
                                    size: theme.space(3.5),
                                    color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Wrap(
                        spacing: theme.space(1.5),
                        runSpacing: theme.space(1.5),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            ghTr('asset_by_author', args: {'author': asset.author}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
                          ),
                          if (widget.showSource && asset.source.isNotEmpty)
                            _badge(
                              theme,
                              bg: theme.accent.withValues(alpha: 0.1),
                              fg: theme.accentBright,
                              border: theme.accentDim.withValues(alpha: 0.3),
                              children: [Text(ghTr('asset_source_${asset.source}'))],
                            ),
                          if (hasRating)
                            _badge(
                              theme,
                              bg: theme.amber.withValues(alpha: 0.1),
                              fg: theme.amber,
                              border: theme.amber.withValues(alpha: 0.25),
                              children: [
                                GhIcon(GhIcons.star, size: theme.space(2.5), color: theme.amber),
                                Text(rating.toStringAsFixed(1)),
                              ],
                            ),
                          if (support != null)
                            _badge(theme, bg: support.bg, fg: support.fg, border: support.border, children: [Text(asset.supportLevel)]),
                        ],
                      ),
                      if (description != null && description.isNotEmpty)
                        Text(
                          description.replaceAll(RegExp(r'\r?\n'), ' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.6), lineHeight: 1.625),
                        ),
                      if (metaParts.isNotEmpty) ...[
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.only(top: theme.space(2)),
                          child: Wrap(
                            spacing: theme.space(1.5),
                            runSpacing: theme.space(1.5),
                            children: [
                              for (final part in metaParts)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(theme.radiusTag),
                                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                                    child: Text(
                                      part,
                                      style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.actions != null)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(theme.space(4), theme.space(1), theme.space(4), theme.space(4)),
                  child: widget.actions,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
