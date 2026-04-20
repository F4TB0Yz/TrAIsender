enum MainTab { record, upload, history }

enum AudioSource { mic, system }

enum HistoryDetailTab { transcript, summary }

class MeetingHistoryItem {
  const MeetingHistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.length,
    required this.transcript,
    this.summary = '',
  });

  final int id;
  final String title;
  final String date;
  final String length;
  final String transcript;
  final String summary;
}
