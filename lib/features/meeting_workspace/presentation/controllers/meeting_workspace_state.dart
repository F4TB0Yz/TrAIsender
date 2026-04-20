import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';

class MeetingWorkspaceState {
  const MeetingWorkspaceState({
    required this.activeTab,
    required this.isRecording,
    required this.audioSource,
    required this.recordTime,
    required this.isUploading,
    required this.uploadProgress,
    required this.uploadFileName,
    required this.selectedMeeting,
    required this.historyDetailTab,
    required this.aiResult,
    required this.isAiLoading,
    required this.aiError,
    required this.liveTranscript,
    required this.history,
  });

  factory MeetingWorkspaceState.initial({
    required List<MeetingHistoryItem> history,
  }) {
    return MeetingWorkspaceState(
      activeTab: MainTab.record,
      isRecording: false,
      audioSource: AudioSource.mic,
      recordTime: 0,
      isUploading: false,
      uploadProgress: 0,
      uploadFileName: '',
      selectedMeeting: null,
      historyDetailTab: HistoryDetailTab.transcript,
      aiResult: '',
      isAiLoading: false,
      aiError: '',
      liveTranscript: '',
      history: history,
    );
  }

  final MainTab activeTab;
  final bool isRecording;
  final AudioSource audioSource;
  final int recordTime;
  final bool isUploading;
  final int uploadProgress;
  final String uploadFileName;
  final MeetingHistoryItem? selectedMeeting;
  final HistoryDetailTab historyDetailTab;
  final String aiResult;
  final bool isAiLoading;
  final String aiError;
  final String liveTranscript;
  final List<MeetingHistoryItem> history;

  MeetingWorkspaceState copyWith({
    MainTab? activeTab,
    bool? isRecording,
    AudioSource? audioSource,
    int? recordTime,
    bool? isUploading,
    int? uploadProgress,
    String? uploadFileName,
    MeetingHistoryItem? selectedMeeting,
    bool clearSelectedMeeting = false,
    HistoryDetailTab? historyDetailTab,
    String? aiResult,
    bool? isAiLoading,
    String? aiError,
    String? liveTranscript,
    List<MeetingHistoryItem>? history,
  }) {
    return MeetingWorkspaceState(
      activeTab: activeTab ?? this.activeTab,
      isRecording: isRecording ?? this.isRecording,
      audioSource: audioSource ?? this.audioSource,
      recordTime: recordTime ?? this.recordTime,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadFileName: uploadFileName ?? this.uploadFileName,
      selectedMeeting: clearSelectedMeeting
          ? null
          : (selectedMeeting ?? this.selectedMeeting),
      historyDetailTab: historyDetailTab ?? this.historyDetailTab,
      aiResult: aiResult ?? this.aiResult,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      aiError: aiError ?? this.aiError,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      history: history ?? this.history,
    );
  }
}
