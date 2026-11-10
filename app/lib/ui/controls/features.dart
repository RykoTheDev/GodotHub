import '../../design/design.dart';
import 'strings.dart' as s;

enum GhCoreFeature {
  projects(GhIcons.folder, s.navProjects, s.onboardingKeepOrganized),
  versions(GhIcons.cloudArrowDown, s.navVersions, s.onboardingDownloadManage);

  const GhCoreFeature(this.icon, this.label, this.description);

  final FaIconData icon;
  final String label;
  final String description;
}

enum GhFeatureId {
  assetStore('asset-store', GhIcons.store, s.navAssetStore, s.featureDescAssetStore),
  templates('templates', GhIcons.rocket, s.navTemplates, s.featureDescTemplates),
  categories('categories', GhIcons.tags, s.categories, s.featureDescCategories),
  dashboard('dashboard', GhIcons.house, s.navDashboard, s.featureDescDashboard),
  vault('vault', GhIcons.briefcase, s.navVault, s.featureDescVault),
  storage('storage', GhIcons.hardDrive, s.navStorage, s.featureDescStorage),
  workspaces('workspaces', GhIcons.layoutGrid, s.sectionWorkspaces, s.featureDescWorkspaces),
  news('news', GhIcons.news, s.navNews, s.onboardingStayCurrent);

  const GhFeatureId(this.id, this.icon, this.label, this.description);

  final String id;
  final FaIconData icon;
  final String label;
  final String description;

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
  minimal('minimal', [], s.setupProfileMinimal, s.setupProfileMinimalDesc),
  essentials('essentials', _essentials, s.setupProfileEssentials, s.setupProfileEssentialsDesc),
  studio(
    'studio',
    [..._essentials, GhFeatureId.dashboard, GhFeatureId.vault, GhFeatureId.storage, GhFeatureId.workspaces],
    s.setupProfileStudio,
    s.setupProfileStudioDesc,
  ),
  complete('complete', GhFeatureId.values, s.setupProfileComplete, s.setupProfileCompleteDesc);

  const GhSetupProfile(this.id, this.features, this.label, this.description);

  final String id;
  final List<GhFeatureId> features;
  final String label;
  final String description;
}

GhSetupProfile? matchSetupProfile(Set<GhFeatureId> enabled) {
  for (final profile in GhSetupProfile.values) {
    if (profile.features.length == enabled.length && profile.features.every(enabled.contains)) {
      return profile;
    }
  }
  return null;
}
