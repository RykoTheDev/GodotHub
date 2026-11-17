import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/showcase_card.dart';

double? parseAssetRating(String raw) {
  final match = RegExp(r'^\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?').firstMatch(raw);
  if (match == null) return null;
  return double.tryParse(match.group(0)!.trim());
}

/// The Store reports ratings as a percentage of positive reviews (81) and
/// the Asset Library on a five-point scale (4.2); show each the way it reads.
String formatAssetRating(double rating) => rating > 5 ? '${rating.round()}%' : rating.toStringAsFixed(1);

/// Badge tone for an Asset Library support level.
GhTone assetSupportTone(String level) => switch (level) {
  'official' => GhTone.mint,
  'featured' => GhTone.accent,
  'testing' || 'testers' => GhTone.amber,
  _ => GhTone.muted,
};

/// One Asset Store or Asset Library result as a showcase card: a cover
/// (the Store's thumbnail full bleed, or an Asset Library icon over its own
/// blurred colors) with glass chips for source, rating, installs and updates
/// and quick actions (save, not interested, open page) that appear on hover
/// or focus; then the title, author, description, detail badges, and the
/// install actions in the footer. The whole card opens the details.
class AssetCard extends StatelessWidget {
  const AssetCard({
    super.key,
    required this.asset,
    this.onOpenPage,
    this.actions,
    this.showSource = false,
    this.onOpenDetails,
    this.favorite = false,
    this.onToggleFavorite,
    this.installedIn = const [],
    this.updateAvailable = false,
    this.onHide,
  });

  final AssetLibraryAsset asset;
  final VoidCallback? onOpenPage;

  /// Footer actions, primary action last.
  final List<Widget>? actions;
  final bool showSource;

  /// Opens the detail dialog; the whole card becomes the button.
  final VoidCallback? onOpenDetails;
  final bool favorite;
  final VoidCallback? onToggleFavorite;

  /// Names of the projects GodotHub installed this asset into.
  final List<String> installedIn;
  final bool updateAvailable;

  /// "Not interested": hides the asset from results.
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rating = parseAssetRating(asset.rating);
    final hasRating = rating != null && rating.isFinite && rating > 0;
    final description = asset.description?.replaceAll(RegExp(r'\r?\n'), ' ').trim();
    final openPage = onOpenPage;
    final details = [
      if (asset.supportLevel.isNotEmpty) GhBadge(label: asset.supportLevel, tone: assetSupportTone(asset.supportLevel)),
      if (asset.category.isNotEmpty) GhBadge(label: asset.category, maxWidth: theme.space(40)),
      if (asset.cost.isNotEmpty) GhBadge(label: asset.cost, mono: true, maxWidth: theme.space(32)),
    ];
    return GhReveal(
      id: 'asset:${asset.assetId}',
      child: GhCard(
        lift: true,
        semanticLabel: asset.title,
        onPressed: onOpenDetails,
        builder: (context, highlighted) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GhCover(
              seed: asset.title,
              imageUrl: asset.iconUrl,
              fallbackIcon: GhIcons.store,
              zoom: highlighted,
              topStart: [
                if (showSource && asset.source.isNotEmpty) GhGlassChip(label: ghTr('asset_source_${asset.source}')),
                if (hasRating) GhGlassChip(label: formatAssetRating(rating), icon: GhIcons.star, iconColor: theme.amber),
                if (installedIn.isNotEmpty)
                  GhGlassChip(
                    label: ghTr('asset_in_projects', count: installedIn.length),
                    icon: GhIcons.circleCheck,
                    iconColor: theme.mint,
                    tooltip: installedIn.join(', '),
                  ),
                if (updateAvailable) GhGlassChip(label: ghTr('asset_update_available'), icon: GhIcons.arrowUp, iconColor: theme.amber),
              ],
              topEnd: [
                if (onHide != null)
                  GhGlassIconButton(
                    key: ValueKey('asset-hide-${asset.assetId}'),
                    icon: GhIcons.eyeSlash,
                    onPressed: onHide,
                    label: ghTr('asset_not_interested'),
                    visible: highlighted,
                  ),
                if (openPage != null)
                  GhGlassIconButton(icon: GhIcons.externalLink, onPressed: openPage, label: ghTr('asset_open_page'), visible: highlighted),
                if (onToggleFavorite != null)
                  GhGlassIconButton(
                    key: ValueKey('asset-favorite-${asset.assetId}'),
                    icon: GhIcons.star,
                    onPressed: onToggleFavorite,
                    label: favorite ? ghTr('asset_unsave') : ghTr('asset_save'),
                    active: favorite,
                    visible: highlighted,
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(theme.space(4), theme.space(3.5), theme.space(4), theme.space(1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(2),
                  children: [
                    Text(
                      asset.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold, lineHeight: 1.3, letterSpacingEm: -0.01),
                    ),
                    Row(
                      spacing: theme.space(2),
                      children: [
                        GhInitialsAvatar(name: asset.author.isEmpty ? asset.title : asset.author, size: 5),
                        Flexible(
                          child: Text(
                            asset.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
                          ),
                        ),
                        if (asset.godotVersion.isNotEmpty)
                          Text(
                            'Godot ${asset.godotVersion}',
                            style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted.withValues(alpha: 0.8)),
                          ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.55),
                      ),
                    const Spacer(),
                    if (details.isNotEmpty) Wrap(spacing: theme.space(1.5), runSpacing: theme.space(1.5), children: details),
                  ],
                ),
              ),
            ),
            if (actions != null) GhCardFooter(trailing: actions!, fill: true),
          ],
        ),
      ),
    );
  }
}
