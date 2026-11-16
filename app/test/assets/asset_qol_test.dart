import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/assets/asset_detail_modal.dart';
import 'package:godothub/assets/asset_store_view.dart';
import 'package:godothub/logic/asset_search_cache.dart';
import 'package:godothub/modals/install_asset_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/asset_prefs.dart';
import 'package:godothub/state/godot_versions.dart';
import 'package:godothub/templates/templates_view.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';
import 'assets_test.dart' as assets;

late FakeRustApi rust;

const _noPrefs = AssetPrefs(schemaVersion: 1, favorites: [], hidden: []);

AssetInfo info(AssetLibraryAsset asset, {bool paid = false, List<AssetRelease> releases = const [], String version = '2.0'}) => AssetInfo(
  asset: asset,
  description: 'A camera helper.\nWorks in 2D and 3D.',
  version: version,
  license: 'MIT',
  sourceUrl: 'https://github.com/x/y',
  media: const [AssetMedia(url: 'https://img/1.png', video: false), AssetMedia(url: 'https://youtu.be/x', video: true)],
  releases: releases,
  downloadSizeBytes: BigInt.from(2 * 1024 * 1024),
  paid: paid,
);

AssetInstallation installation(String assetId, String projectId, String version) =>
    AssetInstallation(assetId: assetId, projectId: projectId, projectName: 'Demo', folder: 'cam', version: version);

class QolBackend extends assets.AssetBackend {
  AssetPrefs prefs = _noPrefs;
  List<AssetInstallation> installs = const [];
  List<TemplateUpdate> templateUpdates = const [];
  final favorites = <String, bool>{};
  final hiddenCalls = <String>[];
  int fileLoads = 0;

