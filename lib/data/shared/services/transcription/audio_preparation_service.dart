import 'dart:developer' as dev;
import 'dart:io';

import 'package:path/path.dart' as p;

class PreparedAudio {
  final String path;
  final Directory tempDir;

  PreparedAudio({required this.path, required this.tempDir});
}

class AudioPreparationService {
  Future<PreparedAudio?> prepare(String sourcePath) async {
    final extension = p.extension(sourcePath).toLowerCase();
    final tempDir = await Directory.systemTemp.createTemp(
      'traisender_transcribe_',
    );

    try {
      dev.log(
        'Procesando archivo para Whisper: $sourcePath',
        name: 'AudioPreparationService',
      );
      final safeInputPath = p.join(tempDir.path, 'input_source$extension');
      await File(sourcePath).copy(safeInputPath);

      final copiedFile = File(safeInputPath);
      final fileSize = await copiedFile.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      dev.log(
        'Archivo copiado: $safeInputPath ($fileSizeMB MB)',
        name: 'AudioPreparationService',
      );

      if (fileSize == 0) {
        dev.log(
          'ERROR: Archivo copiado está vacío (0 bytes)',
          name: 'AudioPreparationService',
        );
        return null;
      }

      var finalAudioPath = p.join(tempDir.path, 'converted_audio.wav');
      dev.log('Convirtiendo a WAV 16kHz Mono...', name: 'AudioPreparationService');
      dev.log(
        'Comando: afconvert -f WAVE -d LEI16@16000 -c 1 "$safeInputPath" "$finalAudioPath"',
        name: 'AudioPreparationService',
      );

      final convertResult = await Process.run('afconvert', [
        '-f',
        'WAVE',
        '-d',
        'LEI16@16000',
        '-c',
        '1',
        safeInputPath,
        finalAudioPath,
      ]);

      if (convertResult.exitCode != 0) {
        dev.log(
          'Error en afconvert: ${convertResult.stderr}',
          name: 'AudioPreparationService',
        );
        dev.log(
          'Salida: ${convertResult.stdout}',
          name: 'AudioPreparationService',
        );

        final fileInfoResult = await Process.run('file', [safeInputPath]);
        dev.log(
          'Tipo de archivo: ${fileInfoResult.stdout}',
          name: 'AudioPreparationService',
        );

        final ffprobeResult = await Process.run('ffprobe', [
          '-v',
          'error',
          '-select_streams',
          'a:0',
          '-show_entries',
          'stream=codec_type,codec_name,sample_rate,channels',
          '-of',
          'default=noprint_wrappers=1:nokey=1:nokey=1',
          safeInputPath,
        ]).catchError((_) => ProcessResult(0, 1, '', 'ffprobe no disponible'));

        if (ffprobeResult.exitCode == 0 &&
            ffprobeResult.stdout.toString().isNotEmpty) {
          dev.log(
            'Audio info: ${ffprobeResult.stdout}',
            name: 'AudioPreparationService',
          );
        } else {
          dev.log(
            'No se encontró track de audio o ffprobe no disponible',
            name: 'AudioPreparationService',
          );
        }

        dev.log(
          'Intentando conversión con ffmpeg...',
          name: 'AudioPreparationService',
        );
        final ffmpegResult = await Process.run('ffmpeg', [
          '-i',
          safeInputPath,
          '-acodec',
          'pcm_s16le',
          '-ar',
          '16000',
          '-ac',
          '1',
          '-y',
          finalAudioPath,
        ]).catchError((_) => ProcessResult(0, 1, '', 'ffmpeg no disponible'));

        if (ffmpegResult.exitCode == 0) {
          dev.log(
            'Conversión con ffmpeg exitosa',
            name: 'AudioPreparationService',
          );
        } else {
          dev.log(
            'ffmpeg también falló: ${ffmpegResult.stderr}',
            name: 'AudioPreparationService',
          );
          if (extension != '.wav') return null;
          finalAudioPath = sourcePath;
        }
      }

      return PreparedAudio(path: finalAudioPath, tempDir: tempDir);
    } catch (e) {
      dev.log('Error al preparar audio: $e', name: 'AudioPreparationService');
      return null;
    }
  }
}
