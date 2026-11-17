import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/opener.dart';
import '../design/design.dart';
import '../motion/presence.dart' show ghFadeInFrameBuilder;
import '../projects/project_tile.dart' show formatProjectSize;
import '../src/rust/api/types.dart';
import '../state/asset_prefs.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/segmented.dart';
import '../ui/reusables/state_panel.dart';
import 'asset_card.dart';
import 'asset_common.dart';

/// Opens the detail dialog for [asset]. [primaryLabel] and [onPrimary] are
/// the caller's main action (install into a project, install as template);
/// the dialog closes before running it.
Future<void> showAssetDetails(
  BuildContext context,
  AssetLibraryAsset asset, {
  required String primaryLabel,
  VoidCallback? onPrimary,
  bool primaryDone = false,
}) => showGhModal<void>(
  context,
  (modal) => AssetDetailModal(
    asset: asset,
    primaryLabel: primaryLabel,
    primaryDone: primaryDone,
    onPrimary: onPrimary == null
        ? null
        : () {
            Navigator.of(modal).pop();
            onPrimary();
          },
    onClose: () => Navigator.of(modal).pop(),
  ),
);

/// Everything about one asset without leaving the app: screenshots,
/// description, version facts and links, which of your projects have it (with
/// updates), the archive's files before installing, and Store release notes.
class AssetDetailModal extends ConsumerStatefulWidget {
  const AssetDetailModal({
    super.key,
    required this.asset,
    required this.primaryLabel,
    required this.onClose,
    this.onPrimary,
    this.primaryDone = false,
    this.loadInfo,
    this.loadFiles,
  });

  final AssetLibraryAsset asset;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryDone;
  final VoidCallback onClose;

  /// Test seams; default to the Rust API.
  final Future<AssetInfo> Function(String assetId)? loadInfo;
  final Future<AssetFileListing> Function(String assetId)? loadFiles;

  @override
  ConsumerState<AssetDetailModal> createState() => _AssetDetailModalState();
}

class _AssetDetailModalState extends ConsumerState<AssetDetailModal> {
  late Future<AssetInfo> _info = _fetchInfo();
  String _tab = 'overview';
  int _mediaIndex = 0;
  AssetFileListing? _files;
  bool _loadingFiles = false;
  String? _filesError;
  final Set<String> _collapsed = {};
  final Set<String> _updating = {};

  AssetLibraryAsset get _asset => widget.asset;

  Future<AssetInfo> _fetchInfo() => (widget.loadInfo ?? AssetLibraryApi.info)(widget.asset.assetId);

  Future<void> _loadFiles() async {
    setState(() {
      _loadingFiles = true;
      _filesError = null;
    });
    try {
      final listing = await (widget.loadFiles ?? AssetLibraryApi.files)(_asset.assetId);
      if (!mounted) return;
      setState(() {
        _files = listing;
        _collapsed
          ..clear()
          ..addAll([
            for (final e in listing.entries)
              if (e.isDir && '/'.allMatches(e.path).isNotEmpty) e.path,
          ]);
      });
    } catch (e) {
      if (mounted) setState(() => _filesError = '$e');
    } finally {
      if (mounted) setState(() => _loadingFiles = false);
    }
  }

