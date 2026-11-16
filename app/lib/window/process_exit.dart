import 'dart:ffi';
import 'dart:io';

Never endProcess(int code) {
  if (Platform.isWindows) {
    final kernel = DynamicLibrary.open('kernel32.dll');
    final current = kernel.lookupFunction<IntPtr Function(), int Function()>('GetCurrentProcess');
    final terminate = kernel.lookupFunction<Int32 Function(IntPtr, Uint32), int Function(int, int)>('TerminateProcess');
    terminate(current(), code);
  }
  exit(code);
}
