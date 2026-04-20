import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/ui/feedback/feedback_styles.dart';

class FeedbackContentPanel extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final String summaryText;
  final String transcriptionText;

  const FeedbackContentPanel({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.summaryText,
    required this.transcriptionText,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = MacosColors.systemBlueColor;
    final inactiveColor = MacosColors.systemGrayColor.withValues(alpha: 0.6);
    final tabs = const {0: 'RESUMEN IA', 1: 'TRANSCRIPCIÓN'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: tabs.entries.map((entry) {
            final isActive = selectedTab == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 18),
              child: GestureDetector(
                onTap: () => onTabChanged(entry.key),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      height: FeedbackStyles.activeUnderlineHeight,
                      width: 86,
                      color: isActive ? activeColor : Color(0x00000000),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: DecoratedBox(
            decoration: FeedbackStyles.panelDecoration(context),
            child: Padding(
              padding: FeedbackStyles.panelPadding,
              child: SingleChildScrollView(
                child: SelectableText(
                  selectedTab == 0 ? summaryText : transcriptionText,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontFamily: selectedTab == 1 ? '.SF Mono' : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
