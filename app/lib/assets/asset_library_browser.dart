import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/opener.dart';
import '../design/design.dart';
import '../logic/asset_search_cache.dart';
import '../logic/asset_sort.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/shell_signals.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/confirm_dialog.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/modal_kit.dart';
import 'asset_card.dart';
import 'asset_common.dart';

const _maxEmptySkip = 15;
const _probeDepth = 5;
const _gatherLimit = assetPageSize * 3;
const _gatherEmptyRun = 5;

const assetLibrarySortKeys = [
  AssetSortKey.relevance,
  AssetSortKey.updatedNew,
  AssetSortKey.updatedOld,
  AssetSortKey.nameAz,
  AssetSortKey.nameZa,
  AssetSortKey.ratingHigh,
  AssetSortKey.ratingLow,
  AssetSortKey.licenseAz,
  AssetSortKey.licenseZa,
];

final Set<String> _installingAssets = {};

bool assetVersionMatches(String assetVersion, String target) {
  var trimmed = assetVersion.trim();
  if (trimmed.startsWith('v')) trimmed = trimmed.substring(1);
  final a = trimmed.split(RegExp(r'[.\-+]'));
  final t = target.trim().split('.');
  return a[0] == t[0] && (a.length > 1 ? a[1] : '') == (t.length > 1 ? t[1] : '');
}

class AssetLibraryBrowser extends ConsumerStatefulWidget {
  const AssetLibraryBrowser({super.key, required this.query, this.onStatsChange, this.installedTemplateNames = const []});

  final String query;
  final ValueChanged<({bool loading, int total})>? onStatsChange;
  final List<String> installedTemplateNames;

  @override
  ConsumerState<AssetLibraryBrowser> createState() => _AssetLibraryBrowserState();
}

