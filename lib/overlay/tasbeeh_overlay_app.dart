import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/reminder_scheduler_service.dart';

class TasbeehOverlayApp extends StatefulWidget {
  const TasbeehOverlayApp({super.key});

  @override
  State<TasbeehOverlayApp> createState() => _TasbeehOverlayAppState();
}

class _TasbeehOverlayAppState extends State<TasbeehOverlayApp> {
  String _tasbeehText = '';
  int _targetCount = 100;
  int _currentCount = 0;
  bool _allowCloseAnytime = false;
  String _lang = 'ar';
  bool _isCompleted = false;
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Listen for data shared from the main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null) {
        _updateFromData(data);
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString('current_overlay_data');
      if (dataJson != null) {
        final data = jsonDecode(dataJson);
        _updateFromData(data);
      }
    } catch (e) {
      // Ignore
    }
  }

  void _updateFromData(dynamic data) {
    if (data is Map<String, dynamic>) {
      setState(() {
        _tasbeehText = data['tasbeehText'] ?? '';
        _targetCount = data['targetCount'] ?? 100;
        _allowCloseAnytime = data['allowCloseAnytime'] ?? false;
        _lang = data['lang'] ?? 'ar';
        _currentCount = 0;
        _isCompleted = false;
      });
    }
  }

  void _onCounterTap() {
    if (_isCompleted) return;

    setState(() {
      _currentCount++;
    });

    HapticFeedback.lightImpact();

    if (_currentCount >= _targetCount) {
      _onCompletion();
    }
  }

  void _onCompletion() async {
    setState(() {
      _isCompleted = true;
    });

    // Mark as completed in scheduler
    try {
      await ReminderSchedulerService.markAsCompleted();
    } catch (e) {
      // Ignore
    }

    // Auto-close after 1.5 seconds
    _completionTimer = Timer(const Duration(milliseconds: 1500), () {
      FlutterOverlayWindow.closeOverlay();
    });
  }

  void _closeOverlay() {
    FlutterOverlayWindow.closeOverlay();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tasbeehText.isEmpty && !_isCompleted) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Close button
                if (_allowCloseAnytime)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _closeOverlay,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isCompleted)
                        _buildCompletionView()
                      else
                        _buildTasbeehView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasbeehView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tasbeeh text
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF0F5132).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _tasbeehText,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F5132),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 24),

        // Progress indicator
        Text(
          '$_currentCount / $_targetCount',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F5132),
          ),
        ),

        const SizedBox(height: 24),

        // Tap-to-count circle
        GestureDetector(
          onTap: _onCounterTap,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F5132),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_targetCount - _currentCount}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lang == 'ar' ? 'متبقي' : 'remaining',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Instructions
        Text(
          _lang == 'ar' ? 'اضغط للعد' : 'Tap to count',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Color(0xFF0F5132)),
        const SizedBox(height: 16),
        Text(
          'بارك الله فيك',
          style: const TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F5132),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _lang == 'ar' ? 'أحسنت' : 'Well done',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
    );
  }
}
