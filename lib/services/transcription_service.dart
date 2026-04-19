import 'dart:io';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class TranscriptionService {
  late final Whisper _whisper;
  bool _isInitialized = false;

  // Ruta absoluta del modelo según lo solicitado
  static const String _modelPath = '/Users/f4tb0y/Documents/Proyectos/I.A Models/ggml-large-v3-turbo.bin';

  Future<void> init() async {
    if (_isInitialized) return;

    if (!await File(_modelPath).exists()) {
      throw Exception('Modelo Whisper no encontrado en: $_modelPath');
    }

    try {
      _whisper = Whisper(
        model: WhisperModel.largeV3Turbo,
        modelDir: File(_modelPath).parent.path,
      );
      _isInitialized = true;
      print('Whisper inicializado con modelo: $_modelPath');
    } catch (e) {
      throw Exception('Error al inicializar Whisper: $e');
    }
  }

  Future<String?> transcribe(String audioPath) async {
    if (!_isInitialized) await init();

    if (!await File(audioPath).exists()) {
      print('Archivo de audio no encontrado: $audioPath');
      return null;
    }

    try {
      print('Iniciando transcripción de: $audioPath');
      
      // transcribe devuelve un objeto con el texto y otros metadatos
      final result = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: 'es', // Idioma predeterminado
        ),
        modelPath: _modelPath,
      );

      return result.text;
    } catch (e) {
      print('Error durante la transcripción: $e');
      return null;
    }
  }
}
