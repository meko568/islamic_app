import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_strings.dart';
import '../models/reminder_settings.dart';
import '../main.dart';

const String _tasbeehReminderTaskName = 'tasbeehReminderTask';
const String _tasbeehOneOffTaskName = 'tasbeehOneOffTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Handle both periodic and one-off tasks
    if (task == _tasbeehReminderTaskName || task == _tasbeehOneOffTaskName) {
      await ReminderSchedulerService._handleReminderTask();
      
      // If it's a one-off task, we need to schedule the next one manually
      // to support intervals less than 15 minutes
      if (task == _tasbeehOneOffTaskName) {
        await ReminderSchedulerService.scheduleNextOneOff();
      }
    }
    return Future.value(true);
  });
}

class ReminderSchedulerService {
  static const String _lastShownIndexKey = 'reminder_last_shown_index';
  static const String _lastCompletedTimestampKey =
      'reminder_last_completed_timestamp';

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await rescheduleAll();
  }

  static Future<void> rescheduleAll() async {
    // Cancel all existing tasks first
    await Workmanager().cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('reminder_settings');
    if (settingsJson == null) return;
    final settings = ReminderSettings.fromJsonString(settingsJson);

    if (!settings.enabled || settings.selectedTasbeehIds.isEmpty) return;

    final interval = settings.intervalMinutes;

    if (interval < 15) {
      // Use OneOffTask chain for intervals < 15 minutes (Android limitation)
      await scheduleNextOneOff();
    } else {
      // Use PeriodicTask for 15+ minutes
      await Workmanager().registerPeriodicTask(
        _tasbeehReminderTaskName,
        _tasbeehReminderTaskName,
        frequency: Duration(minutes: interval),
        initialDelay: Duration(minutes: interval),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    }
  }

  static Future<void> scheduleNextOneOff() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('reminder_settings');
    if (settingsJson == null) return;
    final settings = ReminderSettings.fromJsonString(settingsJson);

    if (!settings.enabled || settings.selectedTasbeehIds.isEmpty) return;

    // Schedule a one-off task that will trigger after the interval
    await Workmanager().registerOneOffTask(
      "tasbeeh_oneoff_${DateTime.now().millisecondsSinceEpoch}",
      _tasbeehOneOffTaskName,
      initialDelay: Duration(minutes: settings.intervalMinutes),
      existingWorkPolicy: ExistingWorkPolicy.append, // Use append to not cancel current
    );
  }

  static Future<void> showImmediate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('reminder_settings');
      if (settingsJson == null) return;
      final settings = ReminderSettings.fromJsonString(settingsJson);
      if (settings.selectedTasbeehIds.isEmpty) return;

      final lastIndex = prefs.getInt(_lastShownIndexKey) ?? -1;
      final selectedIds = settings.selectedTasbeehIds;
      final nextIndex = (lastIndex + 1) % selectedIds.length;
      final tasbeehId = selectedIds[nextIndex];
      await prefs.setInt(_lastShownIndexKey, nextIndex);

      final tasbeehText = await _getTasbeehText(tasbeehId);
      final targetCount = await _getTasbeehTargetCount(tasbeehId);
      final lang = prefs.getString('app_language') ?? 'ar';

      final overlayData = {
        'tasbeehId': tasbeehId,
        'tasbeehText': tasbeehText,
        'targetCount': targetCount,
        'allowCloseAnytime': settings.allowCloseAnytime,
        'lang': lang,
      };

      await prefs.setString('current_overlay_data', jsonEncode(overlayData));

      bool overlayStarted = false;
      try {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await FlutterOverlayWindow.showOverlay(
          height: 600,
          width: 500,
          alignment: OverlayAlignment.center,
          overlayTitle: AppStrings.get('tasbeeh_reminder_overlay_title', lang),
          overlayContent: AppStrings.get('tasbeeh_reminder_overlay_content', lang),
          flag: OverlayFlag.defaultFlag,
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        overlayStarted = await FlutterOverlayWindow.isActive();
      } catch (_) {}

      if (!overlayStarted) {
        await _showHighPriorityNotification(tasbeehText, lang, tasbeehId);
      } else {
        for (int i = 0; i < 3; i++) {
          await Future.delayed(Duration(milliseconds: 1000 + (i * 500)));
          await FlutterOverlayWindow.shareData(overlayData);
        }
      }
    } catch (e) {
      debugPrint('DEBUG ERROR: $e');
      rethrow;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleReminderTask() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('reminder_settings');
      if (settingsJson == null) return;
      final settings = ReminderSettings.fromJsonString(settingsJson);
      if (!settings.enabled || settings.selectedTasbeehIds.isEmpty) return;

      final lastIndex = prefs.getInt(_lastShownIndexKey) ?? -1;
      final selectedIds = settings.selectedTasbeehIds;
      final nextIndex = (lastIndex + 1) % selectedIds.length;
      final tasbeehId = selectedIds[nextIndex];
      await prefs.setInt(_lastShownIndexKey, nextIndex);

      final tasbeehText = await _getTasbeehText(tasbeehId);
      final targetCount = await _getTasbeehTargetCount(tasbeehId);
      final lang = prefs.getString('app_language') ?? 'ar';

      final overlayData = {
        'tasbeehId': tasbeehId,
        'tasbeehText': tasbeehText,
        'targetCount': targetCount,
        'allowCloseAnytime': settings.allowCloseAnytime,
        'lang': lang,
      };

      await prefs.setString('current_overlay_data', jsonEncode(overlayData));

      bool overlayStarted = false;
      try {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await FlutterOverlayWindow.showOverlay(
          height: 600,
          width: 500,
          alignment: OverlayAlignment.center,
          overlayTitle: AppStrings.get('tasbeeh_reminder_overlay_title', lang),
          overlayContent: AppStrings.get('tasbeeh_reminder_overlay_content', lang),
          flag: OverlayFlag.defaultFlag,
        );
        
        await Future.delayed(const Duration(milliseconds: 1000));
        overlayStarted = await FlutterOverlayWindow.isActive();
      } catch (_) {}

      if (!overlayStarted) {
        await _showHighPriorityNotification(tasbeehText, lang, tasbeehId);
      } else {
        for (int i = 0; i < 3; i++) {
          await Future.delayed(Duration(milliseconds: 1000 + (i * 500)));
          await FlutterOverlayWindow.shareData(overlayData);
        }
      }
    } catch (e) {
      debugPrint('Error handling reminder task: $e');
    }
  }

  static Future<void> _showHighPriorityNotification(String text, String lang, String tasbeehId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tasbeeh_reminder_channel',
      'التذكير بالتسبيح',
      channelDescription: 'إشعارات للتذكير بذكر الله',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      color: Color(0xFF0F5132),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID to allow multiple notifications
      AppStrings.get('tasbeeh_reminder_overlay_title', lang),
      text,
      platformChannelSpecifics,
      payload: tasbeehId,
    );
  }

  static Future<String> _getTasbeehText(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customListJson = prefs.getString('custom_tasbeeh_list');
    if (customListJson != null) {
      try {
        final decoded = jsonDecode(customListJson) as List<dynamic>;
        final customList = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        final custom = customList.firstWhere((t) => t['id'] == id, orElse: () => {});
        if (custom.isNotEmpty) return custom['text'] as String;
      } catch (e) {}
    }
    return id;
  }

  static Future<int> _getTasbeehTargetCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customCountsJson = prefs.getString('custom_repeat_counts');
    if (customCountsJson != null) {
      final customCounts = Map<String, dynamic>.from(jsonDecode(customCountsJson));
      if (customCounts.containsKey(id)) return customCounts[id] as int;
    }
    final customListJson = prefs.getString('custom_tasbeeh_list');
    if (customListJson != null) {
      try {
        final decoded = jsonDecode(customListJson) as List<dynamic>;
        final customList = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        final custom = customList.firstWhere((t) => t['id'] == id, orElse: () => {});
        if (custom.isNotEmpty) return custom['targetCount'] as int;
      } catch (e) {}
    }
    return 33;
  }

  static Future<void> markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCompletedTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
