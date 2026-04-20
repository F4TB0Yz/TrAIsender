import 'package:flutter/material.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_controller.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_state.dart';

import 'meeting_workspace_navigation_widgets.dart';
import 'meeting_workspace_tokens.dart';
import 'tab_panes.dart';

typedef MeetingWorkspaceOpenTab =
    void Function(MainTab tab, {bool clearMeeting});
typedef MeetingWorkspaceResolveHeaderTitle =
    String Function(MainTab activeTab, bool hasSelectedMeeting);

class MeetingWorkspaceDesktopSection extends StatelessWidget {
  const MeetingWorkspaceDesktopSection({
    super.key,
    required this.controller,
    required this.onOpenTab,
    required this.resolveHeaderTitle,
  });

  final MeetingWorkspaceController controller;
  final MeetingWorkspaceOpenTab onOpenTab;
  final MeetingWorkspaceResolveHeaderTitle resolveHeaderTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 256,
          padding: const EdgeInsets.fromLTRB(12, 48, 12, 24),
          decoration: BoxDecoration(
            color: MeetingWorkspaceTokens.compactBackground.withValues(
              alpha: 0.75,
            ),
            border: Border(
              right: BorderSide(
                color: MeetingWorkspaceTokens.panelBorder.withValues(alpha: 0.75),
              ),
            ),
          ),
          child: MeetingWorkspaceSelector<MainTab>(
            controller: controller,
            selector: (state) => state.activeTab,
            builder: (context, activeTab) {
              return MeetingWorkspaceNavigation(
                compact: false,
                activeTab: activeTab,
                onOpenTab: onOpenTab,
              );
            },
          ),
        ),
        Expanded(
          child: MeetingWorkspaceMainPanel(
            controller: controller,
            resolveHeaderTitle: resolveHeaderTitle,
          ),
        ),
      ],
    );
  }
}

class MeetingWorkspaceCompactSection extends StatelessWidget {
  const MeetingWorkspaceCompactSection({
    super.key,
    required this.controller,
    required this.onOpenTab,
    required this.resolveHeaderTitle,
  });

  final MeetingWorkspaceController controller;
  final MeetingWorkspaceOpenTab onOpenTab;
  final MeetingWorkspaceResolveHeaderTitle resolveHeaderTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MeetingWorkspaceSelector<MainTab>(
          controller: controller,
          selector: (state) => state.activeTab,
          builder: (context, activeTab) {
            return Container(
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: 10,
                top: 50,
              ),
              color: MeetingWorkspaceTokens.compactBackground,
              child: Row(
                children: [
                  Expanded(
                    child: MeetingWorkspaceNavigation(
                      compact: true,
                      activeTab: activeTab,
                      onOpenTab: onOpenTab,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: MeetingWorkspaceMainPanel(
            controller: controller,
            resolveHeaderTitle: resolveHeaderTitle,
          ),
        ),
      ],
    );
  }
}

class MeetingWorkspaceMainPanel extends StatelessWidget {
  const MeetingWorkspaceMainPanel({
    super.key,
    required this.controller,
    required this.resolveHeaderTitle,
  });

  final MeetingWorkspaceController controller;
  final MeetingWorkspaceResolveHeaderTitle resolveHeaderTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MeetingWorkspaceSelector<
          ({
            MainTab activeTab,
            bool hasSelectedMeeting,
            bool isRecording,
            int recordTime,
            bool isUploading,
            int uploadProgress,
          })
        >(
          controller: controller,
          selector: (state) {
            return (
              activeTab: state.activeTab,
              hasSelectedMeeting: state.selectedMeeting != null,
              isRecording: state.isRecording,
              recordTime: state.recordTime,
              isUploading: state.isUploading,
              uploadProgress: state.uploadProgress,
            );
          },
          builder: (context, selected) {
            return MeetingWorkspaceTopBar(
              title: resolveHeaderTitle(
                selected.activeTab,
                selected.hasSelectedMeeting,
              ),
              isRecording: selected.isRecording,
              recordTime: selected.recordTime,
              isUploading: selected.isUploading,
              uploadProgress: selected.uploadProgress,
              formatTime: controller.formatTime,
            );
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: MeetingWorkspaceSelector<MainTab>(
                  controller: controller,
                  selector: (state) => state.activeTab,
                  builder: (context, activeTab) {
                    return switch (activeTab) {
                      MainTab.record => MeetingWorkspaceSelector<RecordPaneState>(
                        controller: controller,
                        selector: (state) => RecordPaneState(
                          audioSource: state.audioSource,
                          isRecording: state.isRecording,
                          recordTime: state.recordTime,
                          liveTranscript: state.liveTranscript,
                        ),
                        builder: (context, paneState) {
                          return MeetingWorkspaceRecordPane(
                            state: paneState,
                            formatTime: controller.formatTime,
                            callbacks: RecordPaneCallbacks(
                              onSetAudioSource: controller.setAudioSource,
                              onToggleRecording: controller.toggleRecording,
                            ),
                          );
                        },
                      ),
                      MainTab.upload => MeetingWorkspaceSelector<UploadPaneState>(
                        controller: controller,
                        selector: (state) => UploadPaneState(
                          isUploading: state.isUploading,
                          uploadProgress: state.uploadProgress,
                          uploadFileName: state.uploadFileName,
                        ),
                        builder: (context, paneState) {
                          return MeetingWorkspaceUploadPane(
                            state: paneState,
                            callbacks: UploadPaneCallbacks(
                              onStartUpload: controller.startFakeUpload,
                              onDroppedFile: controller.processDroppedFile,
                            ),
                          );
                        },
                      ),
                      MainTab.history =>
                        MeetingWorkspaceSelector<HistoryPaneState>(
                          controller: controller,
                          selector: (state) => HistoryPaneState(
                            history: state.history,
                            selectedMeeting: state.selectedMeeting,
                            historyDetailTab: state.historyDetailTab,
                            aiResult: state.aiResult,
                            isAiLoading: state.isAiLoading,
                            aiError: state.aiError,
                          ),
                          builder: (context, paneState) {
                            return MeetingWorkspaceHistoryPane(
                              state: paneState,
                              callbacks: HistoryPaneCallbacks(
                                onOpenMeeting: controller.openMeeting,
                                onCloseMeeting: controller.closeMeeting,
                                onSetHistoryDetailTab:
                                    controller.setHistoryDetailTab,
                                onRetrySummary: controller.generateSummaryMock,
                              ),
                            );
                          },
                        ),
                    };
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MeetingWorkspaceSelector<T> extends StatefulWidget {
  const MeetingWorkspaceSelector({
    super.key,
    required this.controller,
    required this.selector,
    required this.builder,
  });

  final MeetingWorkspaceController controller;
  final T Function(MeetingWorkspaceState state) selector;
  final Widget Function(BuildContext context, T selected) builder;

  @override
  State<MeetingWorkspaceSelector<T>> createState() =>
      _MeetingWorkspaceSelectorState<T>();
}

class _MeetingWorkspaceSelectorState<T>
    extends State<MeetingWorkspaceSelector<T>> {
  late T selected = widget.selector(widget.controller.state);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant MeetingWorkspaceSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      selected = widget.selector(widget.controller.state);
      return;
    }
    oldWidget.controller.removeListener(_onStateChanged);
    widget.controller.addListener(_onStateChanged);
    selected = widget.selector(widget.controller.state);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    final nextSelected = widget.selector(widget.controller.state);
    if (nextSelected == selected) return;
    setState(() => selected = nextSelected);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, selected);
  }
}
