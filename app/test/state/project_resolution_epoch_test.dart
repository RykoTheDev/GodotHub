import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/projects.dart';
import 'package:godothub/state/project_resolution_epoch.dart';

void main() {
  test('follows the resolution epoch bumped by cache clears', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final start = c.read(projectResolutionEpochProvider);
    expect(start, getResolutionEpoch());
    ProjectsApi.clearIconCache();
    expect(c.read(projectResolutionEpochProvider), start + 1);
    ProjectsApi.clearNameCache();
    expect(c.read(projectResolutionEpochProvider), start + 2);
  });
}
