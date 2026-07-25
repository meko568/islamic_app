import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_task_model.dart';
import '../services/tracker_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/prayer_service.dart';

class TrackerProvider extends ChangeNotifier {
  final CloudSyncService _sync = CloudSyncService();
  static const _uuid = Uuid();

  String? _uid;
  String _date = '';
  DailyRecord _record = DailyRecord(date: '');
  List<CustomTaskDef> _customTasks = [];
  bool _loading = true;
  PrayerTimes? _prayerTimes;

  String get date => _date;
  DailyRecord get record => _record;
  List<CustomTaskDef> get customTasks => _customTasks;
  bool get loading => _loading;

  List<DailyTaskDef> get allTasks => [
    ...DailyTaskDef.presets,
    ..._customTasks.map(
      (c) => DailyTaskDef(
        id: c.id,
        titleAr: c.title,
        titleEn: c.title,
        type: DailyTaskType.custom,
        isPreset: false,
      ),
    ),
  ];

  static const Map<String, Prayer> _prayerTaskMap = {
    'prayer_fajr': Prayer.fajr,
    'prayer_dhuhr': Prayer.dhuhr,
    'prayer_asr': Prayer.asr,
    'prayer_maghrib': Prayer.maghrib,
    'prayer_isha': Prayer.isha,
  };

  TrackerProvider() {
    load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _date = await TrackerStorageService.getCurrentTrackerDate();
    _record = await TrackerStorageService.loadRecord(_date);
    _customTasks = await TrackerStorageService.loadCustomTasks();
    _prayerTimes = await TrackerStorageService.getTodayPrayerTimes();
    await _mergeAutoDetectedPrayers();

    _loading = false;
    notifyListeners();
  }

  /// Pulls checked-prayer state from the Prayer Times screen's own storage
  /// so a prayer marked there shows up here automatically (only valid for
  /// the current calendar day, since PrayerService only tracks "today").
  Future<void> _mergeAutoDetectedPrayers() async {
    final today = await TrackerStorageService.getCurrentTrackerDate();
    if (_date != today) return;

    bool changed = false;
    for (final entry in _prayerTaskMap.entries) {
      final alreadyDone = _record.tasks[entry.key]?.done ?? false;
      if (alreadyDone) continue;
      final checked = await PrayerService.isPrayerChecked(entry.value);
      if (checked) {
        _record.tasks[entry.key] = TaskCompletion(done: true, auto: true);
        changed = true;
      }
    }
    if (changed) await TrackerStorageService.saveRecord(_record);
  }

  /// Call this whenever the tracker screen becomes visible again, to pick up
  /// prayers checked in the meantime from the Prayer Times screen.
  Future<void> refresh() async {
    final today = await TrackerStorageService.getCurrentTrackerDate();
    if (_date != today) {
      await load();
      return;
    }
    await _mergeAutoDetectedPrayers();
    notifyListeners();
  }

  bool isDone(String taskId) => _record.tasks[taskId]?.done ?? false;
  bool isAuto(String taskId) => _record.tasks[taskId]?.auto ?? false;

  /// True when [taskId] is a prayer task whose scheduled time hasn't
  /// arrived yet today - used to keep its checkbox disabled until then.
  bool isPrayerLocked(String taskId) {
    final prayer = _prayerTaskMap[taskId];
    if (prayer == null || _prayerTimes == null) return false;
    final time = _prayerTimes!.timeForPrayer(prayer);
    if (time == null) return false;
    return DateTime.now().isBefore(time);
  }

  /// Marks a task as done automatically from another screen (e.g. finishing
  /// all of today's Morning/Evening Azkar). No-op if already done.
  Future<void> markAutoDone(String taskId) async {
    if (_record.tasks[taskId]?.done ?? false) return;
    _record.tasks[taskId] = TaskCompletion(done: true, auto: true);
    notifyListeners();
    await TrackerStorageService.saveRecord(_record);
    _sync.pushOnDataChange(_uid);
  }

  Future<void> toggleTask(String taskId) async {
    final current = _record.tasks[taskId]?.done ?? false;
    _record.tasks[taskId] = TaskCompletion(done: !current, auto: false);
    notifyListeners();
    await TrackerStorageService.saveRecord(_record);

    // Two-way sync: a manual check here also marks the prayer as prayed
    // on the Prayer Times screen.
    final prayer = _prayerTaskMap[taskId];
    if (prayer != null) {
      await PrayerService.setPrayerChecked(prayer, !current);
    }

    _sync.pushOnDataChange(_uid);
  }

  Future<void> addCustomTask(String title) async {
    final task = CustomTaskDef(id: _uuid.v4(), title: title.trim());
    _customTasks = [..._customTasks, task];
    await TrackerStorageService.saveCustomTasks(_customTasks);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  Future<void> removeCustomTask(String taskId) async {
    _customTasks = _customTasks.where((t) => t.id != taskId).toList();
    _record.tasks.remove(taskId);
    await TrackerStorageService.saveCustomTasks(_customTasks);
    await TrackerStorageService.saveRecord(_record);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  Future<List<DailyRecord>> loadHistory(int days) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    return TrackerStorageService.loadHistory(from, to);
  }

  /// Called by the app whenever the signed-in user changes (login/logout).
  Future<void> attachUser(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    // The main.dart _AuthSync handles the global syncOnLogin which includes tracker.
    if (uid != null) {
      // Just refresh local state after potential pull
      await load();
    }
  }
}
