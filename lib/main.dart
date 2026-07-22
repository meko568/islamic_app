import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:islamic_app/screens/tasbeeh_screen.dart';
import 'screens/home_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/azkar_detail_screen.dart';
import 'screens/prayer_times_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbeeh_reminder_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/daily_tracker_screen.dart';
import 'screens/targets_screen.dart';
import 'models/azkar_model.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/tracker_provider.dart';
import 'providers/target_provider.dart';
import 'services/reminder_scheduler_service.dart';
import 'overlay/tasbeeh_overlay_app.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    // The app must keep working fully offline even if Firebase can't
    // initialize (no network, no config, etc). Login features simply
    // won't be available until this succeeds on a later launch.
    debugPrint('Firebase init failed (app continues offline): $e');
  }

  if (!kIsWeb) {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          _handleNotificationClick(response.payload);
        },
      );

      // Handle notification if app was closed
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final String? payload = notificationAppLaunchDetails?.notificationResponse?.payload;
        if (payload != null) {
          // Give the app a moment to load the first screen before pushing
          Future.delayed(const Duration(seconds: 1), () {
            _handleNotificationClick(payload);
          });
        }
      }

    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
    
    await ReminderSchedulerService.initialize();
  }
  runApp(const IslamicApp());
}

void _handleNotificationClick(String? payload) {
  if (payload != null && navigatorKey.currentState != null) {
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (context) => TasbeehReminderScreen(tasbeehId: payload),
      ),
    );
  }
}

@pragma('vm:entry-point')
void overlayMain() {
  debugPrint('OVERLAY ENGINE STARTING...');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TasbeehOverlayApp());
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
        ChangeNotifierProvider(create: (_) => TargetProvider()),
      ],
      child: const _AuthSync(child: _AppView()),
    );
  }
}

/// Keeps TrackerProvider/TargetProvider in sync whenever the signed-in
/// user changes (login, logout, or a different account), without forcing
/// every screen to know about auth.
class _AuthSync extends StatefulWidget {
  final Widget child;
  const _AuthSync({required this.child});

  @override
  State<_AuthSync> createState() => _AuthSyncState();
}

class _AuthSyncState extends State<_AuthSync> {
  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TrackerProvider>().attachUser(uid);
      context.read<TargetProvider>().attachUser(uid);
    });
    return widget.child;
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'التطبيق الإسلامي',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(settings.appFontSize),
            darkTheme: AppTheme.darkTheme(settings.appFontSize),
            themeMode: settings.themeMode,
            locale: Locale(settings.appLanguage),
            home: settings.isLoading ? const LoadingScreen() : const HomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/azkar': (context) => const AzkarScreen(),
              '/tasbeeh': (context) => TasbeehScreen(),
              '/prayer-times': (context) => const PrayerTimesScreen(),
              '/quran': (context) => const QuranScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/daily-tracker': (context) => const DailyTrackerScreen(),
              '/targets': (context) => const TargetsScreen(),
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
    );
  }
}
