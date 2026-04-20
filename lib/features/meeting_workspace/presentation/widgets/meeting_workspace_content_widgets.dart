import 'package:flutter/material.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';

import 'meeting_workspace_animated_widgets.dart';
import 'meeting_workspace_tokens.dart';

class MeetingWorkspaceRecordButton extends StatelessWidget {
  const MeetingWorkspaceRecordButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MeetingWorkspaceTokens.motionFast,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isRecording
              ? MeetingWorkspaceTokens.dangerRed
              : MeetingWorkspaceTokens.darkText,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isRecording
                  ? const Color(0x44D81E3B)
                  : const Color(0x22000000),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class MeetingWorkspaceSegmentButton extends StatelessWidget {
  const MeetingWorkspaceSegmentButton({
    super.key,
    required this.icon,
    required this.text,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: MeetingWorkspaceTokens.motionMedium,
        opacity: disabled ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? const Color(0xFF1E2129)
                    : const Color(0xFF6E7380),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF1E2129)
                      : const Color(0xFF6E7380),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeetingWorkspaceHistoryListItem extends StatelessWidget {
  const MeetingWorkspaceHistoryListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final MeetingHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E3E8)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD2E1FF)),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: MeetingWorkspaceTokens.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF202229),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.date} • ${item.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7B8090),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFBAC0CC)),
            ],
          ),
        ),
      ),
    );
  }
}

class MeetingWorkspaceHistoryTabButton extends StatelessWidget {
  const MeetingWorkspaceHistoryTabButton({
    super.key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MeetingWorkspaceTokens.motionFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(MeetingWorkspaceTokens.radiusPill),
            color: selected
                ? selectedColor.withValues(alpha: 0.12)
                : MeetingWorkspaceTokens.softPanel,
            border: Border.all(
              color: selected
                  ? selectedColor.withValues(alpha: 0.35)
                  : const Color(0xFFE3E4E9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? selectedColor : const Color(0xFF7B8090),
              ),
              const SizedBox(width: 7),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? selectedColor : const Color(0xFF626877),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeetingWorkspaceCenteredHint extends StatelessWidget {
  const MeetingWorkspaceCenteredHint({
    super.key,
    required this.icon,
    required this.text,
    this.spin = false,
  });

  final IconData icon;
  final String text;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spin)
            MeetingWorkspaceSpinIcon(
              icon: icon,
              color: const Color(0xFF6D7383),
              size: 38,
            )
          else
            Icon(
              icon,
              size: 42,
              color: MeetingWorkspaceTokens.iconMuted,
            ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: MeetingWorkspaceTokens.hintText,
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingWorkspaceMarkdownRenderer extends StatelessWidget {
  const MeetingWorkspaceMarkdownRenderer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map(_buildLine).toList(),
    );
  }

  Widget _buildLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return const SizedBox(height: 8);

    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Color(0xFFBE4D00),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _formattedText(
                line.substring(3),
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MeetingWorkspaceTokens.bodyText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: _formattedText(
          line.substring(2),
          const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: MeetingWorkspaceTokens.bodyText,
          ),
        ),
      );
    }

    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '•',
                style: TextStyle(color: MeetingWorkspaceTokens.metaText),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _formattedText(
                line.substring(2),
                const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: MeetingWorkspaceTokens.bodyTextSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _formattedText(
        line,
        const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: MeetingWorkspaceTokens.bodyTextSecondary,
        ),
      ),
    );
  }

  Widget _formattedText(String source, TextStyle baseStyle) {
    final parts = source.split(RegExp(r'(\*\*.*?\*\*)'));
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: parts.map((part) {
          if (part.startsWith('**') && part.endsWith('**') && part.length > 4) {
            return TextSpan(
              text: part.substring(2, part.length - 2),
              style: baseStyle.copyWith(fontWeight: FontWeight.w700),
            );
          }
          return TextSpan(text: part);
        }).toList(),
      ),
    );
  }
}
