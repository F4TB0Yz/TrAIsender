import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class RecorderService {
  static const _channel = MethodChannel('com.traisender/recorder');
  String? _currentPath;

  Future<void> startRecording({required bool includeMic}) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    _currentPath = path.join(
      directory.path,
      "reunion_${DateTime.now().millisecondsSinceEpoch}.wav",
    );

    try {
      await _channel.invokeMethod('start', {
        'path': _currentPath,
        'includeMic': includeMic,
      });
      print('Grabando vía nativa. Micrófono: $includeMic');
    } on PlatformException catch (e) {
      throw Exception('Error al iniciar grabación nativa: ${e.message}');
    }
  }
  
  Future<String?> stopRecording() async {
    try {
      final String? path = await _channel.invokeMethod('stop');
      print('Grabación nativa finalizada en: $path');
      return path;
    } on PlatformException catch (e) {
      print('Error al detener grabación: ${e.message}');
      return null;
    }
  }

  Future<bool> isRecording() async {
    try {
      final bool recording = await _channel.invokeMethod('isRecording');
      return recording;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    // No hace falta disposición especial por ahora en el canal
  }
}
