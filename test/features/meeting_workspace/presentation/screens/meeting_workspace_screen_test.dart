import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/features/meeting_workspace/meeting_workspace_feature.dart';

void main() {
  Future<void> pumpWorkspace(WidgetTester tester) async {
    await tester.pumpWidget(
      MacosApp(home: const MeetingWorkspaceFeature()),
    );
    await tester.pumpAndSettle();
  }

  group('MeetingWorkspaceScreen', () {
    testWidgets('renderiza vista grabacion por defecto', (tester) async {
      await pumpWorkspace(tester);

      expect(find.text('Nueva Transcripcion'), findsOneWidget);
      expect(find.text('TEXTO EN VIVO'), findsOneWidget);
    });

    testWidgets('navega a archivo e historial', (tester) async {
      await pumpWorkspace(tester);

      await tester.tap(find.text('Archivo').first);
      await tester.pumpAndSettle();
      expect(find.text('Arrastra tu archivo aqui'), findsOneWidget);

      await tester.tap(find.text('Historial').first);
      await tester.pumpAndSettle();
      expect(find.text('Documentos Anteriores'), findsOneWidget);
      expect(find.text('Entrevista Equipo Tech'), findsOneWidget);
    });

    testWidgets('abre detalle historial y vuelve', (tester) async {
      await pumpWorkspace(tester);

      await tester.tap(find.text('Historial').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrevista Equipo Tech').first);
      await tester.pumpAndSettle();
      expect(find.text('Detalle de Reunion'), findsOneWidget);
      expect(find.text('Volver al historial'), findsOneWidget);

      await tester.tap(find.text('Volver al historial').first);
      await tester.pumpAndSettle();
      expect(find.text('Documentos Anteriores'), findsOneWidget);
    });

    testWidgets('resumen IA muestra loading y error con opcion reintento', (
      tester,
    ) async {
      await pumpWorkspace(tester);

      await tester.tap(find.text('Historial').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lluvia de ideas UX').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resumen IA').first);
      await tester.pump();

      expect(find.text('Analizando la reunion con IA...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Error al conectar con la IA despues de varios intentos. Intenta nuevamente.',
        ),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('resumen IA muestra resultado exitoso para item valido', (
      tester,
    ) async {
      await pumpWorkspace(tester);

      await tester.tap(find.text('Historial').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrevista Equipo Tech').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resumen IA').first);
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      expect(
        find.text('Resumen ejecutivo', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Acciones pendientes', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('topbar muestra badges grabando y procesando simultaneo', (
      tester,
    ) async {
      await pumpWorkspace(tester);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();

      await tester.tap(find.text('Archivo').first);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Explorar archivos').first);
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.textContaining('Grabando'), findsOneWidget);
      expect(find.textContaining('Procesando '), findsOneWidget);
    });
  });
}
