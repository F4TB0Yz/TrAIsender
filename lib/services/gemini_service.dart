import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Advertencia: GEMINI_API_KEY no encontrada en .env');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-3.1-flash-lite-preview',
        apiKey: apiKey,
      );
      _isInitialized = true;
      print('Gemini Service inicializado.');
    } catch (e) {
      print('Error al inicializar Gemini: $e');
    }
  }

  Future<String?> summarizeMeeting(String transcription) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return 'Error: Gemini no inicializado. Revisa tu API Key en .env';

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

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text;
    } catch (e) {
      print('Error en Gemini (summarize): $e');
      return 'Error al generar el resumen con Gemini.';
    }
  }
}
