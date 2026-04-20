import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:traisender/domain/shared/entities/app_status.dart';
import 'package:traisender/presentation/shared/controllers/workflow_status_notifier.dart';
import 'package:traisender/domain/shared/entities/history_item.dart';
import 'package:traisender/features/meeting_workspace/data/repositories/meeting_workspace_history_storage_repository.dart';
import 'package:traisender/features/meeting_workspace/data/services/meeting_workspace_file_intake_handler.dart';
import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';
import 'package:traisender/features/meeting_workspace/domain/repositories/meeting_workspace_history_repository.dart';
import 'package:traisender/features/meeting_workspace/presentation/controllers/meeting_workspace_state.dart';

class MeetingWorkspaceController extends ChangeNotifier {
  MeetingWorkspaceController({
    required MeetingWorkspaceHistoryRepository historyRepository,
    StatusController? statusController,
  }) : _historyRepository = historyRepository,
       _statusController = statusController,
       _state = MeetingWorkspaceState.initial(history: historyRepository.loadHistory()) {
    final source = _statusController;
    if (source != null) {
      source.addListener(_syncFromStatusController);
      _syncFromStatusController();
    }
    if (_historyRepository is MeetingWorkspaceHistoryStorageRepository) {
      unawaited(_reloadHistoryFromStorage());
    }
  }

  static const String _dummyTranscript =
      'Hola a todos, gracias por unirse a la llamada. Hoy vamos a revisar el estado del proyecto y ver los bloqueos tecnicos que tenemos con la captura de audio en macOS.';

  final Random _random = Random();
  final MeetingWorkspaceHistoryRepository _historyRepository;
  final StatusController? _statusController;

  MeetingWorkspaceState _state;
  Timer? _recordTimer;
  Timer? _uploadTimer;

  MeetingWorkspaceState get state => _state;

  @override
  void dispose() {
    _statusController?.removeListener(_syncFromStatusController);
    _recordTimer?.cancel();
    _uploadTimer?.cancel();
    super.dispose();
  }

  void setTab(MainTab tab) {
    _setState(_state.copyWith(activeTab: tab));
  }

  void openMeeting(MeetingHistoryItem item) {
    _setState(
      _state.copyWith(
        selectedMeeting: item,
        historyDetailTab: HistoryDetailTab.transcript,
        aiResult: item.summary,
        aiError: '',
      ),
    );
  }

  void closeMeeting() {
    _setState(
      _state.copyWith(clearSelectedMeeting: true, aiResult: '', aiError: ''),
    );
  }

  void setAudioSource(AudioSource source) {
    if (_state.isRecording) return;
    _setState(_state.copyWith(audioSource: source));
    final statusController = _statusController;
    if (statusController == null) return;
    statusController.setMicEnabled(source == AudioSource.mic);
  }

  void setHistoryDetailTab(HistoryDetailTab tab) {
    _setState(_state.copyWith(historyDetailTab: tab));
    final selected = _state.selectedMeeting;
    if (tab == HistoryDetailTab.summary && selected != null) {
      if (selected.summary.isNotEmpty) {
        _setState(_state.copyWith(aiResult: selected.summary, aiError: ''));
        return;
      }
      if (_statusController != null) {
        _setState(
          _state.copyWith(
            aiResult: '',
            aiError: 'Resumen no disponible para esta sesion.',
          ),
        );
        return;
      }
    }
    if (tab == HistoryDetailTab.summary &&
        _state.aiResult.isEmpty &&
        !_state.isAiLoading) {
      generateSummaryMock();
    }
  }

