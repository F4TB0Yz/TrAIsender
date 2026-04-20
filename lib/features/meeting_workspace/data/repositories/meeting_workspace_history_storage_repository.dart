import 'package:traisender/domain/shared/entities/history_item.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/domain/repositories/meeting_workspace_history_repository.dart';
import 'package:traisender/data/shared/sources/local_history_source.dart';

class MeetingWorkspaceHistoryStorageRepository
    implements MeetingWorkspaceHistoryRepository {
  MeetingWorkspaceHistoryStorageRepository({HistoryStorage? historyStorage})
    : _historyStorage = historyStorage ?? HistoryStorage();

  final HistoryStorage _historyStorage;

  @override
  List<MeetingHistoryItem> loadHistory() {
    return const [];
  }

  Future<List<MeetingHistoryItem>> loadHistoryAsync() async {
    final history = await _historyStorage.load();
    return history.asMap().entries.map((entry) {
      final item = entry.value;
      return MeetingHistoryItem(
        id: entry.key + 1,
        title: _buildTitle(item),
        date: item.date,
        length: _estimateLength(item.transcription),
        transcript: item.transcription,
        summary: item.summary,
      );
    }).toList();
  }

  String _buildTitle(HistoryItem item) {
    final source = item.summary.trim().isNotEmpty
        ? item.summary.trim()
        : item.transcription.trim();
    if (source.isEmpty) return 'Sesion sin titulo';
    final firstLine = source.split('\n').first.trim();
    if (firstLine.length <= 36) return firstLine;
    return '${firstLine.substring(0, 33)}...';
  }

  String _estimateLength(String transcription) {
    final words = transcription
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final minutes = (words / 150).clamp(1, 240).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }
}
