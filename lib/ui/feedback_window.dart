import 'dart:convert';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppStatus { idle, recording, transcribing, summarizing, completed, error }

class HistoryItem {
  final String date;
  final String transcription;
  final String summary;

  HistoryItem({required this.date, required this.transcription, required this.summary});

  Map<String, dynamic> toJson() => {
    'date': date,
    'transcription': transcription,
    'summary': summary,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    date: json['date'],
    transcription: json['transcription'],
    summary: json['summary'],
  );
}

class StatusController extends ChangeNotifier {
  AppStatus _status = AppStatus.idle;
  String _text = '';
  String _transcription = '';
  bool _isRecording = false;
  bool _micEnabled = true;
  List<HistoryItem> _history = [];

  AppStatus get status => _status;
  String get text => _text; // This will hold the summary
  String get transcription => _transcription;
  bool get isRecording => _isRecording;
  bool get micEnabled => _micEnabled;
  List<HistoryItem> get history => _history;

  Future<void> Function(String path)? onProcessAudio;
  Future<void> Function()? onToggleRecording;
  void Function(bool)? onToggleMic;

  StatusController() {
    _loadHistory();
  }

  void updateStatus(AppStatus newStatus, {String text = '', String transcription = ''}) {
    _status = newStatus;
    if (text.isNotEmpty) _text = text;
    if (transcription.isNotEmpty) _transcription = transcription;
    
    if (newStatus == AppStatus.recording) _isRecording = true;
    if (newStatus == AppStatus.idle || newStatus == AppStatus.completed || newStatus == AppStatus.error) {
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
    if (onToggleMic != null) onToggleMic!(enabled);
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('history');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _history = decoded.map((item) => HistoryItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _addToHistory(String transcription, String summary) async {
    if (transcription.isEmpty || summary.isEmpty) return;
    
    final newItem = HistoryItem(
      date: DateTime.now().toString().split('.')[0],
      transcription: transcription,
      summary: summary,
    );
    
    _history.insert(0, newItem);
    if (_history.length > 10) _history.removeLast();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history', jsonEncode(_history.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void clear() {
    _status = AppStatus.idle;
    _text = '';
    _transcription = '';
    notifyListeners();
  }

  void loadFromHistory(HistoryItem item) {
    _status = AppStatus.completed;
    _transcription = item.transcription;
    _text = item.summary;
    notifyListeners();
  }
}

class FeedbackWindow extends StatefulWidget {
  final StatusController controller;

  const FeedbackWindow({super.key, required this.controller});

  @override
  State<FeedbackWindow> createState() => _FeedbackWindowState();
}

class _FeedbackWindowState extends State<FeedbackWindow> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return MacosScaffold(
          toolBar: const ToolBar(
            centerTitle: true,
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return DropTarget(
                  onDragDone: (details) {
                    if (details.files.isNotEmpty && widget.controller.onProcessAudio != null) {
                      widget.controller.onProcessAudio!(details.files.first.path);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopControls(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildMainContent(),
                        ),
                        if (widget.controller.history.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildHistorySection(),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopControls() {
    final bool isRecording = widget.controller.isRecording;
    final bool isBusy = widget.controller.status != AppStatus.idle && 
                       widget.controller.status != AppStatus.completed &&
                       widget.controller.status != AppStatus.error &&
                       widget.controller.status != AppStatus.recording;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosColors.systemGrayColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Botón de Grabación
          PushButton(
            controlSize: ControlSize.large,
            secondary: true,
            onPressed: isBusy ? null : () {
              if (widget.controller.onToggleRecording != null) {
                widget.controller.onToggleRecording!();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRecording ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
                  color: isRecording ? MacosColors.systemRedColor : null,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(isRecording ? 'Detener Grabación' : 'Iniciar Grabación'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Botón Subir Archivo (Permanente)
          PushButton(
            controlSize: ControlSize.large,
            secondary: true,
            onPressed: isBusy ? null : () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['wav', 'mp3', 'm4a', 'mp4', 'mov', 'm4v'],
              );
              if (result != null && widget.controller.onProcessAudio != null) {
                widget.controller.onProcessAudio!(result.files.single.path!);
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.folder, size: 18),
                const SizedBox(width: 8),
                Text('Subir Archivo'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Toggle Mic
          MacosTooltip(
            message: 'Detectar mi micrófono',
            child: MacosCheckbox(
              value: widget.controller.micEnabled,
              onChanged: (val) => widget.controller.setMicEnabled(val),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text('Micro', style: TextStyle(fontSize: 13)),
          ),
          const Spacer(),
          // Estado actual
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    String label = 'Listo';
    Color color = MacosColors.systemGreenColor;
    
    switch (widget.controller.status) {
      case AppStatus.recording:
        label = 'Grabando...';
        color = MacosColors.systemRedColor;
        break;
      case AppStatus.transcribing:
        label = 'Transcribiendo...';
        color = MacosColors.systemOrangeColor;
        break;
      case AppStatus.summarizing:
        label = 'IA Analizando...';
        color = MacosColors.systemBlueColor;
        break;
      case AppStatus.error:
        label = 'Error';
        color = MacosColors.systemRedColor;
        break;
      default: break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.controller.status == AppStatus.idle && widget.controller.text.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        SizedBox(
          width: 300,
          child: CupertinoSegmentedControl<int>(
            children: const {
              0: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Resumen IA')),
              1: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Transcripción')),
            },
            groupValue: _selectedTab,
            onValueChanged: (val) => setState(() => _selectedTab = val),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MacosColors.systemGrayColor.withValues(alpha: 0.2)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _selectedTab == 0 ? widget.controller.text : widget.controller.transcription,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text_viewfinder, size: 64, color: MacosColors.systemGrayColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Arrastra un audio o video aquí o inicia una grabación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          PushButton(
            controlSize: ControlSize.large,
            secondary: true,
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['wav', 'mp3', 'm4a', 'mp4', 'mov', 'm4v'],
              );
              if (result != null && widget.controller.onProcessAudio != null) {
                widget.controller.onProcessAudio!(result.files.single.path!);
              }
            },
            child: const Text('Seleccionar Archivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historial Reciente', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.controller.history.length,
            itemBuilder: (context, index) {
              final item = widget.controller.history[index];
              return GestureDetector(
                onTap: () => widget.controller.loadFromHistory(item),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MacosColors.systemGrayColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.date, style: const TextStyle(fontSize: 11, color: MacosColors.systemGrayColor)),
                      const SizedBox(height: 4),
                      Text(
                        item.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
