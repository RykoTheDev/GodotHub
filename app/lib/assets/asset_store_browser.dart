import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/opener.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/asset_search_cache.dart';
import '../logic/asset_sort.dart';
import '../modals/install_asset_modal.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/asset_prefs.dart';
import '../state/projects.dart';
import '../state/shell_signals.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/core/button.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/card_grid.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/open_button.dart';
import '../ui/reusables/state_panel.dart';
import 'asset_card.dart';
import 'asset_common.dart';
import 'asset_detail_modal.dart';

void _reportError(Object error) => ghToasts.pushToast(GhToastType.error, '$error');

class AssetStoreBrowser extends ConsumerStatefulWidget {
  const AssetStoreBrowser({
    super.key,
    required this.query,
    required this.source,
    required this.categoryId,
    required this.version,
    required this.sort,
    this.onStatsChange,
    this.onClearFilters,
    this.savedOnly = false,
  });

  /// Shows the user's saved (favorite) assets instead of search results.
  final bool savedOnly;

  final String query;
  final AssetSource source;
  final String categoryId;
  final String version;
  final AssetSortKey sort;
  final ValueChanged<({bool loading, int total})>? onStatsChange;

  /// Resets the search and filters; offered when nothing matches. Null when
  /// no search or filter is active.
  final VoidCallback? onClearFilters;

  @override
  ConsumerState<AssetStoreBrowser> createState() => _AssetStoreBrowserState();
}

class _AssetStoreBrowserState extends ConsumerState<AssetStoreBrowser> {
  List<AssetLibraryAsset> _assets = const [];
  bool _loading = true;
  bool _paging = false;
  String? _error;

  /// A page change that failed while the current results stay visible.
  int? _failedPage;
  int _page = 0;
  int _pages = 0;
  int _total = 0;
  String? _busyId;
  final Set<String> _installed = {};
  final Set<String> _downloaded = {};
  String? _notice;
  Timer? _searchTimer;
  Timer? _noticeTimer;
  int _requestSeq = 0;

  /// Page size matched to the column count, set from the first layout.
  int _pageSize = assetPageSize;
  bool _sized = false;

