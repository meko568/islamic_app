import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final provider = context.watch<AchievementProvider>();
    final stats = provider.stats;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'ar' ? 'الإنجازات والمستوى' : 'Achievements & Level'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildLevelCard(context, stats, lang),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final achievement = Achievement.allAchievements[index];
                        final isUnlocked = provider.isUnlocked(achievement.id);
                        return _buildAchievementIcon(context, achievement, isUnlocked, lang);
                      },
                      childCount: Achievement.allAchievements.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLevelCard(BuildContext context, UserStats stats, String lang) {
    final level = stats.currentLevel;
    final progress = stats.levelProgress;
    final nextLevelXp = UserStats.xpForLevel(level + 1);
    final currentXp = stats.totalXp;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'ar' ? 'المستوى الحجري' : 'User Level',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _getLevelTitle(level, lang),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentXp XP',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '$nextLevelXp XP',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang == 'ar' 
                ? 'باقي ${nextLevelXp - currentXp} XP للمستوى التالي'
                : '${nextLevelXp - currentXp} XP left for next level',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementIcon(BuildContext context, Achievement achievement, bool isUnlocked, String lang) {
    return GestureDetector(
      onTap: () => _showAchievementDetails(context, achievement, isUnlocked, lang),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? Theme.of(context).colorScheme.primaryContainer 
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isUnlocked 
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(achievement.category),
                  size: 32,
                  color: isUnlocked 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title(lang),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement, bool isUnlocked, String lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(achievement.category),
                size: 64,
                color: isUnlocked ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                achievement.title(lang),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description(lang),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${achievement.xpReward} XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!isUnlocked)
                 Text(
                   lang == 'ar' ? 'لم يتم الإنجاز بعد' : 'Not achieved yet',
                   style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                 )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      lang == 'ar' ? 'تم الإنجاز!' : 'Completed!',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak: return Icons.bolt;
      case AchievementCategory.prayer: return Icons.mosque;
      case AchievementCategory.azkar: return Icons.wb_sunny;
      case AchievementCategory.tasbeeh: return Icons.touch_app;
      case AchievementCategory.quran: return Icons.menu_book;
      case AchievementCategory.targets: return Icons.flag;
      case AchievementCategory.general: return Icons.stars;
    }
  }

  String _getLevelTitle(int level, String lang) {
    if (lang == 'ar') {
      if (level < 5) return 'مبتدئ';
      if (level < 10) return 'مواظب';
      if (level < 20) return 'مجتهد';
      if (level < 35) return 'عابد';
      if (level < 50) return 'قانت';
      return 'سابق بالخيرات';
    } else {
      if (level < 5) return 'Beginner';
      if (level < 10) return 'Consistent';
      if (level < 20) return 'Diligent';
      if (level < 35) return 'Devoted';
      if (level < 50) return 'Pious';
      return 'Foremost in Good Deeds';
    }
  }
}
