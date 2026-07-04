import 'package:flutter/material.dart';
import '../models/surah_model.dart';

class SurahHeaderWidget extends StatelessWidget {
  final Surah surah;

  const SurahHeaderWidget({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF8B6914).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B6914), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left ornament
          _buildOrnament(),
          const SizedBox(width: 16),
          // Surah name
          Text(
            surah.nameArabic,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1810),
            ),
          ),
          const SizedBox(width: 16),
          // Right ornament
          _buildOrnament(),
        ],
      ),
    );
  }

  Widget _buildOrnament() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8B6914), width: 2),
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8B6914),
          ),
        ),
      ),
    );
  }
}
