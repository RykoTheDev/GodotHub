import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show immutable;

enum DiscordOp { handshake, frame, close, ping, pong }

@immutable
class DiscordFrame {
  const DiscordFrame(this.op, this.data);

  final int op;
  final Map<String, Object?> data;

  bool get closed => op == DiscordOp.close.index;
  bool get error => data['evt'] == 'ERROR';
}

Uint8List encodeDiscordFrame(int op, Object? payload) {
  final body = utf8.encode(jsonEncode(payload));
  final bytes = Uint8List(8 + body.length);
  ByteData.sublistView(bytes)
    ..setUint32(0, op, Endian.little)
    ..setUint32(4, body.length, Endian.little);
  bytes.setRange(8, bytes.length, body);
  return bytes;
}

(int op, int length) decodeDiscordHeader(Uint8List header) {
  final view = ByteData.sublistView(header);
  return (view.getUint32(0, Endian.little), view.getUint32(4, Endian.little));
}

abstract interface class DiscordTransport {
  Future<void> write(Uint8List bytes);
  Future<Uint8List> read(int length);
  Future<void> close();
}

Future<DiscordFrame> readDiscordFrame(DiscordTransport transport) async {
  final (op, length) = decodeDiscordHeader(await transport.read(8));
  final body = length == 0 ? '{}' : utf8.decode(await transport.read(length));
  final decoded = jsonDecode(body);
  return DiscordFrame(op, decoded is Map<String, Object?> ? decoded : const {});
}

List<String> discordUnixSocketCandidates(Map<String, String> env) {
  final roots = <String>{
    for (final key in ['XDG_RUNTIME_DIR', 'TMPDIR', 'TMP', 'TEMP'])
      if ((env[key] ?? '').isNotEmpty) env[key]!.replaceAll(RegExp(r'/+$'), ''),
    '/tmp',
  };
  const subfolders = [
    '',
    '/app/com.discordapp.Discord',
    '/app/com.discordapp.DiscordCanary',
    '/app/com.discordapp.DiscordPTB',
    '/snap.discord',
  ];
  return [
    for (var i = 0; i < 10; i++)
      for (final root in roots)
        for (final sub in subfolders) '$root$sub/discord-ipc-$i',
  ];
}

typedef DiscordTransportOpener = Future<DiscordTransport?> Function();

Future<DiscordTransport?> openDiscordTransport() async {
  if (Platform.isWindows) return _WindowsPipeTransport.open();
  for (final path in discordUnixSocketCandidates(Platform.environment)) {
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) continue;
    try {
      final socket = await Socket.connect(InternetAddress(path, type: InternetAddressType.unix), 0, timeout: const Duration(seconds: 2));
      return _SocketTransport(socket);
    } catch (_) {}
  }
  return null;
}

class _SocketTransport implements DiscordTransport {
  _SocketTransport(this._socket) {
    _subscription = _socket.listen(
      (chunk) {
        _buffer.add(chunk);
        _drain();
      },
      onError: (Object e) => _fail(e),
      onDone: () => _fail(const SocketException('Discord closed the connection')),
      cancelOnError: true,
    );
  }

  final Socket _socket;
  late final StreamSubscription<Uint8List> _subscription;
  final _buffer = BytesBuilder(copy: false);
  final _waiting = <(int, Completer<Uint8List>)>[];
  Object? _error;

  void _drain() {
    while (_waiting.isNotEmpty && _buffer.length >= _waiting.first.$1) {
      final (length, completer) = _waiting.removeAt(0);
      final all = _buffer.takeBytes();
      completer.complete(Uint8List.sublistView(all, 0, length));
      _buffer.add(Uint8List.sublistView(all, length));
    }
  }

  void _fail(Object error) {
    _error = error;
    for (final (_, completer) in _waiting) {
      completer.completeError(error);
    }
    _waiting.clear();
  }

  @override
  Future<Uint8List> read(int length) {
    if (_error != null) return Future.error(_error!);
    final completer = Completer<Uint8List>();
    _waiting.add((length, completer));
    _drain();
    return completer.future;
  }

  @override
  Future<void> write(Uint8List bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    _socket.destroy();
  }
}