  Future<void> _update(AssetInstallation install, String version) async {
    final key = '${install.projectId}/${install.folder}';
    final installations = ref.read(assetInstallationsProvider.notifier);
    setState(() => _updating.add(key));
    try {
      if (_asset.source == 'store') {
        final (publisher, slug) = parseStoreId(_asset.assetId);
        await AssetLibraryApi.installStoreAsset(publisher, slug, _asset.title, install.projectId, null);
      } else {
        await AssetLibraryApi.updateAddon(install.projectId, install.folder, _asset.assetId);
      }
      await installations.refresh();
      ghToasts.pushToast(GhToastType.success, ghTr('asset_updated_toast', args: {'title': _asset.title, 'project': install.projectName}));
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, ghTr('asset_update_failed', args: {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _updating.remove(key));
    }
  }

  Future<void> _toggleFavorite(bool favorite) async {
    try {
      await ref.read(assetPrefsProvider.notifier).setFavorite(_asset, favorite);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _hide() async {
    final prefs = ref.read(assetPrefsProvider.notifier);
    widget.onClose();
    try {
      await prefs.setHidden(_asset.assetId, _asset.title, true);
      ghToasts.pushToast(GhToastType.info, ghTr('asset_hidden_toast', args: {'title': _asset.title}));
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  void _open(String url) => OpenerApi.openUrl(url).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final prefs = ref.watch(assetPrefsProvider).data;
    final favorite = prefs.isFavorite(_asset.assetId);
    final browse = _asset.browseUrl;
    return GhModalShell(
      icon: GhIcon(GhIcons.store, size: theme.space(5), color: theme.accentBright),
      title: _asset.title,
      maxWidth: GhModalWidth.x4l,
      // Fits the 680px minimum window and large font scales: the header,
      // footer and margins take about 300px.
      bodyHeight: math.max(theme.rem(12), math.min(theme.rem(34), MediaQuery.sizeOf(context).height - 300)),
      onClose: widget.onClose,
      footer: ghModalActions(
        leading: [
          GhButton(
            key: const ValueKey('asset-detail-favorite'),
            onPressed: () => _toggleFavorite(!favorite).ignore(),
            icon: GhIcons.star,
            label: favorite ? ghTr('asset_saved') : ghTr('asset_save'),
            variant: favorite ? GhButtonVariant.subtle : GhButtonVariant.ghost,
          ),
          GhButton(
            key: const ValueKey('asset-detail-hide'),
            onPressed: () => _hide().ignore(),
            icon: GhIcons.eyeSlash,
            label: ghTr('asset_not_interested'),
            variant: GhButtonVariant.ghost,
          ),
        ],
        trailing: [
          if (browse != null && browse.isNotEmpty)
            GhButton(
              onPressed: () => _open(browse),
              icon: GhIcons.externalLink,
              label: ghTr('asset_open_page'),
              variant: GhButtonVariant.ghost,
            ),
        ],
        primary: widget.onPrimary == null
            ? GhButton(onPressed: widget.onClose, label: ghTr('close'), variant: GhButtonVariant.primary)
            : GhButton(
                key: const ValueKey('asset-detail-primary'),
                onPressed: widget.primaryDone ? null : widget.onPrimary,
                label: widget.primaryLabel,
                icon: widget.primaryDone ? GhIcons.circleCheck : GhIcons.download,
                variant: GhButtonVariant.primary,
              ),
      ),
      child: FutureBuilder<AssetInfo>(
        future: _info,
        builder: (context, snapshot) {
          final info = snapshot.data;
          final body = Padding(
            padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
            child: switch (snapshot.connectionState) {
              _ when snapshot.hasError => GhStatePanel.error(
                compact: true,
                title: ghTr('asset_info_error'),
                message: '${snapshot.error}',
                onRetry: () => setState(() => _info = _fetchInfo()),
              ),
              _ when info == null => GhStatePanel.loading(compact: true, title: ghTr('loading')),
              _ => _content(theme, info),
            },
          );
          return SingleChildScrollView(child: body);
        },
      ),
    );
  }

  Widget _content(GhTheme theme, AssetInfo info) {
    final tabs = [
      ghSegment('overview', ghTr('asset_tab_overview')),
      ghSegment('files', ghTr('asset_tab_files')),
      if (info.releases.isNotEmpty) ghSegment('releases', ghTr('asset_tab_releases')),
    ];
    final tab = tabs.any((t) => t.value == _tab) ? _tab : 'overview';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [
        _header(theme, info),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GhSegmented(value: tab, options: tabs, onChanged: (v) => setState(() => _tab = v)),
        ),
        switch (tab) {
          'files' => _filesTab(theme, info),
          'releases' => _releasesTab(theme, info),
          _ => _overview(theme, info),
        },
      ],
    );
  }

  Widget _header(GhTheme theme, AssetInfo info) {
    final asset = info.asset;
    final rating = parseAssetRating(asset.rating);
    return Wrap(
      spacing: theme.space(1.5),
      runSpacing: theme.space(1.5),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          ghTr('asset_by_author', args: {'author': asset.author}),
          style: theme.text(size: GhTextSize.xs, color: theme.muted),
        ),
        if (info.version.isNotEmpty) GhBadge(label: info.version, mono: true, tone: GhTone.accent),
        if (asset.godotVersion.isNotEmpty) GhBadge(label: 'Godot ${asset.godotVersion}', mono: true),
        if (info.license.isNotEmpty) GhBadge(label: info.license, mono: true),
        if (asset.supportLevel.isNotEmpty) GhBadge(label: asset.supportLevel, tone: assetSupportTone(asset.supportLevel)),
        if (rating != null && rating > 0) GhBadge(label: formatAssetRating(rating), icon: GhIcons.star, tone: GhTone.amber),
        if (info.paid) GhBadge(label: ghTr('asset_paid'), tone: GhTone.amber),
      ],
    );
  }

