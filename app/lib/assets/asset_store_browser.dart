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
import '../state/projects.dart';
import '../state/shell_signals.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/open_button.dart';
import 'asset_card.dart';
import 'asset_common.dart';

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
  });

  final String query;
  final AssetSource source;
  final String categoryId;
  final String version;
  final AssetSortKey sort;
  final ValueChanged<({bool loading, int total})>? onStatsChange;

  @override
  ConsumerState<AssetStoreBrowser> createState() => _AssetStoreBrowserState();
}

class _AssetStoreBrowserState extends ConsumerState<AssetStoreBrowser> {
  List<AssetLibraryAsset> _assets = const [];
  bool _loading = true;
  bool _paging = false;
  String? _error;
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
  ({bool loading, int total})? _reported;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(AssetStoreBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.source != widget.source ||
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.version != widget.version ||
        oldWidget.sort != widget.sort) {
      _error = null;
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

  Future<int> _load(int nextPage) async {
    final seq = ++_requestSeq;
    final query = widget.query.trim();
    final version = widget.version;
    try {
      final params = assetSortParams(widget.sort);
      final storeSort = storeServerSort(widget.sort);
      final res = widget.source == AssetSource.library
          ? await cachedAssetSearch(
              'lib|$query|$version|$nextPage|${widget.categoryId}|${params.sort}|${params.reverse}',
              () => AssetLibraryApi.search(
                query.isEmpty ? null : query,
                version.isEmpty ? assetVersionOptions.first : version,
                nextPage,
                assetPageSize,
                'addon',
                widget.categoryId.isEmpty ? null : widget.categoryId,
                params.sort,
                params.reverse,
              ),
            )
          : await cachedAssetSearch(
              'store|$query|$version|$nextPage|$storeSort',
              () => AssetLibraryApi.searchStore(
                query.isEmpty ? null : query,
                version.isEmpty ? null : version,
                nextPage,
                assetPageSize,
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
      });
    } catch (e) {
      if (_requestSeq != seq || !mounted) return seq;
      setState(() => _error = '$e');
    }
    return seq;
  }

  Future<void> _navigate(int target) async {
    if (_paging) return;
    final clamped = target.clamp(0, _pages - 1 < 0 ? 0 : _pages - 1);
    setState(() => _paging = true);
    await _load(clamped);
    if (!mounted) return;
    setState(() => _paging = false);
    scrollAssetsToTop(context);
  }

  void _handleInstalled(AssetInstallOutcome outcome) {
    if (!mounted) return;
    setState(() => _installed.add(outcome.assetId));
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

  Widget _card(AssetLibraryAsset asset) {
    final isInstalled = _installed.contains(asset.assetId);
    final isDownloaded = _downloaded.contains(asset.assetId);
    final isBusy = _busyId == asset.assetId;
    final browse = asset.browseUrl;
    return AssetCard(
      key: ValueKey(asset.assetId),
      asset: asset,
      onOpenPage: browse != null && browse.isNotEmpty ? () => OpenerApi.openUrl(browse).catchError(_reportError) : null,
      actions: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: GhOpenButton(
          label: isInstalled ? ghTr('asset_installed') : ghTr('asset_install_inside'),
          disabled: isInstalled || isBusy,
          showConsole: false,
          onOpen: (_) => _openInstall(asset),
          moreLabel: ghTr('project_more_aria'),
          paddingX: 8,
          items: [
            GhMenuItem(
              id: 'download',
              label: isDownloaded ? ghTr('asset_downloaded') : ghTr('asset_download_outside'),
              icon: isDownloaded ? GhIcons.circleCheck : GhIcons.cloudArrowDown,
              disabled: isBusy,
              onSelected: () => _download(asset).ignore(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    _reportStats();
    final Widget body;
    if (_loading) {
      body = const AssetSkeletonGrid(storeActions: true);
    } else if (_error != null) {
      body = AssetStateBox(
        danger: true,
        icon: GhIcon(GhIcons.store, size: theme.space(6), color: theme.muted),
        message: ghTr('asset_load_error'),
        onRetry: () => _load(0).ignore(),
      );
    } else if (_assets.isEmpty) {
      body = AssetStateBox(
        icon: GhIcon(GhIcons.store, size: theme.space(6), color: theme.muted),
        message: ghTr('asset_no_results'),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          AssetGrid(children: [for (final asset in _assets) _card(asset)]),
          if (_page > 0 || _page + 1 < _pages) AssetPagination(page: _page, pages: _pages, paging: _paging, onNavigate: _navigate),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        if (_notice != null) AssetNotice(message: _notice!),
        body,
      ],
    );
  }
}
