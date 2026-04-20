import 'package:flutter_test/flutter_test.dart';
import 'package:traisender/features/meeting_workspace/data/repositories/meeting_workspace_mock_history_repository.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_controller.dart';

void main() {
  const repository = MeetingWorkspaceMockHistoryRepository();

  group('MeetingWorkspaceController', () {
    test('starts and stops recording state', () {
      final controller = MeetingWorkspaceController(historyRepository: repository);

      expect(controller.state.isRecording, isFalse);
      expect(controller.state.recordTime, 0);

      controller.toggleRecording();

      expect(controller.state.isRecording, isTrue);
      expect(controller.state.recordTime, 0);

      controller.toggleRecording();

      expect(controller.state.isRecording, isFalse);
      controller.dispose();
    });

    test('upload mock updates progress over time', () async {
      final controller = MeetingWorkspaceController(historyRepository: repository);

      controller.startFakeUpload();

      expect(controller.state.isUploading, isTrue);
      expect(controller.state.uploadFileName, 'reunion_ventas_q3.mp4');

      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(controller.state.uploadProgress, greaterThan(0));
      controller.dispose();
    });

    test('summary mock returns error for item id 2', () async {
      final controller = MeetingWorkspaceController(historyRepository: repository);
      final target = controller.state.history.firstWhere((item) => item.id == 2);

      controller.openMeeting(target);
      controller.setHistoryDetailTab(HistoryDetailTab.summary);

      expect(controller.state.isAiLoading, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 2200));

      expect(controller.state.isAiLoading, isFalse);
      expect(controller.state.aiError, isNotEmpty);
      expect(controller.state.aiResult, isEmpty);
      controller.dispose();
    });

    test('summary mock returns content for non-error item', () async {
      final controller = MeetingWorkspaceController(historyRepository: repository);
      final target = controller.state.history.firstWhere((item) => item.id == 1);

      controller.openMeeting(target);
      controller.setHistoryDetailTab(HistoryDetailTab.summary);

      await Future<void>.delayed(const Duration(milliseconds: 2200));

      expect(controller.state.isAiLoading, isFalse);
      expect(controller.state.aiError, isEmpty);
      expect(controller.state.aiResult, contains('Resumen ejecutivo'));
      controller.dispose();
    });
  });
}
