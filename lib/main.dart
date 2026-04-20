import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:macos_ui/macos_ui.dart';
import 'package:traisender/application/app_bootstrap.dart';
import 'package:traisender/application/status_controller.dart';
import 'package:traisender/ui/feedback_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManipulator.initialize();

  final statusController = StatusController();

  runApp(
    MacosApp(
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: FeedbackWindow(controller: statusController),
    ),
  );

  AppBootstrap().start(statusController);
}
