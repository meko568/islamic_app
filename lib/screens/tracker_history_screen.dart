import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/tracker_provider.dart';
import '../models/daily_task_model.dart';
import '../theme/app_theme.dart';

class TrackerHistoryScreen extends StatefulWidget {
  const TrackerHistoryScreen({super.key});

  @override
  State<TrackerHistoryScreen> createState() => _TrackerHistoryScreenState();
}

class _TrackerHistoryScreenState extends State<TrackerHistoryScreen> {
  static const int _daysToShow = 30;
  late Future<List<DailyRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = context.read<TrackerProvider>().loadHistory(
      _daysToShow,
    );
  }

  /// Looks at the missed tasks across all loaded days and returns up to 2
  /// short pieces of advice about the tasks the person skips most often.
  List<String> _buildAdvice(
    List<DailyRecord> records,
    List<DailyTaskDef> allTasks,
    String lang,
  ) {
    if (records.isEmpty) return [];
    final missedCount = <String, int>{};
    for (final record in records) {
      for (final task in allTasks) {
        final done = record.tasks[task.id]?.done ?? false;
        if (!done) {
          missedCount[task.id] = (missedCount[task.id] ?? 0) + 1;
        }
      }
    }
    final entries = missedCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final advice = <String>[];
    for (final entry in entries.take(2)) {
      if (entry.value < 3) continue; // not a real pattern yet
      final task = allTasks.firstWhere(
        (t) => t.id == entry.key,
        orElse: () => DailyTaskDef(
          id: entry.key,
          titleAr: entry.key,
          titleEn: entry.key,
          type: DailyTaskType.custom,
        ),
      );
      final ratio = (entry.value / records.length * 100).round();
      advice.add(
        lang == 'ar'
            ? 'لاحظت إنك بتفوّت "${task.title(lang)}" في $ratio% من الأيام، حاول تركّز عليها أكتر'
            : 'You missed "${task.title(lang)}" on $ratio% of days - try to focus on it more',
      );
    }
    return advice;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final tracker = context.watch<TrackerProvider>();
    final allTasks = tracker.allTasks;

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('history', lang))),
        body: FutureBuilder<List<DailyRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data!
              ..sort((a, b) => b.date.compareTo(a.date));

            if (records.isEmpty) {
              return Center(
                child: Text(AppStrings.get('no_history_yet', lang)),
              );
            }

            final advice = _buildAdvice(records, allTasks, lang);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (advice.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get('advice_title', lang),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...advice.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              a,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...records.map((record) {
                  final total = allTasks.isEmpty ? 1 : allTasks.length;
                  final done = allTasks
                      .where((t) => record.tasks[t.id]?.done ?? false)
                      .length;
                  final ratio = done / total;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        record.date,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            color: ratio == 1
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      trailing: Text('$done/$total'),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        builder: (sheetContext) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                record.date,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...allTasks.map((task) {
                                final taskDone =
                                    record.tasks[task.id]?.done ?? false;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    taskDone
                                        ? Icons.check_circle
                                        : Icons.cancel_outlined,
                                    color: taskDone
                                        ? AppColors.success
                                        : AppColors.secondaryText,
                                  ),
                                  title: Text(task.title(lang)),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
