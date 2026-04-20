import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:traisender/data/shared/services/transcription/audio_preparation_service.dart';
import 'package:traisender/data/shared/services/transcription/audio_segmentation_service.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class TranscriptionService {
  late final Whisper _whisper;
  bool _isInitialized = false;
  final AudioPreparationService _audioPreparation;
  final AudioSegmentationService _audioSegmentation;

  static const String _modelPath =
      '/Users/f4tb0y/Documents/Proyectos/I.A Models/ggml-large-v3-turbo.bin';

  TranscriptionService({
    AudioPreparationService? audioPreparation,
    AudioSegmentationService? audioSegmentation,
  }) : _audioPreparation = audioPreparation ?? AudioPreparationService(),
       _audioSegmentation = audioSegmentation ?? AudioSegmentationService();

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
      dev.log(
        'Whisper inicializado con modelo: $_modelPath',
        name: 'TranscriptionService',
      );
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
      dev.log(
        'Archivo de audio no encontrado: $audioPath',
        name: 'TranscriptionService',
      );
      return null;
    }

    Directory? tempDir;

    try {
      final preparedAudio = await _audioPreparation.prepare(audioPath);
      if (preparedAudio == null) return null;

      final finalAudioPath = preparedAudio.path;
      tempDir = preparedAudio.tempDir;

      dev.log(
        'Iniciando transcripción de: $finalAudioPath',
        name: 'TranscriptionService',
      );

      var audioDurationMs = await _readAudioDurationMs(finalAudioPath);
      final totalSec = audioDurationMs / 1000;
      const segmentDurationSec = 300;
      final realTimeStopwatch = Stopwatch()..start();

      if (totalSec > segmentDurationSec) {
        dev.log(
          'Archivo largo detectado (${_formatTime(totalSec)}). Dividiendo en segmentos...',
          name: 'TranscriptionService',
        );
        final chunks = await _audioSegmentation.split(
          audioPath: finalAudioPath,
          tempDir: tempDir,
          segmentDurationSec: segmentDurationSec,
        );

        if (chunks != null) {
          final transcript = await _transcribeChunks(
            chunks: chunks,
            onProgress: onProgress,
            stopwatch: realTimeStopwatch,
          );
          return transcript;
        }
      }

      final result = await _transcribeSingleAudio(
        finalAudioPath: finalAudioPath,
        audioDurationMs: audioDurationMs,
        onProgress: onProgress,
        stopwatch: realTimeStopwatch,
      );
      return result;
    } catch (e) {
      dev.log('Error durante la transcripción: $e', name: 'TranscriptionService');
      return null;
    } finally {
      if (tempDir != null) {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } catch (e) {
          dev.log(
            'Error limpiando archivos temporales: $e',
            name: 'TranscriptionService',
          );
        }
      }
    }
  }

  Future<double> _readAudioDurationMs(String audioPath) async {
    try {
      final infoResult = await Process.run('afinfo', [audioPath]);
      final match = RegExp(
        r'estimated duration: ([\d.]+) sec',
      ).firstMatch(infoResult.stdout.toString());
      if (match == null) return 0;
      return double.parse(match.group(1)!) * 1000;
    } catch (_) {
      return 0;
    }
  }

  Future<String> _transcribeChunks({
    required List<File> chunks,
    required Stopwatch stopwatch,
    void Function(double progress, String label)? onProgress,
  }) async {
    final fullTranscript = StringBuffer();
    Timer? uiTimer;
    var currentChunkIndex = 0;

    uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (onProgress == null) return;
      final baseProgress = currentChunkIndex / chunks.length;
      onProgress(
        baseProgress,
        '${_formatRealTime(stopwatch.elapsed)} transcurridos (Parte ${currentChunkIndex + 1}/${chunks.length})',
      );
    });

    for (var i = 0; i < chunks.length; i++) {
      currentChunkIndex = i;
      if (onProgress != null) {
        onProgress(
          i / chunks.length,
          '${_formatRealTime(stopwatch.elapsed)} transcurridos (Parte ${i + 1}/${chunks.length})',
        );
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
    stopwatch.stop();
    onProgress?.call(
      1.0,
      'Completado en ${_formatRealTime(stopwatch.elapsed)}',
    );
    return fullTranscript.toString().trim();
  }

  Future<String?> _transcribeSingleAudio({
    required String finalAudioPath,
    required double audioDurationMs,
    required Stopwatch stopwatch,
    void Function(double progress, String label)? onProgress,
  }) async {
    Timer? progressTimer;
    if (audioDurationMs > 0 && onProgress != null) {
      progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        var simulatedProgress =
            stopwatch.elapsedMilliseconds / (audioDurationMs / 5);
        if (simulatedProgress > 0.95) simulatedProgress = 0.95;
        onProgress(
          simulatedProgress,
          '${_formatRealTime(stopwatch.elapsed)} transcurridos',
        );
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
    stopwatch.stop();
    onProgress?.call(
      1.0,
      'Completado en ${_formatRealTime(stopwatch.elapsed)}',
    );
    return result.text;
  }

  String _formatTime(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) return '${hours}h ${minutes}m ${secs}s';
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }

  String _formatRealTime(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
