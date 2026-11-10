import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static func main() {
    if let code = runCli() {
      exit(code)
    }
    if forwardedToRunningInstance() {
      exit(0)
    }
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  private static func bridgeSymbol(_ name: String) -> UnsafeMutableRawPointer? {
    dlsym(UnsafeMutableRawPointer(bitPattern: -2), name)
  }

  private static var channel: UInt32 {
    let defines = Bundle.main.infoDictionary?["GodotHubDartDefines"] as? String ?? ""
    return buildChannel(defines) == "stable" ? 0 : 1
  }

  private static func runCli() -> Int32? {
    typealias Dispatch = @convention(c) (UInt32, UnsafePointer<CChar>?, UnsafeMutablePointer<Int32>?) -> Bool
    guard let symbol = bridgeSymbol("godothub_cli_dispatch") else {
      return nil
    }
    let dispatch = unsafeBitCast(symbol, to: Dispatch.self)
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    var code: Int32 = 0
    let handled = version.withCString { dispatch(channel, $0, &code) }
    return handled ? code : nil
  }

  private static func forwardedToRunningInstance() -> Bool {
    typealias Forward = @convention(c) (UInt32) -> Bool
    guard let symbol = bridgeSymbol("godothub_forward_to_running_instance") else {
      return false
    }
    return unsafeBitCast(symbol, to: Forward.self)(channel)
  }

  private static func buildChannel(_ defines: String) -> String? {
    for item in defines.split(separator: ",") {
      guard let data = Data(base64Encoded: String(item)),
        let text = String(data: data, encoding: .utf8),
        text.hasPrefix("CHANNEL=")
      else {
        continue
      }
      return String(text.dropFirst("CHANNEL=".count))
    }
    return nil
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in sender.windows {
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
