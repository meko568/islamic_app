import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/target_model.dart';
import 'tracker_storage_service.dart';

class TargetStorageService {
  static const String _targetsKey = 'islamic_targets';
  static const String _historyKey = 'islamic_targets_history';

  static Future<List<IslamicTarget>> loadTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_targetsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => IslamicTarget.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTargets(List<IslamicTarget> targets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _targetsKey,
      jsonEncode(targets.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<GoalHistoryRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GoalHistoryRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<GoalHistoryRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> addToHistory(GoalHistoryRecord record) async {
    final history = await loadHistory();
    // Avoid duplicates for the same target and periodKey
    if (history.any((r) => r.targetId == record.targetId && r.date == record.date)) {
      return;
    }
    history.insert(0, record);
    if (history.length > 100) history.removeLast();
    await saveHistory(history);
  }

  /// The key identifying the current cycle for a given period, used to
  /// detect when a target's progress should reset (new day/week/month).
  static Future<String> currentPeriodKey(TargetPeriod period) async {
    final now = DateTime.now();
    switch (period) {
      case TargetPeriod.daily:
        return await TrackerStorageService.getCurrentTrackerDate();
      case TargetPeriod.weekly:
        // ISO week number, Monday-based.
        final firstDayOfYear = DateTime(now.year, 1, 1);
        final daysSinceStart = now.difference(firstDayOfYear).inDays;
        final weekNumber = ((daysSinceStart + firstDayOfYear.weekday - 1) / 7)
            .ceil();
        return '${now.year}-W$weekNumber';
      case TargetPeriod.monthly:
        return DateFormat('yyyy-MM').format(now);
    }
  }

  /// Increments all targets of a given link type. Used by the overlay
  /// which cannot access the TargetProvider directly.
  static Future<void> incrementAllByLinkType(String linkType, {int by = 1}) async {
    final targets = await loadTargets();
    bool changed = false;
    for (final t in targets) {
      if (t.linkType == linkType && t.progress < t.goal) {
        t.progress = (t.progress + by).clamp(0, t.goal);
        changed = true;
      }
    }
    if (changed) {
      await saveTargets(targets);
    }
  }
}
