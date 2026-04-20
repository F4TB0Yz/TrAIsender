import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/application/status_controller.dart';
import 'package:traisender/domain/history_item.dart';
import 'package:traisender/ui/feedback/feedback_file_intake_handler.dart';
import 'package:traisender/ui/feedback/feedback_view_state.dart';
import 'package:traisender/ui/feedback/widgets/feedback_window_body.dart';

class FeedbackWindow extends StatefulWidget {
  final StatusController controller;

  const FeedbackWindow({super.key, required this.controller});

  @override
  State<FeedbackWindow> createState() => _FeedbackWindowState();
}

class _FeedbackWindowState extends State<FeedbackWindow> {
  int _selectedTab = 0;

  Future<void> _processAudioPath(String path) async =>
      widget.controller.onProcessAudio?.call(path);

  Future<void> _pickAndProcessFile() async =>
      FeedbackFileIntakeHandler.processFromPicker(
        onAcceptedPath: _processAudioPath,
      );

  Future<void> _onDropDone(DropDoneDetails details) async =>
      FeedbackFileIntakeHandler.processFromDrop(
        details: details,
        onAcceptedPath: _processAudioPath,
      );

  void _onHistoryItemSelected(HistoryItem item) {
    setState(() => _selectedTab = 0);
    widget.controller.viewHistoryItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final viewState = FeedbackViewState.fromController(widget.controller);
        return MacosScaffold(
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return FeedbackWindowBody(
                  viewState: viewState,
                  selectedTab: _selectedTab,
                  onTabChanged: (val) => setState(() => _selectedTab = val),
                  onHistoryItemSelected: _onHistoryItemSelected,
                  onPickFile: _pickAndProcessFile,
                  onDropDone: _onDropDone,
                  onToggleRecording: () {
                    widget.controller.onToggleRecording?.call();
                  },
                  onMicChanged: widget.controller.setMicEnabled,
                  onCloseHistoryView: widget.controller.closeHistoryView,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
