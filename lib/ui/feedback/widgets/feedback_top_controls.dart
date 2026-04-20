import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/application/app_status.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';
import 'package:traisender/ui/feedback/widgets/feedback_status_badge.dart';

class FeedbackTopControls extends StatelessWidget {
  final AppStatus status;
  final bool isBusy;
  final bool isRecording;
  final bool micEnabled;
  final String statusLabel;
  final Color statusColor;
  final double progress;
  final VoidCallback? onToggleRecording;
  final VoidCallback? onPickFile;
  final VoidCallback onToggleMic;

  const FeedbackTopControls({
    super.key,
    required this.status,
    required this.isBusy,
    required this.isRecording,
    required this.micEnabled,
    required this.statusLabel,
    required this.statusColor,
    required this.progress,
    required this.onToggleRecording,
    required this.onPickFile,
    required this.onToggleMic,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = MacosTheme.of(context).dividerColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dividerColor,
            width: FeedbackStyles.lineWidth,
          ),
        ),
      ),
      child: SizedBox(
        height: FeedbackStyles.controlsHeight,
        child: Padding(
          padding: FeedbackStyles.controlsPadding,
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: isRecording
                      ? Border.all(
                          color: MacosColors.systemRedColor,
                          width: FeedbackStyles.lineWidth,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(
                    FeedbackStyles.cornerRadius,
                  ),
                ),
                child: PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: isBusy ? null : onToggleRecording,
                  child: Text(
                    isRecording ? '■ DETENER' : '● GRABAR',
                    style: TextStyle(
                      letterSpacing: 0.5,
                      fontSize: 13,
                      color: isRecording ? MacosColors.systemRedColor : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: isBusy ? null : onPickFile,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_up_doc, size: 14),
                    SizedBox(width: 6),
                    Text('Archivo'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isBusy ? null : onToggleMic,
                child: Row(
                  children: [
                    Icon(
                      micEnabled
                          ? CupertinoIcons.mic_fill
                          : CupertinoIcons.mic_slash_fill,
                      size: 14,
                      color: micEnabled
                          ? MacosColors.systemGreenColor
                          : MacosColors.systemGrayColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MIC',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: micEnabled
                            ? MacosColors.systemGreenColor
                            : MacosColors.systemGrayColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FeedbackStatusBadge(
                status: status,
                label: statusLabel,
                color: statusColor,
                progress: progress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
