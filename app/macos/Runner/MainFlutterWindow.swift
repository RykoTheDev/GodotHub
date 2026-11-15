import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let trafficLightInset = NSPoint(x: 20, y: 22)

  override func awakeFromNib() {
    let engine = FlutterEngine(name: "io.flutter", project: nil, allowHeadlessExecution: true)
    let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    DockMenuStore.shared.attach(messenger: engine.binaryMessenger)
    _ = engine.run(withEntrypoint: nil)

    super.awakeFromNib()

    let center = NotificationCenter.default
    for name in [
      NSWindow.didResizeNotification,
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didExitFullScreenNotification,
      NSWindow.didBecomeKeyNotification,
    ] {
      center.addObserver(self, selector: #selector(placeTrafficLights), name: name, object: self)
    }
    placeTrafficLights()
  }

  @objc private func placeTrafficLights() {
    guard styleMask.contains(.fullSizeContentView), !styleMask.contains(.fullScreen),
      let close = standardWindowButton(.closeButton),
      let minimize = standardWindowButton(.miniaturizeButton),
      let zoom = standardWindowButton(.zoomButton),
      let container = close.superview?.superview
    else { return }
    let height = close.frame.height + trafficLightInset.y
    var bar = container.frame
    bar.size.height = height
    bar.origin.y = frame.height - height
    container.frame = bar
    let spacing = minimize.frame.origin.x - close.frame.origin.x
    for (index, button) in [close, minimize, zoom].enumerated() {
      button.setFrameOrigin(NSPoint(x: trafficLightInset.x + CGFloat(index) * spacing, y: button.frame.origin.y))
    }
  }
}
