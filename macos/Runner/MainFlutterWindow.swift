import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    self.orderOut(nil)
  }

  override func makeKeyAndOrderFront(_ sender: Any?) {
    self.alphaValue = 0.0
    super.makeKeyAndOrderFront(sender)
    self.orderOut(nil)
  }

  override func orderFront(_ sender: Any?) {
    self.alphaValue = 0.0
    super.orderFront(sender)
    self.orderOut(nil)
  }
}
