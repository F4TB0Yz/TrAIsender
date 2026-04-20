import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';

class NotificationService {
  Future<void> init() async {
    await localNotifier.setup(
      appName: 'TrAIsender',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  void show({
    required String title,
    required String body,
    required bool focusWindow,
  }) {
    final notification = LocalNotification(
      title: title,
      body: body,
      actions: [LocalNotificationAction(text: 'Ver')],
    );
    notification.onClick = () {
      if (focusWindow) windowManager.show();
    };
    notification.show();
  }
}
