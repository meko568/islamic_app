import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown once at app startup while [SettingsProvider] reads persisted
/// preferences from disk. Kept intentionally simple and fast — this is
/// the in-app loading state, distinct from the native OS splash screen
/// (flutter_native_splash) which is already gone by the time Flutter's
/// first frame (this widget) renders.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B6914), Color(0xFFB08D3F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B6914).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'التطبيق الإسلامي',
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B6914),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF8B6914),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
