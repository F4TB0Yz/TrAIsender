import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:traisender/domain/history_item.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';
import 'package:traisender/ui/feedback/feedback_view_state.dart';
import 'package:traisender/ui/feedback/widgets/feedback_history_sidebar.dart';
import 'package:traisender/ui/feedback/widgets/feedback_main_content.dart';
import 'package:traisender/ui/feedback/widgets/feedback_top_controls.dart';

class FeedbackWindowBody extends StatefulWidget {
  final FeedbackViewState viewState;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<HistoryItem> onHistoryItemSelected;
  final Future<void> Function() onPickFile;
  final Future<void> Function(DropDoneDetails details) onDropDone;
  final VoidCallback onToggleRecording;
  final ValueChanged<bool> onMicChanged;
  final VoidCallback onCloseHistoryView;

  const FeedbackWindowBody({
    super.key,
    required this.viewState,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onHistoryItemSelected,
    required this.onPickFile,
    required this.onDropDone,
    required this.onToggleRecording,
    required this.onMicChanged,
    required this.onCloseHistoryView,
  });

  @override
  State<FeedbackWindowBody> createState() => _FeedbackWindowBodyState();
}

class _FeedbackWindowBodyState extends State<FeedbackWindowBody> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        await widget.onDropDone(details);
      },
      child: Padding(
        padding: FeedbackStyles.shellPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeedbackTopControls(
              status: widget.viewState.status,
              isBusy: widget.viewState.isBusy,
              isRecording: widget.viewState.isRecording,
              micEnabled: widget.viewState.micEnabled,
              statusLabel: widget.viewState.statusLabel,
              statusColor: widget.viewState.statusColor,
              progress: widget.viewState.progress,
              onToggleRecording: widget.onToggleRecording,
              onPickFile: widget.onPickFile,
              onToggleMic: () =>
                  widget.onMicChanged(!widget.viewState.micEnabled),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FeedbackMainContent(
                viewState: widget.viewState,
                isDragging: _isDragging,
                selectedTab: widget.selectedTab,
                onTabChanged: widget.onTabChanged,
                onCloseHistoryView: widget.onCloseHistoryView,
                onPickFile: widget.onPickFile,
              ),
            ),
            if (widget.viewState.showHistory) ...[
              Padding(
                padding: FeedbackStyles.historyRailPadding,
                child: FeedbackHistoryRail(
                  history: widget.viewState.history,
                  viewingItem: widget.viewState.viewingItem,
                  onSelectItem: widget.onHistoryItemSelected,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
