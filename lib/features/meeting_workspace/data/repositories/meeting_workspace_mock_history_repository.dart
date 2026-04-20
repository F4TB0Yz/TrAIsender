import 'package:traisender/features/meeting_workspace/data/sources/meeting_workspace_mock_history_source.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/domain/repositories/meeting_workspace_history_repository.dart';

class MeetingWorkspaceMockHistoryRepository
    implements MeetingWorkspaceHistoryRepository {
  const MeetingWorkspaceMockHistoryRepository();

  @override
  List<MeetingHistoryItem> loadHistory() {
    return MeetingWorkspaceMockHistorySource.history;
  }
}
