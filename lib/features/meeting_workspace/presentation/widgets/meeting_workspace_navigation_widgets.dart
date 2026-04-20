import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';

import 'meeting_workspace_animated_widgets.dart';
import 'meeting_workspace_tokens.dart';

class MeetingWorkspaceTopBar extends StatelessWidget {
  const MeetingWorkspaceTopBar({
    super.key,
    required this.title,
    required this.isRecording,
    required this.recordTime,
    required this.isUploading,
    required this.uploadProgress,
    required this.formatTime,
  });

  final String title;
  final bool isRecording;
  final int recordTime;
  final bool isUploading;
  final int uploadProgress;
  final String Function(int seconds) formatTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: MeetingWorkspaceTokens.topBarDivider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MeetingWorkspaceTokens.topBarTitle,
              ),
            ),
          ),
          if (isRecording)
            MeetingWorkspaceStatusBadge(
              text: 'Grabando ${formatTime(recordTime)}',
              icon: Icons.fiber_manual_record,
              iconColor: MeetingWorkspaceTokens.dangerRed,
              textColor: MeetingWorkspaceTokens.recordingText,
              background: MeetingWorkspaceTokens.recordingSoft,
              border: MeetingWorkspaceTokens.recordingBorder,
              pulse: true,
            ),
          if (isRecording && isUploading) const SizedBox(width: 8),
          if (isUploading)
            MeetingWorkspaceStatusBadge(
              text: 'Procesando ${uploadProgress.clamp(0, 100)}%',
              icon: Icons.autorenew_rounded,
              iconColor: MeetingWorkspaceTokens.deepBlue,
              textColor: MeetingWorkspaceTokens.blueTextStrong,
              background: MeetingWorkspaceTokens.softBlue,
              border: MeetingWorkspaceTokens.blueBorderSoft,
              spin: true,
            ),
        ],
      ),
    );
  }
}

class MeetingWorkspaceNavigation extends StatelessWidget {
  const MeetingWorkspaceNavigation({
    super.key,
    required this.compact,
    required this.activeTab,
    required this.onOpenTab,
  });

  final bool compact;
  final MainTab activeTab;
  final void Function(MainTab tab, {bool clearMeeting}) onOpenTab;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MeetingWorkspaceCompactNavButton(
            label: 'Grabar',
            icon: Icons.mic_rounded,
            active: activeTab == MainTab.record,
            onTap: () => onOpenTab(MainTab.record, clearMeeting: true),
          ),
          MeetingWorkspaceCompactNavButton(
            label: 'Archivo',
            icon: Icons.upload_file_rounded,
            active: activeTab == MainTab.upload,
            onTap: () => onOpenTab(MainTab.upload, clearMeeting: true),
          ),
          MeetingWorkspaceCompactNavButton(
            label: 'Historial',
            icon: Icons.history_rounded,
            active: activeTab == MainTab.history,
            onTap: () => onOpenTab(MainTab.history),
          ),
        ],
      );
    }

    final baseText = MacosTheme.of(context).typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'WORKSPACE',
            style: baseText.caption2.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: MeetingWorkspaceTokens.labelMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        MeetingWorkspaceSidebarItem(
          icon: Icons.mic_rounded,
          label: 'Grabar Reunion',
          active: activeTab == MainTab.record,
          onTap: () => onOpenTab(MainTab.record, clearMeeting: true),
        ),
        MeetingWorkspaceSidebarItem(
          icon: Icons.upload_file_rounded,
          label: 'Procesar Archivo',
          active: activeTab == MainTab.upload,
          onTap: () => onOpenTab(MainTab.upload, clearMeeting: true),
        ),
        MeetingWorkspaceSidebarItem(
          icon: Icons.schedule_rounded,
          label: 'Historial',
          active: activeTab == MainTab.history,
          onTap: () => onOpenTab(MainTab.history),
        ),
        const Spacer(),
        MeetingWorkspaceSidebarItem(
          icon: Icons.settings_rounded,
          label: 'Preferencias',
          active: false,
          onTap: () {},
        ),
      ],
    );
  }
}

class MeetingWorkspaceSidebarItem extends StatelessWidget {
  const MeetingWorkspaceSidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0x14000000) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active
                      ? MeetingWorkspaceTokens.primaryBlue
                      : MeetingWorkspaceTokens.sidebarIconInactive,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? MeetingWorkspaceTokens.sidebarTextActive
                        : MeetingWorkspaceTokens.sidebarTextInactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MeetingWorkspaceCompactNavButton extends StatelessWidget {
  const MeetingWorkspaceCompactNavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? MeetingWorkspaceTokens.darkText
              : MeetingWorkspaceTokens.neutralPill,
          borderRadius: BorderRadius.circular(MeetingWorkspaceTokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active
                  ? Colors.white
                  : MeetingWorkspaceTokens.neutralPillText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : MeetingWorkspaceTokens.neutralPillText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeetingWorkspaceStatusBadge extends StatelessWidget {
  const MeetingWorkspaceStatusBadge({
    super.key,
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.background,
    required this.border,
    this.pulse = false,
    this.spin = false,
  });

  final String text;
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final Color background;
  final Color border;
  final bool pulse;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spin)
            MeetingWorkspaceSpinIcon(icon: icon, color: iconColor, size: 13)
          else if (pulse)
            MeetingWorkspacePulseDot(color: iconColor)
          else
            Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
