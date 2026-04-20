import 'package:flutter_test/flutter_test.dart';
import 'package:traisender/application/app_status.dart';
import 'package:traisender/application/meeting_workflow_orchestrator.dart';
import 'package:traisender/services/gemini_service.dart';
import 'package:traisender/services/recorder_service.dart';
import 'package:traisender/services/transcription_service.dart';

void main() {
  group('MeetingWorkflowOrchestrator', () {
    test('toggleRecording inicia grabación cuando no está grabando', () async {
      final recorder = _FakeRecorderService(initiallyRecording: false);
      final transcription = _FakeTranscriptionService(result: 'texto');
      final gemini = _FakeGeminiService(
        result: GeminiResult.success('resumen'),
      );
      final statuses = <AppStatus>[];

      final orchestrator = MeetingWorkflowOrchestrator(
        recorder: recorder,
        transcription: transcription,
        gemini: gemini,
        updateStatus: (status, {text = '', transcription = ''}) {
          statuses.add(status);
        },
        updateProgress: (_, {label = ''}) {},
        updatePartialSummary: (_) {},
        notify: ({required title, required body, required focusWindow}) {},
        refreshMenu: () async {},
      );

      await orchestrator.toggleRecording(includeMic: true);

      expect(recorder.startCalls, 1);
      expect(statuses, contains(AppStatus.recording));
    });

    test('processAudioFile completa flujo exitoso', () async {
      final recorder = _FakeRecorderService(initiallyRecording: false);
      final transcription = _FakeTranscriptionService(
        result: 'texto transcrito',
      );
      final gemini = _FakeGeminiService(
        result: GeminiResult.success('resumen IA'),
      );
      final statuses = <AppStatus>[];
      var notificationFocus = false;

      final orchestrator = MeetingWorkflowOrchestrator(
        recorder: recorder,
        transcription: transcription,
        gemini: gemini,
        updateStatus: (status, {text = '', transcription = ''}) {
          statuses.add(status);
        },
        updateProgress: (_, {label = ''}) {},
        updatePartialSummary: (_) {},
        notify: ({required title, required body, required focusWindow}) {
          notificationFocus = focusWindow;
        },
        refreshMenu: () async {},
      );

      await orchestrator.processAudioFile('/tmp/audio.wav');

      expect(
        statuses,
        containsAllInOrder([
          AppStatus.transcribing,
          AppStatus.summarizing,
          AppStatus.completed,
        ]),
      );
      expect(notificationFocus, isTrue);
    });

    test('processAudioFile marca error si transcripción falla', () async {
      final recorder = _FakeRecorderService(initiallyRecording: false);
      final transcription = _FakeTranscriptionService(result: null);
      final gemini = _FakeGeminiService(
        result: GeminiResult.success('resumen IA'),
      );
      final statuses = <AppStatus>[];

      final orchestrator = MeetingWorkflowOrchestrator(
        recorder: recorder,
        transcription: transcription,
        gemini: gemini,
        updateStatus: (status, {text = '', transcription = ''}) {
          statuses.add(status);
        },
        updateProgress: (_, {label = ''}) {},
        updatePartialSummary: (_) {},
        notify: ({required title, required body, required focusWindow}) {},
        refreshMenu: () async {},
      );

      await orchestrator.processAudioFile('/tmp/audio.wav');

      expect(
        statuses,
        containsAllInOrder([AppStatus.transcribing, AppStatus.error]),
      );
    });
  });
}

class _FakeRecorderService extends RecorderService {
  bool _recording;
  int startCalls = 0;

  _FakeRecorderService({required bool initiallyRecording})
    : _recording = initiallyRecording;

  @override
  Future<bool> isRecording() async => _recording;

  @override
  Future<void> startRecording({required bool includeMic}) async {
    startCalls += 1;
    _recording = true;
  }

  @override
  Future<String?> stopRecording() async {
    _recording = false;
    return '/tmp/audio.wav';
  }
}

class _FakeTranscriptionService extends TranscriptionService {
  final String? result;

  _FakeTranscriptionService({required this.result});

  @override
  Future<String?> transcribe(
    String audioPath, {
    void Function(double progress, String label)? onProgress,
  }) async {
    return result;
  }
}

class _FakeGeminiService extends GeminiService {
  final GeminiResult result;

  _FakeGeminiService({required this.result});

  @override
  Future<GeminiResult> summarizeMeeting(
    String transcription, {
    void Function(String partialText)? onPartialText,
  }) async {
    return result;
  }
}
