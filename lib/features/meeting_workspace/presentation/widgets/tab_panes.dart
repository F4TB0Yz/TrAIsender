import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';

import 'meeting_workspace_animated_widgets.dart';
import 'meeting_workspace_content_widgets.dart';
import 'meeting_workspace_tokens.dart';

class RecordPaneState {
  const RecordPaneState({
    required this.audioSource,
    required this.isRecording,
    required this.recordTime,
    required this.liveTranscript,
  });

  final AudioSource audioSource;
  final bool isRecording;
  final int recordTime;
  final String liveTranscript;
}

class UploadPaneState {
  const UploadPaneState({
    required this.isUploading,
    required this.uploadProgress,
    required this.uploadFileName,
  });

  final bool isUploading;
  final int uploadProgress;
  final String uploadFileName;
}

class HistoryPaneState {
  const HistoryPaneState({
    required this.history,
    required this.selectedMeeting,
    required this.historyDetailTab,
    required this.aiResult,
    required this.isAiLoading,
    required this.aiError,
  });

  final List<MeetingHistoryItem> history;
  final MeetingHistoryItem? selectedMeeting;
  final HistoryDetailTab historyDetailTab;
  final String aiResult;
  final bool isAiLoading;
  final String aiError;
}

class RecordPaneCallbacks {
  const RecordPaneCallbacks({
    required this.onSetAudioSource,
    required this.onToggleRecording,
  });

  final ValueChanged<AudioSource> onSetAudioSource;
  final VoidCallback onToggleRecording;
}

class UploadPaneCallbacks {
  const UploadPaneCallbacks({
    required this.onStartUpload,
    required this.onDroppedFile,
  });

  final VoidCallback onStartUpload;
  final Future<void> Function(String path) onDroppedFile;
}

class HistoryPaneCallbacks {
  const HistoryPaneCallbacks({
    required this.onOpenMeeting,
    required this.onCloseMeeting,
    required this.onSetHistoryDetailTab,
    required this.onRetrySummary,
  });

  final ValueChanged<MeetingHistoryItem> onOpenMeeting;
  final VoidCallback onCloseMeeting;
  final ValueChanged<HistoryDetailTab> onSetHistoryDetailTab;
  final Future<void> Function() onRetrySummary;
}

