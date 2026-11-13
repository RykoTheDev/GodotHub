import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/discord.dart';
import 'package:godothub/api/events.dart';
import 'package:godothub/src/rust/api/native.dart' as native;
import 'package:godothub/state/discord_rpc.dart';

import '../support/fake_rust.dart';

AppEvent _connected(bool value) =>
    AppEvent(kind: AppEventKind.discordConnected, name: 'discord-rpc://connected', json: '$value', flag: value);

void main() {
  late FakeRustApi rust;

  setUp(() {
    rust = installFakeRust();
  });

  test('activities and connection calls go to the core client', () async {
    final calls = <Object?>[];
    rust
      ..on('crateApiNativeDiscordConnect', ({required String appId}) async => calls.add('connect:$appId'))
      ..on('crateApiNativeDiscordDisconnect', () async => calls.add('disconnect'))
      ..on('crateApiNativeDiscordSetActivity', ({native.DiscordActivity? activity}) async => calls.add(activity));
    const client = RustDiscordRpcClient();
    await client.connect('123');
    await client.setActivity(const DiscordActivity(details: 'Browsing Projects', state: 'Deciding what to work on...', startTimestamp: 42));
    await client.disconnect();
    expect(calls, [
      'connect:123',
      const native.DiscordActivity(name: 'GodotHub', details: 'Browsing Projects', state: 'Deciding what to work on...', startTimestamp: 42),
      'disconnect',
    ]);
  });

  test('bridge failures become future errors', () async {
    const client = RustDiscordRpcClient();
    await expectLater(client.connect('123'), throwsA(isA<UnimplementedError>()));
    await expectLater(client.setActivity(const DiscordActivity(details: 'a', state: 'b')), throwsA(isA<UnimplementedError>()));
  });

  test('connection changes follow the core event', () async {
    const client = RustDiscordRpcClient();
    final seen = <bool>[];
    final subscription = client.connectionChanges.listen(seen.add);
    rust
      ..emit(_connected(true))
      ..emit(_connected(false));
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    expect(seen, [true, false]);
  });
}
