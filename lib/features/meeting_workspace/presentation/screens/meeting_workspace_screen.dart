import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_controller.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_state.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/meeting_workspace_animated_widgets.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/meeting_workspace_content_widgets.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/meeting_workspace_navigation_widgets.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/meeting_workspace_tokens.dart';

class MeetingWorkspaceScreen extends StatefulWidget {
  const MeetingWorkspaceScreen({super.key, required this.controller});

  final MeetingWorkspaceController controller;

  @override
  State<MeetingWorkspaceScreen> createState() => _MeetingWorkspaceScreenState();
}

class _MeetingWorkspaceScreenState extends State<MeetingWorkspaceScreen> {
  late final MeetingWorkspaceController _controller = widget.controller;
  bool _isDraggingUpload = false;

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      children: [
        ContentArea(
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 940;
                return Container(
                  color: MeetingWorkspaceTokens.pageBackground,
                  child: compact
                      ? _buildCompactLayout(context)
                      : _buildDesktopLayout(context),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentView(BuildContext context, MeetingWorkspaceState state) {
    switch (state.activeTab) {
      case MainTab.record:
        return _buildRecordView(context, state);
      case MainTab.upload:
        return _buildUploadView(context, state);
      case MainTab.history:
        return _buildHistoryView(context, state);
    }
  }

  String _headerTitle(MeetingWorkspaceState state) {
    if (state.activeTab == MainTab.record) return 'Nueva Transcripcion';
    if (state.activeTab == MainTab.upload) return 'Importar Audio';
    if (state.activeTab == MainTab.history && state.selectedMeeting == null) {
      return 'Documentos Anteriores';
    }
    return 'Detalle de Reunion';
  }

  void _openTab(MainTab tab, {bool clearMeeting = false}) {
    _controller.setTab(tab);
    if (clearMeeting) {
      _controller.closeMeeting();
    }
  }

  BoxDecoration _panelDecoration({double radius = 18}) {
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

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        Expanded(child: _buildMainPanel(context)),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      children: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: MeetingWorkspaceTokens.compactBackground,
              child: Row(
                children: [
                  Expanded(
                    child: MeetingWorkspaceNavigation(
                      compact: true,
                      state: state,
                      onOpenTab: _openTab,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(child: _buildMainPanel(context)),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 256,
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 24),
      decoration: BoxDecoration(
        color: MeetingWorkspaceTokens.compactBackground.withValues(alpha: 0.75),
        border: Border(
          right: BorderSide(
            color: MeetingWorkspaceTokens.panelBorder.withValues(alpha: 0.75),
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return MeetingWorkspaceNavigation(
            compact: false,
            state: _controller.state,
            onOpenTab: _openTab,
          );
        },
      ),
    );
  }

  Widget _buildMainPanel(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return _buildCurrentView(context, _controller.state);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return MeetingWorkspaceTopBar(
          title: _headerTitle(state),
          state: state,
          formatTime: _controller.formatTime,
        );
      },
    );
  }

  Widget _buildRecordView(BuildContext context, MeetingWorkspaceState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _panelDecoration(),
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
                        onTap: () => _controller.setAudioSource(AudioSource.mic),
                      ),
                      MeetingWorkspaceSegmentButton(
                        icon: Icons.speaker_rounded,
                        text: 'Mic + Audio del Sistema',
                        selected: state.audioSource == AudioSource.system,
                        disabled: state.isRecording,
                        onTap: () => _controller.setAudioSource(AudioSource.system),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                _controller.formatTime(state.recordTime),
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Menlo',
                  fontWeight:
                      state.isRecording ? FontWeight.w600 : FontWeight.w400,
                  color: state.isRecording
                      ? MeetingWorkspaceTokens.dangerRed
                      : const Color(0xFF9FA1AA),
                ),
              ),
              const SizedBox(width: 12),
              MeetingWorkspaceRecordButton(
                isRecording: state.isRecording,
                onTap: _controller.toggleRecording,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(minHeight: 360),
          padding: const EdgeInsets.all(24),
          decoration: _panelDecoration(),
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

  Widget _buildUploadView(BuildContext context, MeetingWorkspaceState state) {
    return Column(
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => _isDraggingUpload = true),
          onDragExited: (_) => setState(() => _isDraggingUpload = false),
          onDragDone: (details) async {
            setState(() => _isDraggingUpload = false);
            if (details.files.isEmpty) return;
            await _controller.processDroppedFile(details.files.first.path);
          },
          child: GestureDetector(
            onTap: _controller.startFakeUpload,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 760, minHeight: 340),
              decoration: BoxDecoration(
                color: state.isUploading
                    ? MeetingWorkspaceTokens.softBlue
                    : MeetingWorkspaceTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isDraggingUpload
                      ? MeetingWorkspaceTokens.primaryBlue
                      : (state.isUploading
                            ? MeetingWorkspaceTokens.blueBorderActive
                            : const Color(0xFFD0D2D8)),
                  width: _isDraggingUpload ? 3 : 2,
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
                    _isDraggingUpload
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
                      state.isUploading ? 'Procesando...' : 'Explorar archivos',
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
        if (state.isUploading) ...[
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 760),
            padding: const EdgeInsets.all(14),
            decoration: _panelDecoration(radius: 14),
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
                              state.uploadFileName,
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
                            'Transcribiendo (${state.uploadProgress.clamp(0, 100)}%)',
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
                          value: state.uploadProgress.clamp(0, 100) / 100,
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

  Widget _buildHistoryView(BuildContext context, MeetingWorkspaceState state) {
    if (state.selectedMeeting == null) {
      return Column(
        children: state.history
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MeetingWorkspaceHistoryListItem(
                  item: item,
                  onTap: () => _controller.openMeeting(item),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _controller.closeMeeting,
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
          state.selectedMeeting!.title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212228),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${state.selectedMeeting!.date} • ${state.selectedMeeting!.length}',
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
                  _controller.setHistoryDetailTab(HistoryDetailTab.transcript),
            ),
            const SizedBox(width: 10),
            MeetingWorkspaceHistoryTabButton(
              text: 'Resumen IA',
              icon: Icons.auto_awesome_rounded,
              selected: state.historyDetailTab == HistoryDetailTab.summary,
              selectedColor: const Color(0xFFBE4D00),
              onTap: () =>
                  _controller.setHistoryDetailTab(HistoryDetailTab.summary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 420),
          padding: const EdgeInsets.all(24),
          decoration: _panelDecoration(),
          child: state.historyDetailTab == HistoryDetailTab.transcript
              ? Text(
                  state.selectedMeeting!.transcript,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF3A3D44),
                  ),
                )
              : _buildSummaryPane(state),
        ),
      ],
    );
  }

  Widget _buildSummaryPane(MeetingWorkspaceState state) {
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
                onTap: _controller.generateSummaryMock,
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