  Widget _overview(GhTheme theme, AssetInfo info) {
    final installs = groupInstallations(ref.watch(assetInstallationsProvider).data)[_asset.assetId] ?? const [];
    final links = [
      if (info.sourceUrl != null) (ghTr('asset_link_source'), GhIcons.code, info.sourceUrl!),
      if (info.issuesUrl != null) (ghTr('asset_link_issues'), GhIcons.bug, info.issuesUrl!),
      if (info.licenseUrl != null) (ghTr('asset_fact_license'), GhIcons.book, info.licenseUrl!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [
        if (info.media.isNotEmpty) _gallery(theme, info.media),
        if (installs.isNotEmpty) _installs(theme, info, installs),
        SelectableText(
          info.description.isEmpty ? ghTr('asset_no_description') : info.description,
          style: theme.text(size: GhTextSize.sm, color: info.description.isEmpty ? theme.muted : theme.ink, lineHeight: 1.6),
        ),
        Wrap(
          spacing: theme.space(4),
          runSpacing: theme.space(2),
          children: [
            if (info.updated != null) _fact(theme, ghTr('asset_fact_updated'), info.updated!.split('T').first.split(' ').first),
            if (info.asset.category.isNotEmpty) _fact(theme, ghTr('asset_fact_category'), info.asset.category),
            if (info.downloadSizeBytes != null) _fact(theme, ghTr('asset_fact_size'), formatProjectSize(info.downloadSizeBytes!.toInt())),
          ],
        ),
        if (links.isNotEmpty)
          Wrap(
            spacing: theme.space(2),
            runSpacing: theme.space(2),
            children: [
              for (final (label, icon, url) in links)
                GhButton(onPressed: () => _open(url), icon: icon, label: label, variant: GhButtonVariant.outline, size: GhTextSize.xs),
            ],
          ),
      ],
    );
  }

  Widget _fact(GhTheme theme, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: theme.space(0.5),
    children: [
      Text(
        label,
        style: theme.text(size: GhTextSize.x2s, color: theme.muted),
      ),
      Text(
        value,
        style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium),
      ),
    ],
  );

