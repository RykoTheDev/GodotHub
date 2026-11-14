import 'dart:async';
import 'dart:io';

import 'updater.dart';

const updaterLabAuto = bool.fromEnvironment('UPDATER_LAB_AUTO');

File get updaterLabReport {
  final home = Platform.isWindows ? null : Platform.environment['HOME'];
  final dir = home == null || home.isEmpty ? Directory.systemTemp.path : home;
  return File('$dir${Platform.pathSeparator}godothub-updater-lab.txt');
}

void updaterLabStep(String step) {
  if (updaterLabAuto) _note('step $step');
}

void _note(String line) {
  stderr.writeln('[updater-lab] $line');
  try {
    updaterLabReport.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } catch (error) {
    stderr.writeln('[updater-lab] could not write ${updaterLabReport.path}: $error');
  }
}

Future<void> runUpdaterLab() async {
  _note('started $appBuildVersion pid $pid');
  try {
    final update = await UpdaterApi.check();
    if (update == null) {
      _note('no-update');
      return;
    }
    _note('downloading ${update.version} ${update.package ?? ''}');
    await update.download((_) {}, onLog: (line) => _note('log $line'));
    _note('restarting');
    await update.restart();
  } catch (error) {
    _note('error $error');
  }
}
