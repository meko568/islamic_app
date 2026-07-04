import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../l10n/app_strings.dart';
import '../models/reminder_settings.dart';

const String _tasbeehReminderTaskName = 'tasbeehReminderTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task == _tasbeehReminderTaskName) {
      await ReminderSchedulerService._handleReminderTask();
    }
    return Future.value(true);
  });
}

class ReminderSchedulerService {
  static const String _lastShownIndexKey = 'reminder_last_shown_index';
  static const String _lastCompletedTimestampKey =
      'reminder_last_completed_timestamp';

  // Initialize the Workmanager scheduler and restore any existing task.
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Workmanager().initialize(callbackDispatcher);
    await rescheduleAll();
  }

  // Schedule or reschedule the reminder task.
  static Future<void> rescheduleAll() async {
    await Workmanager().cancelByUniqueName(_tasbeehReminderTaskName);

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('reminder_settings');

    if (settingsJson == null) return;

    final settings = ReminderSettings.fromJsonString(settingsJson);

    if (!settings.enabled || settings.selectedTasbeehIds.isEmpty) {
      return;
    }

    final intervalMinutes = settings.intervalMinutes;
    final scheduleMinutes = intervalMinutes < 15 ? 15 : intervalMinutes;

    await Workmanager().registerPeriodicTask(
      _tasbeehReminderTaskName,
      _tasbeehReminderTaskName,
      frequency: Duration(minutes: scheduleMinutes),
      initialDelay: Duration(minutes: intervalMinutes),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  // Show reminder immediately (for testing or first run)
  static Future<void> showImmediate() async {
    await _handleReminderTask();
  }

  @pragma('vm:entry-point')
  static Future<void> _handleReminderTask() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('reminder_settings');

    if (settingsJson == null) return;

    final settings = ReminderSettings.fromJsonString(settingsJson);

    if (!settings.enabled || settings.selectedTasbeehIds.isEmpty) {
      return;
    }

    // Check overlay permission one last time
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      return;
    }

    final lastCompletedTimestamp = prefs.getInt(_lastCompletedTimestampKey);
    if (lastCompletedTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMinutes = (now - lastCompletedTimestamp) / 60000;
      // Don't show if completed less than 5 mins ago, UNLESS it's a manual trigger (but we don't distinguish here)
      // For manual trigger from settings, we might want to bypass this.
    }

    final lastIndex = prefs.getInt(_lastShownIndexKey) ?? 0;
    final selectedIds = settings.selectedTasbeehIds;
    final nextIndex = (lastIndex + 1) % selectedIds.length;
    final tasbeehId = selectedIds[nextIndex];

    await prefs.setInt(_lastShownIndexKey, nextIndex);

    final tasbeehText = await _getTasbeehText(tasbeehId);
    final targetCount = await _getTasbeehTargetCount(tasbeehId);
    final allowCloseAnytime = settings.allowCloseAnytime;
    final lang = prefs.getString('app_language') ?? 'ar';

    final overlayData = {
      'tasbeehId': tasbeehId,
      'tasbeehText': tasbeehText,
      'targetCount': targetCount,
      'allowCloseAnytime': allowCloseAnytime,
      'lang': lang,
    };

    // Store in prefs as well so overlay can read it on start
    await prefs.setString('current_overlay_data', jsonEncode(overlayData));

    if (!await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.showOverlay(
        height: 500, // Increased height
        width: 400,  // Increased width
        overlayTitle: AppStrings.get('tasbeeh_reminder_overlay_title', lang),
        overlayContent: AppStrings.get('tasbeeh_reminder_overlay_content', lang),
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );
    }

    // Small delay to ensure overlay is ready
    await Future.delayed(const Duration(milliseconds: 1000));
    await FlutterOverlayWindow.shareData(overlayData);
  }

  // Helper to get tasbeeh text
  static Future<String> _getTasbeehText(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customListJson = prefs.getString('custom_tasbeeh_list');

    if (customListJson != null) {
      try {
        final decoded = jsonDecode(customListJson) as List<dynamic>;
        final customList =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        final custom = customList.firstWhere(
          (t) => t['id'] == id,
          orElse: () => {},
        );
        if (custom.isNotEmpty) {
          return custom['text'] as String;
        }
      } catch (e) {
        // Ignore error, treat as preset
      }
    }

    return id;
  }

  // Helper to get tasbeeh target count
  static Future<int> _getTasbeehTargetCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customListJson = prefs.getString('custom_tasbeeh_list');

    if (customListJson != null) {
      try {
        final decoded = jsonDecode(customListJson) as List<dynamic>;
        final customList =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        final custom = customList.firstWhere(
          (t) => t['id'] == id,
          orElse: () => {},
        );
        if (custom.isNotEmpty) {
          return custom['targetCount'] as int;
        }
      } catch (e) {
        // Ignore error, use default
      }
    }

    return 100;
  }

  // Call this when tasbeeh is completed in overlay
  static Future<void> markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastCompletedTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Cancel all scheduled work
  static Future<void> cancelAll() async {
    await Workmanager().cancelByUniqueName(_tasbeehReminderTaskName);
  }
}
