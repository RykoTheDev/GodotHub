import 'dart:async';
import 'dart:convert';
import 'dart:io';

const usage = '''
Local update lab for the Flutter beta (Windows, in-app updates). Nothing is committed or published.

  dart run tool/updater_lab.dart prepare [--from 0.0.1] [--to 0.0.2] [--broken] [--rebuild]
      Builds both versions with a throwaway signing key, installs --from into
      build/updater_lab/install the way the setup does, and packages --to as a signed update.
      --broken makes --to exit on startup so the launcher's rollback can be tested.
  dart run tool/updater_lab.dart serve [--port 47821] [--slow] [--drop] [--tamper]
      Serves latest.json and the update on 127.0.0.1. --slow throttles the download,
      --drop cuts it off halfway, --tamper changes a byte so the signature check must fail.
  dart run tool/updater_lab.dart start      Starts the installed copy through the launcher.
  dart run tool/updater_lab.dart status     Shows launcher.json and the installed version folders.
  dart run tool/updater_lab.dart reset      Puts the --from version back as the only installed version.
''';

const exeName = 'godothub-beta.exe';
const defaultPort = 47821;

final appDir = File.fromUri(Platform.script).parent.parent;
final repoDir = appDir.parent;
final labDir = Directory(_join(appDir.path, ['build', 'updater_lab']));
final buildsDir = Directory(_join(labDir.path, ['builds']));
final installDir = Directory(_join(labDir.path, ['install']));
final serverDir = Directory(_join(labDir.path, ['server']));
final keyFile = File(_join(labDir.path, ['lab.key']));
final configFile = File(_join(labDir.path, ['lab.json']));

String _join(String base, List<String> parts) => [base, ...parts].join(Platform.pathSeparator);

Future<void> main(List<String> args) async {
  if (!Platform.isWindows) {
    stderr.writeln('The update lab covers the Windows in-app updater only.');
    exit(1);
  }
  final command = args.isEmpty ? '' : args.first;
  final options = args.skip(1).toList();
  switch (command) {
    case 'prepare':
      await prepare(options);
    case 'serve':
      await serve(options);
    case 'start':
      await start();
    case 'status':
      status();
    case 'reset':
      reset();
    default:
      stdout.write(usage);
      exit(command.isEmpty ? 0 : 64);
  }
}

String? _option(List<String> options, String name) {
  final index = options.indexOf(name);
  return index >= 0 && index + 1 < options.length ? options[index + 1] : null;
}

Map<String, dynamic> _config() => configFile.existsSync() ? jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic> : {};

Future<void> _run(String executable, List<String> arguments, {String? workingDirectory}) async {
  stdout.writeln('> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('$executable failed with exit code $code');
    exit(code);
  }
}

Future<String> _capture(String executable, List<String> arguments, {String? workingDirectory}) async {
  final result = await Process.run(executable, arguments, workingDirectory: workingDirectory, runInShell: true);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }
  return result.stdout as String;
}

