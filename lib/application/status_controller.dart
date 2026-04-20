import 'package:flutter/foundation.dart';
import 'package:traisender/application/app_status.dart';
import 'package:traisender/domain/history_item.dart';
import 'package:traisender/infrastructure/history_storage.dart';
import 'package:window_manager/window_manager.dart';

class StatusController extends ChangeNotifier {
  final HistoryStorage _historyStorage;

  AppStatus _status = AppStatus.idle;
  String _text = '';
  String _transcription = '';
  bool _isRecording = false;
  bool _micEnabled = true;
  List<HistoryItem> _history = [];
  double _progress = 0.0;
  String _progressLabel = '';
  HistoryItem? _viewingItem;

  AppStatus get status => _status;
  String get text => _text;
  String get transcription => _transcription;
  bool get isRecording => _isRecording;
  bool get micEnabled => _micEnabled;
  List<HistoryItem> get history => _history;
  double get progress => _progress;
  String get progressLabel => _progressLabel;
  HistoryItem? get viewingItem => _viewingItem;

  Future<void> Function(String path)? onProcessAudio;
  Future<void> Function()? onToggleRecording;
  void Function(bool)? onToggleMic;

  StatusController({HistoryStorage? historyStorage})
    : _historyStorage = historyStorage ?? HistoryStorage() {
    _loadHistory();
  }

  void updateProgress(double value, {String label = ''}) {
    _progress = value.clamp(0.0, 1.0);
    if (label.isNotEmpty) _progressLabel = label;
    notifyListeners();
  }

  void updatePartialSummary(String partial) {
    _text = partial;
    notifyListeners();
  }

  void updateStatus(
    AppStatus newStatus, {
    String text = '',
    String transcription = '',
  }) {
    _status = newStatus;
    if (text.isNotEmpty) _text = text;
    if (transcription.isNotEmpty) _transcription = transcription;

    if (newStatus == AppStatus.transcribing) {
      _progress = 0.0;
      _progressLabel = 'Iniciando...';
      _viewingItem = null;
    }
    if (newStatus == AppStatus.summarizing) {
      _progress = 0.0;
      _progressLabel = 'Conectando con Gemini...';
    }

    if (newStatus == AppStatus.recording) _isRecording = true;
    if (newStatus == AppStatus.idle ||
        newStatus == AppStatus.completed ||
        newStatus == AppStatus.error) {
      _isRecording = false;
    }

    if (newStatus == AppStatus.completed) {
      _addToHistory(_transcription, _text);
    }

    notifyListeners();

    if (newStatus != AppStatus.idle) {
      windowManager.show();
      windowManager.focus();
    }
  }

  void setRecording(bool recording) {
    _isRecording = recording;
    notifyListeners();
  }

  void setMicEnabled(bool enabled) {
    _micEnabled = enabled;
    onToggleMic?.call(enabled);
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    _history = await _historyStorage.load();
    notifyListeners();
  }

  Future<void> _addToHistory(String transcription, String summary) async {
    if (transcription.isEmpty || summary.isEmpty) return;

    final newItem = HistoryItem(
      date: DateTime.now().toString().split('.')[0],
      transcription: transcription,
      summary: summary,
    );

    _history = await _historyStorage.prependAndSave(newItem);
    notifyListeners();
  }

  void clear() {
    _status = AppStatus.idle;
    _text = '';
    _transcription = '';
    notifyListeners();
  }

  void viewHistoryItem(HistoryItem item) {
    _viewingItem = item;
    notifyListeners();
  }

  void closeHistoryView() {
    _viewingItem = null;
    notifyListeners();
  }

  void loadFromHistory(HistoryItem item) {
    viewHistoryItem(item);
  }
}