  void toggleRecording() {
    final statusController = _statusController;
    if (statusController != null) {
      unawaited(statusController.onToggleRecording?.call());
      return;
    }

    if (_state.isRecording) {
      _recordTimer?.cancel();
      _setState(_state.copyWith(isRecording: false));
      return;
    }

    _setState(
      _state.copyWith(isRecording: true, recordTime: 0, liveTranscript: ''),
    );

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = _state;
      final nextTime = current.recordTime + 1;
      var nextTranscript = current.liveTranscript;

      if (nextTime.isEven && nextTranscript.length < _dummyTranscript.length) {
        final nextLength = (nextTranscript.length + 15).clamp(
          0,
          _dummyTranscript.length,
        );
        nextTranscript = _dummyTranscript.substring(0, nextLength);
      }

      _setState(
        current.copyWith(recordTime: nextTime, liveTranscript: nextTranscript),
      );
    });
  }

  void startFakeUpload() {
    if (_statusController != null) {
      unawaited(pickAndProcessFile());
      return;
    }

    if (_state.isUploading) return;

    _setState(
      _state.copyWith(
        uploadFileName: 'reunion_ventas_q3.mp4',
        uploadProgress: 0,
        isUploading: true,
      ),
    );

    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      final current = _state;
      if (current.uploadProgress >= 100) {
        timer.cancel();
        _setState(current.copyWith(isUploading: false, uploadProgress: 0));
        return;
      }

      final nextProgress = current.uploadProgress + _random.nextInt(8) + 2;
      _setState(current.copyWith(uploadProgress: nextProgress.clamp(0, 100)));
    });
  }

  Future<void> pickAndProcessFile() async {
    await MeetingWorkspaceFileIntakeHandler.processFromPicker(
      onAcceptedPath: processAudioPath,
    );
  }

  Future<void> processDroppedFile(String path) async {
    await processAudioPath(path);
  }

  Future<void> processAudioPath(String path) async {
    final callback = _statusController?.onProcessAudio;
    if (callback == null) return;

    _setState(
      _state.copyWith(
        activeTab: MainTab.upload,
        uploadFileName: p.basename(path),
        uploadProgress: 0,
        isUploading: true,
        aiError: '',
      ),
    );
    await callback(path);
  }

  Future<void> generateSummaryMock() async {
    if (_statusController != null) {
      final selected = _state.selectedMeeting;
      if (selected == null) return;
      if (selected.summary.isNotEmpty) {
        _setState(_state.copyWith(aiResult: selected.summary, aiError: ''));
      } else {
        _setState(
          _state.copyWith(
            aiResult: '',
            aiError: 'Resumen no disponible para esta sesion.',
          ),
        );
      }
      return;
    }

    final selected = _state.selectedMeeting;
    if (selected == null || _state.isAiLoading) return;

    _setState(_state.copyWith(isAiLoading: true, aiError: ''));

    await Future<void>.delayed(const Duration(seconds: 2));

    final stillSelected = _state.selectedMeeting;
    if (stillSelected == null || stillSelected.id != selected.id) {
      _setState(_state.copyWith(isAiLoading: false));
      return;
    }

    final shouldError = selected.id == 2;
    if (shouldError) {
      _setState(
        _state.copyWith(
          isAiLoading: false,
          aiError:
              'Error al conectar con la IA despues de varios intentos. Intenta nuevamente.',
        ),
      );
      return;
    }

    const result = '''## Resumen ejecutivo
**Tema principal:** Revision de estado del equipo y decisiones de contratacion.

## Hallazgos clave
- Se identifico una mejor adecuacion tecnica para un perfil senior.
- Se detectaron oportunidades para roles alternativos en candidatos secundarios.

## Acciones pendientes
- **RRHH:** Preparar oferta para perfil senior.
- **Equipo tecnico:** Definir criterios para rol junior de respaldo.
- **Hiring manager:** Confirmar decision final antes del cierre de semana.''';

    _setState(_state.copyWith(isAiLoading: false, aiResult: result, aiError: ''));
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _setState(MeetingWorkspaceState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> _reloadHistoryFromStorage() async {
    final repository = _historyRepository;
    if (repository is! MeetingWorkspaceHistoryStorageRepository) return;
    final history = await repository.loadHistoryAsync();
    _setState(_state.copyWith(history: history));
  }

  void _syncFromStatusController() {
    final source = _statusController;
    if (source == null) return;

    final status = source.status;
    final mappedHistory = _mapHistory(source.history);
    final selected = _state.selectedMeeting;
    final selectedNext = selected == null
        ? null
        : mappedHistory.firstWhere(
            (item) => item.id == selected.id,
            orElse: () => selected,
          );
    final summary = selectedNext?.summary ?? source.text;

    _setState(
      _state.copyWith(
        isRecording: source.isRecording,
        isUploading:
            status == AppStatus.transcribing || status == AppStatus.summarizing,
        uploadProgress: (source.progress * 100).round().clamp(0, 100),
        aiResult: status == AppStatus.error ? _state.aiResult : summary,
        isAiLoading: status == AppStatus.summarizing,
        aiError: status == AppStatus.error ? source.text : '',
        liveTranscript: source.transcription,
        history: mappedHistory,
        selectedMeeting: selectedNext,
      ),
    );
  }

  List<MeetingHistoryItem> _mapHistory(List<HistoryItem> history) {
    return history.asMap().entries.map((entry) {
      final item = entry.value;
      final source = item.summary.trim().isNotEmpty
          ? item.summary.trim()
          : item.transcription.trim();
      final title = source.isEmpty
          ? 'Sesion sin titulo'
          : (source.split('\n').first.length <= 36
                ? source.split('\n').first
                : '${source.split('\n').first.substring(0, 33)}...');
      return MeetingHistoryItem(
        id: entry.key + 1,
        title: title,
        date: item.date,
        length: _estimateLength(item.transcription),
        transcript: item.transcription,
        summary: item.summary,
      );
    }).toList();
  }

  String _estimateLength(String transcription) {
    final words = transcription
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final minutes = (words / 150).clamp(1, 240).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }
}
