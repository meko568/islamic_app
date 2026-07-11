import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/reminder_scheduler_service.dart';
import '../l10n/app_strings.dart';
import '../data/azkar_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _clearAzkarCache() async {
    final lang = context.read<SettingsProvider>().appLanguage;
    try {
      await AzkarData.clearCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('clear_azkar_cache', lang))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.appLanguage;
    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('settings', lang),
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: Icon(lang == 'ar' ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard(
              context,
              title: AppStrings.get('theme', lang),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(AppStrings.get('light', lang))),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(AppStrings.get('dark', lang))),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(AppStrings.get('auto', lang))),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) =>
                    settings.setThemeMode(newSelection.first),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: AppStrings.get('language', lang),
              children: [
                ListTile(
                    title: Text(AppStrings.get('app_language', lang),
                        style: GoogleFonts.cairo(
                            fontSize: 16, fontWeight: FontWeight.w600))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'ar',
                          label: Text(AppStrings.get('arabic_lang', lang))),
                      ButtonSegment(
                          value: 'en',
                          label: Text(AppStrings.get('english', lang))),
                    ],
                    selected: {settings.appLanguage},
                    onSelectionChanged: (Set<String> newSelection) =>
                        settings.setAppLanguage(newSelection.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ReminderProvider>(
              builder: (context, reminderProvider, _) =>
                  _buildTasbeehReminderSection(
                      context, lang, reminderProvider),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: AppStrings.get('quran_settings', lang),
              children: [
                ListTile(
                  title: Text(AppStrings.get('quran_font_size', lang),
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Text('${settings.quranFontSize.toInt()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: settings.quranFontSize > 12
                            ? () => settings.setQuranFontSize(
                                settings.quranFontSize - 2)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: settings.quranFontSize < 48
                            ? () => settings.setQuranFontSize(
                                settings.quranFontSize + 2)
                            : null,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text(AppStrings.get('quran_translation', lang),
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Text(settings.quranTranslationLang == 'en'
                      ? AppStrings.get('english', lang)
                      : settings.quranTranslationLang == 'ar'
                          ? AppStrings.get('arabic_explanation', lang)
                          : AppStrings.get('none', lang)),
                  onTap: () =>
                      _showTranslationSelectionDialog(context, lang, settings),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: AppStrings.get('data_management', lang),
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(AppStrings.get('clear_azkar_cache', lang),
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                onTap: _clearAzkarCache,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context,
      {required String title, Widget? child, List<Widget>? children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),
            if (child != null) child,
            if (children != null) ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTasbeehReminderSection(
      BuildContext context, String lang, ReminderProvider reminderProvider) {
    final settings = reminderProvider.settings;
    return _buildSectionCard(
      context,
      title: AppStrings.get('tasbeeh_reminder', lang),
      children: [
        SwitchListTile(
          title: Text(AppStrings.get('enable_reminder', lang),
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)),
          value: settings.enabled,
          onChanged: (value) async {
            if (value) {
              bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
              if (!isGranted) await FlutterOverlayWindow.requestPermission();
              await Permission.notification.request();
            }
            await reminderProvider.setEnabled(value);
            await ReminderSchedulerService.rescheduleAll();
          },
        ),
        if (settings.enabled) ...[
          ListTile(
            title: Text(AppStrings.get('reminder_interval', lang),
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle:
                Text('${settings.intervalMinutes} ${AppStrings.get('minutes', lang)}'),
            onTap: () =>
                _showIntervalSelectionDialog(context, lang, reminderProvider),
          ),
          const Divider(height: 16),
          SwitchListTile(
            title: Text(AppStrings.get('auto_show_overlay', lang),
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(AppStrings.get('auto_show_overlay_desc', lang),
                style: GoogleFonts.cairo(fontSize: 12)),
            value: settings.autoShowOverlay,
            onChanged: (value) async {
              if (value) {
                bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
                if (!isGranted) await FlutterOverlayWindow.requestPermission();
              }
              await reminderProvider.setAutoShowOverlay(value);
            },
          ),
          if (settings.enabled && !kIsWeb && Platform.isAndroid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.get('honor_huawei_tip', lang),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 16),
          ListTile(
            title: Text(AppStrings.get('select_tasbeeh', lang),
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () =>
                  _showAddCustomTasbeehDialog(context, lang, reminderProvider),
            ),
          ),
          ...reminderProvider.allTasbeehIds.map((id) {
            final isSelected = settings.selectedTasbeehIds.contains(id);
            final text = reminderProvider.getTasbeehText(id);
            final count = reminderProvider.getTasbeehTargetCount(id);
            return CheckboxListTile(
              title: Text(text, style: GoogleFonts.cairo(fontSize: 14)),
              subtitle: Text('${AppStrings.get('target_count', lang)}: $count'),
              value: isSelected,
              onChanged: (val) async {
                await reminderProvider.toggleTasbeehId(id);
                await ReminderSchedulerService.rescheduleAll();
              },
              secondary: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditRepeatCountDialog(
                    context, lang, id, text, count, reminderProvider),
              ),
            );
          }).toList(),
        ]
      ],
    );
  }

  void _showAddCustomTasbeehDialog(
      BuildContext context, String lang, ReminderProvider provider) {
    final textController = TextEditingController();
    final countController = TextEditingController(text: '33');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('add_custom_tasbeeh', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: textController,
                decoration: InputDecoration(
                    labelText: AppStrings.get('custom_tasbeeh_text', lang))),
            TextField(
                controller: countController,
                decoration:
                    InputDecoration(labelText: AppStrings.get('target_count', lang)),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get('cancel', lang))),
          TextButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                await provider.addCustomTasbeeh(
                    textController.text, int.tryParse(countController.text) ?? 33);
                await ReminderSchedulerService.rescheduleAll();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(AppStrings.get('ok', lang)),
          ),
        ],
      ),
    );
  }

  void _showEditRepeatCountDialog(BuildContext context, String lang, String id,
      String text, int currentCount, ReminderProvider provider) {
    final countController = TextEditingController(text: currentCount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('edit_repeat_count', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: GoogleFonts.cairo(fontSize: 14)),
            TextField(
                controller: countController,
                decoration:
                    InputDecoration(labelText: AppStrings.get('target_count', lang)),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.get('cancel', lang))),
          TextButton(
            onPressed: () async {
              await provider.setCustomRepeatCount(
                  id, int.tryParse(countController.text) ?? 33);
              await ReminderSchedulerService.rescheduleAll();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppStrings.get('ok', lang)),
          ),
        ],
      ),
    );
  }

  void _showIntervalSelectionDialog(
      BuildContext context, String lang, ReminderProvider reminderProvider) {
    final intervals = [5, 10, 15, 30, 45, 60, 90, 120];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('reminder_interval', lang)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: intervals.length,
            itemBuilder: (context, index) {
              final value = intervals[index];
              return RadioListTile<int>(
                title: Text('$value ${AppStrings.get('minutes', lang)}'),
                value: value,
                groupValue: reminderProvider.settings.intervalMinutes,
                onChanged: (newValue) async {
                  if (newValue != null) {
                    await reminderProvider.setInterval(newValue);
                    await ReminderSchedulerService.rescheduleAll();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTranslationSelectionDialog(
      BuildContext context, String lang, SettingsProvider settings) {
    final translations = [
      {'id': 'none', 'name': AppStrings.get('none', lang)},
      {'id': 'en', 'name': AppStrings.get('english', lang)},
      {'id': 'ar', 'name': AppStrings.get('arabic_explanation', lang)},
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('quran_translation', lang)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: translations.length,
            itemBuilder: (context, index) {
              final item = translations[index];
              return RadioListTile<String>(
                title: Text(item['name']!),
                value: item['id']!,
                groupValue: settings.quranTranslationLang,
                onChanged: (newValue) async {
                  if (newValue != null) {
                    await settings.setQuranTranslationLang(newValue);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
