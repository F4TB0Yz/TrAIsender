import 'package:system_tray/system_tray.dart';
import 'package:traisender/domain/shared/entities/app_status.dart';

class TrayController {
  final SystemTray _systemTray;
  final AppStatus Function() _statusProvider;
  final bool Function() _micEnabledProvider;
  final Future<bool> Function() _isRecordingProvider;
  final Future<void> Function() _onToggleRecording;
  final void Function(bool enabled) _onSetMicEnabled;
  final Future<void> Function() _onOpenDashboard;
  final void Function() _onExit;

  TrayController({
    required SystemTray systemTray,
    required AppStatus Function() statusProvider,
    required bool Function() micEnabledProvider,
    required Future<bool> Function() isRecordingProvider,
    required Future<void> Function() onToggleRecording,
    required void Function(bool enabled) onSetMicEnabled,
    required Future<void> Function() onOpenDashboard,
    required void Function() onExit,
  }) : _systemTray = systemTray,
       _statusProvider = statusProvider,
       _micEnabledProvider = micEnabledProvider,
       _isRecordingProvider = isRecordingProvider,
       _onToggleRecording = onToggleRecording,
       _onSetMicEnabled = onSetMicEnabled,
       _onOpenDashboard = onOpenDashboard,
       _onExit = onExit;

  Future<void> init() async {
    await _systemTray.initSystemTray(iconPath: 'assets/app_icon.webp');
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick ||
          eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }

  Future<void> refreshMenu() async {
    final recording = await _isRecordingProvider();
    String statusLabel = 'TrAIsender';

    switch (_statusProvider()) {
      case AppStatus.recording:
        statusLabel = '🔴 Grabando...';
        break;
      case AppStatus.transcribing:
        statusLabel = '⏳ Transcribiendo...';
        break;
      case AppStatus.summarizing:
        statusLabel = '🧠 Analizando...';
        break;
      case AppStatus.error:
        statusLabel = '⚠️ Error';
        break;
      default:
        if (recording) statusLabel = '🔴 Grabando...';
    }

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: statusLabel, enabled: false),
      MenuSeparator(),
      MenuItemCheckbox(
        label: '🎙️ Detectar micrófono',
        checked: _micEnabledProvider(),
        onClicked: (_) {
          _onSetMicEnabled(!_micEnabledProvider());
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: recording ? 'Detener Grabación' : 'Grabar Reunión',
        onClicked: (_) async => _onToggleRecording(),
      ),
      MenuItemLabel(
        label: 'Abrir Dashboard',
        onClicked: (_) async => _onOpenDashboard(),
      ),
      MenuSeparator(),
      MenuItemLabel(label: 'Salir', onClicked: (_) => _onExit()),
    ]);

    await _systemTray.setContextMenu(menu);
  }
}
