import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../providers/settings_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/reminder_scheduler_service.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
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
        body: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section 1: المظهر
                _buildSectionCard(
                  context,
                  title: AppStrings.get('theme', lang),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode),
                        label: Text(AppStrings.get('light', lang)),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode),
                        label: Text(AppStrings.get('dark', lang)),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto),
                        label: Text(AppStrings.get('auto', lang)),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      settings.setThemeMode(newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: اللغة
                _buildSectionCard(
                  context,
                  title: AppStrings.get('language', lang),
                  children: [
                    // App Language
                    ListTile(
                      title: Text(
                        AppStrings.get('app_language', lang),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        settings.appLanguage == 'ar'
                            ? AppStrings.get('arabic_lang', lang)
                            : AppStrings.get('english', lang),
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'ar',
                            label: Text(AppStrings.get('arabic_lang', lang)),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text(AppStrings.get('english', lang)),
                          ),
                        ],
                        selected: {settings.appLanguage},
                        onSelectionChanged: (Set<String> newSelection) {
                          settings.setAppLanguage(newSelection.first);
                        },
                      ),
                    ),
                    const Divider(height: 32),
                    // Quran Translation Language
                    ListTile(
                      title: Text(
                        AppStrings.get('translation', lang),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _getTranslationLabel(
                          settings.quranTranslationLang,
                          lang,
                        ),
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'none',
                            label: Text(AppStrings.get('none', lang)),
                          ),
                          ButtonSegment(
                            value: 'ar',
                            label: Text(AppStrings.get('arabic', lang)),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text(AppStrings.get('english', lang)),
                          ),
                        ],
                        selected: {settings.quranTranslationLang},
                        onSelectionChanged: (Set<String> newSelection) {
                          settings.setQuranTranslationLang(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 3: Fonts
                _buildSectionCard(
                  context,
                  title: AppStrings.get('fonts', lang),
                  children: [
                    // App Font Size
                    ListTile(
                      title: Text(
                        AppStrings.get('app_font_size', lang),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        settings.appFontSize.toStringAsFixed(0),
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: settings.appFontSize,
                        min: 12.0,
                        max: 22.0,
                        divisions: 10,
                        label: settings.appFontSize.toStringAsFixed(0),
                        onChanged: (value) {
                          settings.setAppFontSize(value);
                        },
                      ),
                    ),
                    const Divider(height: 32),
                    // Quran Font Size
                    ListTile(
                      title: Text(
                        AppStrings.get('quran_font_size', lang),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        settings.quranFontSize.toStringAsFixed(0),
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: settings.quranFontSize,
                        min: 18.0,
                        max: 36.0,
                        divisions: 18,
                        label: settings.quranFontSize.toStringAsFixed(0),
                        onChanged: (value) {
                          settings.setQuranFontSize(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 4: Quran Display
                _buildSectionCard(
                  context,
                  title: AppStrings.get('quran_display', lang),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'mushaf',
                        label: Text(AppStrings.get('mushaf', lang)),
                      ),
                      ButtonSegment(
                        value: 'adaptive',
                        label: Text(AppStrings.get('adaptive', lang)),
                      ),
                    ],
                    selected: {settings.quranLayoutMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      settings.setQuranLayoutMode(newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Section 5: Tasbeeh Reminder
                Consumer<ReminderProvider>(
                  builder: (context, reminderProvider, _) {
                    return _buildTasbeehReminderSection(
                      context,
                      lang,
                      reminderProvider,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    Widget? child,
    List<Widget>? children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (child != null) child,
            if (children != null) ...children,
          ],
        ),
      ),
    );
  }

  String _getTranslationLabel(String value, String lang) {
    switch (value) {
      case 'ar':
        return AppStrings.get('arabic', lang);
      case 'en':
        return AppStrings.get('english', lang);
      default:
        return AppStrings.get('none', lang);
    }
  }

  Widget _buildTasbeehReminderSection(
    BuildContext context,
    String lang,
    ReminderProvider reminderProvider,
  ) {
    final settings = reminderProvider.settings;

    return _buildSectionCard(
      context,
      title: AppStrings.get('tasbeeh_reminder', lang),
      children: [
        // Enable switch
        SwitchListTile(
          title: Text(
            AppStrings.get('enable_reminder', lang),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          value: settings.enabled,
          onChanged: (value) async {
            if (value) {
              // Check permission before enabling
              bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
              if (!isGranted) {
                final permissionStatus =
                    await FlutterOverlayWindow.requestPermission();
                // Re-check after request
                isGranted = await FlutterOverlayWindow.isPermissionGranted();
                if (!isGranted) {
                  if (context.mounted) {
                    _showPermissionDialog(context, lang, reminderProvider);
                  }
                  return;
                }
              }

              // Check if tasbeehs are selected
              if (settings.selectedTasbeehIds.isEmpty) {
                _showNoTasbeehDialog(context, lang);
                return;
              }
            }
            await reminderProvider.setEnabled(value);
            await ReminderSchedulerService.rescheduleAll();
            
            if (value && context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تفعيل التذكير بنجاح. سيظهر التذكير القادم خلال الفترة المحددة.')),
              );
            }
          },
        ),
        if (settings.enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
                if (!isGranted) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.get('overlay_permission_required', lang))),
                    );
                    await FlutterOverlayWindow.requestPermission();
                  }
                  return;
                }
                
                await ReminderSchedulerService.showImmediate();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال طلب عرض التذكير...')),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(AppStrings.get('test_reminder', lang)),
            ),
          ),
        const Divider(height: 32),

        // Interval selector
        ListTile(
          title: Text(
            AppStrings.get('reminder_interval', lang),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${settings.intervalMinutes} ${AppStrings.get('minutes', lang)}',
            style: GoogleFonts.cairo(fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 15, label: const Text('15')),
              ButtonSegment(value: 30, label: const Text('30')),
              ButtonSegment(value: 60, label: const Text('60')),
              ButtonSegment(value: 120, label: const Text('120')),
              ButtonSegment(value: 180, label: const Text('180')),
              ButtonSegment(value: 240, label: const Text('240')),
            ],
            selected: {settings.intervalMinutes},
            onSelectionChanged: (Set<int> newSelection) async {
              await reminderProvider.setInterval(newSelection.first);
              await ReminderSchedulerService.rescheduleAll();
            },
          ),
        ),
        const Divider(height: 32),

        // Select tasbeeh
        ListTile(
          title: Text(
            AppStrings.get('select_tasbeeh', lang),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => _showAddCustomTasbeehDialog(
                  context,
                  lang,
                  reminderProvider,
                ),
          ),
        ),
        ...reminderProvider.allTasbeehIds.map((id) {
          final isSelected = settings.selectedTasbeehIds.contains(id);
          final tasbeehText = reminderProvider.getTasbeehText(id);
          final isCustom = id.startsWith('custom_');
          final targetCount = reminderProvider.getTasbeehTargetCount(id);

          return CheckboxListTile(
            title: Text(
              tasbeehText,
              style: GoogleFonts.cairo(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${AppStrings.get('target_count', lang)}: $targetCount',
              style: GoogleFonts.cairo(fontSize: 12),
            ),
            value: isSelected,
            onChanged: (value) async {
              await reminderProvider.toggleTasbeehId(id);
              await ReminderSchedulerService.rescheduleAll();
            },
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed:
                      () => _showEditRepeatCountDialog(
                        context,
                        lang,
                        id,
                        tasbeehText,
                        targetCount,
                        reminderProvider,
                      ),
                ),
                if (isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () async {
                      await reminderProvider.removeCustomTasbeeh(id);
                      await ReminderSchedulerService.rescheduleAll();
                    },
                  ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 32),

        // Allow close anytime
        SwitchListTile(
          title: Text(
            AppStrings.get('allow_close_anytime', lang),
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            AppStrings.get('allow_close_anytime_desc', lang),
            style: GoogleFonts.cairo(fontSize: 12),
          ),
          value: settings.allowCloseAnytime,
          onChanged: (value) async {
            await reminderProvider.setAllowCloseAnytime(value);
          },
        ),
      ],
    );
  }

  void _showPermissionDialog(
    BuildContext context,
    String lang,
    ReminderProvider reminderProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.get('overlay_permission_required', lang)),
            content: Text(AppStrings.get('overlay_permission_desc', lang)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('no', lang)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FlutterOverlayWindow.requestPermission();
                  final granted =
                      await FlutterOverlayWindow.isPermissionGranted();
                  if (granted) {
                    await reminderProvider.setEnabled(true);
                    await ReminderSchedulerService.rescheduleAll();
                  } else {
                    if (context.mounted) {
                      _showPermissionDeniedDialog(context, lang);
                    }
                  }
                },
                child: Text(AppStrings.get('grant_permission', lang)),
              ),
            ],
          ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.get('permission_denied', lang)),
            content: Text(AppStrings.get('permission_denied_desc', lang)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('ok', lang)),
              ),
            ],
          ),
    );
  }

  void _showNoTasbeehDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.get('no_tasbeeh_selected', lang)),
            content: Text(AppStrings.get('no_tasbeeh_selected_desc', lang)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('ok', lang)),
              ),
            ],
          ),
    );
  }

  void _showAddCustomTasbeehDialog(
    BuildContext context,
    String lang,
    ReminderProvider reminderProvider,
  ) {
    final textController = TextEditingController();
    final countController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.get('add_custom_tasbeeh', lang)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('custom_tasbeeh_text', lang),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('target_count', lang),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('cancel', lang)),
              ),
              TextButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  final count = int.tryParse(countController.text) ?? 100;
                  if (text.isNotEmpty) {
                    await reminderProvider.addCustomTasbeeh(text, count);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(AppStrings.get('ok', lang)),
              ),
            ],
          ),
    );
  }

  void _showEditRepeatCountDialog(
    BuildContext context,
    String lang,
    String id,
    String tasbeehText,
    int currentCount,
    ReminderProvider reminderProvider,
  ) {
    final countController = TextEditingController(
      text: currentCount.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.get('edit_repeat_count', lang)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tasbeehText,
                  style: GoogleFonts.cairo(fontSize: 14),
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  decoration: InputDecoration(
                    labelText: AppStrings.get('target_count', lang),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('cancel', lang)),
              ),
              TextButton(
                onPressed: () async {
                  final count =
                      int.tryParse(countController.text) ?? currentCount;
                  if (count > 0) {
                    await reminderProvider.setCustomRepeatCount(id, count);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(AppStrings.get('ok', lang)),
              ),
            ],
          ),
    );
  }
}
