import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/ui/feedback/feedback_view_state.dart';
import 'package:traisender/ui/feedback/widgets/feedback_content_panel.dart';
import 'package:traisender/ui/feedback/widgets/feedback_empty_state.dart';
import 'package:traisender/ui/feedback/widgets/feedback_loading_state.dart';

class FeedbackMainContent extends StatelessWidget {
  final FeedbackViewState viewState;
  final bool isDragging;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onCloseHistoryView;
  final VoidCallback onPickFile;

  const FeedbackMainContent({
    super.key,
    required this.viewState,
    required this.isDragging,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onCloseHistoryView,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    final viewingItem = viewState.viewingItem;
    if (viewingItem != null) {
      return Column(
        children: [
          Row(
            children: [
              MacosIconButton(
                icon: const Icon(CupertinoIcons.back, size: 20),
                onPressed: onCloseHistoryView,
              ),
              const SizedBox(width: 8),
              Text(
                'Sesión del ${viewingItem.date}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FeedbackContentPanel(
              selectedTab: selectedTab,
              onTabChanged: onTabChanged,
              summaryText: viewingItem.summary,
              transcriptionText: viewingItem.transcription,
            ),
          ),
        ],
      );
    }

    if (viewState.showEmptyState) {
      return FeedbackEmptyState(isDragging: isDragging, onPickFile: onPickFile);
    }

    if (viewState.isLoading) {
      return FeedbackLoadingState(
        isTranscribing: viewState.isTranscribing,
        progress: viewState.progress,
        progressLabel: viewState.progressLabel,
        showPartialSummary: viewState.showPartialSummary,
        partialSummary: viewState.text,
      );
    }

    return FeedbackContentPanel(
      selectedTab: selectedTab,
      onTabChanged: onTabChanged,
      summaryText: viewState.text,
      transcriptionText: viewState.transcription,
    );
  }
}
