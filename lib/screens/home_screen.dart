import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/feature_card.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                Column(
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
