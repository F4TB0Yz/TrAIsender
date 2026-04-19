import 'dart:io';
import 'package:flutter/material.dart' show Colors, ThemeMode;
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:traisender/services/recorder_service.dart';
import 'package:traisender/services/transcription_service.dart';
import 'package:traisender/services/gemini_service.dart';
import 'package:traisender/ui/feedback_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar utilidades de ventana para efectos nativos
  await WindowManipulator.initialize();

  final StatusController statusController = StatusController();

  runApp(MacosApp(
    debugShowCheckedModeBanner: false,
    theme: MacosThemeData.light(),
    darkTheme: MacosThemeData.dark(),
    themeMode: ThemeMode.system,
    home: FeedbackWindow(controller: statusController),
  ));

  _initAppServices(statusController);
}

Future<void> _initAppServices(StatusController statusController) async {
  try {
    await dotenv.load(fileName: ".env").catchError((e) {
      print('DotEnv load error: $e');
    });

    await windowManager.ensureInitialized();
    
    // Aplicar efectos visuales nativos (Vibrancy/Cristal)
    await WindowManipulator.makeTitlebarTransparent();
    await WindowManipulator.enableFullSizeContentView();
    await WindowManipulator.addMaterial(
      material: NSVisualEffectViewMaterial.underWindowBackground,
    );

    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600), // Ventana más grande para el Dashboard
      minimumSize: Size(600, 500),
      center: true,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: false,
      backgroundColor: Colors.transparent,
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setOpacity(1.0);
      await windowManager.show();
      await windowManager.focus();
    });

    await localNotifier.setup(
      appName: 'TrAIsender',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );

    final RecorderService recorder = RecorderService();
    final TranscriptionService transcription = TranscriptionService();
    final GeminiService gemini = GeminiService();
    final SystemTray systemTray = SystemTray();

    transcription.init().catchError((e) => print('Whisper init error: $e'));
    gemini.init().catchError((e) => print('Gemini init error: $e'));

    await systemTray.initSystemTray(iconPath: 'assets/app_icon.webp');

    late Future<void> Function() updateMenu;
    late Future<void> Function(String) processAudioFile;
    late Future<void> Function() toggleRecording;

    toggleRecording = () async {
      bool recording = await recorder.isRecording();
      if (recording) {
        String? path = await recorder.stopRecording();
        if (path != null) {
          await processAudioFile(path);
        } else {
          statusController.updateStatus(AppStatus.idle);
          await updateMenu();
        }
      } else {
        try {
          statusController.updateStatus(AppStatus.recording);
          await updateMenu();
          await recorder.startRecording(includeMic: statusController.micEnabled);
        } catch (e) {
          print('Error grabación: $e');
          statusController.updateStatus(AppStatus.idle);
          await updateMenu();
        }
      }
    };

    updateMenu = () async {
      bool recording = await recorder.isRecording();
      String statusLabel = 'TrAIsender';
      
      switch (statusController.status) {
        case AppStatus.recording: statusLabel = '🔴 Grabando...'; break;
        case AppStatus.transcribing: statusLabel = '⏳ Transcribiendo...'; break;
        case AppStatus.summarizing: statusLabel = '🧠 Analizando...'; break;
        case AppStatus.error: statusLabel = '⚠️ Error'; break;
        default: if (recording) statusLabel = '🔴 Grabando...';
      }

      final Menu menu = Menu();
      await menu.buildFrom([
        MenuItemLabel(label: statusLabel, enabled: false),
        MenuSeparator(),
        MenuItemCheckbox(
          label: '🎙️ Detectar micrófono',
          checked: statusController.micEnabled,
          onClicked: (menuItem) async {
            statusController.setMicEnabled(!statusController.micEnabled);
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: recording ? 'Detener Grabación' : 'Grabar Reunión',
          onClicked: (menuItem) async => await toggleRecording(),
        ),
        MenuItemLabel(
          label: 'Abrir Dashboard',
          onClicked: (_) => windowManager.show(),
        ),
        MenuSeparator(),
        MenuItemLabel(label: 'Salir', onClicked: (menuItem) => exit(0)),
      ]);

      await systemTray.setContextMenu(menu);
    };

    processAudioFile = (String path) async {
      print("Procesando: $path");
      statusController.updateStatus(AppStatus.transcribing);
      await updateMenu();

      final text = await transcription.transcribe(path);
      
      if (text != null && text.isNotEmpty) {
        statusController.updateStatus(AppStatus.summarizing, transcription: text);
        await updateMenu();

        final result = await gemini.summarizeMeeting(text);
        if (result.ok) {
          statusController.updateStatus(AppStatus.completed, text: result.text!);
          _showNotification(title: 'Resumen Listo', body: 'Resumen disponible en el Dashboard.', focusWindow: true);
        } else {
          statusController.updateStatus(AppStatus.error, text: result.error?.message ?? 'Error.');
          _showNotification(title: 'Error', body: 'No se pudo generar el resumen.', focusWindow: false);
        }
      } else {
        statusController.updateStatus(AppStatus.error, text: 'Error en transcripción.');
      }
      await updateMenu();
    };

    statusController.onProcessAudio = processAudioFile;
    statusController.onToggleRecording = toggleRecording;
    statusController.onToggleMic = (enabled) async => await updateMenu();
    statusController.addListener(() => updateMenu());

    systemTray.registerSystemTrayEventHandler((String eventName) {
      if (eventName == kSystemTrayEventClick || eventName == kSystemTrayEventRightClick) {
        systemTray.popUpContextMenu();
      }
    });

    await updateMenu();
    
  } catch (e) {
    print('Critical initialization error: $e');
  }
}

void _showNotification({
  required String title,
  required String body,
  required bool focusWindow,
}) {
  LocalNotification notification = LocalNotification(
    title: title,
    body: body,
    actions: [LocalNotificationAction(text: 'Ver')],
  );
  notification.onClick = () {
    if (focusWindow) windowManager.show();
  };
  notification.show();
}