void _copyDir(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync()) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final target = _join(to.path, [name]);
    if (entity is Directory) {
      _copyDir(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}

void _deleteDir(Directory dir) {
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}

String get _signer => _join(repoDir.path, ['node_modules', '.bin', 'tauri.exe']);

Future<String> _publicKey() async {
  final pub = File('${keyFile.path}.pub');
  if (!pub.existsSync()) {
    labDir.createSync(recursive: true);
    await _run(_signer, ['signer', 'generate', '--ci', '--password', 'lab', '--write-keys', keyFile.path, '--force']);
  }
  return pub.readAsStringSync().trim();
}

Future<String> _launcherExe() async {
  await _run('cargo', ['build', '-p', 'godothub_launcher', '--release'], workingDirectory: repoDir.path);
  final metadata = jsonDecode(await _capture('cargo', ['metadata', '--format-version', '1', '--no-deps'], workingDirectory: repoDir.path));
  return _join(metadata['target_directory'] as String, ['release', 'godothub-launcher.exe']);
}

Directory _buildDir(String version, bool broken) => Directory(_join(buildsDir.path, [broken ? '$version-broken' : version]));

Future<Directory> _build(String version, String publicKey, int port, {bool broken = false, bool rebuild = false}) async {
  final out = _buildDir(version, broken);
  if (out.existsSync() && !rebuild) {
    stdout.writeln('Reusing ${out.path}');
    return out;
  }
  await _run('flutter', [
    'build',
    'windows',
    '--release',
    '--dart-define=CHANNEL=beta',
    '--dart-define=APP_VERSION=$version',
    '--dart-define=UPDATER_TEST_ENDPOINT=http://127.0.0.1:$port/latest.json',
    '--dart-define=UPDATER_TEST_PUBKEY=$publicKey',
    if (broken) '--dart-define=UPDATER_LAB_CRASH=true',
    '--build-name=$version',
  ], workingDirectory: appDir.path);
  _deleteDir(out);
  _copyDir(Directory(_join(appDir.path, ['build', 'windows', 'x64', 'runner', 'Release'])), out);
  return out;
}

void _install(String version) {
  final config = _config();
  _deleteDir(installDir);
  _copyDir(_buildDir(version, false), Directory(_join(installDir.path, ['app-$version'])));
  File(config['launcher'] as String).copySync(_join(installDir.path, [exeName]));
  File(_join(installDir.path, ['launcher.json'])).writeAsStringSync(jsonEncode({'current': version}));
  stdout.writeln('Installed $version into ${installDir.path}');
}

Future<void> _package(Directory build, String version, int port) async {
  _deleteDir(serverDir);
  serverDir.createSync(recursive: true);
  final name = 'GodotHub-Beta-$version-windows-x64.zip';
  final zip = _join(serverDir.path, [name]);
  final entries = build.listSync().map((e) => e.uri.pathSegments.lastWhere((s) => s.isNotEmpty)).toList();
  final tar = _join(Platform.environment['SYSTEMROOT'] ?? r'C:\Windows', ['System32', 'tar.exe']);
  await _run(tar, ['-a', '-c', '-f', zip, ...entries], workingDirectory: build.path);
  await _run(_signer, ['signer', 'sign', '--private-key-path', keyFile.path, '--password', 'lab', zip]);
  final manifest = {
    'version': version,
    'notes': '### New\n- Update lab build $version\n### Fixed\n- Served from this computer',
    'pub_date': DateTime.now().toUtc().toIso8601String(),
    'platforms': {
      'windows-x86_64-inapp': {'signature': File('$zip.sig').readAsStringSync().trim(), 'url': 'http://127.0.0.1:$port/$name'},
    },
  };
  File(_join(serverDir.path, ['latest.json'])).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('Packaged $version into ${serverDir.path}');
}

Future<void> prepare(List<String> options) async {
  final from = _option(options, '--from') ?? '0.0.1';
  final to = _option(options, '--to') ?? '0.0.2';
  final port = int.parse(_option(options, '--port') ?? '$defaultPort');
  final broken = options.contains('--broken');
  final rebuild = options.contains('--rebuild') || (_config()['port'] ?? port) != port;
  final publicKey = await _publicKey();
  final launcher = await _launcherExe();
  configFile.writeAsStringSync(jsonEncode({'from': from, 'to': to, 'port': port, 'broken': broken, 'launcher': launcher}));
  await _build(from, publicKey, port, rebuild: rebuild);
  final update = await _build(to, publicKey, port, broken: broken, rebuild: rebuild);
  _install(from);
  await _package(update, to, port);
  stdout.writeln('\nNext: close any running GodotHub Beta, then run "serve" in one terminal and "start" in another.');
}

Future<void> serve(List<String> options) async {
  final port = int.parse(_option(options, '--port') ?? '${_config()['port'] ?? defaultPort}');
  final slow = options.contains('--slow');
  final drop = options.contains('--drop');
  final tamper = options.contains('--tamper');
  if (!File(_join(serverDir.path, ['latest.json'])).existsSync()) {
    stderr.writeln('Nothing to serve yet: run "prepare" first.');
    exit(1);
  }
  final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  } on SocketException {
    stderr.writeln('Port $port is in use by another program. Run "prepare --port <free port>" to rebuild for another port.');
    exit(1);
  }
  stdout.writeln('Serving ${serverDir.path} on http://127.0.0.1:$port (slow: $slow, drop: $drop, tamper: $tamper)');
  await for (final request in server) {
    final name = request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last;
    final file = File(_join(serverDir.path, [name]));
    stdout.writeln('${DateTime.now().toIso8601String().substring(11, 19)} ${request.method} ${request.uri.path}');
    if (name.isEmpty || name.contains('..') || !file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }
    final bytes = file.readAsBytesSync();
    if (tamper && name.endsWith('.zip')) bytes[bytes.length ~/ 2] ^= 0xFF;
    request.response.headers.contentType = name.endsWith('.json') ? ContentType.json : ContentType.binary;
    request.response.contentLength = bytes.length;
    if (!name.endsWith('.zip')) {
      request.response.add(bytes);
      await request.response.close();
      continue;
    }
    unawaited(_sendUpdate(request, bytes, slow: slow, drop: drop));
  }
}

Future<void> _sendUpdate(HttpRequest request, List<int> bytes, {required bool slow, required bool drop}) async {
  const chunk = 256 * 1024;
  final socket = await request.response.detachSocket();
  final end = drop ? bytes.length ~/ 2 : bytes.length;
  try {
    for (var offset = 0; offset < end; offset += chunk) {
      socket.add(bytes.sublist(offset, offset + chunk > end ? end : offset + chunk));
      await socket.flush();
      if (slow) await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  } catch (_) {}
  if (drop) {
    stdout.writeln('Dropped the connection after ${end ~/ 1024} KB');
    socket.destroy();
  } else {
    await socket.close();
  }
}

Future<void> start() async {
  final launcher = File(_join(installDir.path, [exeName]));
  if (!launcher.existsSync()) {
    stderr.writeln('Nothing installed yet: run "prepare" first.');
    exit(1);
  }
  await Process.start(launcher.path, const [], workingDirectory: installDir.path, mode: ProcessStartMode.detached);
  stdout.writeln('Started ${launcher.path}');
}

void status() {
  final state = File(_join(installDir.path, ['launcher.json']));
  stdout.writeln(state.existsSync() ? state.readAsStringSync() : 'No launcher.json');
  if (installDir.existsSync()) {
    for (final entity in installDir.listSync()) {
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is Directory && name.startsWith('app-')) stdout.writeln('  $name');
    }
  }
}

void reset() {
  final from = _config()['from'] as String?;
  if (from == null) {
    stderr.writeln('Nothing prepared yet: run "prepare" first.');
    exit(1);
  }
  _install(from);
}
