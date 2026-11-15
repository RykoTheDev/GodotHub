import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/discord.dart';
import 'package:godothub/state/discord_rpc.dart';

void main() {
  test(
    'connects to the running Discord app and sets an activity',
    () async {
      final client = IpcDiscordRpcClient();
      final changes = <bool>[];
      client.connectionChanges.listen(changes.add);
      await client.connect(defaultDiscordAppId).timeout(const Duration(seconds: 10));
      expect(client.connected, isTrue);
      await client.setActivity(const DiscordActivity(details: 'Testing presence', state: 'Back in a moment'));
      await Future<void>.delayed(const Duration(seconds: 5));
      expect(client.connected, isTrue);
      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(changes, [true, false]);
    },
    skip: Platform.environment['DISCORD_LIVE'] == null ? 'set DISCORD_LIVE=1 with Discord running' : false,
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
