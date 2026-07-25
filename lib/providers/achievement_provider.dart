import 'package:flutter/material.dart';
import 'dart:async';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';

class AchievementProvider extends ChangeNotifier {
  UserStats _stats = UserStats();
  bool _loading = true;
  String? _uid;

  final _newAchievementController = StreamController<Achievement>.broadcast();
  Stream<Achievement> get onAchievementUnlocked => _newAchievementController.stream;

  UserStats get stats => _stats;
  bool get loading => _loading;

  AchievementProvider() {
    load();
  }

  @override
  void dispose() {
    _newAchievementController.close();
    super.dispose();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    
    _stats = await AchievementService.loadStats();
    
    _loading = false;
    notifyListeners();
  }

  void updateUid(String? uid) {
    _uid = uid;
  }

  /// Triggers an achievement check. This should be called when 
  /// tasks are completed or counters updated.
  Future<List<Achievement>> checkAndUnlock() async {
    final newAchievements = await AchievementService.checkAchievements(_uid);
    if (newAchievements.isNotEmpty) {
      _stats = await AchievementService.loadStats();
      notifyListeners();
      for (final achievement in newAchievements) {
        _newAchievementController.add(achievement);
      }
    }
    return newAchievements;
  }

  bool isUnlocked(String achievementId) {
    return _stats.unlockedAchievementIds.contains(achievementId);
  }

  List<Achievement> get unlockedAchievements {
    return Achievement.allAchievements
        .where((a) => _stats.unlockedAchievementIds.contains(a.id))
        .toList();
  }

  List<Achievement> get lockedAchievements {
    return Achievement.allAchievements
        .where((a) => !_stats.unlockedAchievementIds.contains(a.id))
        .toList();
  }
}
