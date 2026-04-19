import 'dart:convert';
import 'package:flutter/material.dart' show SelectableText, LinearProgressIndicator, AlwaysStoppedAnimation;
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
  double _progress = 0.0;
  String _progressLabel = '';
  HistoryItem? _viewingItem;

  AppStatus get status => _status;
  String get text => _text; // This will hold the summary
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

  StatusController() {
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

  void updateStatus(AppStatus newStatus, {String text = '', String transcription = ''}) {
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
                    padding: const EdgeInsets.only(left: 24.0, right: 24, top: 50, bottom: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.controller.history.isNotEmpty) ...[
                          SizedBox(
                            width: 220,
                            child: _buildHistorySection(),
                          ),
                          const SizedBox(width: 24),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopControls(),
                              if (widget.controller.viewingItem != null && (widget.controller.status == AppStatus.transcribing || widget.controller.status == AppStatus.summarizing)) ...[
                                const SizedBox(height: 12),
                                _buildActiveProcessBanner(),
                              ],
                              const SizedBox(height: 24),
                              Expanded(
                                child: Center(child: _buildMainContent()),
                              ),
                            ],
                          ),
                        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosColors.systemGrayColor.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.start,
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
                Text(isRecording ? 'Detener' : 'Grabar'),
              ],
            ),
          ),
          // Botón Subir Archivo
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
                Text('Archivo'),
              ],
            ),
          ),
          // Toggle Mic
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          // Estado actual
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildActiveProcessBanner() {
    final bool isTranscribing = widget.controller.status == AppStatus.transcribing;
    final double progress = widget.controller.progress;
    final String label = widget.controller.progressLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MacosColors.systemBlueColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MacosColors.systemBlueColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isTranscribing ? CupertinoIcons.waveform : CupertinoIcons.sparkles,
            size: 16,
            color: MacosColors.systemBlueColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTranscribing ? 'Transcribiendo en segundo plano...' : 'Generando resumen...',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: MacosColors.systemGrayColor),
                ),
              ],
            ),
          ),
          if (isTranscribing && progress > 0) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: MacosColors.systemGrayColor.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(MacosColors.systemBlueColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11),
            ),
          ],
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

  Widget _buildLoadingState() {
    final bool isTranscribing = widget.controller.status == AppStatus.transcribing;
    final double progress = widget.controller.progress;
    final String label = widget.controller.progressLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTranscribing ? CupertinoIcons.waveform : CupertinoIcons.sparkles,
              size: 48,
              color: MacosColors.systemBlueColor.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 20),
            Text(
              isTranscribing ? 'Transcribiendo audio...' : 'IA analizando...',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: MacosColors.systemGrayColor),
            ),
            const SizedBox(height: 24),

            // Barra de progreso — solo para transcripción (progreso real)
            // Para Gemini muestra el texto parcial streamado directamente
            if (isTranscribing) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null, // null = indeterminado hasta primer segmento
                  minHeight: 6,
                  backgroundColor: MacosColors.systemGrayColor.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(MacosColors.systemBlueColor),
                ),
              ),
              const SizedBox(height: 8),
              if (progress > 0)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: MacosColors.systemGrayColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],

            // Para Gemini: mostrar texto parcial conforme llega (streaming)
            if (!isTranscribing && widget.controller.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MacosColors.systemGrayColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MacosColors.systemGrayColor.withValues(alpha: 0.15)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.controller.text,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final viewingItem = widget.controller.viewingItem;
    
    if (viewingItem != null) {
      return Column(
        children: [
          Row(
            children: [
              MacosIconButton(
                icon: const Icon(CupertinoIcons.back, size: 20),
                onPressed: () => widget.controller.closeHistoryView(),
              ),
              const SizedBox(width: 8),
              Text(
                'Sesión del ${viewingItem.date}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  _selectedTab == 0 ? viewingItem.summary : viewingItem.transcription,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.controller.status == AppStatus.idle && widget.controller.text.isEmpty && widget.controller.transcription.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.controller.status == AppStatus.transcribing || widget.controller.status == AppStatus.summarizing) {
      return _buildLoadingState();
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
        const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.controller.history.length,
            itemBuilder: (context, index) {
              final item = widget.controller.history[index];
              final isSelected = widget.controller.viewingItem == item;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = 0);
                  widget.controller.viewHistoryItem(item);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? MacosColors.systemBlueColor.withValues(alpha: 0.1) 
                        : MacosTheme.of(context).canvasColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected 
                            ? MacosColors.systemBlueColor.withValues(alpha: 0.3)
                            : MacosColors.systemGrayColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.date, style: TextStyle(fontSize: 11, color: isSelected ? MacosColors.systemBlueColor : MacosColors.systemGrayColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      const SizedBox(height: 6),
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
