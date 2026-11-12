import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../titlebar/providers.dart' show openConsoleSignal;

class ConsoleRequest {
  const ConsoleRequest({required this.id, this.name, this.exportRun});

  final String id;
  final String? name;
  final ExportRun? exportRun;

  static ConsoleRequest? from(Object? detail) {
    if (detail is ConsoleRequest) return detail;
    if (detail is String && detail.isNotEmpty) return ConsoleRequest(id: detail);
    if (detail is Map) {
      final id = detail['id'];
      if (id is! String || id.isEmpty) return null;
      final name = detail['name'];
      final run = detail['exportRun'];
      return ConsoleRequest(id: id, name: name is String ? name : null, exportRun: run is ExportRun ? run : null);
    }
    return null;
  }
}

void requestOpenConsole(String id, {String? name, ExportRun? exportRun}) =>
    AppSignals.emit(openConsoleSignal, ConsoleRequest(id: id, name: name, exportRun: exportRun));

void requestOpenExportConsole(ExportRun run) => requestOpenConsole(run.id, name: '${run.projectName} · ${run.presetName}', exportRun: run);