class _AssetLibraryBrowserState extends ConsumerState<AssetLibraryBrowser> {
  List<AssetLibraryAsset> _assets = const [];
  bool _loading = true;
  String? _error;
  String _version = '';
  AssetSortKey _sort = AssetSortKey.relevance;
  int _page = 0;
  int _pages = 0;
  int _total = 0;
  String? _installing = _installingAssets.isEmpty ? null : _installingAssets.first;
  final Set<String> _installed = {};
  bool _paging = false;
  bool _canPrev = false;
  bool _canNext = false;
  Timer? _searchTimer;
  int _searchSeq = 0;
  ({bool loading, int total})? _reported;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(AssetLibraryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _error = null;
      _schedule();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () => _runSearch().ignore());
  }

  void _setVersion(String version) {
    setState(() {
      _version = version;
      _error = null;
    });
    _schedule();
  }

  void _setSort(AssetSortKey sort) {
    setState(() {
      _sort = sort;
      _error = null;
    });
    _schedule();
  }

  void _reportStats() {
    final stats = (loading: _loading, total: _total);
    if (stats == _reported) return;
    _reported = stats;
    final callback = widget.onStatsChange;
    if (callback != null) WidgetsBinding.instance.addPostFrameCallback((_) => callback(stats));
  }

  bool _isExactVersion(AssetLibraryAsset asset) => _version.isEmpty || assetVersionMatches(asset.godotVersion, _version);

  List<AssetLibraryAsset> _ranked(List<AssetLibraryAsset> list) =>
      _sort == AssetSortKey.relevance && widget.query.trim().isNotEmpty ? rankByRelevance(list, widget.query) : list;

  Future<AssetLibraryResponse?> _fetchPage(int nextPage, int seq) async {
    final query = widget.query.trim();
    final version = _version;
    final params = assetSortParams(_sort);
    try {
      return await cachedAssetSearch(
        'lib|$query|$version|$nextPage|${params.sort}|${params.reverse}',
        () => AssetLibraryApi.search(
          query.isEmpty ? null : query,
          version.isEmpty ? assetVersionOptions.first : version,
          nextPage,
          assetPageSize,
          null,
          null,
          params.sort,
          params.reverse,
        ),
      );
    } catch (e) {
      if (seq == _searchSeq && mounted) setState(() => _error = '$e');
      return null;
    }
  }

  Future<AssetLibraryResponse?> _load(int nextPage, int seq) async {
    final res = await _fetchPage(nextPage, seq);
    if (res == null || seq != _searchSeq || !mounted) return null;
    setState(() {
      _assets = _ranked(res.assets.where(_isExactVersion).toList());
      _pages = res.pages;
      _total = res.total;
      _page = res.page.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
      _error = null;
    });
    return res;
  }

  Future<void> _probeNeighbors(int cursor, int seq) async {
    if (_version.isEmpty) {
      if (!mounted) return;
      setState(() {
        _canPrev = cursor > 0;
        _canNext = cursor + 1 < _pages;
      });
      return;
    }
    var prev = false;
    var next = false;
    for (var i = 1; i <= _probeDepth && !(prev && next); i++) {
      if (!prev && cursor - i >= 0) {
        final r = await _fetchPage(cursor - i, seq);
        if (r != null && r.assets.any(_isExactVersion)) prev = true;
      }
      if (!next && cursor + i < _pages) {
        final r = await _fetchPage(cursor + i, seq);
        if (r != null && r.assets.any(_isExactVersion)) next = true;
      }
    }
    if (seq != _searchSeq || !mounted) return;
    setState(() {
      _canPrev = prev;
      _canNext = next;
    });
  }

  Future<void> _gatherAll(int startPage, int seq) async {
    var collected = <AssetLibraryAsset>[];
    var emptyRun = 0;
    var cursor = startPage;
    for (var i = 0; i <= _maxEmptySkip && collected.length < _gatherLimit; i++) {
      final res = await _fetchPage(cursor, seq);
      if (res == null) break;
      final matched = res.assets.where(_isExactVersion).toList();
      if (matched.isNotEmpty) {
        collected = [...collected, ...matched];
        emptyRun = 0;
      } else {
        emptyRun += 1;
        if (collected.isNotEmpty && emptyRun >= _gatherEmptyRun) break;
      }
      cursor += 1;
      if (cursor >= res.pages) break;
    }
    if (seq != _searchSeq || !mounted) return;
    setState(() {
      _assets = _ranked(collected);
      _total = collected.length;
      _pages = 1;
      _page = 0;
      _canPrev = false;
      _canNext = false;
    });
  }

  Future<void> _runSearch() async {
    final seq = ++_searchSeq;
    if (!mounted) return;
    setState(() => _loading = true);
    var cursor = 0;
    var landedPage = 0;
    AssetLibraryResponse? landedRes;
    for (var i = 0; i <= _maxEmptySkip; i++) {
      final res = await _load(cursor, seq);
      if (res != null) {
        landedPage = res.page.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
        landedRes = res;
      }
      if (res == null || res.assets.any(_isExactVersion)) break;
      cursor += 1;
    }
    if (seq != _searchSeq || !mounted) return;
    if (_version.isNotEmpty && landedRes != null) {
      final firstCount = landedRes.assets.where(_isExactVersion).length;
      if (firstCount > 0 && firstCount < assetPageSize) {
        await _gatherAll(landedPage, seq);
        if (seq == _searchSeq && mounted) setState(() => _loading = false);
        return;
      }
    }
    setState(() => _loading = false);
    await _probeNeighbors(landedPage, seq);
  }

  Future<void> _navigate(int target) async {
    if (_paging || _pages <= 1) return;
    final clamped = target.clamp(0, _pages - 1);
    final dir = clamped >= _page ? 1 : -1;
    setState(() => _paging = true);
    final seq = _searchSeq;
    var cursor = clamped;
    var landedPage = clamped;
    for (var i = 0; i <= _maxEmptySkip; i++) {
      final res = await _load(cursor, seq);
      if (res != null) landedPage = res.page.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
      if (res == null || res.assets.any(_isExactVersion)) break;
      cursor += dir;
      if (cursor < 0 || cursor >= _pages) break;
    }
    await _probeNeighbors(landedPage, seq);
    if (!mounted) return;
    setState(() => _paging = false);
    scrollAssetsToTop(context);
  }

  bool _isAlreadyInstalled(AssetLibraryAsset asset) =>
      widget.installedTemplateNames.any((name) => name.toLowerCase() == asset.title.toLowerCase());

  Future<void> _doInstall(AssetLibraryAsset asset) async {
    if (_installing != null || _installingAssets.contains(asset.assetId)) return;
    _installingAssets.add(asset.assetId);
    setState(() => _installing = asset.assetId);
    try {
      await AssetLibraryApi.installAsTemplate(asset.assetId);
      if (mounted) setState(() => _installed.add(asset.assetId));
      AppSignals.emit(refreshTemplatesSignal);
    } catch (_) {
    } finally {
      _installingAssets.remove(asset.assetId);
      if (mounted) setState(() => _installing = null);
    }
  }

  Future<void> _install(AssetLibraryAsset asset) async {
    if (_isAlreadyInstalled(asset)) {
      final confirmed = await showGhConfirmDialog(
        context,
        title: ghTr('asset_duplicate_title'),
        description: ghTr('asset_duplicate_desc', args: {'name': asset.title}),
        confirmLabel: ghTr('asset_install'),
      );
      if (!confirmed || !mounted) return;
    }
    await _doInstall(asset);
  }

  Widget _installButton(GhTheme theme, AssetLibraryAsset asset) {
    final isInstalled = _installed.contains(asset.assetId) || _isAlreadyInstalled(asset);
    final isInstalling = _installing == asset.assetId || _installingAssets.contains(asset.assetId);
    final radius = BorderRadius.circular(theme.radiusDropdownBtn);
    return GhPressable(
      onPressed: isInstalling ? null : () => _install(asset).ignore(),
      disabledOpacity: null,
      borderRadius: radius,
      rippleColor: Colors.white,
      builder: (context, states) {
        final hover = states.active && !isInstalling;
        final foreground = isInstalled ? theme.mint : theme.ink;
        final style = theme.text(weight: GhWeight.semibold, color: foreground).copyWith(fontSize: theme.rem(1.0625));
        return GhAnimatedBox(
          height: theme.space(12),
          padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
          alignment: Alignment.center,
          color: isInstalled ? theme.mint.withValues(alpha: 0.1) : (hover ? theme.accentBright : theme.accent),
          borderRadius: radius,
          border: Border.all(color: isInstalled ? theme.mint.withValues(alpha: 0.2) : theme.outline.withValues(alpha: 0.5)),
          boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.1)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: theme.space(1.5),
            children: [
              if (isInstalling) ...[
                GhSpinnerIcon(color: foreground),
                Text(ghTr('asset_installing'), style: style),
              ] else if (isInstalled) ...[
                GhIcon(GhIcons.check, size: theme.space(3.5), color: foreground),
                Text(ghTr('asset_installed'), style: style),
              ] else ...[
                GhIcon(GhIcons.download, size: theme.space(3.5), color: foreground),
                Text(ghTr('asset_install'), style: style),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _filters(GhTheme theme) => Row(
    children: [
      Expanded(
        child: Wrap(
          spacing: theme.space(2),
          runSpacing: theme.space(2),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GhDropdown(
              align: GhSide.left,
              items: [
                for (final key in assetLibrarySortKeys)
                  GhMenuItem(id: key.id, label: ghTr('asset_store_${key.id}'), active: _sort == key, onSelected: () => _setSort(key)),
              ],
              trigger: (context, open, toggle) => AssetDropButton(label: ghTr('asset_store_${_sort.id}'), open: open, onPressed: toggle),
            ),
            GhDropdown(
              align: GhSide.left,
              items: [
                GhMenuItem(id: 'all', label: ghTr('asset_all_versions'), active: _version.isEmpty, onSelected: () => _setVersion('')),
                for (final v in assetVersionOptions)
                  GhMenuItem(id: v, label: 'Godot $v', active: _version == v, onSelected: () => _setVersion(v)),
              ],
              trigger: (context, open, toggle) => AssetDropButton(
                label: _version.isNotEmpty ? 'Godot $_version' : ghTr('asset_all_versions'),
                open: open,
                onPressed: toggle,
              ),
            ),
          ],
        ),
      ),
      if (!_loading)
        Text(
          ghTr('asset_result_count', args: {'count': _total}),
          style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.6)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    _reportStats();
    final Widget body;
    if (_loading) {
      body = const AssetSkeletonGrid(storeActions: false);
    } else if (_error != null) {
      body = AssetStateBox(
        danger: true,
        icon: Container(
          width: theme.space(12),
          height: theme.space(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.radiusTile),
            border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
          ),
          child: GhIcon(GhIcons.x, size: theme.space(5), color: theme.danger),
        ),
        message: ghTr('asset_load_error'),
        onRetry: () => _runSearch().ignore(),
      );
    } else if (_assets.isEmpty) {
      body = AssetStateBox(
        icon: GhIcon(GhIcons.store, size: theme.space(6), color: theme.muted),
        message: ghTr('asset_no_results'),
      );
    } else {
      final Widget? pager;
      if (_version.isEmpty) {
        pager = _page > 0 || _page + 1 < _pages
            ? AssetPagination(page: _page, pages: _pages, paging: _paging, onNavigate: _navigate)
            : null;
      } else {
        pager = _canPrev || _canNext
            ? AssetPagination(
                page: _page,
                pages: _pages,
                paging: _paging,
                onNavigate: _navigate,
                numbered: false,
                canPrev: _canPrev,
                canNext: _canNext,
              )
            : null;
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          AssetGrid(
            children: [
              for (final asset in _assets)
                AssetCard(
                  key: ValueKey(asset.assetId),
                  asset: asset,
                  onOpenPage: asset.browseUrl != null && asset.browseUrl!.isNotEmpty
                      ? () => OpenerApi.openUrl(asset.browseUrl!).ignore()
                      : null,
                  actions: SizedBox(width: double.infinity, child: _installButton(theme, asset)),
                ),
            ],
          ),
          ?pager,
        ],
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(3), children: [_filters(theme), body]);
  }
}