  Widget _gallery(GhTheme theme, List<AssetMedia> media) {
    final index = _mediaIndex.clamp(0, media.length - 1);
    final current = media[index];
    final radius = BorderRadius.circular(theme.radiusItem);
    Widget image(String url, {BoxFit fit = BoxFit.contain}) => Image.network(
      url,
      fit: fit,
      frameBuilder: ghFadeInFrameBuilder,
      errorBuilder: (context, error, stack) => Center(
        child: GhIcon(GhIcons.store, size: theme.space(6), color: theme.muted),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: theme.rem(18),
            child: ColoredBox(
              color: theme.base,
              child: current.video
                  ? GhPressable(
                      onPressed: () => _open(current.url),
                      semanticLabel: ghTr('asset_media_video'),
                      builder: (context, states) => Stack(
                        fit: StackFit.expand,
                        children: [
                          if (current.thumbnail != null) image(current.thumbnail!, fit: BoxFit.cover),
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(theme.space(4)),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: states.active ? 0.7 : 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: GhIcon(GhIcons.play, size: theme.space(6), color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : image(current.url),
            ),
          ),
        ),
        if (media.length > 1)
          SizedBox(
            height: theme.space(14),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (context, _) => SizedBox(width: theme.space(2)),
              itemBuilder: (context, i) {
                final item = media[i];
                final thumb = item.thumbnail ?? (item.video ? null : item.url);
                return GhPressable(
                  key: ValueKey('asset-media-$i'),
                  onPressed: () => setState(() => _mediaIndex = i),
                  selected: i == index,
                  semanticLabel: item.video ? ghTr('asset_media_video') : ghTr('asset_media_image', args: {'index': i + 1}),
                  borderRadius: radius,
                  builder: (context, states) => AnimatedContainer(
                    duration: GhDurations.color,
                    width: theme.space(24),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.raised,
                      borderRadius: radius,
                      border: Border.all(
                        color: i == index ? theme.accent : theme.outline.withValues(alpha: 0.5),
                        width: i == index ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumb != null) image(thumb, fit: BoxFit.cover),
                        if (item.video)
                          Center(
                            child: GhIcon(GhIcons.play, size: theme.space(4), color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _installs(GhTheme theme, AssetInfo info, List<AssetInstallation> installs) {
    return Container(
      padding: EdgeInsets.all(theme.space(3)),
      decoration: BoxDecoration(
        color: theme.mint.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.mint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          Text(
            ghTr('asset_installed_in'),
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.mint),
          ),
          for (final install in installs)
            Row(
              key: ValueKey('asset-install-${install.projectId}-${install.folder}'),
              spacing: theme.space(2),
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: install.projectName,
                      children: [
                        TextSpan(
                          text: '  res://addons/${install.folder}${install.version.isEmpty ? '' : '  ${install.version}'}',
                          style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium),
                  ),
                ),
                if (info.version.isNotEmpty && install.version.isNotEmpty && install.version != info.version)
                  GhButton(
                    onPressed: _updating.contains('${install.projectId}/${install.folder}')
                        ? null
                        : () => _update(install, info.version).ignore(),
                    icon: GhIcons.arrowUp,
                    label: ghTr('asset_update_to', args: {'version': info.version}),
                    variant: GhButtonVariant.primary,
                    size: GhTextSize.xs,
                  )
                else
                  GhBadge(label: ghTr('asset_up_to_date'), tone: GhTone.mint, icon: GhIcons.check),
              ],
            ),
        ],
      ),
    );
  }

  Widget _filesTab(GhTheme theme, AssetInfo info) {
    if (info.paid) {
      return GhAlertBox(tone: GhAlertTone.amber, icon: GhIcons.lock, text: ghTr('asset_files_paid'));
    }
    if (_loadingFiles) return GhStatePanel.loading(compact: true, title: ghTr('asset_files_loading'));
    if (_filesError != null) {
      return GhStatePanel.error(
        compact: true,
        title: ghTr('asset_files_error'),
        message: _filesError,
        onRetry: () => _loadFiles().ignore(),
      );
    }
    final files = _files;
    if (files == null) {
      final size = info.downloadSizeBytes;
      return GhStatePanel.empty(
        compact: true,
        icon: GhIcons.folder,
        title: ghTr('asset_files_title'),
        message: size == null
            ? ghTr('asset_files_intro_unknown')
            : ghTr('asset_files_intro', args: {'size': formatProjectSize(size.toInt())}),
        actions: [
          GhButton(
            key: const ValueKey('asset-files-load'),
            onPressed: () => _loadFiles().ignore(),
            icon: GhIcons.download,
            label: ghTr('asset_files_load'),
            variant: GhButtonVariant.primary,
          ),
        ],
      );
    }
    final count = files.entries.where((e) => !e.isDir).length;
    final total = files.entries.fold<int>(0, (sum, e) => sum + e.size.toInt());
    final visible = [
      for (final e in files.entries)
        if (!_collapsed.any((c) => e.path.startsWith('$c/'))) e,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        Text(
          ghTr('asset_files_summary', args: {'files': count, 'size': formatProjectSize(total)}),
          style: theme.text(size: GhTextSize.xs, color: theme.muted),
        ),
        if (files.truncated)
          GhAlertBox(
            tone: GhAlertTone.amber,
            text: ghTr('asset_files_truncated', args: {'count': files.entries.length}),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.base,
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.space(1.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final e in visible) _fileRow(theme, e)]),
          ),
        ),
      ],
    );
  }

  Widget _fileRow(GhTheme theme, AssetFileEntry entry) {
    final depth = '/'.allMatches(entry.path).length;
    final name = entry.path.split('/').last;
    final collapsed = _collapsed.contains(entry.path);
    final row = Padding(
      padding: EdgeInsetsDirectional.only(
        start: theme.space(3 + depth * 4),
        end: theme.space(3),
        top: theme.space(0.75),
        bottom: theme.space(0.75),
      ),
      child: Row(
        spacing: theme.space(2),
        children: [
          if (entry.isDir)
            GhIcon(collapsed ? GhIcons.chevronRight : GhIcons.chevronDown, size: theme.space(2.5), color: theme.muted)
          else
            SizedBox(width: theme.space(2.5)),
          GhIcon(entry.isDir ? GhIcons.folder : GhIcons.code, size: theme.space(3), color: entry.isDir ? theme.accentBright : theme.muted),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.xs, mono: true),
            ),
          ),
          if (!entry.isDir)
            Text(
              formatProjectSize(entry.size.toInt()),
              style: theme.text(size: GhTextSize.x2s, color: theme.muted),
            ),
        ],
      ),
    );
    if (!entry.isDir) return row;
    return GhPressable(
      onPressed: () => setState(() => collapsed ? _collapsed.remove(entry.path) : _collapsed.add(entry.path)),
      expanded: !collapsed,
      semanticLabel: name,
      builder: (context, states) => ColoredBox(color: states.active ? theme.raised : Colors.transparent, child: row),
    );
  }

