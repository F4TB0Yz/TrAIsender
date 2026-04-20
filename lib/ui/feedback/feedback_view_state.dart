import 'dart:ui' show Color;

import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/application/app_status.dart';
import 'package:traisender/application/status_controller.dart';
import 'package:traisender/domain/history_item.dart';

class FeedbackViewState {
  final AppStatus status;
  final String text;
  final String transcription;
  final bool isRecording;
  final bool micEnabled;
  final List<HistoryItem> history;
  final double progress;
  final String progressLabel;
  final HistoryItem? viewingItem;

  const FeedbackViewState({
    required this.status,
    required this.text,
    required this.transcription,
    required this.isRecording,
    required this.micEnabled,
    required this.history,
    required this.progress,
    required this.progressLabel,
    required this.viewingItem,
  });

  factory FeedbackViewState.fromController(StatusController controller) {
    return FeedbackViewState(
      status: controller.status,
      text: controller.text,
      transcription: controller.transcription,
      isRecording: controller.isRecording,
      micEnabled: controller.micEnabled,
      history: controller.history,
      progress: controller.progress,
      progressLabel: controller.progressLabel,
      viewingItem: controller.viewingItem,
    );
  }

  bool get isTranscribing => status == AppStatus.transcribing;
  bool get isSummarizing => status == AppStatus.summarizing;
  bool get isLoading => isTranscribing || isSummarizing;

  bool get isBusy =>
      status != AppStatus.idle &&
      status != AppStatus.completed &&
      status != AppStatus.error &&
      status != AppStatus.recording;

  bool get showHistory => history.isNotEmpty;
  bool get showActiveProcessBanner => viewingItem != null && isLoading;
  bool get showEmptyState =>
      status == AppStatus.idle && text.isEmpty && transcription.isEmpty;
  bool get showPartialSummary => !isTranscribing && text.isNotEmpty;

  String get statusLabel {
    switch (status) {
      case AppStatus.recording:
        return 'Grabando...';
      case AppStatus.transcribing:
        return 'Transcribiendo...';
      case AppStatus.summarizing:
        return 'IA Analizando...';
      case AppStatus.error:
        return 'Error';
      default:
        return 'Listo';
    }
  }

  Color get statusColor {
    switch (status) {
      case AppStatus.recording:
        return MacosColors.systemRedColor;
      case AppStatus.transcribing:
        return MacosColors.systemOrangeColor;
      case AppStatus.summarizing:
        return MacosColors.systemBlueColor;
      case AppStatus.error:
        return MacosColors.systemRedColor;
      default:
        return MacosColors.systemGreenColor;
    }
  }
}
