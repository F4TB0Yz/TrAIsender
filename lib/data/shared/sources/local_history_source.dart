import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:traisender/domain/shared/entities/history_item.dart';

class HistoryStorage {
  static const String _historyKey = 'history';
  static const int _maxItems = 10;

  Future<List<HistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson == null || historyJson.isEmpty) return [];

    final decoded = jsonDecode(historyJson) as List<dynamic>;
    return decoded
        .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<HistoryItem>> prependAndSave(HistoryItem item) async {
    final history = await load();
    history.insert(0, item);
    if (history.length > _maxItems) history.removeLast();
    await _save(history);
    return history;
  }

  Future<void> _save(List<HistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((entry) => entry.toJson()).toList()),
    );
  }
}
