import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/discord.dart';
import 'package:godothub/discord/discord_ipc.dart';
import 'package:godothub/state/discord_rpc.dart';

class FakeDiscord implements DiscordTransport {
  final sent = <(int, Map<String, Object?>)>[];
  final _out = BytesBuilder();
  final _waiting = <(int, Completer<Uint8List>)>[];
  bool rejectHandshake = false;
  bool closeOnNextFrame = false;
  bool closed = false;

  List<Map<String, Object?>> get activities => [
    for (final (op, data) in sent)
      if (op == 1 && data['cmd'] == 'SET_ACTIVITY') data,
  ];

  int get pings => sent.where((f) => f.$1 == 3).length;

  void _reply(int op, Map<String, Object?> data) {
    _out.add(encodeDiscordFrame(op, data));
    _drain();
  }

  void _drain() {
    while (_waiting.isNotEmpty && _out.length >= _waiting.first.$1) {
      final (length, completer) = _waiting.removeAt(0);
      final all = _out.takeBytes();
      completer.complete(Uint8List.sublistView(all, 0, length));
      _out.add(Uint8List.sublistView(all, length));
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    if (closed) throw const SocketException('closed');
    final (op, length) = decodeDiscordHeader(Uint8List.sublistView(bytes, 0, 8));
    expect(length, bytes.length - 8);
    final data = jsonDecode(utf8.decode(Uint8List.sublistView(bytes, 8))) as Map<String, Object?>;
    sent.add((op, data));
    if (op == 0) {
      _reply(
        rejectHandshake ? 2 : 1,
        rejectHandshake ? {'code': 4000, 'message': 'Invalid Client ID'} : {'cmd': 'DISPATCH', 'evt': 'READY'},
      );
    } else if (closeOnNextFrame) {
      _reply(2, {'code': 1000});
    } else if (op == 3) {
      _reply(4, {});
    } else {
      _reply(1, {'cmd': data['cmd'], 'nonce': data['nonce'], 'evt': null});
    }
  }

  @override
  Future<Uint8List> read(int length) {
    final completer = Completer<Uint8List>();
    _waiting.add((length, completer));
    _drain();
    return completer.future;
  }

  @override
  Future<void> close() async => closed = true;
}

const browsing = DiscordActivity(details: 'Browsing Projects', state: 'Deciding what to work on...', startTimestamp: 42);

Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

void main() {
  test('frames are little-endian op and length followed by JSON', () {
    final bytes = encodeDiscordFrame(1, {'cmd': 'SET_ACTIVITY'});
    expect(bytes.sublist(0, 8), [1, 0, 0, 0, 22, 0, 0, 0]);
    expect(decodeDiscordHeader(Uint8List.sublistView(bytes, 0, 8)), (1, 22));
    expect(utf8.decode(bytes.sublist(8)), '{"cmd":"SET_ACTIVITY"}');
  });

  test('activity JSON leaves out empty fields', () {
    expect(discordActivityJson(browsing), {
      'name': 'GodotHub',
      'details': 'Browsing Projects',
      'state': 'Deciding what to work on...',
      'timestamps': {'start': 42},
    });
    expect(discordActivityJson(const DiscordActivity(details: '', state: 'Godot 4.3')), {'name': 'GodotHub', 'state': 'Godot 4.3'});
  });

  test('Linux and macOS look in the runtime folder, temp folders, Flatpak and Snap', () {
    final paths = discordUnixSocketCandidates({'XDG_RUNTIME_DIR': '/run/user/1000/', 'TMPDIR': '/var/folders/x/T/'});
    expect(paths.first, '/run/user/1000/discord-ipc-0');
    expect(
      paths,
      containsAll([
        '/run/user/1000/app/com.discordapp.Discord/discord-ipc-0',
        '/run/user/1000/snap.discord/discord-ipc-0',
        '/var/folders/x/T/discord-ipc-0',
        '/tmp/discord-ipc-9',
      ]),
    );
  });

  test('backoff doubles up to eight seconds', () {
    expect([0, 1, 3, 4, 30].map(discordBackoff), [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
      const Duration(seconds: 4),
      const Duration(seconds: 8),
      const Duration(seconds: 8),
    ]);
  });

  test('connects, sets the activity with the process id and re-sends it after connecting', () async {
    final discord = FakeDiscord();
    final client = IpcDiscordRpcClient(open: () async => discord, processId: 77, liveness: const Duration(milliseconds: 20));
    final changes = <bool>[];
    client.connectionChanges.listen(changes.add);
    await client.connect('123');
    expect(discord.sent.first.$1, 0);
    expect(discord.sent.first.$2, {'v': 1, 'client_id': '123'});
    await client.setActivity(browsing);
    final first = discord.activities.first;
    expect((first['args']! as Map)['pid'], 77);
    expect((first['args']! as Map)['activity'], discordActivityJson(browsing));
    await waitFor(() => discord.pings >= 2);
    expect(discord.activities, hasLength(1 + discordReassertTicks));
    expect(changes, [true]);
    await client.disconnect();
    expect((discord.activities.last['args']! as Map)['activity'], isNull);
    expect(discord.closed, isTrue);
    await waitFor(() => changes.length == 2);
    expect(changes, [true, false]);
  });

  test('keeps retrying while Discord is closed and connects once it starts', () async {
    FakeDiscord? running;
    final client = IpcDiscordRpcClient(open: () async => running, backoff: (_) => const Duration(milliseconds: 10));
    final changes = <bool>[];
    client.connectionChanges.listen(changes.add);
    await expectLater(client.connect('123'), throwsA(isA<SocketException>()));
    await client.setActivity(browsing);
    running = FakeDiscord();
    await waitFor(() => changes.contains(true));
    expect(running.activities.first['args'], containsPair('activity', discordActivityJson(browsing)));
    await client.disconnect();
  });

  test('a rejected handshake is not a connection', () async {
    final discord = FakeDiscord()..rejectHandshake = true;
    final client = IpcDiscordRpcClient(open: () async => discord, backoff: (_) => const Duration(hours: 1));
    await expectLater(client.connect('bad'), throwsA(isA<SocketException>()));
    expect(client.connected, isFalse);
    expect(discord.closed, isTrue);
    await client.disconnect();
  });

  test('when Discord closes the connection it reconnects and restores the activity', () async {
    var opened = 0;
    final first = FakeDiscord();
    final second = FakeDiscord();
    final client = IpcDiscordRpcClient(
      open: () async => [first, second][opened++ % 2],
      liveness: const Duration(milliseconds: 10),
      backoff: (_) => const Duration(milliseconds: 10),
    );
    final changes = <bool>[];
    client.connectionChanges.listen(changes.add);
    await client.connect('123');
    await client.setActivity(browsing);
    first.closeOnNextFrame = true;
    await waitFor(() => changes.length >= 3);
    expect(changes.take(3), [true, false, true]);
    expect(second.activities.first['args'], containsPair('activity', discordActivityJson(browsing)));
    await client.disconnect();
  });
}
