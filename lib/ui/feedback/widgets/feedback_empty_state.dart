import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';

class FeedbackEmptyState extends StatelessWidget {
  final bool isDragging;
  final VoidCallback? onPickFile;

  const FeedbackEmptyState({
    super.key,
    required this.isDragging,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: FeedbackStyles.dropZoneDecoration(
          context,
          isDragging: isDragging,
        ),
        child: Padding(
          padding: FeedbackStyles.emptyStatePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.arrow_down_to_line,
                size: 20,
                color: MacosColors.systemGrayColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'Arrastra un audio o video',
                style: TextStyle(
                  fontSize: 13,
                  color: MacosColors.systemGrayColor,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onPickFile,
                child: const Text(
                  '— o — Seleccionar archivo',
                  style: TextStyle(
                    fontSize: 12,
                    color: MacosColors.systemBlueColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
