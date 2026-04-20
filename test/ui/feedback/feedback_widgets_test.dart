import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/application/app_status.dart';
import 'package:traisender/domain/history_item.dart';
import 'package:traisender/ui/feedback/feedback_view_state.dart';
import 'package:traisender/ui/feedback/widgets/feedback_history_sidebar.dart';
import 'package:traisender/ui/feedback/widgets/feedback_main_content.dart';
import 'package:traisender/ui/feedback/widgets/feedback_top_controls.dart';

void main() {
  group('FeedbackMainContent', () {
    testWidgets('muestra empty state en idle sin contenido', (tester) async {
      await _pumpMainContent(tester, viewState: _state());

      expect(find.text('Arrastra un audio o video'), findsOneWidget);
      expect(find.text('— o — Seleccionar archivo'), findsOneWidget);
    });

    testWidgets('muestra estado de transcripción con progreso', (tester) async {
      await _pumpMainContent(
        tester,
        viewState: _state(
          status: AppStatus.transcribing,
          progress: 0.42,
          progressLabel: 'Procesando segmento 2/5',
        ),
      );

      expect(find.text('TRANSCRIBIENDO'), findsOneWidget);
      expect(find.text('Procesando segmento 2/5'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('muestra estado de resumen con resumen parcial', (
      tester,
    ) async {
      await _pumpMainContent(
        tester,
        viewState: _state(
          status: AppStatus.summarizing,
          text: 'Puntos clave parciales',
          progressLabel: 'Generando conclusiones',
        ),
      );

      expect(find.text('IA ANALIZANDO'), findsOneWidget);
      expect(find.text('Generando conclusiones'), findsOneWidget);
      expect(
        find.textContaining('Puntos clave parciales', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('muestra sesión de historial cuando hay item seleccionado', (
      tester,
    ) async {
      final item = HistoryItem(
        date: '2026-01-15 10:00:00',
        summary: 'Resumen histórico',
        transcription: 'Transcripción histórica',
      );

      await _pumpMainContent(
        tester,
        viewState: _state(
          status: AppStatus.completed,
          history: [item],
          viewingItem: item,
        ),
      );

      expect(find.text('Sesión del 2026-01-15 10:00:00'), findsOneWidget);
      expect(find.text('RESUMEN IA'), findsOneWidget);
      expect(find.text('TRANSCRIPCIÓN'), findsOneWidget);
      expect(find.text('Resumen histórico'), findsOneWidget);
    });
  });

  group('FeedbackTopControls', () {
    testWidgets('muestra acciones principales visibles', (tester) async {
      await tester.pumpWidget(
        MacosApp(
          home: MacosWindow(
            child: FeedbackTopControls(
              isBusy: false,
              status: AppStatus.idle,
              isRecording: false,
              micEnabled: true,
              statusLabel: 'Listo',
              statusColor: MacosColors.systemGreenColor,
              progress: 0,
              onToggleRecording: () {},
              onPickFile: () {},
              onToggleMic: () {},
            ),
          ),
        ),
      );

      expect(find.text('● GRABAR'), findsOneWidget);
      expect(find.text('Archivo'), findsOneWidget);
      expect(find.text('MIC'), findsOneWidget);
      expect(find.text('Listo'), findsOneWidget);
      expect(find.byType(MacosCheckbox), findsNothing);
    });
  });

  group('FeedbackHistoryRail', () {
    testWidgets('muestra label y hora compacta', (tester) async {
      final items = [
        HistoryItem(
          date: '2026-01-15 14:32:01',
          summary: 'Resumen de sesión',
          transcription: 'Transcripción',
        ),
      ];

      await tester.pumpWidget(
        MacosApp(
          home: MacosWindow(
            child: SizedBox(
              width: 500,
              height: 120,
              child: FeedbackHistoryRail(
                history: items,
                viewingItem: null,
                onSelectItem: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HISTORIAL'), findsOneWidget);
      expect(find.text('14:32:01'), findsOneWidget);
      expect(find.text('Resumen de sesión'), findsOneWidget);
    });

    testWidgets('dispara selección al tocar un item', (tester) async {
      final item = HistoryItem(
        date: '2026-01-15 14:32:01',
        summary: 'Resumen de sesión',
        transcription: 'Transcripción',
      );
      HistoryItem? selected;

      await tester.pumpWidget(
        MacosApp(
          home: MacosWindow(
            child: SizedBox(
              width: 500,
              height: 120,
              child: FeedbackHistoryRail(
                history: [item],
                viewingItem: null,
                onSelectItem: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resumen de sesión'));
      await tester.pumpAndSettle();

      expect(selected, item);
    });
  });
}

Future<void> _pumpMainContent(
  WidgetTester tester, {
  required FeedbackViewState viewState,
}) async {
  await tester.pumpWidget(
    MacosApp(
      home: MacosWindow(
        child: SizedBox(
          width: 1000,
          height: 700,
          child: FeedbackMainContent(
            viewState: viewState,
            isDragging: false,
            selectedTab: 0,
            onTabChanged: (_) {},
            onCloseHistoryView: () {},
            onPickFile: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FeedbackViewState _state({
  AppStatus status = AppStatus.idle,
  String text = '',
  String transcription = '',
  bool isRecording = false,
  bool micEnabled = true,
  List<HistoryItem> history = const [],
  double progress = 0,
  String progressLabel = '',
  HistoryItem? viewingItem,
}) {
  return FeedbackViewState(
    status: status,
    text: text,
    transcription: transcription,
    isRecording: isRecording,
    micEnabled: micEnabled,
    history: history,
    progress: progress,
    progressLabel: progressLabel,
    viewingItem: viewingItem,
  );
}
