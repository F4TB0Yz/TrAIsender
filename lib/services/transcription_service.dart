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
      
      // Debug: verificar archivo copiado
      final copiedFile = File(safeInputPath);
      final fileSize = await copiedFile.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      print('Archivo copiado: $safeInputPath ($fileSizeMB MB)');
      
      if (fileSize == 0) {
        print('❌ ERROR: Archivo copiado está vacío (0 bytes)');
        return null;
      }

      finalAudioPath = p.join(tempDir.path, 'converted_audio.wav');
      
      print('Convirtiendo a WAV 16kHz Mono...');
      print('Comando: afconvert -f WAVE -d LEI16@16000 -c 1 "$safeInputPath" "$finalAudioPath"');
      final convertResult = await Process.run('afconvert', [
        '-f', 'WAVE',
        '-d', 'LEI16@16000',
        '-c', '1',
        safeInputPath,
        finalAudioPath
      ]);

      if (convertResult.exitCode != 0) {
        print('❌ Error en afconvert: ${convertResult.stderr}');
        print('Salida: ${convertResult.stdout}');
        
        // Diagnóstico: verificar contenido del MP4
        final fileInfoResult = await Process.run('file', [safeInputPath]);
        print('📋 Tipo de archivo: ${fileInfoResult.stdout}');
        
        // Intentar ffprobe para diagnosticar streams
        final ffprobeResult = await Process.run('ffprobe', [
          '-v', 'error',
          '-select_streams', 'a:0',
          '-show_entries', 'stream=codec_type,codec_name,sample_rate,channels',
          '-of', 'default=noprint_wrappers=1:nokey=1:nokey=1',
          safeInputPath
        ]).catchError((_) => ProcessResult(0, 1, '', 'ffprobe no disponible'));
        
        if (ffprobeResult.exitCode == 0 && ffprobeResult.stdout.toString().isNotEmpty) {
          print('🔊 Audio info: ${ffprobeResult.stdout}');
        } else {
          print('⚠️ No se encontró track de audio o ffprobe no disponible');
        }
        
        // Fallback: intentar con ffmpeg
        print('🔄 Intentando conversión con ffmpeg...');
        final ffmpegResult = await Process.run('ffmpeg', [
          '-i', safeInputPath,
          '-acodec', 'pcm_s16le',
          '-ar', '16000',
          '-ac', '1',
          '-y',
          finalAudioPath
        ]).catchError((_) => ProcessResult(0, 1, '', 'ffmpeg no disponible'));
        
        if (ffmpegResult.exitCode == 0) {
          print('✅ Conversión con ffmpeg exitosa');
          wasConverted = true;
        } else {
          print('❌ ffmpeg también falló: ${ffmpegResult.stderr}');
          if (extension != '.wav') return null;
          finalAudioPath = audioPath;
        }
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
