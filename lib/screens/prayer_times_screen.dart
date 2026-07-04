import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import '../services/prayer_service.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTimes? _prayerTimes;
  Position? _currentPosition;
  Prayer? _nextPrayer;
  Prayer? _currentPrayer;
  int _countdownSeconds = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<Prayer, bool> _prayerChecked = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePrayerTimes();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializePrayerTimes() async {
    final lang = context.read<SettingsProvider>().appLanguage;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      final position = await PrayerService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _errorMessage = AppStrings.get('location_error', lang);
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      // Calculate prayer times
      final prayerTimes = PrayerService.calculatePrayerTimes(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _prayerTimes = prayerTimes;
        _isLoading = false;
      });

      // Load prayer checked states
      await _loadPrayerCheckedStates();

      // Update current and next prayer
      _updatePrayerStatus();

      // Start countdown timer
      _startTimer();
    } catch (e) {
      setState(() {
        _errorMessage = AppStrings.get(
          'error_message',
          lang,
          params: {'error': e.toString()},
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrayerCheckedStates() async {
    final prayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (var prayer in prayers) {
      final checked = await PrayerService.isPrayerChecked(prayer);
      setState(() {
        _prayerChecked[prayer] = checked;
      });
    }
  }

  void _updatePrayerStatus() {
    if (_prayerTimes == null) return;

    final currentPrayer = PrayerService.getCurrentPrayer(_prayerTimes!);
    final nextPrayer = PrayerService.getNextPrayer(_prayerTimes!);

    setState(() {
      _currentPrayer = currentPrayer;
      _nextPrayer = nextPrayer;
      _countdownSeconds = PrayerService.getTimeUntilNextPrayer(_prayerTimes!);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prayerTimes == null) return;

      setState(() {
        _countdownSeconds = PrayerService.getTimeUntilNextPrayer(_prayerTimes!);
      });

      // Update prayer status every minute
      if (_countdownSeconds % 60 == 0) {
        _updatePrayerStatus();
      }

      // Check for alert
      _checkForAlert();
    });
  }

  Future<void> _checkForAlert() async {
    if (_prayerTimes == null || _currentPrayer == null || _nextPrayer == null) {
      return;
    }

    // Check if current prayer is not checked
    final currentPrayerChecked = _prayerChecked[_currentPrayer] ?? false;
    if (currentPrayerChecked) return;

    // Check if alert should be triggered
    final shouldAlert = PrayerService.shouldTriggerAlert(
      _prayerTimes!,
      _currentPrayer!,
      _nextPrayer,
    );

    if (shouldAlert) {
      // Check if alert has already been played for this transition
      final alertPlayed = await PrayerService.hasAlertPlayed(
        _currentPrayer!,
        _nextPrayer!,
      );

      if (!alertPlayed) {
        // Play alert
        await _playAlert();

        // Show snackbar
        if (mounted) {
          final lang = context.read<SettingsProvider>().appLanguage;
          final currentPrayerName = AppStrings.get(_currentPrayer!.name, lang);
          final nextPrayerName = AppStrings.get(_nextPrayer!.name, lang);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.get(
                  'prayer_alert',
                  lang,
                  params: {
                    'next_prayer': nextPrayerName,
                    'current_prayer': currentPrayerName,
                  },
                ),
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Mark alert as played
        await PrayerService.setAlertPlayed(_currentPrayer!, _nextPrayer!, true);
      }
    }
  }

  Future<void> _playAlert() async {
    try {
      // Play a simple beep sound
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      // If sound file doesn't exist, use system sound
      // This is a fallback
    }
  }

  Future<void> _togglePrayerChecked(Prayer prayer) async {
    final currentState = _prayerChecked[prayer] ?? false;
    final newState = !currentState;

    setState(() {
      _prayerChecked[prayer] = newState;
    });

    await PrayerService.setPrayerChecked(prayer, newState);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().appLanguage;
    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('prayer_times', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializePrayerTimes,
              tooltip: AppStrings.get('refresh', lang),
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView(lang)
                : _buildPrayerTimesView(lang),
      ),
    );
  }

  Widget _buildErrorView(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializePrayerTimes,
            child: Text(AppStrings.get('retry', lang)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesView(String lang) {
    if (_prayerTimes == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Location info
          if (_currentPosition != null)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.get(
                      'latitude_longitude',
                      lang,
                      params: {
                        'lat': _currentPosition!.latitude.toStringAsFixed(2),
                        'long': _currentPosition!.longitude.toStringAsFixed(2),
                      },
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Next prayer card
          if (_nextPrayer != null) _buildNextPrayerCard(lang),

          const SizedBox(height: 16),

          // Prayer list
          _buildPrayerList(lang),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(String lang) {
    final nextPrayerName = AppStrings.get(_nextPrayer!.name, lang);
    final countdown = PrayerService.formatCountdown(_countdownSeconds);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.get('next_prayer', lang),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nextPrayerName,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppStrings.get('remaining', lang, params: {'time': countdown}),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(String lang) {
    final prayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    return Column(
      children:
          prayers.map((prayer) {
            final prayerName = AppStrings.get(prayer.name, lang);
            final prayerTime = _prayerTimes!.timeForPrayer(prayer);
            final formattedTime = PrayerService.formatTime(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                prayerTime?.hour ?? 0,
                prayerTime?.minute ?? 0,
              ),
            );
            final isChecked = _prayerChecked[prayer] ?? false;
            final isCurrentPrayer = _currentPrayer == prayer;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isCurrentPrayer && !isChecked ? 4 : 1,
              color:
                  isChecked
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : (isCurrentPrayer
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface),
              child: ListTile(
                leading: Checkbox(
                  value: isChecked,
                  onChanged:
                      prayer == Prayer.sunrise
                          ? null
                          : (value) => _togglePrayerChecked(prayer),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  prayerName,
                  style: TextStyle(
                    fontWeight:
                        isCurrentPrayer ? FontWeight.bold : FontWeight.normal,
                    color: isChecked ? Colors.grey : null,
                  ),
                ),
                trailing: Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isChecked
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
