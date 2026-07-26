import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tracker_provider.dart';
import '../services/stats_service.dart';
import '../providers/achievement_provider.dart';
import '../models/achievement_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _lifetimeTasbeeh = 0;
  int _perfectDays = 0;
  int _daysTracked = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasbeeh = await StatsService.getLifetimeTasbeeh();
    final tracker = context.read<TrackerProvider>();
    final history = await tracker.loadHistory(365);
    final allTasks = tracker.allTasks;
    final total = allTasks.isEmpty ? 1 : allTasks.length;
    int perfect = 0;
    for (final record in history) {
      final done = allTasks
          .where((t) => record.tasks[t.id]?.done ?? false)
          .length;
      if (done == total) perfect++;
    }
    if (!mounted) return;
    setState(() {
      _lifetimeTasbeeh = tasbeeh;
      _perfectDays = perfect;
      _daysTracked = history.length;
      _loading = false;
    });
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final auth = context.watch<AuthProvider>();
    final achievementProvider = context.watch<AchievementProvider>();
    final stats = achievementProvider.stats;

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('account', lang))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(
                      auth.isLoggedIn ? Icons.person : Icons.person_outline,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isLoggedIn
                              ? (auth.user?.email ?? AppStrings.get('signed_in_as', lang))
                              : AppStrings.get('guest_account', lang),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${lang == 'ar' ? 'المستوى' : 'Level'} ${stats.currentLevel}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              // Level Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${stats.totalXp} XP',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${UserStats.xpForLevel(stats.currentLevel + 1)} XP',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stats.levelProgress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    _statCard(
                      '$_lifetimeTasbeeh',
                      AppStrings.get('lifetime_tasbeeh', lang),
                      Icons.adjust_outlined,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      '$_perfectDays/$_daysTracked',
                      AppStrings.get('perfect_days', lang),
                      Icons.emoji_events_outlined,
                    ),
                  ],
                ),
              const SizedBox(height: 28),
              if (auth.isLoggedIn)
                OutlinedButton.icon(
                  onPressed: () => auth.signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(AppStrings.get('logout', lang)),
                )
              else
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.login),
                  label: Text(AppStrings.get('login', lang)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
