import 'dart:io';
import 'dart:async';
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

  Future<String?> transcribe(
    String audioPath, {
    void Function(double progress, String label)? onProgress,
  }) async {
    if (!_isInitialized) await init();

    if (!await File(audioPath).exists()) {
      print('Archivo de audio no encontrado: $audioPath');
      return null;
    }

    String finalAudioPath = audioPath;
    bool wasConverted = false;
    Directory? tempDir;

    try {
      // Whisper requiere WAV de 16kHz mono. Si el archivo no es WAV o queremos asegurar el formato, lo convertimos.
      // Usamos afconvert de macOS para manejar mp4, mp3, m4a, mov, etc.
      print('Procesando archivo para Whisper: $audioPath');
      final extension = p.extension(audioPath).toLowerCase();
      
      // Siempre convertimos si no es wav 16k o si es un formato de video/audio comprimido
      tempDir = await Directory.systemTemp.createTemp('traisender_transcribe_');
      
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
      
      double audioDurationMs = 0;
      try {
        final infoResult = await Process.run('afinfo', [finalAudioPath]);
        final match = RegExp(r'estimated duration: ([\d.]+) sec').firstMatch(infoResult.stdout.toString());
        if (match != null) {
          audioDurationMs = double.parse(match.group(1)!) * 1000;
        }
      } catch (_) {}

      String formatTime(double seconds) {
        final duration = Duration(milliseconds: (seconds * 1000).toInt());
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final secs = duration.inSeconds.remainder(60);
        
        if (hours > 0) {
          return '${hours}h ${minutes}m ${secs}s';
        } else if (minutes > 0) {
          return '${minutes}m ${secs}s';
        } else {
          return '${secs}s';
        }
      }

      final totalSec = audioDurationMs / 1000;
      // Definimos bloques de 5 minutos (300 segundos)
      const int segmentDurationSec = 300;
      final Stopwatch realTimeStopwatch = Stopwatch()..start();
      
      String formatRealTime(Duration d) {
        final hours = d.inHours;
        final minutes = d.inMinutes.remainder(60);
        final seconds = d.inSeconds.remainder(60);
        if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
        if (minutes > 0) return '${minutes}m ${seconds}s';
        return '${seconds}s';
      }

      if (totalSec > segmentDurationSec) {
        print('Archivo largo detectado (${formatTime(totalSec)}). Dividiendo en segmentos...');
        final segmentsDir = Directory(p.join(tempDir!.path, 'segments'));
        await segmentsDir.create();
        
        final segmentResult = await Process.run('ffmpeg', [
          '-i', finalAudioPath,
          '-f', 'segment',
          '-segment_time', segmentDurationSec.toString(),
          '-c', 'copy',
          p.join(segmentsDir.path, 'chunk%03d.wav')
        ]);

        if (segmentResult.exitCode != 0) {
          print('Error al segmentar audio: ${segmentResult.stderr}');
        } else {
          final chunks = segmentsDir.listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.wav'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

          final StringBuffer fullTranscript = StringBuffer();

          // Timer periódico para actualizar solo el tiempo transcurrido en la UI
          // mientras Whisper está ocupado transcribiendo un bloque largo.
          Timer? uiTimer;
          int currentChunkIndex = 0;

          uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (onProgress != null) {
              final double baseProgress = currentChunkIndex / chunks.length;
              onProgress(baseProgress, '${formatRealTime(realTimeStopwatch.elapsed)} transcurridos (Parte ${currentChunkIndex + 1}/${chunks.length})');
            }
          });

          for (int i = 0; i < chunks.length; i++) {
            currentChunkIndex = i;
            // La actualización inmediata al empezar un nuevo bloque
            if (onProgress != null) {
              onProgress(i / chunks.length, '${formatRealTime(realTimeStopwatch.elapsed)} transcurridos (Parte ${i + 1}/${chunks.length})');
            }

            final result = await _whisper.transcribe(
              transcribeRequest: TranscribeRequest(
                audio: chunks[i].path,
                language: 'es',
              ),
              modelPath: _modelPath,
            );
            
            if (result.text.isNotEmpty) {
              fullTranscript.write('${result.text} ');
            }
          }

          uiTimer.cancel();
          realTimeStopwatch.stop();
          if (onProgress != null) onProgress(1.0, 'Completado en ${formatRealTime(realTimeStopwatch.elapsed)}');
          return fullTranscript.toString().trim();
        }
      }

      // Fallback o archivo corto (< 5 min)
      Timer? progressTimer;
      if (audioDurationMs > 0 && onProgress != null) {
        progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          // Para archivos cortos, simulamos un progreso basado en tiempo real
          // pero sin saltos de 5 minutos.
          double simulatedProgress = realTimeStopwatch.elapsedMilliseconds / (audioDurationMs / 5); // Estimación 5x
          if (simulatedProgress > 0.95) simulatedProgress = 0.95;
          
          onProgress(simulatedProgress, '${formatRealTime(realTimeStopwatch.elapsed)} transcurridos');
        });
      }

      final result = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: finalAudioPath,
          language: 'es',
        ),
        modelPath: _modelPath,
      );

      progressTimer?.cancel();
      realTimeStopwatch.stop();
      if (onProgress != null) onProgress(1.0, 'Completado en ${formatRealTime(realTimeStopwatch.elapsed)}');

      return result.text;
    } catch (e) {
      print('Error durante la transcripción: $e');
      return null;
    } finally {
      // Limpieza de directorio temporal si fue creado
      if (tempDir != null) {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (e) {
          print('Error limpiando archivos temporales: $e');
        }
      }
    }
  }
}
