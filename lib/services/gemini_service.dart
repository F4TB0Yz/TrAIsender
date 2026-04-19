import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiError {
  final String message;
  final bool retriable;
  final int? statusCode;
  final String raw;

  const GeminiError({
    required this.message,
    required this.retriable,
    required this.raw,
    this.statusCode,
  });
}

class GeminiResult {
  final bool ok;
  final String? text;
  final GeminiError? error;

  const GeminiResult._(this.ok, this.text, this.error);

  factory GeminiResult.success(String text) => GeminiResult._(true, text, null);

  factory GeminiResult.failure(GeminiError error) => GeminiResult._(false, null, error);
}

class _RetryJob {
  final int id;
  final String transcription;
  final void Function(String summary) onSuccess;
  final void Function(String message)? onPermanentError;
  int attempt = 0;
  Timer? timer;

  _RetryJob({
    required this.id,
    required this.transcription,
    required this.onSuccess,
    this.onPermanentError,
  });
}

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;
  final Duration _timeout = const Duration(seconds: 15);
  final List<Duration> _retryDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];
  final List<Duration> _queueDelays = const [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 4),
    Duration(minutes: 8),
    Duration(minutes: 10),
  ];
  final Map<int, _RetryJob> _retryJobs = {};
  int _retryId = 0;

  Future<void> init() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Advertencia: GEMINI_API_KEY no encontrada en .env');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );
      _isInitialized = true;
      print('Gemini Service inicializado.');
    } catch (e) {
      print('Error al inicializar Gemini: $e');
    }
  }

  Future<GeminiResult> summarizeMeeting(
    String transcription, {
    void Function(String partialText)? onPartialText,
  }) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) {
      return GeminiResult.failure(
        const GeminiError(
          message: 'Falta configurar Gemini. Revisa tu API Key.',
          retriable: false,
          raw: 'Gemini no inicializado',
        ),
      );
    }

    final prompt = '''
Eres un analizador de texto estricto. Tu ÚNICA función es extraer información de la transcripción y rellenar la siguiente plantilla Markdown.

REGLAS DE FORMATO ESTRICTAS:
1. PROHIBICIÓN DE INTRODUCCIONES: Tu respuesta DEBE empezar EXACTAMENTE con la palabra "Resumen:". No puedes generar absolutamente ningún texto, saludo o párrafo antes de esa palabra.
2. VIÑETAS OBLIGATORIAS: En todas las secciones teóricas y técnicas, cada línea de información DEBE comenzar obligatoriamente con el símbolo de guion y un espacio ("- "). No escribas texto suelto.
3. ACCIÓN ITEMS: Extrae todas las tareas, lecturas y registros de asistencia, usando el formato "[ ] ".
4. PARTICIPACIÓN: Agrupa a todos los que participaron activamente en una sola viñeta separados por comas.

PLANTILLA EXACTA A REPRODUCIR Y RELLENAR, EN CASO DE QUE NO HAYA ALGUNA INFORMACION POR QUE NO SE DIJO, OMITE LA SECCION DEL RESUMEN PERO SIGUE RESUMIENDO LO NECESARIO:

**Resumen**:
**Acción Items**
[ ] (Acción 1 extraída)
[ ] (Acción 2 extraída)

**[Título del Primer Tema Principal]**
- (Dato clave o explicación 1)
- (Dato clave o explicación 2)

**[Título del Segundo Tema Principal]**
- (Dato clave o explicación 1)
- (Dato clave o explicación 2)

**Ejemplos Prácticos Trabajados**
- (Resume los ejercicios resueltos en clase)

**Participación de Estudiantes**
- Participaron activamente: (Lista de nombres separados por comas)
- (Menciona si se resolvieron dudas con alguien en particular)

**Problemas Técnicos**
- (Resume los problemas logísticos, de chat, permisos o plataforma)

**Próxima Clase**
- (Fecha, hora y notas finales de cierre)

TRANSCRIPCIÓN A PROCESAR:
$transcription
''';

    final content = [Content.text(prompt)];

    for (var attempt = 0; attempt < _retryDelays.length; attempt++) {
      try {
        final stream = _model.generateContentStream(content);
        String accumulated = '';

        await for (final chunk in stream) {
          accumulated += chunk.text ?? '';
          onPartialText?.call(accumulated);
        }

        final text = accumulated.isEmpty ? null : accumulated;

        if (text == null || text.trim().isEmpty) {
          return GeminiResult.failure(
            const GeminiError(
              message: 'Gemini respondio sin contenido.',
              retriable: false,
              raw: 'Respuesta vacia',
            ),
          );
        }

        return GeminiResult.success(text);
      } catch (e) {
        final error = _mapError(e);
        print('Error en Gemini (summarize): ${error.raw}');

        final hasMoreAttempts = attempt < _retryDelays.length - 1;
        if (error.retriable && hasMoreAttempts) {
          await Future.delayed(_retryDelays[attempt]);
          continue;
        }

        return GeminiResult.failure(error);
      }
    }

    return GeminiResult.failure(
      const GeminiError(
        message: 'Gemini no respondio. Reintentare mas tarde.',
        retriable: true,
        raw: 'Sin respuesta tras reintentos',
      ),
    );
  }

  Future<void> enqueueRetry(
    String transcription, {
    required void Function(String summary) onSuccess,
    void Function(String message)? onPermanentError,
  }) async {
    if (transcription.trim().isEmpty) return;

    if (!_isInitialized) await init();

    final job = _RetryJob(
      id: _retryId++,
      transcription: transcription,
      onSuccess: onSuccess,
      onPermanentError: onPermanentError,
    );

    _retryJobs[job.id] = job;
    _scheduleRetry(job);
  }

  void _scheduleRetry(_RetryJob job) {
    final delay = _queueDelayForAttempt(job.attempt);
    job.timer?.cancel();
    job.timer = Timer(delay, () async {
      final result = await summarizeMeeting(job.transcription);
      if (result.ok) {
        _retryJobs.remove(job.id);
        job.timer?.cancel();
        job.onSuccess(result.text!);
        return;
      }

      final error = result.error!;
      final hasMoreAttempts = job.attempt < _queueDelays.length - 1;
      if (error.retriable && hasMoreAttempts) {
        job.attempt += 1;
        _scheduleRetry(job);
        return;
      }

      _retryJobs.remove(job.id);
      job.timer?.cancel();
      job.onPermanentError?.call(error.message);
    });
  }

  Duration _queueDelayForAttempt(int attempt) {
    if (attempt < 0) return _queueDelays.first;
    if (attempt >= _queueDelays.length) return _queueDelays.last;
    return _queueDelays[attempt];
  }

  GeminiError _mapError(Object error) {
    if (error is TimeoutException) {
      return const GeminiError(
        message: 'Gemini tarda demasiado. Reintentare.',
        retriable: true,
        raw: 'Timeout',
      );
    }

    final raw = error.toString();
    final statusCode = _extractStatusCode(raw);
    final isRetriable = _isRetriableStatus(statusCode, raw);
    final message = isRetriable
        ? 'Gemini con alta demanda. Reintentare pronto.'
        : 'Gemini fallo. Intenta mas tarde.';

    return GeminiError(
      message: message,
      retriable: isRetriable,
      raw: raw,
      statusCode: statusCode,
    );
  }

  int? _extractStatusCode(String raw) {
    final bracket = RegExp(r'\[(\d{3})\]').firstMatch(raw);
    if (bracket != null) {
      return int.tryParse(bracket.group(1)!);
    }

    final jsonCode = RegExp(r'"code"\s*:\s*(\d{3})').firstMatch(raw);
    if (jsonCode != null) {
      return int.tryParse(jsonCode.group(1)!);
    }

    return null;
  }

  bool _isRetriableStatus(int? code, String raw) {
    if (code == 503 || code == 429) return true;
    final upper = raw.toUpperCase();
    if (upper.contains('UNAVAILABLE')) return true;
    if (upper.contains('RESOURCE_EXHAUSTED')) return true;
    return false;
  }
}
