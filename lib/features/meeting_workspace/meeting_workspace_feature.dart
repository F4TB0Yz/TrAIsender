import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traisender/data/shared/bootstrap/app_bootstrap.dart';
import 'package:traisender/presentation/shared/controllers/workflow_status_notifier.dart';
import 'package:traisender/features/meeting_workspace/data/repositories/meeting_workspace_history_storage_repository.dart';
import 'package:traisender/features/meeting_workspace/data/repositories/meeting_workspace_mock_history_repository.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_controller.dart';
import 'package:traisender/features/meeting_workspace/presentation/screens/meeting_workspace_screen.dart';

class MeetingWorkspaceFeature extends StatefulWidget {
  const MeetingWorkspaceFeature({
    super.key,
    this.useProductionWorkflow = false,
  });

  final bool useProductionWorkflow;

  @override
  State<MeetingWorkspaceFeature> createState() => _MeetingWorkspaceFeatureState();
}

class _MeetingWorkspaceFeatureState extends State<MeetingWorkspaceFeature> {
  late final MeetingWorkspaceController _controller;
  StatusController? _statusController;
  AppBootstrap? _bootstrap;

  @override
  void initState() {
    super.initState();
    if (widget.useProductionWorkflow) {
      _statusController = StatusController();
      _bootstrap = AppBootstrap();
      _controller = MeetingWorkspaceController(
        historyRepository: MeetingWorkspaceHistoryStorageRepository(),
        statusController: _statusController,
      );
      unawaited(_bootstrap!.start(_statusController!));
    } else {
      _controller = MeetingWorkspaceController(
        historyRepository: const MeetingWorkspaceMockHistoryRepository(),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _statusController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeetingWorkspaceScreen(controller: _controller);
  }
}
