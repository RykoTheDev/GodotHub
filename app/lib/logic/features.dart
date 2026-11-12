import '../design/design.dart';
import '../i18n/i18n.dart';
import '../src/rust/api/types.dart';
import 'settings_copy.dart';

enum GhCoreFeature {
  projects('projects', GhIcons.folder),
  versions('versions', GhIcons.cloudArrowDown);

  const GhCoreFeature(this.id, this.icon);

  final String id;
  final FaIconData icon;

  String label([Translations? translations]) {
    final tr = translations ?? t;
    return switch (this) {
      projects => tr.nav.projects,
      versions => tr.nav.versions,
    };
  }

  String description([Translations? translations]) {
    final tr = translations ?? t;
    return switch (this) {
      projects => tr.common.onboarding_keep_organized,
      versions => tr.common.onboarding_download_manage,
    };
  }
}

enum GhFeatureFlag { categoriesEnabled, workspacesEnabled }

enum GhFeatureId {
  assetStore('asset-store', GhIcons.store),
  templates('templates', GhIcons.rocket),
  categories('categories', GhIcons.tags, GhFeatureFlag.categoriesEnabled),
  dashboard('dashboard', GhIcons.house),
  vault('vault', GhIcons.briefcase),
  storage('storage', GhIcons.hardDrive),
  workspaces('workspaces', GhIcons.layoutGrid, GhFeatureFlag.workspacesEnabled),
  news('news', GhIcons.news);

  const GhFeatureId(this.id, this.icon, [this.flag]);

  final String id;
  final FaIconData icon;
  final GhFeatureFlag? flag;

  String label([Translations? translations]) {
    final tr = translations ?? t;
    return switch (this) {
      assetStore => tr.nav.asset_store,
      templates => tr.nav.templates,
      categories => tr.common.categories,
      dashboard => tr.nav.dashboard,
      vault => tr.nav.vault,
      storage => tr.nav.storage_view,
      workspaces => tr.common.section_workspaces,
      news => tr.nav.news,
    };
  }

  String description([Translations? translations]) {
    final tr = translations ?? t;
    return switch (this) {
      assetStore => tr.settings.feature_desc_asset_store,
      templates => tr.settings.feature_desc_templates,
      categories => tr.settings.feature_desc_categories,
      dashboard => tr.settings.feature_desc_dashboard,
      vault => tr.settings.feature_desc_vault,
      storage => tr.settings.feature_desc_storage,
      workspaces => tr.settings.feature_desc_workspaces,
      news => tr.common.onboarding_stay_current,
    };
  }

  static GhFeatureId? fromId(String id) {
    for (final feature in values) {
      if (feature.id == id) {
        return feature;
      }
    }
    return null;
  }
}

const _essentials = [GhFeatureId.assetStore, GhFeatureId.templates, GhFeatureId.categories];

enum GhSetupProfile {
  minimal('minimal', []),
  essentials('essentials', _essentials),
  studio('studio', [..._essentials, GhFeatureId.dashboard, GhFeatureId.vault, GhFeatureId.storage, GhFeatureId.workspaces]),
  complete('complete', GhFeatureId.values);

  const GhSetupProfile(this.id, this.features);

  final String id;
  final List<GhFeatureId> features;

  String label([Translations? translations]) {
    final tr = translations ?? t;
    return switch (this) {
      minimal => tr.settings.setup_profile_minimal,
      essentials => tr.settings.setup_profile_essentials,
      studio => tr.settings.setup_profile_studio,
      complete => tr.settings.setup_profile_complete,
    };
  }

  String description([Translations? translations]) {
    final tr = translations ?? t;
    return switch (this) {
      minimal => tr.settings.setup_profile_minimal_desc,
      essentials => tr.settings.setup_profile_essentials_desc,
      studio => tr.settings.setup_profile_studio_desc,
      complete => tr.settings.setup_profile_complete_desc,
    };
  }
}

bool _flagValue(AppSettings settings, GhFeatureFlag flag) => switch (flag) {
  GhFeatureFlag.categoriesEnabled => settings.categoriesEnabled,
  GhFeatureFlag.workspacesEnabled => settings.workspacesEnabled,
};

bool isFeatureEnabled(AppSettings settings, String id) {
  final feature = GhFeatureId.fromId(id);
  if (feature == null) return true;
  final flag = feature.flag;
  return flag != null ? _flagValue(settings, flag) : !settings.disabledFeatures.contains(id);
}

Set<GhFeatureId> enabledFeatures(AppSettings settings) => {
  for (final feature in GhFeatureId.values)
    if (isFeatureEnabled(settings, feature.id)) feature,
};

AppSettings withFeatures(AppSettings settings, Iterable<GhFeatureId> enabled) {
  final on = enabled.toSet();
  return copySettings(
    settings,
    disabledFeatures: [
      for (final feature in GhFeatureId.values)
        if (feature.flag == null && !on.contains(feature)) feature.id,
    ],
    categoriesEnabled: on.contains(GhFeatureId.categories),
    workspacesEnabled: on.contains(GhFeatureId.workspaces),
  );
}

GhSetupProfile? matchSetupProfile(Set<GhFeatureId> enabled) {
  for (final profile in GhSetupProfile.values) {
    if (profile.features.length == enabled.length && profile.features.every(enabled.contains)) {
      return profile;
    }
  }
  return null;
}
