import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_controller.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/screen_sections.dart';
import 'package:traisender/features/meeting_workspace/presentation/widgets/meeting_workspace_tokens.dart';

class MeetingWorkspaceScreen extends StatelessWidget {
  const MeetingWorkspaceScreen({super.key, required this.controller});

  final MeetingWorkspaceController controller;

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
                      ? MeetingWorkspaceCompactSection(
                          controller: controller,
                          onOpenTab: _openTab,
                          resolveHeaderTitle: _resolveHeaderTitle,
                        )
                      : MeetingWorkspaceDesktopSection(
                          controller: controller,
                          onOpenTab: _openTab,
                          resolveHeaderTitle: _resolveHeaderTitle,
                        ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _resolveHeaderTitle(MainTab activeTab, bool hasSelectedMeeting) {
    if (activeTab == MainTab.record) return 'Nueva Transcripcion';
    if (activeTab == MainTab.upload) return 'Importar Audio';
    if (activeTab == MainTab.history && !hasSelectedMeeting) {
      return 'Documentos Anteriores';
    }
    return 'Detalle de Reunion';
  }

  void _openTab(MainTab tab, {bool clearMeeting = false}) {
    controller.setTab(tab);
    if (clearMeeting) {
      controller.closeMeeting();
    }
  }
}
