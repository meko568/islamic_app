import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_task_model.dart';
import '../models/target_model.dart';
import '../models/achievement_model.dart';
import 'tracker_storage_service.dart';
import 'target_storage_service.dart';
import 'achievement_service.dart';

/// Best-effort Firestore backup/restore. Local storage is the source of truth.
/// This service mirrors local data to the cloud when signed in and online.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal() {
    // Enable offline persistence
    _db.settings = const Settings(persistenceEnabled: true);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _debounceTimer;

  // Firestore Document Paths
  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);
  
  // We use few documents to minimize reads/writes
  DocumentReference _settingsDoc(String uid) => 
      _userDoc(uid).collection('app_data').doc('settings');
  
  DocumentReference _trackerDoc(String uid) => 
      _userDoc(uid).collection('app_data').doc('tracker');

  DocumentReference _targetsDoc(String uid) => 
      _userDoc(uid).collection('app_data').doc('targets');

  /// Reads all relevant local data and pushes it to Firestore.
  Future<void> pushLocalDataToCloud(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Settings & Reminders & Stats
      final stats = await AchievementService.loadStats();
      final settingsData = {
        'theme_mode': prefs.getString('theme_mode'),
        'app_language': prefs.getString('app_language'),
        'quran_translation': prefs.getString('quran_translation'),
        'app_font_size': prefs.getDouble('app_font_size'),
        'quran_font_size': prefs.getDouble('quran_font_size'),
        'is_first_launch': prefs.getBool('is_first_launch'),
        'bookmarked_page': prefs.getInt('bookmarked_page'),
        'last_page': prefs.getInt('last_page'),
        
        'reminder_settings': prefs.getString('reminder_settings'),
        'custom_tasbeeh_list': prefs.getString('custom_tasbeeh_list'),
        'custom_repeat_counts': prefs.getString('custom_repeat_counts'),
        
        'lifetime_tasbeeh_count': prefs.getInt('lifetime_tasbeeh_count'),
        'daily_tasks_history': prefs.getString('daily_tasks_history'),
        'islamic_targets_history': prefs.getString('islamic_targets_history'),
        
        'user_stats': stats.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      // 2. Tasbeeh counters (individual phrases)
      final tasbeehData = <String, dynamic>{};
      tasbeehData['selected_phrase'] = prefs.getString('tasbeeh_selected_phrase');
      final customPhrasesRaw = prefs.getString('tasbeeh_custom_phrases');
      tasbeehData['custom_phrases'] = customPhrasesRaw;
      
      // Collect all counters for preset and custom phrases
      final List<String> presetPhrases = [
        'اللهم صل على محمد', 'سبحان الله', 'الحمد لله', 'لا إله إلا الله', 
        'الله أكبر', 'لا حول ولا قوة إلا بالله', 
        'لَا إلَه إلّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ', 
        'توكلنا على الله', 'إنا لله وإنا إليه راجعون', 'أسماء الله الحسنى', 
        'سبحان الله وبحمده سبحان الله العظيم', 'أستغفر الله العظيم', 'حسبنا الله ونعم الوكيل'
      ];
      
      List<String> allPhrases = [...presetPhrases];
      if (customPhrasesRaw != null) {
        try {
          final decoded = jsonDecode(customPhrasesRaw);
          if (decoded is List) allPhrases.addAll(decoded.cast<String>());
        } catch (_) {}
      }
      
      final counters = <String, Map<String, int>>{};
      for (var phrase in allPhrases) {
        final main = prefs.getInt('tasbeeh_${phrase}_main');
        final round = prefs.getInt('tasbeeh_${phrase}_round');
        if (main != null || round != null) {
          counters[phrase] = {
            'main': main ?? 100,
            'round': round ?? 0,
          };
        }
      }
      tasbeehData['counters'] = counters;
      settingsData['tasbeeh_data'] = tasbeehData;

      await _settingsDoc(uid).set(settingsData, SetOptions(merge: true));

      // 3. Tracker Data (Keep same)
      final customTasks = await TrackerStorageService.loadCustomTasks();
      final records = await TrackerStorageService.loadAllRecords();
      
      final trackerData = {
        'customTasks': customTasks.map((e) => e.toJson()).toList(),
        'records': { for (var r in records) r.date : r.toJson() },
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      await _trackerDoc(uid).set(trackerData, SetOptions(merge: true));

      // 4. Targets (Keep same)
      final targets = await TargetStorageService.loadTargets();
      final targetsData = {
        'targets': targets.map((e) => e.toJson()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      await _targetsDoc(uid).set(targetsData);
      
      debugPrint('Cloud backup successful for UID: $uid');
    } catch (e) {
      debugPrint('Cloud backup failed: $e');
    }
  }

  /// Pulls data from Firestore and restores it to local storage.
  /// Returns true if any data was restored.
  Future<bool> pullCloudDataToLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool restoredAny = false;

      // 1. Settings & Reminders & Stats & Tasbeeh
      final settingsSnap = await _settingsDoc(uid).get();
      if (settingsSnap.exists) {
        final data = settingsSnap.data() as Map<String, dynamic>;
        
        if (data['theme_mode'] != null) await prefs.setString('theme_mode', data['theme_mode']);
        if (data['app_language'] != null) await prefs.setString('app_language', data['app_language']);
        if (data['quran_translation'] != null) await prefs.setString('quran_translation', data['quran_translation']);
        if (data['app_font_size'] != null) await prefs.setDouble('app_font_size', (data['app_font_size'] as num).toDouble());
        if (data['quran_font_size'] != null) await prefs.setDouble('quran_font_size', (data['quran_font_size'] as num).toDouble());
        if (data['is_first_launch'] != null) await prefs.setBool('is_first_launch', data['is_first_launch']);
        if (data['bookmarked_page'] != null) await prefs.setInt('bookmarked_page', (data['bookmarked_page'] as num).toInt());
        if (data['last_page'] != null) await prefs.setInt('last_page', (data['last_page'] as num).toInt());
        
        if (data['reminder_settings'] != null) await prefs.setString('reminder_settings', data['reminder_settings']);
        if (data['custom_tasbeeh_list'] != null) await prefs.setString('custom_tasbeeh_list', data['custom_tasbeeh_list']);
        if (data['custom_repeat_counts'] != null) await prefs.setString('custom_repeat_counts', data['custom_repeat_counts']);
        
        if (data['lifetime_tasbeeh_count'] != null) await prefs.setInt('lifetime_tasbeeh_count', (data['lifetime_tasbeeh_count'] as num).toInt());
        if (data['daily_tasks_history'] != null) await prefs.setString('daily_tasks_history', data['daily_tasks_history']);
        if (data['islamic_targets_history'] != null) await prefs.setString('islamic_targets_history', data['islamic_targets_history']);
        
        if (data['user_stats'] != null) {
          final stats = UserStats.fromJson(Map<String, dynamic>.from(data['user_stats'] as Map));
          await AchievementService.saveStats(stats);
        }
        
        // Restore tasbeeh data
        final tasbeehData = data['tasbeeh_data'] as Map<String, dynamic>?;
        if (tasbeehData != null) {
          if (tasbeehData['selected_phrase'] != null) {
            await prefs.setString('tasbeeh_selected_phrase', tasbeehData['selected_phrase']);
          }
          if (tasbeehData['custom_phrases'] != null) {
            await prefs.setString('tasbeeh_custom_phrases', tasbeehData['custom_phrases']);
          }
          final counters = tasbeehData['counters'] as Map<String, dynamic>?;
          if (counters != null) {
            for (var entry in counters.entries) {
              final phrase = entry.key;
              final phraseCounters = entry.value as Map<String, dynamic>;
              await prefs.setInt('tasbeeh_${phrase}_main', (phraseCounters['main'] as num?)?.toInt() ?? 100);
              await prefs.setInt('tasbeeh_${phrase}_round', (phraseCounters['round'] as num?)?.toInt() ?? 0);
            }
          }
        }
        
        restoredAny = true;
      }

      // 2. Tracker
      final trackerSnap = await _trackerDoc(uid).get();
      if (trackerSnap.exists) {
        final data = trackerSnap.data() as Map<String, dynamic>;
        
        if (data['customTasks'] != null) {
          final tasksRaw = data['customTasks'] as List;
          final tasks = tasksRaw.map((e) => CustomTaskDef.fromJson(Map<String, dynamic>.from(e))).toList();
          await TrackerStorageService.saveCustomTasks(tasks);
        }
        
        if (data['records'] != null) {
          final recordsRaw = data['records'] as Map<String, dynamic>;
          for (var entry in recordsRaw.entries) {
            final record = DailyRecord.fromJson(Map<String, dynamic>.from(entry.value));
            await TrackerStorageService.saveRecord(record);
          }
        }
        restoredAny = true;
      }

      // 3. Targets
      final targetsSnap = await _targetsDoc(uid).get();
      if (targetsSnap.exists) {
        final data = targetsSnap.data() as Map<String, dynamic>;
        if (data['targets'] != null) {
          final raw = data['targets'] as List;
          final targets = raw.map((e) => IslamicTarget.fromJson(Map<String, dynamic>.from(e))).toList();
          await TargetStorageService.saveTargets(targets);
        }
        restoredAny = true;
      }

      return restoredAny;
    } catch (e) {
      debugPrint('Cloud restore failed: $e');
      return false;
    }
  }

  /// Called after login. Decides whether to push or pull.
  Future<void> syncOnLogin(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if local data is "fresh"
      final isFresh = prefs.getBool('is_first_launch') ?? true;
      
      // Check if cloud data exists
      final settingsSnap = await _settingsDoc(uid).get();
      
      if (settingsSnap.exists) {
        // If cloud data exists, we almost always want to PULL it after a reinstall
        // or a new login, unless the local data is already significant.
        final lifetimeTasbeeh = prefs.getInt('lifetime_tasbeeh_count') ?? 0;
        
        // If it's a fresh install OR local data is empty, pull from cloud.
        if (isFresh || lifetimeTasbeeh == 0) {
          await pullCloudDataToLocal(uid);
          // After a successful restore, we should ensure onboarding is skipped
          await prefs.setBool('is_first_launch', false);
        } else {
          // If the user already has significant local data, push it to merge/backup.
          await pushLocalDataToCloud(uid);
        }
      } else {
        // No cloud data exists -> Push current local data as the first backup.
        await pushLocalDataToCloud(uid);
      }
    } catch (e) {
      debugPrint('syncOnLogin failed: $e');
    }
  }

  /// Debounced push to avoid spamming Firestore writes.
  void pushOnDataChange(String? uid) {
    if (uid == null) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 30), () {
      pushLocalDataToCloud(uid);
    });
  }
}
