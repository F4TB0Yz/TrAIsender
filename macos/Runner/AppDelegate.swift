import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
    var recorderManager: AudioRecorderManager?

    private static func isPermissionRelated(_ error: Error) -> Bool {
        let nsError = error as NSError
        let domain = nsError.domain.lowercased()
        let message = nsError.localizedDescription.lowercased()

        // Error codes for local custom permission failures.
        if nsError.code == 1 {
            return true
        }

        // ScreenCaptureKit / TCC denial signals can vary by macOS version.
        if domain.contains("tcc") || domain.contains("avaudio") || domain.contains("avcapture") {
            return true
        }

        if message.contains("tcc") || message.contains("rechaz") || message.contains("deneg") || message.contains("microphone") || message.contains("micrófono") {
            return true
        }

        return false
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.traisender/recorder", binaryMessenger: controller.engine.binaryMessenger)
        
        recorderManager = AudioRecorderManager()
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "start":
                guard let args = call.arguments as? [String: Any],
                      let path = args["path"] as? String,
                      let includeMic = args["includeMic"] as? Bool else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing path or includeMic", details: nil))
                    return
                }
                self?.recorderManager?.start(path: path, includeMic: includeMic) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            let isPermissionError = AppDelegate.isPermissionRelated(error)
                            AppDelegate.showError(
                                title: "Error al Grabar",
                                message: error.localizedDescription,
                                showSettingsButton: isPermissionError
                            )
                        }
                        result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }
            case "stop":
                self?.recorderManager?.stop { path in
                    result(path)
                }
            case "isRecording":
                result(self?.recorderManager?.isRecording ?? false)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    static func showError(title: String, message: String, showSettingsButton: Bool = false) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .critical
            
            // Cargar ícono desde los assets de Flutter (webp)
            if let iconPath = Bundle.main.path(forResource: "app_icon", ofType: "webp", inDirectory: "flutter_assets/assets"),
               let icon = NSImage(contentsOfFile: iconPath) {
                alert.icon = icon
            }
            
            if showSettingsButton {
                alert.addButton(withTitle: "Abrir Ajustes")
                alert.addButton(withTitle: "Cancelar")
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                }
            } else {
                alert.addButton(withTitle: "Entendido")
                alert.runModal()
            }
        }
    }
}

class AudioRecorderManager: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var assetWriter: AVAssetWriter?
    private var audioInput: AVAssetWriterInput?
    private var isWriting = false
    private var micSession: AVCaptureSession?
    private var hasWrittenBuffer = false
    private var outputPath: String?
    
    // Para mezclar, necesitamos saber cuál fue el primer timestamp
    private var startTime: CMTime?
    
    func start(path: String, includeMic: Bool, completion: @escaping (Error?) -> Void) {
        guard includeMic else {
            completion(NSError(
                domain: "com.traisender.recorder",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "No hay fuente de audio activa. Activa el micrófono para grabar."]
            ))
            return
        }

        let url = URL(fileURLWithPath: path)
        outputPath = path
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .m4a)
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000
            ]
            
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
            audioInput?.expectsMediaDataInRealTime = true
            
            if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
                assetWriter?.add(audioInput)
            }
            
            assetWriter?.startWriting()
            isWriting = true
            hasWrittenBuffer = false
            startTime = nil

            startMicCapture(completion: completion)
        } catch {
            isWriting = false
            completion(error)
        }
    }
    
    private func startMicCapture(completion: @escaping (Error?) -> Void) {
        micSession = AVCaptureSession()
        guard let mic = AVCaptureDevice.default(for: .audio) else {
            isWriting = false
            completion(NSError(
                domain: "com.traisender.recorder",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "No se encontró un micrófono disponible."]
            ))
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: mic) else {
            isWriting = false
            completion(NSError(
                domain: "com.traisender.recorder",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo inicializar el micrófono."]
            ))
            return
        }
        
        if micSession?.canAddInput(input) == true {
            micSession?.addInput(input)
        } else {
            isWriting = false
            completion(NSError(
                domain: "com.traisender.recorder",
                code: 1005,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo agregar entrada de micrófono."]
            ))
            return
        }
        
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.traisender.mic"))
        if micSession?.canAddOutput(output) == true {
            micSession?.addOutput(output)
        } else {
            isWriting = false
            completion(NSError(
                domain: "com.traisender.recorder",
                code: 1006,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo agregar salida de audio."]
            ))
            return
        }
        
        micSession?.startRunning()
        completion(nil)
    }
    
    func stop(completion: @escaping (String?) -> Void) {
        micSession?.stopRunning()
        micSession = nil

        guard isWriting else {
            completion(nil)
            return
        }

        guard hasWrittenBuffer else {
            isWriting = false
            assetWriter?.cancelWriting()
            if let outputPath {
                try? FileManager.default.removeItem(atPath: outputPath)
            }
            completion(nil)
            return
        }
        
        audioInput?.markAsFinished()
        assetWriter?.finishWriting { [self] in
            isWriting = false
            completion(assetWriter?.outputURL.path)
        }
    }
    
    var isRecording: Bool {
        return isWriting
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isWriting else { return }
        processBuffer(sampleBuffer)
    }
    
    private func processBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let audioInput = audioInput, audioInput.isReadyForMoreMediaData else { return }
        
        if startTime == nil {
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            assetWriter?.startSession(atSourceTime: startTime!)
        }

        if audioInput.append(sampleBuffer) {
            hasWrittenBuffer = true
        }
    }
}
