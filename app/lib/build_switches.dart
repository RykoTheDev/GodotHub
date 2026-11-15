const testSwitchMarker = 'GODOTHUB-TEST-SWITCH:';

const testBuildSwitches = <String>[
  if (String.fromEnvironment('UPDATER_TEST_ENDPOINT') != '') '${testSwitchMarker}UPDATER_TEST_ENDPOINT',
  if (String.fromEnvironment('UPDATER_TEST_PUBKEY') != '') '${testSwitchMarker}UPDATER_TEST_PUBKEY',
  if (bool.fromEnvironment('UPDATER_LAB_AUTO')) '${testSwitchMarker}UPDATER_LAB_AUTO',
  if (bool.fromEnvironment('UPDATER_LAB_CRASH')) '${testSwitchMarker}UPDATER_LAB_CRASH',
  if (String.fromEnvironment('UPDATER_LAB_DATA') != '') '${testSwitchMarker}UPDATER_LAB_DATA',
  if (bool.fromEnvironment('GODOTHUB_BENCH')) '${testSwitchMarker}GODOTHUB_BENCH',
  if (bool.fromEnvironment('FORCE_SEMANTICS')) '${testSwitchMarker}FORCE_SEMANTICS',
];
