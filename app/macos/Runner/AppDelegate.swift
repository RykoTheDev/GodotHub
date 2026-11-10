import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  static func main() {
    if let code = runCli() {
      exit(code)
    }
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  private static func runCli() -> Int32? {
    typealias Dispatch = @convention(c) (UInt32, UnsafePointer<CChar>?, UnsafeMutablePointer<Int32>?) -> Bool
    guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "godothub_cli_dispatch") else {
      return nil
    }
    let dispatch = unsafeBitCast(symbol, to: Dispatch.self)
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? ""
    let channel: UInt32 = buildChannel(info?["GodotHubDartDefines"] as? String ?? "") == "stable" ? 0 : 1
    var code: Int32 = 0
    let handled = version.withCString { dispatch(channel, $0, &code) }
    return handled ? code : nil
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
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
