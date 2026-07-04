import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:islamic_app/screens/tasbeeh_screen.dart';
import 'screens/home_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/azkar_detail_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';
import 'models/azkar_model.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/reminder_provider.dart';
import 'services/reminder_scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await ReminderSchedulerService.initialize();
  }
  runApp(const IslamicApp());
}

class IslamicApp extends StatelessWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderProvider()..loadSettings(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'التطبيق الإسلامي',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(settings.appFontSize),
            darkTheme: AppTheme.darkTheme(settings.appFontSize),
            themeMode: settings.themeMode,
            locale: Locale(settings.appLanguage),
            home: const HomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/azkar': (context) => const AzkarScreen(),
              '/tasbeeh': (context) => TasbeehScreen(),
              '/prayer-times': (context) => const PrayerTimesScreen(),
              '/quran': (context) => const QuranScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/azkar-detail') {
                final category = settings.arguments as AzkarCategory;
                return MaterialPageRoute(
                  builder: (context) => AzkarDetailScreen(category: category),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
