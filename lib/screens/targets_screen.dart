import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/target_provider.dart';
import '../models/target_model.dart';
import '../theme/app_theme.dart';

class TargetsScreen extends StatelessWidget {
  const TargetsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final targetProvider = context.watch<TargetProvider>();

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.get('my_targets', lang))),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTargetDialog(context, lang),
          icon: const Icon(Icons.add),
          label: Text(AppStrings.get('add_target', lang)),
        ),
        body: targetProvider.loading
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
                  );
                },
              ),
      ),
    );
  }
}
