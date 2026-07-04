import 'package:flutter/material.dart';
import '../models/surah_model.dart';

class AyahTextWidget extends StatelessWidget {
  final Ayah ayah;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAyahNumber;
  final bool isHighlighted;
  final bool isWebLayout;

  const AyahTextWidget({
    super.key,
    required this.ayah,
    this.onTap,
    this.onLongPress,
    this.showAyahNumber = true,
    this.isHighlighted = false,
    this.isWebLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isWebLayout ? 26.0 : 24.0;
    final highlightColor =
        isHighlighted
            ? const Color(0xFFFFF9C4) // Soft yellow
            : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            // Ayah text with red highlighting for الله
            Expanded(
              child: RichText(
                text: TextSpan(children: _buildTextSpans(fontSize)),
                textAlign: isWebLayout ? TextAlign.center : TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
            // Ayah end marker
            if (showAyahNumber)
              isWebLayout ? _buildSuperscriptMarker() : _buildCircularMarker(),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(double fontSize) {
    final spans = <TextSpan>[];
    final text = ayah.text;

    // Pattern to match الله, تالله, بالله
    final pattern = RegExp(r'(الله|تالله|بالله)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: fontSize,
              height: 2.0,
              color: const Color(0xFF2C1810),
            ),
          ),
        );
      }

      // Add the matched word in red
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: fontSize,
            height: 2.0,
            color: const Color(0xFFC0392B), // Red for الله
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: fontSize,
            height: 2.0,
            color: const Color(0xFF2C1810),
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildCircularMarker() {
    return Container(
      margin: const EdgeInsets.only(right: 8, left: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B6914), // Gold/brown
        border: Border.all(color: const Color(0xFF5D4E37), width: 2),
      ),
      child: Center(
        child: Text(
          _convertToArabicNumerals(ayah.numberInSurah),
          style: const TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSuperscriptMarker() {
    return Container(
      margin: const EdgeInsets.only(right: 4, left: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B6914),
        border: Border.all(color: const Color(0xFF5D4E37), width: 1),
      ),
      child: Text(
        _convertToArabicNumerals(ayah.numberInSurah),
        style: const TextStyle(
          fontFamily: 'UthmanicHafs',
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _convertToArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      return arabicNumerals[int.parse(digit)];
    }).join();
  }
}
