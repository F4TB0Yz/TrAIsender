import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';

class FeedbackLoadingState extends StatefulWidget {
  final bool isTranscribing;
  final double progress;
  final String progressLabel;
  final bool showPartialSummary;
  final String partialSummary;

  const FeedbackLoadingState({
    super.key,
    required this.isTranscribing,
    required this.progress,
    required this.progressLabel,
    required this.showPartialSummary,
    required this.partialSummary,
  });

  @override
  State<FeedbackLoadingState> createState() => _FeedbackLoadingStateState();
}

class _FeedbackLoadingStateState extends State<FeedbackLoadingState> {
  final ScrollController _summaryScrollController = ScrollController();

  @override
  void didUpdateWidget(covariant FeedbackLoadingState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isTranscribing &&
        widget.partialSummary != oldWidget.partialSummary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_summaryScrollController.hasClients) return;
        _summaryScrollController.animateTo(
          _summaryScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _summaryScrollController.dispose();
    super.dispose();
  }

  Widget _buildProgressBar(BuildContext context) {
    return SizedBox(
      height: FeedbackStyles.progressBarHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: MacosTheme.of(context).dividerColor),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widget.progress > 0
                ? widget.progress.clamp(0, 1)
                : 0.05,
            child: const ColoredBox(color: MacosColors.systemOrangeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required bool active,
    required bool done,
    required Color activeColor,
  }) {
    final color = done
        ? MacosColors.systemGreenColor
        : active
        ? activeColor
        : MacosColors.systemGrayColor.withValues(alpha: 0.4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? color : Color(0x00000000),
              border: Border.all(color: color, width: FeedbackStyles.lineWidth),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isTranscribing
        ? MacosColors.systemOrangeColor
        : MacosColors.systemBlueColor;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          top: FeedbackStyles.loadingTopOffset,
          left: 14,
          right: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              onEnd: () {
                if (mounted) setState(() {});
              },
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Row(
                children: [
                  Icon(
                    widget.isTranscribing
                        ? CupertinoIcons.waveform
                        : CupertinoIcons.sparkles,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isTranscribing ? 'TRANSCRIBIENDO' : 'IA ANALIZANDO',
                    style: FeedbackStyles.denseCapsStyle(
                      color: statusColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.isTranscribing) ...[
              _buildProgressBar(context),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.progressLabel,
                      style: FeedbackStyles.monoStyle(
                        fontSize: 12,
                        color: MacosColors.systemGrayColor,
                      ),
                    ),
                  ),
                  Text(
                    '${(widget.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: FeedbackStyles.monoStyle(
                      fontSize: 12,
                      color: MacosColors.systemGrayColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                widget.progressLabel,
                style: FeedbackStyles.monoStyle(
                  fontSize: 12,
                  color: MacosColors.systemGrayColor,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: FeedbackStyles.summaryPreviewMaxHeight,
                ),
                child: DecoratedBox(
                  decoration: FeedbackStyles.summaryPreviewDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      controller: _summaryScrollController,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, height: 1.5),
                          children: [
                            TextSpan(
                              text:
                                  widget.showPartialSummary &&
                                      widget.partialSummary.isNotEmpty
                                  ? widget.partialSummary
                                  : 'Esperando salida de IA...',
                              style: const TextStyle(
                                color: MacosColors.textColor,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.2, end: 1),
                                duration: const Duration(milliseconds: 600),
                                onEnd: () {
                                  if (mounted) setState(() {});
                                },
                                builder: (context, value, child) =>
                                    Opacity(opacity: value, child: child),
                                child: Text(
                                  ' |',
                                  style: TextStyle(color: statusColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStep(
                  label: 'TRANSCRIPCIÓN',
                  active: widget.isTranscribing,
                  done: !widget.isTranscribing,
                  activeColor: MacosColors.systemOrangeColor,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  height: 1,
                  child: ColoredBox(color: MacosTheme.of(context).dividerColor),
                ),
                const SizedBox(width: 8),
                _buildStep(
                  label: 'RESUMEN IA',
                  active: !widget.isTranscribing,
                  done: false,
                  activeColor: MacosColors.systemBlueColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
