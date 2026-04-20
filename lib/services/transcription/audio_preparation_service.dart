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
      print('Procesando archivo para Whisper: $sourcePath');
      final safeInputPath = p.join(tempDir.path, 'input_source$extension');
      await File(sourcePath).copy(safeInputPath);

      final copiedFile = File(safeInputPath);
      final fileSize = await copiedFile.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      print('Archivo copiado: $safeInputPath ($fileSizeMB MB)');

      if (fileSize == 0) {
        print('❌ ERROR: Archivo copiado está vacío (0 bytes)');
        return null;
      }

      var finalAudioPath = p.join(tempDir.path, 'converted_audio.wav');
      print('Convirtiendo a WAV 16kHz Mono...');
      print(
        'Comando: afconvert -f WAVE -d LEI16@16000 -c 1 "$safeInputPath" "$finalAudioPath"',
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
        print('❌ Error en afconvert: ${convertResult.stderr}');
        print('Salida: ${convertResult.stdout}');

        final fileInfoResult = await Process.run('file', [safeInputPath]);
        print('📋 Tipo de archivo: ${fileInfoResult.stdout}');

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
          print('🔊 Audio info: ${ffprobeResult.stdout}');
        } else {
          print('⚠️ No se encontró track de audio o ffprobe no disponible');
        }

        print('🔄 Intentando conversión con ffmpeg...');
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
          print('✅ Conversión con ffmpeg exitosa');
        } else {
          print('❌ ffmpeg también falló: ${ffmpegResult.stderr}');
          if (extension != '.wav') return null;
          finalAudioPath = sourcePath;
        }
      }

      return PreparedAudio(path: finalAudioPath, tempDir: tempDir);
    } catch (e) {
      print('Error al preparar audio: $e');
      return null;
    }
  }
}