  @override
  void install(FakeRustApi rust) {
    super.install(rust);
    rust
      ..on('crateApiAssetLibraryGetAssetPrefs', () async => prefs)
      ..on('crateApiAssetLibrarySetAssetFavorite', ({required AssetLibraryAsset asset, required bool favorite}) async {
        favorites[asset.assetId] = favorite;
        prefs = AssetPrefs(
          schemaVersion: 1,
          favorites: [if (favorite) asset, ...prefs.favorites.where((a) => a.assetId != asset.assetId)],
          hidden: prefs.hidden,
        );
        return prefs;
      })
      ..on('crateApiAssetLibrarySetAssetHidden', ({required String assetId, required String title, required bool hidden}) async {
        hiddenCalls.add('$assetId:$hidden');
        prefs = AssetPrefs(
          schemaVersion: 1,
          favorites: prefs.favorites,
          hidden: [if (hidden) HiddenAsset(assetId: assetId, title: title), ...prefs.hidden.where((h) => h.assetId != assetId)],
        );
        return prefs;
      })
      ..on('crateApiAssetLibraryListAssetInstallations', () async => installs)
      ..on('crateApiAssetLibraryCheckTemplateUpdates', () async => templateUpdates)
      ..on('crateApiAssetLibraryUpdateTemplateFromAsset', ({required String templateId}) async {
        calls.add('update-template:$templateId');
        templateUpdates = const [];
        return assets.template(templateId, 'Platformer');
      })
      ..on('crateApiAddonsUpdateProjectAddon', ({required String id, required String folder, required String assetId}) async {
        calls.add('update-addon:$id:$folder:$assetId');
      })
      ..on('crateApiAssetLibraryListAssetFiles', ({required String assetId}) async {
        fileLoads++;
        return AssetFileListing(
          entries: [
            AssetFileEntry(path: 'addons', isDir: true, size: BigInt.zero),
            AssetFileEntry(path: 'addons/cam', isDir: true, size: BigInt.zero),
            AssetFileEntry(path: 'addons/cam/plugin.cfg', isDir: false, size: BigInt.from(120)),
            AssetFileEntry(path: 'README.md', isDir: false, size: BigInt.from(2048)),
          ],
          truncated: false,
          archiveBytes: BigInt.from(4096),
        );
      });
  }
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    clearAssetSearchCache();
    OpenerApi.debugOpenUrl = (url) async {};
  });
  tearDown(() => OpenerApi.debugOpenUrl = null);

  group('logic', () {
    InstalledGodotVersion v(String tag, String version) =>
        InstalledGodotVersion(tag: tag, version: version, executablePath: '', isMono: false, installedAt: '', supportsConsole: false);

    test('match my versions prefers the pinned version, else the newest install', () {
      expect(myAssetVersion(const GodotVersionsState()), isNull);
      final installed = [v('a', '4.2.1-stable'), v('b', '4.4-stable'), v('c', '3.6')];
      expect(myAssetVersion(GodotVersionsState(installed: installed)), '4.4');
      expect(
        myAssetVersion(
          GodotVersionsState(
            installed: installed,
            current: const CurrentVersionInfo(tag: 'a', aliasPath: '', aliasesDir: '', method: ''),
          ),
        ),
        '4.2',
      );
    });

    test('an update shows only when a project has a different version', () {
      final a = AssetLibraryAsset(
        assetId: '1',
        title: 't',
        author: '',
        category: '',
        godotVersion: '',
        cost: '',
        supportLevel: '',
        assetType: 'addon',
        rating: '0',
        source: 'library',
        version: '2.0',
      );
      expect(assetHasUpdate(a, [installation('1', 'p1', '2.0')]), isFalse);
      expect(assetHasUpdate(a, [installation('1', 'p1', '1.9')]), isTrue);
      expect(assetHasUpdate(a, const []), isFalse);
    });
  });

  group('asset store', () {
    testWidgets('hidden assets drop out of results and can be shown again', (tester) async {
      final backend = QolBackend()
        ..prefs = const AssetPrefs(
          schemaVersion: 1,
          favorites: [],
          hidden: [HiddenAsset(assetId: 'store:pub/two', title: 'Asset store:pub/two')],
        );
      backend.install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester, 10);
      expect(find.byKey(const ValueKey('store:pub/one')), findsOneWidget);
      expect(find.byKey(const ValueKey('store:pub/two')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('asset-hidden-manage')));
      await base.settle(tester);
      await tester.tap(find.text('Show again'));
      await base.settle(tester);
      expect(backend.hiddenCalls, ['store:pub/two:false']);
      await tester.tap(find.text('Done'));
      await base.settle(tester);
      expect(find.byKey(const ValueKey('store:pub/two')), findsOneWidget);
    });

    testWidgets('starring an asset saves it and the saved filter lists it', (tester) async {
      final backend = QolBackend()..install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester, 10);
      await tester.tap(find.byKey(const ValueKey('asset-favorite-store:pub/one')));
      await base.settle(tester);
      expect(backend.favorites, {'store:pub/one': true});

      await tester.tap(find.byKey(const ValueKey('asset-filter-saved')));
      await base.settle(tester);
      expect(find.byKey(const ValueKey('store:pub/one')), findsOneWidget);
      expect(find.byKey(const ValueKey('store:pub/two')), findsNothing);
    });

    testWidgets('cards show where an asset is installed', (tester) async {
      final backend = QolBackend()..installs = [installation('store:pub/one', 'p1', '1.0')];
      backend.install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester, 10);
      expect(find.text('In 1 project'), findsOneWidget);
    });
  });

  group('detail modal', () {
    final a = assets.asset('7', title: 'Phantom Camera');

    Future<void> open(WidgetTester tester, {AssetInfo? details, VoidCallback? onPrimary}) => base.openModal(
      tester,
      (close) => AssetDetailModal(
        asset: a,
        primaryLabel: 'Install',
        onPrimary: onPrimary,
        onClose: close,
        loadInfo: (_) async => details ?? info(a),
      ),
    );

    testWidgets('shows media, description and the files only on request', (tester) async {
      final backend = QolBackend()..install(rust);
      await open(tester);
      expect(find.text('A camera helper.\nWorks in 2D and 3D.'), findsOneWidget);
      expect(find.bySemanticsLabel('Play video'), findsWidgets);
      await tester.tap(find.text('Files'));
      await base.settle(tester);
      expect(backend.fileLoads, 0, reason: 'nothing downloads until asked');
      expect(find.textContaining('2.0 MB'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('asset-files-load')));
      await base.settle(tester);
      expect(backend.fileLoads, 1);
      expect(find.text('README.md'), findsOneWidget);
      expect(find.text('addons'), findsOneWidget);
      expect(find.text('plugin.cfg'), findsNothing, reason: 'nested folders start collapsed');
      await tester.tap(find.text('cam'));
      await base.settle(tester);
      expect(find.text('plugin.cfg'), findsOneWidget);
    });

    testWidgets('fits the minimum 1180x680 window without overflow', (tester) async {
      QolBackend().install(rust);
      await base.openModal(
        tester,
        (close) => AssetDetailModal(asset: a, primaryLabel: 'Install', onPrimary: () {}, onClose: close, loadInfo: (_) async => info(a)),
        size: const Size(1180, 680),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('asset-detail-primary')), findsOneWidget);
      expect(tester.getBottomLeft(find.byKey(const ValueKey('asset-detail-primary'))).dy, lessThanOrEqualTo(680));
    });

    testWidgets('paid assets explain why files cannot be previewed', (tester) async {
      QolBackend().install(rust);
      await open(tester, details: info(a, paid: true));
      await tester.tap(find.text('Files'));
      await base.settle(tester);
      expect(find.byKey(const ValueKey('asset-files-load')), findsNothing);
      expect(find.textContaining('paid assets'), findsOneWidget);
    });

    testWidgets('installed projects offer an update to the latest version', (tester) async {
      final backend = QolBackend()..installs = [installation('7', 'p1', '1.0')];
      backend.install(rust);
      await open(tester);
      await tester.ensureVisible(find.text('Update to 2.0'));
      await tester.tap(find.text('Update to 2.0'));
      await base.settle(tester);
      expect(backend.calls, contains('update-addon:p1:cam:7'));
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('not interested hides the asset', (tester) async {
      final backend = QolBackend()..install(rust);
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('asset-detail-hide')));
      await base.settle(tester);
      expect(backend.hiddenCalls, ['7:true']);
      await tester.pump(const Duration(seconds: 7));
    });
  });

  testWidgets('installs into several projects at once', (tester) async {
    final backend = QolBackend()..install(rust);
    final second = Project(
      id: 'p2',
      name: 'Second',
      path: 'C:/games/second',
      godotVersion: '4.3',
      createdAt: '',
      pinned: false,
      sortOrder: 1,
      launchArguments: '',
      tags: const [],
      totalTimeSeconds: BigInt.zero,
      timeTodaySeconds: BigInt.zero,
      timeWeekSeconds: BigInt.zero,
      missing: false,
    );
    rust.on('crateApiProjectsListProjects', () async => [base.demo, second]);
    final outcomes = <String>[];
    await base.openModal(
      tester,
      (close) => InstallAssetModal(asset: assets.asset('5'), onClose: close, onInstalled: (o) => outcomes.add(o.targetName)),
    );
    await tester.tap(find.byKey(const ValueKey('asset-install-select-all')));
    await base.settle(tester);
    expect(find.text('Install into 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('asset-install-submit')));
    await base.settle(tester);
    expect(backend.calls.where((c) => c.startsWith('install:5:')), ['install:5:p1:null', 'install:5:p2:null']);
    expect(outcomes, ['Demo', 'Second']);
  });

  testWidgets('a library template with a newer upload can be updated in place', (tester) async {
    final backend = QolBackend()
      ..templateUpdates = const [TemplateUpdate(templateId: 't1', assetId: '12', installedVersion: '1.0', latestVersion: '1.1')];
    backend.install(rust);
    rust.on(
      'crateApiTemplatesListTemplates',
      () async => [
        ProjectTemplate(
          id: 't1',
          name: 'Platformer',
          description: '',
          godotVersion: '4.3',
          createdAt: '',
          path: 'C:/t/t1',
          keepName: true,
          sourceAssetId: '12',
          sourceAssetVersion: '1.0',
        ),
      ],
    );
    await base.pumpHost(tester, body: const TemplatesView());
    await base.settle(tester, 10);
    expect(find.text('Update: 1.1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('template-update-t1')));
    await base.settle(tester, 4);
    expect(backend.calls, isNot(contains('update-template:t1')), reason: 'replacing files asks first');
    await tester.tap(find.text('Update').last);
    await base.settle(tester, 10);
    expect(backend.calls, contains('update-template:t1'));
    await tester.pump(const Duration(seconds: 7));
  });
}
