import Cocoa
import FlutterMacOS
import AVFoundation
import ScreenCaptureKit
import macos_window_utils

@main
class AppDelegate: FlutterAppDelegate {
    var recorderManager: AudioRecorderManager?

    private static func isPermissionRelated(_ error: Error) -> Bool {
        let nsError = error as NSError
        let domain = nsError.domain.lowercased()
        let message = nsError.localizedDescription.lowercased()

        if nsError.code == 1 { return true }
        if domain.contains("tcc") || domain.contains("avaudio") || domain.contains("avcapture") || domain.contains("screencapture") { return true }
        if message.contains("tcc") || message.contains("rechaz") || message.contains("deneg") || message.contains("microphone") || message.contains("micrófono") { return true }

        return false
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        guard let macOSWindowUtilsVC = mainFlutterWindow?.contentViewController as? MacOSWindowUtilsViewController else {
            print("❌ No se encontró MacOSWindowUtilsViewController")
            return
        }
        let flutterVC = macOSWindowUtilsVC.flutterViewController

        let channel = FlutterMethodChannel(
            name: "com.traisender/recorder", 
            binaryMessenger: flutterVC.engine.binaryMessenger
        )

        recorderManager = AudioRecorderManager()
        
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "start":
                guard let args = call.arguments as? [String: Any],
                      let path = args["path"] as? String,
                      let includeMic = args["includeMic"] as? Bool else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing path or includeMic", details: nil))
                    return
                }
                
                let includeSystemAudio = args["includeSystemAudio"] as? Bool ?? true
                
                // CORRECCIÓN 1: Aquí agregamos el parámetro faltante 'includeSystemAudio'
                self?.recorderManager?.start(path: path, includeMic: includeMic, includeSystemAudio: includeSystemAudio) { error in
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

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = mainFlutterWindow {
            window.alphaValue = 1.0
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    static func showError(title: String, message: String, showSettingsButton: Bool = false) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .critical
            
            if let iconPath = Bundle.main.path(forResource: "app_icon", ofType: "webp", inDirectory: "flutter_assets/assets"),
               let icon = NSImage(contentsOfFile: iconPath) {
                alert.icon = icon
            }
            
            if showSettingsButton {
                alert.addButton(withTitle: "Abrir Ajustes")
                alert.addButton(withTitle: "Cancelar")
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
                }
            } else {
                alert.addButton(withTitle: "Entendido")
                alert.runModal()
            }
        }
    }
}

// CORRECCIÓN 2: Agregamos '@unchecked Sendable' para evitar la advertencia de concurrencia
class AudioRecorderManager: NSObject, SCStreamDelegate, SCStreamOutput, @unchecked Sendable {
    private var assetWriter: AVAssetWriter?
    private var audioInput: AVAssetWriterInput?
    private var isWriting = false
    private var selectedOutputType: SCStreamOutputType = .audio
    
    private var stream: SCStream?
    
    private var hasWrittenBuffer = false
    private var outputPath: String?
    private var startTime: CMTime?
    
    func start(path: String, includeMic: Bool, includeSystemAudio: Bool, completion: @escaping (Error?) -> Void) {
        let url = URL(fileURLWithPath: path)
        outputPath = path
        
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                let resolvedIncludeMic = includeMic && granted
                // Evita mezclar buffers .audio/.microphone en una sola pista AAC, causa archivos inválidos o 0:00.
                let resolvedIncludeSystemAudio = includeSystemAudio && !resolvedIncludeMic

                if includeMic && !granted && !resolvedIncludeSystemAudio {
                    let error = NSError(
                        domain: "com.traisender.recorder",
                        code: 1008,
                        userInfo: [NSLocalizedDescriptionKey: "Permiso de micrófono denegado"]
                    )
                    completion(error)
                    return
                }

                if !resolvedIncludeMic && !resolvedIncludeSystemAudio {
                    let error = NSError(
                        domain: "com.traisender.recorder",
                        code: 1009,
                        userInfo: [NSLocalizedDescriptionKey: "No hay fuente de audio habilitada para grabar"]
                    )
                    completion(error)
                    return
                }

                self.selectedOutputType = resolvedIncludeMic ? .microphone : .audio

                do {
                    self.assetWriter = try AVAssetWriter(outputURL: url, fileType: .wav)
                    
                    self.isWriting = true
                    self.hasWrittenBuffer = false
                    self.startTime = nil
                    self.audioInput = nil // Creado on-demand

                    self.startScreenCaptureKit(includeMic: resolvedIncludeMic, includeSystemAudio: resolvedIncludeSystemAudio, completion: completion)
                } catch {
                    self.isWriting = false
                    completion(error)
                }
            }
        }
    }
    
    private func startScreenCaptureKit(includeMic: Bool, includeSystemAudio: Bool, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                // CORRECCIÓN 3: ScreenCaptureKit exige anclar el filtro a un contenido válido. 
                // Buscamos la pantalla principal.
                let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = availableContent.displays.first else {
                    throw NSError(domain: "com.traisender.recorder", code: 1007, userInfo: [NSLocalizedDescriptionKey: "No se encontró pantalla para anclar la captura de audio"])
                }
                
                // Inicializamos el filtro con la pantalla obtenida
                let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
                
                let config = SCStreamConfiguration()
                config.capturesAudio = includeSystemAudio || includeMic
                config.captureMicrophone = includeMic
                config.excludesCurrentProcessAudio = false 
                
                let newStream = SCStream(filter: filter, configuration: config, delegate: self)
                
                let audioQueue = DispatchQueue(label: "com.traisender.audioQueue")
                if includeSystemAudio {
                    try newStream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
                }
                if includeMic {
                    try newStream.addStreamOutput(self, type: .microphone, sampleHandlerQueue: audioQueue)
                }
                
                try await newStream.startCapture()
                
                self.stream = newStream
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isWriting = false
                    completion(error)
                }
            }
        }
    }
    
    func stop(completion: @escaping (String?) -> Void) {
        Task {
            do {
                try await stream?.stopCapture()
            } catch {
                print("Error al detener SCStream: \(error)")
            }
            stream = nil
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                guard self.isWriting else {
                    completion(nil)
                    return
                }

                guard self.hasWrittenBuffer else {
                    self.isWriting = false
                    self.assetWriter?.cancelWriting()
                    if let outputPath = self.outputPath {
                        try? FileManager.default.removeItem(atPath: outputPath)
                    }
                    completion(nil)
                    return
                }
                
                self.audioInput?.markAsFinished()
                self.assetWriter?.finishWriting {
                    self.isWriting = false
                    completion(self.assetWriter?.outputURL.path)
                }
            }
        }
    }
    
    var isRecording: Bool {
        return isWriting
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard isWriting else { return }
        guard type == selectedOutputType else { return }
        processBuffer(sampleBuffer)
    }
    
    private func processBuffer(_ sampleBuffer: CMSampleBuffer) {
        if audioInput == nil {
            guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings, sourceFormatHint: formatDesc)
            input.expectsMediaDataInRealTime = true
            
            if assetWriter?.canAdd(input) == true {
                assetWriter?.add(input)
            }
            audioInput = input
            assetWriter?.startWriting()
            
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            assetWriter?.startSession(atSourceTime: startTime!)
        }
        
        guard let audioInput = audioInput, audioInput.isReadyForMoreMediaData else { return }

        if audioInput.append(sampleBuffer) {
            hasWrittenBuffer = true
        }
    }
}