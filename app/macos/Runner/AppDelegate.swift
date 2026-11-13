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

  @objc func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    return DockMenuStore.shared.menu(target: self)
  }

  @objc func godothubOpenRecent(_ sender: NSMenuItem) {
    DockMenuStore.shared.open(index: sender.tag)
  }
}

final class DockMenuStore {
  static let shared = DockMenuStore()

  private var items: [(id: String, label: String, path: String)] = []
  private var channel: FlutterMethodChannel?

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "godothub/dock", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setRecent" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let list = call.arguments as? [[String: String]] ?? []
      self?.items = list.compactMap { entry in
        guard let id = entry["id"], let label = entry["label"] else {
          return nil
        }
        return (id: id, label: label, path: entry["path"] ?? "")
      }
      result(nil)
    }
    self.channel = channel
  }

  func menu(target: AnyObject) -> NSMenu {
    let menu = NSMenu()
    for (index, item) in items.enumerated() {
      let entry = NSMenuItem(
        title: item.label, action: #selector(AppDelegate.godothubOpenRecent(_:)), keyEquivalent: "")
      entry.target = target
      entry.tag = index
      entry.toolTip = item.path
      menu.addItem(entry)
    }
    return menu
  }

  func open(index: Int) {
    guard items.indices.contains(index) else {
      return
    }
    channel?.invokeMethod("openRecent", arguments: items[index].id)
  }
}
