import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.appLanguage;

    final List<Map<String, String>> pages = [
      {
        'title': lang == 'ar' ? 'مرحباً بك في درب الإيمان' : 'Welcome to Path of Faith',
        'desc': lang == 'ar' 
          ? 'رفيقك المسلم لقراءة القرآن، الأذكار، ومتابعة عبادتك اليومية.' 
          : 'Your Muslim companion for Quran, Azkar, and tracking your daily worship.',
        'icon': '🕌',
      },
      {
        'title': lang == 'ar' ? 'القرآن الكريم' : 'Holy Quran',
        'desc': lang == 'ar' 
          ? 'اقرأ القرآن الكريم برسم المصحف مع التفسير الميسر لكل آية.' 
          : 'Read the Holy Quran in Mushaf script with easy exegesis for every ayah.',
        'icon': '📖',
      },
      {
        'title': lang == 'ar' ? 'التذكير والعبادة' : 'Reminders & Worship',
        'desc': lang == 'ar' 
          ? 'تنبيهات للأذكار ومواقيت الصلاة، مع نظام لمتابعة أهدافك الإيمانية.' 
          : 'Alerts for Azkar and prayer times, with a system to track your faith goals.',
        'icon': '🔔',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pages[index]['icon']!,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          pages[index]['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B6914),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          pages[index]['desc']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index 
                            ? const Color(0xFF8B6914) 
                            : const Color(0xFF8B6914).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.read<SettingsProvider>().setFirstLaunchComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B6914),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage < pages.length - 1 
                        ? (lang == 'ar' ? 'التالي' : 'Next') 
                        : (lang == 'ar' ? 'ابدأ الآن' : 'Get Started'),
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
