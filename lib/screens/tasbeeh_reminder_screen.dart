import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

class TasbeehReminderScreen extends StatefulWidget {
  final String tasbeehId;
  const TasbeehReminderScreen({super.key, required this.tasbeehId});

  @override
  State<TasbeehReminderScreen> createState() => _TasbeehReminderScreenState();
}

class _TasbeehReminderScreenState extends State<TasbeehReminderScreen> {
  int _currentCount = 0;
  int? _targetCount;
  String? _tasbeehText;

  void _increment() {
    if (_targetCount == null) return;
    if (_currentCount < _targetCount!) {
      setState(() {
        _currentCount++;
      });
      if (_currentCount == _targetCount) {
        _showCompletion();
      }
    }
  }

  void _showCompletion() {
    final lang = context.read<SettingsProvider>().appLanguage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang == 'ar' ? 'تم الانتهاء، بارك الله فيك' : 'Completed, MashAllah'),
        backgroundColor: Colors.green,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    final reminderProvider = context.watch<ReminderProvider>();

    // Wait until settings are loaded
    if (!reminderProvider.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Initialize values once loaded
    _targetCount ??= reminderProvider.getTasbeehTargetCount(widget.tasbeehId);
    _tasbeehText ??= reminderProvider.getTasbeehText(widget.tasbeehId);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('tasbeeh_reminder', lang), style: GoogleFonts.cairo()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _tasbeehText!,
                style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border.all(color: Theme.of(context).primaryColor, width: 5),
                ),
                child: Center(
                  child: Text(
                    '$_currentCount / $_targetCount',
                    style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lang == 'ar' ? 'اضغط على الدائرة للعد' : 'Tap the circle to count',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
