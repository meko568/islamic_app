import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/target_provider.dart';
import '../models/target_model.dart';
import '../theme/app_theme.dart';
import '../services/advice_service.dart';
import 'quran_screen.dart';
import 'tasbeeh_screen.dart';

class TargetsScreen extends StatefulWidget {
  const TargetsScreen({super.key});

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _periodLabel(TargetPeriod period, String lang) {
    switch (period) {
      case TargetPeriod.daily:
        return AppStrings.get('daily', lang);
      case TargetPeriod.weekly:
        return AppStrings.get('weekly', lang);
      case TargetPeriod.monthly:
        return AppStrings.get('monthly', lang);
    }
  }

  Future<void> _showAddTargetDialog(BuildContext context, String lang) async {
    final presets = IslamicTarget.presetTemplates(lang);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.get('choose_preset_or_custom', lang),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...presets.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(p['title'] as String),
                      subtitle: Text(
                        '${_periodLabel(p['period'] as TargetPeriod, lang)} · ${p['goal']} ${p['unit']}',
                      ),
                      onTap: () {
                        context.read<TargetProvider>().addTarget(
                          title: p['title'] as String,
                          period: p['period'] as TargetPeriod,
                          goal: p['goal'] as int,
                          unit: p['unit'] as String,
                          isPreset: true,
                          linkType: p['linkType'] as String?,
                        );
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(AppStrings.get('custom_target', lang)),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showCustomTargetDialog(context, lang);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomTargetDialog(
    BuildContext context,
    String lang,
  ) async {
    final titleController = TextEditingController();
    final goalController = TextEditingController(text: '1');
    final unitController = TextEditingController();
    TargetPeriod period = TargetPeriod.daily;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppStrings.get('add_target', lang)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('target_title', lang),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TargetPeriod>(
                  value: period,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('target_period', lang),
                  ),
                  items: TargetPeriod.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(_periodLabel(p, lang)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => period = v ?? period),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('target_goal', lang),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('target_unit', lang),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.get('cancel', lang)),
            ),
            FilledButton(
              onPressed: () {
                final goal = int.tryParse(goalController.text) ?? 1;
                if (titleController.text.trim().isEmpty) return;
                context.read<TargetProvider>().addTarget(
                  title: titleController.text,
                  period: period,
                  goal: goal < 1 ? 1 : goal,
                  unit: unitController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppStrings.get('add', lang)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTasbeehGoalDialog(
    BuildContext context,
    String lang,
    IslamicTarget target,
  ) async {
    final goalController = TextEditingController(text: target.goal.toString());

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.get('edit_repeat_count', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              target.title,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.get('target_goal', lang),
                suffixText: target.unit,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          FilledButton(
            onPressed: () {
              final goal = int.tryParse(goalController.text) ?? target.goal;
              context.read<TargetProvider>().updateTarget(
                id: target.id,
                goal: goal < 1 ? 1 : goal,
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(AppStrings.get('save', lang)),
          ),
        ],
      ),
    );
  }

  void _openLinkedScreen(BuildContext context, IslamicTarget target) {
    final link = target.linkType;
    if (link == null) return;
    if (link == 'tasbeeh') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => TasbeehScreen()));
    } else if (link.startsWith('surah:')) {
      final surahNumber = int.tryParse(link.split(':').last);
      if (surahNumber != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuranScreen(initialSurahNumber: surahNumber),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final targetProvider = context.watch<TargetProvider>();

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('my_targets', lang)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: AppStrings.get('my_targets', lang)),
              Tab(text: AppStrings.get('goals_summary', lang)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTargetDialog(context, lang),
          icon: const Icon(Icons.add),
          label: Text(AppStrings.get('add_target', lang)),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTargets(context, targetProvider, lang),
            _buildSummaryTable(context, targetProvider, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTargets(BuildContext context, TargetProvider targetProvider, String lang) {
    return targetProvider.loading
        ? const Center(child: CircularProgressIndicator())
        : targetProvider.targets.isEmpty
            ? Center(child: Text(AppStrings.get('no_targets_yet', lang)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: targetProvider.targets.length,
                itemBuilder: (context, index) {
                  final target = targetProvider.targets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: target.linkType == null
                          ? null
                          : () => _openLinkedScreen(context, target),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    target.title,
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (target.isDone)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                  ),
                                if (target.linkType == 'tasbeeh')
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showEditTasbeehGoalDialog(
                                      context,
                                      lang,
                                      target,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  onPressed: () => context
                                      .read<TargetProvider>()
                                      .removeTarget(target.id),
                                ),
                              ],
                            ),
                            Text(
                              _periodLabel(target.period, lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: target.goal == 0
                                    ? 0
                                    : target.progress / target.goal,
                                minHeight: 8,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                color: target.isDone
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${target.progress} / ${target.goal} ${target.unit}',
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                  ),
                                  onPressed: target.progress <= 0
                                      ? null
                                      : () => context
                                            .read<TargetProvider>()
                                            .incrementProgress(
                                              target.id,
                                              by: -1,
                                            ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: target.isDone
                                      ? null
                                      : () => context
                                            .read<TargetProvider>()
                                            .incrementProgress(target.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildSummaryTable(BuildContext context, TargetProvider targetProvider, String lang) {
    if (targetProvider.targets.isEmpty && targetProvider.history.isEmpty) {
      return Center(child: Text(AppStrings.get('no_targets_yet', lang)));
    }

    final allRecords = <dynamic>[
      ...targetProvider.targets,
      ...targetProvider.history,
    ];

    final hasIncompleteGoals = targetProvider.targets.any((t) => !t.isDone);
    final advice = hasIncompleteGoals 
        ? AdviceService.getRandomAdvice(lang, type: AdviceType.general)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (advice != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      advice,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(0.8),
                },
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B6914).withOpacity(0.1),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppStrings.get('target_title', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          lang == 'ar' ? 'التاريخ' : 'Date',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppStrings.get('goal_type', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppStrings.get('goal_status', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  // Rows
                  ...allRecords.map((item) {
                    final bool isHistory = item is GoalHistoryRecord;
                    final String title = item.title;
                    final TargetPeriod period = item.period;
                    final bool isDone = item.isDone;
                    final String date = isHistory ? item.date : (lang == 'ar' ? 'حالياً' : 'Current');

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(title, style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(date, style: const TextStyle(fontSize: 10)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(_periodLabel(period, lang), style: const TextStyle(fontSize: 10)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isDone ? AppColors.success : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
