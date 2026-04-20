import 'dart:io';

import 'package:flutter/cupertino.dart' show Size;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:system_tray/system_tray.dart';
import 'package:traisender/application/meeting_workflow_orchestrator.dart';
import 'package:traisender/application/status_controller.dart';
import 'package:traisender/infrastructure/notification_service.dart';
import 'package:traisender/infrastructure/tray_controller.dart';
import 'package:traisender/services/gemini_service.dart';
import 'package:traisender/services/recorder_service.dart';
import 'package:traisender/services/transcription_service.dart';
import 'package:window_manager/window_manager.dart';

class AppBootstrap {
  Future<void> start(StatusController statusController) async {
    try {
      await dotenv.load(fileName: ".env").catchError((e) {
        print('DotEnv load error: $e');
      });

      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(800, 600),
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

      final recorder = RecorderService();
      final transcription = TranscriptionService();
      final gemini = GeminiService();
      final notifications = NotificationService();

      transcription.init().catchError((e) => print('Whisper init error: $e'));
      gemini.init().catchError((e) => print('Gemini init error: $e'));
      await notifications.init();

      late TrayController trayController;
      final workflow = MeetingWorkflowOrchestrator(
        recorder: recorder,
        transcription: transcription,
        gemini: gemini,
        updateStatus: statusController.updateStatus,
        updateProgress: statusController.updateProgress,
        updatePartialSummary: statusController.updatePartialSummary,
        notify: notifications.show,
        refreshMenu: () => trayController.refreshMenu(),
      );

      trayController = TrayController(
        statusProvider: () => statusController.status,
        micEnabledProvider: () => statusController.micEnabled,
        isRecordingProvider: recorder.isRecording,
        onToggleRecording: () =>
            workflow.toggleRecording(includeMic: statusController.micEnabled),
        onSetMicEnabled: statusController.setMicEnabled,
        onOpenDashboard: windowManager.show,
        onExit: () => exit(0),
        systemTray: SystemTray(),
      );
      await trayController.init();

      statusController.onProcessAudio = workflow.processAudioFile;
      statusController.onToggleRecording = () =>
          workflow.toggleRecording(includeMic: statusController.micEnabled);
      statusController.onToggleMic = (enabled) async =>
          trayController.refreshMenu();
      statusController.addListener(() => trayController.refreshMenu());
      await trayController.refreshMenu();
    } catch (e) {
      print('Critical initialization error: $e');
    }
  }
}