  Widget _releasesTab(GhTheme theme, AssetInfo info) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: theme.space(3),
    children: [
      for (final r in info.releases)
        Container(
          padding: EdgeInsets.all(theme.space(3)),
          decoration: BoxDecoration(
            color: theme.overlay,
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              Wrap(
                spacing: theme.space(1.5),
                runSpacing: theme.space(1.5),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    r.version,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, mono: true),
                  ),
                  GhBadge(
                    label: r.stable ? ghTr('asset_release_stable') : ghTr('asset_release_unstable'),
                    tone: r.stable ? GhTone.mint : GhTone.amber,
                  ),
                  if (r.minGodot != null) GhBadge(label: ghTr('asset_godot_range', args: {'min': r.minGodot!}), mono: true),
                  if (r.date.isNotEmpty)
                    Text(
                      r.date.split('T').first,
                      style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                    ),
                ],
              ),
              if (r.notes.isNotEmpty)
                SelectableText(
                  r.notes,
                  style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.6),
                ),
            ],
          ),
        ),
    ],
  );
}

/// The assets the user marked "Not interested", with a way to show each
/// one again. Hiding is never a dead end.
class HiddenAssetsModal extends ConsumerWidget {
  const HiddenAssetsModal({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final hidden = ref.watch(assetPrefsProvider).data.hidden;
    Future<void> restore(HiddenAsset asset) async {
      try {
        await ref.read(assetPrefsProvider.notifier).setHidden(asset.assetId, asset.title, false);
      } catch (e) {
        ghToasts.pushToast(GhToastType.error, '$e');
      }
    }

    return GhModalShell(
      icon: GhIcon(GhIcons.eyeSlash, size: theme.space(5), color: theme.muted),
      title: ghTr('asset_hidden_title'),
      maxWidth: GhModalWidth.xl,
      onClose: onClose,
      footer: ghModalActions(
        primary: GhButton(onPressed: onClose, label: ghTr('done'), variant: GhButtonVariant.primary),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: hidden.isEmpty
            ? GhStatePanel.empty(compact: true, icon: GhIcons.eye, title: ghTr('asset_hidden_empty'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2),
                children: [
                  Text(
                    ghTr('asset_hidden_desc'),
                    style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.5),
                  ),
                  for (final asset in hidden)
                    Row(
                      key: ValueKey('hidden-${asset.assetId}'),
                      spacing: theme.space(2),
                      children: [
                        Expanded(
                          child: Text(
                            asset.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.sm),
                          ),
                        ),
                        GhButton(
                          onPressed: () => restore(asset).ignore(),
                          icon: GhIcons.eye,
                          label: ghTr('asset_show_again'),
                          variant: GhButtonVariant.outline,
                          size: GhTextSize.xs,
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
