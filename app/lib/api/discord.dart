import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../discord/discord_ipc.dart';
import '../state/discord_rpc.dart';

const discordLiveness = Duration(seconds: 2);
const discordReassertTicks = 3;

Duration discordBackoff(int attempt) => Duration(milliseconds: min(8000, 500 * (1 << min(attempt, 16))));

Map<String, Object?> discordActivityJson(DiscordActivity activity) => {
  if (activity.name.isNotEmpty) 'name': activity.name,
  if (activity.details.isNotEmpty) 'details': activity.details,
  if (activity.state.isNotEmpty) 'state': activity.state,
  if (activity.startTimestamp != null) 'timestamps': {'start': activity.startTimestamp},
};

class IpcDiscordRpcClient implements DiscordRpcClient {
  IpcDiscordRpcClient({DiscordTransportOpener? open, int? processId, this.liveness = discordLiveness, this.backoff = discordBackoff})
    : _open = open ?? openDiscordTransport,
      _pid = processId ?? pid;

  final Duration liveness;
  final Duration Function(int attempt) backoff;

  final DiscordTransportOpener _open;
  final int _pid;
  final _changes = StreamController<bool>.broadcast();
  DiscordTransport? _transport;
  String? _appId;
  DiscordActivity? _desired;
  Timer? _timer;
  int _attempt = 0;
  int _reassert = 0;
  int _nonce = 0;
  Future<void> _queue = Future.value();

  bool get connected => _transport != null;

  @override
  Stream<bool> get connectionChanges => _changes.stream;

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  @override
  Future<void> connect(String appId) => _serial(() async {
    if (_appId == appId && _transport != null) return;
    await _close(clear: true);
    _appId = appId;
    _attempt = 0;
    if (!await _tryConnect()) {
      _scheduleRetry();
      throw const SocketException('Discord is not running');
    }
  });

  @override
  Future<void> disconnect() => _serial(() async {
    _appId = null;
    _timer?.cancel();
    await _close(clear: true);
  });

  @override
  Future<void> setActivity(DiscordActivity activity) => _serial(() async {
    _desired = activity;
    if (_transport != null) await _apply();
  });

  Future<bool> _tryConnect() async {
    final appId = _appId;
    if (appId == null) return false;
    DiscordTransport? transport;
    try {
      transport = await _open();
      if (transport == null) return false;
      await transport.write(encodeDiscordFrame(DiscordOp.handshake.index, {'v': 1, 'client_id': appId}));
      final reply = await readDiscordFrame(transport).timeout(const Duration(seconds: 5));
      if (reply.closed || reply.error) throw const SocketException('Discord rejected the connection');
    } catch (_) {
      await transport?.close();
      return false;
    }
    _transport = transport;
    _attempt = 0;
    _reassert = discordReassertTicks;
    _changes.add(true);
    if (_desired != null) await _apply();
    _schedule(liveness);
    return true;
  }

  Future<void> _exchange(int op, Object? payload) async {
    final transport = _transport;
    if (transport == null) return;
    try {
      await transport.write(encodeDiscordFrame(op, payload));
      final reply = await readDiscordFrame(transport).timeout(const Duration(seconds: 5));
      if (reply.closed) throw const SocketException('Discord closed the connection');
    } catch (_) {
      await _dropConnection();
    }
  }

  Future<void> _apply() => _exchange(DiscordOp.frame.index, {
    'cmd': 'SET_ACTIVITY',
    'args': {'pid': _pid, 'activity': _desired == null ? null : discordActivityJson(_desired!)},
    'nonce': '$_pid-${++_nonce}',
  });

  Future<void> _tick() => _serial(() async {
    if (_transport != null) {
      if (_reassert > 0 && _desired != null) {
        _reassert--;
        await _apply();
      } else {
        await _exchange(DiscordOp.ping.index, const <String, Object?>{});
      }
      if (_transport != null) _schedule(liveness);
      return;
    }
    if (_appId != null && !await _tryConnect()) _scheduleRetry();
  });

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => _tick().ignore());
  }

  void _scheduleRetry() {
    _schedule(backoff(_attempt));
    _attempt++;
  }

  Future<void> _dropConnection() async {
    final transport = _transport;
    _transport = null;
    await transport?.close();
    if (transport != null) _changes.add(false);
    if (_appId != null) {
      _attempt = 0;
      _scheduleRetry();
    }
  }

  Future<void> _close({required bool clear}) async {
    final transport = _transport;
    _transport = null;
    if (transport == null) return;
    if (clear) {
      try {
        await transport.write(
          encodeDiscordFrame(DiscordOp.frame.index, {
            'cmd': 'SET_ACTIVITY',
            'args': {'pid': _pid, 'activity': null},
            'nonce': '$_pid-${++_nonce}',
          }),
        );
        await readDiscordFrame(transport).timeout(const Duration(seconds: 1));
      } catch (_) {}
    }
    await transport.close();
    _changes.add(false);
  }
}
