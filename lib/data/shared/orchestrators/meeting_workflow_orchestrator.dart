import 'package:traisender/domain/shared/entities/app_status.dart';
import 'package:traisender/data/shared/services/gemini_service.dart';
import 'package:traisender/data/shared/services/recorder_service.dart';
import 'package:traisender/data/shared/services/transcription_service.dart';

typedef StatusUpdater =
    void Function(AppStatus status, {String text, String transcription});
typedef ProgressUpdater = void Function(double progress, {String label});
typedef PartialSummaryUpdater = void Function(String partial);
typedef NotificationDispatcher =
    void Function({
      required String title,
      required String body,
      required bool focusWindow,
    });
typedef RefreshMenu = Future<void> Function();

class MeetingWorkflowOrchestrator {
  final RecorderService _recorder;
  final TranscriptionService _transcription;
  final GeminiService _gemini;
  final StatusUpdater _updateStatus;
  final ProgressUpdater _updateProgress;
  final PartialSummaryUpdater _updatePartialSummary;
  final NotificationDispatcher _notify;
  final RefreshMenu _refreshMenu;

  MeetingWorkflowOrchestrator({
    required RecorderService recorder,
    required TranscriptionService transcription,
    required GeminiService gemini,
    required StatusUpdater updateStatus,
    required ProgressUpdater updateProgress,
    required PartialSummaryUpdater updatePartialSummary,
    required NotificationDispatcher notify,
    required RefreshMenu refreshMenu,
  }) : _recorder = recorder,
       _transcription = transcription,
       _gemini = gemini,
       _updateStatus = updateStatus,
       _updateProgress = updateProgress,
       _updatePartialSummary = updatePartialSummary,
       _notify = notify,
       _refreshMenu = refreshMenu;

  Future<void> toggleRecording({required bool includeMic}) async {
    final recording = await _recorder.isRecording();
    if (recording) {
      final path = await _recorder.stopRecording();
      if (path != null) {
        await processAudioFile(path);
      } else {
        _updateStatus(AppStatus.idle);
        await _refreshMenu();
      }
      return;
    }

    try {
      _updateStatus(AppStatus.recording);
      await _refreshMenu();
      await _recorder.startRecording(includeMic: includeMic);
    } catch (_) {
      _updateStatus(AppStatus.idle);
      await _refreshMenu();
    }
  }

  Future<void> processAudioFile(String path) async {
    _updateStatus(AppStatus.transcribing);
    await _refreshMenu();

    final text = await _transcription.transcribe(
      path,
      onProgress: (progress, label) {
        _updateProgress(progress, label: label);
      },
    );

    if (text == null || text.isEmpty) {
      _updateStatus(AppStatus.error, text: 'Error en transcripción.');
      await _refreshMenu();
      return;
    }

    _updateStatus(AppStatus.summarizing, transcription: text);
    await _refreshMenu();

    final result = await _gemini.summarizeMeeting(
      text,
      onPartialText: (partial) {
        _updateProgress(0.0, label: 'Generando resumen...');
        _updatePartialSummary(partial);
      },
    );

    if (result.ok) {
      _updateStatus(AppStatus.completed, text: result.text ?? '');
      _notify(
        title: 'Resumen Listo',
        body: 'Resumen disponible en el Dashboard.',
        focusWindow: true,
      );
    } else {
      _updateStatus(AppStatus.error, text: result.error?.message ?? 'Error.');
      _notify(
        title: 'Error',
        body: 'No se pudo generar el resumen.',
        focusWindow: false,
      );
    }

    await _refreshMenu();
  }
}