  /// Requests pages that fill whole rows. Measured from the grid's width
  /// before the first search, and again when a resize changes the columns.
  Widget _sizedTo(BoxConstraints constraints, Widget child) {
    final theme = GhTheme.of(context);
    final size = assetPageSizeFor(GhGridBreakpoints.cards.columnsFor(constraints.maxWidth, fontScale: theme.fontScale));
    if (!_sized || size != _pageSize) {
      final first = !_sized;
      _sized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!first && size == _pageSize) return;
        _pageSize = size;
        _reloadForPageSize();
      });
    }
    return child;
  }

  void _reloadForPageSize() {
    _page = 0;
    _schedule();
  }

  ({bool loading, int total})? _reported;

  @override
  void initState() {
    super.initState();
    // The first search waits for the first layout, which sets the page size.
  }

  @override
  void didUpdateWidget(AssetStoreBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.source != widget.source ||
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.version != widget.version ||
        oldWidget.sort != widget.sort ||
        oldWidget.savedOnly != widget.savedOnly) {
      _error = null;
      _failedPage = null;
      _schedule();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      final seq = await _load(0);
      if (mounted && _requestSeq == seq) setState(() => _loading = false);
    });
  }

  void _reportStats() {
    final stats = (loading: _loading, total: _total);
    if (stats == _reported) return;
    _reported = stats;
    final callback = widget.onStatsChange;
    if (callback != null) WidgetsBinding.instance.addPostFrameCallback((_) => callback(stats));
  }

  void _showNotice(String message) {
    setState(() => _notice = message);
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  Future<int> _load(int nextPage, {bool keepResults = false}) async {
    final seq = ++_requestSeq;
    final query = widget.query.trim();
    final version = widget.version;
    try {
      final params = assetSortParams(widget.sort);
      final storeSort = storeServerSort(widget.sort);
      final res = widget.source == AssetSource.library
          ? await cachedAssetSearch(
              'lib|$query|$version|$nextPage|$_pageSize|${widget.categoryId}|${params.sort}|${params.reverse}',
              () => AssetLibraryApi.search(
                query.isEmpty ? null : query,
                version.isEmpty ? assetVersionOptions.first : version,
                nextPage,
                _pageSize,
                'addon',
                widget.categoryId.isEmpty ? null : widget.categoryId,
                params.sort,
                params.reverse,
              ),
            )
          : await cachedAssetSearch(
              'store|$query|$version|$nextPage|$_pageSize|$storeSort',
              () => AssetLibraryApi.searchStore(
                query.isEmpty ? null : query,
                version.isEmpty ? null : version,
                nextPage,
                _pageSize,
                storeSort,
              ),
            );
      if (_requestSeq != seq || !mounted) return seq;
      setState(() {
        _assets = res.assets;
        _pages = res.pages;
        _total = res.total;
        _page = nextPage.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
        _error = null;
        _failedPage = null;
      });
    } catch (e) {
      if (_requestSeq != seq || !mounted) return seq;
      setState(() {
        if (keepResults && _assets.isNotEmpty) {
          _failedPage = nextPage;
        } else {
          _error = '$e';
        }
      });
    }
    return seq;
  }

  Future<void> _navigate(int target) async {
    if (_paging) return;
    final clamped = target.clamp(0, _pages - 1 < 0 ? 0 : _pages - 1);
    setState(() => _paging = true);
    await _load(clamped, keepResults: true);
    if (!mounted) return;
    setState(() => _paging = false);
    scrollAssetsToTop(context);
  }

  void _handleInstalled(AssetInstallOutcome outcome) {
    if (!mounted) return;
    setState(() => _installed.add(outcome.assetId));
    ref.read(assetInstallationsProvider.notifier).refresh().ignore();
    if (outcome.targetType == AssetInstallTarget.project) {
      ref.read(projectsProvider.notifier).refresh().ignore();
    } else {
      AppSignals.emit(refreshTemplatesSignal);
    }
    _showNotice(
      outcome.targetType == AssetInstallTarget.project
          ? ghTr('asset_install_success_project', args: {'target': outcome.targetName})
          : ghTr('asset_install_success_template', args: {'target': outcome.targetName}),
    );
  }

  Future<void> _download(AssetLibraryAsset asset) async {
    if (_busyId != null) return;
    setState(() => _busyId = asset.assetId);
    try {
      final String path;
      if (asset.source == 'store') {
        final (publisher, slug) = parseStoreId(asset.assetId);
        path = await AssetLibraryApi.downloadStoreAsset(publisher, slug, asset.title);
      } else {
        path = await AssetLibraryApi.download(asset.assetId);
      }
      if (!mounted) return;
      setState(() => _downloaded.add(asset.assetId));
      ProjectsApi.openFolder(assetDirname(path)).catchError(_reportError);
      _showNotice('${ghTr('asset_downloaded_to')} ${assetDirname(path)}');
    } catch (_) {
      if (mounted) _showNotice(ghTr('asset_download_error'));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _openInstall(AssetLibraryAsset asset) {
    showGhModal<void>(
      context,
      (modal) => InstallAssetModal(asset: asset, onClose: () => Navigator.of(modal).pop(), onInstalled: _handleInstalled),
    ).ignore();
  }

  Future<void> _setFavorite(AssetLibraryAsset asset, bool favorite) async {
    try {
      await ref.read(assetPrefsProvider.notifier).setFavorite(asset, favorite);
    } catch (e) {
      _reportError(e);
    }
  }

  Future<void> _hide(AssetLibraryAsset asset) async {
    try {
      await ref.read(assetPrefsProvider.notifier).setHidden(asset.assetId, asset.title, true);
      ghToasts.pushToast(GhToastType.info, ghTr('asset_hidden_toast', args: {'title': asset.title}));
    } catch (e) {
      _reportError(e);
    }
  }

  Widget _card(AssetLibraryAsset asset, {required AssetPrefs prefs, required Map<String, List<AssetInstallation>> installs}) {
    final isInstalled = _installed.contains(asset.assetId);
    final favorite = prefs.isFavorite(asset.assetId);
    final installedIn = installs[asset.assetId] ?? const <AssetInstallation>[];
    final isDownloaded = _downloaded.contains(asset.assetId);
    final isBusy = _busyId == asset.assetId;
    final browse = asset.browseUrl;
    return AssetCard(
      key: ValueKey(asset.assetId),
      asset: asset,
      favorite: favorite,
      onToggleFavorite: () => _setFavorite(asset, !favorite).ignore(),
      installedIn: [for (final i in installedIn) i.projectName],
      updateAvailable: assetHasUpdate(asset, installedIn),
      onOpenDetails: () => showAssetDetails(
        context,
        asset,
        primaryLabel: isInstalled ? ghTr('asset_installed') : ghTr('asset_install_inside'),
        primaryDone: isInstalled,
        onPrimary: () => _openInstall(asset),
      ).ignore(),
      onOpenPage: browse != null && browse.isNotEmpty ? () => OpenerApi.openUrl(browse).catchError(_reportError) : null,
      actions: [
        GhOpenButton(
          label: isInstalled ? ghTr('asset_installed') : ghTr('asset_install_inside'),
          disabled: isInstalled || isBusy,
          showConsole: false,
          onOpen: (_) => _openInstall(asset),
          moreLabel: ghTr('project_more_aria'),
          size: GhOpenButtonSize.compact,
          items: [
            GhMenuItem(
              id: 'details',
              label: ghTr('asset_view_details'),
              icon: GhIcons.info,
              onSelected: () => showAssetDetails(
                context,
                asset,
                primaryLabel: isInstalled ? ghTr('asset_installed') : ghTr('asset_install_inside'),
                primaryDone: isInstalled,
                onPrimary: () => _openInstall(asset),
              ).ignore(),
            ),
            GhMenuItem(
              id: 'download',
              label: isDownloaded ? ghTr('asset_downloaded') : ghTr('asset_download_outside'),
              icon: isDownloaded ? GhIcons.circleCheck : GhIcons.cloudArrowDown,
              disabled: isBusy,
              onSelected: () => _download(asset).ignore(),
              dividerAfter: true,
            ),
            GhMenuItem(id: 'hide', label: ghTr('asset_not_interested'), icon: GhIcons.eyeSlash, onSelected: () => _hide(asset).ignore()),
          ],
        ),
      ],
    );
  }

  void _retry() {
    setState(() => _loading = true);
    _load(0).then((seq) {
      if (mounted && _requestSeq == seq) setState(() => _loading = false);
    }).ignore();
  }

  Widget _saved(GhTheme theme, AssetPrefs prefs, Map<String, List<AssetInstallation>> installs) {
    final query = widget.query.trim().toLowerCase();
    final source = widget.source == AssetSource.library ? 'library' : 'store';
    final saved = [
      for (final a in prefs.favorites)
        if (a.source == source && (query.isEmpty || a.title.toLowerCase().contains(query) || a.author.toLowerCase().contains(query))) a,
    ];
    if (saved.isEmpty) {
      return GhStatePanel.empty(
        icon: GhIcons.star,
        title: ghTr('asset_saved_empty_title'),
        message: query.isEmpty ? ghTr('asset_saved_empty_desc') : ghTr('asset_no_results_filtered'),
      );
    }
    return GhCardGrid(
      gap: 4,
      children: [for (final asset in saved) _card(asset, prefs: prefs, installs: installs)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final prefs = ref.watch(assetPrefsProvider).data;
    final installs = groupInstallations(ref.watch(assetInstallationsProvider).data);
    final hidden = prefs.hiddenIds;
    final visible = [
      for (final a in _assets)
        if (!hidden.contains(a.assetId)) a,
    ];
    _reportStats();
    final Widget body;
    if (widget.savedOnly) {
      body = _saved(theme, prefs, installs);
    } else if (_loading) {
      body = GhCardGrid.fill(rows: 2, builder: (context, _) => const GhCardSkeleton(mediaHeight: 40, showcase: true));
    } else if (_error != null) {
      final site = widget.source == AssetSource.library ? assetLibrarySiteUrl : assetStoreSiteUrl;
      body = GhStatePanel.error(
        title: ghTr('asset_load_error_title'),
        message: ghTr('asset_load_error'),
        onRetry: _retry,
        actions: [
          GhButton(
            onPressed: () => OpenerApi.openUrl(site).catchError(_reportError),
            label: ghTr('asset_open_page'),
            icon: GhIcons.externalLink,
            variant: GhButtonVariant.ghost,
          ),
        ],
      );
    } else if (_assets.isEmpty) {
      final clear = widget.onClearFilters;
      body = GhStatePanel.empty(
        icon: GhIcons.store,
        title: ghTr('asset_no_results_title'),
        message: clear != null ? ghTr('asset_no_results_filtered') : null,
        actions: [
          if (clear != null) GhButton(onPressed: clear, label: ghTr('clear_filters'), icon: GhIcons.x, variant: GhButtonVariant.outline),
        ],
      );
    } else {
      final failed = _failedPage;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          if (failed != null)
            GhCardNotice(
              tone: GhTone.danger,
              message: ghTr('asset_partial_error'),
              action: GhButton(onPressed: () => _navigate(failed).ignore(), label: ghTr('retry'), size: GhTextSize.xs, paddingY: 1.5),
            ),
          if (visible.isEmpty)
            GhCardNotice(message: ghTr('asset_page_all_hidden'))
          else
            GhCardGrid(
              gap: 4,
              children: [for (final asset in visible) _card(asset, prefs: prefs, installs: installs)],
            ),
          if (_page > 0 || _page + 1 < _pages) AssetPagination(page: _page, pages: _pages, paging: _paging, onNavigate: _navigate),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _sizedTo(
        constraints,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
            if (_notice != null) GhCardNotice(message: _notice!),
            body,
          ],
        ),
      ),
    );
  }
}
