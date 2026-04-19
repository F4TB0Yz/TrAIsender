import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:traisender/services/recorder_service.dart';
import 'package:traisender/services/transcription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar bandeja del sistema
  final SystemTray systemTray = SystemTray();
  final RecorderService recorder = RecorderService();
  final TranscriptionService transcription = TranscriptionService();

  // Inicializar Whisper en segundo plano
  transcription.init().catchError((e) => print('Whisper init error: $e'));

  bool micEnabled = true;

  // Para actualizar menu dinamicamente
  Future<void> updateMenu() async {
    bool recording = await recorder.isRecording();

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemCheckbox(
        label: '🎙️ Detectar micrófono',
        checked: micEnabled,
        onClicked: (menuItem) async {
          micEnabled = !micEnabled;
          await updateMenu();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: recording ? 'Detener Grabación' : 'Grabar Reunión',
        onClicked: (menuItem) async {
          if (recording) {
            String? path = await recorder.stopRecording();
            if (path != null) {
              print("Iniciando transcripción: $path");
              final text = await transcription.transcribe(path);
              if (text != null) {
                print("Transcripción completada:\n$text");
                // Aquí podrías guardar el texto en un archivo o mostrarlo
              }
            }
          } else {
            try {
              await recorder.startRecording(
                includeMic: micEnabled,
              );
            } catch (e) {
              // Error visual ya mostrado por NSAlert nativo en Swift
              print('Error grabación: $e');
            }
          }
          await updateMenu();
        },
      ),
      MenuItemLabel(label: 'Salir', onClicked: (menuItem) => exit(0)),
    ]);

    await systemTray.setContextMenu(menu);
  }

  await systemTray.initSystemTray(iconPath: 'assets/app_icon.webp');

  await updateMenu();

  // Manejar eventos de click en el icono de la bandeja
  systemTray.registerSystemTrayEventHandler((String eventName) {
    if (eventName == kSystemTrayEventClick ||
        eventName == kSystemTrayEventRightClick) {
      systemTray.popUpContextMenu();
    }
  });

  runApp(const SizedBox.shrink());
}
