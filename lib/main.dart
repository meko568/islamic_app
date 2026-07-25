import 'package:flutter/material.dart';
import 'package:islamic_app/screens/loading_screen.dart';
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
import 'services/cloud_sync_service.dart';
import 'overlay/tasbeeh_overlay_app.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'screens/onboarding_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

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
        onDidReceiveNotificationResponse: (
          NotificationResponse response,
        ) async {
          _handleNotificationClick(response.payload);
        },
      );

      // Handle notification if app was closed
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final String? payload =
            notificationAppLaunchDetails?.notificationResponse?.payload;
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
    if (payload == 'prayer_reminder') {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const PrayerTimesScreen()),
      );
    } else {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => TasbeehReminderScreen(tasbeehId: payload),
        ),
      );
    }
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
/// user changes (login, logout, or a different account), and handles
/// cloud backup/restore via CloudSyncService.
class _AuthSync extends StatefulWidget {
  final Widget child;
  const _AuthSync({required this.child});

  @override
  State<_AuthSync> createState() => _AuthSyncState();
}

class _AuthSyncState extends State<_AuthSync> with WidgetsBindingObserver {
  String? _lastUid;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        _lastUid != null) {
      // Final backup on app close/pause
      CloudSyncService().pushLocalDataToCloud(_lastUid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    final lang = context.read<SettingsProvider>().appLanguage;

    if (uid != _lastUid) {
      final wasNull = _lastUid == null;
      _lastUid = uid;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // 1. Update providers with new UID
        context.read<SettingsProvider>().attachUser(uid);
        context.read<ReminderProvider>().attachUser(uid);
        context.read<TrackerProvider>().attachUser(uid);
        context.read<TargetProvider>().attachUser(uid);

        // 2. Perform sync if logged in and it's a fresh login (not just app restart)
        if (uid != null && wasNull) {
          setState(() => _isSyncing = true);

          try {
            await CloudSyncService().syncOnLogin(uid);
          } finally {
            if (mounted) setState(() => _isSyncing = false);
          }

          // 3. Reload providers to pick up restored data
          if (mounted) {
            await context.read<SettingsProvider>().loadSettings();
            await context.read<ReminderProvider>().loadSettings();
            await context.read<TrackerProvider>().load();
            await context.read<TargetProvider>().load();
          }
        }
      });
    }

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isSyncing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            lang == 'ar'
                                ? 'جاري مزامنة البيانات...'
                                : 'Syncing data...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
          title: 'دَرْبُ الْإِيمَانِ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(settings.appFontSize),
          darkTheme: AppTheme.darkTheme(settings.appFontSize),
          themeMode: settings.themeMode,
          locale: Locale(settings.appLanguage),
          home:
              settings.isLoading
                  ? const LoadingScreen()
                  : settings.isFirstLaunch
                  ? const OnboardingScreen()
                  : const HomeScreen(),
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