BoxDecoration meetingWorkspacePanelDecoration({double radius = 18}) {
  return BoxDecoration(
    color: MeetingWorkspaceTokens.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: MeetingWorkspaceTokens.panelBorder),
    boxShadow: const [
      BoxShadow(
        color: MeetingWorkspaceTokens.panelShadow,
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  );
}

class MeetingWorkspaceRecordPane extends StatelessWidget {
  const MeetingWorkspaceRecordPane({
    super.key,
    required this.state,
    required this.formatTime,
    required this.callbacks,
  });

  final RecordPaneState state;
  final String Function(int seconds) formatTime;
  final RecordPaneCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: meetingWorkspacePanelDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      MeetingWorkspaceSegmentButton(
                        icon: Icons.mic_rounded,
                        text: 'Solo Microfono',
                        selected: state.audioSource == AudioSource.mic,
                        disabled: state.isRecording,
                        onTap: () => callbacks.onSetAudioSource(AudioSource.mic),
                      ),
                      MeetingWorkspaceSegmentButton(
                        icon: Icons.speaker_rounded,
                        text: 'Mic + Audio del Sistema',
                        selected: state.audioSource == AudioSource.system,
                        disabled: state.isRecording,
                        onTap: () =>
                            callbacks.onSetAudioSource(AudioSource.system),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                formatTime(state.recordTime),
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Menlo',
                  fontWeight: state.isRecording ? FontWeight.w600 : FontWeight.w400,
                  color: state.isRecording
                      ? MeetingWorkspaceTokens.dangerRed
                      : const Color(0xFF9FA1AA),
                ),
              ),
              const SizedBox(width: 12),
              MeetingWorkspaceRecordButton(
                isRecording: state.isRecording,
                onTap: callbacks.onToggleRecording,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(minHeight: 360),
          padding: const EdgeInsets.all(24),
          decoration: meetingWorkspacePanelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEXTO EN VIVO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA6A8B1),
                ),
              ),
              const SizedBox(height: 16),
              if (state.liveTranscript.isEmpty)
                const SizedBox(
                  height: 280,
                  child: MeetingWorkspaceCenteredHint(
                    icon: Icons.mic_rounded,
                    text: 'Presiona grabar para iniciar la captura de audio.',
                  ),
                )
              else
                SizedBox(
                  height: 280,
                  child: SingleChildScrollView(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.5,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF2E3035),
                        ),
                        children: [
                          TextSpan(text: state.liveTranscript),
                          if (state.isRecording)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: MeetingWorkspaceBlinkingCaret(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MeetingWorkspaceUploadPane extends StatefulWidget {
  const MeetingWorkspaceUploadPane({
    super.key,
    required this.state,
    required this.callbacks,
  });

  final UploadPaneState state;
  final UploadPaneCallbacks callbacks;

  @override
  State<MeetingWorkspaceUploadPane> createState() =>
      _MeetingWorkspaceUploadPaneState();
}

class _MeetingWorkspaceUploadPaneState extends State<MeetingWorkspaceUploadPane> {
  bool isDraggingUpload = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => isDraggingUpload = true),
          onDragExited: (_) => setState(() => isDraggingUpload = false),
          onDragDone: (details) async {
            setState(() => isDraggingUpload = false);
            if (details.files.isEmpty) return;
            await widget.callbacks.onDroppedFile(details.files.first.path);
          },
          child: GestureDetector(
            onTap: widget.callbacks.onStartUpload,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 760, minHeight: 340),
              decoration: BoxDecoration(
                color: widget.state.isUploading
                    ? MeetingWorkspaceTokens.softBlue
                    : MeetingWorkspaceTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDraggingUpload
                      ? MeetingWorkspaceTokens.primaryBlue
                      : (widget.state.isUploading
                            ? MeetingWorkspaceTokens.blueBorderActive
                            : const Color(0xFFD0D2D8)),
                  width: isDraggingUpload ? 3 : 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEEEF1)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.audio_file_rounded,
                      size: 34,
                      color: MeetingWorkspaceTokens.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isDraggingUpload
                        ? 'Suelta el archivo para procesarlo'
                        : 'Arrastra tu archivo aqui',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22242A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Soporta MP3, WAV, M4A o MP4 (hasta 500MB)',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7F8492)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: MeetingWorkspaceTokens.darkText,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.state.isUploading
                          ? 'Procesando...'
                          : 'Explorar archivos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.state.isUploading) ...[
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 760),
            padding: const EdgeInsets.all(14),
            decoration: meetingWorkspacePanelDecoration(radius: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MeetingWorkspaceTokens.softBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const MeetingWorkspaceSpinIcon(
                    icon: Icons.autorenew_rounded,
                    color: MeetingWorkspaceTokens.primaryBlue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.state.uploadFileName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A2C31),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Transcribiendo (${widget.state.uploadProgress.clamp(0, 100)}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C818E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: widget.state.uploadProgress.clamp(0, 100) / 100,
                          backgroundColor: const Color(0xFFE8E9ED),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            MeetingWorkspaceTokens.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class MeetingWorkspaceHistoryPane extends StatelessWidget {
  const MeetingWorkspaceHistoryPane({
    super.key,
    required this.state,
    required this.callbacks,
  });

  final HistoryPaneState state;
  final HistoryPaneCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    if (state.selectedMeeting == null) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = state.history[index];
          return MeetingWorkspaceHistoryListItem(
            item: item,
            onTap: () => callbacks.onOpenMeeting(item),
          );
        },
      );
    }

    final meeting = state.selectedMeeting!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: callbacks.onCloseMeeting,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: Color(0xFF6F7483),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Volver al historial',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6F7483),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          meeting.title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212228),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${meeting.date} • ${meeting.length}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF797E8B)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            MeetingWorkspaceHistoryTabButton(
              text: 'Transcripcion',
              icon: Icons.description_rounded,
              selected: state.historyDetailTab == HistoryDetailTab.transcript,
              selectedColor: const Color(0xFF2E68F2),
              onTap: () =>
                  callbacks.onSetHistoryDetailTab(HistoryDetailTab.transcript),
            ),
            const SizedBox(width: 10),
            MeetingWorkspaceHistoryTabButton(
              text: 'Resumen IA',
              icon: Icons.auto_awesome_rounded,
              selected: state.historyDetailTab == HistoryDetailTab.summary,
              selectedColor: const Color(0xFFBE4D00),
              onTap: () =>
                  callbacks.onSetHistoryDetailTab(HistoryDetailTab.summary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 420),
          padding: const EdgeInsets.all(24),
          decoration: meetingWorkspacePanelDecoration(),
          child: state.historyDetailTab == HistoryDetailTab.transcript
              ? Text(
                  meeting.transcript,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF3A3D44),
                  ),
                )
              : MeetingWorkspaceSummaryPane(
                  state: state,
                  onRetrySummary: callbacks.onRetrySummary,
                ),
        ),
      ],
    );
  }
}

class MeetingWorkspaceSummaryPane extends StatelessWidget {
  const MeetingWorkspaceSummaryPane({
    super.key,
    required this.state,
    required this.onRetrySummary,
  });

  final HistoryPaneState state;
  final Future<void> Function() onRetrySummary;

  @override
  Widget build(BuildContext context) {
    if (state.isAiLoading) {
      return const MeetingWorkspaceCenteredHint(
        icon: Icons.autorenew_rounded,
        text: 'Analizando la reunion con IA...',
        spin: true,
      );
    }

    if (state.aiError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: MeetingWorkspaceTokens.dangerText,
            ),
            const SizedBox(height: 8),
            Text(
              state.aiError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MeetingWorkspaceTokens.dangerText),
            ),
            const SizedBox(height: 14),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onRetrySummary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: MeetingWorkspaceTokens.dangerSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MeetingWorkspaceTokens.dangerBorderSoft,
                    ),
                  ),
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MeetingWorkspaceTokens.dangerText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.aiResult.isEmpty) {
      return const SizedBox.shrink();
    }

    return MeetingWorkspaceMarkdownRenderer(text: state.aiResult);
  }
}
