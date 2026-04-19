import Cocoa
import FlutterMacOS
import macos_window_utils

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let windowFrame = self.frame
    
    // Establecer el estilo fullSizeContentView ANTES de asignar el contentViewController
    self.styleMask.insert(.fullSizeContentView)
    
    // Usar el view controller del plugin para permitir efectos visuales
    let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
    self.contentViewController = macOSWindowUtilsViewController
    self.setFrame(windowFrame, display: true)

    // Inicializar el manipulador de ventana del plugin
    MainFlutterWindowManipulator.start(mainFlutterWindow: self)
    
    // Configurar comportamiento para que la ventana pueda aparecer en cualquier espacio
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    RegisterGeneratedPlugins(registry: macOSWindowUtilsViewController.flutterViewController)

    super.awakeFromNib()
  }
}
