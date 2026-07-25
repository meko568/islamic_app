import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/target_model.dart';
import '../services/target_storage_service.dart';
import '../services/cloud_sync_service.dart';

class TargetProvider extends ChangeNotifier {
  final CloudSyncService _sync = CloudSyncService();
  static const _uuid = Uuid();

  String? _uid;
  List<IslamicTarget> _targets = [];
  List<GoalHistoryRecord> _history = [];
  bool _loading = true;

  List<IslamicTarget> get targets => _targets;
  List<GoalHistoryRecord> get history => _history;
  bool get loading => _loading;

  TargetProvider() {
    load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _targets = await TargetStorageService.loadTargets();
    _history = await TargetStorageService.loadHistory();
    await _resetExpiredCycles();
    _loading = false;
    notifyListeners();
  }

  /// If a target's stored cycle (e.g. last week) doesn't match the current
  /// one, its progress resets to 0 for the new day/week/month.
  Future<void> _resetExpiredCycles() async {
    bool changed = false;
    for (final t in _targets) {
      final key = await TargetStorageService.currentPeriodKey(t.period);
      if (t.periodKey != key) {
        // Before resetting, save to history
        await TargetStorageService.addToHistory(GoalHistoryRecord(
          targetId: t.id,
          title: t.title,
          period: t.period,
          goal: t.goal,
          progress: t.progress,
          date: t.periodKey,
        ));
        
        t.periodKey = key;
        t.progress = 0;
        changed = true;
      }
    }
    if (changed) {
      await TargetStorageService.saveTargets(_targets);
      _history = await TargetStorageService.loadHistory();
    }
  }

  Future<void> addTarget({
    required String title,
    required TargetPeriod period,
    required int goal,
    String unit = '',
    bool isPreset = false,
    String? linkType,
  }) async {
    final target = IslamicTarget(
      id: _uuid.v4(),
      title: title.trim(),
      period: period,
      goal: goal,
      unit: unit,
      periodKey: await TargetStorageService.currentPeriodKey(period),
      isPreset: isPreset,
      linkType: linkType,
    );
    _targets = [..._targets, target];
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  Future<void> updateTarget({
    required String id,
    String? title,
    int? goal,
    String? unit,
  }) async {
    final index = _targets.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final target = _targets[index];
    if (title != null) target.title = title.trim();
    if (goal != null) {
      target.goal = goal;
      if (target.progress > target.goal) target.progress = target.goal;
    }
    if (unit != null) target.unit = unit.trim();

    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  Future<void> removeTarget(String id) async {
    _targets = _targets.where((t) => t.id != id).toList();
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  Future<void> incrementProgress(String id, {int by = 1}) async {
    final target = _targets.firstWhere((t) => t.id == id);
    target.progress = (target.progress + by).clamp(0, target.goal);
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  Future<void> setProgress(String id, int value) async {
    final target = _targets.firstWhere((t) => t.id == id);
    target.progress = value.clamp(0, target.goal);
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _sync.pushOnDataChange(_uid);
  }

  /// Called from the Tasbeeh screen on every tap: bumps every active target
  /// linked to tasbeeh counting by [by] (default 1), capped at each goal.
  Future<void> incrementAllByLinkType(String linkType, {int by = 1}) async {
    bool changed = false;
    for (final t in _targets) {
      if (t.linkType == linkType && t.progress < t.goal) {
        t.progress = (t.progress + by).clamp(0, t.goal);
        changed = true;
      }
    }
    if (changed) {
      await TargetStorageService.saveTargets(_targets);
      notifyListeners();
      _sync.pushOnDataChange(_uid);
    }
  }

  /// Called whenever the signed-in user changes.
  Future<void> attachUser(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    if (uid != null) {
      await load();
    }
  }
}
