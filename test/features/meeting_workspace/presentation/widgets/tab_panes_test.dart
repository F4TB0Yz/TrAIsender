import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/tab_panes.dart';

void main() {
  const historyItem = MeetingHistoryItem(
    id: 1,
    title: 'Sesion demo',
    date: '2026-04-20',
    length: '22 min',
    transcript: 'Texto transcripcion',
    summary: 'Resumen corto',
  );

  Future<void> pumpPane(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MacosApp(
        home: Material(
          child: Center(child: SizedBox(width: 900, child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('tab panes', () {
    testWidgets('record pane dispara callbacks de audio y grabacion', (
      tester,
    ) async {
      AudioSource? selectedSource;
      var toggledRecording = false;

      await pumpPane(
        tester,
        MeetingWorkspaceRecordPane(
          state: const RecordPaneState(
            audioSource: AudioSource.mic,
            isRecording: false,
            recordTime: 0,
            liveTranscript: '',
          ),
          formatTime: (seconds) => '00:00',
          callbacks: RecordPaneCallbacks(
            onSetAudioSource: (source) => selectedSource = source,
            onToggleRecording: () => toggledRecording = true,
          ),
        ),
      );

      await tester.tap(find.text('Mic + Audio del Sistema'));
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));

      expect(selectedSource, AudioSource.system);
      expect(toggledRecording, isTrue);
    });

    testWidgets('upload pane dispara callback de iniciar carga', (tester) async {
      var startedUpload = false;

      await pumpPane(
        tester,
        MeetingWorkspaceUploadPane(
          state: const UploadPaneState(
            isUploading: false,
            uploadProgress: 0,
            uploadFileName: '',
          ),
          callbacks: UploadPaneCallbacks(
            onStartUpload: () => startedUpload = true,
            onDroppedFile: (_) async {},
          ),
        ),
      );

      await tester.tap(find.text('Explorar archivos'));
      expect(startedUpload, isTrue);
    });

    testWidgets('history pane dispara callbacks de detalle y tabs', (tester) async {
      MeetingHistoryItem? openedItem;
      HistoryDetailTab? selectedDetailTab;

      await pumpPane(
        tester,
        MeetingWorkspaceHistoryPane(
          state: const HistoryPaneState(
            history: [historyItem],
            selectedMeeting: null,
            historyDetailTab: HistoryDetailTab.transcript,
            aiResult: '',
            isAiLoading: false,
            aiError: '',
          ),
          callbacks: HistoryPaneCallbacks(
            onOpenMeeting: (item) => openedItem = item,
            onCloseMeeting: () {},
            onSetHistoryDetailTab: (tab) => selectedDetailTab = tab,
            onRetrySummary: () async {},
          ),
        ),
      );

      await tester.tap(find.text('Sesion demo'));
      expect(openedItem?.id, 1);

      await pumpPane(
        tester,
        MeetingWorkspaceHistoryPane(
          state: const HistoryPaneState(
            history: [historyItem],
            selectedMeeting: historyItem,
            historyDetailTab: HistoryDetailTab.transcript,
            aiResult: '',
            isAiLoading: false,
            aiError: '',
          ),
          callbacks: HistoryPaneCallbacks(
            onOpenMeeting: (_) {},
            onCloseMeeting: () {},
            onSetHistoryDetailTab: (tab) => selectedDetailTab = tab,
            onRetrySummary: () async {},
          ),
        ),
      );

      await tester.tap(find.text('Resumen IA'));
      expect(selectedDetailTab, HistoryDetailTab.summary);
    });
  });
}
