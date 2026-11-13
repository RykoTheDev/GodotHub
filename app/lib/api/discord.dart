import '../src/rust/api/native.dart' as native;
import '../state/discord_rpc.dart';
import 'events.dart';

class RustDiscordRpcClient implements DiscordRpcClient {
  const RustDiscordRpcClient();

  @override
  Future<void> connect(String appId) async => native.discordConnect(appId: appId);

  @override
  Future<void> disconnect() async => native.discordDisconnect();

  @override
  Future<void> setActivity(DiscordActivity activity) async => native.discordSetActivity(
    activity: native.DiscordActivity(
      name: activity.name,
      details: activity.details,
      state: activity.state,
      startTimestamp: activity.startTimestamp,
    ),
  );

  @override
  Stream<bool> get connectionChanges => AppEvents.of(AppEventKind.discordConnected).map((event) => event.flag ?? false);
}
