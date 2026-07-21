import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tracker_provider.dart';
import '../models/daily_task_model.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DailyTrackerScreen extends StatefulWidget {
  const DailyTrackerScreen({super.key});

  @override
  State<DailyTrackerScreen> createState() => _DailyTrackerScreenState();
}

class _DailyTrackerScreenState extends State<DailyTrackerScreen>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) {
      context.read<TrackerProvider>().refresh();
    }
  }

  IconData _iconFor(DailyTaskType type) {
    switch (type) {
      case DailyTaskType.prayer:
        return Icons.mosque_outlined;
      case DailyTaskType.azkar:
        return Icons.menu_book_outlined;
      case DailyTaskType.tasbeeh:
        return Icons.adjust_outlined;
      case DailyTaskType.quran:
        return Icons.book_outlined;
      case DailyTaskType.custom:
        return Icons.check_circle_outline;
    }
  }

  Future<void> _showAddTaskDialog(BuildContext context, String lang) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.get('add_custom_task', lang)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.get('custom_task_hint', lang),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<TrackerProvider>().addCustomTask(
                  controller.text,
                );
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(AppStrings.get('add', lang)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final auth = context.watch<AuthProvider>();
    final tracker = context.watch<TrackerProvider>();

    final doneCount = tracker.allTasks
        .where((t) => tracker.isDone(t.id))
        .length;
    final totalCount = tracker.allTasks.length;

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('daily_tracker', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddTaskDialog(context, lang),
            ),
          ],
        ),
        body: tracker.loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    if (!auth.isLoggedIn)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.get('guest_mode_warning', lang),
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: Text(AppStrings.get('login', lang)),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.get('today_tasks', lang),
                                  style: GoogleFonts.cairo(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  AppStrings.get('day_starts_at_fajr', lang),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$doneCount/$totalCount',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalCount == 0 ? 0 : doneCount / totalCount,
                            minHeight: 8,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Expanded(
                      child: tracker.allTasks.isEmpty
                          ? Center(
                              child: Text(
                                AppStrings.get('no_tasks_yet', lang),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                24,
                              ),
                              itemCount: tracker.allTasks.length,
                              itemBuilder: (context, index) {
                                final task = tracker.allTasks[index];
                                final done = tracker.isDone(task.id);
                                final auto = tracker.isAuto(task.id);
                                final locked = tracker.isPrayerLocked(
                                  task.id,
                                );
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      _iconFor(task.type),
                                      color: done
                                          ? AppColors.success
                                          : AppColors.secondaryText,
                                    ),
                                    title: Text(task.title(lang)),
                                    subtitle: locked
                                        ? Text(
                                            AppStrings.get(
                                              'prayer_time_not_reached',
                                              lang,
                                            ),
                                            style: TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 11,
                                            ),
                                          )
                                        : (auto && done
                                              ? Text(
                                                  AppStrings.get(
                                                    'auto_detected',
                                                    lang,
                                                  ),
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.accentDark,
                                                    fontSize: 11,
                                                  ),
                                                )
                                              : null),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        locked
                                            ? const Icon(
                                                Icons.lock_outline,
                                                size: 20,
                                              )
                                            : Checkbox(
                                                value: done,
                                                onChanged: (_) => context
                                                    .read<TrackerProvider>()
                                                    .toggleTask(task.id),
                                              ),
                                        if (!task.isPreset)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            onPressed: () => context
                                                .read<TrackerProvider>()
                                                .removeCustomTask(task.id),
                                          ),
                                      ],
                                    ),
                                    onTap: locked
                                        ? null
                                        : () => context
                                              .read<TrackerProvider>()
                                              .toggleTask(task.id),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
