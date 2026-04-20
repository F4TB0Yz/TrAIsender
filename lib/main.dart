import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/features/meeting_workspace/meeting_workspace_feature.dart';
import 'package:traisender/presentation/shared/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManipulator.initialize();

  runApp(
    ProviderScope(
      child: MacosApp(
        debugShowCheckedModeBanner: false,
        theme: MacosThemeData.light().copyWith(
          canvasColor: AppMacosColors.background,
          primaryColor: AppMacosColors.accent,
        ),
        darkTheme: MacosThemeData.dark(),
        themeMode: ThemeMode.light,
        home: const MeetingWorkspaceFeature(useProductionWorkflow: true),
      ),
    ),
  );
}
