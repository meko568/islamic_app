import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/target_model.dart';

class TargetStorageService {
  static const String _targetsKey = 'islamic_targets';

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

  /// The key identifying the current cycle for a given period, used to
  /// detect when a target's progress should reset (new day/week/month).
  static String currentPeriodKey(TargetPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case TargetPeriod.daily:
        return DateFormat('yyyy-MM-dd').format(now);
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
}
