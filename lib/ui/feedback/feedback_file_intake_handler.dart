import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class FeedbackFileIntakeHandler {
  static const List<String> allowedExtensions = [
    'wav',
    'mp3',
    'm4a',
    'mp4',
    'mov',
    'm4v',
  ];

  const FeedbackFileIntakeHandler._();

  static Future<void> processFromPicker({
    required Future<void> Function(String path) onAcceptedPath,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result == null) return;

    final path = result.files.single.path;
    await _processPath(path: path, onAcceptedPath: onAcceptedPath);
  }

  static Future<void> processFromDrop({
    required DropDoneDetails details,
    required Future<void> Function(String path) onAcceptedPath,
  }) async {
    if (details.files.isEmpty) return;

    final path = details.files.first.path;
    await onAcceptedPath(path);
  }

  static Future<void> _processPath({
    required String? path,
    required Future<void> Function(String path) onAcceptedPath,
  }) async {
    if (path == null || !_isAllowed(path)) return;
    await onAcceptedPath(path);
  }

  static bool _isAllowed(String path) {
    final extension = p.extension(path).toLowerCase();
    if (extension.isEmpty) return false;

    return allowedExtensions.contains(extension.substring(1));
  }
}
