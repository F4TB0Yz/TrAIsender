import 'dart:io';

import 'package:path/path.dart' as p;

class AudioSegmentationService {
  Future<List<File>?> split({
    required String audioPath,
    required Directory tempDir,
    int segmentDurationSec = 300,
  }) async {
    final segmentsDir = Directory(p.join(tempDir.path, 'segments'));
    await segmentsDir.create();

    final segmentResult = await Process.run('ffmpeg', [
      '-i',
      audioPath,
      '-f',
      'segment',
      '-segment_time',
      segmentDurationSec.toString(),
      '-c',
      'copy',
      p.join(segmentsDir.path, 'chunk%03d.wav'),
    ]);

    if (segmentResult.exitCode != 0) {
      print('Error al segmentar audio: ${segmentResult.stderr}');
      return null;
    }

    final chunks =
        segmentsDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.wav'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    if (chunks.isEmpty) return null;
    return chunks;
  }
}
