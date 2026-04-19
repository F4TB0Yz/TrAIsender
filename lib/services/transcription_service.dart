import 'dart:io';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
import 'package:path/path.dart' as p;

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

    String finalAudioPath = audioPath;
    bool wasConverted = false;

    try {
      // Whisper requiere WAV de 16kHz mono. Si el archivo no es WAV o queremos asegurar el formato, lo convertimos.
      // Usamos afconvert de macOS para manejar mp4, mp3, m4a, mov, etc.
      print('Procesando archivo para Whisper: $audioPath');
      final extension = p.extension(audioPath).toLowerCase();
      
      // Siempre convertimos si no es wav 16k o si es un formato de video/audio comprimido
      final tempDir = await Directory.systemTemp.createTemp('traisender_transcribe_');
      
      // Paso de seguridad: copiar origen a un nombre ASCII simple para evitar error -50 de afconvert en paths complejos
      final safeInputPath = p.join(tempDir.path, 'input_source${extension}');
      await File(audioPath).copy(safeInputPath);

      finalAudioPath = p.join(tempDir.path, 'converted_audio.wav');
      
      print('Convirtiendo a WAV 16kHz Mono...');
      final convertResult = await Process.run('afconvert', [
        '-f', 'WAVE',
        '-d', 'LEI16@16000',
        '-c', '1',
        safeInputPath,
        finalAudioPath
      ]);

      if (convertResult.exitCode != 0) {
        print('Error en afconvert: ${convertResult.stderr}');
        // Si falla afconvert, intentamos con el original si es wav, si no, fallamos
        if (extension != '.wav') return null;
        finalAudioPath = audioPath;
      } else {
        wasConverted = true;
      }

      print('Iniciando transcripción de: $finalAudioPath');
      
      // transcribe devuelve un objeto con el texto y otros metadatos
      final result = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: finalAudioPath,
          language: 'es', // Idioma predeterminado
        ),
        modelPath: _modelPath,
      );

      return result.text;
    } catch (e) {
      print('Error durante la transcripción: $e');
      return null;
    } finally {
      // Limpieza de archivo temporal si fue creado
      if (wasConverted) {
        try {
          final tempFile = File(finalAudioPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
            await tempFile.parent.delete();
          }
        } catch (e) {
          print('Error limpiando archivos temporales: $e');
        }
      }
    }
  }
}
