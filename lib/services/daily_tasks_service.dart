import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks, per calendar day, whether the user completed at least 80% of
/// Morning Azkar and/or Evening Azkar. Persisted locally (offline-first)
/// so it survives app restarts and can back a future streak/history UI.
class DailyTasksService {
  static const String _storageKey = 'daily_tasks_history';
  static const double _completionThreshold = 0.8;

  static const String morningCategory = 'Morning';
  static const String eveningCategory = 'Evening';

  /// Call this after any counter update in an Azkar category. If [percent]
  /// (completedItems / totalItems) has reached the 80% threshold, today's
  /// date is marked done for that category. Safe to call repeatedly —
  /// already-marked days are left untouched.
  static Future<void> markCategoryProgress(
    String category,
    double percent,
  ) async {
    if (category != morningCategory && category != eveningCategory) return;
    if (percent < _completionThreshold) return;

    final today = _todayKey();
    final history = await getHistory();
    final todayEntry = Map<String, bool>.from(
      history[today] ?? {morningCategory: false, eveningCategory: false},
    );

    if (todayEntry[category] == true) return; // already marked, nothing to do

    todayEntry[category] = true;
    history[today] = todayEntry;
    await _saveHistory(history);
  }

  /// Morning/Evening completion status for today.
  static Future<Map<String, bool>> getTodayStatus() async {
    final history = await getHistory();
    final today = _todayKey();
    return history[today] ?? {morningCategory: false, eveningCategory: false};
  }

  /// Full history, keyed by date string (yyyy-MM-dd), for future
  /// streak/stats screens.
  static Future<Map<String, Map<String, bool>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return {};

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (date, value) => MapEntry(
          date,
          Map<String, bool>.from(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveHistory(
    Map<String, Map<String, bool>> history,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(history));
    } catch (_) {
      // Silent fail: daily-task marking should never crash the Azkar screen.
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
