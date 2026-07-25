import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as fow;
import 'package:timezone/data/latest_all.dart' as tz;

import '../l10n/app_strings.dart';
import '../models/reminder_settings.dart';
import '../main.dart';
import 'prayer_service.dart';

const String _prayerCheckTaskName = 'prayerApproachCheckTask';
const String _tasbeehOneOffTaskName = 'tasbeehOneOffTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize notification engine in background
    final fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    final fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // This is handled in main.dart for foreground, 
        // but background clicks trigger app launch.
      }
    );
    tz.initializeTimeZones();

    if (task.startsWith(_tasbeehOneOffTaskName)) {
      // Schedule next reminder immediately to keep the loop going
      await ReminderSchedulerService.scheduleNextOneOff();
      await ReminderSchedulerService._handleReminderTask();
    } else if (task.startsWith(_prayerCheckTaskName)) {
      // Schedule next check in 15 mins to keep the loop going
      await ReminderSchedulerService.schedulePrayerApproachChecks();

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('app_language') ?? 'ar';
      await PrayerService.checkAndNotifyIfPrayerApproaching(lang);
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
    tz.initializeTimeZones();
    
    // Create the high-priority channel immediately on start
    const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
      'islamic_app_high_priority_v3', 
      'إشعارات درب الإيمان',
      description: 'إشعارات عالية الأهمية للأذكار والصلوات',
      importance: fln.Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await Workmanager().initialize(callbackDispatcher);
    await rescheduleAll();
  }

  static Future<void> rescheduleAll() async {
    await Workmanager().cancelAll();
    await scheduleNextOneOff();
    await schedulePrayerApproachChecks();
  }

  static Future<void> scheduleNextOneOff() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('reminder_settings');
    if (settingsJson == null) return;
    final settings = ReminderSettings.fromJsonString(settingsJson);

    if (!settings.enabled || settings.selectedTasbeehIds.isEmpty) return;

    await Workmanager().registerOneOffTask(
      "${_tasbeehOneOffTaskName}_${DateTime.now().millisecondsSinceEpoch}",
      _tasbeehOneOffTaskName,
      initialDelay: Duration(minutes: settings.intervalMinutes),
      existingWorkPolicy: ExistingWorkPolicy.append,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  static Future<void> schedulePrayerApproachChecks() async {
    try {
      // Using OneOffTask instead of PeriodicTask for better reliability on Honor/Huawei
      await Workmanager().registerOneOffTask(
        "${_prayerCheckTaskName}_${DateTime.now().millisecondsSinceEpoch}",
        _prayerCheckTaskName,
        initialDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.append,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    } catch (e) {
      debugPrint('Could not schedule prayer approach checks: $e');
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

      // Cycle through selected Azkar
      final lastIndex = prefs.getInt(_lastShownIndexKey) ?? -1;
      final selectedIds = settings.selectedTasbeehIds;
      final nextIndex = (lastIndex + 1) % selectedIds.length;
      final tasbeehId = selectedIds[nextIndex];
      await prefs.setInt(_lastShownIndexKey, nextIndex);

      final tasbeehText = await _getTasbeehText(tasbeehId);
      final targetCount = await _getTasbeehTargetCount(tasbeehId);
      final lang = prefs.getString('app_language') ?? 'ar';

      // 1. Show the "WhatsApp style" high-priority notification
      await _showHighPriorityNotification(tasbeehText, lang, tasbeehId);

      // 2. Show overlay automatically if enabled (Popup)
      if (settings.autoShowOverlay && !Platform.isIOS) {
        final hasPermission = await fow.FlutterOverlayWindow.isPermissionGranted();
        if (hasPermission) {
          final overlayData = {
            'tasbeehText': tasbeehText,
            'targetCount': targetCount,
            'allowCloseAnytime': settings.allowCloseAnytime,
            'lang': lang,
          };
          await prefs.setString('current_overlay_data', jsonEncode(overlayData));
          await fow.FlutterOverlayWindow.showOverlay(
            enableDrag: true,
            overlayTitle: "Tasbeeh Reminder",
            overlayContent: tasbeehText,
            flag: fow.OverlayFlag.defaultFlag,
            visibility: fow.NotificationVisibility.visibilityPublic,
            positionGravity: fow.PositionGravity.none,
            height: fow.WindowSize.matchParent,
            width: fow.WindowSize.matchParent,
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling reminder task: $e');
    }
  }

  static Future<void> _showHighPriorityNotification(
      String text, String lang, String tasbeehId) async {
    final fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'islamic_app_high_priority_v3',
      'إشعارات درب الإيمان',
      channelDescription: 'إشعارات عالية الأهمية للأذكار والصلوات',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      showWhen: true,
      fullScreenIntent: true,
      audioAttributesUsage: fln.AudioAttributesUsage.alarm,
      category: fln.AndroidNotificationCategory.alarm,
      color: const Color(0xFF0F5132),
      styleInformation: const fln.BigTextStyleInformation(''),
    );
    final fln.NotificationDetails platformChannelSpecifics =
        fln.NotificationDetails(android: androidPlatformChannelSpecifics);

    final int notificationId = DateTime.now().millisecond + (DateTime.now().second * 1000);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
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
        final List decoded = jsonDecode(customListJson);
        final custom = decoded.firstWhere((t) => t['id'] == id, orElse: () => null);
        if (custom != null) return custom['text'] as String;
      } catch (_) {}
    }
    return id;
  }

  static Future<int> _getTasbeehTargetCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customCountsJson = prefs.getString('custom_repeat_counts');
    if (customCountsJson != null) {
      final Map<String, dynamic> customCounts = jsonDecode(customCountsJson);
      if (customCounts.containsKey(id)) return customCounts[id] as int;
    }
    return 33;
  }

  static Future<void> markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastCompletedTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    await fln.FlutterLocalNotificationsPlugin().cancelAll();
  }
}
