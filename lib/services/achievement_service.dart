import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_model.dart';
import '../models/daily_task_model.dart';
import '../models/target_model.dart';
import 'tracker_storage_service.dart';
import 'target_storage_service.dart';
import 'cloud_sync_service.dart';

class AchievementService {
  static const String _statsKey = 'user_stats_v1';

  static Future<UserStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null) return UserStats();
    try {
      return UserStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserStats();
    }
  }

  static Future<void> saveStats(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  /// Checks and unlocks new achievements based on current state.
  /// Returns a list of newly unlocked achievements.
  static Future<List<Achievement>> checkAchievements(String? uid) async {
    final currentStats = await loadStats();
    final allRecords = await TrackerStorageService.loadAllRecords();
    final prefs = await SharedPreferences.getInstance();
    final lifetimeTasbeeh = prefs.getInt('lifetime_tasbeeh_count') ?? 0;
    final customTasksCount = (await TrackerStorageService.loadCustomTasks()).length;
    final allTargets = await TargetStorageService.loadTargets();
    final completedTargetsCount = allTargets.where((t) => t.progress >= t.goal).length;
    
    // Sort records by date ascending for streak calculation
    allRecords.sort((a, b) => a.date.compareTo(b.date));

    final newUnlockedIds = <String>[];
    final alreadyUnlocked = Set<String>.from(currentStats.unlockedAchievementIds);

    for (final achievement in Achievement.allAchievements) {
      if (alreadyUnlocked.contains(achievement.id)) continue;

      bool unlocked = false;

      if (achievement.id.startsWith('streak_')) {
        int days = int.parse(achievement.id.split('_')[1]);
        unlocked = _checkDailyStreak(allRecords, days);
      } else if (achievement.id.startsWith('fajr_')) {
        int days = int.parse(achievement.id.split('_')[1]);
        unlocked = _checkTaskStreak(allRecords, 'prayer_fajr', days);
      } else if (achievement.id.startsWith('dhuhr_')) {
        int days = int.parse(achievement.id.split('_')[1]);
        unlocked = _checkTaskStreak(allRecords, 'prayer_dhuhr', days);
      } else if (achievement.id.startsWith('asr_')) {
        int days = int.parse(achievement.id.split('_')[1]);
        unlocked = _checkTaskStreak(allRecords, 'prayer_asr', days);
      } else if (achievement.id.startsWith('maghrib_')) {
        int days = int.parse(achievement.id.split('_')[1]);
        unlocked = _checkTaskStreak(allRecords, 'prayer_maghrib', days);
      } else if (achievement.id.startsWith('isha_')) {
        int days = int.parse(achievement.id.split('_')[1]);
        unlocked = _checkTaskStreak(allRecords, 'prayer_isha', days);
      } else if (achievement.id == 'prayer_all_1') {
        unlocked = _checkTotalDaysWithTasks(allRecords, 
          ['prayer_fajr', 'prayer_dhuhr', 'prayer_asr', 'prayer_maghrib', 'prayer_isha'], 1);
      } else if (achievement.id.startsWith('prayer_consistent_')) {
        int days = int.parse(achievement.id.split('_')[2]);
        unlocked = _checkTotalDaysWithTasks(allRecords, 
          ['prayer_fajr', 'prayer_dhuhr', 'prayer_asr', 'prayer_maghrib', 'prayer_isha'], days);
      } else if (achievement.id.startsWith('tasbeeh_')) {
        int count = int.parse(achievement.id.split('_')[1]);
        unlocked = lifetimeTasbeeh >= count;
      } else if (achievement.id.startsWith('azkar_daily_')) {
         int days = int.parse(achievement.id.split('_')[2]);
         unlocked = _checkTaskStreak(allRecords, ['morning_azkar', 'evening_azkar'], days);
      } else if (achievement.id.startsWith('azkar_')) {
         final parts = achievement.id.split('_');
         int? days = int.tryParse(parts[1]);
         if (days != null) {
           unlocked = _checkTaskStreak(allRecords, ['morning_azkar', 'evening_azkar'], days);
         }
      } else if (achievement.id.startsWith('quran_')) {
         int days = int.parse(achievement.id.split('_')[1]);
         unlocked = _checkTaskStreak(allRecords, 'quran_wird', days);
      } else if (achievement.id.startsWith('consistent_')) {
        final parts = achievement.id.split('_');
        int? count = int.tryParse(parts[1]);
        if (count != null) {
          unlocked = _getTotalCompletedTasks(allRecords) >= count;
        }
      } else if (achievement.id == 'early_bird_7') {
        unlocked = _checkTaskStreak(allRecords, ['prayer_fajr', 'morning_azkar'], 7);
      } else if (achievement.id == 'custom_tasks_1') {
        unlocked = customTasksCount >= 1;
      } else if (achievement.id == 'custom_tasks_5') {
        unlocked = customTasksCount >= 5;
      } else if (achievement.id == 'targets_1') {
        unlocked = completedTargetsCount >= 1;
      } else if (achievement.id == 'targets_5') {
        unlocked = completedTargetsCount >= 5;
      } else if (achievement.id == 'targets_10') {
        unlocked = completedTargetsCount >= 10;
      } else if (achievement.id == 'targets_25') {
        unlocked = completedTargetsCount >= 25;
      } else if (achievement.id == 'targets_50') {
        unlocked = completedTargetsCount >= 50;
      } else if (achievement.id == 'friday_master') {
        final now = DateTime.now();
        if (now.weekday == DateTime.friday) {
          final todayStr = now.toIso8601String().split('T')[0];
          final todayRecord = allRecords.any((r) => r.date == todayStr) 
              ? allRecords.firstWhere((r) => r.date == todayStr)
              : null;
          if (todayRecord != null) {
            unlocked = DailyTaskDef.presets.every((task) => todayRecord.tasks[task.id]?.done ?? false);
          }
        }
      }
      // Note: Friday master and targets will need specific logic or to be triggered from elsewhere

      if (unlocked) {
        newUnlockedIds.add(achievement.id);
      }
    }

    if (newUnlockedIds.isNotEmpty) {
      int addedXp = newUnlockedIds.fold(0, (sum, id) {
        return sum + Achievement.allAchievements.firstWhere((a) => a.id == id).xpReward;
      });

      final updatedStats = UserStats(
        totalXp: currentStats.totalXp + addedXp,
        unlockedAchievementIds: [...currentStats.unlockedAchievementIds, ...newUnlockedIds],
        lastSync: DateTime.now(),
      );

      await saveStats(updatedStats);
      CloudSyncService().pushOnDataChange(uid);
      
      return Achievement.allAchievements.where((a) => newUnlockedIds.contains(a.id)).toList();
    }

    return [];
  }

  static bool _checkDailyStreak(List<DailyRecord> records, int requiredDays) {
    if (records.length < requiredDays) return false;
    
    int streak = 0;
    for (int i = records.length - 1; i >= 0; i--) {
      bool allPresetsDone = DailyTaskDef.presets.every((task) => 
        records[i].tasks[task.id]?.done ?? false
      );
      
      if (allPresetsDone) {
        streak++;
        if (streak >= requiredDays) return true;
      } else {
        // If not today (last record), break streak. 
        // Allow missing today if it's not finished yet? 
        // Simple version: consecutive days in record list.
        if (i < records.length - 1) break; 
      }
    }
    return false;
  }

  static bool _checkTaskStreak(List<DailyRecord> records, dynamic taskIds, int requiredDays) {
    List<String> ids = taskIds is String ? [taskIds] : List<String>.from(taskIds);
    if (records.length < requiredDays) return false;

    int streak = 0;
    for (int i = records.length - 1; i >= 0; i--) {
      bool allDone = ids.every((id) => records[i].tasks[id]?.done ?? false);
      if (allDone) {
        streak++;
        if (streak >= requiredDays) return true;
      } else {
        if (i < records.length - 1) break;
      }
    }
    return false;
  }

  static bool _checkTotalDaysWithTasks(List<DailyRecord> records, List<String> taskIds, int requiredDays) {
    int totalDays = 0;
    for (var record in records) {
      if (taskIds.every((id) => record.tasks[id]?.done ?? false)) {
        totalDays++;
      }
    }
    return totalDays >= requiredDays;
  }

  static int _getTotalCompletedTasks(List<DailyRecord> records) {
    int total = 0;
    for (var record in records) {
      total += record.tasks.values.where((t) => t.done).length;
    }
    return total;
  }
}
