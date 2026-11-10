import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/features.dart';

import '../ui/i18n_setup.dart';
import 'logic_fixtures.dart';

void main() {
  test('feature ids, order and flags match features.ts', () {
    expect([for (final f in GhFeatureId.values) f.id], [
      'asset-store',
      'templates',
      'categories',
      'dashboard',
      'vault',
      'storage',
      'workspaces',
      'news',
    ]);
    expect([for (final f in GhFeatureId.values) if (f.flag != null) f], [GhFeatureId.categories, GhFeatureId.workspaces]);
    expect([for (final f in GhCoreFeature.values) f.id], ['projects', 'versions']);
    expect(GhFeatureId.fromId('vault'), GhFeatureId.vault);
    expect(GhFeatureId.fromId('projects'), isNull);
  });

  test('setup profiles', () {
    expect(GhSetupProfile.minimal.features, isEmpty);
    expect(GhSetupProfile.essentials.features, [GhFeatureId.assetStore, GhFeatureId.templates, GhFeatureId.categories]);
    expect(GhSetupProfile.studio.features, [
      GhFeatureId.assetStore,
      GhFeatureId.templates,
      GhFeatureId.categories,
      GhFeatureId.dashboard,
      GhFeatureId.vault,
      GhFeatureId.storage,
      GhFeatureId.workspaces,
    ]);
    expect(GhSetupProfile.complete.features, GhFeatureId.values);
  });

  test('isFeatureEnabled uses flags, the disabled list, and allows unknown ids', () {
    final settings = withFeatures(baseSettings, {GhFeatureId.categories, GhFeatureId.news});
    expect(isFeatureEnabled(settings, 'categories'), isTrue);
    expect(isFeatureEnabled(settings, 'workspaces'), isFalse);
    expect(isFeatureEnabled(settings, 'news'), isTrue);
    expect(isFeatureEnabled(settings, 'vault'), isFalse);
    expect(isFeatureEnabled(settings, 'projects'), isTrue);
    expect(isFeatureEnabled(settings, 'anything-else'), isTrue);
  });

  test('withFeatures writes disabled_features in FEATURES order and both flags', () {
    final settings = withFeatures(baseSettings, [GhFeatureId.workspaces, GhFeatureId.vault, GhFeatureId.vault]);
    expect(settings.disabledFeatures, ['asset-store', 'templates', 'dashboard', 'storage', 'news']);
    expect(settings.categoriesEnabled, isFalse);
    expect(settings.workspacesEnabled, isTrue);
    expect(settings.language, baseSettings.language);
    expect(settings.cardViewOverrides, baseSettings.cardViewOverrides);
  });

  test('enabledFeatures round-trips withFeatures in FEATURES order', () {
    for (final profile in GhSetupProfile.values) {
      final enabled = enabledFeatures(withFeatures(baseSettings, profile.features));
      expect(enabled, profile.features.toSet());
      expect(enabled.toList(), [for (final f in GhFeatureId.values) if (profile.features.contains(f)) f]);
      expect(matchSetupProfile(enabled), profile);
    }
  });

  test('matchSetupProfile', () {
    expect(matchSetupProfile({}), GhSetupProfile.minimal);
    expect(matchSetupProfile(GhFeatureId.values.toSet()), GhSetupProfile.complete);
    expect(matchSetupProfile({GhFeatureId.news}), isNull);
    expect(matchSetupProfile({GhFeatureId.categories, GhFeatureId.templates, GhFeatureId.assetStore}), GhSetupProfile.essentials);
  });

  test('labels resolve through translations', () async {
    final i18n = await setUpTestI18n();
    expect(i18n.language, 'en-US');
    for (final feature in GhFeatureId.values) {
      expect(feature.label(), isNotEmpty);
      expect(feature.description(), isNotEmpty);
    }
    for (final profile in GhSetupProfile.values) {
      expect(profile.label(), isNotEmpty);
    }
  });
}
