import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/feature_card.dart';
import '../widgets/update_dialog.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/update_check_service.dart';
import 'profile_screen.dart';
import 'achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    final updateResult = await UpdateCheckService().checkForUpdate();
    if (updateResult.hasUpdate && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !updateResult.forceUpdate,
        builder: (context) => UpdateDialog(updateInfo: updateResult),
      );
    }
  }

  LinearGradient _buildFeatureGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.accent.withValues(alpha: 0.2),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryLight.withValues(alpha: 0.2),
        AppColors.accent.withValues(alpha: 0.15),
      ],
    );
  }

  Widget _buildMiniLevelBadge(BuildContext context, String lang) {
    final stats = context.watch<AchievementProvider>().stats;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${stats.currentLevel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              lang == 'ar' ? 'المستوى' : 'Level',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('islamic_app', lang),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 28),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                auth.isLoggedIn ? Icons.person : Icons.person_outline,
              ),
              tooltip: AppStrings.get('account', lang),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('home', lang),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.get('explore_islamic_learning_tools', lang),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _buildMiniLevelBadge(context, lang),
                  ],
                ),
                const SizedBox(height: 28),

                // Feature grid
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    FeatureCard(
                      title: AppStrings.get('azkar', lang),
                      icon: Icons.menu_book,
                      isActive: true,
                      gradient: _buildFeatureGradient(isDark),
                      onTap: () {
                        Navigator.pushNamed(context, '/azkar');
                      },
                    ),
                    FeatureCard(
                      title: AppStrings.get('quran', lang),
                      icon: Icons.book,
                      isActive: true,
                      gradient: _buildFeatureGradient(isDark),
                      onTap: () {
                        Navigator.pushNamed(context, '/quran');
                      },
                    ),
                    FeatureCard(
                      title: AppStrings.get('tasbeeh', lang),
                      icon: Icons.adjust,
                      isActive: true,
                      gradient: _buildFeatureGradient(isDark),
                      onTap: () {
                        Navigator.pushNamed(context, '/tasbeeh');
                      },
                    ),
                    FeatureCard(
                      title: AppStrings.get('prayer_times', lang),
                      icon: Icons.schedule,
                      isActive: true,
                      gradient: _buildFeatureGradient(isDark),
                      onTap: () {
                        Navigator.pushNamed(context, '/prayer-times');
                      },
                    ),
                    FeatureCard(
                      title: AppStrings.get('daily_tracker', lang),
                      icon: Icons.checklist_rtl,
                      isActive: true,
                      gradient: _buildFeatureGradient(isDark),
                      onTap: () {
                        Navigator.pushNamed(context, '/daily-tracker');
                      },
                    ),
                    FeatureCard(
                      title: AppStrings.get('targets', lang),
                      icon: Icons.flag_outlined,
                      isActive: true,
                      gradient: _buildFeatureGradient(isDark),
                      onTap: () {
                        Navigator.pushNamed(context, '/targets');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