class _WindowsPipeTransport implements DiscordTransport {
  _WindowsPipeTransport(this._requests, this._isolate);

  final SendPort _requests;
  final Isolate _isolate;

  static Future<DiscordTransport?> open() async {
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(_pipeWorker, ready.sendPort);
    final requests = await ready.first as SendPort;
    final transport = _WindowsPipeTransport(requests, isolate);
    final opened = await transport._call<bool>(('open', null));
    if (opened) return transport;
    await transport.close();
    return null;
  }

  Future<T> _call<T>((String, Object?) request) async {
    final reply = ReceivePort();
    _requests.send((request.$1, request.$2, reply.sendPort));
    final result = await reply.first;
    reply.close();
    if (result is String && result.startsWith('error:')) throw FileSystemException(result.substring(6));
    return result as T;
  }

  @override
  Future<Uint8List> read(int length) => _call<Uint8List>(('read', length));

  @override
  Future<void> write(Uint8List bytes) => _call<bool>(('write', bytes));

  @override
  Future<void> close() async {
    try {
      await _call<bool>(('close', null)).timeout(const Duration(seconds: 1));
    } catch (_) {}
    _isolate.kill(priority: Isolate.immediate);
  }
}

typedef _CreateFileNative = IntPtr Function(Pointer<Utf16>, Uint32, Uint32, Pointer<Void>, Uint32, Uint32, IntPtr);
typedef _CreateFileDart = int Function(Pointer<Utf16>, int, int, Pointer<Void>, int, int, int);
typedef _IoNative = Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Void>);
typedef _IoDart = int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>);
typedef _CloseNative = Int32 Function(IntPtr);
typedef _CloseDart = int Function(int);

void _pipeWorker(SendPort ready) {
  final kernel = DynamicLibrary.open('kernel32.dll');
  final createFile = kernel.lookupFunction<_CreateFileNative, _CreateFileDart>('CreateFileW');
  final readFile = kernel.lookupFunction<_IoNative, _IoDart>('ReadFile');
  final writeFile = kernel.lookupFunction<_IoNative, _IoDart>('WriteFile');
  final closeHandle = kernel.lookupFunction<_CloseNative, _CloseDart>('CloseHandle');
  const genericRead = 0x80000000;
  const genericWrite = 0x40000000;
  const openExisting = 3;
  const invalidHandle = -1;
  var handle = invalidHandle;
  final requests = ReceivePort();
  ready.send(requests.sendPort);
  requests.listen((message) {
    final (command, argument, SendPort reply) = message as (String, Object?, SendPort);
    switch (command) {
      case 'open':
        for (var i = 0; i < 10 && handle == invalidHandle; i++) {
          final name = '\\\\.\\pipe\\discord-ipc-$i'.toNativeUtf16();
          handle = createFile(name, genericRead | genericWrite, 0, nullptr, openExisting, 0, 0);
          calloc.free(name);
        }
        reply.send(handle != invalidHandle);
      case 'write':
        final bytes = argument! as Uint8List;
        final buffer = calloc<Uint8>(bytes.length);
        final written = calloc<Uint32>();
        buffer.asTypedList(bytes.length).setAll(0, bytes);
        final ok = writeFile(handle, buffer, bytes.length, written, nullptr) != 0 && written.value == bytes.length;
        calloc
          ..free(buffer)
          ..free(written);
        reply.send(ok ? true : 'error:writing to Discord failed');
      case 'read':
        final length = argument! as int;
        final buffer = calloc<Uint8>(length);
        final count = calloc<Uint32>();
        var total = 0;
        var ok = true;
        while (total < length) {
          if (readFile(handle, buffer + total, length - total, count, nullptr) == 0 || count.value == 0) {
            ok = false;
            break;
          }
          total += count.value;
        }
        final bytes = Uint8List.fromList(buffer.asTypedList(length));
        calloc
          ..free(buffer)
          ..free(count);
        reply.send(ok ? bytes : 'error:reading from Discord failed');
      case 'close':
        if (handle != invalidHandle) closeHandle(handle);
        handle = invalidHandle;
        reply.send(true);
        requests.close();
    }
  });
}
