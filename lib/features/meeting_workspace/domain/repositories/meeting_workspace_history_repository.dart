import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';

abstract interface class MeetingWorkspaceHistoryRepository {
  List<MeetingHistoryItem> loadHistory();
}
