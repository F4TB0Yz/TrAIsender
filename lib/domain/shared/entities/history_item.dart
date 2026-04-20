class HistoryItem {
  final String date;
  final String transcription;
  final String summary;

  HistoryItem({
    required this.date,
    required this.transcription,
    required this.summary,
  });

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
