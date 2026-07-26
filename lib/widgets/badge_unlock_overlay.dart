import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';
import '../providers/settings_provider.dart';

class BadgeUnlockOverlay extends StatefulWidget {
  final Widget child;
  const BadgeUnlockOverlay({super.key, required this.child});

  @override
  State<BadgeUnlockOverlay> createState() => _BadgeUnlockOverlayState();
}

class _BadgeUnlockOverlayState extends State<BadgeUnlockOverlay> {
  StreamSubscription? _achievementSub;
  StreamSubscription? _levelSub;
  Achievement? _currentAchievement;
  int? _newLevel;
  bool _isVisible = false;
  bool _isLevelUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AchievementProvider>();
      _achievementSub = provider.onAchievementUnlocked.listen((achievement) {
        _showBadge(achievement);
      });
      _levelSub = provider.onLevelUp.listen((level) {
        _showLevelUp(level);
      });
    });
  }

  @override
  void dispose() {
    _achievementSub?.cancel();
    _levelSub?.cancel();
    super.dispose();
  }

  void _showBadge(Achievement achievement) {
    if (!mounted) return;
    setState(() {
      _currentAchievement = achievement;
      _isLevelUp = false;
      _isVisible = true;
    });

    _hideAfterDelay();
  }

  void _showLevelUp(int level) {
    if (!mounted) return;
    setState(() {
      _newLevel = level;
      _isLevelUp = true;
      _isVisible = true;
    });

    _hideAfterDelay();
  }

  void _hideAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;

    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: GestureDetector(
                  onTap: () => setState(() => _isVisible = false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isLevelUp 
                        ? Colors.amber.shade50 
                        : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: _isLevelUp ? Colors.amber : Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: _isLevelUp ? _buildLevelUpRow(context, lang) : _buildBadgeRow(context, lang),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgeRow(BuildContext context, String lang) {
    if (_currentAchievement == null) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            image: DecorationImage(
              image: AssetImage(_currentAchievement!.icon),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'ar' ? 'أُنجز الوسام!' : 'Badge Unlocked!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
              Text(
                _currentAchievement!.title(lang),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                _currentAchievement!.description(lang),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${_currentAchievement!.xpReward} XP',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelUpRow(BuildContext context, String lang) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.trending_up, color: Colors.white, size: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'ar' ? 'تهانينا!' : 'Congratulations!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 13,
                ),
              ),
              Text(
                lang == 'ar' ? 'ارتفع مستواك!' : 'Level Up!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                lang == 'ar' ? 'لقد وصلت للمستوى $_newLevel' : 'You reached Level $_newLevel',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
