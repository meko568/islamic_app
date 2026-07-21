import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_task_model.dart';
import '../services/tracker_storage_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/prayer_service.dart';

class TrackerProvider extends ChangeNotifier {
  final FirestoreSyncService _sync = FirestoreSyncService();
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
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

    if (_uid != null) {
      unawaited(_sync.pushTrackerRecord(_uid!, _record));
    }
  }

  Future<void> addCustomTask(String title) async {
    final task = CustomTaskDef(id: _uuid.v4(), title: title.trim());
    _customTasks = [..._customTasks, task];
    await TrackerStorageService.saveCustomTasks(_customTasks);
    notifyListeners();
    if (_uid != null) {
      unawaited(_sync.pushCustomTasks(_uid!, _customTasks));
    }
  }

  Future<void> removeCustomTask(String taskId) async {
    _customTasks = _customTasks.where((t) => t.id != taskId).toList();
    _record.tasks.remove(taskId);
    await TrackerStorageService.saveCustomTasks(_customTasks);
    await TrackerStorageService.saveRecord(_record);
    notifyListeners();
    if (_uid != null) {
      unawaited(_sync.pushCustomTasks(_uid!, _customTasks));
      unawaited(_sync.pushTrackerRecord(_uid!, _record));
    }
  }

  Future<List<DailyRecord>> loadHistory(int days) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    return TrackerStorageService.loadHistory(from, to);
  }

  /// Called by the app whenever the signed-in user changes (login/logout).
  /// On first login, merges cloud data into local so nothing is lost.
  Future<void> attachUser(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    if (uid == null) return;

    final cloud = await _sync.pullTrackerData(uid);
    if (cloud == null) {
      // Nothing in the cloud yet - push what we have locally as first backup.
      unawaited(_sync.pushTrackerRecord(uid, _record));
      unawaited(_sync.pushCustomTasks(uid, _customTasks));
      return;
    }

    // Merge cloud custom tasks with local ones (union by id).
    final mergedCustom = {for (final t in cloud.customTasks) t.id: t};
    for (final t in _customTasks) {
      mergedCustom[t.id] = t;
    }
    _customTasks = mergedCustom.values.toList();
    await TrackerStorageService.saveCustomTasks(_customTasks);

    // Merge today's record: a task counts as done if either side has it done.
    final cloudRecord = cloud.records[_date];
    if (cloudRecord != null) {
      for (final entry in cloudRecord.tasks.entries) {
        final localDone = _record.tasks[entry.key]?.done ?? false;
        if (entry.value.done && !localDone) {
          _record.tasks[entry.key] = entry.value;
        }
      }
      await TrackerStorageService.saveRecord(_record);
    }

    notifyListeners();
  }
}
