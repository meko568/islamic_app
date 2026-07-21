import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/target_model.dart';
import '../services/target_storage_service.dart';
import '../services/firestore_sync_service.dart';

class TargetProvider extends ChangeNotifier {
  final FirestoreSyncService _sync = FirestoreSyncService();
  static const _uuid = Uuid();

  String? _uid;
  List<IslamicTarget> _targets = [];
  bool _loading = true;

  List<IslamicTarget> get targets => _targets;
  bool get loading => _loading;

  TargetProvider() {
    load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _targets = await TargetStorageService.loadTargets();
    await _resetExpiredCycles();
    _loading = false;
    notifyListeners();
  }

  /// If a target's stored cycle (e.g. last week) doesn't match the current
  /// one, its progress resets to 0 for the new day/week/month.
  Future<void> _resetExpiredCycles() async {
    bool changed = false;
    for (final t in _targets) {
      final key = TargetStorageService.currentPeriodKey(t.period);
      if (t.periodKey != key) {
        t.periodKey = key;
        t.progress = 0;
        changed = true;
      }
    }
    if (changed) await TargetStorageService.saveTargets(_targets);
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
      periodKey: TargetStorageService.currentPeriodKey(period),
      isPreset: isPreset,
      linkType: linkType,
    );
    _targets = [..._targets, target];
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _pushIfLoggedIn();
  }

  Future<void> removeTarget(String id) async {
    _targets = _targets.where((t) => t.id != id).toList();
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _pushIfLoggedIn();
  }

  Future<void> incrementProgress(String id, {int by = 1}) async {
    final target = _targets.firstWhere((t) => t.id == id);
    target.progress = (target.progress + by).clamp(0, target.goal);
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _pushIfLoggedIn();
  }

  Future<void> setProgress(String id, int value) async {
    final target = _targets.firstWhere((t) => t.id == id);
    target.progress = value.clamp(0, target.goal);
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
    _pushIfLoggedIn();
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
      _pushIfLoggedIn();
    }
  }

  void _pushIfLoggedIn() {
    if (_uid != null) {
      unawaited(_sync.pushTargets(_uid!, _targets));
    }
  }

  /// Called whenever the signed-in user changes; merges cloud targets with
  /// local ones the first time a user logs in on this device.
  Future<void> attachUser(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;
    if (uid == null) return;

    final cloud = await _sync.pullTargets(uid);
    if (cloud == null) {
      unawaited(_sync.pushTargets(uid, _targets));
      return;
    }

    final merged = {for (final t in cloud) t.id: t};
    for (final t in _targets) {
      merged[t.id] = t;
    }
    _targets = merged.values.toList();
    await TargetStorageService.saveTargets(_targets);
    notifyListeners();
  }
}
